import datetime
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.core.database import Base


class Prediction(Base):
    __tablename__ = "predictions"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    prediction_id = Column(String(64), unique=True, index=True, nullable=False)
    provider_id = Column(Integer, ForeignKey("users.id"), nullable=True, index=True)

    # Input Features
    expected_people = Column(Integer, nullable=False)
    planned_quantity = Column(Integer, nullable=False)
    historical_attendance_rate = Column(Float, nullable=False)
    current_attendance = Column(Integer, nullable=False)
    event_type = Column(String(50), nullable=False)
    menu_category = Column(String(50), nullable=False)
    weather_condition = Column(String(50), nullable=False)
    day_of_week = Column(String(20), nullable=False)
    historical_surplus_rate = Column(Float, nullable=False)

    # Output Predictions & Uncertainty
    predicted_consumption = Column(Float, nullable=False)
    predicted_surplus_min = Column(Float, nullable=False)
    predicted_surplus_max = Column(Float, nullable=False)
    surplus_percentage = Column(Float, nullable=False)
    risk_level = Column(String(20), nullable=False)
    explanation = Column(Text, nullable=True)
    factors_json = Column(Text, nullable=True)

    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    # Relationship to User
    provider = relationship("User", back_populates="predictions")


# Backward compatibility alias
SurplusPrediction = Prediction
