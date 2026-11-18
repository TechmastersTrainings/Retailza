from decimal import Decimal

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from backend.app.database import Base, get_db
from backend.app.main import app

# In-memory SQLite for super-fast, clean, isolated test runs
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


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


@pytest.fixture(autouse=True)
def upi_configured(monkeypatch):
    """Configure a collecting UPI ID so /subscriptions/create-order works.
    Direct UPI billing has no external service to fake — the backend just
    builds a upi:// intent and verifies UTRs the shop owner submits."""
    from backend.app.config import settings
    monkeypatch.setattr(settings, "SUBSCRIPTION_UPI_ID", "retailza@okhdfcbank")
    monkeypatch.setattr(settings, "SUBSCRIPTION_UPI_PAYEE", "Retailza")
    monkeypatch.setattr(settings, "SUBSCRIPTION_AUTO_ACTIVATE_ON_UTR", True)
    return settings
