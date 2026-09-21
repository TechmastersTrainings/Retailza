from typing import List, Optional
from decimal import Decimal
from datetime import datetime, date, time
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from backend.app.database import get_db
from backend.app.models import (
    Shop, Product, Sale, SaleItem, Customer, CreditTransaction, StockTransaction
)
from backend.app.schemas import (
    SaleCreate, SaleResponse, SaleItemResponse
)
from backend.app.dependencies import get_current_shop

router = APIRouter(prefix="/sales", tags=["Billing & Sales Engine"])


def to_sale_response(sale: Sale) -> SaleResponse:
    customer_name = sale.customer.name if sale.customer else None
    return SaleResponse(
        id=sale.id,
        shop_id=sale.shop_id,
        customer_id=sale.customer_id,
        customer_name=customer_name,
        total_amount=sale.total_amount,
        discount=sale.discount,
        final_amount=sale.final_amount,
        payment_mode=sale.payment_mode,
        payment_status=getattr(sale, "payment_status", "PAID"),
        profit=getattr(sale, "profit", Decimal("0.00")),
        status=sale.status,
        created_at=sale.created_at,
        items=[
            SaleItemResponse(
                id=item.id,
                product_id=item.product_id,
                product_name=item.product_name,
                quantity=item.quantity,
                purchase_price=getattr(item, "purchase_price", Decimal("0.00")),
                unit_price=item.unit_price,
                subtotal=item.subtotal,
                created_at=item.created_at
            )
            for item in sale.items
        ]
    )


