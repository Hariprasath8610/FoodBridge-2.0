import unittest
from fastapi.testclient import TestClient
from app.main import app
from app.core.database import SessionLocal
from app.models.impact_record import ImpactRecord
from app.models.prediction_feedback import PredictionFeedback

client = TestClient(app)


class TestImpactTrackingAndFeedback(unittest.TestCase):
    def setUp(self):
        self.provider_headers = {
            "Authorization": "Bearer test-firebase-sender-hotel-1:hotel@greenleaf.demo"
        }
        self.recipient_headers = {
            "Authorization": "Bearer test-firebase-recipient-shelter-1:help@sunriseshelter.demo"
        }

    def test_rescue_delivery_creates_impact_record_and_updates_dashboard(self):
        """Test completing a rescue mission automatically creates an ImpactRecord."""
        # 1. Initiate and complete a rescue mission
        req_res = client.post(
            "/api/rescues/request",
            json={"provider_id": 1, "quantity": 100},
            headers=self.recipient_headers,
        )
        self.assertEqual(req_res.status_code, 201)
        rescue = req_res.json()
        rescue_id = rescue["id"]

        # Approve
        client.post(f"/api/rescues/{rescue_id}/approve", headers=self.provider_headers)
        # Verify food
        client.post(
            f"/api/rescues/{rescue_id}/verify-food",
            json={"safety_status": "SAFE_VERIFIED"},
            headers=self.provider_headers,
        )
        # Verify pickup
        client.post(
            f"/api/rescues/{rescue_id}/pickup/verify",
            json={"pickup_otp": rescue["pickup_otp"]},
            headers=self.provider_headers,
        )
        # Verify delivery
        deliv_res = client.post(
            f"/api/rescues/{rescue_id}/delivery/verify",
            json={"delivery_otp": rescue["delivery_otp"]},
            headers=self.recipient_headers,
        )
        self.assertEqual(deliv_res.status_code, 200)
        self.assertEqual(deliv_res.json()["status"], "DELIVERED")

        # 2. Verify ImpactRecord in database
        db = SessionLocal()
        try:
            impact = (
                db.query(ImpactRecord)
                .filter(ImpactRecord.rescue_id == rescue_id)
                .first()
            )
            self.assertIsNotNone(impact)
            self.assertEqual(impact.meals_rescued, 100)
            self.assertEqual(impact.people_served, 100)
            self.assertEqual(impact.food_quantity_kg, 45.0)
            self.assertEqual(impact.estimated_food_value, 8000.0)
            self.assertEqual(impact.waste_avoided, 45.0)
        finally:
            db.close()

        # 3. Verify GET /api/dashboard/impact reflects the completed rescue
        dash_res = client.get("/api/dashboard/impact")
        self.assertEqual(dash_res.status_code, 200)
        dash_data = dash_res.json()

        self.assertIn("total_meals_rescued", dash_data)
        self.assertIn("total_people_served", dash_data)
        self.assertIn("total_food_kg_rescued", dash_data)
        self.assertIn("total_estimated_value", dash_data)
        self.assertIn("total_rescues", dash_data)
        self.assertGreaterEqual(dash_data["total_meals_rescued"], 100)
        self.assertGreaterEqual(dash_data["total_rescues"], 1)

        # Assumptions disclaimer present
        self.assertIn("assumptions", dash_data)
        self.assertIn("disclaimer", dash_data["assumptions"])

    def test_prediction_feedback_loop(self):
        """Test POST /api/predictions/{id}/feedback calculates and stores errors."""
        pred_id = "pred_test_feedback_101"
        payload = {
            "predicted_quantity": 95.0,
            "actual_quantity": 88.0,
        }

        res = client.post(f"/api/predictions/{pred_id}/feedback", json=payload)
        self.assertEqual(res.status_code, 200, res.text)
        data = res.json()

        self.assertEqual(data["prediction_id"], pred_id)
        self.assertEqual(data["predicted_quantity"], 95.0)
        self.assertEqual(data["actual_quantity"], 88.0)
        # absolute error: |88 - 95| = 7.0
        self.assertEqual(data["absolute_error"], 7.0)
        # percentage error: (7.0 / 88.0) * 100 = 7.95
        self.assertEqual(data["percentage_error"], 7.95)
        self.assertEqual(data["feedback_status"], "STORED")

        # Verify persisted in database
        db = SessionLocal()
        try:
            record = (
                db.query(PredictionFeedback)
                .filter(PredictionFeedback.prediction_id == pred_id)
                .first()
            )
            self.assertIsNotNone(record)
            self.assertEqual(record.absolute_error, 7.0)
            self.assertEqual(record.percentage_error, 7.95)
        finally:
            db.close()


if __name__ == "__main__":
    unittest.main()
