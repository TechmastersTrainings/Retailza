import re
from datetime import datetime
from typing import Optional, List, Dict
from decimal import Decimal
from pydantic import BaseModel, ConfigDict, Field, field_validator


# --- Auth Schemas ---

class OTPRequest(BaseModel):
    identifier: Optional[str] = Field(None, description="10-digit mobile number or email address")
    mobile_number: Optional[str] = Field(None, description="10-digit Indian mobile number")

    @field_validator("identifier", mode="before")
    @classmethod
    def validate_identifier(cls, v: Optional[str]) -> Optional[str]:
        if not v:
            return v
        v = str(v).strip()
        if "@" in v:
            if not re.match(r"^[^@]+@[^@]+\.[^@]+$", v):
                raise ValueError("Invalid email address format")
            return v.lower()
        cleaned = "".join(filter(str.isdigit, v))
        if len(cleaned) == 12 and cleaned.startswith("91"):
            cleaned = cleaned[2:]
        if len(cleaned) != 10:
            raise ValueError("Must be a valid 10-digit mobile number or email address")
        return cleaned


class OTPVerify(BaseModel):
    identifier: Optional[str] = None
    mobile_number: Optional[str] = None
    otp_code: str

    @field_validator("identifier", mode="before")
    @classmethod
    def validate_identifier(cls, v: Optional[str]) -> Optional[str]:
        if not v:
            return v
        v = str(v).strip()
        if "@" in v:
            if not re.match(r"^[^@]+@[^@]+\.[^@]+$", v):
                raise ValueError("Invalid email address format")
            return v.lower()
        cleaned = "".join(filter(str.isdigit, v))
        if len(cleaned) == 12 and cleaned.startswith("91"):
            cleaned = cleaned[2:]
        if len(cleaned) != 10:
            raise ValueError("Must be a valid 10-digit mobile number or email address")
        return cleaned


class PasswordLoginRequest(BaseModel):
    identifier: str = Field(..., description="Email address or 10-digit mobile number")
    password: str = Field(..., min_length=4)


class UserResponse(BaseModel):
    id: int
    mobile_number: Optional[str] = None
    email: Optional[str] = None
    name: Optional[str] = None
    role: str
    is_active: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ShopResponse(BaseModel):
    id: int
    owner_id: int
    shop_name: str
    owner_name: str
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None
    upi_qr_image: Optional[str] = None
    upi_id: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserResponse
    shop: Optional[ShopResponse] = None


class RefreshTokenRequest(BaseModel):
    refresh_token: str


# --- Shop Schemas ---

class ShopCreate(BaseModel):
    shop_name: str = Field(..., min_length=2, max_length=150)
    owner_name: str = Field(..., min_length=2, max_length=100)
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None
    upi_qr_image: Optional[str] = None
    upi_id: Optional[str] = None


class ShopUpdate(BaseModel):
    shop_name: Optional[str] = None
    owner_name: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None
    upi_qr_image: Optional[str] = None
    upi_id: Optional[str] = None


# --- Subscription Schemas ---

class SubscriptionResponse(BaseModel):
    id: int
    shop_id: int
    plan_name: str
    amount: Decimal
    status: str
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    is_active: bool = False

    model_config = ConfigDict(from_attributes=True)


class SubscriptionOrderResponse(BaseModel):
    order_id: str
    amount: Decimal
    currency: str = "INR"
    key_id: str
    subscription_id: int


class SubscriptionPaymentVerify(BaseModel):
    razorpay_order_id: str
    razorpay_payment_id: str
    razorpay_signature: str


# --- Product Schemas ---

class ProductCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=150)
    barcode: Optional[str] = None
    category: Optional[str] = "General"
    unit: str = Field("piece", description="kg, g, l, ml, piece, packet")
    purchase_price: Decimal = Field(Decimal("0.00"), ge=0)
    selling_price: Decimal = Field(..., ge=0)
    stock_quantity: Decimal = Field(Decimal("0.000"), ge=0)
    min_stock_threshold: Decimal = Field(Decimal("5.000"), ge=0)


class ProductUpdate(BaseModel):
    name: Optional[str] = None
    barcode: Optional[str] = None
    category: Optional[str] = None
    unit: Optional[str] = None
    purchase_price: Optional[Decimal] = Field(None, ge=0)
    selling_price: Optional[Decimal] = Field(None, ge=0)
    stock_quantity: Optional[Decimal] = Field(None, ge=0)
    min_stock_threshold: Optional[Decimal] = Field(None, ge=0)
    is_active: Optional[bool] = None


