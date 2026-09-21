import pytest
from datetime import datetime, timedelta
from backend.app.models import User, Shop, Subscription, SystemAnnouncement
from backend.app.utils.security import hash_password


@pytest.fixture
def super_admin_user(db_session):
    """Seed a default Super Admin account for testing."""
    admin = User(
        email="admin@retailza.com",
        mobile_number="9999999999",
        name="Retailza Super Admin",
        role="SUPER_ADMIN",
        hashed_password=hash_password("Admin@Retailza2026"),
        is_active=True
    )
    db_session.add(admin)
    db_session.commit()
    db_session.refresh(admin)
    return admin


def test_mobile_otp_request_and_verify(client):
    """Test OTP request and verification using 10-digit mobile number."""
    # 1. Request OTP
    req_res = client.post("/api/auth/request-otp", json={"identifier": "9876543210"})
    assert req_res.status_code == 200
    req_json = req_res.json()
    assert "debug_otp" in req_json
    debug_otp = req_json["debug_otp"]

    # 2. Verify OTP
    verify_res = client.post("/api/auth/verify-otp", json={
        "identifier": "9876543210",
        "otp_code": debug_otp
    })
    assert verify_res.status_code == 200
    data = verify_res.json()
    assert "access_token" in data
    assert data["user"]["mobile_number"] == "9876543210"
    assert data["user"]["role"] == "OWNER"


def test_email_otp_request_and_verify(client):
    """Test OTP request and verification using email address."""
    # 1. Request OTP
    req_res = client.post("/api/auth/request-otp", json={"identifier": "kirana_owner@retailza.com"})
    assert req_res.status_code == 200
    req_json = req_res.json()
    assert "debug_otp" in req_json
    debug_otp = req_json["debug_otp"]

    # 2. Verify OTP
    verify_res = client.post("/api/auth/verify-otp", json={
        "identifier": "kirana_owner@retailza.com",
        "otp_code": debug_otp
    })
    assert verify_res.status_code == 200
    data = verify_res.json()
    assert "access_token" in data
    assert data["user"]["email"] == "kirana_owner@retailza.com"
    assert data["user"]["role"] == "OWNER"


def test_super_admin_password_login(client, super_admin_user):
    """Test password-based login using email identifier."""
    res = client.post("/api/auth/login-password", json={
        "identifier": "admin@retailza.com",
        "password": "Admin@Retailza2026"
    })
    assert res.status_code == 200
    data = res.json()
    assert "access_token" in data
    assert data["user"]["role"] == "SUPER_ADMIN"
    assert data["user"]["email"] == "admin@retailza.com"


def test_super_admin_mobile_password_login(client, super_admin_user):
    """Test password-based login using 10-digit mobile identifier."""
    res = client.post("/api/auth/login-password", json={
        "identifier": "9999999999",
        "password": "Admin@Retailza2026"
    })
    assert res.status_code == 200
    data = res.json()
    assert "access_token" in data
    assert data["user"]["role"] == "SUPER_ADMIN"


def test_password_login_invalid_credentials(client, super_admin_user):
    """Test password-based login rejection on invalid password."""
    res = client.post("/api/auth/login-password", json={
        "identifier": "admin@retailza.com",
        "password": "WrongPassword123"
    })
    assert res.status_code == 401
    assert "Invalid password" in res.json()["detail"]


def test_admin_metrics_forbidden_for_regular_owner(client):
    """Test that regular Kirana store owners are rejected from /api/admin/metrics."""
    # Authenticate as owner
    req_res = client.post("/api/auth/request-otp", json={"identifier": "9876543210"})
    debug_otp = req_res.json().get("debug_otp", "123456")
    verify_res = client.post("/api/auth/verify-otp", json={"identifier": "9876543210", "otp_code": debug_otp})
    owner_token = verify_res.json()["access_token"]

    # Try accessing admin endpoint
    res = client.get(
        "/api/admin/metrics",
        headers={"Authorization": f"Bearer {owner_token}"}
    )
    assert res.status_code == 403
    assert "Super Admin" in res.json()["detail"]


