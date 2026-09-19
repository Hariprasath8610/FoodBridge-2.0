from fastapi import APIRouter, Depends, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.impact_record import ImpactRecord
from app.models.rescue_mission import RescueMission, RescueStatus
from app.schemas.impact import DashboardImpactResponse

router = APIRouter(prefix="/dashboard", tags=["Dashboard & Impact Metrics"])


@router.get(
    "/impact",
    response_model=DashboardImpactResponse,
    status_code=status.HTTP_200_OK,
    summary="Retrieve aggregate food rescue impact metrics",
)
def get_dashboard_impact(db: Session = Depends(get_db)):
    """Aggregate cumulative social and environmental impact from delivered rescue missions.

    Uses documented empirical demo assumptions (0.45 kg/meal, ₹80 wholesale retail value/meal).
    Calculations represent practical planning estimates rather than scientifically exact measurements.
    """
    total_rescues = (
        db.query(func.count(RescueMission.id))
        .filter(RescueMission.status == RescueStatus.DELIVERED.value)
        .scalar()
        or 0
    )

    impact_stats = (
        db.query(
            func.coalesce(func.sum(ImpactRecord.meals_rescued), 0).label("meals"),
            func.coalesce(func.sum(ImpactRecord.people_served), 0).label("people"),
            func.coalesce(func.sum(ImpactRecord.food_quantity_kg), 0.0).label("kg"),
            func.coalesce(func.sum(ImpactRecord.estimated_food_value), 0.0).label("val"),
        )
        .first()
    )

    total_meals = int(impact_stats.meals)
    total_people = int(impact_stats.people)
    total_kg = round(float(impact_stats.kg), 1)
    total_val = round(float(impact_stats.val), 2)

    assumptions = {
        "kg_per_meal": 0.45,
        "value_per_meal_inr": 80.0,
        "disclaimer": (
            "Empirical demo estimates based on average institutional portions "
            "(~0.45 kg/meal portion, ₹80 baseline value). Not presented as scientifically exact."
        ),
    }

    return DashboardImpactResponse(
        total_meals_rescued=total_meals,
        total_people_served=total_people,
        total_food_kg_rescued=total_kg,
        total_estimated_value=total_val,
        total_rescues=total_rescues,
        assumptions=assumptions,
    )
