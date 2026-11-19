from typing import List, Optional
from decimal import Decimal
from fastapi import APIRouter, Depends, HTTPException, Query, status, UploadFile, File, Response
from sqlalchemy.orm import Session
from sqlalchemy import or_, func
from backend.app.database import get_db
from backend.app.models import Shop, Product, StockTransaction, Subscription
from backend.app.schemas import (
    ProductCreate, ProductUpdate, ProductResponse,
    BulkProductItem, BulkProductUploadResponse, BulkProductCommitRequest, BulkProductCommitResponse
)
from backend.app.dependencies import get_current_shop, require_active_subscription
from backend.app.utils.bulk_parser import (
    parse_excel_file, parse_csv_file, parse_word_file, validate_and_normalize_items
)
from backend.app.utils.template_generator import (
    generate_excel_template, generate_word_template
)

router = APIRouter(prefix="/products", tags=["Products & Catalog"])


def to_product_response(p: Product) -> ProductResponse:
    return ProductResponse(
        id=p.id,
        shop_id=p.shop_id,
        name=p.name,
        barcode=p.barcode,
        category=p.category,
        unit=p.unit,
        purchase_price=p.purchase_price,
        selling_price=p.selling_price,
        stock_quantity=p.stock_quantity,
        min_stock_threshold=p.min_stock_threshold,
        is_active=p.is_active,
        is_low_stock=bool(p.stock_quantity <= p.min_stock_threshold),
        created_at=p.created_at,
        updated_at=p.updated_at
    )


@router.get("", response_model=List[ProductResponse])
def get_products(
    search: Optional[str] = Query(None, description="Search by name or barcode"),
    category: Optional[str] = Query(None, description="Filter by category"),
    low_stock_only: bool = Query(False, description="Filter only low stock items"),
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db)
):
    """List products with case-insensitive search and low-stock filters."""
    query = db.query(Product).filter(
        Product.shop_id == shop.id,
        Product.is_active == True
    )

    if search:
        search_term = f"%{search.strip().lower()}%"
        query = query.filter(
            or_(
                func.lower(Product.name).like(search_term),
                Product.barcode.like(search_term)
            )
        )

    if category and category != "All":
        query = query.filter(Product.category == category)

    if low_stock_only:
        query = query.filter(Product.stock_quantity <= Product.min_stock_threshold)

    products = query.order_by(Product.name.asc()).all()
    return [to_product_response(p) for p in products]


@router.get("/barcode/{barcode}", response_model=ProductResponse)
def get_product_by_barcode(
    barcode: str,
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db)
):
    """Instant lookup by barcode for scanner integrations."""
    product = db.query(Product).filter(
        Product.shop_id == shop.id,
        Product.barcode == barcode.strip(),
        Product.is_active == True
    ).first()

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Product with barcode '{barcode}' not found"
        )

    return to_product_response(product)


# --- Bulk Product Import Endpoints ---

@router.get("/bulk/template/excel")
def download_excel_template():
    """Download styled Excel (.xlsx) template for bulk product import."""
    buf = generate_excel_template()
    return Response(
        content=buf.getvalue(),
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": "attachment; filename=retailza_product_template.xlsx"}
    )


@router.get("/bulk/template/word")
def download_word_template():
    """Download styled Word (.docx) template for bulk product import."""
    buf = generate_word_template()
    return Response(
        content=buf.getvalue(),
        media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        headers={"Content-Disposition": "attachment; filename=retailza_product_template.docx"}
    )


@router.post("/bulk/upload", response_model=BulkProductUploadResponse)
async def upload_bulk_file(
    file: UploadFile = File(...),
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db)
):
    """
    Upload and parse Excel (.xlsx, .csv) or Word (.docx) file.
    Validates all product rows, checks for duplicate barcodes against shop catalog,
    and returns a preview of items to the customer.
    """
    filename = file.filename or ""
    filename_lower = filename.lower()
    content = await file.read()

    if not content:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="The uploaded file is empty. Please select a valid Excel or Word file."
        )

    file_type = "unknown"
    raw_items = []

    if filename_lower.endswith(".xlsx") or filename_lower.endswith(".xls"):
        file_type = "excel"
        try:
            raw_items = parse_excel_file(content)
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to read Excel file: {str(e)}. Please ensure it is a valid .xlsx spreadsheet."
            )
    elif filename_lower.endswith(".csv"):
        file_type = "excel"
        try:
            raw_items = parse_csv_file(content)
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to read CSV file: {str(e)}."
            )
    elif filename_lower.endswith(".docx") or filename_lower.endswith(".doc"):
        file_type = "word"
        try:
            raw_items = parse_word_file(content)
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to read Word document: {str(e)}. Please ensure it is a valid .docx document."
            )
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unsupported file format. Please upload an Excel sheet (.xlsx, .csv) or Word document (.docx)."
        )

    if not raw_items:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No product rows found in the uploaded file. Please use our sample template."
        )

    # Fetch existing active barcodes for this shop
    existing_barcodes = {
        p[0] for p in db.query(Product.barcode).filter(
            Product.shop_id == shop.id,
            Product.is_active == True,
            Product.barcode.isnot(None)
        ).all() if p[0]
    }

    validated = validate_and_normalize_items(raw_items, existing_barcodes)
    valid_count = sum(1 for it in validated if it["is_valid"])
    invalid_count = len(validated) - valid_count

    return BulkProductUploadResponse(
        total_rows=len(validated),
        valid_count=valid_count,
        invalid_count=invalid_count,
        filename=filename,
        file_type=file_type,
        items=[BulkProductItem(**it) for it in validated]
    )


