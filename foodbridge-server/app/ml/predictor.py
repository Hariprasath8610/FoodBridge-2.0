import os
import uuid
import numpy as np
import pandas as pd
from typing import Dict, Any, List, Optional
from app.ml.model import (
    load_pipeline,
    MODEL_PATH,
    NUMERICAL_FEATURES,
    CATEGORICAL_FEATURES,
)


class SurplusPredictor:
    """Lightweight Scikit-Learn RandomForest surplus prediction engine with uncertainty bounds."""

    def __init__(self):
        self.pipeline = None
        self._load_or_train()

    def _load_or_train(self):
        if os.path.exists(MODEL_PATH):
            try:
                self.pipeline = load_pipeline(MODEL_PATH)
                return
            except Exception as e:
                print(f"Warning: Could not load model from {MODEL_PATH}: {e}")

        # If model does not exist or failed to load, train it now
        try:
            from app.ml.train import run_training

            self.pipeline, _ = run_training()
        except Exception as e:
            print(f"Failed to auto-train model: {e}")
            self.pipeline = None

    def is_loaded(self) -> bool:
        return self.pipeline is not None

    def predict(
        self,
        expected_people: int,
        planned_quantity: int,
        historical_attendance_rate: float,
        current_attendance: int,
        event_type: str,
        menu_category: str,
        weather_condition: str,
        day_of_week: str,
        historical_surplus_rate: float,
    ) -> Dict[str, Any]:
        """Perform real ML prediction with empirical confidence ranges and explainable factors."""
        if self.pipeline is None:
            self._load_or_train()

        clean_event = event_type.lower().strip()
        clean_menu = menu_category.lower().strip()
        clean_weather = weather_condition.lower().strip()
        clean_day = day_of_week.lower().strip()

        # Build feature DataFrame
        df_input = pd.DataFrame(
            [
                {
                    "expected_people": expected_people,
                    "planned_quantity": planned_quantity,
                    "historical_attendance_rate": historical_attendance_rate,
                    "current_attendance": current_attendance,
                    "event_type": clean_event,
                    "menu_category": clean_menu,
                    "weather_risk": clean_weather,
                    "day_of_week": clean_day,
                    "historical_surplus_rate": historical_surplus_rate,
                }
            ]
        )

        # Predict using individual trees in the RandomForest ensemble for empirical uncertainty bounds
        try:
            preprocessor = self.pipeline.named_steps["preprocessor"]
            regressor = self.pipeline.named_steps["regressor"]

            X_trans = preprocessor.transform(df_input)
            tree_preds = np.array(
                [tree.predict(X_trans)[0] for tree in regressor.estimators_]
            )

            point_estimate = float(np.mean(tree_preds))
            lower_bound = float(np.percentile(tree_preds, 10))
            upper_bound = float(np.percentile(tree_preds, 90))
        except Exception as e:
            # Fallback estimation if pipeline encounters unexpected error
            print(f"Inference error: {e}")
            point_estimate = planned_quantity * max(
                0.05, 1.0 - (current_attendance / expected_people)
            )
            lower_bound = point_estimate * 0.8
            upper_bound = point_estimate * 1.25

        # Sanitize bounds against physical realities
        predicted_surplus = max(0.0, round(point_estimate, 1))
        surplus_min = max(0.0, round(lower_bound, 1))
        surplus_max = max(surplus_min + 2.0, round(upper_bound, 1))

        # Predicted consumption: planned meals minus estimated surplus
        predicted_consumption = max(
            0.0, round(float(planned_quantity) - predicted_surplus, 1)
        )

        # Calculate surplus percentage relative to planned inventory
        surplus_percentage = (
            round((predicted_surplus / planned_quantity) * 100, 1)
            if planned_quantity > 0
            else 0.0
        )

        # Risk Classification (LOW, MEDIUM, HIGH, CRITICAL)
        if surplus_percentage < 8.0:
            risk_level = "LOW"
        elif surplus_percentage < 15.0:
            risk_level = "MEDIUM"
        elif surplus_percentage < 25.0:
            risk_level = "HIGH"
        else:
            risk_level = "CRITICAL"

        # Generate Explainable Factors
        factors = self._generate_factors(
            expected_people=expected_people,
            planned_quantity=planned_quantity,
            historical_attendance_rate=historical_attendance_rate,
            current_attendance=current_attendance,
            event_type=clean_event,
            weather_condition=clean_weather,
            day_of_week=clean_day,
            historical_surplus_rate=historical_surplus_rate,
        )

        # Generate Contextual Human-Readable Explanation
        explanation = self._build_explanation(
            surplus_min=surplus_min,
            surplus_max=surplus_max,
            surplus_percentage=surplus_percentage,
            risk_level=risk_level,
            weather_condition=clean_weather,
            event_type=clean_event,
        )

        prediction_id = f"pred_{uuid.uuid4().hex[:12]}"

        return {
            "prediction_id": prediction_id,
            "predicted_consumption": predicted_consumption,
            "predicted_surplus_min": surplus_min,
            "predicted_surplus_max": surplus_max,
            "surplus_percentage": surplus_percentage,
            "risk_level": risk_level,
            "explanation": explanation,
            "factors": factors,
        }

    def _generate_factors(
        self,
        expected_people: int,
        planned_quantity: int,
        historical_attendance_rate: float,
        current_attendance: int,
        event_type: str,
        weather_condition: str,
        day_of_week: str,
        historical_surplus_rate: float,
    ) -> List[Dict[str, str]]:
        factors = []

        # 1. Weather Impact
        if weather_condition in ["heavy_rain", "storm"]:
            factors.append(
                {
                    "factor": "weather",
                    "effect": "increase_risk",
                    "description": "Heavy rain can significantly reduce event arrival rates and transit times.",
                }
            )
        elif weather_condition in ["mild_rain", "extreme_heat"]:
            factors.append(
                {
                    "factor": "weather",
                    "effect": "moderate_risk",
                    "description": f"Suboptimal weather ({weather_condition.replace('_', ' ')}) creates moderate turnout uncertainty.",
                }
            )
        else:
            factors.append(
                {
                    "factor": "weather",
                    "effect": "neutral",
                    "description": "Favorable weather conditions support normal expected attendee attendance.",
                }
            )

        # 2. Attendance Gap
        expected_turnout = int(expected_people * historical_attendance_rate)
        if current_attendance < expected_turnout:
            gap = expected_turnout - current_attendance
            factors.append(
                {
                    "factor": "attendance_gap",
                    "effect": "increase_risk",
                    "description": f"Current turnout ({current_attendance}) is currently {gap} people below the historical expectation.",
                }
            )
        else:
            factors.append(
                {
                    "factor": "attendance_stability",
                    "effect": "decrease_risk",
                    "description": f"Current headcount ({current_attendance}) matches or exceeds historical baseline pace.",
                }
            )

        # 3. Event Type Specifics
        if event_type in ["wedding", "college_fest"]:
            factors.append(
                {
                    "factor": "event_type",
                    "effect": "increase_risk",
                    "description": "Weddings and celebrations typically carry larger precautionary preparation buffers.",
                }
            )
        elif event_type in ["hostel_canteen", "corporate"]:
            factors.append(
                {
                    "factor": "event_type",
                    "effect": "decrease_risk",
                    "description": "Institutional catering features stricter headcount control and standard consumption rates.",
                }
            )

        # 4. Over-preparation buffer
        if planned_quantity > expected_people:
            buffer_pct = round(
                ((planned_quantity - expected_people) / expected_people) * 100, 1
            )
            factors.append(
                {
                    "factor": "preparation_buffer",
                    "effect": "increase_risk",
                    "description": f"Planned quantity exceeds expected guest count by {buffer_pct}%, creating surplus exposure.",
                }
            )

        return factors

    def _build_explanation(
        self,
        surplus_min: float,
        surplus_max: float,
        surplus_percentage: float,
        risk_level: str,
        weather_condition: str,
        event_type: str,
    ) -> str:
        weather_desc = (
            "adverse weather conditions"
            if weather_condition in ["heavy_rain", "storm"]
            else f"{weather_condition} weather"
        )
        return (
            f"Estimated surplus range of {int(surplus_min)} to {int(surplus_max)} meals "
            f"(~{surplus_percentage}% of planned preparation, {risk_level} risk). "
            f"Turnout variability, {weather_desc}, and {event_type} catering buffers "
            f"influence this range. Probable estimates are derived from historical patterns "
            f"without claiming absolute certainty."
        )


predictor = SurplusPredictor()
