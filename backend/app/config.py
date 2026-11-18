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
    # locked out before the UPI gateway is deployed. Turn on once it is live.
    ENFORCE_SUBSCRIPTION: bool = False

    # Subscription payments via the self-hosted UPI Gateway.
    # Set these on the server (Render dashboard); never commit real values.
    # UPI_GATEWAY_BASE_URL is the gateway's public URL, e.g. https://pay.example.com
    UPI_GATEWAY_BASE_URL: str = ""
    UPI_GATEWAY_API_KEY: str = ""
    UPI_GATEWAY_API_SECRET: str = ""
    # Live webhook signing secret shown in the gateway dashboard (API & Webhooks).
    UPI_GATEWAY_WEBHOOK_SECRET: str = ""
    # Only for testing with gateway Sandbox keys (test_key_...). Sandbox payments
    # are simulated and must never activate a subscription in production.
    UPI_GATEWAY_ALLOW_SANDBOX: bool = False
    UPI_GATEWAY_TIMEOUT_SECONDS: float = 15.0
    SUBSCRIPTION_AMOUNT: Decimal = Decimal("49.00")

    model_config = SettingsConfigDict(
        env_file=str(ENV_FILE) if ENV_FILE.exists() else ".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )


settings = Settings()
