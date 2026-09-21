from typing import List, Optional
from decimal import Decimal
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from backend.app.database import get_db
from backend.app.models import Shop, Product, StockTransaction
from backend.app.schemas import (
    StockAdjustment, StockTransactionResponse, ProductResponse
)
from backend.app.dependencies import get_current_shop
from backend.app.routers.products import to_product_response

router = APIRouter(prefix="/inventory", tags=["Inventory & Stock Audit"])


@router.post("/{product_id}/restock", response_model=ProductResponse)
def restock_product(
    product_id: int,
    quantity: Decimal = Query(..., gt=0, description="Quantity to add to inventory"),
    reason: Optional[str] = Query("Supplier restock delivery", description="Restock note"),
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db)
):
    """Increase stock quantity and log audit trail transaction."""
    product = db.query(Product).filter(
        Product.id == product_id,
        Product.shop_id == shop.id,
        Product.is_active == True
    ).first()

    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    product.stock_quantity = product.stock_quantity + quantity
    tx = StockTransaction(
        product_id=product.id,
        change_quantity=quantity,
        balance_quantity=product.stock_quantity,
        transaction_type="RESTOCK",
        reason=reason
    )
    db.add(tx)
    db.commit()
    db.refresh(product)

    return to_product_response(product)


@router.post("/{product_id}/adjust", response_model=ProductResponse)
def adjust_inventory(
    product_id: int,
    payload: StockAdjustment,
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db)
):
    """Adjust stock quantity (+ or -) with audit justification (breakage, spoilage, return)."""
    product = db.query(Product).filter(
        Product.id == product_id,
        Product.shop_id == shop.id,
        Product.is_active == True
    ).first()

    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    new_quantity = product.stock_quantity + payload.change_quantity
    if new_quantity < Decimal("0.000"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Adjustment would result in negative stock ({new_quantity}). Available: {product.stock_quantity}"
        )

    product.stock_quantity = new_quantity
    tx = StockTransaction(
        product_id=product.id,
        change_quantity=payload.change_quantity,
        balance_quantity=product.stock_quantity,
        transaction_type=payload.transaction_type,
        reason=payload.reason or "Stock adjustment"
    )
    db.add(tx)
    db.commit()
    db.refresh(product)

    return to_product_response(product)


@router.get("/{product_id}/transactions", response_model=List[StockTransactionResponse])
def get_product_stock_history(
    product_id: int,
    limit: int = Query(50, le=200),
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db)
):
    """Retrieve full audit trail of stock movements for this product."""
    product = db.query(Product).filter(
        Product.id == product_id,
        Product.shop_id == shop.id
    ).first()

    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    txs = db.query(StockTransaction).filter(
        StockTransaction.product_id == product.id
    ).order_by(StockTransaction.id.desc()).limit(limit).all()

    return [
        StockTransactionResponse(
            id=tx.id,
            product_id=tx.product_id,
            change_quantity=tx.change_quantity,
            balance_quantity=tx.balance_quantity,
            transaction_type=tx.transaction_type,
            reason=tx.reason,
            created_at=tx.created_at
        )
        for tx in txs
    ]
