import requests
import json
import base64
import sys
import os

sys.path.insert(0, os.path.abspath("."))

BASE_URL = "http://127.0.0.1:8000"

def run_live_acceptance():
    print("=" * 65)
    print("  FOODBRIDGE LIVE SERVER BACKEND ACCEPTANCE TEST")
    print("  Target: " + BASE_URL)
    print("=" * 65)

    session = requests.Session()

    # Step 0: Check server health
    res = session.get(f"{BASE_URL}/health")
    assert res.status_code == 200, f"Health check failed: {res.text}"
    health = res.json()
    print(f"\n[System Check] Server is healthy. DB: {health['database']}, Model Loaded: {health['ml_model_loaded']}")

    # Headers
    provider_headers = {
        "Authorization": "Bearer test-firebase-sender-hotel-1:hotel@greenleaf.demo"
    }
    recipient_headers = {
        "Authorization": "Bearer test-firebase-recipient-kitchen-1:contact@hopekitchen.demo"
    }
    third_party_headers = {
        "Authorization": "Bearer test-firebase-sender-college-1:mess@abccollege.demo"
    }

    # Step 1: Authenticate provider
    res = session.get(f"{BASE_URL}/api/me", headers=provider_headers)
    assert res.status_code == 200, f"Step 1 failed: {res.text}"
    prov_data = res.json()
    assert prov_data["role"] == "sender"
    assert prov_data["verification_status"] == "verified"
    print(f"[Step 1] Provider Authenticated: {prov_data['organization_name']} (Role: {prov_data['role']})")

    # Step 2: Authenticate recipient
    res = session.get(f"{BASE_URL}/api/me", headers=recipient_headers)
    assert res.status_code == 200, f"Step 2 failed: {res.text}"
    recip_data = res.json()
    assert recip_data["role"] == "recipient"
    assert recip_data["verification_status"] == "verified"
    print(f"[Step 2] Recipient Authenticated: {recip_data['organization_name']} (Role: {recip_data['role']})")

    # Step 3: Provider creates wedding prediction
    pred_payload = {
        "expected_people": 500,
        "planned_quantity": 500,
        "historical_attendance_rate": 0.92,
        "current_attendance": 430,
        "event_type": "wedding",
        "menu_category": "vegetarian",
        "weather_condition": "heavy_rain",
        "day_of_week": "saturday",
        "historical_surplus_rate": 0.08,
    }
    res = session.post(f"{BASE_URL}/api/predictions", json=pred_payload, headers=provider_headers)
    assert res.status_code == 200, f"Step 3 failed: {res.text}"
    pred_data = res.json()
    pred_id = pred_data["prediction_id"]
    print(f"[Step 3] Provider Created Wedding Prediction: {pred_id}")

    # Step 4: ML predicts surplus
    assert "predicted_consumption" in pred_data
    assert "predicted_surplus_min" in pred_data
    assert "predicted_surplus_max" in pred_data
    assert pred_data["risk_level"] == "HIGH"
    surplus_avg = round((pred_data["predicted_surplus_min"] + pred_data["predicted_surplus_max"]) / 2, 1)
    print(f"[Step 4] ML Predicted Surplus: {pred_data['predicted_surplus_min']} - {pred_data['predicted_surplus_max']} meals (~{surplus_avg} avg, Risk: {pred_data['risk_level']})")

    # Step 5: Matching engine finds verified recipient
    res = session.post(f"{BASE_URL}/api/matching/{pred_id}")
    assert res.status_code == 200, f"Step 5 failed: {res.text}"
    match_data = res.json()
    assert match_data["total_matches"] >= 1
    top_match = match_data["matches"][0]
    assert top_match["recipient"]["verification_status"] == "VERIFIED"
    print(f"[Step 5] Matching Engine Found Verified Recipient: {top_match['recipient']['organization_name']} (Score: {top_match['match_score']}, Dist: {top_match['distance_km']} km)")

    # Step 6: Recipient requests food
    rescue_req = {
        "provider_id": prov_data["id"],
        "quantity": 100,
        "prediction_id": pred_id,
        "recipient_id": recip_data["id"],
    }
    res = session.post(f"{BASE_URL}/api/rescues/request", json=rescue_req, headers=recipient_headers)
    assert res.status_code in [200, 201], f"Step 6 failed: {res.text}"
    rescue_data = res.json()
    rescue_id = rescue_data["id"]
    pickup_otp = rescue_data["pickup_otp"]
    delivery_otp = rescue_data["delivery_otp"]
    assert rescue_data["status"] == "RECIPIENT_REQUESTED"
    print(f"[Step 6] Recipient Requested Food: Rescue Code={rescue_data['rescue_code']}, Pickup OTP={pickup_otp}, Delivery OTP={delivery_otp}")

    # Step 7: Provider approves
    res = session.post(f"{BASE_URL}/api/rescues/{rescue_id}/approve", headers=provider_headers)
    assert res.status_code == 200, f"Step 7 failed: {res.text}"
    assert res.json()["status"] == "PROVIDER_APPROVED"
    print(f"[Step 7] Provider Approved Rescue: Status={res.json()['status']}")

    # Step 8: Provider verifies food
    food_payload = {
        "safety_status": "SAFE_VERIFIED",
        "temperature_c": 68.5,
        "notes": "Hygienically maintained above 65C in insulated thermoware.",
    }
    res = session.post(f"{BASE_URL}/api/rescues/{rescue_id}/verify-food", json=food_payload, headers=provider_headers)
    assert res.status_code == 200, f"Step 8 failed: {res.text}"
    assert res.json()["status"] == "FOOD_VERIFIED"
    print(f"[Step 8] Provider Verified Food: Status={res.json()['status']}, Safety={res.json()['food_safety_status']}")

    # Step 9: Pickup is verified
    res = session.post(f"{BASE_URL}/api/rescues/{rescue_id}/pickup/verify", json={"pickup_otp": pickup_otp}, headers=provider_headers)
    assert res.status_code == 200, f"Step 9 failed: {res.text}"
    pickup_res = res.json()
    print(f"[Step 9] Pickup OTP Verified")

    # Step 10: Rescue becomes IN_TRANSIT
    assert pickup_res["status"] == "IN_TRANSIT", f"Expected IN_TRANSIT, got {pickup_res['status']}"
    assert pickup_res["pickup_time"] is not None
    print(f"[Step 10] Rescue Status Transition: {pickup_res['status']} at {pickup_res['pickup_time']}")

    # Step 11: Recipient confirms delivery
    res = session.post(f"{BASE_URL}/api/rescues/{rescue_id}/delivery/verify", json={"delivery_otp": delivery_otp}, headers=recipient_headers)
    assert res.status_code == 200, f"Step 11 failed: {res.text}"
    deliv_res = res.json()
    print(f"[Step 11] Recipient Confirmed Delivery with Delivery OTP")

    # Step 12: Rescue becomes DELIVERED
    assert deliv_res["status"] == "DELIVERED", f"Expected DELIVERED, got {deliv_res['status']}"
    assert deliv_res["delivery_time"] is not None
    print(f"[Step 12] Rescue Status Transition: {deliv_res['status']} at {deliv_res['delivery_time']}")

    # Step 13: Impact record is created
    res = session.get(f"{BASE_URL}/api/dashboard/impact")
    assert res.status_code == 200, f"Step 13 failed: {res.text}"
    impact_data = res.json()
    assert impact_data["total_meals_rescued"] >= 100
    print(f"[Step 13] Impact Record Created: Total Rescues={impact_data['total_rescues']}, Total Meals={impact_data['total_meals_rescued']}, Total Food={impact_data['total_food_kg_rescued']} kg, Value=Rs. {impact_data['total_estimated_value']}")

    # Step 14: Prediction feedback is recorded
    fb_payload = {
        "predicted_quantity": surplus_avg,
        "actual_quantity": 100.0,
    }
    res = session.post(f"{BASE_URL}/api/predictions/{pred_id}/feedback", json=fb_payload)
    assert res.status_code in [200, 201], f"Step 14 failed: {res.text}"
    fb_data = res.json()
    assert fb_data["prediction_id"] == pred_id
    assert "absolute_error" in fb_data
    assert "percentage_error" in fb_data
    print(f"[Step 14] AI Prediction Feedback Recorded: Abs Error={fb_data['absolute_error']}, % Error={fb_data['percentage_error']}%")

    print("\n--- TESTING AUTHORIZATION GUARDS ON LIVE SERVER ---")

    # Guard 1: Recipient cannot create provider prediction
    res = session.post(f"{BASE_URL}/api/predictions", json=pred_payload, headers=recipient_headers)
    assert res.status_code == 403, f"Guard 1 failed: expected 403, got {res.status_code}"
    print("[Guard 1 Verified] Recipient cannot create provider prediction -> HTTP 403 Forbidden")

    # Guard 2: Provider cannot impersonate recipient
    res = session.post(f"{BASE_URL}/api/rescues/request", json=rescue_req, headers=provider_headers)
    assert res.status_code == 403, f"Guard 2 failed: expected 403, got {res.status_code}"
    print("[Guard 2 Verified] Provider cannot request food / impersonate recipient -> HTTP 403 Forbidden")

    # Guard 3: Unverified recipient cannot request food
    # Ensure unverified recipient user exists in DB
    from app.core.database import SessionLocal
    from app.models.user import User, UserRole, VerificationStatus
    db = SessionLocal()
    try:
        unverified_user = db.query(User).filter(User.email == "unverified@live.demo").first()
        if not unverified_user:
            unverified_user = User(
                firebase_uid="firebase-unverified-live",
                email="unverified@live.demo",
                organization_name="Unverified Live Demo Shelter",
                organization_type="SHELTER",
                role=UserRole.RECIPIENT.value,
                verification_status=VerificationStatus.PENDING.value,
            )
            db.add(unverified_user)
            db.commit()
            db.refresh(unverified_user)
    finally:
        db.close()

    unverified_headers = {
        "Authorization": "Bearer test-firebase-unverified-live:unverified@live.demo"
    }
    res = session.post(f"{BASE_URL}/api/rescues/request", json=rescue_req, headers=unverified_headers)
    assert res.status_code == 403, f"Guard 3 failed: expected 403, got {res.status_code}: {res.text}"
    print("[Guard 3 Verified] Unverified recipient cannot request food -> HTTP 403 Forbidden")

    # Guard 4: Users cannot access another organization's private rescue
    res = session.get(f"{BASE_URL}/api/rescues/{rescue_id}", headers=third_party_headers)
    assert res.status_code == 403, f"Guard 4 failed: expected 403, got {res.status_code}"
    print("[Guard 4 Verified] Users cannot access another organization's private rescue -> HTTP 403 Forbidden")

    print("\n" + "=" * 65)
    print("  ALL 14 WORKFLOW STEPS AND 4 AUTHORIZATION GUARDS VERIFIED LIVE!")
    print("=" * 65)

if __name__ == "__main__":
    try:
        run_live_acceptance()
    except Exception as e:
        print(f"\n[FAILED] Live acceptance error: {e}")
        sys.exit(1)
