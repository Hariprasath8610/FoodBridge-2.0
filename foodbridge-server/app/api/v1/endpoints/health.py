from datetime import datetime
from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.ml.predictor import predictor
from app.services.firebase_service import firebase_service
from app.schemas.common import HealthResponse

router = APIRouter()


@router.get("/health", response_model=HealthResponse, tags=["Health"])
def health_check(db: Session = Depends(get_db)):
    """Health check endpoint verifying DB connectivity, Firebase status, and ML model."""
    db_status = "connected"
    try:
        db.execute(text("SELECT 1"))
    except Exception as e:
        db_status = f"unhealthy: {str(e)}"

    fb_status = "initialized" if firebase_service.is_initialized else "development_mock_mode"
    ml_status = predictor.is_loaded()

    return HealthResponse(
        status="ok" if db_status == "connected" else "degraded",
        version=settings.VERSION,
        environment=settings.ENV,
        database=db_status,
        firebase=fb_status,
        ml_model_loaded=ml_status,
        timestamp=datetime.utcnow().isoformat() + "Z",
    )
