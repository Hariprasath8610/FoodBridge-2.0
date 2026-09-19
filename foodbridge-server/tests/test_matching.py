import unittest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


class TestIntelligentMatchingSystem(unittest.TestCase):
    def test_get_recipients(self):
        """Verify GET /api/recipients returns seeded verified recipients."""
        response = client.get("/api/recipients")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertGreaterEqual(len(data), 3)

        names = [r["organization_name"] for r in data]
        self.assertIn("Hope Community Kitchen", names)
        self.assertIn("Sunrise Community Shelter", names)
        self.assertIn("CareBridge Community Center", names)

        for r in data:
            self.assertEqual(r["verification_status"], "VERIFIED")

    def test_get_recipient_by_id(self):
        """Verify GET /api/recipients/{id} returns correct detail."""
        res_list = client.get("/api/recipients")
        first_id = res_list.json()[0]["id"]

        response = client.get(f"/api/recipients/{first_id}")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["id"], first_id)
        self.assertIn("organization_name", data)
        self.assertIn("current_demand", data)

    def test_update_recipient_demand(self):
        """Verify POST /api/recipients/demand updates active demand."""
        res_list = client.get("/api/recipients")
        recipient = res_list.json()[0]
        recipient_id = recipient["id"]
        new_demand = 175

        response = client.post(
            "/api/recipients/demand",
            json={"recipient_id": recipient_id, "current_demand": new_demand},
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["current_demand"], new_demand)

        # Verify persisted via GET
        check = client.get(f"/api/recipients/{recipient_id}")
        self.assertEqual(check.json()["current_demand"], new_demand)

    def test_matching_for_prediction(self):
        """Test POST /api/matching/{prediction_id} produces ranked, multi-criteria matches."""
        # 1. Create a fresh prediction
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
        res_pred = client.post("/api/predictions", json=pred_payload)
        self.assertEqual(res_pred.status_code, 200)
        pred_data = res_pred.json()
        prediction_id = pred_data["prediction_id"]

        # 2. Invoke matching engine
        res_match = client.post(f"/api/matching/{prediction_id}")
        self.assertEqual(res_match.status_code, 200, res_match.text)
        match_data = res_match.json()

        print("\n=== Matching API Response ===")
        print("Prediction ID:", match_data["prediction_id"])
        print("Surplus Avg:", match_data["predicted_surplus_avg"])
        print("Total Matches:", match_data["total_matches"])

        self.assertEqual(match_data["prediction_id"], prediction_id)
        self.assertEqual(match_data["event_type"], "wedding")
        self.assertEqual(match_data["menu_category"], "vegetarian")
        self.assertGreater(len(match_data["matches"]), 0)

        # 3. Validate each ranked match item
        previous_score = 100.0
        for idx, m in enumerate(match_data["matches"]):
            print(
                f"Rank #{idx+1}: {m['recipient']['organization_name']} | "
                f"Score: {m['match_score']} | Dist: {m['distance_km']} km | "
                f"Demand: {m['current_demand']} | Urgency: {m['urgency']}"
            )
            self.assertIn("recipient", m)
            self.assertIn("match_score", m)
            self.assertIn("distance_km", m)
            self.assertIn("current_demand", m)
            self.assertIn("compatible_quantity", m)
            self.assertIn("urgency", m)
            self.assertIn("reason", m)

            # Verification: only VERIFIED recipients
            self.assertEqual(m["recipient"]["verification_status"], "VERIFIED")

            # Check descending rank order
            self.assertLessEqual(m["match_score"], previous_score)
            previous_score = m["match_score"]

            # Haversine distance should be a realistic positive number
            self.assertGreater(m["distance_km"], 0.0)

    def test_matching_nonexistent_prediction_returns_404(self):
        """Verify 404 is returned if prediction_id does not exist."""
        response = client.post("/api/matching/non_existent_pred_id")
        self.assertEqual(response.status_code, 404)


if __name__ == "__main__":
    unittest.main()
