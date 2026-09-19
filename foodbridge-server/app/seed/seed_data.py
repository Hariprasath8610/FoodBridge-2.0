"""
FoodBridge Deterministic Demo Seed System
-----------------------------------------
Seeds fictional demo organizations, realistic Bangalore coordinates, hunger demand,
historical predictions, the required wedding demo scenario, active food listings,
completed rescue missions, and social impact records.

Organizations:
PROVIDERS:
  1. GreenLeaf Hotel (Hotel - Indiranagar, Bangalore)
  2. Sunrise Wedding Hall (Wedding - Palace Grounds, Bangalore)
  3. ABC College Hostel (Hostel/College - Koramangala, Bangalore)

RECIPIENTS (All VERIFIED):
  1. Hope Community Kitchen (Shivajinagar, Bangalore)
  2. Sunrise Community Shelter (Vasanth Nagar, Bangalore)
  3. CareBridge Community Center (Victoria Layout, Bangalore)

Demo Scenario:
  - Event: Wedding at Sunrise Wedding Hall
  - Expected Guests: 500
  - Planned Meals: 500
  - Historical Attendance: 92% (0.92)
  - Current Attendance: 430
  - Weather: Heavy Rain
  - Day: Saturday
  - Historical Surplus Rate: 8% (0.08)

Command to run:
  python -m app.seed.seed_data
"""

import json
from datetime import datetime, timedelta

from app.core.database import SessionLocal, engine, Base
from app.models.user import User, UserRole, VerificationStatus
from app.models.recipient import Recipient
from app.models.food_listing import (
    FoodListing,
    FoodType,
    MealType,
    ListingStatus,
    StorageRequirement,
)
from app.models.claim import Claim, ClaimStatus
from app.models.prediction import Prediction
from app.models.rescue_mission import RescueMission, RescueStatus, FoodSafetyStatus
from app.models.impact_record import ImpactRecord
from app.models.prediction_feedback import PredictionFeedback
from app.ml.predictor import SurplusPredictor


