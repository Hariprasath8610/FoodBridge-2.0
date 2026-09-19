from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.exceptions import NotFoundException
from app.core.security import get_current_user_optional
from app.models.user import User
from app.models.recipient import Recipient
from app.schemas.recipient import (
    RecipientDemandUpdate,
    RecipientResponse,
    RecipientCreate,
)

router = APIRouter(prefix="/recipients", tags=["Recipients Management"])


@router.get("", response_model=List[RecipientResponse])
def list_recipients(
    verification_status: Optional[str] = Query(
        None, description="Filter by status (e.g. VERIFIED)"
    ),
    min_demand: Optional[int] = Query(None, ge=0),
    limit: int = Query(50, ge=1, le=100),
    skip: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    """List recipients registered on FoodBridge."""
    query = db.query(Recipient)
    if verification_status:
        query = query.filter(Recipient.verification_status == verification_status)
    if min_demand is not None:
        query = query.filter(Recipient.current_demand >= min_demand)

    return query.offset(skip).limit(limit).all()


@router.get("/{recipient_id}", response_model=RecipientResponse)
def get_recipient(
    recipient_id: int,
    db: Session = Depends(get_db),
):
    """Retrieve detailed recipient profile by ID."""
    recipient = db.query(Recipient).filter(Recipient.id == recipient_id).first()
    if not recipient:
        raise NotFoundException("Recipient", recipient_id)
    return recipient


@router.post("/demand", response_model=RecipientResponse)
def update_recipient_demand(
    data: RecipientDemandUpdate,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    """Update current active meal demand, preferences, and capacity for a verified recipient."""
    recipient = None
    if data.recipient_id:
        recipient = (
            db.query(Recipient).filter(Recipient.id == data.recipient_id).first()
        )
    if not recipient and current_user:
        recipient = (
            db.query(Recipient).filter(Recipient.user_id == current_user.id).first()
        )
    if not recipient:
        recipient = db.query(Recipient).first()

    if not recipient:
        raise NotFoundException("Recipient", data.recipient_id or 1)

    recipient.current_demand = data.current_demand
    if data.people_served is not None:
        recipient.people_served = data.people_served
    if data.food_preferences is not None:
        recipient.food_preferences = data.food_preferences
    if data.availability_start is not None:
        recipient.availability_start = data.availability_start
    if data.availability_end is not None:
        recipient.availability_end = data.availability_end

    db.commit()
    db.refresh(recipient)
    return recipient
