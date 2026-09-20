"""FoodBridge 2.0 — Model Training Pipeline

Trains a Scikit-Learn RandomForestRegressor on the synthetic training dataset,
computes evaluation metrics (MAE, RMSE, R²), and serializes the model to
app/ml/artifacts/surplus_model.pkl and metadata to app/ml/artifacts/model_metadata.json.
"""

import logging
from app.ml.dataset import generate_surplus_dataset
from app.ml.model import train_model, save_pipeline, MODEL_PKL_PATH, METRICS_PATH

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def run_training(n_samples: int = 4500, random_state: int = 42):
    """Execute end-to-end model training, evaluation, and artifact serialization."""
    logger.info(f"Generating synthetic training dataset ({n_samples} samples)...")
    df = generate_surplus_dataset(n_samples=n_samples, random_state=random_state)
    logger.info(f"Dataset generated. Shape: {df.shape}")

    logger.info("Training Scikit-Learn RandomForestRegressor pipeline...")
    pipeline, metrics = train_model(df)

    logger.info("=" * 60)
    logger.info("FOODBRIDGE SURPLUS MODEL TRAINING COMPLETED")
    logger.info(f"Model Type : {metrics.get('model_type')}")
    logger.info(f"Train Size : {metrics.get('train_samples')} samples")
    logger.info(f"Test Size  : {metrics.get('test_samples')} samples")
    logger.info(f"MAE        : {metrics['mae']:.2f} meals")
    logger.info(f"RMSE       : {metrics['rmse']:.2f} meals")
    logger.info(f"R² Score   : {metrics['r2']:.4f}")
    logger.info("=" * 60)

    save_pipeline(pipeline, metrics, MODEL_PKL_PATH, METRICS_PATH)
    logger.info(f"Model artifact saved to: {MODEL_PKL_PATH}")
    logger.info(f"Evaluation metadata saved to: {METRICS_PATH}")
    return pipeline, metrics


if __name__ == "__main__":
    run_training()
