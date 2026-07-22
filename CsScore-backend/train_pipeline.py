import pandas as pd
import numpy as np
from xgboost import XGBClassifier
import shap
import joblib

# 1. LOAD OR MOCK DATA FAST
try:
    # Try to load a small chunk of Kaggle data if you have it
    df = pd.read_csv('application_train.csv', nrows=5000)
    print("Loaded Kaggle data.")
    # Keep only a couple of simple numerical columns for speed
    df = df[['AMT_INCOME_TOTAL', 'DAYS_EMPLOYED', 'TARGET']]
    df.fillna(df.median(), inplace=True)
except FileNotFoundError:
    print("CSV not found. Generating synthetic base data to unblock you...")
    df = pd.DataFrame({
        'AMT_INCOME_TOTAL': np.random.uniform(20000, 100000, 5000),
        'DAYS_EMPLOYED': np.random.uniform(-3000, -100, 5000),
        'TARGET': np.random.choice([0, 1], 5000, p=[0.8, 0.2]) # 80% good, 20% default
    })

# 2. INJECT YOUR CUSTOM FEATURES (The Differentiators)
# Good borrowers (TARGET=0) get statistically higher synthetic scores
df['savings_cadence'] = np.where(df['TARGET'] == 0, np.random.normal(0.8, 0.1, len(df)), np.random.normal(0.4, 0.2, len(df))).clip(0, 1)
df['trust_circle_vouch'] = np.where(df['TARGET'] == 0, np.random.normal(0.7, 0.2, len(df)), np.random.normal(0.3, 0.2, len(df))).clip(0, 1)
df['fee_punctuality'] = np.where(df['TARGET'] == 0, np.random.normal(0.9, 0.05, len(df)), np.random.normal(0.5, 0.3, len(df))).clip(0, 1)

features = ['AMT_INCOME_TOTAL', 'DAYS_EMPLOYED', 'savings_cadence', 'trust_circle_vouch', 'fee_punctuality']
X = df[features]
y = df['TARGET']

# 3. TRAIN THE MODEL
print("Training XGBoost model...")
model = XGBClassifier(eval_metric='logloss', max_depth=4, n_estimators=100)
model.fit(X, y)

# 4. ATTACH SHAP EXPLAINER
print("Generating SHAP Explainer...")
explainer = shap.TreeExplainer(model)

# 5. EXPORT DELIVERABLES
joblib.dump(model, 'credit_model.pkl')
joblib.dump(explainer, 'shap_explainer.pkl')
joblib.dump(features, 'feature_names.pkl')

print("DONE. Handoff credit_model.pkl, shap_explainer.pkl, and feature_names.pkl to backend.")