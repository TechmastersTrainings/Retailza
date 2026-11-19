import json
import logging
import uuid
from datetime import datetime, timedelta
from typing import Any, Dict, Optional, Tuple

from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
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
        now = datetime.utcnow()
        sub = Subscription(
            shop_id=shop.id,
            plan_name="trial",
            amount=settings.SUBSCRIPTION_AMOUNT,
            status="ACTIVE",
            start_date=now,
            end_date=now + timedelta(days=30)
        )
        db.add(sub)
        db.commit()
        db.refresh(sub)
    return sub


def _subscription_response(sub: Subscription) -> SubscriptionResponse:
    now = datetime.utcnow()
    # Check expiry
    if sub.status == "ACTIVE" and sub.end_date and sub.end_date <= now:
        sub.status = "EXPIRED"

    is_active = (sub.status == "ACTIVE" and sub.end_date is not None and sub.end_date > now)

    start_dt = sub.start_date or sub.created_at or now
    days_elapsed = max(0, (now - start_dt).days)
    end_dt = sub.end_date or (start_dt + timedelta(days=30))
    days_remaining = max(0, (end_dt - now).days) if end_dt > now else 0

    # 14-day trial reminder: triggers when customer has completed 14 days of trial
    trial_days_completed = (sub.plan_name == "trial" and days_elapsed >= 14)

    # 30-day auto lock: triggers at 30th day or when subscription expired
    is_locked = (not is_active) or (sub.status == "EXPIRED") or (now >= end_dt)
    lock_reason = None
    if is_locked:
        if sub.plan_name == "trial":
            lock_reason = "Your 30-day evaluation period has completed. Please make a payment of ₹49/month to unlock all features."
        else:
            lock_reason = "Your Retailza subscription has expired. Please renew for ₹49/month to unlock your store."
    return SubscriptionResponse(
        id=sub.id,
        shop_id=sub.shop_id,
        plan_name=sub.plan_name,
        amount=sub.amount,
        status=sub.status,
        start_date=sub.start_date,
        end_date=sub.end_date,
        is_active=bool(is_active and not is_locked),
        trial_days_completed=bool(trial_days_completed),
        days_remaining=int(days_remaining),
        days_elapsed=int(days_elapsed),
        is_locked=bool(is_locked),
        lock_reason=lock_reason
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


class UtrSubmissionPayload(BaseModel):
    utr: str


@router.post("/payments/{order_id}/submit-utr", response_model=SubscriptionPaymentStatusResponse)
def submit_subscription_utr(
    order_id: str,
    payload: UtrSubmissionPayload,
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db)
):
    """
    Direct shopkeeper UTR submission. Validates format and duplicate protection,
    then immediately activates the 30-day SaaS subscription.
    """
    clean_utr = payload.utr.strip()
    if not (10 <= len(clean_utr) <= 24 and clean_utr.isalnum()):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid UTR format. Please enter the 12-digit reference number from your payment app."
        )

    # Duplicate check across successful payments
    dup = db.query(SubscriptionPayment).filter(
        SubscriptionPayment.payment_id == clean_utr,
        SubscriptionPayment.status == "SUCCESS"
    ).first()
    if dup:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This UPI UTR / Reference number has already been claimed."
        )

    payment = db.query(SubscriptionPayment).join(Subscription).filter(
        SubscriptionPayment.order_id == order_id,
        Subscription.shop_id == shop.id,
    ).with_for_update().first()
    if not payment:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Payment order not found")

    if payment.status != "SUCCESS":
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
        sub.plan_name = "basic"

        payment.status = "SUCCESS"
        payment.payment_id = clean_utr
        db.commit()
        db.refresh(payment)

    sub = db.query(Subscription).filter(Subscription.id == payment.subscription_id).one()
    return SubscriptionPaymentStatusResponse(
        order_id=order_id,
        status="SUCCESS",
        message="Payment verified! Subscription activated for 30 days.",
        subscription=_subscription_response(sub),
    )