@router.post("/bulk/commit", response_model=BulkProductCommitResponse, status_code=status.HTTP_201_CREATED)
def commit_bulk_products(
    payload: BulkProductCommitRequest,
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db),
    _sub: Subscription = Depends(require_active_subscription)
):
    """
    Commit validated bulk items to the shop's catalog.
    Creates products and initial stock transactions.
    """
    if not payload.items:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No items provided to import."
        )

    # Filter only valid items
    valid_items = [item for item in payload.items if item.is_valid]
    if not valid_items:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No valid items to import. Please correct the validation errors first."
        )

    created_products = []
    for item in valid_items:
        # Re-verify barcode uniqueness
        if item.barcode:
            exists = db.query(Product).filter(
                Product.shop_id == shop.id,
                Product.barcode == item.barcode.strip(),
                Product.is_active == True
            ).first()
            if exists:
                continue

        prod = Product(
            shop_id=shop.id,
            name=item.name.strip(),
            barcode=item.barcode.strip() if item.barcode else None,
            category=item.category or "General",
            unit=item.unit or "piece",
            purchase_price=item.purchase_price or Decimal("0.00"),
            selling_price=item.selling_price,
            stock_quantity=item.stock_quantity or Decimal("0.000"),
            min_stock_threshold=item.min_stock_threshold or Decimal("5.000"),
            is_active=True
        )
        db.add(prod)
        db.flush()

        stock_qty = item.stock_quantity or Decimal("0.000")
        if stock_qty > Decimal("0.000"):
            tx = StockTransaction(
                product_id=prod.id,
                change_quantity=stock_qty,
                balance_quantity=stock_qty,
                transaction_type="RESTOCK",
                reason="Bulk catalog import"
            )
            db.add(tx)

        created_products.append(prod)

    db.commit()
    for p in created_products:
        db.refresh(p)

    return BulkProductCommitResponse(
        imported_count=len(created_products),
        message=f"Successfully imported {len(created_products)} products!",
        products=[to_product_response(p) for p in created_products]
    )


@router.get("/{product_id}", response_model=ProductResponse)
def get_product_detail(
    product_id: int,
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db)
):
    """Retrieve single product details."""
    product = db.query(Product).filter(
        Product.id == product_id,
        Product.shop_id == shop.id,
        Product.is_active == True
    ).first()

    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    return to_product_response(product)


@router.post("", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
def create_product(
    payload: ProductCreate,
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db),
    _sub: Subscription = Depends(require_active_subscription)
):
    """Create a new product with decimal stock quantities and purchase/selling prices."""
    # Check barcode uniqueness if provided
    if payload.barcode:
        existing = db.query(Product).filter(
            Product.shop_id == shop.id,
            Product.barcode == payload.barcode.strip(),
            Product.is_active == True
        ).first()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Product with barcode '{payload.barcode}' already exists: {existing.name}"
            )

    product = Product(
        shop_id=shop.id,
        name=payload.name.strip(),
        barcode=payload.barcode.strip() if payload.barcode else None,
        category=payload.category or "General",
        unit=payload.unit,
        purchase_price=payload.purchase_price,
        selling_price=payload.selling_price,
        stock_quantity=payload.stock_quantity,
        min_stock_threshold=payload.min_stock_threshold,
        is_active=True
    )
    db.add(product)
    db.flush()

    # If initial stock > 0, log audit transaction
    if payload.stock_quantity > Decimal("0.000"):
        tx = StockTransaction(
            product_id=product.id,
            change_quantity=payload.stock_quantity,
            balance_quantity=payload.stock_quantity,
            transaction_type="RESTOCK",
            reason="Initial inventory entry"
        )
        db.add(tx)

    db.commit()
    db.refresh(product)
    return to_product_response(product)


@router.put("/{product_id}", response_model=ProductResponse)
def update_product(
    product_id: int,
    payload: ProductUpdate,
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db)
):
    """Update product details."""
    product = db.query(Product).filter(
        Product.id == product_id,
        Product.shop_id == shop.id
    ).first()

    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    if payload.name is not None:
        product.name = payload.name.strip()
    if payload.barcode is not None:
        product.barcode = payload.barcode.strip() if payload.barcode else None
    if payload.category is not None:
        product.category = payload.category
    if payload.unit is not None:
        product.unit = payload.unit
    if payload.purchase_price is not None:
        product.purchase_price = payload.purchase_price
    if payload.selling_price is not None:
        product.selling_price = payload.selling_price
    if payload.stock_quantity is not None and payload.stock_quantity != product.stock_quantity:
        diff = payload.stock_quantity - product.stock_quantity
        product.stock_quantity = payload.stock_quantity
        tx = StockTransaction(
            product_id=product.id,
            change_quantity=diff,
            balance_quantity=product.stock_quantity,
            transaction_type="ADJUSTMENT",
            reason="Manual stock edit"
        )
        db.add(tx)
    if payload.min_stock_threshold is not None:
        product.min_stock_threshold = payload.min_stock_threshold
    if payload.is_active is not None:
        product.is_active = payload.is_active

    db.commit()
    db.refresh(product)
    return to_product_response(product)


@router.delete("/{product_id}", status_code=status.HTTP_200_OK)
def delete_product(
    product_id: int,
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db)
):
    """Soft delete a product by setting is_active=False."""
    product = db.query(Product).filter(
        Product.id == product_id,
        Product.shop_id == shop.id
    ).first()

    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    product.is_active = False
    db.commit()
    return {"message": f"Product '{product.name}' deactivated successfully"}