def seed_database():
    """Drop and recreate all tables, then seed deterministic demo data."""
    print("=" * 65)
    print("  FoodBridge Deterministic Demo Seed System")
    print("=" * 65)
    print("\n[1/7] Dropping and recreating database schema...")
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()
    try:
        now = datetime.utcnow()

        # -------------------------------------------------------------
        # 1. Fictional Demo Providers
        # -------------------------------------------------------------
        print("\n[2/7] Seeding Fictional Demo Providers...")
        providers = [
            User(
                id=1,
                firebase_uid="firebase-sender-hotel-1",
                email="hotel@greenleaf.demo",
                organization_name="GreenLeaf Hotel",
                organization_type="HOTEL",
                role=UserRole.SENDER.value,
                verification_status=VerificationStatus.VERIFIED.value,
                phone="+91 98450 11111",
                latitude=12.9784,
                longitude=77.6408,  # Indiranagar, Bangalore
                created_at=now - timedelta(days=30),
            ),
            User(
                id=2,
                firebase_uid="firebase-sender-wedding-1",
                email="events@sunrisewedding.demo",
                organization_name="Sunrise Wedding Hall",
                organization_type="WEDDING",
                role=UserRole.SENDER.value,
                verification_status=VerificationStatus.VERIFIED.value,
                phone="+91 98450 22222",
                latitude=13.0033,
                longitude=77.5891,  # Palace Grounds, Bangalore
                created_at=now - timedelta(days=45),
            ),
            User(
                id=3,
                firebase_uid="firebase-sender-college-1",
                email="mess@abccollege.demo",
                organization_name="ABC College Hostel",
                organization_type="COLLEGE",
                role=UserRole.SENDER.value,
                verification_status=VerificationStatus.VERIFIED.value,
                phone="+91 98450 33333",
                latitude=12.9345,
                longitude=77.6050,  # Koramangala / Adugodi, Bangalore
                created_at=now - timedelta(days=60),
            ),
        ]
        for p in providers:
            db.add(p)
        db.commit()
        for p in providers:
            print(f"  [OK] Provider #{p.id}: {p.organization_name} ({p.organization_type}) - {p.email}")

        # -------------------------------------------------------------
        # 2. Fictional Demo Recipients (All VERIFIED)
        # -------------------------------------------------------------
        print("\n[3/7] Seeding Fictional Demo Recipients (All VERIFIED)...")
        # Recipient User Accounts (Authorized to login and request rescues)
        recipient_users = [
            User(
                id=4,
                firebase_uid="firebase-recipient-kitchen-1",
                email="contact@hopekitchen.demo",
                organization_name="Hope Community Kitchen",
                organization_type="COMMUNITY_KITCHEN",
                role=UserRole.RECIPIENT.value,
                verification_status=VerificationStatus.VERIFIED.value,
                phone="+91 98800 11111",
                latitude=12.9785,
                longitude=77.6010,  # Shivajinagar, Central Bangalore
                created_at=now - timedelta(days=90),
            ),
            User(
                id=5,
                firebase_uid="firebase-recipient-shelter-1",
                email="help@sunriseshelter.demo",
                organization_name="Sunrise Community Shelter",
                organization_type="SHELTER",
                role=UserRole.RECIPIENT.value,
                verification_status=VerificationStatus.VERIFIED.value,
                phone="+91 98800 22222",
                latitude=12.9850,
                longitude=77.5920,  # Vasanth Nagar, Bangalore
                created_at=now - timedelta(days=75),
            ),
            User(
                id=6,
                firebase_uid="firebase-recipient-center-1",
                email="admin@carebridge.demo",
                organization_name="CareBridge Community Center",
                organization_type="COMMUNITY_CENTER",
                role=UserRole.RECIPIENT.value,
                verification_status=VerificationStatus.VERIFIED.value,
                phone="+91 98800 33333",
                latitude=12.9640,
                longitude=77.6150,  # Victoria Layout, Bangalore
                created_at=now - timedelta(days=50),
            ),
        ]
        for ru in recipient_users:
            db.add(ru)
        db.commit()

        # Recipient Entity Profiles for Matching Engine
        recipients_profiles = [
            Recipient(
                id=1,
                user_id=4,
                organization_name="Hope Community Kitchen",
                organization_type="community_kitchen",
                people_served=250,
                current_demand=120,
                maximum_capacity=300,
                food_preferences="all",
                availability_start="07:00",
                availability_end="23:00",
                latitude=12.9785,
                longitude=77.6010,
                verification_status="VERIFIED",
                created_at=now - timedelta(days=90),
            ),
            Recipient(
                id=2,
                user_id=5,
                organization_name="Sunrise Community Shelter",
                organization_type="shelter",
                people_served=180,
                current_demand=95,
                maximum_capacity=200,
                food_preferences="vegetarian",
                availability_start="06:00",
                availability_end="22:00",
                latitude=12.9850,
                longitude=77.5920,
                verification_status="VERIFIED",
                created_at=now - timedelta(days=75),
            ),
            Recipient(
                id=3,
                user_id=6,
                organization_name="CareBridge Community Center",
                organization_type="community_center",
                people_served=140,
                current_demand=60,
                maximum_capacity=160,
                food_preferences="all",
                availability_start="09:00",
                availability_end="21:00",
                latitude=12.9640,
                longitude=77.6150,
                verification_status="VERIFIED",
                created_at=now - timedelta(days=50),
            ),
        ]
        for rp in recipients_profiles:
            db.add(rp)
        db.commit()
        for rp in recipients_profiles:
            print(
                f"  [OK] Recipient #{rp.id} (User #{rp.user_id}): {rp.organization_name} "
                f"[Demand: {rp.current_demand}, Cap: {rp.maximum_capacity}, Diet: {rp.food_preferences}, "
                f"Hours: {rp.availability_start}-{rp.availability_end}, Status: {rp.verification_status}]"
            )

        # -------------------------------------------------------------
        # 3. Demo Scenario: Wedding (500 expected, 500 planned, 92%, rain, Saturday)
        # -------------------------------------------------------------
        print("\n[4/7] Seeding Demo Scenario Prediction & Historical AI Data...")
        predictor = SurplusPredictor()
        ml_prediction = predictor.predict(
            expected_people=500,
            planned_quantity=500,
            historical_attendance_rate=0.92,
            current_attendance=430,
            event_type="wedding",
            menu_category="vegetarian",
            weather_condition="heavy_rain",
            day_of_week="saturday",
            historical_surplus_rate=0.08,
        )

        demo_wedding_prediction = Prediction(
            prediction_id="pred_demo_wedding_scenario_01",
            provider_id=2,  # Sunrise Wedding Hall
            expected_people=500,
            planned_quantity=500,
            historical_attendance_rate=0.92,
            current_attendance=430,
            event_type="wedding",
            menu_category="vegetarian",
            weather_condition="heavy_rain",
            day_of_week="saturday",
            historical_surplus_rate=0.08,
            predicted_consumption=ml_prediction["predicted_consumption"],
            predicted_surplus_min=ml_prediction["predicted_surplus_min"],
            predicted_surplus_max=ml_prediction["predicted_surplus_max"],
            surplus_percentage=ml_prediction["surplus_percentage"],
            risk_level=ml_prediction["risk_level"],
            explanation=ml_prediction["explanation"],
            factors_json=json.dumps(ml_prediction.get("factors", [])),
            created_at=now - timedelta(minutes=45),
        )
        db.add(demo_wedding_prediction)

        # Additional historical prediction (GreenLeaf Hotel buffet from previous day)
        hotel_past_pred = Prediction(
            prediction_id="pred_demo_hotel_past_01",
            provider_id=1,  # GreenLeaf Hotel
            expected_people=120,
            planned_quantity=130,
            historical_attendance_rate=0.95,
            current_attendance=105,
            event_type="buffet_hotel",
            menu_category="mixed",
            weather_condition="clear",
            day_of_week="friday",
            historical_surplus_rate=0.06,
            predicted_consumption=104.0,
            predicted_surplus_min=18.0,
            predicted_surplus_max=32.0,
            surplus_percentage=19.2,
            risk_level="HIGH",
            explanation="Friday executive lunch buffet experienced early departure of corporate attendees.",
            factors_json=json.dumps([{"factor": "attendance_gap", "effect": "increase_risk", "description": "Attendance below expected."}]),
            created_at=now - timedelta(days=1, hours=4),
        )
        db.add(hotel_past_pred)

        # Additional historical prediction (ABC College Hostel from 2 days ago)
        hostel_past_pred = Prediction(
            prediction_id="pred_demo_hostel_past_01",
            provider_id=3,  # ABC College Hostel
            expected_people=300,
            planned_quantity=300,
            historical_attendance_rate=0.88,
            current_attendance=240,
            event_type="hostel_canteen",
            menu_category="vegetarian",
            weather_condition="mild_rain",
            day_of_week="thursday",
            historical_surplus_rate=0.07,
            predicted_consumption=242.0,
            predicted_surplus_min=45.0,
            predicted_surplus_max=75.0,
            surplus_percentage=20.0,
            risk_level="HIGH",
            explanation="Hostel dinner after university exam schedule shift led to surplus.",
            factors_json=json.dumps([{"factor": "weather", "effect": "increase_risk", "description": "Rain reduced mess walk-ins."}]),
            created_at=now - timedelta(days=2, hours=3),
        )
        db.add(hostel_past_pred)
        db.commit()

        print(
            f"  [OK] Seeded Demo Scenario: 'pred_demo_wedding_scenario_01'\n"
            f"    - Event: Wedding at Sunrise Wedding Hall\n"
            f"    - 500 Expected | 500 Planned | 92% Attendance Rate | 430 Current | Heavy Rain | Saturday\n"
            f"    - ML Predicted Consumption: {demo_wedding_prediction.predicted_consumption} meals\n"
            f"    - ML Surplus Range: {demo_wedding_prediction.predicted_surplus_min} - {demo_wedding_prediction.predicted_surplus_max} meals "
            f"({demo_wedding_prediction.surplus_percentage}%, {demo_wedding_prediction.risk_level} Risk)\n"
            f"  [OK] Seeded 2 Historical Prediction records for model validation."
        )

        # -------------------------------------------------------------
        # 4. Active Food Listings
        # -------------------------------------------------------------
        print("\n[5/7] Seeding Active Food Listings...")
        listings = [
            FoodListing(
                id=1,
                provider_id=2,  # Sunrise Wedding Hall
                title="Traditional South Indian Wedding Feast - Rice, Sambar, Kootu, Payasam",
                description="Hot, hygienically packaged wedding banquet surplus. Packed in food-grade insulated thermoware.",
                food_type=FoodType.VEG.value,
                meal_type=MealType.DINNER.value,
                quantity_servings=120,
                weight_kg=54.0,
                prepared_time=now - timedelta(hours=1),
                expiry_time=now + timedelta(hours=5),
                status=ListingStatus.AVAILABLE.value,
                storage_requirement=StorageRequirement.ROOM_TEMP.value,
                pickup_address="Sunrise Wedding Hall Gate 2, Palace Grounds",
                city="Bangalore",
                latitude=13.0033,
                longitude=77.5891,
                contact_phone="+91 98450 22222",
                created_at=now - timedelta(hours=1),
            ),
            FoodListing(
                id=2,
                provider_id=1,  # GreenLeaf Hotel
                title="GreenLeaf Executive Lunch Surplus - Dal Makhani & Jeera Rice",
                description="Hygienically maintained buffet surplus kept under 65°C heating trays.",
                food_type=FoodType.VEG.value,
                meal_type=MealType.LUNCH.value,
                quantity_servings=45,
                weight_kg=20.0,
                prepared_time=now - timedelta(hours=2),
                expiry_time=now + timedelta(hours=4),
                status=ListingStatus.AVAILABLE.value,
                storage_requirement=StorageRequirement.HEATED.value,
                pickup_address="GreenLeaf Hotel Service Lane, 100ft Road, Indiranagar",
                city="Bangalore",
                latitude=12.9784,
                longitude=77.6408,
                contact_phone="+91 98450 11111",
                created_at=now - timedelta(hours=2),
            ),
        ]
        for l in listings:
            db.add(l)
        db.commit()
        for l in listings:
            print(f"  [OK] FoodListing #{l.id}: '{l.title}' [{l.quantity_servings} servings, {l.status}]")

        # -------------------------------------------------------------
        # 5. Food Rescue Missions (Completed & Active)
        # -------------------------------------------------------------
        print("\n[6/7] Seeding Food Rescue Missions & Chain-of-Custody Lifecycles...")
        rescues = [
            # Completed mission 1: GreenLeaf Hotel -> Hope Community Kitchen
            RescueMission(
                id=1,
                rescue_code="RESCUE-DEMO-2026-DELIVERED-01",
                prediction_id="pred_demo_hotel_past_01",
                provider_id=1,  # GreenLeaf Hotel
                recipient_id=4,  # Hope Community Kitchen
                food_source_id=2,
                quantity=80,
                status=RescueStatus.DELIVERED.value,
                food_safety_status=FoodSafetyStatus.SAFE_VERIFIED.value,
                pickup_otp="482910",
                delivery_otp="931048",
                pickup_time=now - timedelta(days=1, hours=2),
                delivery_time=now - timedelta(days=1, hours=1),
                created_at=now - timedelta(days=1, hours=4),
                updated_at=now - timedelta(days=1, hours=1),
            ),
            # Completed mission 2: ABC College Hostel -> Sunrise Community Shelter
            RescueMission(
                id=2,
                rescue_code="RESCUE-DEMO-2026-DELIVERED-02",
                prediction_id="pred_demo_hostel_past_01",
                provider_id=3,  # ABC College Hostel
                recipient_id=5,  # Sunrise Community Shelter
                food_source_id=None,
                quantity=60,
                status=RescueStatus.DELIVERED.value,
                food_safety_status=FoodSafetyStatus.SAFE_VERIFIED.value,
                pickup_otp="519283",
                delivery_otp="772910",
                pickup_time=now - timedelta(days=2, hours=1),
                delivery_time=now - timedelta(days=2, minutes=30),
                created_at=now - timedelta(days=2, hours=3),
                updated_at=now - timedelta(days=2, minutes=30),
            ),
        ]
        for r in rescues:
            db.add(r)
        db.commit()
        for r in rescues:
            print(f"  [OK] RescueMission #{r.id}: {r.rescue_code} [{r.quantity} meals, Status: {r.status}]")

        # -------------------------------------------------------------
        # 6. Social Impact Tracking & AI Continuous Feedback Loop
        # -------------------------------------------------------------
        print("\n[7/7] Seeding Impact Records & AI Feedback Loop...")
        # Demo assumptions: 0.45 kg/meal, Rs. 80/meal, 1 person/meal
        impact_records = [
            ImpactRecord(
                id=1,
                rescue_id=1,
                meals_rescued=80,
                people_served=80,
                food_quantity_kg=round(80 * 0.45, 1),      # 36.0 kg
                estimated_food_value=round(80 * 80.0, 1),  # Rs. 6,400
                waste_avoided=round(80 * 0.45, 1),         # 36.0 kg
                created_at=now - timedelta(days=1, hours=1),
            ),
            ImpactRecord(
                id=2,
                rescue_id=2,
                meals_rescued=60,
                people_served=60,
                food_quantity_kg=round(60 * 0.45, 1),      # 27.0 kg
                estimated_food_value=round(60 * 80.0, 1),  # Rs. 4,800
                waste_avoided=round(60 * 0.45, 1),         # 27.0 kg
                created_at=now - timedelta(days=2, minutes=30),
            ),
        ]
        for imp in impact_records:
            db.add(imp)
        db.commit()

        # Seed prediction feedback (closing the loop: Predicted vs Actual)
        feedbacks = [
            PredictionFeedback(
                id=1,
                prediction_id="pred_demo_hotel_past_01",
                predicted_quantity=85.0,
                actual_quantity=80.0,
                absolute_error=5.0,
                percentage_error=6.25,
                created_at=now - timedelta(days=1, hours=1),
            ),
            PredictionFeedback(
                id=2,
                prediction_id="pred_demo_hostel_past_01",
                predicted_quantity=65.0,
                actual_quantity=60.0,
                absolute_error=5.0,
                percentage_error=8.33,
                created_at=now - timedelta(days=2, minutes=30),
            ),
        ]
        for fb in feedbacks:
            db.add(fb)
        db.commit()

        # Print Database Verification Summary
        print("\n" + "=" * 65)
        print("  DATABASE VERIFICATION SUMMARY")
        print("=" * 65)
        users_count = db.query(User).count()
        senders_count = db.query(User).filter(User.role == "sender").count()
        recipients_user_count = db.query(User).filter(User.role == "recipient").count()
        recipients_count = db.query(Recipient).filter(Recipient.verification_status == "VERIFIED").count()
        predictions_count = db.query(Prediction).count()
        listings_count = db.query(FoodListing).count()
        rescues_count = db.query(RescueMission).count()
        delivered_count = db.query(RescueMission).filter(RescueMission.status == "DELIVERED").count()
        impact_count = db.query(ImpactRecord).count()
        feedback_count = db.query(PredictionFeedback).count()

        print(f"  * Total Users:               {users_count} ({senders_count} Providers, {recipients_user_count} Recipient Accounts)")
        print(f"  * Verified Recipient Orgs:   {recipients_count} (Hope Kitchen, Sunrise Shelter, CareBridge Center)")
        print(f"  * Prediction Scenarios:      {predictions_count} (Includes Wedding Saturday Heavy Rain Scenario)")
        print(f"  * Active Food Listings:      {listings_count}")
        print(f"  * Rescue Missions:           {rescues_count} ({delivered_count} DELIVERED)")
        print(f"  * Impact Records:            {impact_count} (Meals: 140, Food: 63.0 kg, Value: Rs. 11,200)")
        print(f"  * AI Feedback Records:       {feedback_count} (Error loop verified)")
        print("=" * 65)
        print("[OK] FoodBridge Demo Database Successfully Seeded & Ready for Demo!\n")

    finally:
        db.close()


if __name__ == "__main__":
    seed_database()
