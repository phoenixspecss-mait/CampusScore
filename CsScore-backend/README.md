# CampusScore Backend

This is the FastAPI backend for the CampusScore project. It serves as the "Credit Scoring Engine API," taking user data or bank statement PDFs and returning a comprehensive credit score powered by Machine Learning.

## 🚀 Features

- **Credit Scoring Engine**: Evaluates users based on alternative data metrics like savings cadence and "trust circle" vouches.
- **PDF Bank Statement Parsing**: Endpoints that accept PDF uploads, parsing them using `pdfplumber` to extract income, expenses, and derived features like `DAYS_EMPLOYED`.
- **Machine Learning Integration**: Uses a pre-trained scikit-learn / XGBoost model (`credit_model.pkl`) to calculate the probability of default.
- **Explainability (SHAP)**: Returns feature impacts using a SHAP explainer (`shap_explainer.pkl`) so frontend clients can display *why* a user got a specific score.

## 📁 Directory Structure

- `main.py`: The core FastAPI application containing the API endpoints.
- `credit_model.pkl`: The serialized pre-trained machine learning model.
- `shap_explainer.pkl`: The serialized SHAP explainer for interpreting model predictions.
- `feature_names.pkl`: The ordered list of features expected by the model.
- `generate_statement.py`: A utility script to generate synthetic PDF bank statements for testing/demoing the `/upload_statement` endpoint.
- `train_pipeline.py`: The script used to originally train the ML model and generate the `.pkl` artifacts.
- `test_inference.py`: A quick local testing script for model inference.

## ⚙️ Setup and Installation

### Requirements

- Python `3.9.6` (as specified in `.python-version`)

### Installation Steps

1. **Create a virtual environment (Recommended)**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows use: venv\Scripts\activate
   ```

2. **Install Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Run the API Server**:
   ```bash
   uvicorn main:app --reload
   ```
   The server will start at `http://127.0.0.1:8000`.

## 📡 API Endpoints

Once running, you can explore and test the endpoints via the built-in Swagger UI at:
[http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)

### `POST /score`
Accepts a JSON payload of user profile data (`AMT_INCOME_TOTAL`, `DAYS_EMPLOYED`, `savings_cadence`, `trust_circle_vouch`, `fee_punctuality`) and returns the calculated credit score, probability of default, and SHAP impacts.

### `POST /upload_statement`
Accepts a PDF `file` and a `trust_circle_vouch` value. It parses the PDF text to calculate income, expenses, and other metrics dynamically, before passing them to the ML model for a final score.
