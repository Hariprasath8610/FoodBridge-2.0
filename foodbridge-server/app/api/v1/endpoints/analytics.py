from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.claim import Claim, ClaimStatus
from app.models.food_listing import FoodListing, ListingStatus
from app.models.user import User, UserRole

router = APIRouter(prefix="/analytics", tags=["Impact & Analytics"])


@router.get("/impact")
def get_impact_metrics(db: Session = Depends(get_db)):
    """Calculate aggregate social and environmental impact metrics."""
    # Count verified organizations
    provider_count = (
        db.query(func.count(User.id))
        .filter(User.role == UserRole.SENDER.value)
        .scalar()
        or 0
    )
    recipient_count = (
        db.query(func.count(User.id))
        .filter(User.role == UserRole.RECIPIENT.value)
        .scalar()
        or 0
    )

    # Completed rescues
    completed_claims = (
        db.query(Claim)
        .filter(Claim.status.in_([ClaimStatus.COMPLETED.value, ClaimStatus.APPROVED.value]))
        .all()
    )

    meals_rescued = sum(c.servings_requested for c in completed_claims)
    kg_saved = round(meals_rescued * 0.45, 1)
    co2_kg_avoided = round(kg_saved * 2.5, 1)  # 2.5 kg CO2e avoided per 1 kg food waste diverted

    # Active surplus listings currently on platform
    active_listings_count = (
        db.query(func.count(FoodListing.id))
        .filter(FoodListing.status == ListingStatus.AVAILABLE.value)
        .scalar()
        or 0
    )

    active_servings_available = (
        db.query(func.sum(FoodListing.quantity_servings))
        .filter(FoodListing.status == ListingStatus.AVAILABLE.value)
        .scalar()
        or 0
    )

    return {
        "success": True,
        "data": {
            "meals_rescued": meals_rescued,
            "food_diverted_kg": kg_saved,
            "co2_emissions_avoided_kg": co2_kg_avoided,
            "verified_food_providers": provider_count,
            "verified_food_recipients": recipient_count,
            "currently_available_listings": active_listings_count,
            "currently_available_servings": active_servings_available,
        },
    }
