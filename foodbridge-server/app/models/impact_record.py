import datetime
from sqlalchemy import Column, Integer, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base


class ImpactRecord(Base):
    __tablename__ = "impact_records"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    rescue_id = Column(
        Integer, ForeignKey("rescue_missions.id"), unique=True, nullable=False, index=True
    )
    meals_rescued = Column(Integer, nullable=False)
    people_served = Column(Integer, nullable=False)
    food_quantity_kg = Column(Float, nullable=False)
    estimated_food_value = Column(Float, nullable=False)
    waste_avoided = Column(Float, nullable=False)

    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    # Relationship to parent rescue mission
    rescue = relationship("RescueMission", foreign_keys=[rescue_id])
