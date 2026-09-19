from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict
from app.models.food_listing import FoodType, MealType, ListingStatus, StorageRequirement
from app.schemas.user import UserResponse


class FoodListingBase(BaseModel):
    title: str = Field(..., example="Surplus Lunch Meals - Rice, Dal & Sabzi")
    description: Optional[str] = Field(
        None, example="Freshly prepared lunch buffet surplus in clean stainless steel containers"
    )
    food_type: FoodType = FoodType.VEG
    meal_type: MealType = MealType.LUNCH
    quantity_servings: int = Field(..., gt=0, example=50)
    weight_kg: float = Field(..., gt=0, example=25.5)
    prepared_time: datetime
    expiry_time: datetime
    storage_requirement: StorageRequirement = StorageRequirement.ROOM_TEMP
    pickup_address: str = Field(..., example="Grand Regency Banquet Hall, MG Road")
    city: str = Field("Bangalore", example="Bangalore")
    latitude: Optional[float] = 12.9716
    longitude: Optional[float] = 77.5946
    contact_phone: Optional[str] = "+91 9876543210"


class FoodListingCreate(FoodListingBase):
    pass


class FoodListingUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    food_type: Optional[FoodType] = None
    meal_type: Optional[MealType] = None
    quantity_servings: Optional[int] = None
    weight_kg: Optional[float] = None
    expiry_time: Optional[datetime] = None
    status: Optional[ListingStatus] = None
    storage_requirement: Optional[StorageRequirement] = None
    pickup_address: Optional[str] = None
    contact_phone: Optional[str] = None


class FoodListingResponse(FoodListingBase):
    id: int
    provider_id: int
    status: ListingStatus
    created_at: datetime
    updated_at: Optional[datetime] = None
    provider: Optional[UserResponse] = None

    model_config = ConfigDict(from_attributes=True)


class ListingFilter(BaseModel):
    city: Optional[str] = None
    food_type: Optional[FoodType] = None
    status: Optional[ListingStatus] = ListingStatus.AVAILABLE
    min_servings: Optional[int] = None
