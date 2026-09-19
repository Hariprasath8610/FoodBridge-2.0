import datetime
import enum
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.core.database import Base


class ClaimStatus(str, enum.Enum):
    REQUESTED = "REQUESTED"
    APPROVED = "APPROVED"
    PICKED_UP = "PICKED_UP"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"


class Claim(Base):
    __tablename__ = "claims"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    listing_id = Column(
        Integer, ForeignKey("food_listings.id"), nullable=False, index=True
    )
    recipient_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    status = Column(
        String(50), default=ClaimStatus.REQUESTED.value, nullable=False, index=True
    )
    servings_requested = Column(Integer, nullable=False)
    notes = Column(Text, nullable=True)
    pickup_otp = Column(String(10), nullable=True)  # Verification code for handoff

    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(
        DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow
    )

    # Relationships
    listing = relationship("FoodListing", back_populates="claims")
    recipient = relationship("User", back_populates="claims")
