import json
import logging
import uuid
from datetime import datetime, timedelta
from typing import Any, Dict, Optional, Tuple

from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session

from backend.app.database import get_db
from backend.app.models import Shop, Subscription, SubscriptionPayment
from backend.app.schemas import (
    SubscriptionResponse, SubscriptionOrderResponse, SubscriptionPaymentStatusResponse
)
from backend.app.dependencies import get_current_shop
from backend.app.utils import upi_gateway
from backend.app.utils.upi_gateway import UpiGatewayError, UpiGatewayNotConfigured
from backend.app.config import settings

router = APIRouter(prefix="/subscriptions", tags=["Subscription & Billing"])
logger = logging.getLogger(__name__)

PAYMENT_METHOD = "UPI_GATEWAY"
SUBSCRIPTION_PERIOD = timedelta(days=30)

# Gateway order status -> SubscriptionPayment.status
GATEWAY_STATUS_MAP = {
    "pending": "PENDING",
    "review": "REVIEW",
    "expired": "EXPIRED",
    "failed": "FAILED",
}


def _get_or_create_subscription(db: Session, shop: Shop) -> Subscription:
    sub = db.query(Subscription).filter(Subscription.shop_id == shop.id).first()
    if not sub:
        sub = Subscription(
            shop_id=shop.id,
            plan_name="basic",
            amount=settings.SUBSCRIPTION_AMOUNT,
            status="PENDING"
        )
        db.add(sub)
        db.commit()
        db.refresh(sub)
    return sub


def _subscription_response(sub: Subscription) -> SubscriptionResponse:
    now = datetime.utcnow()
    is_active = sub.status == "ACTIVE" and sub.end_date is not None and sub.end_date > now
    return SubscriptionResponse(
        id=sub.id,
        shop_id=sub.shop_id,
        plan_name=sub.plan_name,
        amount=sub.amount,
        status=sub.status,
        start_date=sub.start_date,
        end_date=sub.end_date,
        is_active=bool(is_active)
    )


def _environment_allowed(order: Dict[str, Any]) -> bool:
    if order.get("environment") == "live" and order.get("test") is not True:
        return True
    return settings.UPI_GATEWAY_ALLOW_SANDBOX and order.get("environment") == "sandbox"


def _paid_order_problem(payment: SubscriptionPayment, order: Dict[str, Any]) -> Optional[str]:
    """Why a gateway 'paid' order must NOT activate this subscription (None if it may)."""
    if order.get("order_id") != payment.order_id:
        return "order_id_mismatch"
    if upi_gateway.to_amount(order.get("amount")) != upi_gateway.to_amount(payment.amount):
        return "amount_mismatch"
    if (order.get("currency") or "INR") != "INR":
        return "currency_mismatch"
    if not _environment_allowed(order):
        return "sandbox_payment"
    return None


def _apply_gateway_order(db: Session, payment_id: int, order: Dict[str, Any]) -> Tuple[SubscriptionPayment, Optional[str]]:
    """
    Record the gateway's view of the order and activate the subscription once.
    Row locks make concurrent webhook + app polling activate at most once.
    """
    payment = db.query(SubscriptionPayment).filter(
        SubscriptionPayment.id == payment_id
    ).with_for_update().one()

    # SUCCESS is final. An EXPIRED order can still turn PAID: the gateway
    # recovers payments the customer completed shortly before expiry.
    if payment.status == "SUCCESS":
        db.commit()
        return payment, None

    gateway_status = str(order.get("status") or "").lower()
    message: Optional[str] = None

    if gateway_status == "paid":
        problem = _paid_order_problem(payment, order)
        if problem:
            logger.warning(
                "Subscription payment not activated",
                extra={"payment_id": payment.id, "order_id": payment.order_id, "reason": problem},
            )
            payment.status = "FAILED"
            message = ("Test payments cannot activate a subscription."
                       if problem == "sandbox_payment"
                       else "Payment could not be verified. Please contact Retailza support.")
        else:
            sub = db.query(Subscription).filter(
                Subscription.id == payment.subscription_id
            ).with_for_update().one()
            now = datetime.utcnow()
            if sub.status == "ACTIVE" and sub.end_date and sub.end_date > now:
                sub.end_date = sub.end_date + SUBSCRIPTION_PERIOD
            else:
                sub.start_date = now
                sub.end_date = now + SUBSCRIPTION_PERIOD
            sub.status = "ACTIVE"

            payment.status = "SUCCESS"
            utr = order.get("utr")
            payment.payment_id = str(utr)[:100] if utr else payment.payment_id
    elif gateway_status in GATEWAY_STATUS_MAP:
        payment.status = GATEWAY_STATUS_MAP[gateway_status]
        if payment.status == "REVIEW":
            message = "Your UTR was submitted and is being verified."

    db.commit()
    db.refresh(payment)
    return payment, message


