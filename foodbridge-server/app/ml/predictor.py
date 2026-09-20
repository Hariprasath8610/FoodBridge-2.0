"""FoodBridge 2.0 — Surplus Prediction Engine

Loads the trained Scikit-Learn RandomForestRegressor from app/ml/artifacts/surplus_model.pkl,
validates incoming inputs, computes expected food consumption and derived surplus,
evaluates risk levels against configurable thresholds, and generates explainability factors.
"""

import os
import uuid
from datetime import datetime
from typing import Dict, Any, List, Optional
import numpy as np
import pandas as pd

from app.core.config import settings
from app.ml.model import (
    load_pipeline,
    load_metadata,
    MODEL_PKL_PATH,
    NUMERICAL_FEATURES,
    CATEGORICAL_FEATURES,
)


class SurplusPredictor:
    """Production ML Inference Engine for Food Surplus Forecasting."""

    def __init__(self):
        self.pipeline = None
        self.metadata = {}
        self._load_or_train()

    def _load_or_train(self):
        """Loads serialized model artifact or executes one-time initial training."""
        if os.path.exists(MODEL_PKL_PATH):
            try:
                self.pipeline = load_pipeline(MODEL_PKL_PATH)
                self.metadata = load_metadata()
                return
            except Exception as e:
                print(f"[ML] Could not load model from {MODEL_PKL_PATH}: {e}")

        # If model artifact does not exist, trigger one-time training
        try:
            from app.ml.train import run_training

            self.pipeline, self.metadata = run_training()
        except Exception as e:
            print(f"[ML] Failed to auto-train model: {e}")
            self.pipeline = None
            self.metadata = {}

    def is_loaded(self) -> bool:
        """Returns True if the ML model is currently loaded and ready."""
        return self.pipeline is not None

    def predict(
        self,
        expected_people: int,
        planned_meals: int,
        historical_attendance_rate: float,
        current_attendance: int,
        event_type: str,
        weather_condition: str,
        day_of_week: str,
        historical_surplus_rate: float,
        menu_category: str = "vegetarian",
    ) -> Dict[str, Any]:
        """Generate machine learning surplus prediction and explainable factors."""
        if self.pipeline is None:
            self._load_or_train()

        clean_event = event_type.lower().strip()
        clean_weather = weather_condition.lower().strip()
        clean_day = day_of_week.lower().strip()
        clean_menu = menu_category.lower().strip()

        # Build feature DataFrame strictly aligned with training schema
        df_input = pd.DataFrame(
            [
                {
                    "expected_people": expected_people,
                    "planned_meals": planned_meals,
                    "historical_attendance_rate": historical_attendance_rate,
                    "current_attendance": current_attendance,
                    "event_type": clean_event,
                    "menu_category": clean_menu,
                    "weather_condition": clean_weather,
                    "day_of_week": clean_day,
                    "historical_surplus_rate": historical_surplus_rate,
                }
            ]
        )

        try:
            preprocessor = self.pipeline.named_steps["preprocessor"]
            regressor = self.pipeline.named_steps["regressor"]

            X_trans = preprocessor.transform(df_input)

            # Predict expected consumption across individual ensemble trees
            tree_preds = np.array(
                [tree.predict(X_trans)[0] for tree in regressor.estimators_]
            )

            predicted_consumption = float(np.mean(tree_preds))
            lower_consumption = float(np.percentile(tree_preds, 10))
            upper_consumption = float(np.percentile(tree_preds, 90))
        except Exception as e:
            # Fallback estimation if pipeline encounters unexpected runtime error
            print(f"[ML] Inference error: {e}")
            consumption_rate = min(1.0, current_attendance / max(1, expected_people))
            predicted_consumption = planned_meals * consumption_rate * 0.95
            lower_consumption = predicted_consumption * 0.9
            upper_consumption = predicted_consumption * 1.1

        # Physical constraints: consumption cannot exceed planned meals or be negative
        predicted_consumption = max(0.0, min(float(planned_meals), round(predicted_consumption, 1)))

        # Derive Surplus: surplus = planned - expected consumption
        predicted_surplus = max(0.0, round(float(planned_meals) - predicted_consumption, 1))

        # Empirical bounds derived from ensemble variance
        surplus_min = max(0.0, round(float(planned_meals) - upper_consumption, 1))
        surplus_max = max(surplus_min, round(float(planned_meals) - lower_consumption, 1))

        # Calculate surplus percentage
        surplus_percentage = (
            round((predicted_surplus / planned_meals) * 100, 1)
            if planned_meals > 0
            else 0.0
        )

        # Risk Classification using configurable settings thresholds
        if surplus_percentage < settings.SURPLUS_RISK_LOW_THRESHOLD:
            risk_level = "LOW"
        elif surplus_percentage < settings.SURPLUS_RISK_MEDIUM_THRESHOLD:
            risk_level = "MEDIUM"
        elif surplus_percentage < settings.SURPLUS_RISK_HIGH_THRESHOLD:
            risk_level = "HIGH"
        else:
            risk_level = "CRITICAL"

        # Generate Explainable Factors (using non-causal contributing terminology)
        factors = self._generate_factors(
            expected_people=expected_people,
            planned_meals=planned_meals,
            historical_attendance_rate=historical_attendance_rate,
            current_attendance=current_attendance,
            event_type=clean_event,
            weather_condition=clean_weather,
            day_of_week=clean_day,
            historical_surplus_rate=historical_surplus_rate,
        )

        # Human-Readable Explanation
        explanation = self._build_explanation(
            predicted_consumption=predicted_consumption,
            predicted_surplus=predicted_surplus,
            surplus_percentage=surplus_percentage,
            risk_level=risk_level,
            weather_condition=clean_weather,
            event_type=clean_event,
        )

        prediction_id = f"pred_{uuid.uuid4().hex[:12]}"
        created_at = datetime.utcnow().isoformat() + "Z"

        return {
            "prediction_id": prediction_id,
            "predicted_consumption": predicted_consumption,
            "predicted_surplus": predicted_surplus,
            "predicted_surplus_min": surplus_min,
            "predicted_surplus_max": surplus_max,
            "surplus_percentage": surplus_percentage,
            "risk_level": risk_level,
            "factors": factors,
            "model_version": settings.MODEL_VERSION,
            "created_at": created_at,
            "explanation": explanation,
        }

    def _generate_factors(
        self,
        expected_people: int,
        planned_meals: int,
        historical_attendance_rate: float,
        current_attendance: int,
        event_type: str,
        weather_condition: str,
        day_of_week: str,
        historical_surplus_rate: float,
    ) -> List[Dict[str, str]]:
        """Extract multi-factor explainability elements that contributed to the model output."""
        factors = []

        # 1. Weather Factor
        if weather_condition in ["heavy_rain", "storm"]:
            factors.append(
                {
                    "name": "weather",
                    "factor": "weather",
                    "effect": "increases_surplus_risk",
                    "description": f"Adverse weather ({weather_condition.replace('_', ' ')}) contributed to lower expected attendance.",
                }
            )
        elif weather_condition in ["mild_rain", "extreme_heat"]:
            factors.append(
                {
                    "name": "weather",
                    "factor": "weather",
                    "effect": "moderate_surplus_risk",
                    "description": f"Suboptimal weather ({weather_condition.replace('_', ' ')}) contributed moderate turnout variance.",
                }
            )
        else:
            factors.append(
                {
                    "name": "weather",
                    "factor": "weather",
                    "effect": "reduces_surplus_risk",
                    "description": "Clear weather conditions contributed to stable expected attendance.",
                }
            )

        # 2. Attendance Pattern
        expected_turnout = int(expected_people * historical_attendance_rate)
        if current_attendance < expected_turnout:
            gap = expected_turnout - current_attendance
            factors.append(
                {
                    "name": "attendance",
                    "factor": "attendance_gap",
                    "effect": "reduces_expected_consumption",
                    "description": f"Current attendance ({current_attendance}) is {gap} attendees below the historical baseline pace.",
                }
            )
        else:
            factors.append(
                {
                    "name": "attendance",
                    "factor": "attendance_stability",
                    "effect": "increases_expected_consumption",
                    "description": f"Current turnout ({current_attendance}) matches or exceeds historical baseline pace.",
                }
            )

        # 3. Event Type Buffer
        if event_type in ["wedding", "college_fest", "large_gathering"]:
            factors.append(
                {
                    "name": "event_type",
                    "factor": "event_type",
                    "effect": "increases_surplus_risk",
                    "description": f"Celebration catering ({event_type}) historically carries higher precautionary preparation buffers.",
                }
            )
        elif event_type in ["hostel_canteen", "corporate"]:
            factors.append(
                {
                    "name": "event_type",
                    "factor": "event_type",
                    "effect": "reduces_surplus_risk",
                    "description": "Institutional catering features stricter headcount control and standard consumption rates.",
                }
            )

        # 4. Over-preparation buffer
        if planned_meals > expected_people:
            buffer_pct = round(
                ((planned_meals - expected_people) / expected_people) * 100, 1
            )
            factors.append(
                {
                    "name": "planned_quantity",
                    "factor": "preparation_buffer",
                    "effect": "increases_surplus_risk",
                    "description": f"Planned preparation exceeds expected headcount by {buffer_pct}%, creating surplus exposure.",
                }
            )

        # 5. Historical Surplus Pattern
        if historical_surplus_rate >= 0.10:
            factors.append(
                {
                    "name": "historical_surplus",
                    "factor": "historical_surplus",
                    "effect": "increases_surplus_risk",
                    "description": f"Historical surplus rate is elevated at {round(historical_surplus_rate * 100, 1)}%.",
                }
            )

        return factors

    def _build_explanation(
        self,
        predicted_consumption: float,
        predicted_surplus: float,
        surplus_percentage: float,
        risk_level: str,
        weather_condition: str,
        event_type: str,
    ) -> str:
        weather_str = (
            "adverse weather"
            if weather_condition in ["heavy_rain", "storm"]
            else f"{weather_condition} weather"
        )
        return (
            f"Estimated consumption of {int(predicted_consumption)} meals with "
            f"potential surplus of {int(predicted_surplus)} meals (~{surplus_percentage}% of planned preparation, {risk_level} risk). "
            f"Turnout pace, {weather_str}, and {event_type} catering patterns contributed to this forecast."
        )


predictor = SurplusPredictor()
