from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.services.matching_service import matching_service
from app.schemas.matching import MatchingResponse

router = APIRouter(tags=["Intelligent Matching Engine"])


@router.post(
    "/matching/{prediction_id}",
    response_model=MatchingResponse,
    status_code=status.HTTP_200_OK,
    summary="Match Verified Recipients for Predicted Surplus",
    description="Intelligently scores and ranks verified recipients based on Haversine distance, active demand, capacity compatibility, urgency, and dietary preferences.",
)
def match_recipients(
    prediction_id: str,
    db: Session = Depends(get_db),
):
    """Execute multi-criteria ranking of verified welfare recipients for a given food surplus prediction."""
    return matching_service.match_recipients_for_prediction(db, prediction_id)
