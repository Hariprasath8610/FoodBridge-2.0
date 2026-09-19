from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict
from app.models.rescue_mission import RescueStatus, FoodSafetyStatus


class RescueRequestCreate(BaseModel):
    provider_id: int = Field(..., example=1, description="Food provider user ID")
    quantity: int = Field(..., gt=0, example=85, description="Number of meals to rescue")
    prediction_id: Optional[str] = Field(None, example="pred_017500598a14")
    food_source_id: Optional[int] = Field(None, example=1)
    recipient_id: Optional[int] = Field(
        None, example=6, description="Recipient user ID (auto-detected if logged in)"
    )


class FoodVerificationRequest(BaseModel):
    safety_status: FoodSafetyStatus = FoodSafetyStatus.SAFE_VERIFIED
    temperature_c: Optional[float] = Field(
        None, example=68.5, description="Internal food temperature in Celsius"
    )
    notes: Optional[str] = Field(
        None, example="Hygienically packaged in food-grade insulated thermoware."
    )


class PickupVerificationRequest(BaseModel):
    pickup_otp: Optional[str] = Field(None, min_length=4, max_length=10, example="592810")
    rescue_code: Optional[str] = Field(None, example="RESCUE-20260919-A1B2C3")
    qr_data: Optional[str] = Field(None, example='{"rescue_code": "RESCUE-20260919-A1B2C3"}')


class DeliveryVerificationRequest(BaseModel):
    delivery_otp: Optional[str] = Field(None, min_length=4, max_length=10, example="839102")
    rescue_code: Optional[str] = Field(None, example="RESCUE-20260919-A1B2C3")
    qr_data: Optional[str] = Field(None, example='{"rescue_code": "RESCUE-20260919-A1B2C3"}')


class QRVerificationRequest(BaseModel):
    qr_data: str = Field(..., example='{"rescue_code": "RESCUE-20260919-A1B2C3"}')
    action: Optional[str] = Field(None, example="pickup", description="'pickup' or 'delivery'")
    rescue_id: Optional[int] = None


class RescueMissionResponse(BaseModel):
    id: int
    rescue_code: str
    prediction_id: Optional[str] = None
    provider_id: int
    recipient_id: int
    food_source_id: Optional[int] = None
    quantity: int
    status: RescueStatus
    food_safety_status: FoodSafetyStatus
    pickup_otp: str
    delivery_otp: str
    pickup_time: Optional[datetime] = None
    delivery_time: Optional[datetime] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)
