from typing import Any, Generic, List, Optional, TypeVar
from pydantic import BaseModel

T = TypeVar("T")


class APIResponse(BaseModel, Generic[T]):
    success: bool = True
    message: Optional[str] = "Operation successful"
    data: Optional[T] = None


class HealthResponse(BaseModel):
    status: str = "ok"
    version: str
    environment: str
    database: str
    firebase: str
    ml_model_loaded: bool
    timestamp: str