class ProductResponse(BaseModel):
    id: int
    shop_id: int
    name: str
    barcode: Optional[str] = None
    category: Optional[str] = None
    unit: str
    purchase_price: Decimal
    selling_price: Decimal
    stock_quantity: Decimal
    min_stock_threshold: Decimal
    is_active: bool
    is_low_stock: bool = False
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# --- Inventory & Stock Schemas ---

class StockAdjustment(BaseModel):
    change_quantity: Decimal = Field(..., description="Quantity to add (positive) or deduct (negative)")
    transaction_type: str = Field("ADJUSTMENT", description="RESTOCK, ADJUSTMENT, RETURN")
    reason: Optional[str] = None


class StockTransactionResponse(BaseModel):
    id: int
    product_id: int
    change_quantity: Decimal
    balance_quantity: Decimal
    transaction_type: str
    reason: Optional[str] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


# --- Customer & Khata Schemas ---

class CustomerCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    mobile_number: Optional[str] = None


class CustomerUpdate(BaseModel):
    name: Optional[str] = None
    mobile_number: Optional[str] = None


class CreditPaymentCreate(BaseModel):
    amount: Decimal = Field(..., gt=0, description="Amount paid by customer to clear khata balance")
    note: Optional[str] = "Customer Payment"


class CreditTransactionResponse(BaseModel):
    id: int
    customer_id: int
    sale_id: Optional[int] = None
    amount: Decimal
    transaction_type: str
    note: Optional[str] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class CustomerResponse(BaseModel):
    id: int
    shop_id: int
    name: str
    mobile_number: Optional[str] = None
    balance: Decimal
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class CustomerDetailResponse(CustomerResponse):
    recent_transactions: List[CreditTransactionResponse] = []


# --- Sales Schemas ---

class SaleItemCreate(BaseModel):
    product_id: int
    quantity: Decimal = Field(..., gt=0)


class SaleCreate(BaseModel):
    customer_id: Optional[int] = None
    discount: Decimal = Field(Decimal("0.00"), ge=0)
    payment_mode: str = Field("CASH", description="CASH, UPI, CREDIT")
    payment_status: Optional[str] = Field("PAID", description="PAID, UNPAID")
    items: List[SaleItemCreate] = Field(..., min_length=1)


class SaleItemResponse(BaseModel):
    id: int
    product_id: int
    product_name: str
    quantity: Decimal
    purchase_price: Decimal = Decimal("0.00")
    unit_price: Decimal
    subtotal: Decimal
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class SaleResponse(BaseModel):
    id: int
    shop_id: int
    customer_id: Optional[int] = None
    customer_name: Optional[str] = None
    total_amount: Decimal
    discount: Decimal
    final_amount: Decimal
    payment_mode: str
    payment_status: str = "PAID"
    profit: Decimal = Decimal("0.00")
    status: str
    created_at: datetime
    items: List[SaleItemResponse] = []

    model_config = ConfigDict(from_attributes=True)


# --- Dashboard Schemas ---

class DashboardMetrics(BaseModel):
    today_sales_amount: Decimal
    today_transactions_count: int
    today_cash_sales: Decimal
    today_upi_sales: Decimal
    today_credit_sales: Decimal
    today_paid_sales: Decimal = Decimal("0.00")
    today_unpaid_sales: Decimal = Decimal("0.00")
    today_profit: Decimal = Decimal("0.00")
    total_outstanding_credit: Decimal
    low_stock_count: int
    total_products_count: int
    total_customers_count: int


# --- Super Admin & Announcement Schemas ---

class AdminMetricsResponse(BaseModel):
    total_users: int
    total_shops: int
    total_revenue: Decimal
    monthly_recurring_revenue: Decimal
    new_registrations_today: int
    new_registrations_this_week: int
    active_subscriptions: int
    expiring_soon_subscriptions: int
    expired_subscriptions: int
    pending_subscriptions: int


class AdminShopItem(BaseModel):
    id: int
    shop_name: str
    owner_name: str
    mobile_number: Optional[str] = None
    email: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    created_at: datetime
    subscription_status: str
    subscription_end_date: Optional[datetime] = None
    sales_count: int = 0
    total_sales_amount: Decimal = Decimal("0.00")


class SendReminderRequest(BaseModel):
    shop_id: int
    channel: str = "WHATSAPP"  # WHATSAPP, SMS, EMAIL


class ExtendSubscriptionRequest(BaseModel):
    shop_id: int
    days: int = 30


class AnnouncementCreate(BaseModel):
    title: str = Field(..., min_length=2, max_length=200)
    message: str = Field(..., min_length=5)
    tag: str = "FEATURE"  # FEATURE, UPDATE, ALERT, OFFER
    action_url: Optional[str] = None


class AnnouncementResponse(BaseModel):
    id: int
    title: str
    message: str
    tag: str
    action_url: Optional[str] = None
    is_active: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
