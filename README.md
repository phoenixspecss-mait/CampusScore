# CampusScore

CampusScore is a modern platform designed to calculate credit scores using alternative data points. It is particularly tailored for individuals who might not have a traditional credit history—such as students and gig workers—by evaluating bank statements, savings cadence, and "trust circle" vouches. 

The project is split into a **Flutter Frontend** for a seamless user experience and a **FastAPI Python Backend** that handles PDF parsing and Machine Learning-based credit scoring.

## 🚀 Features

- **Alternative Credit Scoring**: Moves beyond traditional FICO scores by evaluating user-uploaded bank statements.
- **Automated PDF Parsing**: Extracts key financial indicators like total income, total debits, savings cadence, and fee punctuality directly from PDF bank statements.
- **Machine Learning Engine**: Uses a pre-trained ML model to predict the probability of default and calculates a final credit score (scaled out of 900).
- **Explainable AI (XAI)**: Integrates SHAP (SHapley Additive exPlanations) to provide feature impact insights, explaining *why* a user received a specific score.
- **Mobile-First Frontend**: Built with Flutter, featuring Firebase integration for authentication/database and Google Maps for location-based functionalities.

## 🏗️ Tech Stack

### Frontend (`/Frontend`)
- **Framework**: Flutter (Dart)
- **Backend-as-a-Service**: Firebase (Auth, Realtime Database)
- **Key Packages**:
  - `google_maps_flutter` & `geolocator`: For mapping and location features.
  - `file_picker`: For uploading bank statements.
  - `provider`: For state management.
  - `http`: For making API calls to the FastAPI backend.

### Backend (`/CsScore-backend`)
- **Framework**: FastAPI (Python)
- **Data Processing**: `pandas`, `pdfplumber` (for parsing bank statements)
- **Machine Learning**: `scikit-learn`, `xgboost`, `joblib`
- **Explainability**: `shap`

## 📂 Project Structure

```text
CampusScore/
├── CsScore-backend/        # FastAPI server and ML models
│   ├── main.py             # API endpoints (/score, /upload_statement)
│   ├── requirements.txt    # Python dependencies
│   ├── *.pkl               # Pre-trained ML model, feature names, and SHAP explainer
│   └── generate_statement.py # Utility script (likely for demo/synthetic data)
│
└── Frontend/               # Flutter application
    ├── lib/                # Dart source code
    ├── pubspec.yaml        # Flutter dependencies
    ├── android/            # Android-specific files
    └── ios/                # iOS-specific files
```

## ⚙️ Getting Started

### Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd CsScore-backend
   ```
2. Create and activate a virtual environment (recommended):
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Run the FastAPI server:
   ```bash
   uvicorn main:app --reload
   ```
   The API will be available at `http://127.0.0.1:8000`. You can view the interactive Swagger documentation at `http://127.0.0.1:8000/docs`.

### Frontend Setup

1. Navigate to the frontend directory:
   ```bash
   cd Frontend
   ```
2. Get Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application (ensure you have an emulator running or a device connected):
   ```bash
   flutter run
   ```
   *Note: You may need to configure Firebase for your specific environment by providing the appropriate `google-services.json` (Android) or `GoogleService-Info.plist` (iOS).*

## 🧠 How the Scoring Works

1. **Upload**: The user uploads a bank statement (PDF) via the Flutter app.
2. **Parsing**: The backend's `/upload_statement` endpoint uses `pdfplumber` to extract transaction history (credits and debits) and dates.
3. **Feature Engineering**: It calculates derived metrics like:
   - `AMT_INCOME_TOTAL`: Total detected income.
   - `savings_cadence`: Ratio of (Income - Expenses) / Income.
   - `DAYS_EMPLOYED`: Estimated from the span of dates found.
   - `fee_punctuality`: Boosted if regular payments (rent, subscriptions) are detected.
4. **Prediction**: The engineered features, along with a user-provided `trust_circle_vouch`, are fed into the loaded `credit_model.pkl`.
5. **Result**: The API returns the credit score, probability of default, and the exact SHAP impacts showing which factors helped or hurt the score.
