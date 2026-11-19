import os
os.environ["TESTING"] = "1"
os.environ["DATABASE_URL"] = "sqlite:///:memory:"
from decimal import Decimal

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

import backend.app.database as db_module
from backend.app.config import settings

# Force SQLite for test runs so tests are 100% offline and isolated
settings.DATABASE_URL = "sqlite:///:memory:"
db_module.DATABASE_URL = "sqlite:///:memory:"

from backend.app.database import Base, get_db
from backend.app.main import app

# In-memory SQLite for super-fast, clean, isolated test runs
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
db_module.engine = engine
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db_module.SessionLocal = TestingSessionLocal


@pytest.fixture(scope="function")
def db_session():
    """Create fresh database tables for each test function."""
    Base.metadata.create_all(bind=engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=engine)


@pytest.fixture(scope="function")
def client(db_session):
    """Override get_db with the test session."""
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


class FakeUpiGateway:
    """In-memory stand-in for the UPI Gateway merchant API (no network)."""

    def __init__(self):
        self.orders = {}
        self.unavailable = False

    def create_order(self, amount, client_order_id, note=None, customer_name=None, customer_mobile=None):
        from backend.app.utils.upi_gateway import UpiGatewayError
        if self.unavailable:
            raise UpiGatewayError("Payment server is not reachable. Please try again.")
        order_id = f"ORDTEST{len(self.orders) + 1:08d}"
        amount_str = f"{Decimal(amount):.2f}"
        self.orders[order_id] = {
            "order_id": order_id,
            "client_order_id": client_order_id,
            "amount": amount_str,
            "currency": "INR",
            "status": "pending",
            "environment": "live",
            "test": False,
            "utr": None,
            "payment_url": f"https://pay.example.test/pay/{order_id}",
            "upi_intent": f"upi://pay?pa=retailza%40upi&am={amount_str}&cu=INR&tr={order_id}",
            "expires_at": "2026-11-18T12:15:00+05:30",
        }
        return dict(self.orders[order_id])

    def get_order(self, order_id):
        from backend.app.utils.upi_gateway import UpiGatewayError
        if self.unavailable:
            raise UpiGatewayError("Payment server is not reachable. Please try again.")
        if order_id not in self.orders:
            raise UpiGatewayError("Payment order was not found.")
        return dict(self.orders[order_id])

    def set(self, order_id, **changes):
        self.orders[order_id].update(changes)


@pytest.fixture
def fake_gateway(monkeypatch):
    from backend.app.utils import upi_gateway
    gateway = FakeUpiGateway()
    monkeypatch.setattr(upi_gateway, "create_order", gateway.create_order)
    monkeypatch.setattr(upi_gateway, "get_order", gateway.get_order)
    return gateway