def test_admin_metrics_and_shops_success(client, super_admin_user, db_session):
    """Test metrics and shop directory queries for authenticated Super Admin."""
    # Seed a shopkeeper with a shop
    owner = User(mobile_number="9111111111", name="Ramesh Kumar", role="OWNER")
    db_session.add(owner)
    db_session.flush()

    shop = Shop(
        owner_id=owner.id,
        shop_name="Ramesh Kirana",
        owner_name="Ramesh Kumar",
        city="Jaipur"
    )
    db_session.add(shop)
    db_session.flush()

    sub = Subscription(
        shop_id=shop.id,
        plan_name="basic",
        amount=49.00,
        status="ACTIVE",
        start_date=datetime.utcnow(),
        end_date=datetime.utcnow() + timedelta(days=30)
    )
    db_session.add(sub)
    db_session.commit()

    # Log in as admin
    login_res = client.post("/api/auth/login-password", json={
        "identifier": "admin@retailza.com",
        "password": "Admin@Retailza2026"
    })
    admin_token = login_res.json()["access_token"]

    # 1. Check /api/admin/metrics
    metrics_res = client.get(
        "/api/admin/metrics",
        headers={"Authorization": f"Bearer {admin_token}"}
    )
    assert metrics_res.status_code == 200
    m = metrics_res.json()
    assert m["total_shops"] >= 1
    assert m["active_subscriptions"] >= 1
    assert float(m["monthly_recurring_revenue"]) >= 49.0

    # 2. Check /api/admin/shops
    shops_res = client.get(
        "/api/admin/shops?q=Ramesh",
        headers={"Authorization": f"Bearer {admin_token}"}
    )
    assert shops_res.status_code == 200
    shops_list = shops_res.json()
    assert len(shops_list) >= 1
    assert shops_list[0]["shop_name"] == "Ramesh Kirana"
    assert shops_list[0]["subscription_status"] == "ACTIVE"


def test_admin_extend_and_send_reminder(client, super_admin_user, db_session):
    """Test manual subscription extension and automated reminder dispatch."""
    owner = User(mobile_number="9222222222", name="Suresh Store", role="OWNER")
    db_session.add(owner)
    db_session.flush()

    shop = Shop(owner_id=owner.id, shop_name="Suresh General Store", owner_name="Suresh")
    db_session.add(shop)
    db_session.flush()

    sub = Subscription(
        shop_id=shop.id,
        status="EXPIRED",
        end_date=datetime.utcnow() - timedelta(days=2)
    )
    db_session.add(sub)
    db_session.commit()

    # Admin login
    login_res = client.post("/api/auth/login-password", json={
        "identifier": "admin@retailza.com",
        "password": "Admin@Retailza2026"
    })
    admin_token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {admin_token}"}

    # 1. Send Renewal Reminder
    rem_res = client.post(
        "/api/admin/reminders/send",
        headers=headers,
        json={"shop_id": shop.id, "channel": "WHATSAPP"}
    )
    assert rem_res.status_code == 200
    rem_data = rem_res.json()
    assert rem_data["success"] is True
    assert "Suresh General Store" in rem_data["message"]

    # 2. Extend subscription by 30 days
    ext_res = client.post(
        "/api/admin/subscriptions/extend",
        headers=headers,
        json={"shop_id": shop.id, "days": 30}
    )
    assert ext_res.status_code == 200
    ext_data = ext_res.json()
    assert ext_data["success"] is True
    assert ext_data["status"] == "ACTIVE"


def test_announcement_broadcast_and_mobile_delivery(client, super_admin_user):
    """Test announcement creation by Super Admin and public mobile retrieval."""
    # Admin login
    login_res = client.post("/api/auth/login-password", json={
        "identifier": "admin@retailza.com",
        "password": "Admin@Retailza2026"
    })
    admin_token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {admin_token}"}

    # 1. Super Admin creates announcement
    create_res = client.post(
        "/api/admin/announcements",
        headers=headers,
        json={
            "title": "GST E-Invoicing Released!",
            "message": "You can now print GST bills with one click directly from POS checkout.",
            "tag": "FEATURE"
        }
    )
    assert create_res.status_code == 200
    announcement_id = create_res.json()["id"]

    # 2. Public mobile endpoint retrieves announcement without any token
    pub_res = client.get("/api/announcements/latest")
    assert pub_res.status_code == 200
    latest = pub_res.json()
    assert latest is not None
    assert latest["title"] == "GST E-Invoicing Released!"
    assert latest["tag"] == "FEATURE"

    # 3. Super Admin deletes announcement
    del_res = client.delete(f"/api/admin/announcements/{announcement_id}", headers=headers)
    assert del_res.status_code == 200

    # 4. Public mobile endpoint now returns None
    pub_res2 = client.get("/api/announcements/latest")
    assert pub_res2.status_code == 200
    assert pub_res2.json() is None


def test_admin_static_website_served(client):
    """Test that the Super Admin website HTML, CSS, and JS are properly served at /admin."""
    # Test index.html served at /admin/
    res = client.get("/admin/")
    assert res.status_code == 200
    assert "Retailza Super Admin" in res.text
    assert "admin.css" in res.text
    assert "admin.js" in res.text

    # Test CSS file
    css_res = client.get("/admin/admin.css")
    assert css_res.status_code == 200

    # Test JS file
    js_res = client.get("/admin/admin.js")
    assert js_res.status_code == 200

