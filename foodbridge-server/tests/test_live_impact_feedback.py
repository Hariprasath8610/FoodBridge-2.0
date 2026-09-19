from fastapi.testclient import TestClient
from app.main import app
import json

client = TestClient(app)

def test_live_impact_and_feedback():
    # 1. Health check
    res = client.get("/health")
    assert res.status_code == 200, f"Health check failed: {res.text}"

    # 2. Check initial impact stats
    res = client.get("/api/dashboard/impact")
    assert res.status_code == 200, f"Impact dashboard failed: {res.text}"
    initial_impact = res.json()

    # 3. Create Prediction (Provider: GreenLeaf Hotel)
    provider_headers = {
        "Authorization": "Bearer test-firebase-sender-hotel-1:hotel@greenleaf.demo"
    }
    pred_payload = {
        "expected_people": 500,
        "planned_quantity": 500,
        "historical_attendance_rate": 0.92,
        "current_attendance": 430,
        "event_type": "wedding",
        "menu_category": "vegetarian",
        "weather_condition": "heavy_rain",
        "day_of_week": "saturday",
        "historical_surplus_rate": 0.08
    }
    res = client.post("/api/predictions", json=pred_payload, headers=provider_headers)
    assert res.status_code == 200, f"Prediction failed: {res.text}"
    pred_data = res.json()
    pred_id = pred_data["prediction_id"]

    # 4. Request Rescue (Recipient: Hope Community Kitchen, User ID 4)
    recipient_headers = {
        "Authorization": "Bearer test-firebase-recipient-kitchen-1:contact@hopekitchen.demo"
    }
    rescue_req_payload = {
        "provider_id": 1,
        "quantity": 100,
        "prediction_id": pred_id,
        "recipient_id": 4
    }
    res = client.post("/api/rescues/request", json=rescue_req_payload, headers=recipient_headers)
    assert res.status_code in (200, 201), f"Rescue request failed ({res.status_code}): {res.text}"
    rescue = res.json()
    rescue_id = rescue["id"]
    pickup_otp = rescue["pickup_otp"]
    delivery_otp = rescue["delivery_otp"]

    # 5. Provider Approves
    res = client.post(f"/api/rescues/{rescue_id}/approve", headers=provider_headers)
    assert res.status_code == 200, f"Approval failed: {res.text}"

    # 6. Provider Verifies Food
    food_verify_payload = {
        "safety_status": "SAFE_VERIFIED",
        "temperature_c": 68.5,
        "notes": "Optimal temperature maintained, hygienically packed"
    }
    res = client.post(f"/api/rescues/{rescue_id}/verify-food", json=food_verify_payload, headers=provider_headers)
    assert res.status_code == 200, f"Food verification failed: {res.text}"

    # 7. Pickup Verification (Provider verifies recipient's pickup OTP)
    pickup_payload = {"pickup_otp": pickup_otp}
    res = client.post(f"/api/rescues/{rescue_id}/pickup/verify", json=pickup_payload, headers=provider_headers)
    assert res.status_code == 200, f"Pickup verification failed: {res.text}"
    assert res.json()["status"] in ["IN_TRANSIT", "PICKED_UP"]

    # 8. Delivery Verification (Recipient confirms with delivery OTP)
    # This triggers the ImpactRecord creation!
    delivery_payload = {"delivery_otp": delivery_otp}
    res = client.post(f"/api/rescues/{rescue_id}/delivery/verify", json=delivery_payload, headers=recipient_headers)
    assert res.status_code == 200, f"Delivery verification failed: {res.text}"
    delivered_rescue = res.json()
    assert delivered_rescue["status"] == "DELIVERED"

    # 9. Verify Impact Dashboard updated
    res = client.get("/api/dashboard/impact")
    assert res.status_code == 200
    updated_impact = res.json()

    # Validate stats increased
    assert updated_impact["total_rescues"] >= initial_impact["total_rescues"] + 1
    assert updated_impact["total_meals_rescued"] >= initial_impact["total_meals_rescued"] + 100.0
    assert updated_impact["total_people_served"] >= initial_impact["total_people_served"] + 100
    assert updated_impact["total_food_kg_rescued"] >= initial_impact["total_food_kg_rescued"] + 45.0
    assert updated_impact["total_estimated_value"] >= initial_impact["total_estimated_value"] + 8000.0

    # 10. AI Prediction Feedback Loop
    feedback_payload = {
        "predicted_quantity": 118.0,
        "actual_quantity": 100.0
    }
    res = client.post(f"/api/predictions/{pred_id}/feedback", json=feedback_payload)
    assert res.status_code in (200, 201), f"Feedback submission failed ({res.status_code}): {res.text}"
    feedback = res.json()

    assert feedback["prediction_id"] == pred_id
    assert feedback["predicted_quantity"] == 118.0
    assert feedback["actual_quantity"] == 100.0
    assert feedback["absolute_error"] == 18.0
    assert feedback["percentage_error"] == 18.0

if __name__ == "__main__":
    test_live_impact_and_feedback()
    print("Integration test passed successfully!")
