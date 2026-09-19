from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user, require_sender, require_recipient
from app.models.user import User
from app.schemas.user import UserCreate, UserMeResponse, UserResponse, UserUpdate
from app.services.user_service import user_service

router = APIRouter(prefix="/auth", tags=["Auth & Organizations"])


@router.get("/me", response_model=UserMeResponse)
def get_current_user_profile(current_user: User = Depends(get_current_user)):
    """Retrieve current authenticated user profile using Firebase token."""
    return current_user


@router.post("/register", response_model=UserResponse)
def register_user(
    data: UserCreate,
    db: Session = Depends(get_db),
):
    """Register a new verified Food Provider (sender) or Recipient organization."""
    return user_service.create(db, data)


@router.put("/me", response_model=UserResponse)
def update_profile(
    data: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update profile details for the authenticated user."""
    return user_service.update(db, current_user.id, data)


@router.get("/sender-only")
def test_sender_access(sender: User = Depends(require_sender)):
    """Test endpoint accessible only to users with authoritative 'sender' role in DB."""
    return {
        "success": True,
        "message": f"Welcome Sender: {sender.organization_name}",
        "role": sender.role,
    }


@router.get("/recipient-only")
def test_recipient_access(recipient: User = Depends(require_recipient)):
    """Test endpoint accessible only to users with authoritative 'recipient' role in DB."""
    return {
        "success": True,
        "message": f"Welcome Recipient: {recipient.organization_name}",
        "role": recipient.role,
    }


@router.get("/organizations", response_model=List[UserResponse])
def list_organizations(
    role: Optional[str] = Query(None, description="sender or recipient"),
    limit: int = Query(50, ge=1, le=100),
    skip: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    """List verified partner organizations."""
    return user_service.list_users(db, role=role, limit=limit, skip=skip)
