import json
from app.core.database import SessionLocal
from app.models.user import User
from app.models.recipient import Recipient
from app.models.prediction import Prediction
from app.models.food_listing import FoodListing
from app.models.rescue_mission import RescueMission
from app.models.impact_record import ImpactRecord
from app.models.prediction_feedback import PredictionFeedback
from app.services.matching_service import MatchingService

def verify_seed():
    db = SessionLocal()
    try:
        print("--- VERIFYING PROVIDERS ---")
        providers = db.query(User).filter(User.role == "sender").all()
        provider_names = [p.organization_name for p in providers]
        print("Providers:", provider_names)
        assert "GreenLeaf Hotel" in provider_names
        assert "Sunrise Wedding Hall" in provider_names
        assert "ABC College Hostel" in provider_names
        print("[OK] All required providers verified.")

        print("\n--- VERIFYING RECIPIENTS ---")
        recipients = db.query(Recipient).all()
        recipient_names = [r.organization_name for r in recipients]
        print("Recipients:", recipient_names)
        assert "Hope Community Kitchen" in recipient_names
        assert "Sunrise Community Shelter" in recipient_names
        assert "CareBridge Community Center" in recipient_names
        for r in recipients:
            assert r.verification_status == "VERIFIED", f"{r.organization_name} is not VERIFIED!"
            print(f"  * {r.organization_name}: Status={r.verification_status}, Demand={r.current_demand}, Diet={r.food_preferences}, Hours={r.availability_start}-{r.availability_end}")
        print("[OK] All required recipients verified as VERIFIED.")

        print("\n--- VERIFYING DEMO SCENARIO PREDICTION ---")
        pred = db.query(Prediction).filter(Prediction.prediction_id == "pred_demo_wedding_scenario_01").first()
        assert pred is not None, "Demo wedding scenario prediction not found!"
        assert pred.event_type == "wedding"
        assert pred.expected_people == 500
        assert pred.planned_quantity == 500
        assert pred.historical_attendance_rate == 0.92
        assert pred.weather_condition == "heavy_rain"
        assert pred.day_of_week == "saturday"
        print(f"  * Prediction ID: {pred.prediction_id}")
        print(f"  * Event: {pred.event_type.title()} | Guests: {pred.expected_people} | Planned: {pred.planned_quantity}")
        print(f"  * Conditions: {pred.weather_condition} on {pred.day_of_week.title()} | Hist Attendance: {int(pred.historical_attendance_rate*100)}%")
        print(f"  * ML Consumption Forecast: {pred.predicted_consumption} meals")
        print(f"  * ML Surplus Range: {pred.predicted_surplus_min} - {pred.predicted_surplus_max} meals ({pred.surplus_percentage}%, Risk: {pred.risk_level})")
        print("[OK] Demo wedding scenario prediction verified.")

        print("\n--- VERIFYING INTELLIGENT MATCHING ENGINE ---")
        match_result = MatchingService.match_recipients_for_prediction(db, "pred_demo_wedding_scenario_01")
        print(f"  * Matching for: {match_result['prediction_id']} (Avg Surplus: {match_result['predicted_surplus_avg']} meals)")
        print(f"  * Total Ranked Matches: {match_result['total_matches']}")
        for idx, m in enumerate(match_result["matches"], 1):
            print(f"    - Rank #{idx}: {m['recipient'].organization_name} | Score: {m['match_score']} | Dist: {m['distance_km']} km | Demand: {m['current_demand']} | Urgency: {m['urgency']}")
        assert match_result["total_matches"] == 3
        print("[OK] Intelligent matching engine successfully ranked all verified recipients.")

        print("\n--- VERIFYING FOOD RESCUE MISSIONS ---")
        rescues = db.query(RescueMission).all()
        print(f"  * Total Rescue Missions: {len(rescues)}")
        for rm in rescues:
            print(f"    - {rm.rescue_code}: {rm.quantity} meals from Provider #{rm.provider_id} to Recipient #{rm.recipient_id} | Status: {rm.status}")
        assert len(rescues) >= 2
        print("[OK] Food rescue missions verified.")

        print("\n--- VERIFYING SOCIAL IMPACT RECORDS ---")
        impacts = db.query(ImpactRecord).all()
        total_meals = sum(i.meals_rescued for i in impacts)
        total_kg = sum(i.food_quantity_kg for i in impacts)
        total_val = sum(i.estimated_food_value for i in impacts)
        print(f"  * Total Rescues Logged: {len(impacts)}")
        print(f"  * Total Meals Rescued:  {total_meals}")
        print(f"  * Total Food Mass:      {total_kg} kg")
        print(f"  * Total Estimated Value: Rs. {total_val:,.2f}")
        assert total_meals > 0
        print("[OK] Social impact records verified.")

        print("\n--- VERIFYING PREDICTION FEEDBACK LOOP ---")
        feedbacks = db.query(PredictionFeedback).all()
        print(f"  * Total AI Feedbacks Logged: {len(feedbacks)}")
        for fb in feedbacks:
            print(f"    - Pred: {fb.prediction_id} | Predicted: {fb.predicted_quantity} | Actual: {fb.actual_quantity} | Abs Error: {fb.absolute_error} | % Error: {fb.percentage_error}%")
        assert len(feedbacks) >= 2
        print("[OK] AI prediction feedback loop verified.")

        print("\n=================================================")
        print("  ALL DATABASE AND SEED SYSTEM CHECKS PASSED!")
        print("=================================================")

    finally:
        db.close()

if __name__ == "__main__":
    verify_seed()
