import logging
from app.ml.dataset import generate_surplus_dataset
from app.ml.model import train_model, save_pipeline, MODEL_PATH

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def run_training():
    logger.info("Generating synthetic training dataset for surplus prediction...")
    df = generate_surplus_dataset(n_samples=4000, random_state=42)
    logger.info(f"Generated {len(df)} samples.")

    logger.info("Training Scikit-Learn RandomForestRegressor pipeline...")
    pipeline, metrics = train_model(df)

    logger.info(
        f"Model Training Finished! Metrics: "
        f"MAE={metrics['mae']:.2f} meals, "
        f"RMSE={metrics['rmse']:.2f} meals, "
        f"R2={metrics['r2']:.4f}"
    )

    save_pipeline(pipeline, MODEL_PATH)
    logger.info(f"Model successfully saved to: {MODEL_PATH}")
    return pipeline, metrics


if __name__ == "__main__":
    run_training()
