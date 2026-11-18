"""Subscription payments through the self-hosted UPI Gateway."""
import hashlib
import hmac
import json
import time
from datetime import timedelta

import httpx
import pytest

from backend.app.config import settings
from backend.app.models import User, Shop, Subscription, SubscriptionPayment
from backend.app.utils import upi_gateway
from backend.app.utils.security import create_access_token

WEBHOOK_SECRET = "whsec_test_retailza"


def make_shop(db_session, mobile="9000000001", name="Gateway Test Store"):
    user = User(mobile_number=mobile, name="Owner", role="OWNER")
    db_session.add(user)
    db_session.flush()
    shop = Shop(owner_id=user.id, shop_name=name, owner_name="Owner", category="Provision Store")
    db_session.add(shop)
    db_session.commit()
    token = create_access_token(data={"sub": str(user.id), "shop_id": shop.id})
    return shop, {"Authorization": f"Bearer {token}"}


def sign(body: bytes, secret=WEBHOOK_SECRET, timestamp=None) -> str:
    ts = str(int(time.time()) if timestamp is None else timestamp)
    sig = hmac.new(secret.encode(), ts.encode() + b"." + body, hashlib.sha256).hexdigest()
    return f"t={ts},v1={sig}"


def webhook(client, order_id, event="order.paid", secret=WEBHOOK_SECRET, timestamp=None):
    body = json.dumps({"event_id": "evt-1", "event": event, "data": {"order_id": order_id}}).encode()
    return client.post(
        "/api/subscriptions/gateway-webhook",
        content=body,
        headers={"Content-Type": "application/json", "X-Signature": sign(body, secret, timestamp)},
    )


@pytest.fixture
def webhook_secret(monkeypatch):
    monkeypatch.setattr(settings, "UPI_GATEWAY_WEBHOOK_SECRET", WEBHOOK_SECRET)


def create_order(client, headers):
    res = client.post("/api/subscriptions/create-order", headers=headers)
    assert res.status_code == 200, res.text
    return res.json()


def status(client, headers, order_id):
    return client.get(f"/api/subscriptions/payments/{order_id}/status", headers=headers)


def test_create_order_returns_gateway_payment_details(client, db_session, fake_gateway):
    _, headers = make_shop(db_session)
    order = create_order(client, headers)

    assert order["order_id"] in fake_gateway.orders
    assert order["payment_url"] == f"https://pay.example.test/pay/{order['order_id']}"
    assert order["upi_intent"].startswith("upi://pay")
    assert order["test"] is False
    assert fake_gateway.orders[order["order_id"]]["client_order_id"].startswith("RTZSUB-")

    payment = db_session.query(SubscriptionPayment).filter_by(order_id=order["order_id"]).one()
    assert payment.status == "PENDING"
    assert payment.payment_method == "UPI_GATEWAY"


def test_paid_order_activates_once_and_repeat_checks_do_not_extend(client, db_session, fake_gateway, webhook_secret):
    shop, headers = make_shop(db_session)
    order = create_order(client, headers)
    fake_gateway.set(order["order_id"], status="paid", utr="412345678901")

    first = status(client, headers, order["order_id"]).json()
    assert first["status"] == "SUCCESS"
    assert first["subscription"]["is_active"] is True
    end_date = first["subscription"]["end_date"]

    # Polling again and a late webhook delivery must not add another 30 days.
    assert status(client, headers, order["order_id"]).json()["subscription"]["end_date"] == end_date
    assert webhook(client, order["order_id"]).status_code == 200
    assert status(client, headers, order["order_id"]).json()["subscription"]["end_date"] == end_date

    payment = db_session.query(SubscriptionPayment).filter_by(order_id=order["order_id"]).one()
    assert payment.payment_id == "412345678901"


def test_second_paid_order_extends_active_subscription(client, db_session, fake_gateway):
    shop, headers = make_shop(db_session)
    first = create_order(client, headers)
    fake_gateway.set(first["order_id"], status="paid", utr="412345678901")
    status(client, headers, first["order_id"])
    end_1 = db_session.query(Subscription).filter_by(shop_id=shop.id).one().end_date

    second = create_order(client, headers)
    fake_gateway.set(second["order_id"], status="paid", utr="412345678902")
    status(client, headers, second["order_id"])
    db_session.expire_all()
    end_2 = db_session.query(Subscription).filter_by(shop_id=shop.id).one().end_date
    assert end_2 - end_1 == timedelta(days=30)


def test_pending_and_review_do_not_activate(client, db_session, fake_gateway):
    _, headers = make_shop(db_session)
    order = create_order(client, headers)

    assert status(client, headers, order["order_id"]).json()["status"] == "PENDING"
    fake_gateway.set(order["order_id"], status="review")
    res = status(client, headers, order["order_id"]).json()
    assert res["status"] == "REVIEW"
    assert res["subscription"]["is_active"] is False


