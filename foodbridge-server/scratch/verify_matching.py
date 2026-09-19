import httpx
import json

client = httpx.Client(base_url="http://127.0.0.1:8000")

# 1. Health
r_health = client.get("/health")
print("=== 1. Health Check ===")
print("STATUS:", r_health.status_code)
print(json.dumps(r_health.json(), indent=2))

# 2. GET /api/recipients
r_recipients = client.get("/api/recipients")
print("\n=== 2. GET /api/recipients ===")
print("STATUS:", r_recipients.status_code)
recipients = r_recipients.json()
print(f"Total Recipients: {len(recipients)}")
for r in recipients:
    print(
        f" - ID {r['id']}: {r['organization_name']} ({r['organization_type']}) | "
        f"Demand: {r['current_demand']} | Status: {r['verification_status']}"
    )

# 3. GET /api/recipients/{id}
first_id = recipients[0]["id"]
r_rec1 = client.get(f"/api/recipients/{first_id}")
print(f"\n=== 3. GET /api/recipients/{first_id} ===")
print("STATUS:", r_rec1.status_code)
print(json.dumps(r_rec1.json(), indent=2))

# 4. POST /api/recipients/demand
r_demand = client.post(
    "/api/recipients/demand",
    json={"recipient_id": first_id, "current_demand": 140},
)
print("\n=== 4. POST /api/recipients/demand ===")
print("STATUS:", r_demand.status_code)
print("Updated Demand:", r_demand.json()["current_demand"])

# 5. Create Prediction (Wedding, Heavy Rain, 500 people)
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
r_pred = client.post("/api/predictions", json=pred_payload)
pred_data = r_pred.json()
prediction_id = pred_data["prediction_id"]
print("\n=== 5. Created Prediction ===")
print("Prediction ID:", prediction_id)
print(
    f"Surplus Range: {pred_data['predicted_surplus_min']} - {pred_data['predicted_surplus_max']} meals"
)

# 6. POST /api/matching/{prediction_id}
r_match = client.post(f"/api/matching/{prediction_id}")
print(f"\n=== 6. POST /api/matching/{prediction_id} ===")
print("STATUS:", r_match.status_code)
match_data = r_match.json()
print("Surplus Range:", match_data["predicted_surplus_range"])
print("Average Surplus:", match_data["predicted_surplus_avg"])
print("Total Ranked Matches:", match_data["total_matches"])

for idx, m in enumerate(match_data["matches"]):
    print(f"\n[Rank #{idx+1}] {m['recipient']['organization_name']}")
    print(f"  Match Score: {m['match_score']}")
    print(f"  Distance: {m['distance_km']} km")
    print(
        f"  Demand: {m['current_demand']} meals | Compatible: {m['compatible_quantity']} meals"
    )
    print(f"  Urgency: {m['urgency']}")
    print(f"  Reason: {m['reason']}")
