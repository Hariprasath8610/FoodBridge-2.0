from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user_optional
from app.models.user import User
from app.services.rescue_service import rescue_service
from app.schemas.rescue import (
    RescueRequestCreate,
    RescueMissionResponse,
    FoodVerificationRequest,
    PickupVerificationRequest,
    DeliveryVerificationRequest,
    QRVerificationRequest,
)

router = APIRouter(prefix="/rescues", tags=["Rescue Mission Lifecycle"])


@router.post(
    "/request",
    response_model=RescueMissionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Recipient requests food opportunity",
)
def request_rescue(
    data: RescueRequestCreate,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    """Recipient registers interest in claiming and transporting surplus food."""
    return rescue_service.request_rescue(db, data, current_user=current_user)


@router.post(
    "/{rescue_id}/approve",
    response_model=RescueMissionResponse,
    summary="Provider approves rescue mission",
)
def approve_rescue(
    rescue_id: int,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    """Provider accepts the rescue request."""
    return rescue_service.approve_rescue(db, rescue_id, current_user=current_user)


@router.post(
    "/{rescue_id}/verify-food",
    response_model=RescueMissionResponse,
    summary="Provider verifies food safety",
)
def verify_food(
    rescue_id: int,
    data: FoodVerificationRequest,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    """Provider certifies food quality, temperature, and readiness before handoff."""
    return rescue_service.verify_food(
        db, rescue_id, data, current_user=current_user
    )


@router.post(
    "/{rescue_id}/pickup/verify",
    response_model=RescueMissionResponse,
    summary="Verify pickup handoff with safe QR or fallback OTP",
)
def verify_pickup(
    rescue_id: int,
    data: PickupVerificationRequest,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    """Verify pickup handover using recipient driver's safe QR or 6-digit OTP code."""
    return rescue_service.verify_pickup(
        db,
        rescue_id,
        pickup_otp=data.pickup_otp,
        rescue_code=data.rescue_code,
        current_user=current_user,
    )


@router.post(
    "/{rescue_id}/delivery/verify",
    response_model=RescueMissionResponse,
    summary="Verify delivery receipt with safe QR or fallback OTP",
)
def verify_delivery(
    rescue_id: int,
    data: DeliveryVerificationRequest,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    """Recipient confirms delivery arrival using the safe QR code or delivery OTP."""
    return rescue_service.verify_delivery(
        db,
        rescue_id,
        delivery_otp=data.delivery_otp,
        rescue_code=data.rescue_code,
        current_user=current_user,
    )


@router.post(
    "/verify-qr",
    response_model=RescueMissionResponse,
    summary="Verify rescue mission via scanned QR code",
)
def verify_qr(
    data: QRVerificationRequest,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    """Verify rescue pickup or delivery by scanning the safe rescue identifier QR."""
    return rescue_service.verify_qr(
        db,
        qr_data=data.qr_data,
        action=data.action,
        rescue_id=data.rescue_id,
        current_user=current_user,
    )


@router.get(
    "",
    response_model=List[RescueMissionResponse],
    summary="List rescue missions",
)
def list_rescues(
    status: Optional[str] = Query(None, description="Filter by mission status"),
    limit: int = Query(50, ge=1, le=100),
    skip: int = Query(0, ge=0),
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    """List rescue missions. Scoped to caller's organization if logged in."""
    return rescue_service.list_rescues(
        db, current_user=current_user, status=status, limit=limit, skip=skip
    )


@router.get(
    "/{rescue_id}",
    response_model=RescueMissionResponse,
    summary="Get rescue mission details",
)
def get_rescue(
    rescue_id: int,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    """Retrieve full mission lifecycle record by ID."""
    return rescue_service.get_by_id(db, rescue_id, current_user=current_user)
