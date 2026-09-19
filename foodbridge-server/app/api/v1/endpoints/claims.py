from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.schemas.claim import ClaimCreate, ClaimResponse, ClaimVerifyOTP
from app.services.claim_service import claim_service

router = APIRouter(prefix="/claims", tags=["Food Claims & Handoff"])


@router.get("", response_model=List[ClaimResponse])
def list_claims(
    recipient_id: Optional[int] = Query(None),
    provider_id: Optional[int] = Query(None),
    status: Optional[str] = Query(None),
    limit: int = Query(50, ge=1, le=100),
    skip: int = Query(0, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List food claims. Filter by recipient, provider, or status."""
    # If standard user, default to scoping to their role
    effective_recipient = (
        current_user.id if current_user.role == "RECIPIENT" and not recipient_id else recipient_id
    )
    effective_provider = (
        current_user.id if current_user.role == "PROVIDER" and not provider_id else provider_id
    )

    return claim_service.list_claims(
        db,
        recipient_id=effective_recipient,
        provider_id=effective_provider,
        status=status,
        limit=limit,
        skip=skip,
    )


@router.post("", response_model=ClaimResponse, status_code=status.HTTP_201_CREATED)
def request_claim(
    data: ClaimCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Submit a request to claim/reserve a surplus listing (Recipient role required)."""
    return claim_service.create_claim(db, data, recipient=current_user)


@router.get("/{claim_id}", response_model=ClaimResponse)
def get_claim(claim_id: int, db: Session = Depends(get_db)):
    """Retrieve claim details by ID."""
    return claim_service.get_by_id(db, claim_id)


@router.put("/{claim_id}/approve", response_model=ClaimResponse)
def approve_claim(
    claim_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Provider approves the claim reservation."""
    return claim_service.approve_claim(db, claim_id, current_user=current_user)


@router.post("/{claim_id}/verify-otp", response_model=ClaimResponse)
def verify_pickup_otp(
    claim_id: int,
    data: ClaimVerifyOTP,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Verify pickup handoff using the recipient's 6-digit OTP code."""
    return claim_service.verify_pickup_otp(
        db, claim_id, data.pickup_otp, current_user=current_user
    )
