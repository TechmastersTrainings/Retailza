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

    # JWT Authentication
    SECRET_KEY: str = "retailza_super_secret_jwt_key_kirana_saas_2026_production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 10080  # 7 days
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # OTP & SMS Gateway
    OTP_EXPIRE_MINUTES: int = 5
    DEBUG_MOCK_OTP: bool = False
    MOCK_OTP_CODE: str = "123456"
    SMS_PROVIDER: str = "fast2sms"
    FAST2SMS_API_KEY: str = ""

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
