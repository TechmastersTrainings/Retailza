from typing import List, Optional
from decimal import Decimal
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import or_, func
from backend.app.database import get_db
from backend.app.models import Shop, Product, StockTransaction
from backend.app.schemas import ProductCreate, ProductUpdate, ProductResponse
from backend.app.dependencies import get_current_shop

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
    db: Session = Depends(get_db)
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
