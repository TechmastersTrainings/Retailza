"""Direct-UPI subscription billing: pay into Retailza's own UPI ID, confirm by UTR."""
from datetime import timedelta
from urllib.parse import parse_qs, urlparse

import pytest

from backend.app.config import settings
from backend.app.models import User, Shop, Subscription, SubscriptionPayment
from backend.app.utils.security import create_access_token


def make_shop(db_session, mobile="9000000001", name="UPI Test Store"):
    user = User(mobile_number=mobile, name="Owner", role="OWNER")
    db_session.add(user)
    db_session.flush()
    shop = Shop(owner_id=user.id, shop_name=name, owner_name="Owner", category="Provision Store")
    db_session.add(shop)
    db_session.commit()
    token = create_access_token(data={"sub": str(user.id), "shop_id": shop.id})
    return shop, {"Authorization": f"Bearer {token}"}


def make_admin(db_session, mobile="9000009999"):
    user = User(mobile_number=mobile, name="Admin", role="SUPER_ADMIN",
                email="techmastersinnovations@gmail.com")
    db_session.add(user)
    db_session.commit()
    token = create_access_token(data={"sub": str(user.id)})
    return {"Authorization": f"Bearer {token}"}


def create_order(client, headers):
    res = client.post("/api/subscriptions/create-order", headers=headers)
    assert res.status_code == 200, res.text
    return res.json()


def submit_utr(client, headers, order_id, utr):
    return client.post(f"/api/subscriptions/payments/{order_id}/submit-utr",
                       json={"utr": utr}, headers=headers)


def status(client, headers, order_id):
    return client.get(f"/api/subscriptions/payments/{order_id}/status", headers=headers)


def test_create_order_returns_own_upi_details(client, db_session):
    _, headers = make_shop(db_session)
    order = create_order(client, headers)

    assert order["upi_id"] == "retailza@okhdfcbank"
    assert order["payee_name"] == "Retailza"
    q = parse_qs(urlparse(order["upi_intent"]).query)
    assert q["pa"] == ["retailza@okhdfcbank"]
    assert q["am"] == ["49.00"]
    assert q["cu"] == ["INR"]
    assert q["tr"] == [order["order_id"]]

    payment = db_session.query(SubscriptionPayment).filter_by(order_id=order["order_id"]).one()
    assert payment.status == "PENDING"
    assert payment.payment_method == "UPI_DIRECT"


def test_create_order_503_when_upi_not_configured(client, db_session, monkeypatch):
    _, headers = make_shop(db_session)
    monkeypatch.setattr(settings, "SUBSCRIPTION_UPI_ID", "")
    assert client.post("/api/subscriptions/create-order", headers=headers).status_code == 503


def test_valid_utr_activates_subscription(client, db_session):
    _, headers = make_shop(db_session)
    order = create_order(client, headers)

    assert status(client, headers, order["order_id"]).json()["status"] == "PENDING"

    res = submit_utr(client, headers, order["order_id"], "412345678901")
    assert res.status_code == 200
    body = res.json()
    assert body["status"] == "SUCCESS"
    assert body["subscription"]["is_active"] is True
    assert body["subscription"]["end_date"] is not None

    payment = db_session.query(SubscriptionPayment).filter_by(order_id=order["order_id"]).one()
    assert payment.payment_id == "412345678901"


@pytest.mark.parametrize("bad", ["", "12345", "41234567890a", "abcdefghijkl", "4123456789012345"])
def test_invalid_utr_rejected(client, db_session, bad):
    _, headers = make_shop(db_session)
    order = create_order(client, headers)
    res = submit_utr(client, headers, order["order_id"], bad)
    assert res.status_code in (400, 422)
    assert client.get("/api/subscriptions/current", headers=headers).json()["is_active"] is False


def test_spaces_in_utr_are_tolerated(client, db_session):
    _, headers = make_shop(db_session)
    order = create_order(client, headers)
    # 12 digits with spaces (as some apps display them) normalizes to valid
    res = submit_utr(client, headers, order["order_id"], " 4123 4567 8901 ")
    assert res.status_code == 200
    assert res.json()["status"] == "SUCCESS"


