from typing import List, Optional
import json
from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "FoodBridge API"
    VERSION: str = "1.0.0"
    DESCRIPTION: str = "AI-Powered Surplus Food Prediction & Rescue Platform"
    ENV: str = "development"
    DEBUG: bool = True
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    API_V1_STR: str = "/api/v1"

    DATABASE_URL: str = "sqlite:///./foodbridge.db"

    # CORS Configuration
    CORS_ORIGINS: List[str] = ["*"]

    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v):
        if isinstance(v, str):
            if v.startswith("[") and v.endswith("]"):
                try:
                    return json.loads(v)
                except Exception:
                    pass
            return [i.strip() for i in v.split(",") if i.strip()]
        elif isinstance(v, (list, tuple)):
            return list(v)
        return ["*"]

    # Firebase Admin Settings
    FIREBASE_CREDENTIALS_PATH: Optional[str] = None
    FIREBASE_PROJECT_ID: Optional[str] = None

    # AI Surplus Prediction & Risk Classification Configuration
    # Note: These are hackathon/demo calibrated thresholds (surplus percentage relative to planned meals)
    SURPLUS_RISK_LOW_THRESHOLD: float = 5.0      # < 5% surplus -> LOW risk
    SURPLUS_RISK_MEDIUM_THRESHOLD: float = 10.0  # 5% - 10% surplus -> MEDIUM risk
    SURPLUS_RISK_HIGH_THRESHOLD: float = 20.0    # 10% - 20% surplus -> HIGH risk; > 20% -> CRITICAL risk
    MODEL_VERSION: str = "foodbridge-surplus-v1"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="allow",
    )


settings = Settings()
