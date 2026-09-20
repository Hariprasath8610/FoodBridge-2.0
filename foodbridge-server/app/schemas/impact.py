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
    actual_surplus: Optional[float] = Field(None, example=75.0, description="Actual recorded surplus in meals")
    actual_quantity: Optional[float] = Field(None, example=75.0, description="Alias for actual_surplus")
    predicted_quantity: Optional[float] = Field(None, example=70.0, description="Predicted surplus in meals")

    def get_actual(self) -> float:
        if self.actual_surplus is not None:
            return float(self.actual_surplus)
        if self.actual_quantity is not None:
            return float(self.actual_quantity)
        raise ValueError("Either 'actual_surplus' or 'actual_quantity' must be provided.")


class PredictionFeedbackResponse(BaseModel):
    prediction_id: str
    predicted_quantity: float
    actual_quantity: float
    absolute_error: float
    percentage_error: float
    feedback_status: str = "STORED"
    message: str = "Actual surplus feedback recorded for future AI model fine-tuning."
