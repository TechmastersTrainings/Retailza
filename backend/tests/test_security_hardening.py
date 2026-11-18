"""Tests for the security hardening fixes (OTP abuse, khata overpay, paywall, secret, CORS)."""
import pytest

from backend.app.config import settings
from backend.app.utils.security import get_secret_key


def auth(client, mobile="9810000011"):
    otp = client.post("/api/auth/request-otp", json={"identifier": mobile}).json()["debug_otp"]
    tok = client.post("/api/auth/verify-otp", json={"identifier": mobile, "otp_code": otp}).json()["access_token"]
    return {"Authorization": f"Bearer {tok}"}


def setup_shop(client, mobile):
    h = auth(client, mobile)
    r = client.post("/api/shops/setup", json={"shop_name": "Test Shop", "owner_name": "Test Owner"}, headers=h)
    assert r.status_code == 201, r.text
    return h


# ---------------- OTP brute-force lockout ----------------

def test_otp_verify_locks_out_after_max_attempts(client, monkeypatch):
    monkeypatch.setattr(settings, "OTP_MAX_VERIFY_ATTEMPTS", 5)
    client.post("/api/auth/request-otp", json={"identifier": "9810000021"})
    for _ in range(5):
        r = client.post("/api/auth/verify-otp", json={"identifier": "9810000021", "otp_code": "000000"})
        assert r.status_code == 400
    # 6th guess is locked, not another free attempt
    locked = client.post("/api/auth/verify-otp", json={"identifier": "9810000021", "otp_code": "000000"})
    assert locked.status_code == 429


def test_otp_cannot_be_used_after_lockout_even_if_correct(client, monkeypatch):
    monkeypatch.setattr(settings, "OTP_MAX_VERIFY_ATTEMPTS", 3)
    otp = client.post("/api/auth/request-otp", json={"identifier": "9810000022"}).json()["debug_otp"]
    for _ in range(3):
        client.post("/api/auth/verify-otp", json={"identifier": "9810000022", "otp_code": "111111"})
    # correct code now rejected because the code was burned
    r = client.post("/api/auth/verify-otp", json={"identifier": "9810000022", "otp_code": otp})
    assert r.status_code == 429


# ---------------- OTP request throttling ----------------

def test_otp_request_cooldown(client):
    first = client.post("/api/auth/request-otp", json={"identifier": "9810000031"})
    assert first.status_code == 200
    second = client.post("/api/auth/request-otp", json={"identifier": "9810000031"})
    assert second.status_code == 429


def test_otp_request_capped_per_window(client, monkeypatch):
    monkeypatch.setattr(settings, "OTP_RESEND_COOLDOWN_SECONDS", 0)  # ignore cooldown, test the cap
    monkeypatch.setattr(settings, "OTP_MAX_SENDS_PER_WINDOW", 3)
    codes = [client.post("/api/auth/request-otp", json={"identifier": "9810000032"}).status_code for _ in range(5)]
    assert codes.count(200) == 3
    assert codes[-1] == 429


# ---------------- OTP not leaked in production ----------------

def test_debug_otp_hidden_in_production(client, monkeypatch):
    monkeypatch.setattr(settings, "APP_ENV", "production")
    monkeypatch.setattr(settings, "SECRET_KEY", "x" * 40)
    r = client.post("/api/auth/request-otp", json={"identifier": "9810000041"}).json()
    assert "debug_otp" not in r


# ---------------- Khata overpay ----------------

def test_credit_payment_cannot_exceed_balance(client):
    h = setup_shop(client, "9810000051")
    cust = client.post("/api/customers", json={"name": "Ramesh"}, headers=h).json()
    prod = client.post("/api/products", json={"name": "Rice", "selling_price": 100, "stock_quantity": 10}, headers=h).json()
    client.post("/api/sales/checkout", json={"customer_id": cust["id"], "payment_mode": "CREDIT",
                "items": [{"product_id": prod["id"], "quantity": 1}]}, headers=h)  # balance 100
    over = client.post(f"/api/customers/{cust['id']}/credit-payment", json={"amount": "500.00"}, headers=h)
    assert over.status_code == 400
    bal = client.get(f"/api/customers/{cust['id']}", headers=h).json()["balance"]
    assert float(bal) == 100.0  # unchanged, never negative
    ok = client.post(f"/api/customers/{cust['id']}/credit-payment", json={"amount": "40.00"}, headers=h)
    assert ok.status_code == 200
    assert float(ok.json()["balance"]) == 60.0


# ---------------- Subscription paywall flag ----------------

def test_write_endpoints_open_when_enforcement_off(client):
    h = setup_shop(client, "9810000061")
    r = client.post("/api/products", json={"name": "Free", "selling_price": 10}, headers=h)
    assert r.status_code == 201  # PENDING subscription, but flag off


def test_write_endpoints_blocked_when_enforcement_on(client, monkeypatch):
    h = setup_shop(client, "9810000062")  # subscription starts PENDING
    monkeypatch.setattr(settings, "ENFORCE_SUBSCRIPTION", True)
    blocked = client.post("/api/products", json={"name": "Paid", "selling_price": 10}, headers=h)
    assert blocked.status_code == 402
    # read endpoints remain open
    assert client.get("/api/products", headers=h).status_code == 200


# ---------------- Secret key handling ----------------

def test_dev_secret_used_when_unset_and_not_production(monkeypatch):
    monkeypatch.setattr(settings, "SECRET_KEY", "")
    monkeypatch.setattr(settings, "APP_ENV", "development")
    assert get_secret_key() == "dev-insecure-secret-not-for-production"


def test_missing_secret_in_production_raises(monkeypatch):
    monkeypatch.setattr(settings, "SECRET_KEY", "")
    monkeypatch.setattr(settings, "APP_ENV", "production")
    with pytest.raises(RuntimeError):
        get_secret_key()


def test_shop_fields_length_bounded(client):
    h = auth(client, "9810000071")
    r = client.post("/api/shops/setup", json={"shop_name": "S", "owner_name": "O", "city": "C" * 500}, headers=h)
    assert r.status_code == 422
