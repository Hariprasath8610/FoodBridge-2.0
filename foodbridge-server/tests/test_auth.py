import unittest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


class TestFirebaseAuthIntegration(unittest.TestCase):
    def test_health_endpoint(self):
        """Verify GET /health is accessible."""
        response = client.get("/health")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "ok")
        self.assertEqual(data["database"], "connected")

    def test_me_without_token_returns_401(self):
        """Verify GET /api/me fails with 401 when Authorization header is absent."""
        response = client.get("/api/me")
        self.assertEqual(response.status_code, 401)
        self.assertIn("Authorization header with Bearer token is required", response.text)

    def test_me_with_invalid_token_returns_401(self):
        """Verify GET /api/me fails with 401 when token is malformed."""
        response = client.get("/api/me", headers={"Authorization": "Bearer invalid.token.value"})
        self.assertEqual(response.status_code, 401)

    def test_me_with_sender_token(self):
        """Verify GET /api/me returns exact specified schema for a sender."""
        # Uses seeded user with firebase_uid: firebase-sender-hotel-1
        headers = {"Authorization": "Bearer test-firebase-sender-hotel-1:hotel@greenleaf.demo"}
        response = client.get("/api/me", headers=headers)
        self.assertEqual(response.status_code, 200, response.text)

        data = response.json()
        # Verify exact required fields
        self.assertIn("id", data)
        self.assertEqual(data["firebase_uid"], "firebase-sender-hotel-1")
        self.assertEqual(data["email"], "hotel@greenleaf.demo")
        self.assertEqual(data["organization_name"], "GreenLeaf Hotel")
        self.assertEqual(data["organization_type"], "HOTEL")
        self.assertEqual(data["role"], "sender")
        self.assertEqual(data["verification_status"], "verified")

    def test_me_with_recipient_token(self):
        """Verify GET /api/me returns recipient role for a recipient user."""
        headers = {"Authorization": "Bearer test-firebase-recipient-shelter-1:help@sunriseshelter.demo"}
        response = client.get("/api/me", headers=headers)
        self.assertEqual(response.status_code, 200, response.text)

        data = response.json()
        self.assertEqual(data["firebase_uid"], "firebase-recipient-shelter-1")
        self.assertEqual(data["role"], "recipient")
        self.assertEqual(data["verification_status"], "verified")

    def test_require_sender_dependency(self):
        """Test require_sender() allows sender and blocks recipient."""
        sender_headers = {"Authorization": "Bearer test-firebase-sender-hotel-1"}
        recipient_headers = {"Authorization": "Bearer test-firebase-recipient-shelter-1"}

        # Sender should succeed
        res_sender = client.get("/api/v1/auth/sender-only", headers=sender_headers)
        self.assertEqual(res_sender.status_code, 200, res_sender.text)
        self.assertEqual(res_sender.json()["role"], "sender")

        # Recipient should be rejected with 403
        res_forbidden = client.get("/api/v1/auth/sender-only", headers=recipient_headers)
        self.assertEqual(res_forbidden.status_code, 403)
        self.assertIn("sender role required", res_forbidden.text)

    def test_require_recipient_dependency(self):
        """Test require_recipient() allows recipient and blocks sender."""
        sender_headers = {"Authorization": "Bearer test-firebase-sender-hotel-1"}
        recipient_headers = {"Authorization": "Bearer test-firebase-recipient-shelter-1"}

        # Recipient should succeed
        res_recipient = client.get("/api/v1/auth/recipient-only", headers=recipient_headers)
        self.assertEqual(res_recipient.status_code, 200, res_recipient.text)
        self.assertEqual(res_recipient.json()["role"], "recipient")

        # Sender should be rejected with 403
        res_forbidden = client.get("/api/v1/auth/recipient-only", headers=sender_headers)
        self.assertEqual(res_forbidden.status_code, 403)
        self.assertIn("recipient role required", res_forbidden.text)

    def test_backend_database_is_authoritative_for_role(self):
        """Verify that client cannot tamper with or spoof roles.

        Even if client claims role='admin' or 'sender' in payload,
        backend database record decides access.
        """
        # A recipient trying to pass fake role in a JWT-like payload
        import base64, json
        fake_payload = json.dumps({
            "uid": "firebase-recipient-shelter-1",
            "email": "help@sunriseshelter.demo",
            "role": "sender",  # Spoofed claim!
        })
        encoded = base64.urlsafe_b64encode(fake_payload.encode()).decode().rstrip("=")
        spoofed_jwt = f"eyJhbGciOiJub25lIn0.{encoded}."

        # Target endpoint that requires sender
        headers = {"Authorization": f"Bearer {spoofed_jwt}"}
        res = client.get("/api/v1/auth/sender-only", headers=headers)
        # MUST BE 403 because database record has role='recipient'
        self.assertEqual(res.status_code, 403)

        # Checking /api/me should reflect authoritative DB role 'recipient'
        me_res = client.get("/api/me", headers=headers)
        self.assertEqual(me_res.status_code, 200)
        self.assertEqual(me_res.json()["role"], "recipient")


if __name__ == "__main__":
    unittest.main()
