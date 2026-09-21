from typing import Optional
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from backend.app.database import get_db
from backend.app.models import SystemAnnouncement
from backend.app.schemas import AnnouncementResponse

router = APIRouter(prefix="/announcements", tags=["Announcements"])


@router.get("/latest", response_model=Optional[AnnouncementResponse])
def get_latest_announcement(db: Session = Depends(get_db)):
    """Fetch the latest active announcement to display inside the mobile app dashboard."""
    return db.query(SystemAnnouncement)\
        .filter(SystemAnnouncement.is_active == True)\
        .order_by(SystemAnnouncement.created_at.desc())\
        .first()
