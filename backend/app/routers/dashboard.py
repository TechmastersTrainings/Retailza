from decimal import Decimal
from typing import Optional
from datetime import datetime, date, time
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from backend.app.database import get_db
from backend.app.models import Shop, Sale, Customer, Product
from backend.app.schemas import DashboardMetrics
from backend.app.dependencies import get_current_shop

router = APIRouter(prefix="/dashboard", tags=["Kirana Owner Dashboard"])


@router.get("/metrics", response_model=DashboardMetrics)
def get_dashboard_metrics(
    target_date: Optional[date] = Query(None, description="Optional date (defaults to current server UTC date)"),
    shop: Shop = Depends(get_current_shop),
    db: Session = Depends(get_db)
):
    """
    Real-time Kirana store analytics:
    - Today's total sales and breakdown by Cash, UPI, and Khata (Credit).
    - Total outstanding khata book debt across all customers.
    - Low stock inventory alert count.
    - Product and customer counts.
    """
    query_date = target_date or datetime.utcnow().date()
    start_today = datetime.combine(query_date, time.min)
    end_today = datetime.combine(query_date, time.max)

    # Today's completed sales
    today_sales_query = db.query(Sale).filter(
        Sale.shop_id == shop.id,
        Sale.status == "COMPLETED",
        Sale.created_at >= start_today,
        Sale.created_at <= end_today
    )

    today_sales = today_sales_query.all()

    today_sales_amount = Decimal("0.00")
    today_cash_sales = Decimal("0.00")
    today_upi_sales = Decimal("0.00")
    today_credit_sales = Decimal("0.00")
    today_paid_sales = Decimal("0.00")
    today_unpaid_sales = Decimal("0.00")
    today_profit = Decimal("0.00")
    today_transactions_count = len(today_sales)

    for s in today_sales:
        today_sales_amount += s.final_amount
        mode = s.payment_mode.upper()
        if mode == "CASH":
            today_cash_sales += s.final_amount
        elif mode == "UPI":
            today_upi_sales += s.final_amount
        elif mode == "CREDIT":
            today_credit_sales += s.final_amount

        # Paid vs Unpaid & Profit Breakdown
        p_status = getattr(s, "payment_status", "PAID")
        if p_status == "PAID":
            today_paid_sales += s.final_amount
            today_profit += getattr(s, "profit", Decimal("0.00")) or Decimal("0.00")
        else:
            today_unpaid_sales += s.final_amount

    # Total outstanding credit
    total_credit_result = db.query(func.sum(Customer.balance)).filter(
        Customer.shop_id == shop.id,
        Customer.balance > Decimal("0.00")
    ).scalar()
    total_outstanding_credit = Decimal(str(total_credit_result)) if total_credit_result else Decimal("0.00")

    # Low stock items count
    low_stock_count = db.query(func.count(Product.id)).filter(
        Product.shop_id == shop.id,
        Product.is_active == True,
        Product.stock_quantity <= Product.min_stock_threshold
    ).scalar() or 0

    # Total active products
    total_products_count = db.query(func.count(Product.id)).filter(
        Product.shop_id == shop.id,
        Product.is_active == True
    ).scalar() or 0

    # Total customers
    total_customers_count = db.query(func.count(Customer.id)).filter(
        Customer.shop_id == shop.id
    ).scalar() or 0

    return DashboardMetrics(
        today_sales_amount=round(today_sales_amount, 2),
        today_transactions_count=today_transactions_count,
        today_cash_sales=round(today_cash_sales, 2),
        today_upi_sales=round(today_upi_sales, 2),
        today_credit_sales=round(today_credit_sales, 2),
        today_paid_sales=round(today_paid_sales, 2),
        today_unpaid_sales=round(today_unpaid_sales, 2),
        today_profit=round(today_profit, 2),
        total_outstanding_credit=round(total_outstanding_credit, 2),
        low_stock_count=int(low_stock_count),
        total_products_count=int(total_products_count),
        total_customers_count=int(total_customers_count)
    )
