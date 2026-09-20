"""FoodBridge 2.0 — Synthetic Training Dataset Generator

NOTICE:
This is a synthetic/demo dataset. Production deployment should retrain the model using verified historical FoodBridge data.

Generates realistic historical data across:
- Restaurants, buffet hotels, weddings, college events/fests, hostels/canteen, and large gatherings.
- Multi-factor variations: attendance, planned quantity/meals, weather risk, day of week, historical attendance & surplus rates.
"""

from typing import Tuple
import numpy as np
import pandas as pd


def generate_surplus_dataset(n_samples: int = 4000, random_state: int = 42) -> pd.DataFrame:
    """Generate domain-realistic synthetic training dataset for FoodBridge surplus prediction.

    Captures realistic non-trivial interactions between:
    - Event types (wedding, corporate, hostel_canteen, buffet_hotel, restaurant, college_fest, large_gathering)
    - Weather conditions (clear, mild_rain, heavy_rain, extreme_heat, storm)
    - Days of week (monday through sunday)
    - Attendance variations and preparation buffer dynamics
    """
    np.random.seed(random_state)

    event_types = [
        "wedding",
        "corporate",
        "hostel_canteen",
        "buffet_hotel",
        "restaurant",
        "college_fest",
        "large_gathering",
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
        weather = np.random.choice(weather_conditions, p=[0.52, 0.22, 0.16, 0.06, 0.04])
        day = np.random.choice(days_of_week)

        # Expected people distribution and typical preparation buffer by event type
        if event == "wedding":
            expected = int(np.random.normal(520, 160))
            expected = max(150, min(1800, expected))
            prep_buffer = np.random.uniform(1.05, 1.20)  # Celebrations over-cater significantly
            hist_attendance_mean = 0.91
        elif event == "corporate":
            expected = int(np.random.normal(200, 65))
            expected = max(40, min(800, expected))
            prep_buffer = np.random.uniform(0.98, 1.08)
            hist_attendance_mean = 0.88
        elif event == "hostel_canteen":
            expected = int(np.random.normal(450, 90))
            expected = max(100, min(1000, expected))
            prep_buffer = np.random.uniform(0.95, 1.04)
            hist_attendance_mean = 0.94
        elif event == "buffet_hotel":
            expected = int(np.random.normal(280, 75))
            expected = max(50, min(700, expected))
            prep_buffer = np.random.uniform(1.04, 1.14)
            hist_attendance_mean = 0.89
        elif event == "college_fest":
            expected = int(np.random.normal(750, 220))
            expected = max(200, min(2200, expected))
            prep_buffer = np.random.uniform(1.02, 1.16)
            hist_attendance_mean = 0.85
        elif event == "large_gathering":
            expected = int(np.random.normal(900, 300))
            expected = max(300, min(3000, expected))
            prep_buffer = np.random.uniform(1.05, 1.18)
            hist_attendance_mean = 0.87
        else:  # restaurant
            expected = int(np.random.normal(160, 45))
            expected = max(30, min(450, expected))
            prep_buffer = np.random.uniform(1.02, 1.12)
            hist_attendance_mean = 0.91

        # Planned meals calculated from expected people and buffer
        planned = int(round(expected * prep_buffer))

        # Historical baseline rates
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

        # Day of week factor
        day_factor = 0.0
        if day in ["saturday", "sunday"]:
            if event in ["wedding", "college_fest", "large_gathering"]:
                day_factor = 0.02
            elif event in ["corporate", "hostel_canteen"]:
                day_factor = -0.06
        elif day == "friday" and event == "corporate":
            day_factor = -0.03

        # Current / actual attendance influenced by weather & history
        actual_att_rate = np.clip(
            hist_att_rate - weather_turnout_drop + day_factor + np.random.normal(0, 0.02),
            0.50,
            1.02,
        )
        current_attendance = int(round(expected * actual_att_rate))

        # Actual consumption per person (varies slightly based on menu and time)
        consumption_per_person = np.random.uniform(0.92, 1.0)
        actual_consumption = round(current_attendance * consumption_per_person, 1)

        # Target surplus quantity (cannot be negative)
        surplus_quantity = round(max(0.0, planned - actual_consumption), 1)

        records.append(
            {
                "expected_people": expected,
                "planned_meals": planned,
                "planned_quantity": planned,
                "historical_attendance_rate": round(hist_att_rate, 3),
                "current_attendance": current_attendance,
                "event_type": event,
                "menu_category": menu,
                "weather_condition": weather,
                "weather_risk": weather,
                "day_of_week": day,
                "historical_surplus_rate": round(hist_surplus_rate, 3),
                "expected_consumption": actual_consumption,
                "surplus_quantity": surplus_quantity,
            }
        )

    df = pd.DataFrame(records)
    return df


if __name__ == "__main__":
    df = generate_surplus_dataset()
    print("Synthetic dataset generated successfully!")
    print(f"Shape: {df.shape}")
    print(df.head())