@router.get("/current", response_model=SubscriptionResponse)
def get_subscription(shop: Shop = Depends(get_current_shop), db: Session = Depends(get_db)):
    """Fetch active subscription status and renewal dates."""
    sub = _get_or_create_subscription(db, shop)

    # Check expiry
    if sub.status == "ACTIVE" and sub.end_date and sub.end_date < datetime.utcnow():
        sub.status = "EXPIRED"
        db.commit()
        db.refresh(sub)

    return _subscription_response(sub)


@router.post("/create-order", response_model=SubscriptionOrderResponse)
def create_subscription_order(
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db)
):
    """Create a ₹49 UPI Gateway payment order for a 30-day subscription."""
    sub = _get_or_create_subscription(db, shop)
    amount = settings.SUBSCRIPTION_AMOUNT
    client_order_id = f"RTZSUB-{shop.id}-{uuid.uuid4().hex[:20]}"
    owner_mobile = shop.owner.mobile_number if shop.owner else None

    try:
        order = upi_gateway.create_order(
            amount=amount,
            client_order_id=client_order_id,
            note="Retailza 30 day plan",
            customer_name=shop.owner_name,
            customer_mobile=owner_mobile,
        )
    except UpiGatewayNotConfigured as e:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(e))
    except UpiGatewayError as e:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=str(e))

    order_id = order.get("order_id")
    payment_url = order.get("payment_url")
    if (not isinstance(order_id, str) or not order_id or not isinstance(payment_url, str)
            or upi_gateway.to_amount(order.get("amount")) != upi_gateway.to_amount(amount)
            or not _environment_allowed(order)):
        logger.error("Unexpected UPI gateway order response", extra={"client_order_id": client_order_id})
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Payment server returned an unexpected order. Please try again."
        )

    db.add(SubscriptionPayment(
        subscription_id=sub.id,
        order_id=order_id,
        amount=amount,
        status="PENDING",
        payment_method=PAYMENT_METHOD,
    ))
    db.commit()

    return SubscriptionOrderResponse(
        order_id=order_id,
        amount=amount,
        currency="INR",
        subscription_id=sub.id,
        payment_url=payment_url,
        upi_intent=order.get("upi_intent") or None,
        expires_at=order.get("expires_at"),
        test=order.get("environment") != "live",
    )


@router.get("/payments/{order_id}/status", response_model=SubscriptionPaymentStatusResponse)
def get_subscription_payment_status(
    order_id: str,
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db)
):
    """
    Polled by the app while the shop owner pays. The gateway is the only
    source of truth; the app cannot mark a payment as paid.
    """
    payment = db.query(SubscriptionPayment).join(Subscription).filter(
        SubscriptionPayment.order_id == order_id,
        SubscriptionPayment.payment_method == PAYMENT_METHOD,
        Subscription.shop_id == shop.id,
    ).first()
    if not payment:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Payment order not found")

    message: Optional[str] = None
    if payment.status != "SUCCESS":
        try:
            order = upi_gateway.get_order(order_id)
            payment, message = _apply_gateway_order(db, payment.id, order)
        except UpiGatewayError as e:
            # Keep the last known status; the app simply polls again.
            message = str(e)

    sub = db.query(Subscription).filter(Subscription.id == payment.subscription_id).one()
    return SubscriptionPaymentStatusResponse(
        order_id=order_id,
        status=payment.status,
        message=message,
        subscription=_subscription_response(sub),
    )


@router.post("/gateway-webhook")
async def upi_gateway_webhook(request: Request, db: Session = Depends(get_db)):
    """
    Signed server-to-server notification from the UPI Gateway
    (order.paid / order.expired / order.under_review). Activates the
    subscription even if the app was closed after paying.
    """
    raw_body = await request.body()
    if not upi_gateway.verify_webhook_signature(
        raw_body, request.headers.get("X-Signature"), settings.UPI_GATEWAY_WEBHOOK_SECRET
    ):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid signature")

    try:
        event = json.loads(raw_body)
        order_id = event["data"]["order_id"]
    except (ValueError, KeyError, TypeError):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid payload")

    payment = db.query(SubscriptionPayment).filter(
        SubscriptionPayment.order_id == order_id,
        SubscriptionPayment.payment_method == PAYMENT_METHOD,
    ).first()
    if not payment:
        # Not a Retailza subscription order; acknowledge so it is not retried.
        return {"status": "ignored"}

    if payment.status != "SUCCESS":
        try:
            # Re-read the order from the gateway API instead of acting on the
            # payload alone; duplicate or out-of-order deliveries are harmless.
            order = upi_gateway.get_order(order_id)
        except UpiGatewayError:
            # Non-2xx makes the gateway retry the delivery later.
            raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Retry later")
        payment, _ = _apply_gateway_order(db, payment.id, order)

    return {"status": "ok", "payment_status": payment.status}
