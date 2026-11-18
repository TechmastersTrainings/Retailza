import logging
import re
import uuid
from datetime import datetime, timedelta
from typing import Optional
from urllib.parse import quote

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from backend.app.database import get_db
from backend.app.models import Shop, Subscription, SubscriptionPayment
from backend.app.schemas import (
    SubscriptionResponse, SubscriptionOrderResponse,
    SubscriptionPaymentStatusResponse, UtrSubmission,
)
from backend.app.dependencies import get_current_shop
from backend.app.config import settings

router = APIRouter(prefix="/subscriptions", tags=["Subscription & Billing"])
logger = logging.getLogger(__name__)

PAYMENT_METHOD = "UPI_DIRECT"
# A UPI UTR / bank reference number (RRN) is a 12-digit number printed on the
# payment receipt in every UPI app. We store it so the same receipt can never
# pay for two shops.
UTR_RE = re.compile(r"^\d{12}$")


def _period() -> timedelta:
    return timedelta(days=settings.SUBSCRIPTION_PERIOD_DAYS)


def _get_or_create_subscription(db: Session, shop: Shop) -> Subscription:
    sub = db.query(Subscription).filter(Subscription.shop_id == shop.id).first()
    if not sub:
        sub = Subscription(
            shop_id=shop.id,
            plan_name="basic",
            amount=settings.SUBSCRIPTION_AMOUNT,
            status="PENDING",
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
        is_active=bool(is_active),
    )


def _activate(db: Session, subscription_id: int) -> None:
    """Start or extend a subscription by one period. Caller commits."""
    sub = db.query(Subscription).filter(
        Subscription.id == subscription_id
    ).with_for_update().one()
    now = datetime.utcnow()
    if sub.status == "ACTIVE" and sub.end_date and sub.end_date > now:
        sub.end_date = sub.end_date + _period()  # stack onto remaining time
    else:
        sub.start_date = now
        sub.end_date = now + _period()
    sub.status = "ACTIVE"


@router.get("/current", response_model=SubscriptionResponse)
def get_subscription(shop: Shop = Depends(get_current_shop), db: Session = Depends(get_db)):
    """Fetch the shop's subscription status and renewal dates."""
    sub = _get_or_create_subscription(db, shop)
    if sub.status == "ACTIVE" and sub.end_date and sub.end_date < datetime.utcnow():
        sub.status = "EXPIRED"
        db.commit()
        db.refresh(sub)
    return _subscription_response(sub)


@router.post("/create-order", response_model=SubscriptionOrderResponse)
def create_subscription_order(
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db),
):
    """
    Start a ₹49 UPI payment. Returns YOUR collecting UPI ID as a scannable
    intent. The shop owner pays directly into your account with any UPI app,
    then submits the UTR from their receipt to activate the month.
    """
    vpa = settings.SUBSCRIPTION_UPI_ID.strip()
    if not vpa:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Subscription payments are not configured yet. Please contact Retailza support.",
        )

    sub = _get_or_create_subscription(db, shop)
    amount = settings.SUBSCRIPTION_AMOUNT
    reference = f"RTZ{shop.id}{uuid.uuid4().hex[:12]}".upper()  # alphanumeric, <35 chars for UPI tr=
    note = "Retailza 30 day plan"
    amount_str = f"{amount:.2f}"
    payee = settings.SUBSCRIPTION_UPI_PAYEE.strip() or "Retailza"

    upi_intent = (
        "upi://pay?"
        f"pa={quote(vpa)}"
        f"&pn={quote(payee)}"
        f"&am={amount_str}"
        "&cu=INR"
        f"&tn={quote(note)}"
        f"&tr={quote(reference)}"
    )

    db.add(SubscriptionPayment(
        subscription_id=sub.id,
        order_id=reference,
        amount=amount,
        status="PENDING",
        payment_method=PAYMENT_METHOD,
    ))
    db.commit()

    return SubscriptionOrderResponse(
        order_id=reference,
        amount=amount,
        currency="INR",
        subscription_id=sub.id,
        upi_id=vpa,
        payee_name=payee,
        upi_intent=upi_intent,
        note=note,
    )


@router.post("/payments/{order_id}/submit-utr", response_model=SubscriptionPaymentStatusResponse)
def submit_utr(
    order_id: str,
    payload: UtrSubmission,
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db),
):
    """
    The shop owner submits the 12-digit UTR from their UPI receipt. A valid,
    unused UTR activates the month (or waits for admin review, per config).
    """
    utr = re.sub(r"\s+", "", payload.utr or "")
    if not UTR_RE.match(utr):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Enter the 12-digit UTR / UPI reference number from your payment receipt.",
        )

    payment = db.query(SubscriptionPayment).join(Subscription).filter(
        SubscriptionPayment.order_id == order_id,
        SubscriptionPayment.payment_method == PAYMENT_METHOD,
        Subscription.shop_id == shop.id,
    ).with_for_update().first()
    if not payment:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Payment order not found")

    if payment.status == "SUCCESS":
        sub = db.query(Subscription).filter(Subscription.id == payment.subscription_id).one()
        return SubscriptionPaymentStatusResponse(
            order_id=order_id, status="SUCCESS",
            message="This payment is already confirmed.",
            subscription=_subscription_response(sub),
        )

    # One receipt can pay for exactly one order, ever.
    clash = db.query(SubscriptionPayment).filter(
        SubscriptionPayment.payment_id == utr,
        SubscriptionPayment.id != payment.id,
        SubscriptionPayment.status.in_(["SUCCESS", "REVIEW"]),
    ).first()
    if clash:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This UTR has already been used. Each payment reference can be used only once.",
        )

    payment.payment_id = utr

    if settings.SUBSCRIPTION_AUTO_ACTIVATE_ON_UTR:
        payment.status = "SUCCESS"
        _activate(db, payment.subscription_id)
        message = "Payment confirmed. Your subscription is active."
    else:
        payment.status = "REVIEW"
        message = "UTR received. Your subscription will activate once we verify the payment."

    db.commit()
    db.refresh(payment)
    sub = db.query(Subscription).filter(Subscription.id == payment.subscription_id).one()
    return SubscriptionPaymentStatusResponse(
        order_id=order_id, status=payment.status, message=message,
        subscription=_subscription_response(sub),
    )


@router.get("/payments/{order_id}/status", response_model=SubscriptionPaymentStatusResponse)
def get_subscription_payment_status(
    order_id: str,
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db),
):
    """Current status of a payment order for this shop (no external calls)."""
    payment = db.query(SubscriptionPayment).join(Subscription).filter(
        SubscriptionPayment.order_id == order_id,
        SubscriptionPayment.payment_method == PAYMENT_METHOD,
        Subscription.shop_id == shop.id,
    ).first()
    if not payment:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Payment order not found")

    sub = db.query(Subscription).filter(Subscription.id == payment.subscription_id).one()
    messages = {
        "PENDING": "Waiting for your UTR. Pay ₹49 and submit the reference number.",
        "REVIEW": "Your UTR is being verified.",
        "SUCCESS": "Payment confirmed. Your subscription is active.",
        "FAILED": "This payment was rejected. Please contact Retailza support.",
    }
    return SubscriptionPaymentStatusResponse(
        order_id=order_id,
        status=payment.status,
        message=messages.get(payment.status),
        subscription=_subscription_response(sub),
    )
