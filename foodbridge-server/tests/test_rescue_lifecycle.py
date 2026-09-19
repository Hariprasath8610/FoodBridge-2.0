import unittest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


class TestRescueMissionLifecycle(unittest.TestCase):
    def setUp(self):
        # Seeded test users:
        # Provider ID: 1 (GreenLeaf Hotel, firebase_uid: firebase-sender-hotel-1)
        # Recipient ID: 5 (Sunrise Community Shelter, firebase_uid: firebase-recipient-shelter-1)
        # Another Provider ID: 2 (Sunrise Wedding Hall, firebase_uid: firebase-sender-wedding-1)
        self.provider_id = 1
        self.recipient_id = 5
        self.unauthorized_provider_id = 2

        self.provider_headers = {
            "Authorization": "Bearer test-firebase-sender-hotel-1:hotel@greenleaf.demo"
        }
        self.recipient_headers = {
            "Authorization": "Bearer test-firebase-recipient-shelter-1:help@sunriseshelter.demo"
        }
        self.other_provider_headers = {
            "Authorization": "Bearer test-firebase-sender-wedding-1:events@sunrisewedding.demo"
        }

    def test_complete_rescue_lifecycle(self):
        """Test full successful lifecycle: REQUEST -> APPROVE -> VERIFY_FOOD -> PICKUP -> DELIVER."""
        # 1. Step 1: Recipient requests food opportunity
        req_payload = {
            "provider_id": self.provider_id,
            "quantity": 80,
            "prediction_id": "pred_017500598a14",
        }
        res_req = client.post(
            "/api/rescues/request", json=req_payload, headers=self.recipient_headers
        )
        self.assertEqual(res_req.status_code, 201, res_req.text)
        rescue = res_req.json()
        rescue_id = rescue["id"]

        self.assertIn("RESCUE-", rescue["rescue_code"])
        self.assertEqual(rescue["status"], "RECIPIENT_REQUESTED")
        self.assertEqual(rescue["food_safety_status"], "PENDING_VERIFICATION")
        self.assertEqual(len(rescue["pickup_otp"]), 6)
        self.assertEqual(len(rescue["delivery_otp"]), 6)
        pickup_otp = rescue["pickup_otp"]
        delivery_otp = rescue["delivery_otp"]

        # 2. Step 2: Provider approves rescue
        res_approve = client.post(
            f"/api/rescues/{rescue_id}/approve", headers=self.provider_headers
        )
        self.assertEqual(res_approve.status_code, 200)
        self.assertEqual(res_approve.json()["status"], "PROVIDER_APPROVED")

        # 3. Step 3: Provider verifies food safety
        food_payload = {
            "safety_status": "SAFE_VERIFIED",
            "temperature_c": 67.5,
            "notes": "Hygienically insulated in hot boxes.",
        }
        res_food = client.post(
            f"/api/rescues/{rescue_id}/verify-food",
            json=food_payload,
            headers=self.provider_headers,
        )
        self.assertEqual(res_food.status_code, 200)
        self.assertEqual(res_food.json()["status"], "FOOD_VERIFIED")
        self.assertEqual(res_food.json()["food_safety_status"], "SAFE_VERIFIED")

        # 4. Step 4: Pickup verification with OTP
        # Test wrong OTP first
        res_bad_pickup = client.post(
            f"/api/rescues/{rescue_id}/pickup/verify",
            json={"pickup_otp": "000000"},
            headers=self.provider_headers,
        )
        self.assertEqual(res_bad_pickup.status_code, 400)
        self.assertIn("Invalid pickup verification OTP code", res_bad_pickup.text)

        # Test correct OTP
        res_pickup = client.post(
            f"/api/rescues/{rescue_id}/pickup/verify",
            json={"pickup_otp": pickup_otp},
            headers=self.provider_headers,
        )
        self.assertEqual(res_pickup.status_code, 200)
        self.assertIn(res_pickup.json()["status"], ["IN_TRANSIT", "PICKED_UP"])
        self.assertIsNotNone(res_pickup.json()["pickup_time"])

        # 5. Step 5: Delivery verification with OTP
        # Test wrong OTP first
        res_bad_deliv = client.post(
            f"/api/rescues/{rescue_id}/delivery/verify",
            json={"delivery_otp": "000000"},
            headers=self.recipient_headers,
        )
        self.assertEqual(res_bad_deliv.status_code, 400)
        self.assertIn("Invalid delivery verification OTP code", res_bad_deliv.text)

        # Test correct delivery OTP
        res_deliv = client.post(
            f"/api/rescues/{rescue_id}/delivery/verify",
            json={"delivery_otp": delivery_otp},
            headers=self.recipient_headers,
        )
        self.assertEqual(res_deliv.status_code, 200)
        self.assertEqual(res_deliv.json()["status"], "DELIVERED")
        self.assertIsNotNone(res_deliv.json()["delivery_time"])

        # 6. Cannot deliver twice
        res_twice = client.post(
            f"/api/rescues/{rescue_id}/delivery/verify",
            json={"delivery_otp": delivery_otp},
            headers=self.recipient_headers,
        )
        self.assertEqual(res_twice.status_code, 400)
        self.assertIn("Cannot deliver twice", res_twice.text)

    def test_state_transition_violations(self):
        """Test illegal state transitions are blocked."""
        # Create fresh rescue
        req_payload = {"provider_id": self.provider_id, "quantity": 50}
        res_req = client.post(
            "/api/rescues/request", json=req_payload, headers=self.recipient_headers
        )
        rescue = res_req.json()
        rescue_id = rescue["id"]
        pickup_otp = rescue["pickup_otp"]
        delivery_otp = rescue["delivery_otp"]

        # 1. Cannot mark PICKED_UP before FOOD_VERIFIED
        res_early_pickup = client.post(
            f"/api/rescues/{rescue_id}/pickup/verify",
            json={"pickup_otp": pickup_otp},
            headers=self.provider_headers,
        )
        self.assertEqual(res_early_pickup.status_code, 400)
        self.assertIn("Cannot mark PICKED_UP before FOOD_VERIFIED", res_early_pickup.text)

        # 2. Cannot mark DELIVERED before PICKED_UP
        res_early_deliv = client.post(
            f"/api/rescues/{rescue_id}/delivery/verify",
            json={"delivery_otp": delivery_otp},
            headers=self.recipient_headers,
        )
        self.assertEqual(res_early_deliv.status_code, 400)
        self.assertIn("Cannot mark DELIVERED before PICKED_UP", res_early_deliv.text)

    def test_cross_organization_authorization(self):
        """Do not allow a user from another organization to modify a rescue mission."""
        req_payload = {"provider_id": self.provider_id, "quantity": 40}
        res_req = client.post(
            "/api/rescues/request", json=req_payload, headers=self.recipient_headers
        )
        rescue_id = res_req.json()["id"]

        # Different provider tries to approve rescue
        res_unauth = client.post(
            f"/api/rescues/{rescue_id}/approve", headers=self.other_provider_headers
        )
        self.assertEqual(res_unauth.status_code, 403)
        self.assertIn("You cannot modify another organization's rescue mission", res_unauth.text)

    def test_get_rescues_and_detail(self):
        """Test GET /api/rescues and GET /api/rescues/{id}."""
        # Create one rescue
        req_payload = {"provider_id": self.provider_id, "quantity": 60}
        res_req = client.post(
            "/api/rescues/request", json=req_payload, headers=self.recipient_headers
        )
        rescue_id = res_req.json()["id"]

        # List rescues
        res_list = client.get("/api/rescues")
        self.assertEqual(res_list.status_code, 200)
        self.assertGreaterEqual(len(res_list.json()), 1)

        # Detail rescue
        res_detail = client.get(f"/api/rescues/{rescue_id}")
        self.assertEqual(res_detail.status_code, 200)
        self.assertEqual(res_detail.json()["id"], rescue_id)

    def test_qr_rescue_verification(self):
        """Test QR verification with safe identifier and OTP fallback."""
        import json

        # 1. Recipient creates request
        req_res = client.post(
            "/api/rescues/request",
            json={"provider_id": self.provider_id, "quantity": 75},
            headers=self.recipient_headers,
        )
        self.assertEqual(req_res.status_code, 201)
        rescue = req_res.json()
        rescue_id = rescue["id"]
        rescue_code = rescue["rescue_code"]
        pickup_otp = rescue["pickup_otp"]

        # 2. Provider approves & certifies food
        client.post(f"/api/rescues/{rescue_id}/approve", headers=self.provider_headers)
        client.post(
            f"/api/rescues/{rescue_id}/verify-food",
            json={"safety_status": "SAFE_VERIFIED"},
            headers=self.provider_headers,
        )

        # 3. Safe QR payload: contains ONLY the rescue identifier (no OTP, no sensitive data)
        safe_qr_payload = json.dumps({"rescue_code": rescue_code, "action": "pickup"})
        self.assertNotIn(pickup_otp, safe_qr_payload)

        # 4. Unauthorized participant tries to scan and verify -> 403 Forbidden
        res_unauth = client.post(
            "/api/rescues/verify-qr",
            json={"qr_data": safe_qr_payload},
            headers=self.other_provider_headers,
        )
        self.assertEqual(res_unauth.status_code, 403)

        # 5. Authorized recipient scans safe QR -> backend verifies and transitions to IN_TRANSIT
        res_qr_pickup = client.post(
            "/api/rescues/verify-qr",
            json={"qr_data": safe_qr_payload},
            headers=self.recipient_headers,
        )
        self.assertEqual(res_qr_pickup.status_code, 200)
        self.assertEqual(res_qr_pickup.json()["status"], "IN_TRANSIT")
        self.assertIsNotNone(res_qr_pickup.json()["pickup_time"])

        # 6. Delivery verification via direct delivery QR verification
        delivery_qr_payload = json.dumps({"rescue_code": rescue_code, "action": "delivery"})
        res_qr_delivery = client.post(
            f"/api/rescues/{rescue_id}/delivery/verify",
            json={"rescue_code": rescue_code},
            headers=self.recipient_headers,
        )
        self.assertEqual(res_qr_delivery.status_code, 200)
        self.assertEqual(res_qr_delivery.json()["status"], "DELIVERED")
        self.assertIsNotNone(res_qr_delivery.json()["delivery_time"])


if __name__ == "__main__":
    unittest.main()
