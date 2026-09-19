import datetime
from sqlalchemy import Column, Integer, Float, String, DateTime
from app.core.database import Base


class PredictionFeedback(Base):
    __tablename__ = "prediction_feedbacks"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    prediction_id = Column(String(64), nullable=False, index=True)
    predicted_quantity = Column(Float, nullable=False)
    actual_quantity = Column(Float, nullable=False)
    absolute_error = Column(Float, nullable=False)
    percentage_error = Column(Float, nullable=False)

    created_at = Column(DateTime, default=datetime.datetime.utcnow)
