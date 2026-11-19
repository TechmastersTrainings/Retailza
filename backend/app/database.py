import os
from urllib.parse import urlparse, parse_qs, urlencode, urlunparse
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from backend.app.config import settings

# Register PyMySQL as standard MySQLdb driver fallback
try:
    import pymysql
    pymysql.install_as_MySQLdb()
except ImportError:
    pass

if os.environ.get("PYTEST_CURRENT_TEST") or os.environ.get("TESTING"):
    DATABASE_URL = "sqlite:///:memory:"
else:
    DATABASE_URL = os.environ.get("DATABASE_URL") or settings.DATABASE_URL
connect_args = {}
engine_kwargs = {"echo": False}

# Automatically normalize PostgreSQL and MySQL URI schemes for SQLAlchemy drivers
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql+psycopg2://", 1)
elif DATABASE_URL.startswith("postgresql://") and not DATABASE_URL.startswith("postgresql+"):
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+psycopg2://", 1)
elif "mysql" in DATABASE_URL:
    if DATABASE_URL.startswith("mysql://") and not DATABASE_URL.startswith("mysql+"):
        DATABASE_URL = DATABASE_URL.replace("mysql://", "mysql+pymysql://", 1)

    # Cloud MySQL providers (e.g. Aiven) append ?ssl-mode=REQUIRED or ?sslmode=...
    # PyMySQL expects ssl as a dictionary in connect_args, not as URL query parameters.
    try:
        parsed_db = urlparse(DATABASE_URL)
        query_params = parse_qs(parsed_db.query)
        ssl_enabled = False
        for param in list(query_params.keys()):
            if param.lower() in ("ssl-mode", "sslmode", "ssl_mode"):
                mode_val = query_params.pop(param)[0].lower()
                if mode_val not in ("disabled", "disable", "none", "0", "false"):
                    ssl_enabled = True

        new_query = urlencode(query_params, doseq=True)
        DATABASE_URL = urlunparse(parsed_db._replace(query=new_query))
        if ssl_enabled:
            connect_args["ssl"] = {"check_hostname": False}
    except Exception as parse_err:
        print(f"[database.py] MySQL URL query parse notice: {parse_err}")

if DATABASE_URL.startswith("sqlite"):
    connect_args["check_same_thread"] = False
elif "postgresql" in DATABASE_URL or "postgres" in DATABASE_URL:
    engine_kwargs["pool_pre_ping"] = True
    engine_kwargs["pool_recycle"] = 300
    engine_kwargs["pool_size"] = 10
    engine_kwargs["max_overflow"] = 20
elif "mysql" in DATABASE_URL:
    engine_kwargs["pool_pre_ping"] = True
    engine_kwargs["pool_recycle"] = 3600
    engine_kwargs["pool_size"] = 10
    engine_kwargs["max_overflow"] = 20
    connect_args["charset"] = "utf8mb4"

engine = create_engine(
    DATABASE_URL,
    connect_args=connect_args,
    **engine_kwargs
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

from sqlalchemy import inspect, text, func

Base = declarative_base()


def init_db():
    """Create all tables and run lightweight migrations for new columns."""
    import backend.app.models  # noqa: F401 - register models on Base.metadata
    Base.metadata.create_all(bind=engine)

    inspector = inspect(engine)
    existing_tables = inspector.get_table_names()

    with engine.connect() as conn:
        # Check users table
        if "users" in existing_tables:
            user_cols = [c["name"] for c in inspector.get_columns("users")]
            if "email" not in user_cols:
                conn.execute(text("ALTER TABLE users ADD COLUMN email VARCHAR(150);"))
            if "hashed_password" not in user_cols:
                conn.execute(text("ALTER TABLE users ADD COLUMN hashed_password VARCHAR(255);"))

        # Check otp_verifications table
        if "otp_verifications" in existing_tables:
            otp_cols = [c["name"] for c in inspector.get_columns("otp_verifications")]
            if "identifier" not in otp_cols:
                conn.execute(text("ALTER TABLE otp_verifications ADD COLUMN identifier VARCHAR(150);"))

        # Check shops table
        if "shops" in existing_tables:
            shop_cols = [c["name"] for c in inspector.get_columns("shops")]
            if "upi_qr_image" not in shop_cols:
                conn.execute(text("ALTER TABLE shops ADD COLUMN upi_qr_image LONGTEXT;" if "mysql" in DATABASE_URL else "ALTER TABLE shops ADD COLUMN upi_qr_image TEXT;"))
            elif "mysql" in DATABASE_URL:
                try:
                    conn.execute(text("ALTER TABLE shops MODIFY COLUMN upi_qr_image LONGTEXT;"))
                except Exception as mod_err:
                    print(f"[init_db] upi_qr_image modify notice: {mod_err}")
            if "upi_id" not in shop_cols:
                conn.execute(text("ALTER TABLE shops ADD COLUMN upi_id VARCHAR(100);"))
            if "category" not in shop_cols:
                conn.execute(text("ALTER TABLE shops ADD COLUMN category VARCHAR(100) DEFAULT 'Provision Store';"))

        # Check sales table
        if "sales" in existing_tables:
            sales_cols = [c["name"] for c in inspector.get_columns("sales")]
            if "payment_status" not in sales_cols:
                conn.execute(text("ALTER TABLE sales ADD COLUMN payment_status VARCHAR(20) DEFAULT 'PAID';"))
            if "profit" not in sales_cols:
                conn.execute(text("ALTER TABLE sales ADD COLUMN profit NUMERIC(10, 2) DEFAULT 0.00;"))

        # Check sale_items table
        if "sale_items" in existing_tables:
            item_cols = [c["name"] for c in inspector.get_columns("sale_items")]
            if "purchase_price" not in item_cols:
                conn.execute(text("ALTER TABLE sale_items ADD COLUMN purchase_price NUMERIC(10, 2) DEFAULT 0.00;"))

        conn.commit()

    # Seed Default Super Admin Accounts
    try:
        from backend.app.models import User
        from backend.app.utils.security import hash_password
        with SessionLocal() as db:
            default_admins = [
                {
                    "email": "admin@retailza.com",
                    "mobile_number": "9999999999",
                    "name": "Retailza Super Admin",
                    "role": "SUPER_ADMIN",
                    "password": "Admin@Retailza2026"
                },
                {
                    "email": "techmastersinnovations@gmail.com",
                    "mobile_number": "9888888888",
                    "name": "Techmasters Admin",
                    "role": "SUPER_ADMIN",
                    "password": "Fri10Feb@2023"
                }
            ]
            for admin_info in default_admins:
                target_email = admin_info["email"].lower()
                admin = db.query(User).filter(
                    (func.lower(User.email) == target_email) | (User.mobile_number == admin_info["mobile_number"])
                ).first()
                if not admin:
                    admin = User(
                        email=target_email,
                        mobile_number=admin_info["mobile_number"],
                        name=admin_info["name"],
                        role="SUPER_ADMIN",
                        hashed_password=hash_password(admin_info["password"]),
                        is_active=True
                    )
                    db.add(admin)
                    db.commit()
                else:
                    admin.role = "SUPER_ADMIN"
                    admin.email = target_email
                    admin.hashed_password = hash_password(admin_info["password"])
                    db.commit()
    except Exception as e:
        print(f"[init_db] Super Admin seeding notice: {e}")


def get_db():
    """Dependency that provides an active database session and closes it afterwards."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

