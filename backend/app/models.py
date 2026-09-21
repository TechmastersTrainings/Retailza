from datetime import datetime
from sqlalchemy import (
    Column, Integer, String, Boolean, DateTime, Numeric, ForeignKey, Text
)
from sqlalchemy.orm import relationship
from backend.app.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    mobile_number = Column(String(15), unique=True, index=True, nullable=True)
    email = Column(String(150), unique=True, index=True, nullable=True)
    hashed_password = Column(String(255), nullable=True)
    name = Column(String(100), nullable=True)
    role = Column(String(20), default="OWNER", nullable=False)  # OWNER, SUPER_ADMIN
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    shops = relationship("Shop", back_populates="owner", cascade="all, delete-orphan")


class OTPVerification(Base):
    __tablename__ = "otp_verifications"

    id = Column(Integer, primary_key=True, index=True)
    identifier = Column(String(150), index=True, nullable=True)  # Mobile number or email
    mobile_number = Column(String(15), index=True, nullable=True)
    otp_code = Column(String(10), nullable=False)
    expires_at = Column(DateTime, nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)


class Shop(Base):
    __tablename__ = "shops"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    shop_name = Column(String(150), nullable=False)
    owner_name = Column(String(100), nullable=False)
    address = Column(String(255), nullable=True)
    city = Column(String(100), nullable=True)
    state = Column(String(100), nullable=True)
    pincode = Column(String(10), nullable=True)
    upi_qr_image = Column(Text, nullable=True)
    upi_id = Column(String(100), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    owner = relationship("User", back_populates="shops")
    subscription = relationship("Subscription", back_populates="shop", uselist=False, cascade="all, delete-orphan")
    products = relationship("Product", back_populates="shop", cascade="all, delete-orphan")
    sales = relationship("Sale", back_populates="shop", cascade="all, delete-orphan")
    customers = relationship("Customer", back_populates="shop", cascade="all, delete-orphan")


class Subscription(Base):
    __tablename__ = "subscriptions"

    id = Column(Integer, primary_key=True, index=True)
    shop_id = Column(Integer, ForeignKey("shops.id", ondelete="CASCADE"), unique=True, nullable=False)
    plan_name = Column(String(50), default="basic", nullable=False)
    amount = Column(Numeric(10, 2), default=49.00, nullable=False)
    status = Column(String(20), default="PENDING", nullable=False)  # PENDING, ACTIVE, EXPIRED
    start_date = Column(DateTime, nullable=True)
    end_date = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    shop = relationship("Shop", back_populates="subscription")
    payments = relationship("SubscriptionPayment", back_populates="subscription", cascade="all, delete-orphan")


class SubscriptionPayment(Base):
    __tablename__ = "subscription_payments"

    id = Column(Integer, primary_key=True, index=True)
    subscription_id = Column(Integer, ForeignKey("subscriptions.id", ondelete="CASCADE"), nullable=False)
    payment_id = Column(String(100), nullable=True)
    order_id = Column(String(100), nullable=True)
    signature = Column(String(255), nullable=True)
    amount = Column(Numeric(10, 2), nullable=False)
    status = Column(String(20), default="SUCCESS", nullable=False)  # PENDING, SUCCESS, FAILED
    payment_method = Column(String(50), default="RAZORPAY", nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    subscription = relationship("Subscription", back_populates="payments")


class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    shop_id = Column(Integer, ForeignKey("shops.id", ondelete="CASCADE"), index=True, nullable=False)
    name = Column(String(150), index=True, nullable=False)
    barcode = Column(String(100), index=True, nullable=True)
    category = Column(String(100), index=True, default="General", nullable=True)
    unit = Column(String(20), default="piece", nullable=False)  # kg, g, l, ml, piece, packet
    purchase_price = Column(Numeric(10, 2), default=0.00, nullable=False)
    selling_price = Column(Numeric(10, 2), nullable=False)
    stock_quantity = Column(Numeric(10, 3), default=0.000, nullable=False)
    min_stock_threshold = Column(Numeric(10, 3), default=5.000, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    shop = relationship("Shop", back_populates="products")
    stock_transactions = relationship("StockTransaction", back_populates="product", cascade="all, delete-orphan")
    sale_items = relationship("SaleItem", back_populates="product")


class StockTransaction(Base):
    __tablename__ = "stock_transactions"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id", ondelete="CASCADE"), index=True, nullable=False)
    change_quantity = Column(Numeric(10, 3), nullable=False)  # + or -
    balance_quantity = Column(Numeric(10, 3), nullable=False)
    transaction_type = Column(String(20), nullable=False)  # RESTOCK, SALE, ADJUSTMENT, RETURN
    reason = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    product = relationship("Product", back_populates="stock_transactions")


class Customer(Base):
    __tablename__ = "customers"

    id = Column(Integer, primary_key=True, index=True)
    shop_id = Column(Integer, ForeignKey("shops.id", ondelete="CASCADE"), index=True, nullable=False)
    name = Column(String(100), nullable=False)
    mobile_number = Column(String(15), index=True, nullable=True)
    balance = Column(Numeric(10, 2), default=0.00, nullable=False)  # positive = owes shopkeeper
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    shop = relationship("Shop", back_populates="customers")
    credit_transactions = relationship("CreditTransaction", back_populates="customer", cascade="all, delete-orphan")
    sales = relationship("Sale", back_populates="customer")


class Sale(Base):
    __tablename__ = "sales"

    id = Column(Integer, primary_key=True, index=True)
    shop_id = Column(Integer, ForeignKey("shops.id", ondelete="CASCADE"), index=True, nullable=False)
    customer_id = Column(Integer, ForeignKey("customers.id", ondelete="SET NULL"), nullable=True)
    total_amount = Column(Numeric(10, 2), nullable=False)
    discount = Column(Numeric(10, 2), default=0.00, nullable=False)
    final_amount = Column(Numeric(10, 2), nullable=False)
    payment_mode = Column(String(20), default="CASH", nullable=False)  # CASH, UPI, CREDIT
    payment_status = Column(String(20), default="PAID", nullable=False)  # PAID, UNPAID
    profit = Column(Numeric(10, 2), default=0.00, nullable=False)
    status = Column(String(20), default="COMPLETED", nullable=False)  # COMPLETED, CANCELLED
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    shop = relationship("Shop", back_populates="sales")
    customer = relationship("Customer", back_populates="sales")
    items = relationship("SaleItem", back_populates="sale", cascade="all, delete-orphan")
    credit_transactions = relationship("CreditTransaction", back_populates="sale")


class SaleItem(Base):
    __tablename__ = "sale_items"

    id = Column(Integer, primary_key=True, index=True)
    sale_id = Column(Integer, ForeignKey("sales.id", ondelete="CASCADE"), index=True, nullable=False)
    product_id = Column(Integer, ForeignKey("products.id", ondelete="RESTRICT"), nullable=False)
    product_name = Column(String(150), nullable=False)
    quantity = Column(Numeric(10, 3), nullable=False)
    purchase_price = Column(Numeric(10, 2), default=0.00, nullable=False)
    unit_price = Column(Numeric(10, 2), nullable=False)
    subtotal = Column(Numeric(10, 2), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    sale = relationship("Sale", back_populates="items")
    product = relationship("Product", back_populates="sale_items")


class CreditTransaction(Base):
    __tablename__ = "credit_transactions"

    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(Integer, ForeignKey("customers.id", ondelete="CASCADE"), index=True, nullable=False)
    sale_id = Column(Integer, ForeignKey("sales.id", ondelete="SET NULL"), nullable=True)
    amount = Column(Numeric(10, 2), nullable=False)
    transaction_type = Column(String(20), nullable=False)  # CREDIT_GIVEN, PAYMENT_RECEIVED
    note = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    customer = relationship("Customer", back_populates="credit_transactions")
    sale = relationship("Sale", back_populates="credit_transactions")


class SystemAnnouncement(Base):
    __tablename__ = "system_announcements"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    message = Column(Text, nullable=False)
    tag = Column(String(50), default="FEATURE", nullable=False)  # FEATURE, UPDATE, ALERT, OFFER
    action_url = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
