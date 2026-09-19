from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.user import User, UserRole, VerificationStatus
from app.schemas.user import UserCreate, UserUpdate
from app.core.exceptions import NotFoundException, BadRequestException


class UserService:
    @staticmethod
    def get_by_id(db: Session, user_id: int) -> User:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise NotFoundException("User", user_id)
        return user

    @staticmethod
    def get_by_email(db: Session, email: str) -> Optional[User]:
        return db.query(User).filter(User.email == email).first()

    @staticmethod
    def get_by_firebase_uid(db: Session, uid: str) -> Optional[User]:
        return db.query(User).filter(User.firebase_uid == uid).first()

    @staticmethod
    def create(db: Session, data: UserCreate) -> User:
        existing_email = db.query(User).filter(User.email == data.email).first()
        if existing_email:
            raise BadRequestException(f"User with email '{data.email}' already exists.")

        existing_uid = db.query(User).filter(User.firebase_uid == data.firebase_uid).first()
        if existing_uid:
            raise BadRequestException(
                f"User with Firebase UID '{data.firebase_uid}' already exists."
            )

        role_val = data.role.value if hasattr(data.role, "value") else data.role
        ver_status = (
            data.verification_status.value
            if hasattr(data.verification_status, "value")
            else data.verification_status
        )

        user = User(
            firebase_uid=data.firebase_uid,
            email=data.email,
            organization_name=data.organization_name,
            organization_type=data.organization_type,
            role=role_val,
            verification_status=ver_status or VerificationStatus.PENDING.value,
            phone=data.phone,
            latitude=data.latitude,
            longitude=data.longitude,
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        return user

    @staticmethod
    def update(db: Session, user_id: int, data: UserUpdate) -> User:
        user = UserService.get_by_id(db, user_id)
        update_data = data.model_dump(exclude_unset=True)

        for key, value in update_data.items():
            if hasattr(value, "value"):
                value = value.value
            setattr(user, key, value)

        db.commit()
        db.refresh(user)
        return user

    @staticmethod
    def list_users(
        db: Session,
        role: Optional[str] = None,
        limit: int = 50,
        skip: int = 0,
    ) -> List[User]:
        query = db.query(User)
        if role:
            query = query.filter(User.role == role)
        return query.offset(skip).limit(limit).all()


user_service = UserService()
