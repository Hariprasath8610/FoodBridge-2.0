import datetime
import secrets
from typing import List, Optional
from sqlalchemy.orm import Session

from app.models.rescue_mission import RescueMission, RescueStatus, FoodSafetyStatus
from app.models.user import User, UserRole
from app.models.recipient import Recipient
from app.schemas.rescue import (
    RescueRequestCreate,
    FoodVerificationRequest,
)
from app.core.exceptions import (
    NotFoundException,
    BadRequestException,
    ForbiddenException,
)


def generate_secure_otp(length: int = 6) -> str:
    """Generate a cryptographically secure random numeric OTP."""
    return "".join(secrets.choice("0123456789") for _ in range(length))


def generate_rescue_code() -> str:
    """Generate a readable, unique mission tracking code."""
    date_str = datetime.datetime.utcnow().strftime("%Y%m%d")
    random_suffix = secrets.token_hex(3).upper()
    return f"RESCUE-{date_str}-{random_suffix}"


class RescueService:
    @staticmethod
    def get_by_id(db: Session, rescue_id: int, current_user: Optional[User] = None) -> RescueMission:
        rescue = db.query(RescueMission).filter(RescueMission.id == rescue_id).first()
        if not rescue:
            raise NotFoundException("RescueMission", rescue_id)
        if current_user and current_user.role != "ADMIN":
            if current_user.id != rescue.provider_id and current_user.id != rescue.recipient_id:
                raise ForbiddenException("You cannot access another organization's private rescue mission.")
        return rescue

    @staticmethod
    def request_rescue(
        db: Session,
        data: RescueRequestCreate,
        current_user: Optional[User] = None,
    ) -> RescueMission:
        """Recipient initiates a food rescue opportunity."""
        if current_user and current_user.role not in [UserRole.RECIPIENT.value, "recipient", "ADMIN"]:
            raise ForbiddenException("Only verified food recipients can request a food rescue.")

        recipient_id = current_user.id if current_user else (data.recipient_id or 6)

        # Enforce verification status: unverified recipient cannot request food
        recipient_user = current_user or db.query(User).filter(User.id == recipient_id).first()
        if recipient_user:
            if recipient_user.verification_status.lower() != "verified":
                raise ForbiddenException("Access forbidden: Unverified recipient organizations cannot request food rescues.")

        recipient_org = db.query(Recipient).filter(Recipient.user_id == recipient_id).first()
        if recipient_org and recipient_org.verification_status != "VERIFIED":
            raise ForbiddenException("Access forbidden: Unverified recipient organizations cannot request food rescues.")

        provider = db.query(User).filter(User.id == data.provider_id).first()
        if not provider:
            raise NotFoundException("Provider User", data.provider_id)

        mission = RescueMission(
            rescue_code=generate_rescue_code(),
            prediction_id=data.prediction_id,
            provider_id=provider.id,
            recipient_id=recipient_id,
            food_source_id=data.food_source_id,
            quantity=data.quantity,
            status=RescueStatus.RECIPIENT_REQUESTED.value,
            food_safety_status=FoodSafetyStatus.PENDING_VERIFICATION.value,
            pickup_otp=generate_secure_otp(6),
            delivery_otp=generate_secure_otp(6),
        )
        db.add(mission)
        db.commit()
        db.refresh(mission)
        return mission

    @staticmethod
    def approve_rescue(
        db: Session,
        rescue_id: int,
        current_user: Optional[User] = None,
    ) -> RescueMission:
        """Provider approves the rescue mission."""
        rescue = RescueService.get_by_id(db, rescue_id)

        # Authorization: Only the designated provider or admin can approve
        if current_user and current_user.role != "ADMIN" and current_user.id != rescue.provider_id:
            raise ForbiddenException("You cannot modify another organization's rescue mission.")

        # State transition validation
        if rescue.status == RescueStatus.CANCELLED.value:
            raise BadRequestException("Cannot approve a cancelled rescue mission.")

        if rescue.status not in [
            RescueStatus.RECIPIENT_REQUESTED.value,
            RescueStatus.CREATED.value,
        ]:
            raise BadRequestException(
                f"Cannot approve rescue in current status '{rescue.status}'."
            )

        rescue.status = RescueStatus.PROVIDER_APPROVED.value
        db.commit()
        db.refresh(rescue)
        return rescue

    @staticmethod
    def verify_food(
        db: Session,
        rescue_id: int,
        data: FoodVerificationRequest,
        current_user: Optional[User] = None,
    ) -> RescueMission:
        """Provider inspects food safety, packaging, and temperature."""
        rescue = RescueService.get_by_id(db, rescue_id)

        # Authorization: Only the designated provider or admin can verify food
        if current_user and current_user.role != "ADMIN" and current_user.id != rescue.provider_id:
            raise ForbiddenException("You cannot modify another organization's rescue mission.")

        # State transition validation
        if rescue.status == RescueStatus.CANCELLED.value:
            raise BadRequestException("Cannot verify food for a cancelled rescue mission.")

        if rescue.status != RescueStatus.PROVIDER_APPROVED.value:
            raise BadRequestException(
                f"Cannot verify food before provider approval. Current status: '{rescue.status}'."
            )

        safety_val = (
            data.safety_status.value
            if hasattr(data.safety_status, "value")
            else data.safety_status
        )

        rescue.status = RescueStatus.FOOD_VERIFIED.value
        rescue.food_safety_status = safety_val
        db.commit()
        db.refresh(rescue)
        return rescue

    @staticmethod
    def verify_pickup(
        db: Session,
        rescue_id: int,
        pickup_otp: Optional[str] = None,
        rescue_code: Optional[str] = None,
        current_user: Optional[User] = None,
    ) -> RescueMission:
        """Verify pickup handoff using recipient/driver's safe QR or fallback OTP."""
        rescue = RescueService.get_by_id(db, rescue_id)

        # Authorization: Provider, Recipient, or Admin
        if current_user and current_user.role != "ADMIN" and current_user.id not in [rescue.provider_id, rescue.recipient_id]:
            raise ForbiddenException("You cannot modify another organization's rescue mission.")

        # State transition validation: Cannot PICKED_UP before FOOD_VERIFIED
        if rescue.status == RescueStatus.CANCELLED.value:
            raise BadRequestException("Cannot pick up a cancelled rescue mission.")

        if rescue.status not in [
            RescueStatus.FOOD_VERIFIED.value,
            RescueStatus.PICKUP_READY.value,
        ]:
            raise BadRequestException(
                f"Cannot mark PICKED_UP before FOOD_VERIFIED. Current status: '{rescue.status}'."
            )

        # Verify via safe rescue code (from QR) or OTP (fallback)
        is_valid = False
        if pickup_otp and rescue.pickup_otp == pickup_otp.strip():
            is_valid = True
        elif rescue_code and rescue.rescue_code.strip().upper() == rescue_code.strip().upper():
            is_valid = True

        if not is_valid:
            if pickup_otp:
                raise BadRequestException("Invalid pickup verification OTP code.")
            raise BadRequestException("Invalid pickup verification code. Check QR or OTP.")

        rescue.status = RescueStatus.IN_TRANSIT.value
        rescue.pickup_time = datetime.datetime.utcnow()
        db.commit()
        db.refresh(rescue)
        return rescue

    @staticmethod
    def verify_delivery(
        db: Session,
        rescue_id: int,
        delivery_otp: Optional[str] = None,
        rescue_code: Optional[str] = None,
        current_user: Optional[User] = None,
    ) -> RescueMission:
        """Recipient confirms delivery receipt using safe QR or fallback OTP."""
        rescue = RescueService.get_by_id(db, rescue_id)

        # Authorization: Provider, Recipient, or Admin
        if current_user and current_user.role != "ADMIN" and current_user.id not in [rescue.provider_id, rescue.recipient_id]:
            raise ForbiddenException("You cannot modify another organization's rescue mission.")

        # State transition validation: Cannot deliver twice; cannot deliver before picked up
        if rescue.status == RescueStatus.DELIVERED.value:
            raise BadRequestException("Cannot deliver twice. Rescue mission is already completed.")

        if rescue.status == RescueStatus.CANCELLED.value:
            raise BadRequestException("Cannot deliver a cancelled rescue mission.")

        if rescue.status not in [
            RescueStatus.PICKED_UP.value,
            RescueStatus.IN_TRANSIT.value,
        ]:
            raise BadRequestException(
                f"Cannot mark DELIVERED before PICKED_UP. Current status: '{rescue.status}'."
            )

        # Verify via safe rescue code (from QR) or OTP (fallback)
        is_valid = False
        if delivery_otp and rescue.delivery_otp == delivery_otp.strip():
            is_valid = True
        elif rescue_code and rescue.rescue_code.strip().upper() == rescue_code.strip().upper():
            is_valid = True

        if not is_valid:
            if delivery_otp:
                raise BadRequestException("Invalid delivery verification OTP code.")
            raise BadRequestException("Invalid delivery verification code. Check QR or OTP.")

        rescue.status = RescueStatus.DELIVERED.value
        rescue.delivery_time = datetime.datetime.utcnow()

        # Automatically create ImpactRecord with clearly documented demo assumptions
        from app.models.impact_record import ImpactRecord

        existing_impact = (
            db.query(ImpactRecord).filter(ImpactRecord.rescue_id == rescue.id).first()
        )
        if not existing_impact:
            meals = rescue.quantity
            # Demo assumptions: 0.45 kg per prepared meal portion; ₹80 estimated value per portion
            kg = round(meals * 0.45, 2)
            val = round(meals * 80.0, 2)
            impact = ImpactRecord(
                rescue_id=rescue.id,
                meals_rescued=meals,
                people_served=meals,
                food_quantity_kg=kg,
                estimated_food_value=val,
                waste_avoided=kg,
            )
            db.add(impact)

        db.commit()
        db.refresh(rescue)
        return rescue

    @staticmethod
    def verify_qr(
        db: Session,
        qr_data: str,
        action: Optional[str] = None,
        rescue_id: Optional[int] = None,
        current_user: Optional[User] = None,
    ) -> RescueMission:
        """Verify rescue pickup or delivery via safe scanned QR payload.

        The QR code only contains a safe public rescue identifier (e.g. rescue_code).
        The backend remains authoritative and validates organization authorization and status progression.
        """
        import json
        clean_code = qr_data.strip()
        # Parse JSON if formatted as JSON
        if clean_code.startswith("{") and clean_code.endswith("}"):
            try:
                parsed = json.loads(clean_code)
                clean_code = parsed.get("rescue_code") or parsed.get("code") or clean_code
                if not rescue_id:
                    rescue_id = parsed.get("rescue_id") or parsed.get("id")
                if not action:
                    action = parsed.get("action") or parsed.get("type")
            except Exception:
                pass
        elif clean_code.startswith("FB-") or clean_code.startswith("foodbridge:"):
            parts = clean_code.replace("foodbridge:", "").split(":")
            if len(parts) >= 2:
                clean_code = parts[-1]

        # Look up mission by rescue_code or rescue_id
        query = db.query(RescueMission)
        if clean_code.startswith("RESCUE-"):
            rescue = query.filter(RescueMission.rescue_code == clean_code).first()
        elif rescue_id:
            rescue = query.filter(RescueMission.id == rescue_id).first()
        else:
            rescue = query.filter(RescueMission.rescue_code == clean_code).first()

        if not rescue:
            raise NotFoundException("RescueMission with identifier", clean_code)

        # Authorize: caller must be an authorized participant
        if current_user and current_user.role != "ADMIN" and current_user.id not in [rescue.provider_id, rescue.recipient_id]:
            raise ForbiddenException("You cannot verify another organization's rescue mission.")

        # Determine action from current state or explicit action hint
        if rescue.status in [RescueStatus.FOOD_VERIFIED.value, RescueStatus.PICKUP_READY.value] or action == "pickup":
            return RescueService.verify_pickup(
                db, rescue.id, rescue_code=rescue.rescue_code, current_user=current_user
            )
        elif rescue.status in [RescueStatus.PICKED_UP.value, RescueStatus.IN_TRANSIT.value] or action == "delivery":
            return RescueService.verify_delivery(
                db, rescue.id, rescue_code=rescue.rescue_code, current_user=current_user
            )
        elif rescue.status == RescueStatus.DELIVERED.value:
            return rescue
        else:
            raise BadRequestException(
                f"Rescue mission cannot be verified in current state: '{rescue.status}'."
            )

    @staticmethod
    def list_rescues(
        db: Session,
        current_user: Optional[User] = None,
        status: Optional[str] = None,
        limit: int = 50,
        skip: int = 0,
    ) -> List[RescueMission]:
        query = db.query(RescueMission)

        # Scope by organization if authenticated
        if current_user and current_user.role != "ADMIN":
            if current_user.role in [UserRole.SENDER.value, "sender"]:
                query = query.filter(RescueMission.provider_id == current_user.id)
            elif current_user.role in [UserRole.RECIPIENT.value, "recipient"]:
                query = query.filter(RescueMission.recipient_id == current_user.id)

        if status:
            query = query.filter(RescueMission.status == status)

        return (
            query.order_by(RescueMission.created_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )


rescue_service = RescueService()