def test_amount_mismatch_never_activates(client, db_session, fake_gateway):
    _, headers = make_shop(db_session)
    order = create_order(client, headers)
    fake_gateway.set(order["order_id"], status="paid", amount="1.00", utr="412345678903")

    res = status(client, headers, order["order_id"]).json()
    assert res["status"] == "FAILED"
    assert res["subscription"]["is_active"] is False


def test_sandbox_payment_never_activates_by_default(client, db_session, fake_gateway):
    _, headers = make_shop(db_session)
    order = create_order(client, headers)
    fake_gateway.set(order["order_id"], status="paid", environment="sandbox", test=True, utr="TESTABC")

    res = status(client, headers, order["order_id"]).json()
    assert res["status"] == "FAILED"
    assert res["subscription"]["is_active"] is False


def test_create_order_rejects_sandbox_gateway_keys_by_default(client, db_session, fake_gateway, monkeypatch):
    _, headers = make_shop(db_session)
    original = fake_gateway.create_order

    def sandbox_order(*args, **kwargs):
        order = original(*args, **kwargs)
        fake_gateway.set(order["order_id"], environment="sandbox", test=True)
        return dict(fake_gateway.orders[order["order_id"]])

    monkeypatch.setattr(upi_gateway, "create_order", sandbox_order)
    assert client.post("/api/subscriptions/create-order", headers=headers).status_code == 502


def test_expired_order_later_paid_is_still_honoured(client, db_session, fake_gateway):
    _, headers = make_shop(db_session)
    order = create_order(client, headers)
    fake_gateway.set(order["order_id"], status="expired")
    assert status(client, headers, order["order_id"]).json()["status"] == "EXPIRED"

    fake_gateway.set(order["order_id"], status="paid", utr="412345678904")
    res = status(client, headers, order["order_id"]).json()
    assert res["status"] == "SUCCESS"
    assert res["subscription"]["is_active"] is True


def test_other_shop_cannot_read_or_use_order(client, db_session, fake_gateway):
    _, headers_a = make_shop(db_session, mobile="9000000001", name="Shop A")
    _, headers_b = make_shop(db_session, mobile="9000000002", name="Shop B")
    order = create_order(client, headers_a)
    fake_gateway.set(order["order_id"], status="paid", utr="412345678905")

    assert status(client, headers_b, order["order_id"]).status_code == 404
    assert client.get("/api/subscriptions/current", headers=headers_b).json()["is_active"] is False


def test_gateway_outage_keeps_status_and_returns_message(client, db_session, fake_gateway):
    _, headers = make_shop(db_session)
    order = create_order(client, headers)
    fake_gateway.unavailable = True

    res = status(client, headers, order["order_id"])
    assert res.status_code == 200
    assert res.json()["status"] == "PENDING"
    assert "not reachable" in res.json()["message"]

    assert client.post("/api/subscriptions/create-order", headers=headers).status_code == 502


def test_create_order_when_gateway_not_configured(client, db_session, monkeypatch):
    _, headers = make_shop(db_session)
    monkeypatch.setattr(settings, "UPI_GATEWAY_BASE_URL", "")
    res = client.post("/api/subscriptions/create-order", headers=headers)
    assert res.status_code == 503


def test_webhook_activates_subscription_without_app(client, db_session, fake_gateway, webhook_secret):
    shop, headers = make_shop(db_session)
    order = create_order(client, headers)
    fake_gateway.set(order["order_id"], status="paid", utr="412345678906")

    res = webhook(client, order["order_id"])
    assert res.status_code == 200
    assert res.json()["payment_status"] == "SUCCESS"
    assert client.get("/api/subscriptions/current", headers=headers).json()["is_active"] is True


def test_webhook_payload_alone_cannot_activate(client, db_session, fake_gateway, webhook_secret):
    """A signed order.paid is re-checked against the gateway API before activation."""
    _, headers = make_shop(db_session)
    order = create_order(client, headers)  # gateway still says pending

    res = webhook(client, order["order_id"], event="order.paid")
    assert res.status_code == 200
    assert res.json()["payment_status"] == "PENDING"
    assert client.get("/api/subscriptions/current", headers=headers).json()["is_active"] is False


def test_webhook_rejects_bad_signatures(client, db_session, fake_gateway, webhook_secret):
    _, headers = make_shop(db_session)
    order = create_order(client, headers)
    fake_gateway.set(order["order_id"], status="paid", utr="412345678907")

    assert webhook(client, order["order_id"], secret="wrong-secret").status_code == 401
    assert webhook(client, order["order_id"], timestamp=int(time.time()) - 600).status_code == 401
    unsigned = client.post("/api/subscriptions/gateway-webhook", json={"data": {"order_id": order["order_id"]}})
    assert unsigned.status_code == 401
    assert client.get("/api/subscriptions/current", headers=headers).json()["is_active"] is False


