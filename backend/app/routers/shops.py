from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from backend.app.database import get_db
from backend.app.models import User, Shop, Subscription
from backend.app.schemas import ShopCreate, ShopUpdate, ShopResponse
from backend.app.dependencies import get_current_user, get_current_shop
from backend.app.config import settings

router = APIRouter(prefix="/shops", tags=["Shop Management"])


@router.post("/setup", response_model=ShopResponse, status_code=status.HTTP_201_CREATED)
def setup_shop(
    payload: ShopCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Initial onboarding: create Kirana store profile and initialize pending subscription."""
    existing_shop = db.query(Shop).filter(Shop.owner_id == current_user.id).first()
    if existing_shop:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Shop is already set up for this user. Use PUT /shops/current to update."
        )

    # Create new Shop
    shop = Shop(
        owner_id=current_user.id,
        shop_name=payload.shop_name,
        owner_name=payload.owner_name,
        address=payload.address,
        city=payload.city,
        state=payload.state,
        pincode=payload.pincode,
        upi_qr_image=payload.upi_qr_image,
        upi_id=payload.upi_id
    )
    db.add(shop)
    db.flush()

    # Create initial pending subscription for ₹49/month
    subscription = Subscription(
        shop_id=shop.id,
        plan_name="basic",
        amount=settings.SUBSCRIPTION_AMOUNT,
        status="PENDING"
    )
    db.add(subscription)

    # Sync owner name to user profile
    current_user.name = payload.owner_name

    db.commit()
    db.refresh(shop)
    return ShopResponse.model_validate(shop)


@router.get("/current", response_model=ShopResponse)
def get_shop(shop: Shop = Depends(get_current_shop)):
    """Fetch current user's shop profile."""
    return ShopResponse.model_validate(shop)


@router.put("/current", response_model=ShopResponse)
def update_shop(
    payload: ShopUpdate,
    shop: Shop = Depends(get_current_shop),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update Kirana shop profile information."""
    if payload.shop_name is not None:
        shop.shop_name = payload.shop_name
    if payload.owner_name is not None:
        shop.owner_name = payload.owner_name
        current_user.name = payload.owner_name
    if payload.address is not None:
        shop.address = payload.address
    if payload.city is not None:
        shop.city = payload.city
    if payload.state is not None:
        shop.state = payload.state
    if payload.pincode is not None:
        shop.pincode = payload.pincode
    if payload.upi_qr_image is not None:
        shop.upi_qr_image = payload.upi_qr_image
    if payload.upi_id is not None:
        shop.upi_id = payload.upi_id

    db.commit()
    db.refresh(shop)
    return ShopResponse.model_validate(shop)
