from typing import Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.user import User, UserRole
from app.services.firebase_service import firebase_service

security_scheme = HTTPBearer(auto_error=False)


def get_firebase_token_payload(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security_scheme),
) -> dict:
    """Reads Authorization: Bearer <Firebase ID token>, verifies it, and extracts uid & email."""
    if not credentials or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header with Bearer token is required.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = credentials.credentials
    try:
        payload = firebase_service.verify_token(token)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid or expired Firebase ID token: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )

    uid = payload.get("uid") or payload.get("user_id") or payload.get("sub")
    email = payload.get("email")

    if not uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token payload does not contain a valid user identifier (uid).",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return {"uid": uid, "email": email, "raw_payload": payload}


def get_current_user(
    token_data: dict = Depends(get_firebase_token_payload),
    db: Session = Depends(get_db),
) -> User:
    """Authoritative user lookup from the backend database using firebase_uid.

    Never trusts client-supplied roles; the database record is the single source of truth.
    """
    firebase_uid = token_data["uid"]
    user = db.query(User).filter(User.firebase_uid == firebase_uid).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"FoodBridge user profile not found for Firebase UID '{firebase_uid}'. Please complete registration.",
        )

    return user


def require_sender(
    current_user: User = Depends(get_current_user),
) -> User:
    """Enforces sender role authorization.

    The database record is authoritative.
    """
    if current_user.role != UserRole.SENDER.value and current_user.role != "sender":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access forbidden: sender role required.",
        )
    return current_user


def require_recipient(
    current_user: User = Depends(get_current_user),
) -> User:
    """Enforces recipient role authorization.

    The database record is authoritative.
    """
    if current_user.role != UserRole.RECIPIENT.value and current_user.role != "recipient":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access forbidden: recipient role required.",
        )
    return current_user


def get_current_user_optional(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security_scheme),
    db: Session = Depends(get_db),
) -> Optional[User]:
    """Retrieve authenticated user if Authorization Bearer header is present, else None."""
    if not credentials or not credentials.credentials:
        return None
    try:
        payload = firebase_service.verify_token(credentials.credentials)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid or expired token: {str(e)}",
        )
    uid = payload.get("uid") or payload.get("user_id") or payload.get("sub")
    if not uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token payload missing UID",
        )
    user = db.query(User).filter(User.firebase_uid == uid).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User profile not found for UID '{uid}'.",
        )
    return user

