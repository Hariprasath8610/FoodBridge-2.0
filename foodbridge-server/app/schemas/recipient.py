from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class RecipientBase(BaseModel):
    organization_name: str = Field(..., example="Hope Community Kitchen")
    organization_type: str = Field(..., example="community_kitchen")
    people_served: int = Field(100, ge=1, example=250)
    current_demand: int = Field(..., ge=0, example=120)
    maximum_capacity: int = Field(..., gt=0, example=300)
    food_preferences: str = Field("all", example="vegetarian")
    availability_start: str = Field("08:00", example="07:00")
    availability_end: str = Field("22:00", example="23:00")
    latitude: float = Field(..., example=12.9785)
    longitude: float = Field(..., example=77.6010)
    verification_status: str = Field("VERIFIED", example="VERIFIED")


class RecipientCreate(RecipientBase):
    user_id: Optional[int] = None


class RecipientDemandUpdate(BaseModel):
    recipient_id: Optional[int] = Field(None, example=1)
    current_demand: int = Field(..., ge=0, example=140)
    people_served: Optional[int] = Field(None, example=250)
    food_preferences: Optional[str] = Field(None, example="vegetarian")
    availability_start: Optional[str] = Field(None, example="08:00")
    availability_end: Optional[str] = Field(None, example="22:00")


class RecipientResponse(RecipientBase):
    id: int
    user_id: Optional[int] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
