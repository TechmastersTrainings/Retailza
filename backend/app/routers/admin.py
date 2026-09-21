from datetime import datetime, timedelta
from typing import List, Optional
from decimal import Decimal
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import func, or_
from backend.app.database import get_db
from backend.app.models import (
    User, Shop, Subscription, SubscriptionPayment, Sale, SystemAnnouncement
)
from backend.app.schemas import (
    AdminMetricsResponse, AdminShopItem, SendReminderRequest,
    ExtendSubscriptionRequest, AnnouncementCreate, AnnouncementResponse
)
from backend.app.dependencies import require_super_admin
from backend.app.config import settings

router = APIRouter(prefix="/admin", tags=["Super Admin Operations"])


@router.get("/metrics", response_model=AdminMetricsResponse)
def get_company_metrics(
    admin: User = Depends(require_super_admin),
    db: Session = Depends(get_db)
):
    """Retrieve top-level business and SaaS metrics for the platform."""
    now = datetime.utcnow()
    start_of_today = datetime(now.year, now.month, now.day)
    seven_days_ago = now - timedelta(days=7)
    three_days_future = now + timedelta(days=3)

    total_users = db.query(User).filter(User.role != "SUPER_ADMIN").count()
    total_shops = db.query(Shop).count()

    # Revenue calculation from successful subscription payments
    raw_revenue = db.query(func.coalesce(func.sum(SubscriptionPayment.amount), 0.0))\
        .filter(SubscriptionPayment.status == "SUCCESS").scalar()
    total_revenue = Decimal(str(raw_revenue))

    # New registrations
    new_today = db.query(Shop).filter(Shop.created_at >= start_of_today).count()
    new_week = db.query(Shop).filter(Shop.created_at >= seven_days_ago).count()

    # Subscription breakdown
    subs = db.query(Subscription).all()
    active_count = 0
    expiring_soon_count = 0
    expired_count = 0
    pending_count = 0

    for s in subs:
        if s.status == "ACTIVE" and s.end_date:
            if s.end_date > now:
                active_count += 1
                if s.end_date <= three_days_future:
                    expiring_soon_count += 1
            else:
                expired_count += 1
        elif s.status == "EXPIRED":
            expired_count += 1
        else:
            pending_count += 1

    # Monthly Recurring Revenue estimation (Active paying shops * ₹49.00)
    mrr = Decimal(str(active_count)) * settings.SUBSCRIPTION_AMOUNT

    return AdminMetricsResponse(
        total_users=total_users,
        total_shops=total_shops,
        total_revenue=total_revenue,
        monthly_recurring_revenue=mrr,
        new_registrations_today=new_today,
        new_registrations_this_week=new_week,
        active_subscriptions=active_count,
        expiring_soon_subscriptions=expiring_soon_count,
        expired_subscriptions=expired_count,
        pending_subscriptions=pending_count
    )


@router.get("/shops", response_model=List[AdminShopItem])
def get_all_shops(
    q: Optional[str] = Query(None, description="Search query by shop name, owner, phone, email, or city"),
    status_filter: Optional[str] = Query("ALL", description="ALL, ACTIVE, EXPIRING, EXPIRED, PENDING"),
    admin: User = Depends(require_super_admin),
    db: Session = Depends(get_db)
):
    """List all registered Kirana stores with contact info, status, and transaction totals."""
    query = db.query(Shop).join(User, Shop.owner_id == User.id)

    if q:
        search = f"%{q.strip()}%"
        query = query.filter(
            or_(
                Shop.shop_name.ilike(search),
                Shop.owner_name.ilike(search),
                Shop.city.ilike(search),
                User.mobile_number.ilike(search),
                User.email.ilike(search)
            )
        )

    shops = query.order_by(Shop.created_at.desc()).all()
    now = datetime.utcnow()
    three_days_future = now + timedelta(days=3)

    results: List[AdminShopItem] = []
    for s in shops:
        sub = db.query(Subscription).filter(Subscription.shop_id == s.id).first()
        sub_status = "PENDING"
        end_date = None
        if sub:
            end_date = sub.end_date
            if sub.status == "ACTIVE" and sub.end_date:
                if sub.end_date > now:
                    if sub.end_date <= three_days_future:
                        sub_status = "EXPIRING_SOON"
                    else:
                        sub_status = "ACTIVE"
                else:
                    sub_status = "EXPIRED"
            elif sub.status == "EXPIRED":
                sub_status = "EXPIRED"
            else:
                sub_status = "PENDING"

        # Apply status filter
        if status_filter != "ALL":
            if status_filter == "ACTIVE" and sub_status not in ("ACTIVE", "EXPIRING_SOON"):
                continue
            elif status_filter == "EXPIRING" and sub_status != "EXPIRING_SOON":
                continue
            elif status_filter == "EXPIRED" and sub_status != "EXPIRED":
                continue
            elif status_filter == "PENDING" and sub_status != "PENDING":
                continue

        # Get sales aggregates
        sales_stats = db.query(
            func.count(Sale.id).label("cnt"),
            func.coalesce(func.sum(Sale.final_amount), 0.0).label("tot")
        ).filter(Sale.shop_id == s.id).first()

        results.append(
            AdminShopItem(
                id=s.id,
                shop_name=s.shop_name,
                owner_name=s.owner_name,
                mobile_number=s.owner.mobile_number if s.owner else None,
                email=s.owner.email if s.owner else None,
                city=s.city,
                state=s.state,
                created_at=s.created_at,
                subscription_status=sub_status,
                subscription_end_date=end_date,
                sales_count=sales_stats[0] if sales_stats else 0,
                total_sales_amount=Decimal(str(sales_stats[1])) if sales_stats else Decimal("0.00")
            )
        )

    return results


