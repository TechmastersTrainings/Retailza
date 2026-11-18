from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from backend.app.config import settings

# Register PyMySQL as standard MySQLdb driver fallback
try:
    import pymysql
    pymysql.install_as_MySQLdb()
except ImportError:
    pass

DATABASE_URL = settings.DATABASE_URL
# Automatically normalize PostgreSQL and MySQL URI schemes for SQLAlchemy drivers
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql+psycopg2://", 1)
elif DATABASE_URL.startswith("postgresql://") and not DATABASE_URL.startswith("postgresql+"):
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+psycopg2://", 1)
elif DATABASE_URL.startswith("mysql://") and not DATABASE_URL.startswith("mysql+"):
    DATABASE_URL = DATABASE_URL.replace("mysql://", "mysql+pymysql://", 1)

connect_args = {}
engine_kwargs = {"echo": False}

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
                conn.execute(text("ALTER TABLE shops ADD COLUMN upi_qr_image TEXT;"))
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

        # Check otp_verifications table (abuse-protection columns)
        if "otp_verifications" in existing_tables:
            otp_cols = [c["name"] for c in inspector.get_columns("otp_verifications")]
            if "attempts" not in otp_cols:
                conn.execute(text("ALTER TABLE otp_verifications ADD COLUMN attempts INTEGER DEFAULT 0;"))
            if "request_count" not in otp_cols:
                conn.execute(text("ALTER TABLE otp_verifications ADD COLUMN request_count INTEGER DEFAULT 1;"))

        conn.commit()

    seed_super_admin()


def seed_super_admin():
    """
    Create ONE super-admin from environment variables, only if it does not
    already exist. Credentials are never hard-coded, and an existing admin's
    password is never reset on boot. If SEED_ADMIN_EMAIL/PASSWORD are unset,
    no admin is created (configure them in the Render dashboard).
    """
    from backend.app.config import settings

    email = (settings.SEED_ADMIN_EMAIL or "").strip().lower()
    password = settings.SEED_ADMIN_PASSWORD or ""
    if not email or not password:
        print("[init_db] SEED_ADMIN_EMAIL/SEED_ADMIN_PASSWORD not set; skipping admin seeding.")
        return

    try:
        from backend.app.models import User
        from backend.app.utils.security import hash_password
        mobile = (settings.SEED_ADMIN_MOBILE or "").strip() or None
        with SessionLocal() as db:
            match = func.lower(User.email) == email
            if mobile:
                match = match | (User.mobile_number == mobile)
            existing = db.query(User).filter(match).first()
            if existing:
                print(f"[init_db] Super admin {email} already exists; left unchanged.")
                return
            db.add(User(
                email=email,
                mobile_number=mobile,
                name=settings.SEED_ADMIN_NAME or "Retailza Super Admin",
                role="SUPER_ADMIN",
                hashed_password=hash_password(password),
                is_active=True,
            ))
            db.commit()
            print(f"[init_db] Seeded super admin {email}.")
    except Exception as e:
        print(f"[init_db] Super Admin seeding notice: {e}")


def get_db():
    """Dependency that provides an active database session and closes it afterwards."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

