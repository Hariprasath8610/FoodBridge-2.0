from datetime import datetime
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field, ConfigDict, model_validator


class PredictionFactor(BaseModel):
    name: Optional[str] = None
    factor: str = Field(..., example="weather")
    effect: str = Field(..., example="increases_surplus_risk")
    description: str = Field(
        ...,
        example="Adverse weather (heavy rain) contributed to lower expected attendance.",
    )

    @model_validator(mode="after")
    def sync_name_and_factor(self):
        if not self.name and self.factor:
            self.name = self.factor
        elif not self.factor and self.name:
            self.factor = self.name
        return self


class PredictionRequest(BaseModel):
    expected_people: int = Field(..., gt=0, example=500, description="Total expected guests/attendees (>0)")
    planned_meals: Optional[int] = Field(None, gt=0, example=500, description="Total meals/portions planned (>0)")
    planned_quantity: Optional[int] = Field(None, gt=0, example=500, description="Alias for planned_meals (>0)")
    historical_attendance_rate: float = Field(
        ..., ge=0.0, le=1.0, example=0.92, description="Historical attendance rate between 0.0 and 1.0"
    )
    current_attendance: int = Field(..., ge=0, example=430, description="Current recorded attendees (>=0)")
    event_type: str = Field(..., example="wedding", description="Event category e.g. wedding, corporate, restaurant")
    weather_condition: str = Field(
        ..., example="heavy_rain", description="Weather e.g. clear, mild_rain, heavy_rain, extreme_heat, storm"
    )
    day_of_week: str = Field(..., example="saturday", description="Day of week e.g. monday to sunday")
    historical_surplus_rate: float = Field(
        ..., ge=0.0, le=1.0, example=0.08, description="Historical surplus rate between 0.0 and 1.0"
    )
    menu_category: str = Field("vegetarian", example="vegetarian", description="Menu category")

    @model_validator(mode="after")
    def validate_and_sync_planned(self):
        if self.planned_meals is None and self.planned_quantity is None:
            raise ValueError("Either 'planned_meals' or 'planned_quantity' must be provided and greater than 0.")
        if self.planned_meals is None and self.planned_quantity is not None:
            self.planned_meals = self.planned_quantity
        elif self.planned_quantity is None and self.planned_meals is not None:
            self.planned_quantity = self.planned_meals

        # Validate non-empty event_type
        if not self.event_type or not self.event_type.strip():
            raise ValueError("event_type cannot be empty.")
        return self


class PredictionResponse(BaseModel):
    prediction_id: str
    predicted_consumption: float = Field(..., example=420.0, description="Estimated total meals consumed")
    predicted_surplus: float = Field(..., example=80.0, description="Estimated surplus portions remaining")
    predicted_surplus_min: Optional[float] = Field(None, example=68.0, description="Uncertainty lower bound")
    predicted_surplus_max: Optional[float] = Field(None, example=92.0, description="Uncertainty upper bound")
    surplus_percentage: float = Field(..., example=16.0, description="Surplus as percentage of planned meals")
    risk_level: str = Field(..., example="HIGH", description="Risk category: LOW, MEDIUM, HIGH, CRITICAL")
    factors: List[PredictionFactor] = Field(..., description="Explainable contributing factors")
    model_version: str = Field("foodbridge-surplus-v1", example="foodbridge-surplus-v1")
    created_at: str = Field(..., example="2026-09-20T12:00:00Z")
    explanation: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class ModelInfoResponse(BaseModel):
    model_type: str
    model_version: str
    mae: float
    rmse: float
    r2: float
    train_samples: int
    test_samples: int
    feature_importances: Dict[str, float]
    risk_thresholds: Dict[str, float]


# Aliases for backward compatibility
PredictionInput = PredictionRequest
PredictionOutput = PredictionResponse