@router.post("/reminders/send")
def send_renewal_reminder(
    payload: SendReminderRequest,
    admin: User = Depends(require_super_admin),
    db: Session = Depends(get_db)
):
    """Trigger an automated renewal reminder (WhatsApp/SMS) to an expiring shopkeeper."""
    shop = db.query(Shop).filter(Shop.id == payload.shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")

    sub = db.query(Subscription).filter(Subscription.shop_id == shop.id).first()
    expiry_str = sub.end_date.strftime("%d-%b-%Y") if (sub and sub.end_date) else "soon"
    contact = shop.owner.mobile_number or shop.owner.email or "Store Owner"

    reminder_text = (
        f"Namaste {shop.owner_name} Ji, your Retailza SaaS subscription for {shop.shop_name} "
        f"is due for renewal on {expiry_str}. Renew for ₹49.00 to keep billing & Khata uninterrupted."
    )

    # Simulated/logged dispatch for WhatsApp/SMS
    print(f"\n=========================================\n"
          f"  [RETAILZA DISPATCHED {payload.channel} REMINDER]\n"
          f"  To: {contact} ({shop.owner_name})\n"
          f"  Store: {shop.shop_name}\n"
          f"  Message: {reminder_text}\n"
          f"=========================================\n")

    return {
        "success": True,
        "channel": payload.channel,
        "recipient": contact,
        "message": reminder_text,
        "dispatched_at": datetime.utcnow().isoformat()
    }


@router.post("/subscriptions/extend")
def extend_subscription_manually(
    payload: ExtendSubscriptionRequest,
    admin: User = Depends(require_super_admin),
    db: Session = Depends(get_db)
):
    """Admin manual subscription extension or complimentary trial activation."""
    shop = db.query(Shop).filter(Shop.id == payload.shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")

    sub = db.query(Subscription).filter(Subscription.shop_id == shop.id).first()
    now = datetime.utcnow()
    if not sub:
        sub = Subscription(
            shop_id=shop.id,
            plan_name="basic",
            amount=settings.SUBSCRIPTION_AMOUNT,
            status="ACTIVE",
            start_date=now,
            end_date=now + timedelta(days=payload.days)
        )
        db.add(sub)
    else:
        if sub.status == "ACTIVE" and sub.end_date and sub.end_date > now:
            sub.end_date = sub.end_date + timedelta(days=payload.days)
        else:
            sub.start_date = now
            sub.end_date = now + timedelta(days=payload.days)
        sub.status = "ACTIVE"

    db.commit()
    db.refresh(sub)

    return {
        "success": True,
        "shop_id": shop.id,
        "new_end_date": sub.end_date.isoformat(),
        "status": sub.status,
        "days_extended": payload.days
    }


@router.get("/announcements", response_model=List[AnnouncementResponse])
def list_announcements(
    admin: User = Depends(require_super_admin),
    db: Session = Depends(get_db)
):
    """List all feature announcements and broadcasts."""
    return db.query(SystemAnnouncement).order_by(SystemAnnouncement.created_at.desc()).all()


@router.post("/announcements", response_model=AnnouncementResponse)
def create_announcement(
    payload: AnnouncementCreate,
    admin: User = Depends(require_super_admin),
    db: Session = Depends(get_db)
):
    """Publish a new feature push or broadcast message to all mobile users."""
    announcement = SystemAnnouncement(
        title=payload.title,
        message=payload.message,
        tag=payload.tag.upper(),
        action_url=payload.action_url,
        is_active=True
    )
    db.add(announcement)
    db.commit()
    db.refresh(announcement)
    return announcement


@router.delete("/announcements/{announcement_id}")
def delete_announcement(
    announcement_id: int,
    admin: User = Depends(require_super_admin),
    db: Session = Depends(get_db)
):
    """Delete an announcement."""
    announcement = db.query(SystemAnnouncement).filter(SystemAnnouncement.id == announcement_id).first()
    if not announcement:
        raise HTTPException(status_code=404, detail="Announcement not found")
    db.delete(announcement)
    db.commit()
    return {"success": True, "message": "Announcement deleted"}
