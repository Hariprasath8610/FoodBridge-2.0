from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, ConfigDict, field_validator
from app.models.user import UserRole, VerificationStatus


class UserBase(BaseModel):
    email: EmailStr
    organization_name: str
    organization_type: str
    role: UserRole = UserRole.SENDER
    phone: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class UserCreate(UserBase):
    firebase_uid: str
    verification_status: VerificationStatus = VerificationStatus.PENDING


class UserUpdate(BaseModel):
    organization_name: Optional[str] = None
    organization_type: Optional[str] = None
    phone: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    verification_status: Optional[VerificationStatus] = None


class UserMeResponse(BaseModel):
    id: str
    firebase_uid: str
    email: str
    organization_name: str
    organization_type: str
    role: str
    verification_status: str

    @field_validator("id", mode="before")
    @classmethod
    def serialize_id(cls, v):
        return str(v)

    model_config = ConfigDict(from_attributes=True)


class UserResponse(BaseModel):
    id: int
    firebase_uid: str
    email: str
    organization_name: str
    organization_type: str
    role: str
    verification_status: str
    phone: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)
