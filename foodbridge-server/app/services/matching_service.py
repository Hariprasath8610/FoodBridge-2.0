import math
from typing import Dict, List, Any, Optional
from sqlalchemy.orm import Session

from app.models.prediction import Prediction
from app.models.recipient import Recipient
from app.core.exceptions import NotFoundException


def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate the great circle distance between two points on the earth in kilometers."""
    R = 6371.0  # Earth radius in km
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(dlon / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return round(R * c, 2)


class MatchingService:
    DEFAULT_WEIGHTS = {
        "distance": 0.25,
        "demand": 0.20,
        "quantity_compatibility": 0.20,
        "urgency": 0.15,
        "food_compatibility": 0.10,
        "availability": 0.10,
    }

    @staticmethod
    def match_recipients_for_prediction(
        db: Session,
        prediction_id: str,
        weights: Optional[Dict[str, float]] = None,
    ) -> Dict[str, Any]:
        """Perform intelligent matching between a food surplus prediction and verified recipients."""
        active_weights = dict(MatchingService.DEFAULT_WEIGHTS)
        if weights:
            active_weights.update(weights)

        # Normalize weights so they sum to 1.0
        total_w = sum(active_weights.values())
        if total_w > 0:
            active_weights = {k: v / total_w for k, v in active_weights.items()}

        # 1. Fetch prediction record
        prediction = (
            db.query(Prediction)
            .filter(Prediction.prediction_id == prediction_id)
            .first()
        )
        if not prediction:
            raise NotFoundException("Prediction", prediction_id)

        # Average estimated surplus meals
        surplus_avg = round(
            (prediction.predicted_surplus_min + prediction.predicted_surplus_max) / 2,
            1,
        )

        # Source coordinates (from linked provider or default event location)
        src_lat = 12.9716
        src_lon = 77.5946
        if prediction.provider:
            if prediction.provider.latitude and prediction.provider.longitude:
                src_lat = prediction.provider.latitude
                src_lon = prediction.provider.longitude

        # 2. Query ONLY verified recipients
        recipients = (
            db.query(Recipient)
            .filter(Recipient.verification_status == "VERIFIED")
            .all()
        )

        matches = []
        for r in recipients:
            # 1. Distance Calculation (Haversine)
            dist_km = haversine_distance(src_lat, src_lon, r.latitude, r.longitude)
            # Distance score: 1.0 at 0 km, decays linearly to 0.0 at 25 km
            distance_score = max(0.0, min(1.0, 1.0 - (dist_km / 25.0)))

            # 2. Demand Score
            # Recipients with large unmet demand get priority
            demand_score = min(1.0, r.current_demand / max(r.maximum_capacity, 1))

            # 3. Quantity Compatibility
            # How closely the surplus fits within recipient intake and capacity
            compatible_quantity = min(r.maximum_capacity, int(round(surplus_avg)))
            if surplus_avg > 0 and r.current_demand > 0:
                coverage_ratio = min(surplus_avg, float(r.current_demand)) / max(
                    surplus_avg, float(r.current_demand)
                )
                quantity_score = max(0.2, coverage_ratio)
            else:
                quantity_score = 0.5

            # 4. Urgency
            if r.current_demand >= 120 or prediction.risk_level == "CRITICAL":
                urgency_level = "CRITICAL"
                urgency_score = 1.0
            elif r.current_demand >= 75 or prediction.risk_level == "HIGH":
                urgency_level = "HIGH"
                urgency_score = 0.85
            elif r.current_demand >= 30:
                urgency_level = "MEDIUM"
                urgency_score = 0.60
            else:
                urgency_level = "LOW"
                urgency_score = 0.35

            # 5. Food Compatibility
            # Match recipient dietary preference against predicted menu category
            pref = (r.food_preferences or "all").lower().strip()
            menu = (prediction.menu_category or "mixed").lower().strip()

            if pref in ["all", "any", "mixed"]:
                food_score = 1.0
            elif pref == menu:
                food_score = 1.0
            elif "veg" in pref and "veg" in menu:
                food_score = 1.0
            elif pref == "vegetarian" and menu == "non_vegetarian":
                food_score = 0.1  # Incompatible dietary restriction
            else:
                food_score = 0.7

            # 6. Availability Window Score
            # Broad operational window gets highest score
            availability_score = 0.95

            # Calculate Aggregate Weighted Match Score (0 to 100)
            composite_score = (
                (distance_score * active_weights["distance"])
                + (demand_score * active_weights["demand"])
                + (quantity_score * active_weights["quantity_compatibility"])
                + (urgency_score * active_weights["urgency"])
                + (food_score * active_weights["food_compatibility"])
                + (availability_score * active_weights["availability"])
            )
            match_score = round(composite_score * 100, 1)

            # Formulate Contextual Reason
            reason_parts = [f"Located {dist_km} km away"]
            if urgency_level in ["CRITICAL", "HIGH"]:
                reason_parts.append(
                    f"urgent demand for {r.current_demand} meals ({urgency_level})"
                )
            else:
                reason_parts.append(f"active demand for {r.current_demand} meals")

            if food_score >= 0.9:
                reason_parts.append(f"100% {menu} dietary compatibility")

            reason_parts.append(f"can absorb up to {compatible_quantity} portions")
            reason = "; ".join(reason_parts).capitalize() + "."

            matches.append(
                {
                    "recipient": r,
                    "match_score": match_score,
                    "distance_km": dist_km,
                    "current_demand": r.current_demand,
                    "compatible_quantity": compatible_quantity,
                    "urgency": urgency_level,
                    "reason": reason,
                }
            )

        # Sort matches descending by match_score
        matches.sort(key=lambda x: x["match_score"], reverse=True)

        return {
            "prediction_id": prediction_id,
            "event_type": prediction.event_type,
            "menu_category": prediction.menu_category,
            "predicted_surplus_range": f"{int(prediction.predicted_surplus_min)} - {int(prediction.predicted_surplus_max)} meals",
            "predicted_surplus_avg": surplus_avg,
            "total_matches": len(matches),
            "matches": matches,
        }


matching_service = MatchingService()
