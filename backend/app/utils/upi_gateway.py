"""
Client for the self-hosted UPI Gateway (merchant API v1).

The gateway creates the payment order, shows the customer a UPI QR / intent
(or a PhonePe/Paytm PG hosted checkout) and verifies the payment with the
provider. Retailza only asks the gateway for the order status and trusts
nothing the mobile app reports about a payment.

API key/secret stay on the server; they are never sent to the mobile app.
"""
import hashlib
import hmac
import time
from decimal import Decimal, InvalidOperation
from typing import Any, Dict, Optional
from urllib.parse import quote

import httpx

from backend.app.config import settings

WEBHOOK_TOLERANCE_SECONDS = 300


class UpiGatewayError(Exception):
    """Gateway call failed. The message is safe to show to the app user."""


class UpiGatewayNotConfigured(UpiGatewayError):
    pass


def is_configured() -> bool:
    return bool(
        settings.UPI_GATEWAY_BASE_URL.strip()
        and settings.UPI_GATEWAY_API_KEY.strip()
        and settings.UPI_GATEWAY_API_SECRET.strip()
    )


def _api_url(path: str) -> str:
    return settings.UPI_GATEWAY_BASE_URL.strip().rstrip("/") + "/api/v1" + path


def _headers() -> Dict[str, str]:
    return {
        "X-Api-Key": settings.UPI_GATEWAY_API_KEY.strip(),
        "X-Api-Secret": settings.UPI_GATEWAY_API_SECRET.strip(),
        "Accept": "application/json",
    }


def _request(method: str, path: str, json_body: Optional[dict] = None) -> Dict[str, Any]:
    if not is_configured():
        raise UpiGatewayNotConfigured("Online payment is not configured yet. Please contact Retailza support.")

    try:
        response = httpx.request(
            method,
            _api_url(path),
            headers=_headers(),
            json=json_body,
            timeout=settings.UPI_GATEWAY_TIMEOUT_SECONDS,
        )
    except httpx.HTTPError:
        # Never include the URL or credentials in the message.
        raise UpiGatewayError("Payment server is not reachable. Please try again.")

    try:
        body = response.json()
    except ValueError:
        body = None

    if response.status_code >= 400 or not isinstance(body, dict) or body.get("success") is not True:
        if response.status_code in (401, 403):
            raise UpiGatewayError("Payment server rejected Retailza's credentials. Please contact support.")
        if response.status_code == 429:
            raise UpiGatewayError("Too many payment requests. Please wait a minute and try again.")
        if response.status_code == 404:
            raise UpiGatewayError("Payment order was not found.")
        raise UpiGatewayError("Payment server could not process the request. Please try again.")

    data = body.get("data")
    if not isinstance(data, dict):
        raise UpiGatewayError("Payment server returned an invalid response.")
    return data


def create_order(amount: Decimal, client_order_id: str, note: Optional[str] = None,
                 customer_name: Optional[str] = None, customer_mobile: Optional[str] = None) -> Dict[str, Any]:
    """Create a payment order. Returns the gateway's order data."""
    payload: Dict[str, Any] = {
        "amount": f"{Decimal(amount).quantize(Decimal('0.01'))}",
        "client_order_id": client_order_id,
    }
    if note:
        payload["note"] = note[:50]
    if customer_name:
        payload["customer_name"] = customer_name[:100]
    if customer_mobile:
        payload["customer_mobile"] = customer_mobile[:20]
    return _request("POST", "/orders", payload)


def get_order(order_id: str) -> Dict[str, Any]:
    """Fetch the order; the gateway re-checks the provider before answering."""
    return _request("GET", "/orders/" + quote(order_id, safe=""))


def to_amount(value: Any) -> Optional[Decimal]:
    try:
        return Decimal(str(value)).quantize(Decimal("0.01"))
    except (InvalidOperation, TypeError, ValueError):
        return None


def verify_webhook_signature(raw_body: bytes, signature_header: Optional[str], secret: str,
                             tolerance: int = WEBHOOK_TOLERANCE_SECONDS, now: Optional[int] = None) -> bool:
    """
    Verify `X-Signature: t=<unix>,v1=<hex hmac-sha256 of "t.<raw body>">`
    with a replay window, exactly as the gateway signs it.
    """
    if not signature_header or not secret:
        return False

    parts: Dict[str, str] = {}
    for item in signature_header.split(","):
        key, sep, value = item.strip().partition("=")
        if sep:
            parts[key] = value

    timestamp, signature = parts.get("t", ""), parts.get("v1", "")
    if not timestamp.isdigit() or len(signature) != 64:
        return False

    current = int(time.time()) if now is None else now
    if abs(current - int(timestamp)) > tolerance:
        return False

    expected = hmac.new(
        secret.encode("utf-8"),
        timestamp.encode("utf-8") + b"." + raw_body,
        hashlib.sha256,
    ).hexdigest()
    return hmac.compare_digest(expected, signature.lower())
