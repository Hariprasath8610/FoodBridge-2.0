from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict
from app.models.claim import ClaimStatus
from app.schemas.food_listing import FoodListingResponse
from app.schemas.user import UserResponse


class ClaimCreate(BaseModel):
    listing_id: int = Field(..., example=1)
    servings_requested: int = Field(..., gt=0, example=30)
    notes: Optional[str] = Field(
        None, example="Volunteer transport van arriving at 2:30 PM with hot boxes"
    )


class ClaimStatusUpdate(BaseModel):
    status: ClaimStatus


class ClaimVerifyOTP(BaseModel):
    pickup_otp: str = Field(..., min_length=4, max_length=10, example="482910")


class ClaimResponse(BaseModel):
    id: int
    listing_id: int
    recipient_id: int
    status: ClaimStatus
    servings_requested: int
    notes: Optional[str] = None
    pickup_otp: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    listing: Optional[FoodListingResponse] = None
    recipient: Optional[UserResponse] = None

    model_config = ConfigDict(from_attributes=True)
