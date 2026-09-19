import datetime
import enum
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.core.database import Base


class RescueStatus(str, enum.Enum):
    CREATED = "CREATED"
    RECIPIENT_REQUESTED = "RECIPIENT_REQUESTED"
    PROVIDER_APPROVED = "PROVIDER_APPROVED"
    FOOD_VERIFIED = "FOOD_VERIFIED"
    PICKUP_READY = "PICKUP_READY"
    PICKED_UP = "PICKED_UP"
    IN_TRANSIT = "IN_TRANSIT"
    DELIVERED = "DELIVERED"
    CANCELLED = "CANCELLED"


class FoodSafetyStatus(str, enum.Enum):
    PENDING_VERIFICATION = "PENDING_VERIFICATION"
    SAFE_VERIFIED = "SAFE_VERIFIED"
    TEMPERATURE_CHECKED = "TEMPERATURE_CHECKED"
    REJECTED = "REJECTED"


class RescueMission(Base):
    __tablename__ = "rescue_missions"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    rescue_code = Column(String(64), unique=True, index=True, nullable=False)
    prediction_id = Column(String(64), nullable=True, index=True)
    provider_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    recipient_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    food_source_id = Column(Integer, ForeignKey("food_listings.id"), nullable=True, index=True)

    quantity = Column(Integer, nullable=False)
    status = Column(
        String(50), default=RescueStatus.RECIPIENT_REQUESTED.value, nullable=False, index=True
    )
    food_safety_status = Column(
        String(50), default=FoodSafetyStatus.PENDING_VERIFICATION.value, nullable=False
    )

    pickup_otp = Column(String(10), nullable=False)
    delivery_otp = Column(String(10), nullable=False)

    pickup_time = Column(DateTime, nullable=True)
    delivery_time = Column(DateTime, nullable=True)

    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(
        DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow
    )

    # Relationships
    provider = relationship("User", foreign_keys=[provider_id])
    recipient = relationship("User", foreign_keys=[recipient_id])
    food_source = relationship("FoodListing", foreign_keys=[food_source_id])