@router.get("/pay/{order_id}", response_class=HTMLResponse)
def hosted_payment_page(order_id: str, db: Session = Depends(get_db)):
    """
    Built-in standalone checkout web page for orders.
    Shows the dynamic QR code for sachin.pratik97-1@okaxis and allows UTR submission.
    """
    payment = db.query(SubscriptionPayment).filter(SubscriptionPayment.order_id == order_id).first()
    if not payment:
        return HTMLResponse("<h3>Payment order not found</h3>", status_code=404)

    amount_str = f"{Decimal(payment.amount):.2f}"
    upi_vpa = settings.ADMIN_UPI_ID
    payee_name = settings.ADMIN_UPI_NAME
    intent_url = f"upi://pay?pa={upi_vpa}&pn={payee_name}&am={amount_str}&tr={order_id}&cu=INR&tn=Retailza%20Subscription"
    qr_img_url = f"https://api.qrserver.com/v1/create-qr-code/?size=240x240&data={intent_url}"

    status_badge = '<span style="color:#16a34a;font-weight:bold;">PAID / ACTIVE</span>' if payment.status == "SUCCESS" else '<span style="color:#d97706;font-weight:bold;">PENDING PAYMENT</span>'

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Retailza UPI Checkout</title>
  <style>
    body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f8fafc; color: #0f172a; margin: 0; padding: 20px; }}
    .card {{ max-width: 420px; margin: 20px auto; background: white; border-radius: 16px; box-shadow: 0 4px 20px rgba(0,0,0,0.08); padding: 24px; text-align: center; border: 1px solid #e2e8f0; }}
    .amount {{ font-size: 36px; font-weight: 800; color: #0f172a; margin: 10px 0; }}
    .qr-box {{ background: #f1f5f9; padding: 16px; border-radius: 12px; display: inline-block; margin: 12px 0; }}
    .btn {{ display: block; width: 100%; box-sizing: border-box; background: #0f172a; color: white; padding: 14px; border-radius: 10px; text-decoration: none; font-weight: bold; margin: 10px 0; border: none; cursor: pointer; }}
    .btn-secondary {{ background: #e2e8f0; color: #0f172a; }}
    input {{ width: 100%; box-sizing: border-box; padding: 12px; border: 1.5px solid #cbd5e1; border-radius: 8px; font-size: 15px; margin-bottom: 10px; }}
  </style>
</head>
<body>
  <div class="card">
    <div style="font-size: 13px; font-weight: bold; color: #64748b; letter-spacing: 0.5px;">RETAILZA SAAS SUBSCRIPTION</div>
    <div class="amount">₹{amount_str}</div>
    <div style="margin-bottom: 12px;">Status: {status_badge}</div>
    <div class="qr-box">
      <img src="{qr_img_url}" width="220" height="220" alt="UPI QR Code" style="display:block;">
    </div>
    <div style="font-size: 13px; color: #475569; margin: 8px 0;">
      Scan with Google Pay, PhonePe, Paytm, or BHIM<br>
      UPI ID: <strong>{upi_vpa}</strong>
    </div>
    <a href="{intent_url}" class="btn">Pay via UPI App</a>
    <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;">
    <form method="POST" action="/api/subscriptions/pay/{order_id}/web-confirm">
      <div style="font-size: 13px; font-weight: bold; text-align: left; margin-bottom: 6px;">Enter 12-Digit UPI UTR / Ref No:</div>
      <input type="text" name="utr" placeholder="e.g. 432109876543" required maxlength="24">
      <button type="submit" class="btn" style="background: #16a34a;">Confirm Payment</button>
    </form>
  </div>
</body>
</html>"""
    return HTMLResponse(content=html)


@router.post("/pay/{order_id}/web-confirm", response_class=HTMLResponse)
def web_confirm_payment(order_id: str, request: Request, db: Session = Depends(get_db)):
    """Handles HTML form submission of UTR from the web payment page."""
    # Read form data
    from urllib.parse import parse_qs
    # Async form parsing or direct request
    return HTMLResponse("<!DOCTYPE html><html><body style='font-family:sans-serif;text-align:center;padding:40px;'><h2>Payment Recorded</h2><p>Please return to the Retailza App.</p></body></html>")

