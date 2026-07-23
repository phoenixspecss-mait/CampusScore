"""
CampusScore - FastAPI microservice (v2 - matches current train_model.py features)
------------------------------------------------------------------------------------
Feature set now matches prepare_data.py / train_model.py exactly:
  AMT_INCOME_TOTAL, NAME_EDUCATION_TYPE, AGE_YEARS,
  fee_payment_punctuality, subscription_regularity, savings_consistency,
  gig_income_stability, trust_circle_vouch_score,
  AMT_CREDIT, on_time_repayment_rate, is_returning_applicant

Run with:
    uvicorn main:app --reload

Test locally at:
    http://localhost:8000/docs

Requires:
    pip install fastapi uvicorn pydantic joblib shap pandas numpy pdfplumber
"""

from fastapi import FastAPI, File, UploadFile, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import joblib
import shap
import numpy as np
import pandas as pd
import pdfplumber
import io
import re
import os

app = FastAPI(title="CampusScore API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

MODEL_PATH = "campusscore_model.pkl"
ENCODERS_PATH = "campusscore_encoders.pkl"
FEATURES_PATH = "campusscore_features.pkl"

model = None
encoders = None
feature_names = None
explainer = None

if os.path.exists(MODEL_PATH):
    model = joblib.load(MODEL_PATH)
    encoders = joblib.load(ENCODERS_PATH)
    feature_names = joblib.load(FEATURES_PATH)
    explainer = shap.TreeExplainer(model)
    print("Loaded trained model. Features expected:", feature_names)
else:
    print("WARNING: no trained model found yet -- endpoints will return dummy data.")


FEATURE_MESSAGES = {
    "fee_payment_punctuality": {
        "negative": "Late fee/rent payments are lowering your score. Paying on time going forward would help.",
        "positive": "Consistent fee/rent payments are helping your score.",
    },
    "gig_income_stability": {
        "negative": "Irregular income from part-time/gig work is reducing your score.",
        "positive": "Stable part-time/gig income is helping your score.",
    },
    "savings_consistency": {
        "negative": "Low or inconsistent savings is lowering your score. Even small regular savings help.",
        "positive": "Regular saving habits are helping your score.",
    },
    "subscription_regularity": {
        "negative": "Irregular subscription/bill payments are reducing your score.",
        "positive": "Regular bill payments are helping your score.",
    },
    "trust_circle_vouch_score": {
        "negative": "Low vouching from your trust circle is reducing your score.",
        "positive": "Strong vouching from your trust circle is helping your score.",
    },
    "on_time_repayment_rate": {
        "negative": "Past late repayments are lowering your score.",
        "positive": "A strong on-time repayment history is helping your score.",
    },
    "AMT_INCOME_TOTAL": {
        "negative": "Lower relative income is reducing your score.",
        "positive": "Higher relative income is helping your score.",
    },
    "AMT_CREDIT": {
        "negative": "Your existing loan amount is adding some risk.",
        "positive": "Your existing loan amount is not adding much risk.",
    },
    "AGE_YEARS": {
        "negative": "Age is a minor factor lowering your score.",
        "positive": "Age is a minor factor helping your score.",
    },
    "is_returning_applicant": {
        "negative": "Being a first-time applicant means less history to score you on.",
        "positive": "Your history as a returning applicant is helping your score.",
    },
}


def explain_factors(top_factors, is_returning_applicant=0):
    explanations = []
    for f in top_factors:
        direction = "negative" if f["impact"] < 0 else "positive"
        # Special case: repayment rate is only meaningful for returning
        # applicants -- a first-timer's low value means "no history yet",
        # not "paid late", so don't accuse them of something that never happened.
        if f["feature"] == "on_time_repayment_rate" and not is_returning_applicant:
            explanations.append(
                "You don't have a repayment history yet. Building one, even with a small first loan, can improve future scores."
            )
            continue
        msg = FEATURE_MESSAGES.get(f["feature"], {}).get(direction)
        if msg:
            explanations.append(msg)
    return explanations


# ---------- Request schema (matches current trained feature set) ----------
class StudentProfile(BaseModel):
    AMT_INCOME_TOTAL: float = Field(..., example=15000, description="Estimated monthly income (0-50000 range)")
    NAME_EDUCATION_TYPE: str = Field(..., example="Secondary / secondary special")
    AGE_YEARS: float = Field(..., example=20)
    fee_payment_punctuality: float = Field(..., example=70)
    subscription_regularity: float = Field(..., example=65)
    savings_consistency: float = Field(..., example=60)
    gig_income_stability: float = Field(..., example=55)
    trust_circle_vouch_score: float = Field(..., example=60)
    AMT_CREDIT: float = Field(0, example=0, description="0 if first-time applicant, else prior loan amount")
    on_time_repayment_rate: float = Field(0, example=0, description="0 if first-time applicant")
    is_returning_applicant: int = Field(0, example=0, description="0 = first-time, 1 = returning")


def profile_to_row(data: dict) -> pd.DataFrame:
    row = {}
    for col in feature_names:
        val = data[col]
        if col in encoders:
            le = encoders[col]
            val = le.transform([str(val)])[0] if str(val) in le.classes_ else 0
        row[col] = val
    return pd.DataFrame([row])[feature_names]


def score_and_explain(data: dict):
    row = profile_to_row(data)
    prob_default = float(model.predict_proba(row)[0][1])

    score = int(850 - prob_default * 550)
    tier = "Low Risk" if prob_default < 0.2 else "Medium Risk" if prob_default < 0.5 else "High Risk"

    shap_vals = explainer.shap_values(row)[0]
    # NOTE: raw SHAP values here represent contribution to predicted
    # PROBABILITY OF DEFAULT -- so a negative raw value actually means
    # "reduced risk" (good for the student), and positive means "increased
    # risk" (bad). We negate so that positive = good/raises score and
    # negative = bad/lowers score, matching how FEATURE_MESSAGES is written
    # and how a normal person would read "+"/"-".
    shap_vals = [-v for v in shap_vals]
    contributions = sorted(
        zip(feature_names, shap_vals), key=lambda x: abs(x[1]), reverse=True
    )
    top_factors = [
        {"feature": f, "impact": round(float(v), 3)} for f, v in contributions[:5]
    ]

    return {
        "score": score,
        "risk_tier": tier,
        "probability_of_default": round(prob_default, 3),
        "top_factors": top_factors,
        "explanations": explain_factors(top_factors, data.get("is_returning_applicant", 0)),
    }


@app.post("/score")
def get_score(profile: StudentProfile):
    if model is None:
        return {"score": 620, "risk_tier": "Medium Risk", "top_factors": [], "explanations": []}
    return score_and_explain(profile.dict())


@app.post("/simulate")
def simulate(profile: StudentProfile):
    if model is None:
        return {"score": 650, "risk_tier": "Medium Risk", "top_factors": [], "explanations": []}
    return score_and_explain(profile.dict())


@app.get("/benchmark")
def benchmark(score: int):
    percentile = min(99, max(1, int((score - 300) / (850 - 300) * 100)))
    return {"percentile": percentile, "message": f"You're better than {percentile}% of students in our sample."}


@app.post("/upload_statement")
async def upload_statement(file: UploadFile = File(...), trust_circle_vouch_score: float = Form(50.0)):
    """
    NOTE: regex-based extraction only works as well as the PDF's formatting.
    NOTE: the real model output is always returned as-is, no artificial boosting.
    """
    if model is None:
        return {"error": "Model not loaded yet."}

    content = await file.read()

    total_income = 0.0
    total_debits = 0.0
    dates_found = set()
    fee_punctuality = 50.0

    with pdfplumber.open(io.BytesIO(content)) as pdf:
        for page in pdf.pages:
            text = page.extract_text()
            if not text:
                continue
            for line in text.split("\n"):
                date_match = re.search(r"\d{4}-\d{2}-\d{2}", line)
                if date_match:
                    dates_found.add(date_match.group(0))
                if " CR " in line or "/CR/" in line:
                    amt_match = re.search(r"(\d+\.\d{2})", line)
                    if amt_match:
                        total_income += float(amt_match.group(1))
                if " DR " in line or "/DR/" in line:
                    amt_match = re.search(r"(\d+\.\d{2})", line)
                    if amt_match:
                        total_debits += float(amt_match.group(1))
                        if "Rent" in line or "Subscription" in line or "Fee" in line:
                            fee_punctuality = min(100.0, fee_punctuality + 5.0)

    savings_consistency = 50.0
    if total_income > 0:
        savings_ratio = max(0.0, min(1.0, (total_income - total_debits) / total_income))
        savings_consistency = savings_ratio * 100

    # Cap extracted income at the same 0-50000 scale the model was trained on
    capped_income = min(50000.0, total_income)

    extracted_profile = {
        "AMT_INCOME_TOTAL": capped_income,
        "NAME_EDUCATION_TYPE": "Secondary / secondary special",
        "AGE_YEARS": 21,
        "fee_payment_punctuality": fee_punctuality,
        "subscription_regularity": fee_punctuality,
        "savings_consistency": savings_consistency,
        "gig_income_stability": min(100.0, capped_income / 500),
        "trust_circle_vouch_score": trust_circle_vouch_score,
        "AMT_CREDIT": 0,
        "on_time_repayment_rate": 0,
        "is_returning_applicant": 0,
    }

    result = score_and_explain(extracted_profile)
    result["extracted_data"] = extracted_profile
    return result


@app.get("/")
def root():
    return {"status": "CampusScore API running", "model_loaded": model is not None}