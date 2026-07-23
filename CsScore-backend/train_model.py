"""
CampusScore - Model Training (v2 - student-appropriate features)
----------------------------------------------------------------------
Trains on the corrected, student-appropriate feature set. Run after
prepare_data.py has produced campusscore_training_data.csv.
"""

import pandas as pd
import numpy as np
import xgboost as xgb
import shap
import joblib
from sklearn.model_selection import train_test_split
from sklearn.metrics import roc_auc_score, classification_report
from sklearn.preprocessing import LabelEncoder

# ---------- 1. Load data ----------
df = pd.read_csv("campusscore_training_data.csv")

cat_cols = ["NAME_EDUCATION_TYPE"]
encoders = {}
for col in cat_cols:
    le = LabelEncoder()
    df[col] = le.fit_transform(df[col].astype(str))
    encoders[col] = le

X = df.drop(columns=["TARGET"])
y = df["TARGET"]

feature_names = list(X.columns)
print("Features used:", feature_names)
print(f"Number of features: {len(feature_names)}")
print(f"Number of rows: {len(X)}  (rows-per-feature ratio: {len(X)/len(feature_names):.0f})")

# ---------- 2. Train/test split ----------
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# ---------- 3. Train XGBoost ----------
model = xgb.XGBClassifier(
    n_estimators=150,
    max_depth=3,
    learning_rate=0.05,
    subsample=0.7,
    colsample_bytree=0.7,
    reg_alpha=0.5,
    reg_lambda=1.0,
    eval_metric="auc",
    random_state=42,
)
model.fit(X_train, y_train)

# ---------- 4. Evaluate ----------
train_probs = model.predict_proba(X_train)[:, 1]
test_probs = model.predict_proba(X_test)[:, 1]
test_preds = (test_probs >= 0.5).astype(int)

train_auc = roc_auc_score(y_train, train_probs)
test_auc = roc_auc_score(y_test, test_probs)

print(f"\nTrain AUC: {train_auc:.3f}")
print(f"Test AUC:  {test_auc:.3f}")
if train_auc > 0.97 and test_auc > 0.97:
    print("WARNING: both AUCs suspiciously high -- check for data leakage.")
elif train_auc - test_auc > 0.15:
    print("WARNING: large train/test gap -- model may be overfitting.")
else:
    print("AUC gap looks reasonable.")

print("\nClassification report (test set):")
print(classification_report(y_test, test_preds))

# ---------- 5. Feature importance ----------
print("\nFeature importance (sorted):")
importances = model.feature_importances_
for name, imp in sorted(zip(feature_names, importances), key=lambda x: -x[1]):
    print(f"  {name}: {imp:.4f}")

# ---------- 6. SHAP sanity check ----------
explainer = shap.TreeExplainer(model)
sample = X_test.iloc[[0]]
shap_values = explainer.shap_values(sample)
print("\nSHAP values for one sample:")
for fname, val in zip(feature_names, shap_values[0]):
    print(f"  {fname}: {val:.3f}")

# ---------- 7. Score distribution (for setting risk-tier cutoffs) ----------
scores = (850 - test_probs * 550).astype(int)
print("\nTest set score distribution (for choosing tier cutoffs):")
print(f"  min: {scores.min()}, 25th pct: {np.percentile(scores,25):.0f}, "
      f"median: {np.percentile(scores,50):.0f}, 75th pct: {np.percentile(scores,75):.0f}, "
      f"max: {scores.max()}")

# ---------- 8. Save everything the API needs ----------
joblib.dump(model, "campusscore_model.pkl")
joblib.dump(encoders, "campusscore_encoders.pkl")
joblib.dump(feature_names, "campusscore_features.pkl")

print("\nSaved: campusscore_model.pkl, campusscore_encoders.pkl, campusscore_features.pkl")