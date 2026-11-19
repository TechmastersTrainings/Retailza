from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from backend.app.database import get_db
from backend.app.models import Shop, Subscription, SubscriptionPayment
from backend.app.schemas import (
    SubscriptionResponse, SubscriptionOrderResponse, SubscriptionPaymentVerify
)
from backend.app.dependencies import get_current_shop
from backend.app.utils.razorpay_client import (
    create_razorpay_order, verify_razorpay_signature
)
from backend.app.config import settings

router = APIRouter(prefix="/subscriptions", tags=["Subscription & Billing"])


@router.get("/current", response_model=SubscriptionResponse)
def get_subscription(shop: Shop = Depends(get_current_shop), db: Session = Depends(get_db)):
    """Fetch active subscription status and renewal dates."""
    sub = db.query(Subscription).filter(Subscription.shop_id == shop.id).first()
    if not sub:
        # Create default complimentary 30-day active trial
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

    now = datetime.utcnow()
    # Check expiry
    if sub.status == "ACTIVE" and sub.end_date and sub.end_date <= now:
        sub.status = "EXPIRED"
        db.commit()
        db.refresh(sub)

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


@router.post("/create-order", response_model=SubscriptionOrderResponse)
def create_subscription_order(
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db)
):
    """Create a ₹49 Razorpay order for 30-day SaaS subscription."""
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

    order = create_razorpay_order(
        amount=settings.SUBSCRIPTION_AMOUNT,
        currency="INR",
        receipt=f"shop_{shop.id}_sub_{sub.id}"
    )

    return SubscriptionOrderResponse(
        order_id=order["id"],
        amount=settings.SUBSCRIPTION_AMOUNT,
        currency="INR",
        key_id=settings.RAZORPAY_KEY_ID,
        subscription_id=sub.id
    )


@router.post("/verify-payment", response_model=SubscriptionResponse)
def verify_subscription_payment(
    payload: SubscriptionPaymentVerify,
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db)
):
    """
    Verify payment signature and activate/extend the ₹49/month subscription for 30 days.
    """
    is_valid = verify_razorpay_signature(
        order_id=payload.razorpay_order_id,
        payment_id=payload.razorpay_payment_id,
        signature=payload.razorpay_signature
    )

    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid payment signature. Verification failed."
        )

    sub = db.query(Subscription).filter(Subscription.shop_id == shop.id).first()
    if not sub:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Subscription not found for this shop"
        )

    now = datetime.utcnow()
    # Calculate new period
    if sub.status == "ACTIVE" and sub.end_date and sub.end_date > now:
        # Extend by 30 days from existing end date
        sub.end_date = sub.end_date + timedelta(days=30)
    else:
        # Start new 30-day period
        sub.start_date = now
        sub.end_date = now + timedelta(days=30)

    sub.status = "ACTIVE"
    sub.plan_name = "basic"

    # Record payment transaction
    payment_record = SubscriptionPayment(
        subscription_id=sub.id,
        payment_id=payload.razorpay_payment_id,
        order_id=payload.razorpay_order_id,
        signature=payload.razorpay_signature,
        amount=settings.SUBSCRIPTION_AMOUNT,
        status="SUCCESS",
        payment_method="RAZORPAY"
    )
    db.add(payment_record)

    db.commit()
    db.refresh(sub)

    rem_days = max(0, (sub.end_date - now).days) if sub.end_date and sub.end_date > now else 30

    return SubscriptionResponse(
        id=sub.id,
        shop_id=sub.shop_id,
        plan_name=sub.plan_name,
        amount=sub.amount,
        status=sub.status,
        start_date=sub.start_date,
        end_date=sub.end_date,
        is_active=True,
        trial_days_completed=False,
        days_remaining=int(rem_days),
        days_elapsed=0,
        is_locked=False,
        lock_reason=None
    )


@router.post("/webhook")
async def razorpay_webhook(request: Request, db: Session = Depends(get_db)):
    """Razorpay server-to-server webhook endpoint for async payment confirmations."""
    body = await request.json()
    event = body.get("event")
    # Log webhook event for audit trail
    return {"status": "ok", "received_event": event}
