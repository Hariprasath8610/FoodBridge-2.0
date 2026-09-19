import os
import joblib
import numpy as np
import pandas as pd
from typing import Dict, Any, Tuple
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, root_mean_squared_error, r2_score
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

MODEL_PATH = os.path.join(os.path.dirname(__file__), "surplus_model.joblib")

CATEGORICAL_FEATURES = [
    "event_type",
    "menu_category",
    "weather_risk",
    "day_of_week",
]

NUMERICAL_FEATURES = [
    "expected_people",
    "planned_quantity",
    "historical_attendance_rate",
    "current_attendance",
    "historical_surplus_rate",
]

TARGET = "surplus_quantity"


def build_pipeline() -> Pipeline:
    """Construct Scikit-Learn ColumnTransformer and RandomForestRegressor pipeline."""
    preprocessor = ColumnTransformer(
        transformers=[
            ("num", StandardScaler(), NUMERICAL_FEATURES),
            (
                "cat",
                OneHotEncoder(handle_unknown="ignore", sparse_output=False),
                CATEGORICAL_FEATURES,
            ),
        ]
    )

    pipeline = Pipeline(
        steps=[
            ("preprocessor", preprocessor),
            (
                "regressor",
                RandomForestRegressor(
                    n_estimators=120,
                    max_depth=14,
                    min_samples_split=4,
                    random_state=42,
                    n_jobs=-1,
                ),
            ),
        ]
    )
    return pipeline


def train_model(
    df: pd.DataFrame,
) -> Tuple[Pipeline, Dict[str, float]]:
    """Train the model pipeline and compute evaluation metrics."""
    from sklearn.model_selection import train_test_split

    X = df[NUMERICAL_FEATURES + CATEGORICAL_FEATURES]
    y = df[TARGET]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.15, random_state=42
    )

    pipeline = build_pipeline()
    pipeline.fit(X_train, y_train)

    y_pred = pipeline.predict(X_test)
    metrics = {
        "mae": float(mean_absolute_error(y_test, y_pred)),
        "rmse": float(root_mean_squared_error(y_test, y_pred)),
        "r2": float(r2_score(y_test, y_pred)),
    }

    return pipeline, metrics


def save_pipeline(pipeline: Pipeline, path: str = MODEL_PATH) -> None:
    """Serialize model pipeline to disk using joblib."""
    joblib.dump(pipeline, path)


def load_pipeline(path: str = MODEL_PATH) -> Pipeline:
    """Load serialized model pipeline from disk."""
    if not os.path.exists(path):
        raise FileNotFoundError(f"Trained model not found at {path}")
    return joblib.load(path)