def test_resubmitting_after_success_does_not_extend(client, db_session):
    shop, headers = make_shop(db_session)
    order = create_order(client, headers)
    first = submit_utr(client, headers, order["order_id"], "412345678901").json()
    end_1 = first["subscription"]["end_date"]

    again = submit_utr(client, headers, order["order_id"], "412345678901").json()
    assert again["status"] == "SUCCESS"
    assert again["subscription"]["end_date"] == end_1


def test_same_utr_cannot_pay_two_orders(client, db_session):
    _, headers_a = make_shop(db_session, mobile="9000000001", name="Shop A")
    _, headers_b = make_shop(db_session, mobile="9000000002", name="Shop B")

    order_a = create_order(client, headers_a)
    assert submit_utr(client, headers_a, order_a["order_id"], "412345678901").json()["status"] == "SUCCESS"

    order_b = create_order(client, headers_b)
    clash = submit_utr(client, headers_b, order_b["order_id"], "412345678901")
    assert clash.status_code == 409
    assert client.get("/api/subscriptions/current", headers=headers_b).json()["is_active"] is False


def test_second_payment_extends_active_subscription(client, db_session):
    shop, headers = make_shop(db_session)
    o1 = create_order(client, headers)
    submit_utr(client, headers, o1["order_id"], "412345678901")
    end_1 = db_session.query(Subscription).filter_by(shop_id=shop.id).one().end_date

    o2 = create_order(client, headers)
    submit_utr(client, headers, o2["order_id"], "412345678902")
    db_session.expire_all()
    end_2 = db_session.query(Subscription).filter_by(shop_id=shop.id).one().end_date
    assert end_2 - end_1 == timedelta(days=30)


def test_review_mode_waits_for_admin_then_verify_activates(client, db_session, monkeypatch):
    monkeypatch.setattr(settings, "SUBSCRIPTION_AUTO_ACTIVATE_ON_UTR", False)
    shop, headers = make_shop(db_session)
    order = create_order(client, headers)

    res = submit_utr(client, headers, order["order_id"], "412345678901").json()
    assert res["status"] == "REVIEW"
    assert res["subscription"]["is_active"] is False

    payment = db_session.query(SubscriptionPayment).filter_by(order_id=order["order_id"]).one()
    admin_h = make_admin(db_session)
    ok = client.post(f"/api/admin/subscription-payments/{payment.id}/verify", headers=admin_h)
    assert ok.status_code == 200
    assert client.get("/api/subscriptions/current", headers=headers).json()["is_active"] is True


def test_admin_can_list_and_reject_revokes_activation(client, db_session):
    shop, headers = make_shop(db_session)
    order = create_order(client, headers)
    submit_utr(client, headers, order["order_id"], "412345678901")
    assert client.get("/api/subscriptions/current", headers=headers).json()["is_active"] is True

    admin_h = make_admin(db_session)
    listing = client.get("/api/admin/subscription-payments", headers=admin_h)
    assert listing.status_code == 200
    rows = listing.json()
    assert len(rows) == 1
    assert rows[0]["utr"] == "412345678901"
    payment_id = rows[0]["id"]

    rej = client.post(f"/api/admin/subscription-payments/{payment_id}/reject", headers=admin_h)
    assert rej.status_code == 200
    assert rej.json()["revoked_activation"] is True
    assert client.get("/api/subscriptions/current", headers=headers).json()["is_active"] is False


def test_non_admin_cannot_manage_payments(client, db_session):
    shop, headers = make_shop(db_session)
    order = create_order(client, headers)
    submit_utr(client, headers, order["order_id"], "412345678901")
    assert client.get("/api/admin/subscription-payments", headers=headers).status_code == 403


def test_other_shop_cannot_use_order(client, db_session):
    _, headers_a = make_shop(db_session, mobile="9000000001", name="Shop A")
    _, headers_b = make_shop(db_session, mobile="9000000002", name="Shop B")
    order = create_order(client, headers_a)

    assert status(client, headers_b, order["order_id"]).status_code == 404
    assert submit_utr(client, headers_b, order["order_id"], "412345678901").status_code == 404


def test_old_razorpay_mock_signature_bypass_is_gone(client, db_session):
    _, headers = make_shop(db_session)
    res = client.post("/api/subscriptions/verify-payment", json={
        "razorpay_order_id": "order_x", "razorpay_payment_id": "pay_x",
        "razorpay_signature": "mock_valid_signature",
    }, headers=headers)
    assert res.status_code in (404, 405)
    assert client.get("/api/subscriptions/current", headers=headers).json()["is_active"] is False
