from datetime import datetime
from typing import Dict, Any, Optional
from pydantic import BaseModel, Field, ConfigDict


class ImpactRecordResponse(BaseModel):
    id: int
    rescue_id: int
    meals_rescued: int
    people_served: int
    food_quantity_kg: float
    estimated_food_value: float
    waste_avoided: float
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class DashboardImpactResponse(BaseModel):
    total_meals_rescued: int = Field(..., example=125)
    total_people_served: int = Field(..., example=125)
    total_food_kg_rescued: float = Field(..., example=56.3)
    total_estimated_value: float = Field(..., example=10000.0)
    total_rescues: int = Field(..., example=2)
    assumptions: Optional[Dict[str, Any]] = None


class PredictionFeedbackRequest(BaseModel):
    predicted_quantity: float = Field(..., example=95.0, description="Predicted surplus quantity in meals")
    actual_quantity: float = Field(..., example=88.0, description="Actual recorded surplus quantity in meals")


class PredictionFeedbackResponse(BaseModel):
    prediction_id: str
    predicted_quantity: float
    actual_quantity: float
    absolute_error: float
    percentage_error: float
    feedback_status: str = "STORED"
    message: str = "Actual surplus feedback recorded for future AI model fine-tuning."
