import os
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict
from decimal import Decimal

# Locate .env in backend directory or root
BASE_DIR = Path(__file__).resolve().parent.parent
ENV_FILE = BASE_DIR / ".env"


class Settings(BaseSettings):
    # App
    APP_NAME: str = "Retailza"
    APP_ENV: str = "development"
    DEBUG: bool = True

    # Database
    DATABASE_URL: str = f"sqlite:///{BASE_DIR / 'retailza.db'}"

    # JWT Authentication.
    # No secret is committed: set SECRET_KEY in the environment (Render dashboard).
    # In production the app refuses to start without it (see main.py). Locally,
    # an ephemeral dev key is used only when APP_ENV != "production".
    SECRET_KEY: str = ""
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 10080  # 7 days
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # Allowed browser origins for CORS (comma-separated, or "*").
    # The API authenticates with Bearer tokens (no cookies), so credentials are off.
    ALLOWED_ORIGINS: str = "*"

    # OTP & SMS Gateway
    OTP_EXPIRE_MINUTES: int = 5
    DEBUG_MOCK_OTP: bool = False
    MOCK_OTP_CODE: str = "123456"
    SMS_PROVIDER: str = "fast2sms"
    FAST2SMS_API_KEY: str = ""
    # OTP abuse protection
    OTP_RESEND_COOLDOWN_SECONDS: int = 30     # min gap between OTP requests per identifier
    OTP_MAX_SENDS_PER_WINDOW: int = 5         # max OTP sends within one unexpired window
    OTP_MAX_VERIFY_ATTEMPTS: int = 5          # wrong guesses before the code is locked

    # Seed super-admin from the environment only. If email+password are unset,
    # NO admin is auto-created, and an existing admin's password is never reset.
    SEED_ADMIN_EMAIL: str = ""
    SEED_ADMIN_MOBILE: str = ""
    SEED_ADMIN_NAME: str = "Retailza Super Admin"
    SEED_ADMIN_PASSWORD: str = ""

    # Server-side subscription paywall. Off by default so the live app is not
    # locked out before billing is switched on. Turn on once you are collecting.
    ENFORCE_SUBSCRIPTION: bool = False

    # Direct UPI subscription billing (no payment aggregator, no middleman).
    # The ₹49 is paid straight into YOUR own UPI ID / bank account. The app shows
    # this VPA as a QR + intent; the shop owner pays with any UPI app and submits
    # the 12-digit UTR (bank reference) printed on their payment receipt.
    #   SUBSCRIPTION_UPI_ID        your collecting VPA, e.g. techmasters@okhdfcbank
    #   SUBSCRIPTION_UPI_PAYEE     name shown in the UPI app while paying
    # Set these on the server (Render dashboard).
    SUBSCRIPTION_UPI_ID: str = ""
    SUBSCRIPTION_UPI_PAYEE: str = "Retailza"
    SUBSCRIPTION_AMOUNT: Decimal = Decimal("49.00")
    SUBSCRIPTION_PERIOD_DAYS: int = 30
    # True  -> a validated, unused UTR activates the month immediately (lowest
    #          friction; you reconcile against your bank and can reject fakes).
    # False -> UTR submissions wait in REVIEW until an admin verifies each one.
    SUBSCRIPTION_AUTO_ACTIVATE_ON_UTR: bool = True

    model_config = SettingsConfigDict(
        env_file=str(ENV_FILE) if ENV_FILE.exists() else ".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )


settings = Settings()
