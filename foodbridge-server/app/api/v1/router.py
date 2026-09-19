from fastapi import APIRouter
from app.api.v1.endpoints import health, auth, listings, claims, predictions, analytics

api_router = APIRouter()

api_router.include_router(health.router)
api_router.include_router(auth.router)
api_router.include_router(listings.router)
api_router.include_router(claims.router)
api_router.include_router(predictions.router)
api_router.include_router(analytics.router)
