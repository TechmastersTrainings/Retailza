from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from backend.app.database import get_db
from backend.app.models import User, OTPVerification, Shop
from backend.app.schemas import (
    OTPRequest, OTPVerify, PasswordLoginRequest, TokenResponse, RefreshTokenRequest,
    UserResponse, ShopResponse
)
from backend.app.utils.security import (
    create_access_token, create_refresh_token, decode_token, verify_password
)
from backend.app.utils.otp import generate_otp, get_otp_expiry, send_sms_otp
from backend.app.dependencies import get_current_user
from backend.app.config import settings

router = APIRouter(prefix="/auth", tags=["Authentication"])


def normalize_identifier(identifier: str) -> tuple[str, bool]:
    """Normalize identifier: strip formatting, handle +91/0 prefixes, and lowercase emails."""
    cleaned = identifier.strip()
    if "@" in cleaned:
        return cleaned.lower(), True
    # Digits only for phone
    digits = "".join(filter(str.isdigit, cleaned))
    if len(digits) == 12 and digits.startswith("91"):
        digits = digits[2:]
    elif len(digits) == 11 and digits.startswith("0"):
        digits = digits[1:]
    return digits if digits else cleaned, False


@router.post("/request-otp", status_code=status.HTTP_200_OK)
def request_otp(payload: OTPRequest, db: Session = Depends(get_db)):
    """Request a 6-digit OTP for mobile number or email address authentication."""
    raw_target = payload.identifier or payload.mobile_number
    if not raw_target:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mobile number or email address is required"
        )
    target, is_email = normalize_identifier(raw_target)

    otp_code = generate_otp()
    expires_at = get_otp_expiry()

    # Invalidate previous unverified OTPs for this identifier
    db.query(OTPVerification).filter(
        (OTPVerification.identifier == target) | (OTPVerification.mobile_number == target),
        OTPVerification.is_verified == False
    ).delete()

    otp_record = OTPVerification(
        identifier=target,
        mobile_number=target if not is_email else None,
        otp_code=otp_code,
        expires_at=expires_at,
        is_verified=False
    )
    db.add(otp_record)
    db.commit()

    if is_email:
        print(f"\n=========================================\n  [RETAILZA EMAIL OTP NOTIFICATION]\n  Email: {target}\n  OTP Code: {otp_code} (Valid for {settings.OTP_EXPIRE_MINUTES} mins)\n=========================================\n")
        message = f"OTP sent successfully to {target}"
    else:
        send_sms_otp(target, otp_code)
        message = f"OTP sent successfully to +91-{target}"

    response_data = {
        "message": message,
        "identifier": target,
        "expires_in_minutes": settings.OTP_EXPIRE_MINUTES
    }
    if settings.DEBUG:
        response_data["debug_otp"] = otp_code

    return response_data


@router.post("/verify-otp", response_model=TokenResponse)
def verify_otp(payload: OTPVerify, db: Session = Depends(get_db)):
    """Verify OTP for mobile or email and issue JWT access and refresh tokens."""
    raw_target = payload.identifier or payload.mobile_number
    if not raw_target:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mobile number or email address is required"
        )
    target, is_email = normalize_identifier(raw_target)

    now = datetime.utcnow()
    otp_record = db.query(OTPVerification).filter(
        (OTPVerification.identifier == target) | (OTPVerification.mobile_number == target),
        OTPVerification.otp_code == payload.otp_code,
        OTPVerification.is_verified == False,
        OTPVerification.expires_at >= now
    ).order_by(OTPVerification.id.desc()).first()

    if not otp_record:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired OTP"
        )

    # Mark OTP as verified
    otp_record.is_verified = True

    # Find or create User
    if is_email:
        user = db.query(User).filter(func.lower(User.email) == target.lower()).first()
        if not user:
            user = User(
                email=target.lower(),
                name=target.split("@")[0].capitalize(),
                role="OWNER"
            )
            db.add(user)
            db.flush()
    else:
        user = db.query(User).filter(User.mobile_number == target).first()
        if not user:
            user = User(
                mobile_number=target,
                name=f"Shopkeeper {target[-4:]}",
                role="OWNER"
            )
            db.add(user)
            db.flush()

    db.commit()
    db.refresh(user)

    # Check for existing shop
    shop = db.query(Shop).filter(Shop.owner_id == user.id).first()

    # Issue JWT tokens
    token_payload = {
        "sub": str(user.id),
        "mobile": user.mobile_number or "",
        "email": user.email or "",
        "role": user.role
    }
    access_token = create_access_token(token_payload)
    refresh_token = create_refresh_token(token_payload)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        user=UserResponse.model_validate(user),
        shop=ShopResponse.model_validate(shop) if shop else None
    )


@router.post("/login-password", response_model=TokenResponse)
def login_with_password(payload: PasswordLoginRequest, db: Session = Depends(get_db)):
    """Authenticate with Email or Mobile and Password (for Admins and registered users)."""
    target, is_email = normalize_identifier(payload.identifier)
    if is_email:
        user = db.query(User).filter(func.lower(User.email) == target.lower()).first()
    else:
        user = db.query(User).filter(User.mobile_number == target).first()

    if not user or not user.hashed_password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials or password not configured for this account"
        )

    if not verify_password(payload.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid password"
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is deactivated"
        )

    shop = db.query(Shop).filter(Shop.owner_id == user.id).first()
    token_payload = {
        "sub": str(user.id),
        "mobile": user.mobile_number or "",
        "email": user.email or "",
        "role": user.role
    }
    access_token = create_access_token(token_payload)
    refresh_token = create_refresh_token(token_payload)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        user=UserResponse.model_validate(user),
        shop=ShopResponse.model_validate(shop) if shop else None
    )


@router.post("/refresh-token")
def refresh_access_token(payload: RefreshTokenRequest, db: Session = Depends(get_db)):
    """Issue a new access token using a valid refresh token."""
    token_data = decode_token(payload.refresh_token)
    if not token_data or token_data.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token"
        )

    user_id = token_data.get("sub")
    user = db.query(User).filter(User.id == int(user_id)).first()
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive"
        )

    new_payload = {"sub": str(user.id), "mobile": user.mobile_number, "role": user.role}
    new_access_token = create_access_token(new_payload)

    return {
        "access_token": new_access_token,
        "token_type": "bearer"
    }


@router.get("/me")
def get_current_user_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Retrieve the authenticated user's profile and active shop."""
    shop = db.query(Shop).filter(Shop.owner_id == current_user.id).first()
    return {
        "user": UserResponse.model_validate(current_user),
        "shop": ShopResponse.model_validate(shop) if shop else None
    }
