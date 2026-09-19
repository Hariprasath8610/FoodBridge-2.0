import datetime
import enum
from sqlalchemy import Column, Integer, String, Float, DateTime
from sqlalchemy.orm import relationship
from app.core.database import Base


class UserRole(str, enum.Enum):
    SENDER = "sender"
    RECIPIENT = "recipient"


class VerificationStatus(str, enum.Enum):
    VERIFIED = "verified"
    PENDING = "pending"
    REJECTED = "rejected"


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    firebase_uid = Column(String(128), unique=True, index=True, nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    organization_name = Column(String(255), nullable=False)
    organization_type = Column(String(50), nullable=False)
    role = Column(String(50), nullable=False, index=True)
    verification_status = Column(
        String(50), default=VerificationStatus.PENDING.value, nullable=False
    )
    phone = Column(String(50), nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)

    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(
        DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow
    )

    # Relationships
    listings = relationship(
        "FoodListing", back_populates="provider", cascade="all, delete-orphan"
    )
    claims = relationship(
        "Claim", back_populates="recipient", cascade="all, delete-orphan"
    )
    predictions = relationship(
        "Prediction", back_populates="provider", cascade="all, delete-orphan"
    )
