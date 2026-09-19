import datetime
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base


class Recipient(Base):
    __tablename__ = "recipients"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True, index=True)
    organization_name = Column(String(255), nullable=False, index=True)
    organization_type = Column(String(100), nullable=False)
    people_served = Column(Integer, default=100, nullable=False)
    current_demand = Column(Integer, default=50, nullable=False)
    maximum_capacity = Column(Integer, default=150, nullable=False)
    food_preferences = Column(String(255), default="all", nullable=False)
    availability_start = Column(String(10), default="08:00", nullable=False)
    availability_end = Column(String(10), default="22:00", nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    verification_status = Column(String(50), default="VERIFIED", nullable=False, index=True)

    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    # Optional relationship to user account
    user = relationship("User", foreign_keys=[user_id])
