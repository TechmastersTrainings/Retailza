import io
import pytest
from decimal import Decimal
from backend.app.models import User, Shop, Subscription, Product
from backend.app.utils.template_generator import generate_excel_template, generate_word_template
from backend.app.utils.security import create_access_token


@pytest.fixture
def auth_header(db_session):
    # Setup test user, shop, and active subscription
    user = User(
        mobile_number="9876543299",
        name="Kirana Owner",
        role="OWNER"
    )
    db_session.add(user)
    db_session.flush()

    shop = Shop(
        owner_id=user.id,
        shop_name="Kirana Test Store",
        owner_name="Kirana Owner",
        category="Provision Store"
    )
    db_session.add(shop)
    db_session.flush()

    sub = Subscription(
        shop_id=shop.id,
        plan_name="basic",
        amount=49.00,
        status="ACTIVE"
    )
    db_session.add(sub)
    db_session.commit()

    token = create_access_token(data={"sub": str(user.id), "shop_id": shop.id})
    return {"Authorization": f"Bearer {token}"}


def test_download_excel_template(client, auth_header):
    resp = client.get("/api/products/bulk/template/excel", headers=auth_header)
    assert resp.status_code == 200
    assert resp.headers["content-type"] == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    assert len(resp.content) > 1000


def test_download_word_template(client, auth_header):
    resp = client.get("/api/products/bulk/template/word", headers=auth_header)
    assert resp.status_code == 200
    assert resp.headers["content-type"] == "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    assert len(resp.content) > 1000


def test_bulk_upload_and_commit_excel(client, auth_header, db_session):
    # 1. Generate sample excel template
    excel_buf = generate_excel_template()

    # 2. Upload template
    files = {
        "file": ("sample_products.xlsx", excel_buf.getvalue(), "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    }
    resp = client.post("/api/products/bulk/upload", headers=auth_header, files=files)
    assert resp.status_code == 200
    data = resp.json()
    assert data["total_rows"] == 5
    assert data["valid_count"] == 5
    assert data["invalid_count"] == 0
    assert data["file_type"] == "excel"
    assert len(data["items"]) == 5

    # 3. Commit parsed items
    commit_payload = {"items": data["items"]}
    commit_resp = client.post("/api/products/bulk/commit", headers=auth_header, json=commit_payload)
    assert commit_resp.status_code == 201
    commit_data = commit_resp.json()
    assert commit_data["imported_count"] == 5

    # Verify products in DB
    prods = db_session.query(Product).all()
    assert len(prods) == 5
    names = [p.name for p in prods]
    assert "Aashirvaad Shudh Chakki Atta 5kg" in names
    assert "Tata Salt Vacuum Evaporated 1kg" in names


def test_bulk_upload_and_commit_word(client, auth_header, db_session):
    # 1. Generate sample word template
    word_buf = generate_word_template()

    # 2. Upload template
    files = {
        "file": ("kirana_list.docx", word_buf.getvalue(), "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
    }
    resp = client.post("/api/products/bulk/upload", headers=auth_header, files=files)
    assert resp.status_code == 200
    data = resp.json()
    assert data["total_rows"] == 5
    assert data["valid_count"] == 5
    assert data["file_type"] == "word"

    # 3. Commit items
    commit_payload = {"items": data["items"]}
    commit_resp = client.post("/api/products/bulk/commit", headers=auth_header, json=commit_payload)
    assert commit_resp.status_code == 201
    assert commit_resp.json()["imported_count"] == 5


def test_bulk_upload_csv(client, auth_header):
    csv_content = (
        "Product Name,Selling Price,Purchase Price,Stock Qty,Unit,Category,Barcode\n"
        "Kurkure Masala Munch,20,16.5,50,packet,Snacks,8901491101899\n"
        "Good Day Butter Cookies,30,24,40,packet,Snacks,8901063012014\n"
    ).encode("utf-8")

    files = {"file": ("stock.csv", csv_content, "text/csv")}
    resp = client.post("/api/products/bulk/upload", headers=auth_header, files=files)
    assert resp.status_code == 200
    data = resp.json()
    assert data["total_rows"] == 2
    assert data["valid_count"] == 2
    assert data["items"][0]["name"] == "Kurkure Masala Munch"
    assert Decimal(str(data["items"][0]["selling_price"])) == Decimal("20.00")


def test_bulk_upload_validation_errors(client, auth_header, db_session):
    # CSV with bad data: missing name, negative price, duplicate barcode
    csv_content = (
        "Product Name,Selling Price,Purchase Price,Stock Qty,Unit,Category,Barcode\n"
        ",20,16.5,50,packet,Snacks,8901111111111\n"
        "Bad Price Item,-10,0,10,piece,General,\n"
        "Duplicate Barcode 1,50,40,10,piece,General,9999999999999\n"
        "Duplicate Barcode 2,60,50,10,piece,General,9999999999999\n"
    ).encode("utf-8")

    files = {"file": ("invalid_stock.csv", csv_content, "text/csv")}
    resp = client.post("/api/products/bulk/upload", headers=auth_header, files=files)
    assert resp.status_code == 200
    data = resp.json()
    assert data["total_rows"] == 4
    assert data["valid_count"] == 1  # only Duplicate Barcode 1 is initially valid
    assert data["invalid_count"] == 3

    # Check specific errors
    assert "name is required" in data["items"][0]["error_message"].lower()
    assert "negative" in data["items"][1]["error_message"].lower()
    assert "duplicate barcode" in data["items"][3]["error_message"].lower()


def test_single_add_product_remains_intact(client, auth_header):
    # Ensure existing single add product POST /api/products is untouched and functions
    payload = {
        "name": "Single Added Biscuit",
        "barcode": "8901000000001",
        "category": "Snacks",
        "unit": "packet",
        "purchase_price": "15.00",
        "selling_price": "20.00",
        "stock_quantity": "25.000",
        "min_stock_threshold": "5.000"
    }
    resp = client.post("/api/products", headers=auth_header, json=payload)
    assert resp.status_code == 201
    data = resp.json()
    assert data["name"] == "Single Added Biscuit"
    assert data["selling_price"] == "20.00"
