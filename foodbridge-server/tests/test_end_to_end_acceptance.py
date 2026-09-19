import unittest
import json
import base64
from fastapi.testclient import TestClient
from app.main import app
from app.core.database import SessionLocal
from app.models.user import User, UserRole, VerificationStatus
from app.models.recipient import Recipient
from app.models.impact_record import ImpactRecord
from app.models.prediction_feedback import PredictionFeedback

client = TestClient(app)


class TestFoodBridgeAcceptanceWorkflow(unittest.TestCase):
    """
    End-to-End Acceptance Test for FoodBridge.
    
    Validates the exact 14-step AI food rescue workflow and 4 critical authorization guards:
      1. Authenticate provider.
      2. Authenticate recipient.
      3. Provider creates wedding prediction.
      4. ML predicts surplus.
      5. Matching engine finds verified recipient.
      6. Recipient requests food.
      7. Provider approves.
      8. Provider verifies food.
      9. Pickup is verified.
      10. Rescue becomes IN_TRANSIT.
      11. Recipient confirms delivery.
      12. Rescue becomes DELIVERED.
      13. Impact record is created.
      14. Prediction feedback is recorded.
      
      Authorization Guards:
      - recipient cannot create provider prediction
      - provider cannot impersonate recipient
      - unverified recipient cannot request food
      - users cannot access another organization's private rescue
    """

    def setUp(self):
        self.db = SessionLocal()
        # Seeded organizations:
        # Provider 1: GreenLeaf Hotel (sender)
        self.provider_headers = {
            "Authorization": "Bearer test-firebase-sender-hotel-1:hotel@greenleaf.demo"
        }
        # Recipient 4: Hope Community Kitchen (recipient)
        self.recipient_headers = {
            "Authorization": "Bearer test-firebase-recipient-kitchen-1:contact@hopekitchen.demo"
        }
        # Another Provider 3: ABC College Hostel (unrelated provider)
        self.third_party_headers = {
            "Authorization": "Bearer test-firebase-sender-college-1:mess@abccollege.demo"
        }

    def tearDown(self):
        self.db.close()

    def test_complete_14_step_workflow(self):
        print("\n=== STARTING 14-STEP FOODBRIDGE ACCEPTANCE WORKFLOW ===")

        # Step 1: Authenticate provider
        res_provider_auth = client.get("/api/me", headers=self.provider_headers)
        self.assertEqual(res_provider_auth.status_code, 200, "Step 1: Provider auth failed")
        provider_data = res_provider_auth.json()
        self.assertEqual(provider_data["role"], "sender")
        self.assertEqual(provider_data["verification_status"], "verified")
        self.assertEqual(provider_data["organization_name"], "GreenLeaf Hotel")
        provider_id = provider_data["id"]
        print("  [Step 1] Provider Authenticated:", provider_data["organization_name"])

        # Step 2: Authenticate recipient
        res_recipient_auth = client.get("/api/me", headers=self.recipient_headers)
        self.assertEqual(res_recipient_auth.status_code, 200, "Step 2: Recipient auth failed")
        recipient_data = res_recipient_auth.json()
        self.assertEqual(recipient_data["role"], "recipient")
        self.assertEqual(recipient_data["verification_status"], "verified")
        self.assertEqual(recipient_data["organization_name"], "Hope Community Kitchen")
        recipient_id = recipient_data["id"]
        print("  [Step 2] Recipient Authenticated:", recipient_data["organization_name"])

        # Step 3: Provider creates wedding prediction
        wedding_payload = {
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
        res_pred = client.post("/api/predictions", json=wedding_payload, headers=self.provider_headers)
        self.assertEqual(res_pred.status_code, 200, "Step 3: Prediction creation failed")
        pred_data = res_pred.json()
        prediction_id = pred_data["prediction_id"]
        print(f"  [Step 3] Provider Created Wedding Prediction: ID={prediction_id}")

        # Step 4: ML predicts surplus
        self.assertIn("predicted_consumption", pred_data)
        self.assertIn("predicted_surplus_min", pred_data)
        self.assertIn("predicted_surplus_max", pred_data)
        self.assertIn("surplus_percentage", pred_data)
        self.assertIn("risk_level", pred_data)
        self.assertIn("explanation", pred_data)
        self.assertIn("factors", pred_data)
        self.assertEqual(pred_data["risk_level"], "HIGH")
        self.assertGreater(pred_data["predicted_surplus_max"], pred_data["predicted_surplus_min"])
        surplus_avg = round((pred_data["predicted_surplus_min"] + pred_data["predicted_surplus_max"]) / 2, 1)
        print(f"  [Step 4] ML Predicted Surplus: {pred_data['predicted_surplus_min']} - {pred_data['predicted_surplus_max']} meals (~{surplus_avg} avg, Risk: {pred_data['risk_level']})")

        # Step 5: Matching engine finds verified recipient
        res_match = client.post(f"/api/matching/{prediction_id}")
        self.assertEqual(res_match.status_code, 200, "Step 5: Matching failed")
        match_data = res_match.json()
        self.assertGreaterEqual(match_data["total_matches"], 1)
        top_match = match_data["matches"][0]
        self.assertEqual(top_match["recipient"]["verification_status"], "VERIFIED")
        matched_recipient_org = top_match["recipient"]["organization_name"]
        print(f"  [Step 5] Matching Engine Found Recipient: {matched_recipient_org} (Score: {top_match['match_score']}, Distance: {top_match['distance_km']} km)")

        # Step 6: Recipient requests food
        rescue_req_payload = {
            "provider_id": provider_id,
            "quantity": 100,
            "prediction_id": prediction_id,
            "recipient_id": recipient_id,
        }
        res_rescue_req = client.post("/api/rescues/request", json=rescue_req_payload, headers=self.recipient_headers)
        self.assertEqual(res_rescue_req.status_code, 201, "Step 6: Food request failed")
        rescue_data = res_rescue_req.json()
        rescue_id = rescue_data["id"]
        pickup_otp = rescue_data["pickup_otp"]
        delivery_otp = rescue_data["delivery_otp"]
        self.assertEqual(rescue_data["status"], "RECIPIENT_REQUESTED")
        print(f"  [Step 6] Recipient Requested Food: Rescue Code={rescue_data['rescue_code']}, Pickup OTP={pickup_otp}, Delivery OTP={delivery_otp}")

        # Step 7: Provider approves
        res_approve = client.post(f"/api/rescues/{rescue_id}/approve", headers=self.provider_headers)
        self.assertEqual(res_approve.status_code, 200, "Step 7: Approval failed")
        self.assertEqual(res_approve.json()["status"], "PROVIDER_APPROVED")
        print("  [Step 7] Provider Approved Rescue")

        # Step 8: Provider verifies food
        food_verify_payload = {
            "safety_status": "SAFE_VERIFIED",
            "temperature_c": 68.0,
            "notes": "Hygienically maintained above 65C in insulated transport units.",
        }
        res_food = client.post(f"/api/rescues/{rescue_id}/verify-food", json=food_verify_payload, headers=self.provider_headers)
        self.assertEqual(res_food.status_code, 200, "Step 8: Food verification failed")
        self.assertEqual(res_food.json()["status"], "FOOD_VERIFIED")
        self.assertEqual(res_food.json()["food_safety_status"], "SAFE_VERIFIED")
        print("  [Step 8] Provider Verified Food Safety (SAFE_VERIFIED)")

        # Step 9: Pickup is verified
        pickup_payload = {"pickup_otp": pickup_otp}
        res_pickup = client.post(f"/api/rescues/{rescue_id}/pickup/verify", json=pickup_payload, headers=self.provider_headers)
        self.assertEqual(res_pickup.status_code, 200, "Step 9: Pickup verification failed")
        print("  [Step 9] Pickup OTP Verified")

        # Step 10: Rescue becomes IN_TRANSIT
        self.assertEqual(res_pickup.json()["status"], "IN_TRANSIT", "Step 10: Status must be IN_TRANSIT")
        self.assertIsNotNone(res_pickup.json()["pickup_time"])
        print("  [Step 10] Rescue Mission Status: IN_TRANSIT")

        # Step 11: Recipient confirms delivery
        delivery_payload = {"delivery_otp": delivery_otp}
        res_delivery = client.post(f"/api/rescues/{rescue_id}/delivery/verify", json=delivery_payload, headers=self.recipient_headers)
        self.assertEqual(res_delivery.status_code, 200, "Step 11: Delivery verification failed")
        print("  [Step 11] Recipient Confirmed Delivery with Delivery OTP")

        # Step 12: Rescue becomes DELIVERED
        delivered_data = res_delivery.json()
        self.assertEqual(delivered_data["status"], "DELIVERED", "Step 12: Status must be DELIVERED")
        self.assertIsNotNone(delivered_data["delivery_time"])
        print("  [Step 12] Rescue Mission Status: DELIVERED")

        # Step 13: Impact record is created
        impact_record = self.db.query(ImpactRecord).filter(ImpactRecord.rescue_id == rescue_id).first()
        self.assertIsNotNone(impact_record, "Step 13: Impact record was not created")
        self.assertEqual(impact_record.meals_rescued, 100)
        self.assertEqual(impact_record.people_served, 100)
        self.assertEqual(impact_record.food_quantity_kg, 45.0)
        self.assertEqual(impact_record.estimated_food_value, 8000.0)
        self.assertEqual(impact_record.waste_avoided, 45.0)

        # Also verify dashboard endpoint reflects this
        res_impact_dash = client.get("/api/dashboard/impact")
        self.assertEqual(res_impact_dash.status_code, 200)
        dash_data = res_impact_dash.json()
        self.assertGreaterEqual(dash_data["total_meals_rescued"], 100)
        print(f"  [Step 13] Impact Record Created: {impact_record.meals_rescued} meals, {impact_record.food_quantity_kg} kg, Rs. {impact_record.estimated_food_value}")

        # Step 14: Prediction feedback is recorded
        feedback_payload = {
            "predicted_quantity": surplus_avg,
            "actual_quantity": 100.0,
        }
        res_feedback = client.post(f"/api/predictions/{prediction_id}/feedback", json=feedback_payload)
        self.assertIn(res_feedback.status_code, [200, 201], "Step 14: Feedback recording failed")
        fb_data = res_feedback.json()
        self.assertEqual(fb_data["prediction_id"], prediction_id)
        self.assertAlmostEqual(fb_data["actual_quantity"], 100.0, places=1)
        self.assertIn("absolute_error", fb_data)
        self.assertIn("percentage_error", fb_data)
        print(f"  [Step 14] AI Feedback Recorded: Absolute Error={fb_data['absolute_error']}, % Error={fb_data['percentage_error']}%")

        print("=== 14-STEP WORKFLOW COMPLETED SUCCESSFULLY! ===\n")

    def test_authorization_guards(self):
        print("=== STARTING AUTHORIZATION GUARDS VERIFICATION ===")

        # Guard 1: Recipient cannot create provider prediction
        pred_payload = {
            "expected_people": 200,
            "planned_quantity": 200,
            "historical_attendance_rate": 0.90,
            "current_attendance": 180,
            "event_type": "buffet_hotel",
            "menu_category": "vegetarian",
            "weather_condition": "clear",
            "day_of_week": "friday",
            "historical_surplus_rate": 0.05,
        }
        res_recip_pred = client.post("/api/predictions", json=pred_payload, headers=self.recipient_headers)
        self.assertEqual(res_recip_pred.status_code, 403, "Guard 1 Failed: Recipient was allowed to create provider prediction")
        self.assertIn("Recipients cannot create provider surplus predictions", res_recip_pred.text)
        print("  [Guard 1 Verified] Recipient cannot create provider prediction (HTTP 403)")

        # Guard 2: Provider cannot impersonate recipient to request food
        req_payload = {
            "provider_id": 1,
            "quantity": 50,
            "recipient_id": 4,
        }
        res_prov_impersonate = client.post("/api/rescues/request", json=req_payload, headers=self.provider_headers)
        self.assertEqual(res_prov_impersonate.status_code, 403, "Guard 2 Failed: Provider was allowed to request rescue")
        self.assertIn("Only verified food recipients can request a food rescue", res_prov_impersonate.text)

        # Also test with forged role in client token
        fake_jwt_payload = json.dumps({
            "uid": "firebase-sender-hotel-1",
            "email": "hotel@greenleaf.demo",
            "role": "recipient",  # Spoofed claim!
        })
        b64_claim = base64.urlsafe_b64encode(fake_jwt_payload.encode()).decode().rstrip("=")
        spoofed_token = f"Bearer eyJhbGciOiJub25lIn0.{b64_claim}."
        res_spoofed = client.post("/api/rescues/request", json=req_payload, headers={"Authorization": spoofed_token})
        self.assertEqual(res_spoofed.status_code, 403, "Guard 2 Failed: Spoofed role was trusted")
        print("  [Guard 2 Verified] Provider cannot impersonate recipient (Database is authoritative, HTTP 403)")

        # Guard 3: Unverified recipient cannot request food
        # Create a temporary unverified recipient in DB
        unverified_user = self.db.query(User).filter(User.email == "unverified@demo.org").first()
        if not unverified_user:
            unverified_user = User(
                firebase_uid="firebase-unverified-recip",
                email="unverified@demo.org",
                organization_name="Unverified Shelter Org",
                organization_type="SHELTER",
                role=UserRole.RECIPIENT.value,
                verification_status=VerificationStatus.PENDING.value,
            )
            self.db.add(unverified_user)
            self.db.commit()
            self.db.refresh(unverified_user)

        unverified_headers = {
            "Authorization": "Bearer test-firebase-unverified-recip:unverified@demo.org"
        }
        res_unverified = client.post(
            "/api/rescues/request",
            json={"provider_id": 1, "quantity": 30, "recipient_id": unverified_user.id},
            headers=unverified_headers,
        )
        self.assertEqual(res_unverified.status_code, 403, "Guard 3 Failed: Unverified recipient was allowed to request food")
        self.assertIn("Unverified recipient organizations cannot request food rescues", res_unverified.text)
        print("  [Guard 3 Verified] Unverified recipient cannot request food (HTTP 403)")

        # Guard 4: Users cannot access another organization's private rescue
        # Create a rescue between Provider 1 and Recipient 4
        req_res = client.post(
            "/api/rescues/request",
            json={"provider_id": 1, "quantity": 40, "recipient_id": 4},
            headers=self.recipient_headers,
        )
        private_rescue_id = req_res.json()["id"]

        # Third-party organization (Provider 3: ABC College Hostel) tries to view details
        res_private_view = client.get(f"/api/rescues/{private_rescue_id}", headers=self.third_party_headers)
        self.assertEqual(res_private_view.status_code, 403, "Guard 4 Failed: Third party was allowed to view private rescue")
        self.assertIn("You cannot access another organization's private rescue mission", res_private_view.text)

        # Third-party tries to approve rescue
        res_private_approve = client.post(f"/api/rescues/{private_rescue_id}/approve", headers=self.third_party_headers)
        self.assertEqual(res_private_approve.status_code, 403, "Guard 4 Failed: Third party was allowed to approve private rescue")
        self.assertIn("You cannot modify another organization's rescue mission", res_private_approve.text)
        print("  [Guard 4 Verified] Users cannot access or modify another organization's private rescue (HTTP 403)")

        print("=== ALL AUTHORIZATION GUARDS VERIFIED SUCCESSFULLY! ===\n")


if __name__ == "__main__":
    unittest.main()
