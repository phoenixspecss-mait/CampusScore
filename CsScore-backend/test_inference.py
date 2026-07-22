import joblib
import pandas as pd
import json

# 1. Load the artifacts you just generated
model = joblib.load('credit_model.pkl')
explainer = joblib.load('shap_explainer.pkl')
feature_names = joblib.load('feature_names.pkl')

def get_score_and_explanation(user_data_dict):
    # Force the dictionary into a 1-row DataFrame with exact column order
    df_input = pd.DataFrame([user_data_dict])[feature_names]
    
    # Predict Probability of default
    prob_default = model.predict_proba(df_input)[0][1]
    
    # Translate probability into a consumer-friendly score (300 to 900)
    credit_score = int(900 - (prob_default * 600)) 
    
    # Get SHAP values for the "Why"
    shap_values = explainer.shap_values(df_input)
    
    # Zip feature names with their exact impact
    impacts = {feat: round(float(val), 4) for feat, val in zip(feature_names, shap_values[0])}
    
    return {
        "final_score": credit_score,
        "probability_of_default": round(float(prob_default), 4),
        "shap_impacts": impacts
    }

# --- THE SANDBOX ---

print("\n--- TEST 1: 'BAD' FINANCIAL HABITS ---")
bad_profile = {
    'AMT_INCOME_TOTAL': 30000,
    'DAYS_EMPLOYED': -100, 
    'savings_cadence': 0.1,      # Low savings
    'trust_circle_vouch': 0.1,   # Low trust score
    'fee_punctuality': 0.2       # Missed payments
}
bad_result = get_score_and_explanation(bad_profile)
print(json.dumps(bad_result, indent=2))


print("\n--- TEST 2: 'GOOD' FINANCIAL HABITS (Simulating the Slider) ---")
# Watch how changing the synthetic features drastically improves the score
good_profile = {
    'AMT_INCOME_TOTAL': 30000,   # Income stays the SAME
    'DAYS_EMPLOYED': -100,       # Job history stays the SAME
    'savings_cadence': 0.9,      # Improved savings!
    'trust_circle_vouch': 0.8,   # High trust score!
    'fee_punctuality': 0.9       # Perfect payments!
}
good_result = get_score_and_explanation(good_profile)
print(json.dumps(good_result, indent=2))