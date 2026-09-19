import json
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.ml.predictor import predictor
from app.models.prediction import Prediction
from app.schemas.prediction import PredictionRequest, PredictionResponse

router = APIRouter(prefix="/predictions", tags=["AI Surplus Prediction"])


@router.post("", response_model=PredictionResponse, status_code=status.HTTP_200_OK)
@router.post("/predict", response_model=PredictionResponse, status_code=status.HTTP_200_OK)
def predict_surplus(
    data: PredictionRequest,
    db: Session = Depends(get_db),
):
    """Predict food surplus for an event using trained Scikit-Learn RandomForestRegressor."""
    prediction_data = predictor.predict(
        expected_people=data.expected_people,
        planned_quantity=data.planned_quantity,
        historical_attendance_rate=data.historical_attendance_rate,
        current_attendance=data.current_attendance,
        event_type=data.event_type,
        menu_category=data.menu_category,
        weather_condition=data.weather_condition,
        day_of_week=data.day_of_week,
        historical_surplus_rate=data.historical_surplus_rate,
    )

    db_record = Prediction(
        prediction_id=prediction_data["prediction_id"],
        expected_people=data.expected_people,
        planned_quantity=data.planned_quantity,
        historical_attendance_rate=data.historical_attendance_rate,
        current_attendance=data.current_attendance,
        event_type=data.event_type,
        menu_category=data.menu_category,
        weather_condition=data.weather_condition,
        day_of_week=data.day_of_week,
        historical_surplus_rate=data.historical_surplus_rate,
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
