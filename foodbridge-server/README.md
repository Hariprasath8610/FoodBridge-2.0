# FoodBridge Backend

> **AI-Powered Surplus Food Prediction & Rescue Platform**  
> Built for the 18-hour AI / Social Impact Hackathon.

FoodBridge prevents food waste by predicting potential surplus before events and services conclude, and automatically connecting verified food providers (hotels, restaurants, colleges, hostels, weddings, caterers) with verified recipients (NGOs, shelters, community kitchens, old-age homes).

---

## Tech Stack

- **Framework**: FastAPI (Python 3.12 / 3.14)
- **Database**: SQLite with SQLAlchemy 2.0 ORM
- **Validation**: Pydantic v2
- **Machine Learning**: Scikit-Learn (Random Forest Regressor, Pipeline, OneHotEncoder, StandardScaler) + Pandas & NumPy
- **Authentication**: Firebase Admin SDK (with seamless local development mock mode)
- **ASGI Server**: Uvicorn

---

## Directory Structure

```
foodbridge-server/
├── app/
│   ├── main.py                     # Application entrypoint, lifespan, CORS, and root health check
│   ├── core/
│   │   ├── config.py               # Pydantic Settings (.env configuration)
│   │   ├── database.py             # SQLAlchemy engine & session factory
│   │   ├── security.py             # Auth dependencies & token handling
│   │   └── exceptions.py           # Custom exceptions & global HTTP handlers
│   ├── models/
│   │   ├── user.py                 # Users & Organization profiles (Providers & Recipients)
│   │   ├── food_listing.py         # Food surplus donation listings
│   │   ├── claim.py                # Food reservations & OTP handoff tracking
│   │   └── prediction.py           # Historical ML surplus prediction records
│   ├── schemas/
│   │   ├── common.py               # API responses & health check schemas
│   │   ├── user.py                 # User & Organization DTOs
│   │   ├── food_listing.py         # Listing DTOs & filter parameters
│   │   ├── claim.py                # Claim creation & OTP verification DTOs
│   │   └── prediction.py           # AI surplus prediction request/response schemas
│   ├── services/
│   │   ├── user_service.py         # User management logic
│   │   ├── listing_service.py      # Listing lifecycle & expiry handling
│   │   ├── claim_service.py        # Claim workflow & 6-digit OTP verification
│   │   └── firebase_service.py     # Firebase Admin SDK with development fallback
│   ├── ml/
│   │   ├── predictor.py            # Real-time ML inference & actionable recommendations
│   │   ├── train.py                # Training pipeline for surplus prediction model
│   │   └── surplus_model.joblib    # Serialized Scikit-Learn pipeline
│   ├── seed/
│   │   └── seed_data.py            # Seeder for demo providers, recipients, and listings
│   └── api/
│       └── v1/
│           ├── router.py           # Master router
│           └── endpoints/
│               ├── health.py       # Health check endpoint
│               ├── auth.py         # Authentication & organization directory
│               ├── listings.py     # Food surplus listings CRUD & filters
│               ├── claims.py       # Reservations & OTP handoff verification
│               ├── predictions.py  # Pre-event AI surplus forecast
│               └── analytics.py    # Social impact metrics (meals & kg saved, CO2 avoided)
├── requirements.txt
├── .env.example
├── .gitignore
└── README.md
```

---

## Getting Started

### 1. Create Virtual Environment & Install Dependencies

Using `uv` (recommended) or standard `python -m venv`:

```bash
# Create virtual environment
uv venv .venv --python 3.12

# Activate virtual environment
# On Windows (PowerShell):
.venv\Scripts\Activate.ps1
# On Linux/macOS:
source .venv/bin/activate

# Install dependencies
uv pip install -r requirements.txt
```

### 2. Configure Environment

Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

*(Optional: Place `firebase-credentials.json` in the root folder if you have a Firebase project service account; otherwise, the backend operates in development mock mode automatically).*

### 3. Train the AI Model & Seed Demo Data

```bash
# Train the Scikit-learn surplus prediction model
python -m app.ml.train

# Seed deterministic demo data (Providers, Verified Recipients, Wedding Demo Scenario)
python -m app.seed.seed_data

# Verify all database records, matching engine, and impact stats
python -m tests.verify_seed_database
```

#### Demo Fictional Organizations
- **Providers**: `GreenLeaf Hotel`, `Sunrise Wedding Hall`, `ABC College Hostel`
- **Recipients (All VERIFIED)**: `Hope Community Kitchen`, `Sunrise Community Shelter`, `CareBridge Community Center`

