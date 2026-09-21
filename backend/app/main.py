from pathlib import Path
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from backend.app.database import engine, Base, init_db
from backend.app.config import settings
from backend.app.routers import (
    auth, shops, subscriptions, products, inventory, sales, customers, dashboard,
    admin, announcements
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize database tables and columns on startup
    init_db()
    yield


app = FastAPI(
    title=settings.APP_NAME,
    description="Commercial Kirana SaaS API for Billing, Inventory, Khata & Metrics",
    version="1.0.0",
    lifespan=lifespan
)

# Enable CORS for Flutter mobile client, web, and local development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount Routers under /api
app.include_router(auth.router, prefix="/api")
app.include_router(shops.router, prefix="/api")
app.include_router(subscriptions.router, prefix="/api")
app.include_router(products.router, prefix="/api")
app.include_router(inventory.router, prefix="/api")
app.include_router(sales.router, prefix="/api")
app.include_router(customers.router, prefix="/api")
app.include_router(dashboard.router, prefix="/api")
app.include_router(admin.router, prefix="/api")
app.include_router(announcements.router, prefix="/api")

# Mount Super Admin Website static files
admin_static_dir = Path(__file__).resolve().parent / "static" / "admin"
admin_static_dir.mkdir(parents=True, exist_ok=True)
app.mount("/admin", StaticFiles(directory=str(admin_static_dir), html=True), name="admin")


@app.get("/")
def root():
    return {
        "app": settings.APP_NAME,
        "company": "TechMasters Innovations Private Limited",
        "status": "online",
        "version": "1.0.0",
        "docs": "/docs",
        "privacy_policy": "/privacy",
        "terms_conditions": "/terms"
    }


static_dir = Path(__file__).resolve().parent / "static"


@app.get("/privacy")
def get_privacy_page():
    return FileResponse(static_dir / "privacy.html")


@app.get("/terms")
def get_terms_page():
    return FileResponse(static_dir / "terms.html")


@app.get("/api/legal/info")
def get_legal_info():
    return {
        "brand_name": "Retailza",
        "company_name": "TechMasters Innovations Private Limited",
        "copyright": "© 2026 TechMasters Innovations Private Limited. All rights reserved.",
        "support_email": "support@retailza.com",
        "privacy_email": "privacy@retailza.com",
        "last_updated": "September 20, 2026",
        "privacy_url": "/privacy",
        "terms_url": "/terms"
    }


@app.get("/api/health")
def health_check():
    return {
        "status": "healthy",
        "environment": settings.APP_ENV
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("backend.app.main:app", host="0.0.0.0", port=8000, reload=True)
