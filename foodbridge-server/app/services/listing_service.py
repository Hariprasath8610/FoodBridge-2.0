from datetime import datetime
from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.food_listing import FoodListing, ListingStatus
from app.models.user import User
from app.schemas.food_listing import FoodListingCreate, FoodListingUpdate
from app.core.exceptions import NotFoundException, BadRequestException, ForbiddenException


class ListingService:
    @staticmethod
    def get_by_id(db: Session, listing_id: int) -> FoodListing:
        listing = db.query(FoodListing).filter(FoodListing.id == listing_id).first()
        if not listing:
            raise NotFoundException("FoodListing", listing_id)
        return listing

    @staticmethod
    def create(db: Session, data: FoodListingCreate, provider: User) -> FoodListing:
        if provider.role not in ["sender", "PROVIDER", "ADMIN"]:
            raise ForbiddenException("Only verified food senders/providers can publish food listings.")

        if data.expiry_time <= data.prepared_time:
            raise BadRequestException("Expiry time must be strictly after prepared time.")

        listing = FoodListing(
            provider_id=provider.id,
            title=data.title,
            description=data.description,
            food_type=data.food_type.value if hasattr(data.food_type, "value") else data.food_type,
            meal_type=data.meal_type.value if hasattr(data.meal_type, "value") else data.meal_type,
            quantity_servings=data.quantity_servings,
            weight_kg=data.weight_kg,
            prepared_time=data.prepared_time,
            expiry_time=data.expiry_time,
            status=ListingStatus.AVAILABLE.value,
            storage_requirement=(
                data.storage_requirement.value
                if hasattr(data.storage_requirement, "value")
                else data.storage_requirement
            ),
            pickup_address=data.pickup_address,
            city=data.city,
            latitude=data.latitude or provider.latitude,
            longitude=data.longitude or provider.longitude,
            contact_phone=data.contact_phone or provider.phone,
        )
        db.add(listing)
        db.commit()
        db.refresh(listing)
        return listing

    @staticmethod
    def update(
        db: Session, listing_id: int, data: FoodListingUpdate, current_user: User
    ) -> FoodListing:
        listing = ListingService.get_by_id(db, listing_id)
        if listing.provider_id != current_user.id and current_user.role != "ADMIN":
            raise ForbiddenException("You can only modify your own listings.")

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            if hasattr(value, "value"):
                value = value.value
            setattr(listing, key, value)

        db.commit()
        db.refresh(listing)
        return listing

    @staticmethod
    def list_listings(
        db: Session,
        status: Optional[str] = ListingStatus.AVAILABLE.value,
        city: Optional[str] = None,
        food_type: Optional[str] = None,
        min_servings: Optional[int] = None,
        provider_id: Optional[int] = None,
        limit: int = 50,
        skip: int = 0,
    ) -> List[FoodListing]:
        query = db.query(FoodListing)

        if status:
            query = query.filter(FoodListing.status == status)
        if city:
            query = query.filter(FoodListing.city.ilike(f"%{city}%"))
        if food_type:
            query = query.filter(FoodListing.food_type == food_type)
        if min_servings:
            query = query.filter(FoodListing.quantity_servings >= min_servings)
        if provider_id:
            query = query.filter(FoodListing.provider_id == provider_id)

        return (
            query.order_by(FoodListing.expiry_time.asc())
            .offset(skip)
            .limit(limit)
            .all()
        )


listing_service = ListingService()
