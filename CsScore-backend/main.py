from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import pandas as pd

# 1. Load the ML artifacts exactly once when the server starts
model = joblib.load('credit_model.pkl')
explainer = joblib.load('shap_explainer.pkl')
feature_names = joblib.load('feature_names.pkl')

app = FastAPI(title="Credit Scoring Engine API")

# 2. Define the expected incoming JSON structure from the frontend
class UserProfile(BaseModel):
    AMT_INCOME_TOTAL: float
    DAYS_EMPLOYED: float
    savings_cadence: float
    trust_circle_vouch: float
    fee_punctuality: float

# 3. Create the endpoint that the frontend will call
@app.post("/score")
def calculate_score(profile: UserProfile):
    # Convert incoming JSON to a dictionary, then to a DataFrame
    user_data_dict = profile.dict()
    df_input = pd.DataFrame([user_data_dict])[feature_names]
    
    # ML Predictions
    prob_default = model.predict_proba(df_input)[0][1]
    credit_score = int(900 - (prob_default * 600)) 
    shap_values = explainer.shap_values(df_input)
    
    # Zip feature names with their exact impact
    impacts = {feat: round(float(val), 4) for feat, val in zip(feature_names, shap_values[0])}
    
    return {
        "final_score": credit_score,
        "probability_of_default": round(float(prob_default), 4),
        "shap_impacts": impacts
    }