def test_webhook_rejected_when_secret_not_configured(client, db_session, fake_gateway, monkeypatch):
    monkeypatch.setattr(settings, "UPI_GATEWAY_WEBHOOK_SECRET", "")
    body = b'{"data":{"order_id":"X"}}'
    res = client.post("/api/subscriptions/gateway-webhook", content=body,
                      headers={"X-Signature": sign(body, secret="")})
    assert res.status_code == 401


def test_webhook_unknown_order_ignored_and_outage_retried(client, db_session, fake_gateway, webhook_secret):
    assert webhook(client, "ORDUNKNOWN").json()["status"] == "ignored"

    _, headers = make_shop(db_session)
    order = create_order(client, headers)
    fake_gateway.unavailable = True
    assert webhook(client, order["order_id"]).status_code == 503


def test_old_razorpay_mock_signature_bypass_is_gone(client, db_session):
    _, headers = make_shop(db_session)
    res = client.post("/api/subscriptions/verify-payment", json={
        "razorpay_order_id": "order_x", "razorpay_payment_id": "pay_x",
        "razorpay_signature": "mock_valid_signature",
    }, headers=headers)
    assert res.status_code in (404, 405)
    assert client.get("/api/subscriptions/current", headers=headers).json()["is_active"] is False


# --- HTTP client (no real network) ------------------------------------------------

@pytest.fixture
def configured(monkeypatch):
    monkeypatch.setattr(settings, "UPI_GATEWAY_BASE_URL", "https://pay.example.test/")
    monkeypatch.setattr(settings, "UPI_GATEWAY_API_KEY", "key_abc")
    monkeypatch.setattr(settings, "UPI_GATEWAY_API_SECRET", "sec_abc")


def test_client_sends_credentials_and_parses_order(configured, monkeypatch):
    seen = {}

    def fake_request(method, url, headers=None, json=None, timeout=None):
        seen.update(method=method, url=url, headers=headers, json=json)
        return httpx.Response(201, json={"success": True, "data": {"order_id": "ORD1", "status": "pending"}})

    monkeypatch.setattr(upi_gateway.httpx, "request", fake_request)
    data = upi_gateway.create_order(amount=49, client_order_id="RTZSUB-1-abc", note="Retailza 30 day plan")

    assert data["order_id"] == "ORD1"
    assert seen["method"] == "POST"
    assert seen["url"] == "https://pay.example.test/api/v1/orders"
    assert seen["headers"]["X-Api-Key"] == "key_abc"
    assert seen["headers"]["X-Api-Secret"] == "sec_abc"
    assert seen["json"] == {"amount": "49.00", "client_order_id": "RTZSUB-1-abc", "note": "Retailza 30 day plan"}


def test_client_maps_errors_without_leaking_details(configured, monkeypatch):
    monkeypatch.setattr(upi_gateway.httpx, "request",
                        lambda *a, **k: httpx.Response(401, json={"message": "Invalid key"}))
    with pytest.raises(upi_gateway.UpiGatewayError, match="credentials"):
        upi_gateway.get_order("ORD1")

    def boom(*a, **k):
        raise httpx.ConnectError("connection refused to https://pay.example.test")

    monkeypatch.setattr(upi_gateway.httpx, "request", boom)
    with pytest.raises(upi_gateway.UpiGatewayError) as err:
        upi_gateway.get_order("ORD1")
    assert "pay.example.test" not in str(err.value)


def test_order_id_is_url_encoded(configured, monkeypatch):
    seen = {}

    def fake_request(method, url, **kwargs):
        seen["url"] = url
        return httpx.Response(200, json={"success": True, "data": {"order_id": "x"}})

    monkeypatch.setattr(upi_gateway.httpx, "request", fake_request)
    upi_gateway.get_order("../admin?x=1")
    assert seen["url"] == "https://pay.example.test/api/v1/orders/..%2Fadmin%3Fx%3D1"


def test_signature_verification_unit():
    body = b'{"event":"order.paid"}'
    now = 1_800_000_000
    header = sign(body, timestamp=now)

    assert upi_gateway.verify_webhook_signature(body, header, WEBHOOK_SECRET, now=now)
    assert not upi_gateway.verify_webhook_signature(body + b" ", header, WEBHOOK_SECRET, now=now)
    assert not upi_gateway.verify_webhook_signature(body, header, WEBHOOK_SECRET, now=now + 301)
    assert not upi_gateway.verify_webhook_signature(body, None, WEBHOOK_SECRET, now=now)
    assert not upi_gateway.verify_webhook_signature(body, "garbage", WEBHOOK_SECRET, now=now)
