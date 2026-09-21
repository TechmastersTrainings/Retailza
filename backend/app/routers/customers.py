from typing import List, Optional
from decimal import Decimal
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import or_, func
from backend.app.database import get_db
from backend.app.models import Shop, Customer, CreditTransaction
from backend.app.schemas import (
    CustomerCreate, CustomerUpdate, CustomerResponse,
    CustomerDetailResponse, CreditPaymentCreate, CreditTransactionResponse
)
from backend.app.dependencies import get_current_shop

router = APIRouter(prefix="/customers", tags=["Customer Khata (Credit)"])


@router.get("", response_model=List[CustomerResponse])
def get_customers(
    search: Optional[str] = Query(None, description="Search by customer name or phone"),
    has_balance_only: bool = Query(False, description="Only show customers with pending credit debt"),
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db)
):
    """List all customers with outstanding Khata balances."""
    query = db.query(Customer).filter(Customer.shop_id == shop.id)

    if search:
        term = f"%{search.strip().lower()}%"
        query = query.filter(
            or_(
                func.lower(Customer.name).like(term),
                Customer.mobile_number.like(term)
            )
        )

    if has_balance_only:
        query = query.filter(Customer.balance > Decimal("0.00"))

    customers = query.order_by(Customer.balance.desc(), Customer.name.asc()).all()
    return [CustomerResponse.model_validate(c) for c in customers]


@router.post("", response_model=CustomerResponse, status_code=status.HTTP_201_CREATED)
def create_customer(
    payload: CustomerCreate,
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db)
):
    """Add a new customer to the shop's Khata ledger."""
    customer = Customer(
        shop_id=shop.id,
        name=payload.name.strip(),
        mobile_number=payload.mobile_number.strip() if payload.mobile_number else None,
        balance=Decimal("0.00")
    )
    db.add(customer)
    db.commit()
    db.refresh(customer)
    return CustomerResponse.model_validate(customer)


@router.get("/{customer_id}", response_model=CustomerDetailResponse)
def get_customer_details(
    customer_id: int,
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db)
):
    """Get customer details along with complete credit ledger history."""
    customer = db.query(Customer).filter(
        Customer.id == customer_id,
        Customer.shop_id == shop.id
    ).first()

    if not customer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Customer not found")

    txs = db.query(CreditTransaction).filter(
        CreditTransaction.customer_id == customer.id
    ).order_by(CreditTransaction.id.desc()).all()

    return CustomerDetailResponse(
        id=customer.id,
        shop_id=customer.shop_id,
        name=customer.name,
        mobile_number=customer.mobile_number,
        balance=customer.balance,
        created_at=customer.created_at,
        updated_at=customer.updated_at,
        recent_transactions=[
            CreditTransactionResponse(
                id=tx.id,
                customer_id=tx.customer_id,
                sale_id=tx.sale_id,
                amount=tx.amount,
                transaction_type=tx.transaction_type,
                note=tx.note,
                created_at=tx.created_at
            )
            for tx in txs
        ]
    )


@router.put("/{customer_id}", response_model=CustomerResponse)
def update_customer(
    customer_id: int,
    payload: CustomerUpdate,
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db)
):
    """Update customer contact info."""
    customer = db.query(Customer).filter(
        Customer.id == customer_id,
        Customer.shop_id == shop.id
    ).first()

    if not customer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Customer not found")

    if payload.name is not None:
        customer.name = payload.name.strip()
    if payload.mobile_number is not None:
        customer.mobile_number = payload.mobile_number.strip() if payload.mobile_number else None

    db.commit()
    db.refresh(customer)
    return CustomerResponse.model_validate(customer)


@router.post("/{customer_id}/credit-payment", response_model=CustomerResponse)
def record_credit_payment(
    customer_id: int,
    payload: CreditPaymentCreate,
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db)
):
    """
    Record payment received from a customer settling their khata debt.
    Reduces customer balance and creates PAYMENT_RECEIVED transaction.
    """
    customer = db.query(Customer).filter(
        Customer.id == customer_id,
        Customer.shop_id == shop.id
    ).first()

    if not customer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Customer not found")

    # Deduct balance
    customer.balance = customer.balance - payload.amount

    tx = CreditTransaction(
        customer_id=customer.id,
        sale_id=None,
        amount=payload.amount,
        transaction_type="PAYMENT_RECEIVED",
        note=payload.note or "Customer Payment"
    )
    db.add(tx)
    db.commit()
    db.refresh(customer)

    return CustomerResponse.model_validate(customer)
