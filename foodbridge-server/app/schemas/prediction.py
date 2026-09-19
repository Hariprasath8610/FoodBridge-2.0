from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field, ConfigDict


class PredictionFactor(BaseModel):
    factor: str = Field(..., example="weather")
    effect: str = Field(..., example="increase_risk")
    description: str = Field(..., example="Heavy rain can reduce event attendance.")


class PredictionRequest(BaseModel):
    expected_people: int = Field(..., gt=0, example=500)
    planned_quantity: int = Field(..., gt=0, example=500)
    historical_attendance_rate: float = Field(
        ..., ge=0.0, le=1.0, example=0.92, description="Rate between 0.0 and 1.0"
    )
    current_attendance: int = Field(..., ge=0, example=430)
    event_type: str = Field(..., example="wedding")
    menu_category: str = Field(..., example="vegetarian")
    weather_condition: str = Field(
        ..., example="heavy_rain", description="clear, mild_rain, heavy_rain, extreme_heat, storm"
    )
    day_of_week: str = Field(..., example="saturday")
    historical_surplus_rate: float = Field(
        ..., ge=0.0, le=1.0, example=0.08, description="Rate between 0.0 and 1.0"
    )


class PredictionResponse(BaseModel):
    prediction_id: str
    predicted_consumption: float
    predicted_surplus_min: float
    predicted_surplus_max: float
    surplus_percentage: float
    risk_level: str  # LOW, MEDIUM, HIGH, CRITICAL
    explanation: str
    factors: List[PredictionFactor]

    model_config = ConfigDict(from_attributes=True)


# Aliases for backward compatibility
PredictionInput = PredictionRequest
PredictionOutput = PredictionResponse
