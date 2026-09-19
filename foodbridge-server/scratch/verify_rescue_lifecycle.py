import httpx
import json

client = httpx.Client(base_url="http://127.0.0.1:8000")

provider_headers = {
    "Authorization": "Bearer test-firebase-sender-hotel-1:hotel@grandregency.demo"
}
recipient_headers = {
    "Authorization": "Bearer test-firebase-recipient-shelter-1:help@hopeshelter.demo"
}
other_provider_headers = {
    "Authorization": "Bearer test-firebase-sender-rest-1:restaurant@greenleaf.demo"
}

print("=== 1. Health Check ===")
r_health = client.get("/health")
print("Status:", r_health.status_code, r_health.json()["status"])

print("\n=== 2. Recipient Requests Food Opportunity ===")
req_payload = {
    "provider_id": 1,
    "quantity": 85,
    "prediction_id": "pred_017500598a14",
}
r_req = client.post(
    "/api/rescues/request", json=req_payload, headers=recipient_headers
)
print("Status:", r_req.status_code)
rescue = r_req.json()
rescue_id = rescue["id"]
print(f"Created Mission Code: {rescue['rescue_code']} (ID: {rescue_id})")
print(f"Status: {rescue['status']}")
print(f"Pickup OTP: {rescue['pickup_otp']} | Delivery OTP: {rescue['delivery_otp']}")

print("\n=== 3. Unauthorized Cross-Organization Attempt (Should be 403) ===")
r_unauth = client.post(
    f"/api/rescues/{rescue_id}/approve", headers=other_provider_headers
)
print("Status:", r_unauth.status_code, "(Expected 403)")
print("Response:", r_unauth.json()["error"]["message"] if "error" in r_unauth.json() else r_unauth.json())

print("\n=== 4. Provider Approves Rescue Mission ===")
r_approve = client.post(
    f"/api/rescues/{rescue_id}/approve", headers=provider_headers
)
print("Status:", r_approve.status_code)
print("New Status:", r_approve.json()["status"])

print("\n=== 5. Provider Verifies Food Safety ===")
food_payload = {
    "safety_status": "SAFE_VERIFIED",
    "temperature_c": 68.0,
    "notes": "Hygienically vacuum sealed in thermal packaging.",
}
r_food = client.post(
    f"/api/rescues/{rescue_id}/verify-food",
    json=food_payload,
    headers=provider_headers,
)
print("Status:", r_food.status_code)
print("New Status:", r_food.json()["status"])
print("Food Safety Status:", r_food.json()["food_safety_status"])

print("\n=== 6. Verify Pickup Handover with OTP ===")
r_pickup = client.post(
    f"/api/rescues/{rescue_id}/pickup/verify",
    json={"pickup_otp": rescue["pickup_otp"]},
    headers=provider_headers,
)
print("Status:", r_pickup.status_code)
print("New Status:", r_pickup.json()["status"])
print("Pickup Timestamp:", r_pickup.json()["pickup_time"])

print("\n=== 7. Verify Delivery Receipt with OTP ===")
r_deliv = client.post(
    f"/api/rescues/{rescue_id}/delivery/verify",
    json={"delivery_otp": rescue["delivery_otp"]},
    headers=recipient_headers,
)
print("Status:", r_deliv.status_code)
print("Final Status:", r_deliv.json()["status"])
print("Delivery Timestamp:", r_deliv.json()["delivery_time"])

print("\n=== 8. Attempt Duplicate Delivery (Should be 400) ===")
r_twice = client.post(
    f"/api/rescues/{rescue_id}/delivery/verify",
    json={"delivery_otp": rescue["delivery_otp"]},
    headers=recipient_headers,
)
print("Status:", r_twice.status_code, "(Expected 400)")
print("Response:", r_twice.json()["error"]["message"] if "error" in r_twice.json() else r_twice.json())

print("\n=== 9. Retrieve Mission Details (GET /api/rescues/{id}) ===")
r_detail = client.get(f"/api/rescues/{rescue_id}", headers=recipient_headers)
print("Status:", r_detail.status_code)
print(json.dumps(r_detail.json(), indent=2))
