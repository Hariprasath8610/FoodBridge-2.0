import datetime
import enum
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.core.database import Base


class FoodType(str, enum.Enum):
    VEG = "VEG"
    NON_VEG = "NON_VEG"
    BOTH = "BOTH"


class MealType(str, enum.Enum):
    BREAKFAST = "BREAKFAST"
    LUNCH = "LUNCH"
    DINNER = "DINNER"
    SNACKS = "SNACKS"


class ListingStatus(str, enum.Enum):
    AVAILABLE = "AVAILABLE"
    RESERVED = "RESERVED"
    CLAIMED = "CLAIMED"
    EXPIRED = "EXPIRED"
    CANCELLED = "CANCELLED"


class StorageRequirement(str, enum.Enum):
    ROOM_TEMP = "ROOM_TEMP"
    REFRIGERATED = "REFRIGERATED"
    HEATED = "HEATED"


class FoodListing(Base):
    __tablename__ = "food_listings"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    provider_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    food_type = Column(String(50), default=FoodType.VEG.value, nullable=False)
    meal_type = Column(String(50), default=MealType.LUNCH.value, nullable=False)
    quantity_servings = Column(Integer, nullable=False)
    weight_kg = Column(Float, nullable=False)
    prepared_time = Column(DateTime, nullable=False)
    expiry_time = Column(DateTime, nullable=False)
    status = Column(String(50), default=ListingStatus.AVAILABLE.value, nullable=False, index=True)
    storage_requirement = Column(
        String(50), default=StorageRequirement.ROOM_TEMP.value, nullable=False
    )
    pickup_address = Column(String(500), nullable=False)
    city = Column(String(100), default="Bangalore", nullable=False, index=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    contact_phone = Column(String(50), nullable=True)

    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(
        DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow
    )

    # Relationships
    provider = relationship("User", back_populates="listings")
    claims = relationship("Claim", back_populates="listing", cascade="all, delete-orphan")
