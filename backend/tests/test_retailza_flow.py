import pytest
from decimal import Decimal
from fastapi import status


def get_authenticated_client(client, mobile="9876543210"):
    """Helper to register/login a user and return auth headers."""
    # 1. Request OTP
    res_otp = client.post("/api/auth/request-otp", json={"mobile_number": mobile})
    assert res_otp.status_code == status.HTTP_200_OK
    otp_code = res_otp.json().get("debug_otp", "123456")

    # 2. Verify OTP
    res_verify = client.post("/api/auth/verify-otp", json={
        "mobile_number": mobile,
        "otp_code": otp_code
    })
    assert res_verify.status_code == status.HTTP_200_OK
    data = res_verify.json()
    token = data["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_root_and_health(client):
    res_root = client.get("/")
    assert res_root.status_code == 200
    assert res_root.json()["status"] == "online"
    assert "TechMasters Innovations" in res_root.json().get("company", "")

    res_health = client.get("/api/health")
    assert res_health.status_code == 200
    assert res_health.json()["status"] == "healthy"

    # Legal endpoints
    res_privacy = client.get("/privacy")
    assert res_privacy.status_code == 200
    assert "Privacy Policy" in res_privacy.text
    assert "TechMasters Innovations Private Limited" in res_privacy.text

    res_terms = client.get("/terms")
    assert res_terms.status_code == 200
    assert "Terms & Conditions" in res_terms.text
    assert "TechMasters Innovations Private Limited" in res_terms.text

    res_legal = client.get("/api/legal/info")
    assert res_legal.status_code == 200
    data = res_legal.json()
    assert data["brand_name"] == "Retailza"
    assert data["company_name"] == "TechMasters Innovations Private Limited"


def test_auth_otp_flow(client):
    mobile = "9988776655"
    # Request OTP
    req = client.post("/api/auth/request-otp", json={"mobile_number": mobile})
    assert req.status_code == 200
    data = req.json()
    assert "expires_in_minutes" in data
    debug_otp = data.get("debug_otp", "123456")

    # Invalid OTP attempt
    inv = client.post("/api/auth/verify-otp", json={"mobile_number": mobile, "otp_code": "000000"})
    assert inv.status_code == 400

    # Valid OTP
    verify = client.post("/api/auth/verify-otp", json={"mobile_number": mobile, "otp_code": debug_otp})
    assert verify.status_code == 200
    tokens = verify.json()
    assert "access_token" in tokens
    assert "refresh_token" in tokens
    assert tokens["user"]["mobile_number"] == mobile

    # Test Refresh Token
    ref = client.post("/api/auth/refresh-token", json={"refresh_token": tokens["refresh_token"]})
    assert ref.status_code == 200
    assert "access_token" in ref.json()

    # Get Me profile
    headers = {"Authorization": f"Bearer {tokens['access_token']}"}
    me = client.get("/api/auth/me", headers=headers)
    assert me.status_code == 200
    assert me.json()["user"]["mobile_number"] == mobile


def test_shop_setup_and_subscription_flow(client):
    headers = get_authenticated_client(client, mobile="9123456780")

    # 1. Setup Shop
    shop_payload = {
        "shop_name": "Sharma Kirana Store",
        "owner_name": "Satish Sharma",
        "address": "Shop 4, Main Market, MG Road",
        "city": "Indore",
        "state": "Madhya Pradesh",
        "pincode": "452001"
    }
    res_shop = client.post("/api/shops/setup", json=shop_payload, headers=headers)
    assert res_shop.status_code == 201
    shop_data = res_shop.json()
    assert shop_data["shop_name"] == "Sharma Kirana Store"
    assert shop_data["owner_name"] == "Satish Sharma"

    # 2. Duplicate Setup Rejected
    dup_res = client.post("/api/shops/setup", json=shop_payload, headers=headers)
    assert dup_res.status_code == 400

    # 3. Check Subscription initially PENDING
    res_sub = client.get("/api/subscriptions/current", headers=headers)
    assert res_sub.status_code == 200
    sub_data = res_sub.json()
    assert sub_data["status"] == "PENDING"
    assert Decimal(str(sub_data["amount"])) == Decimal("49.00")
    assert sub_data["is_active"] is False

    # 4. Create Subscription Order (₹49)
    res_order = client.post("/api/subscriptions/create-order", headers=headers)
    assert res_order.status_code == 200
    order_data = res_order.json()
    assert "order_id" in order_data
    assert Decimal(str(order_data["amount"])) == Decimal("49.00")

    # 5. Invalid Signature Rejected
    invalid_pay = {
        "razorpay_order_id": order_data["order_id"],
        "razorpay_payment_id": "pay_test_001",
        "razorpay_signature": "invalid_bogus_sig"
    }
    bad_res = client.post("/api/subscriptions/verify-payment", json=invalid_pay, headers=headers)
    assert bad_res.status_code == 400

    # 6. Verify Payment with Test Signature
    verify_payload = {
        "razorpay_order_id": order_data["order_id"],
        "razorpay_payment_id": "pay_test_kirana_001",
        "razorpay_signature": "mock_valid_signature"
    }
    res_pay = client.post("/api/subscriptions/verify-payment", json=verify_payload, headers=headers)
    assert res_pay.status_code == 200
    updated_sub = res_pay.json()
    assert updated_sub["status"] == "ACTIVE"
    assert updated_sub["is_active"] is True
    assert updated_sub["end_date"] is not None


def test_complete_kirana_business_lifecycle(client):
    headers = get_authenticated_client(client, mobile="9811223344")

    # 1. Setup Shop & Activate Subscription
    client.post("/api/shops/setup", json={
        "shop_name": "Gupta Daily Needs",
        "owner_name": "Rajesh Gupta",
        "city": "Jaipur",
        "state": "Rajasthan"
    }, headers=headers)

    client.post("/api/subscriptions/verify-payment", json={
        "razorpay_order_id": "order_test_999",
        "razorpay_payment_id": "pay_test_999",
        "razorpay_signature": "mock_valid_signature"
    }, headers=headers)

    # 2. Create Products with Decimal Precision
    # Product A: Basmati Rice (fractional kg stock)
    prod_a_res = client.post("/api/products", json={
        "name": "India Gate Basmati Rice",
        "barcode": "890123456701",
        "category": "Grains & Pulses",
        "unit": "kg",
        "purchase_price": 75.00,
        "selling_price": 95.50,
        "stock_quantity": 25.500,
        "min_stock_threshold": 5.000
    }, headers=headers)
    assert prod_a_res.status_code == 201
    prod_a = prod_a_res.json()
    assert prod_a["name"] == "India Gate Basmati Rice"
    assert Decimal(str(prod_a["stock_quantity"])) == Decimal("25.500")
    assert Decimal(str(prod_a["selling_price"])) == Decimal("95.50")

    # Product B: Tata Salt 1kg packet
    prod_b_res = client.post("/api/products", json={
        "name": "Tata Salt 1kg",
        "barcode": "890123456702",
        "category": "Groceries",
        "unit": "packet",
        "purchase_price": 20.00,
        "selling_price": 28.00,
        "stock_quantity": 10.000,
        "min_stock_threshold": 3.000
    }, headers=headers)
    assert prod_b_res.status_code == 201
    prod_b = prod_b_res.json()

    # 3. Barcode Search & Text Search
    search_res = client.get("/api/products?search=basmati", headers=headers)
    assert len(search_res.json()) == 1
    assert search_res.json()[0]["id"] == prod_a["id"]

    barcode_res = client.get("/api/products/barcode/890123456702", headers=headers)
    assert barcode_res.status_code == 200
    assert barcode_res.json()["name"] == "Tata Salt 1kg"

    # 4. Restock & Adjust Inventory
    # Restock 5 kg rice
    restock_res = client.post(f"/api/inventory/{prod_a['id']}/restock?quantity=5.000", headers=headers)
    assert restock_res.status_code == 200
    assert Decimal(str(restock_res.json()["stock_quantity"])) == Decimal("30.500")

    # Adjust -0.5 kg (spillage / damaged)
    adjust_res = client.post(f"/api/inventory/{prod_a['id']}/adjust", json={
        "change_quantity": -0.500,
        "transaction_type": "ADJUSTMENT",
        "reason": "Bag torn and spillage"
    }, headers=headers)
    assert adjust_res.status_code == 200
    assert Decimal(str(adjust_res.json()["stock_quantity"])) == Decimal("30.000")

    # Prevent negative stock adjustment
    bad_adjust = client.post(f"/api/inventory/{prod_a['id']}/adjust", json={
        "change_quantity": -50.000,
        "transaction_type": "ADJUSTMENT"
    }, headers=headers)
    assert bad_adjust.status_code == 400

    # Check inventory audit trail
    tx_res = client.get(f"/api/inventory/{prod_a['id']}/transactions", headers=headers)
    assert tx_res.status_code == 200
    assert len(tx_res.json()) == 3  # Initial + Restock + Adjustment

    # 5. Atomic CASH Sale
    # Buy 2.500 kg rice @ 95.50 = 238.75 and 2 packets salt @ 28.00 = 56.00. Total = 294.75. Discount = 4.75 -> Final = 290.00
    sale_cash_res = client.post("/api/sales/checkout", json={
        "payment_mode": "CASH",
        "discount": 4.75,
        "items": [
            {"product_id": prod_a["id"], "quantity": 2.500},
            {"product_id": prod_b["id"], "quantity": 2.000}
        ]
    }, headers=headers)
    assert sale_cash_res.status_code == 201
    sale_cash = sale_cash_res.json()
    assert Decimal(str(sale_cash["total_amount"])) == Decimal("294.75")
    assert Decimal(str(sale_cash["discount"])) == Decimal("4.75")
    assert Decimal(str(sale_cash["final_amount"])) == Decimal("290.00")
    assert sale_cash["payment_mode"] == "CASH"

    # Verify stock reduction:
    # Rice: 30.000 - 2.500 = 27.500 kg
    # Salt: 10.000 - 2.000 = 8.000 packets
    rice_after = client.get(f"/api/products/{prod_a['id']}", headers=headers).json()
    assert Decimal(str(rice_after["stock_quantity"])) == Decimal("27.500")

    salt_after = client.get(f"/api/products/{prod_b['id']}", headers=headers).json()
    assert Decimal(str(salt_after["stock_quantity"])) == Decimal("8.000")

    # 6. Customer Khata & CREDIT Sale
    # Add customer "Amit Verma"
    cust_res = client.post("/api/customers", json={
        "name": "Amit Verma",
        "mobile_number": "9765432109"
    }, headers=headers)
    assert cust_res.status_code == 201
    customer = cust_res.json()
    assert Decimal(str(customer["balance"])) == Decimal("0.00")

    # Sale on Credit to Amit Verma: 1.5 kg rice @ 95.50 = 143.25
    credit_sale_res = client.post("/api/sales/checkout", json={
        "customer_id": customer["id"],
        "payment_mode": "CREDIT",
        "discount": 0.00,
        "items": [
            {"product_id": prod_a["id"], "quantity": 1.500}
        ]
    }, headers=headers)
    assert credit_sale_res.status_code == 201

    # Verify customer Khata balance updated to 143.25
    cust_updated = client.get(f"/api/customers/{customer['id']}", headers=headers).json()
    assert Decimal(str(cust_updated["balance"])) == Decimal("143.25")
    assert len(cust_updated["recent_transactions"]) == 1
    assert cust_updated["recent_transactions"][0]["transaction_type"] == "CREDIT_GIVEN"

    # 7. Khata Debt Settlement (Payment Received)
    # Amit pays ₹100.00 cash towards his debt
    pay_res = client.post(f"/api/customers/{customer['id']}/credit-payment", json={
        "amount": 100.00,
        "note": "Partial payment by cash"
    }, headers=headers)
    assert pay_res.status_code == 200
    assert Decimal(str(pay_res.json()["balance"])) == Decimal("43.25")

    # 8. Verify Dashboard Aggregates
    dash_res = client.get("/api/dashboard/metrics", headers=headers)
    assert dash_res.status_code == 200
    dash = dash_res.json()
    # Total sales = 290.00 (Cash) + 143.25 (Credit) = 433.25
    assert Decimal(str(dash["today_sales_amount"])) == Decimal("433.25")
    assert Decimal(str(dash["today_cash_sales"])) == Decimal("290.00")
    assert Decimal(str(dash["today_credit_sales"])) == Decimal("143.25")
    assert dash["today_transactions_count"] == 2
    # Outstanding khata credit = 43.25
    assert Decimal(str(dash["total_outstanding_credit"])) == Decimal("43.25")
    assert dash["total_products_count"] == 2
    assert dash["total_customers_count"] == 1

    # 9. Sale Rollback on Insufficient Stock
    # Try to buy 50.000 kg rice (only 26.000 left)
    failed_sale_res = client.post("/api/sales/checkout", json={
        "payment_mode": "CASH",
        "items": [
            {"product_id": prod_a["id"], "quantity": 50.000}
        ]
    }, headers=headers)
    assert failed_sale_res.status_code == 400
    assert "Insufficient stock" in failed_sale_res.json()["detail"]

    # Verify inventory was NOT changed
    rice_still = client.get(f"/api/products/{prod_a['id']}", headers=headers).json()
    assert Decimal(str(rice_still["stock_quantity"])) == Decimal("26.000")


def test_sales_and_customer_validations(client):
    headers = get_authenticated_client(client, mobile="9822334455")
    client.post("/api/shops/setup", json={
        "shop_name": "Patel Provision",
        "owner_name": "Bhavik Patel"
    }, headers=headers)

    # Product
    p = client.post("/api/products", json={
        "name": "Maggie 2-min Noodles",
        "selling_price": 14.00,
        "stock_quantity": 50.000
    }, headers=headers).json()

    # 1. Discount exceeding total should fail
    bad_discount = client.post("/api/sales/checkout", json={
        "payment_mode": "CASH",
        "discount": 100.00,
        "items": [{"product_id": p["id"], "quantity": 2.000}]
    }, headers=headers)
    assert bad_discount.status_code == 400
    assert "Discount" in bad_discount.json()["detail"]

    # 2. Credit sale without customer should fail
    no_cust = client.post("/api/sales/checkout", json={
        "payment_mode": "CREDIT",
        "items": [{"product_id": p["id"], "quantity": 1.000}]
    }, headers=headers)
    assert no_cust.status_code == 400
    assert "Customer selection is required" in no_cust.json()["detail"]

    # 3. Product soft deletion
    del_res = client.delete(f"/api/products/{p['id']}", headers=headers)
    assert del_res.status_code == 200

    # Once deactivated, it should not appear in active product list
    prods = client.get("/api/products", headers=headers).json()
    assert len(prods) == 0


def test_upi_qr_and_paid_unpaid_profit_engine(client):
    headers = get_authenticated_client(client, mobile="9811223344")

    # 1. Onboarding with UPI QR Image screenshot (base64) & UPI ID
    mock_qr_base64 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
    shop_res = client.post("/api/shops/setup", json={
        "shop_name": "Radhe Kirana",
        "owner_name": "Radhe Shyam",
        "address": "Bazaar Chowk",
        "city": "Bhopal",
        "state": "Madhya Pradesh",
        "pincode": "462001",
        "upi_qr_image": mock_qr_base64,
        "upi_id": "radhe@okaxis"
    }, headers=headers)
    assert shop_res.status_code == 201
    shop_data = shop_res.json()
    assert shop_data["upi_qr_image"] == mock_qr_base64
    assert shop_data["upi_id"] == "radhe@okaxis"

    # Update UPI QR
    updated_shop = client.put("/api/shops/current", json={
        "upi_id": "radhe@paytm"
    }, headers=headers).json()
    assert updated_shop["upi_id"] == "radhe@paytm"

    # 2. Add products with purchase_price & selling_price
    # Product 1: Cost 80.00, Sell 100.00 -> Profit per piece = 20.00
    prod1 = client.post("/api/products", json={
        "name": "Tata Tea Gold 250g",
        "purchase_price": 80.00,
        "selling_price": 100.00,
        "stock_quantity": 20.000,
        "unit": "packet"
    }, headers=headers).json()

    # Product 2: Cost 40.00, Sell 50.00 -> Profit per piece = 10.00
    prod2 = client.post("/api/products", json={
        "name": "Sugar 1kg",
        "purchase_price": 40.00,
        "selling_price": 50.00,
        "stock_quantity": 50.000,
        "unit": "kg"
    }, headers=headers).json()

    # Add customer for Khata / Unpaid
    cust = client.post("/api/customers", json={
        "name": "Rahul Sharma",
        "mobile_number": "9876500001"
    }, headers=headers).json()

    # 3. Sale 1: PAID via UPI
    # 2 pkts Tea (Cost 160, Sell 200) + 1 kg Sugar (Cost 40, Sell 50) = 250, Discount 10.00 = 240.00
    # Profit = 240.00 - (160 + 40) = 40.00
    paid_sale_res = client.post("/api/sales/checkout", json={
        "payment_mode": "UPI",
        "payment_status": "PAID",
        "discount": 10.00,
        "items": [
            {"product_id": prod1["id"], "quantity": 2.0},
            {"product_id": prod2["id"], "quantity": 1.0}
        ]
    }, headers=headers)
    assert paid_sale_res.status_code == 201
    paid_sale = paid_sale_res.json()
    assert paid_sale["payment_status"] == "PAID"
    assert Decimal(str(paid_sale["final_amount"])) == Decimal("240.00")
    assert Decimal(str(paid_sale["profit"])) == Decimal("40.00")

    # 4. Sale 2: UNPAID / Khata
    # 1 pkt Tea (Cost 80, Sell 100) = 100.00. Unpaid assigned to Rahul Sharma
    unpaid_sale_res = client.post("/api/sales/checkout", json={
        "customer_id": cust["id"],
        "payment_mode": "CREDIT",
        "payment_status": "UNPAID",
        "discount": 0.00,
        "items": [
            {"product_id": prod1["id"], "quantity": 1.0}
        ]
    }, headers=headers)
    assert unpaid_sale_res.status_code == 201
    unpaid_sale = unpaid_sale_res.json()
    assert unpaid_sale["payment_status"] == "UNPAID"
    assert Decimal(str(unpaid_sale["profit"])) == Decimal("20.00")

    # Check Rahul Sharma's balance increased by 100.00
    cust_check = client.get(f"/api/customers/{cust['id']}", headers=headers).json()
    assert Decimal(str(cust_check["balance"])) == Decimal("100.00")

    # 5. Check Dashboard Analytics
    dash = client.get("/api/dashboard/metrics", headers=headers).json()
    # Total sales = 240.00 (PAID) + 100.00 (UNPAID) = 340.00
    assert Decimal(str(dash["today_sales_amount"])) == Decimal("340.00")
    assert Decimal(str(dash["today_paid_sales"])) == Decimal("240.00")
    assert Decimal(str(dash["today_unpaid_sales"])) == Decimal("100.00")
    # Realized today profit from PAID sales = 40.00
    assert Decimal(str(dash["today_profit"])) == Decimal("40.00")

    # 6. Check Razorpay Subscription Order with test key
    order_res = client.post("/api/subscriptions/create-order", headers=headers)
    assert order_res.status_code == 200
    order_data = order_res.json()
    assert order_data["key_id"] == "rzp_test_TWXn6r1HPxwz0r"
    assert Decimal(str(order_data["amount"])) == Decimal("49.00")

