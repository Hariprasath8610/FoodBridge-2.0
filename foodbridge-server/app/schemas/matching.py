from typing import List, Optional
from pydantic import BaseModel, Field
from app.schemas.recipient import RecipientResponse


class MatchItem(BaseModel):
    recipient: RecipientResponse
    match_score: float = Field(..., example=92.4, description="Calculated matching score (0 to 100)")
    distance_km: float = Field(..., example=2.1, description="Haversine distance in kilometers")
    current_demand: int = Field(..., example=120, description="Active meal demand at the recipient facility")
    compatible_quantity: int = Field(..., example=118, description="Estimated meals compatible with intake capacity")
    urgency: str = Field(..., example="HIGH", description="Recipient intake urgency (CRITICAL, HIGH, MEDIUM, LOW)")
    reason: str = Field(..., example="Close proximity (2.1 km), urgent demand for 120 meals, 100% vegetarian dietary match.")


class MatchingResponse(BaseModel):
    prediction_id: str
    event_type: str
    menu_category: str
    predicted_surplus_range: str
    predicted_surplus_avg: float
    total_matches: int
    matches: List[MatchItem]
