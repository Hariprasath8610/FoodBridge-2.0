import unittest
from fastapi.testclient import TestClient
from app.main import app
from app.core.database import SessionLocal
from app.models.prediction import Prediction

client = TestClient(app)


class TestSurplusPredictionEngine(unittest.TestCase):
    def test_wedding_heavy_rain_prediction(self):
        """Test with exact requested scenario: 500 people, wedding, heavy rain."""
        payload = {
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

        response = client.post("/api/predictions", json=payload)
        self.assertEqual(response.status_code, 200, response.text)

        data = response.json()
        print("\nTest Wedding Heavy Rain Response:", data)

        # 1. Required response fields
        self.assertIn("prediction_id", data)
        self.assertIn("predicted_consumption", data)
        self.assertIn("predicted_surplus_min", data)
        self.assertIn("predicted_surplus_max", data)
        self.assertIn("surplus_percentage", data)
        self.assertIn("risk_level", data)
        self.assertIn("explanation", data)
        self.assertIn("factors", data)

        # 2. Risk classification
        self.assertIn(data["risk_level"], ["LOW", "MEDIUM", "HIGH", "CRITICAL"])

        # 3. Realistic bounds and not a fake hardcoded 75 meals
        self.assertGreater(data["predicted_surplus_max"], data["predicted_surplus_min"])
        self.assertGreater(data["predicted_surplus_min"], 20.0)
        self.assertLess(data["predicted_surplus_max"], 250.0)
        self.assertGreater(data["predicted_consumption"], 250.0)

        # 4. Explainable factors
        factors = data["factors"]
        self.assertGreaterEqual(len(factors), 2)
        factor_names = [f["factor"] for f in factors]
        self.assertIn("weather", factor_names)
        for f in factors:
            self.assertIn("factor", f)
            self.assertIn("effect", f)
            self.assertIn("description", f)

        # 5. Verify database persistence
        db = SessionLocal()
        try:
            record = (
                db.query(Prediction)
                .filter(Prediction.prediction_id == data["prediction_id"])
                .first()
            )
            self.assertIsNotNone(record)
            self.assertEqual(record.expected_people, 500)
            self.assertEqual(record.event_type, "wedding")
        finally:
            db.close()

    def test_contrasting_corporate_clear_weather_prediction(self):
        """Test model produces dynamic, contrasting predictions for different scenarios."""
        corporate_payload = {
            "expected_people": 200,
            "planned_quantity": 200,
            "historical_attendance_rate": 0.95,
            "current_attendance": 195,
            "event_type": "corporate",
            "menu_category": "continental",
            "weather_condition": "clear",
            "day_of_week": "tuesday",
            "historical_surplus_rate": 0.04,
        }

        response = client.post("/api/predictions", json=corporate_payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()

        # Corporate with high attendance & clear weather should yield lower surplus & lower risk
        self.assertIn(data["risk_level"], ["LOW", "MEDIUM"])
        self.assertLess(data["surplus_percentage"], 15.0)


if __name__ == "__main__":
    unittest.main()