@router.post("/checkout", response_model=SaleResponse, status_code=status.HTTP_201_CREATED)
def checkout_sale(
    payload: SaleCreate,
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db)
):
    """
    Atomic Kirana Billing Checkout:
    1. Validates products and stock.
    2. Snapshots server prices & cost (tamper-proof).
    3. Calculates decimal totals, discounts, and real-time profit.
    4. Atomically reduces stock and logs stock movements.
    5. Handles PAID vs UNPAID status and updates customer Khata balance if applicable.
    6. Rollback on any failure.
    """
    if not payload.items:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Sale must contain at least one item"
        )

    # Determine payment status
    payment_status = (payload.payment_status or "PAID").upper()
    if payload.payment_mode.upper() == "CREDIT":
        payment_status = "UNPAID"

    # Validate customer if credit/unpaid sale with customer
    customer = None
    if payload.payment_mode.upper() == "CREDIT":
        if not payload.customer_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Customer selection is required for CREDIT sales (Khata)"
            )
        customer = db.query(Customer).filter(
            Customer.id == payload.customer_id,
            Customer.shop_id == shop.id
        ).first()
        if not customer:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Customer not found in this shop"
            )
    elif payload.customer_id:
        customer = db.query(Customer).filter(
            Customer.id == payload.customer_id,
            Customer.shop_id == shop.id
        ).first()

    # Pre-fetch and lock products for inventory check
    product_ids = [item.product_id for item in payload.items]
    products_db = db.query(Product).filter(
        Product.id.in_(product_ids),
        Product.shop_id == shop.id,
        Product.is_active == True
    ).all()
    product_map = {p.id: p for p in products_db}

    # Verify all products exist and have sufficient stock
    prepared_items = []
    running_total = Decimal("0.00")
    total_cost = Decimal("0.00")

    for req_item in payload.items:
        product = product_map.get(req_item.product_id)
        if not product:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Product with ID {req_item.product_id} not found in this store"
            )

        if product.stock_quantity < req_item.quantity:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Insufficient stock for '{product.name}'. Available: {product.stock_quantity}, Requested: {req_item.quantity}"
            )

        # Precise calculation with server-side price & cost snapshot
        unit_price = product.selling_price
        purchase_price = product.purchase_price or Decimal("0.00")
        subtotal = round(req_item.quantity * unit_price, 2)
        item_cost = round(req_item.quantity * purchase_price, 2)

        running_total += subtotal
        total_cost += item_cost

        prepared_items.append({
            "product": product,
            "quantity": req_item.quantity,
            "purchase_price": purchase_price,
            "unit_price": unit_price,
            "subtotal": subtotal
        })

    if payload.discount > running_total:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Discount (₹{payload.discount}) cannot exceed total sale amount (₹{running_total})"
        )

    final_amount = running_total - payload.discount
    # Calculate captured profit: (Revenue after discount) - Cost
    calculated_profit = max(Decimal("0.00"), final_amount - total_cost)

    # Atomic Execution
    try:
        sale = Sale(
            shop_id=shop.id,
            customer_id=customer.id if customer else None,
            total_amount=running_total,
            discount=payload.discount,
            final_amount=final_amount,
            payment_mode=payload.payment_mode.upper(),
            payment_status=payment_status,
            profit=calculated_profit,
            status="COMPLETED"
        )
        db.add(sale)
        db.flush()

        for item_data in prepared_items:
            prod = item_data["product"]
            qty = item_data["quantity"]

            # 1. Create Sale Item with purchase_price snapshot
            sale_item = SaleItem(
                sale_id=sale.id,
                product_id=prod.id,
                product_name=prod.name,
                quantity=qty,
                purchase_price=item_data["purchase_price"],
                unit_price=item_data["unit_price"],
                subtotal=item_data["subtotal"]
            )
            db.add(sale_item)

            # 2. Deduct inventory
            prod.stock_quantity = prod.stock_quantity - qty

            # 3. Log stock movement
            stock_tx = StockTransaction(
                product_id=prod.id,
                change_quantity=-qty,
                balance_quantity=prod.stock_quantity,
                transaction_type="SALE",
                reason=f"Sale #{sale.id}"
            )
            db.add(stock_tx)

        # 4. Handle Khata Credit entry if CREDIT or UNPAID with customer
        if (payload.payment_mode.upper() == "CREDIT" or payment_status == "UNPAID") and customer:
            customer.balance = customer.balance + final_amount
            credit_tx = CreditTransaction(
                customer_id=customer.id,
                sale_id=sale.id,
                amount=final_amount,
                transaction_type="CREDIT_GIVEN",
                note=f"Khata Credit Sale #{sale.id}"
            )
            db.add(credit_tx)

        db.commit()
        db.refresh(sale)
        return to_sale_response(sale)

    except Exception as e:
        db.rollback()
        raise e


@router.get("", response_model=List[SaleResponse])
def get_sales(
    limit: int = Query(50, le=200),
    offset: int = Query(0, ge=0),
    payment_mode: Optional[str] = Query(None, description="Filter by CASH, UPI, CREDIT"),
    customer_id: Optional[int] = Query(None, description="Filter by customer"),
    sale_date: Optional[date] = Query(None, description="Filter by date YYYY-MM-DD"),
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db)
):
    """List store sales with filtering."""
    query = db.query(Sale).filter(Sale.shop_id == shop.id)

    if payment_mode:
        query = query.filter(Sale.payment_mode == payment_mode.upper())

    if customer_id:
        query = query.filter(Sale.customer_id == customer_id)

    if sale_date:
        start_dt = datetime.combine(sale_date, time.min)
        end_dt = datetime.combine(sale_date, time.max)
        query = query.filter(Sale.created_at >= start_dt, Sale.created_at <= end_dt)

    sales = query.order_by(Sale.id.desc()).offset(offset).limit(limit).all()
    return [to_sale_response(s) for s in sales]


@router.get("/{sale_id}", response_model=SaleResponse)
def get_sale_detail(
    sale_id: int,
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db)
):
    """Retrieve single receipt / bill details."""
    sale = db.query(Sale).filter(
        Sale.id == sale_id,
        Sale.shop_id == shop.id
    ).first()

    if not sale:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Sale bill not found")

    return to_sale_response(sale)
