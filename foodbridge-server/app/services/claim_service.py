import random
import string
from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.claim import Claim, ClaimStatus
from app.models.food_listing import FoodListing, ListingStatus
from app.models.user import User
from app.schemas.claim import ClaimCreate
from app.core.exceptions import NotFoundException, BadRequestException, ForbiddenException


def generate_otp() -> str:
    """Generate a 6-digit verification code for secure food handoff."""
    return "".join(random.choices(string.digits, k=6))


class ClaimService:
    @staticmethod
    def get_by_id(db: Session, claim_id: int) -> Claim:
        claim = db.query(Claim).filter(Claim.id == claim_id).first()
        if not claim:
            raise NotFoundException("Claim", claim_id)
        return claim

    @staticmethod
    def create_claim(db: Session, data: ClaimCreate, recipient: User) -> Claim:
        if recipient.role not in ["recipient", "RECIPIENT", "ADMIN"]:
            raise ForbiddenException("Only verified food recipients (NGOs, Shelters) can claim food.")

        listing = (
            db.query(FoodListing)
            .filter(FoodListing.id == data.listing_id)
            .first()
        )
        if not listing:
            raise NotFoundException("FoodListing", data.listing_id)

        if listing.status != ListingStatus.AVAILABLE.value:
            raise BadRequestException(f"Listing is not available for claim (current status: {listing.status}).")

        if data.servings_requested > listing.quantity_servings:
            raise BadRequestException(
                f"Requested servings ({data.servings_requested}) exceed available quantity ({listing.quantity_servings})."
            )

        otp = generate_otp()
        claim = Claim(
            listing_id=listing.id,
            recipient_id=recipient.id,
            servings_requested=data.servings_requested,
            notes=data.notes,
            status=ClaimStatus.REQUESTED.value,
            pickup_otp=otp,
        )
        # Mark listing as reserved
        listing.status = ListingStatus.RESERVED.value

        db.add(claim)
        db.commit()
        db.refresh(claim)
        return claim

    @staticmethod
    def approve_claim(db: Session, claim_id: int, current_user: User) -> Claim:
        claim = ClaimService.get_by_id(db, claim_id)
        listing = claim.listing

        if listing.provider_id != current_user.id and current_user.role != "ADMIN":
            raise ForbiddenException("Only the food provider can approve this claim.")

        claim.status = ClaimStatus.APPROVED.value
        db.commit()
        db.refresh(claim)
        return claim

    @staticmethod
    def verify_pickup_otp(
        db: Session, claim_id: int, otp_code: str, current_user: User
    ) -> Claim:
        claim = ClaimService.get_by_id(db, claim_id)
        listing = claim.listing

        if listing.provider_id != current_user.id and current_user.role != "ADMIN":
            raise ForbiddenException("Only the food provider can confirm the pickup with OTP.")

        if claim.pickup_otp != otp_code:
            raise BadRequestException("Invalid pickup verification OTP code.")

        claim.status = ClaimStatus.COMPLETED.value
        listing.status = ListingStatus.CLAIMED.value
        db.commit()
        db.refresh(claim)
        return claim

    @staticmethod
    def list_claims(
        db: Session,
        recipient_id: Optional[int] = None,
        provider_id: Optional[int] = None,
        status: Optional[str] = None,
        limit: int = 50,
        skip: int = 0,
    ) -> List[Claim]:
        query = db.query(Claim)
        if recipient_id:
            query = query.filter(Claim.recipient_id == recipient_id)
        if provider_id:
            query = query.join(FoodListing).filter(FoodListing.provider_id == provider_id)
        if status:
            query = query.filter(Claim.status == status)

        return query.order_by(Claim.created_at.desc()).offset(skip).limit(limit).all()


claim_service = ClaimService()