#### Demo Scenario: Wedding Under Heavy Rain
- Event: Wedding at Sunrise Wedding Hall
- 500 Expected Guests | 500 Planned Meals | 92% Historical Attendance | 430 Current Turnout | Heavy Rain | Saturday
- Pre-seeded as `pred_demo_wedding_scenario_01` (ML Forecast: 387.9 consumption, 69.0 - 167.7 meals surplus range, HIGH risk).
- Ready for instant matching via `POST /api/matching/pred_demo_wedding_scenario_01` and rescue requests!


### 4. Run the Server

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

---

## Interactive Documentation

- **Swagger UI**: [http://localhost:8000/docs](http://localhost:8000/docs)
- **ReDoc**: [http://localhost:8000/redoc](http://localhost:8000/redoc)
- **Health Check**: [http://localhost:8000/health](http://localhost:8000/health)

---

## Firebase Authentication Integration

FoodBridge uses **Firebase Authentication** on the client side (Flutter mobile and Web) and validates tokens on the backend using the **Firebase Admin SDK**.

### Setup Instructions

1. **Obtain Firebase Service Account Key**:
   - Go to the [Firebase Console](https://console.firebase.google.com/).
   - Navigate to **Project Settings** > **Service Accounts**.
   - Click **Generate New Private Key** and save the JSON file as `firebase-credentials.json` in the `foodbridge-server/` directory (or place it in a secure directory).

2. **Configure Environment Variables (`.env`)**:
   ```env
   # Path to service account JSON (recommended for local development)
   FIREBASE_CREDENTIALS_PATH="firebase-credentials.json"

   # Or specify the Project ID
   FIREBASE_PROJECT_ID="your-firebase-project-id"
   ```

3. **Development / Mock Testing Mode**:
   - If no Firebase credentials are configured, the backend automatically runs in safe **Development / Mock Mode**.
   - You can test endpoints by passing test tokens in the header:
     ```http
     Authorization: Bearer test-<firebase_uid>:<email>
     ```

---

## Authentication & Role Security

### 1. Verification Flow
1. Client logs in with Firebase (Google, Email/Password, or Phone Auth) and obtains an ID token.
2. Client sends token in the request header:
   ```http
   Authorization: Bearer <Firebase ID token>
   ```
3. Backend verifies token using `firebase_admin.auth.verify_id_token()`.
4. Backend extracts `uid` and `email`.
5. Backend performs an authoritative database lookup by `firebase_uid`.

### 2. Authoritative Database Roles
> [!IMPORTANT]
> **Zero Client Trust**: FoodBridge never trusts roles or claims passed in the client token or headers. The backend database record (`users.role`) is the sole authority determining whether an organization is a `sender` or `recipient`.

### 3. Role Authorization Dependencies
- `get_current_user()`: Resolves authenticated user profile from DB.
- `require_sender()`: Ensures the user has `role == "sender"`.
- `require_recipient()`: Ensures the user has `role == "recipient"`.

---

## Key API Endpoints

| Method | Endpoint | Auth Required | Description |
|---|---|---|---|
| `GET` | `/health` | No | Server, DB, Firebase, and ML predictor health status |
| `GET` | `/api/me` | Bearer Token | Current user profile & authoritative role |
| `POST` | `/api/predictions` | No | Real ML surplus forecast with empirical ranges & explainable factors |
| `POST` | `/api/matching/{prediction_id}` | No | Multi-criteria ranked recipient matching engine |
| `GET` | `/api/recipients` | No | List registered welfare organizations & shelters |
| `GET` | `/api/recipients/{id}` | No | Detail profile for a specific recipient |
| `POST` | `/api/recipients/demand` | No | Update live hunger demand for a recipient facility |
| `POST` | `/api/rescues/request` | Bearer (`recipient`) | Recipient requests food rescue opportunity |
| `POST` | `/api/rescues/{id}/approve` | Bearer (`sender`) | Provider approves rescue mission |
| `POST` | `/api/rescues/{id}/verify-food` | Bearer (`sender`) | Provider verifies food quality & temperature |
| `POST` | `/api/rescues/{id}/pickup/verify` | Bearer (`sender`) | Provider verifies pickup handover with 6-digit OTP |
| `POST` | `/api/rescues/{id}/delivery/verify` | Bearer (`recipient`) | Recipient confirms delivery receipt with 6-digit OTP |
| `GET` | `/api/rescues` | Optional Bearer | List rescue missions scoped to user organization |
| `GET` | `/api/rescues/{id}` | Optional Bearer | Retrieve mission lifecycle details by ID |
| `POST` | `/api/v1/auth/register` | No | Register new Food Provider or Recipient profile |
| `GET` | `/api/v1/auth/sender-only` | Bearer (`sender`) | Test endpoint guarded by `require_sender()` |
| `GET` | `/api/v1/auth/recipient-only` | Bearer (`recipient`) | Test endpoint guarded by `require_recipient()` |
| `GET` | `/api/v1/listings` | No | Search & filter active food surplus donations |
| `POST` | `/api/v1/listings` | Bearer (`sender`) | Publish new food surplus donation |
| `POST` | `/api/v1/claims` | Bearer (`recipient`) | Reserve food surplus (generates 6-digit OTP) |
| `POST` | `/api/v1/claims/{id}/verify-otp` | Bearer (`sender`) | Verify OTP during physical handoff |
| `GET` | `/api/v1/analytics/impact` | No | Total meals saved, kg diverted, CO2 avoided |
| `GET` | `/api/dashboard/impact` | No | FoodBridge social impact metrics & demo assumptions |
| `POST` | `/api/predictions/{id}/feedback` | No | AI feedback loop: actual vs predicted surplus error |

---

## Food Rescue Mission Lifecycle & Chain of Custody

FoodBridge governs physical food handoffs through a cryptographically verified state machine with strict chain-of-custody rules.

### Mission State Progression
```
CREATED / RECIPIENT_REQUESTED
          │
          ▼
   PROVIDER_APPROVED
          │
          ▼
    FOOD_VERIFIED
          │
          ▼
     PICKED_UP (Requires recipient's 6-digit pickup_otp)
          │
          ▼
     DELIVERED (Requires transporter's 6-digit delivery_otp)
```

### State Machine Constraints
- **Food Safety Gate**: Cannot mark `PICKED_UP` before `FOOD_VERIFIED`.
- **Chronological Handover**: Cannot mark `DELIVERED` before `PICKED_UP`.
- **No Duplicate Completion**: Cannot deliver twice.
- **Cancellation Lock**: Cannot approve or modify a `CANCELLED` mission.
- **Cross-Organization Isolation**: Users cannot modify another organization's rescue mission.

---

## Intelligent Recipient Matching Engine

FoodBridge matches predicted surplus food to verified recipients before food goes to waste.

### Multi-Criteria Scoring Factors
1. **Distance (Haversine)**: Calculates actual great-circle distance in kilometers between donor and recipient. Proximity preserves food temperature and freshness.
2. **Recipient Demand**: Prioritizes facilities with immediate, active hunger demand.
3. **Quantity Compatibility**: Evaluates intake capacity against predicted surplus volume.
4. **Urgency**: Balances food spoilage risk (`CRITICAL`/`HIGH`) with recipient urgency.
5. **Food Compatibility**: Validates dietary rules (e.g., vegetarian, halal, mixed rations).
6. **Strict Verification**: Only `VERIFIED` organizations are eligible for matching.
7. **Availability Window**: Ensures the recipient is actively open and ready for receipt.

---

## Machine Learning Surplus Prediction Engine

FoodBridge features a real, lightweight Scikit-Learn **RandomForestRegressor** pipeline (R² = 0.965, MAE = 11.4 meals) trained on domain-realistic synthetic data.

### Architecture

```
app/ml/
├── dataset.py            # Generates synthetic training dataset modeling event & weather turnouts
├── model.py              # ColumnTransformer (StandardScaler + OneHotEncoder) + RandomForestRegressor
├── train.py              # CLI training script and model evaluator
├── predictor.py          # Uncertainty estimation & explainable factor generator
└── surplus_model.joblib  # Serialized model artifact
```

### Features Used in Training & Inference
- `expected_people`: Expected guest headcount
- `planned_quantity`: Planned meals/portions prepared
- `historical_attendance_rate`: Historical venue attendance fraction (0.0 - 1.0)
- `current_attendance`: Headcount recorded so far
- `event_type`: wedding, corporate, hostel_canteen, buffet_hotel, restaurant, college_fest
- `menu_category`: vegetarian, non_vegetarian, mixed, continental, south_indian, north_indian
- `weather_condition`: clear, mild_rain, heavy_rain, extreme_heat, storm
- `day_of_week`: monday, tuesday, wednesday, thursday, friday, saturday, sunday
- `historical_surplus_rate`: Baseline venue waste fraction (0.0 - 1.0)

### Empirical Prediction Intervals & Explainable Factors
- **Empirical Prediction Ranges**: Instead of fake certainty or a hardcoded single number, the model computes prediction intervals (`predicted_surplus_min` and `predicted_surplus_max`) directly from tree predictions across the 120-tree random forest ensemble (10th and 90th percentiles).
- **Risk Levels**: `LOW` (< 8%), `MEDIUM` (8-15%), `HIGH` (15-25%), `CRITICAL` (>= 25%).
- **Explainable Factors**: Transparent breakdown of what is driving surplus risk (e.g. weather conditions, attendance gaps, event preparation buffers).
