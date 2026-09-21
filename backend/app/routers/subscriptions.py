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
        # Create default pending if none exists
        sub = Subscription(
            shop_id=shop.id,
            plan_name="basic",
            amount=settings.SUBSCRIPTION_AMOUNT,
            status="PENDING"
        )
        db.add(sub)
        db.commit()
        db.refresh(sub)

    now = datetime.utcnow()
    # Check expiry
    if sub.status == "ACTIVE" and sub.end_date and sub.end_date < now:
        sub.status = "EXPIRED"
        db.commit()
        db.refresh(sub)

    is_active = (sub.status == "ACTIVE" and sub.end_date and sub.end_date > now)

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

    return SubscriptionResponse(
        id=sub.id,
        shop_id=sub.shop_id,
        plan_name=sub.plan_name,
        amount=sub.amount,
        status=sub.status,
        start_date=sub.start_date,
        end_date=sub.end_date,
        is_active=True
    )


@router.post("/webhook")
async def razorpay_webhook(request: Request, db: Session = Depends(get_db)):
    """Razorpay server-to-server webhook endpoint for async payment confirmations."""
    body = await request.json()
    event = body.get("event")
    # Log webhook event for audit trail
    return {"status": "ok", "received_event": event}
