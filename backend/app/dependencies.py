from datetime import datetime
from typing import Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from backend.app.database import get_db
from backend.app.models import User, Shop, Subscription
from backend.app.utils.security import decode_token

security = HTTPBearer(auto_error=False)


def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication token is required",
            headers={"WWW-Authenticate": "Bearer"},
        )

    payload = decode_token(credentials.credentials)
    if not payload or payload.get("type") != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired access token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user = db.query(User).filter(User.id == int(user_id)).first()
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or account deactivated",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return user


def get_current_shop(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Shop:
    shop = db.query(Shop).filter(Shop.owner_id == user.id).first()
    if not shop:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No shop configured for this user. Please complete shop setup."
        )
    return shop


def require_active_subscription(
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db)
) -> Subscription:
    sub = db.query(Subscription).filter(Subscription.shop_id == shop.id).first()
    now = datetime.utcnow()

    if not sub or sub.status != "ACTIVE" or (sub.end_date and sub.end_date < now):
        if sub and sub.end_date and sub.end_date < now and sub.status == "ACTIVE":
            sub.status = "EXPIRED"
            db.commit()

        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Active Retailza subscription (₹49/month) required to perform this action."
        )

    return sub


def require_super_admin(
    user: User = Depends(get_current_user),
) -> User:
    if user.role != "SUPER_ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access forbidden: Super Admin privileges required."
        )
    return user
