from fastapi import APIRouter, Depends
from app.core.security import get_current_user
from app.models.user import User
from app.schemas.user import UserMeResponse

router = APIRouter(tags=["Profile"])


@router.get("/me", response_model=UserMeResponse)
def get_me(current_user: User = Depends(get_current_user)):
    """Authoritative user profile lookup using verified Firebase UID.

    Requires: Authorization: Bearer <Firebase ID token>
    """
    return current_user
