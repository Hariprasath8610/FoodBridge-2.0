from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.schemas.food_listing import (
    FoodListingCreate,
    FoodListingResponse,
    FoodListingUpdate,
)
from app.services.listing_service import listing_service

router = APIRouter(prefix="/listings", tags=["Food Listings"])


@router.get("", response_model=List[FoodListingResponse])
def get_listings(
    city: Optional[str] = Query(None, description="City filter"),
    food_type: Optional[str] = Query(None, description="VEG, NON_VEG, BOTH"),
    status: Optional[str] = Query("AVAILABLE", description="Listing status"),
    min_servings: Optional[int] = Query(None, ge=1),
    provider_id: Optional[int] = Query(None),
    limit: int = Query(50, ge=1, le=100),
    skip: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    """Retrieve food surplus listings with filtering."""
    return listing_service.list_listings(
        db,
        status=status,
        city=city,
        food_type=food_type,
        min_servings=min_servings,
        provider_id=provider_id,
        limit=limit,
        skip=skip,
    )


@router.post(
    "",
    response_model=FoodListingResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_listing(
    data: FoodListingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Publish a new surplus food listing (Provider role required)."""
    return listing_service.create(db, data, provider=current_user)


@router.get("/{listing_id}", response_model=FoodListingResponse)
def get_listing_detail(
    listing_id: int,
    db: Session = Depends(get_db),
):
    """Get single food surplus listing by ID."""
    return listing_service.get_by_id(db, listing_id)


@router.put("/{listing_id}", response_model=FoodListingResponse)
def update_listing(
    listing_id: int,
    data: FoodListingUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update food surplus listing (Owner provider only)."""
    return listing_service.update(db, listing_id, data, current_user=current_user)
