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

    # Razorpay Subscription
    RAZORPAY_KEY_ID: str = "rzp_test_TWXn6r1HPxwz0r"
    RAZORPAY_KEY_SECRET: str = "6u35s2LHnOuWVlBWF94HP1by"
    SUBSCRIPTION_AMOUNT: Decimal = Decimal("49.00")

    model_config = SettingsConfigDict(
        env_file=str(ENV_FILE) if ENV_FILE.exists() else ".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )


settings = Settings()
