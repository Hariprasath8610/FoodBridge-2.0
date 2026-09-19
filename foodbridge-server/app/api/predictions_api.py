import json
from typing import List, Optional
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user_optional
from app.core.exceptions import ForbiddenException
from app.models.user import User, UserRole
from app.ml.predictor import predictor
from app.models.prediction import Prediction
from app.models.prediction_feedback import PredictionFeedback
from app.schemas.prediction import PredictionRequest, PredictionResponse
from app.schemas.impact import (
    PredictionFeedbackRequest,
    PredictionFeedbackResponse,
)

router = APIRouter(tags=["Surplus Prediction Engine"])


@router.post(
    "/predictions",
    response_model=PredictionResponse,
    status_code=status.HTTP_200_OK,
    summary="Generate AI Surplus Food Prediction",
    description="Uses a trained Scikit-Learn RandomForestRegressor to estimate consumption, surplus ranges, risk level, and explainable factors.",
)
def create_prediction(
    request: PredictionRequest,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    """Predict food surplus for an upcoming or active food service/event.

    Returns empirical uncertainty ranges and explainable factors.
    """
    if current_user:
        if current_user.role not in [UserRole.SENDER.value, "sender", "ADMIN"]:
            raise ForbiddenException("Access forbidden: Recipients cannot create provider surplus predictions.")
    prediction_data = predictor.predict(
        expected_people=request.expected_people,
        planned_quantity=request.planned_quantity,
        historical_attendance_rate=request.historical_attendance_rate,
        current_attendance=request.current_attendance,
        event_type=request.event_type,
        menu_category=request.menu_category,
        weather_condition=request.weather_condition,
        day_of_week=request.day_of_week,
        historical_surplus_rate=request.historical_surplus_rate,
    )

    # Persist prediction in database
    db_record = Prediction(
        prediction_id=prediction_data["prediction_id"],
        expected_people=request.expected_people,
        planned_quantity=request.planned_quantity,
        historical_attendance_rate=request.historical_attendance_rate,
        current_attendance=request.current_attendance,
        event_type=request.event_type,
        menu_category=request.menu_category,
        weather_condition=request.weather_condition,
        day_of_week=request.day_of_week,
        historical_surplus_rate=request.historical_surplus_rate,
        predicted_consumption=prediction_data["predicted_consumption"],
        predicted_surplus_min=prediction_data["predicted_surplus_min"],
        predicted_surplus_max=prediction_data["predicted_surplus_max"],
        surplus_percentage=prediction_data["surplus_percentage"],
        risk_level=prediction_data["risk_level"],
        explanation=prediction_data["explanation"],
        factors_json=json.dumps(prediction_data["factors"]),
    )
    db.add(db_record)
    db.commit()

    return prediction_data


@router.post(
    "/predictions/{prediction_id}/feedback",
    response_model=PredictionFeedbackResponse,
    status_code=status.HTTP_200_OK,
    summary="Record actual surplus feedback for continuous AI learning",
)
def record_prediction_feedback(
    prediction_id: str,
    feedback: PredictionFeedbackRequest,
    db: Session = Depends(get_db),
):
    """Stores actual vs predicted surplus quantities to power the continuous AI learning loop."""
    abs_err = round(abs(feedback.actual_quantity - feedback.predicted_quantity), 2)
    denom = (
        feedback.actual_quantity
        if feedback.actual_quantity > 0
        else max(1.0, feedback.predicted_quantity)
    )
    pct_err = round((abs_err / denom) * 100, 2)

    feedback_record = PredictionFeedback(
        prediction_id=prediction_id,
        predicted_quantity=feedback.predicted_quantity,
        actual_quantity=feedback.actual_quantity,
        absolute_error=abs_err,
        percentage_error=pct_err,
    )
    db.add(feedback_record)
    db.commit()

    return PredictionFeedbackResponse(
        prediction_id=prediction_id,
        predicted_quantity=feedback.predicted_quantity,
        actual_quantity=feedback.actual_quantity,
        absolute_error=abs_err,
        percentage_error=pct_err,
        feedback_status="STORED",
        message="Actual surplus feedback recorded for future AI model fine-tuning.",
    )
