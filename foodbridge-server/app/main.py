import os
from contextlib import asynccontextmanager
from datetime import datetime
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, FileResponse
from sqlalchemy import text

from app.api import me, predictions_api, matching_api, recipients_api, rescues_api, dashboard_api
from app.api.v1.router import api_router
from app.core.config import settings
from app.core.database import Base, engine, SessionLocal
from app.core.exceptions import (
    AppException,
    app_exception_handler,
    generic_exception_handler,
    validation_exception_handler,
)
from app.ml.predictor import predictor
from app.schemas.common import HealthResponse
from app.services.firebase_service import firebase_service


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for application startup and shutdown events."""
    # Ensure database schema is initialized
    Base.metadata.create_all(bind=engine)
    # Ensure ML predictor is loaded or trained
    if not predictor.is_loaded():
        predictor._load_or_train()
    yield


app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="AI-Powered Surplus Food Prediction & Rescue Platform",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

# Store debug flag in app state for exception handler
app.state.debug = settings.DEBUG

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register custom exception handlers
app.add_exception_handler(AppException, app_exception_handler)
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(Exception, generic_exception_handler)


@app.get("/", tags=["Root"])
def root():
    """Root endpoint welcoming developers and linking to API documentation."""
    return {
        "project": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "description": settings.DESCRIPTION,
        "environment": settings.ENV,
        "documentation": {
            "swagger": "/docs",
            "redoc": "/redoc",
            "openapi": "/openapi.json",
        },
        "health": "/health",
        "api_v1": settings.API_V1_STR,
        "endpoints": {
            "me": "/api/me",
            "predictions": "/api/predictions",
            "feedback": "/api/predictions/{id}/feedback",
            "matching": "/api/matching/{prediction_id}",
            "recipients": "/api/recipients",
            "demand": "/api/recipients/demand",
            "rescues": "/api/rescues",
            "impact_dashboard": "/api/dashboard/impact",
        },
    }


@app.get("/health", response_model=HealthResponse, tags=["Health"])
@app.get("/api/health", response_model=HealthResponse, tags=["Health"])
def root_health():
    """Root health check endpoint verifying database, Firebase, and ML predictor status."""
    db_status = "connected"
    try:
        with SessionLocal() as session:
            session.execute(text("SELECT 1"))
    except Exception as e:
        db_status = f"unhealthy: {str(e)}"

    return HealthResponse(
        status="ok" if db_status == "connected" else "degraded",
        version=settings.VERSION,
        environment=settings.ENV,
        database=db_status,
        firebase="initialized" if firebase_service.is_initialized else "development_mock_mode",
        ml_model_loaded=predictor.is_loaded(),
        timestamp=datetime.utcnow().isoformat() + "Z",
    )


@app.get("/apk", tags=["APK Distribution"])
@app.get("/download/apk", tags=["APK Distribution"])
def download_release_apk():
    """Serves the compiled FoodBridge Android release APK directly over Wi-Fi/LAN."""
    apk_path = os.path.abspath("C:/FoodBridge 2.0/foodbridge-mobile/build/app/outputs/flutter-apk/app-release.apk")
    if not os.path.exists(apk_path):
        return JSONResponse(status_code=404, content={"detail": "APK not found on host disk."})
    return FileResponse(
        path=apk_path,
        filename="FoodBridge-release.apk",
        media_type="application/vnd.android.package-archive",
    )


# Mount direct /api routes
app.include_router(me.router, prefix="/api")
app.include_router(predictions_api.router, prefix="/api")
app.include_router(matching_api.router, prefix="/api")
app.include_router(recipients_api.router, prefix="/api")
app.include_router(rescues_api.router, prefix="/api")
app.include_router(dashboard_api.router, prefix="/api")

# Mount API v1 routes
app.include_router(api_router, prefix=settings.API_V1_STR)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
    )
