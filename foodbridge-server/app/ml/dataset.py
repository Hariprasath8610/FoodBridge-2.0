import numpy as np
import pandas as pd
from typing import Tuple


def generate_surplus_dataset(n_samples: int = 3500, random_state: int = 42) -> pd.DataFrame:
    """Generate domain-realistic synthetic training dataset for FoodBridge surplus prediction.

    Captures realistic interactions between:
    - Event types (wedding, corporate, hostel_canteen, buffet_hotel, restaurant, college_fest)
    - Weather conditions (clear, mild_rain, heavy_rain, extreme_heat, storm)
    - Days of week (monday through sunday)
    - Attendance patterns and historical buffers
    """
    np.random.seed(random_state)

    event_types = [
        "wedding",
        "corporate",
        "hostel_canteen",
        "buffet_hotel",
        "restaurant",
        "college_fest",
    ]
    menu_categories = [
        "vegetarian",
        "non_vegetarian",
        "mixed",
        "south_indian",
        "north_indian",
        "continental",
    ]
    weather_conditions = [
        "clear",
        "mild_rain",
        "heavy_rain",
        "extreme_heat",
        "storm",
    ]
    days_of_week = [
        "monday",
        "tuesday",
        "wednesday",
        "thursday",
        "friday",
        "saturday",
        "sunday",
    ]

    records = []
    for _ in range(n_samples):
        event = np.random.choice(event_types)
        menu = np.random.choice(menu_categories)
        weather = np.random.choice(weather_conditions, p=[0.55, 0.20, 0.15, 0.06, 0.04])
        day = np.random.choice(days_of_week)

        # Expected people distribution by event type
        if event == "wedding":
            expected = int(np.random.normal(550, 180))
            expected = max(150, min(1600, expected))
            prep_buffer = np.random.uniform(1.05, 1.20)  # Weddings over-cater significantly
            hist_attendance_mean = 0.90
        elif event == "corporate":
            expected = int(np.random.normal(200, 70))
            expected = max(40, min(800, expected))
            prep_buffer = np.random.uniform(0.98, 1.08)
            hist_attendance_mean = 0.88
        elif event == "hostel_canteen":
            expected = int(np.random.normal(450, 100))
            expected = max(100, min(1000, expected))
            prep_buffer = np.random.uniform(0.95, 1.05)
            hist_attendance_mean = 0.94
        elif event == "buffet_hotel":
            expected = int(np.random.normal(280, 80))
            expected = max(50, min(700, expected))
            prep_buffer = np.random.uniform(1.05, 1.15)
            hist_attendance_mean = 0.89
        elif event == "college_fest":
            expected = int(np.random.normal(700, 200))
            expected = max(200, min(2000, expected))
            prep_buffer = np.random.uniform(1.02, 1.18)
            hist_attendance_mean = 0.85
        else:  # restaurant
            expected = int(np.random.normal(160, 45))
            expected = max(30, min(450, expected))
            prep_buffer = np.random.uniform(1.02, 1.12)
            hist_attendance_mean = 0.91

        # Planned quantity based on buffer
        planned = int(round(expected * prep_buffer))

        # Historical attendance rate with slight variance
        hist_att_rate = float(
            np.clip(np.random.normal(hist_attendance_mean, 0.04), 0.70, 0.99)
        )
        hist_surplus_rate = float(
            np.clip(np.random.normal(0.09, 0.03), 0.02, 0.25)
        )

        # Weather impact on actual turnout
        weather_turnout_drop = 0.0
        if weather == "mild_rain":
            weather_turnout_drop = np.random.uniform(0.04, 0.09)
        elif weather == "heavy_rain":
            weather_turnout_drop = np.random.uniform(0.12, 0.22)
        elif weather == "storm":
            weather_turnout_drop = np.random.uniform(0.20, 0.35)
        elif weather == "extreme_heat":
            weather_turnout_drop = np.random.uniform(0.03, 0.08)

        # Day of week factor (weekends have better attendance for weddings, worse for corporate)
        day_factor = 0.0
        if day in ["saturday", "sunday"]:
            if event in ["wedding", "college_fest"]:
                day_factor = 0.03
            elif event in ["corporate", "hostel_canteen"]:
                day_factor = -0.06
        elif day == "friday" and event == "corporate":
            day_factor = -0.04

        # Current / actual attendance
        actual_att_rate = np.clip(
            hist_att_rate - weather_turnout_drop + day_factor + np.random.normal(0, 0.02),
            0.50,
            1.02,
        )
        current_attendance = int(round(expected * actual_att_rate))

        # Actual consumption:
        # Meals consumed per person ~ 0.95 to 1.0 (some people skip or eat very lightly)
        consumption_per_person = np.random.uniform(0.92, 1.0)
        actual_consumption = round(current_attendance * consumption_per_person, 1)

        # Target surplus quantity (cannot be negative)
        surplus_quantity = round(max(0.0, planned - actual_consumption), 1)

        records.append(
            {
                "expected_people": expected,
                "planned_quantity": planned,
                "historical_attendance_rate": round(hist_att_rate, 3),
                "current_attendance": current_attendance,
                "event_type": event,
                "menu_category": menu,
                "weather_risk": weather,
                "day_of_week": day,
                "historical_surplus_rate": round(hist_surplus_rate, 3),
                "surplus_quantity": surplus_quantity,
            }
        )

    df = pd.DataFrame(records)
    return df


if __name__ == "__main__":
    df = generate_surplus_dataset()
    print("Dataset generated successfully!")
    print(f"Shape: {df.shape}")
    print(df.head())
