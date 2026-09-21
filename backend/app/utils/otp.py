import os
import re
import random
import logging
from datetime import datetime, timedelta
import httpx
from backend.app.config import settings

logger = logging.getLogger(__name__)


def generate_otp() -> str:
    """Generate a 6-digit OTP string."""
    if settings.DEBUG_MOCK_OTP:
        return settings.MOCK_OTP_CODE
    return f"{random.randint(100000, 999999)}"


def get_otp_expiry() -> datetime:
    """Get UTC timestamp for OTP expiration."""
    return datetime.utcnow() + timedelta(minutes=settings.OTP_EXPIRE_MINUTES)


def sanitize_indian_mobile(mobile: str) -> str:
    """
    Extract standard 10-digit Indian mobile number:
    Strips country code (+91/91), leading zeros, and formatting characters.
    """
    digits = re.sub(r"\D", "", mobile)
    if digits.startswith("91") and len(digits) == 12:
        return digits[2:]
    if digits.startswith("0") and len(digits) == 11:
        return digits[1:]
    return digits[-10:] if len(digits) >= 10 else digits


def send_sms_otp(mobile_number: str, otp_code: str) -> bool:
    """
    Dispatcher for sending real OTP via SMS.
    Uses Fast2SMS Quick OTP route when configured.
    Falls back gracefully or bypasses during automated unit test runs.
    """
    clean_mobile = sanitize_indian_mobile(mobile_number)

    # 1. Skip external carrier call during automated tests or for test dummy numbers
    is_testing = bool(os.environ.get("PYTEST_CURRENT_TEST"))
    if is_testing or clean_mobile in ("9988776655", "0000000000"):
        logger.info(f"[Test OTP Mode] Skipped carrier dispatch for {clean_mobile}. Code: {otp_code}")
        print(f"\n==========================================")
        print(f"  [RETAILZA TEST RUN OTP]")
        print(f"  Mobile: +91 {clean_mobile}")
        print(f"  OTP Code: {otp_code}")
        print(f"==========================================\n")
        return True

    # 2. Mock mode (if explicitly re-enabled in .env)
    if settings.DEBUG_MOCK_OTP:
        logger.info(f"[Mock OTP] {otp_code} for mobile: +91-{clean_mobile}")
        print(f"\n==========================================")
        print(f"  [RETAILZA MOCK OTP NOTIFICATION]")
        print(f"  Mobile: +91 {clean_mobile}")
        print(f"  OTP Code: {otp_code} (Valid for {settings.OTP_EXPIRE_MINUTES} mins)")
        print(f"==========================================\n")
        return True

    # 3. Live Fast2SMS Gateway Integration
    if settings.SMS_PROVIDER.lower() == "fast2sms" and settings.FAST2SMS_API_KEY:
        try:
            url = "https://www.fast2sms.com/dev/bulkV2"
            headers = {
                "authorization": settings.FAST2SMS_API_KEY,
                "accept": "application/json",
            }
            params = {
                "variables_values": str(otp_code),
                "route": "otp",
                "numbers": clean_mobile,
            }

            with httpx.Client(timeout=8.0) as client:
                response = client.get(url, headers=headers, params=params)
                data = response.json() if response.status_code == 200 else {}

                if response.status_code == 200 and data.get("return") is True:
                    logger.info(f"[Fast2SMS] OTP sent to +91-{clean_mobile}: {data.get('message')}")
                    print(f"\n==========================================")
                    print(f"  [FAST2SMS DISPATCHED]")
                    print(f"  Sent real OTP to: +91 {clean_mobile}")
                    print(f"  Provider Message: {data.get('message', ['Success'])}")
                    print(f"  OTP Code: {otp_code} (Valid for {settings.OTP_EXPIRE_MINUTES} mins)")
                    print(f"==========================================\n")
                    return True
                else:
                    logger.error(
                        f"[Fast2SMS Failure] Status={response.status_code}, Body={response.text}"
                    )
                    print(f"\n[Fast2SMS Error] HTTP {response.status_code}: {response.text}\n")
                    return False
        except Exception as e:
            logger.error(f"[Fast2SMS Exception] Error sending SMS to {clean_mobile}: {e}")
            print(f"\n[Fast2SMS Exception] Error: {e}\n")
            return False

    # 4. Fallback if no provider key is configured
    logger.warning(f"No active SMS provider configured for {clean_mobile}.")
    print(f"\n==========================================")
    print(f"  [RETAILZA OTP - NO SMS PROVIDER KEY]")
    print(f"  Mobile: +91 {clean_mobile}")
    print(f"  OTP Code: {otp_code}")
    print(f"==========================================\n")
    return True
