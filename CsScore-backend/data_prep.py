"""
CampusScore - Data Preparation (v2 - student-appropriate features)
----------------------------------------------------------------------
Changes from v1:
  - Dropped AMT_ANNUITY, FLAG_OWN_CAR, FLAG_OWN_REALTY, CNT_CHILDREN
    (don't fit a student/first-time-earner population)
  - Renamed NAME_FAMILY_STATUS usage -> replaced with a synthetic
    trust_circle_vouch_score (co-vouching feature, your differentiator)
  - Added AGE filter of 17-27 (students), not just <=30
  - AMT_CREDIT is kept but repurposed: 0 for first-time applicants,
    otherwise their prior loan amount (see note below)
  - Added on_time_repayment_rate: only meaningful for returning
    applicants; 0/blank for first-timers
  - AMT_INCOME_TOTAL kept but renamed conceptually to
    estimated_monthly_income and given a wider synthetic spread since
    many students won't have formal income

Before running:
    Place application_train.csv (or application_train.csv.zip) from
    Kaggle's "Home Credit Default Risk" in this same folder.
"""

import pandas as pd
import numpy as np
import os

np.random.seed(42)

# ---------- 1. Load real data ----------
# Only read the columns we actually need -- the full file has 122 columns,
# and parsing all of them is what makes loading slow. This also avoids
# pandas' type-inference retries on irrelevant columns.
needed_cols = ["TARGET", "AMT_INCOME_TOTAL", "DAYS_BIRTH", "NAME_EDUCATION_TYPE"]

if os.path.exists("application_train.csv"):
    df = pd.read_csv("application_train.csv", usecols=needed_cols)
elif os.path.exists("application_train.csv.zip"):
    df = pd.read_csv("application_train.csv.zip", usecols=needed_cols)
else:
    raise FileNotFoundError(
        "Couldn't find application_train.csv or application_train.csv.zip "
        "in this folder. Download it from Kaggle and place it here."
    )
print("Loaded data.")

df = df.dropna(subset=["AMT_INCOME_TOTAL"])

# NOTE: Home Credit's population is real loan applicants -- even in the
# 17-27 age slice, most already have full-time jobs and formal salaries,
# which is NOT representative of actual students (allowance, part-time
# work, tutoring, etc). Using their raw income values would train the
# model on numbers wildly higher than what real students will ever enter.
#
# Fix: keep each row's RELATIVE income rank (percentile within this
# dataset), but rescale it onto a realistic student income range
# (0 - 50,000/month) so the model learns the *pattern* -- higher
# relative income tends to reduce risk -- without learning specific
# values that don't match reality.
income_percentile = df["AMT_INCOME_TOTAL"].rank(pct=True)
df["AMT_INCOME_TOTAL"] = (income_percentile * 50000).round(0)

# Age: convert DAYS_BIRTH -> years, then filter to a real student range
df["AGE_YEARS"] = (-df["DAYS_BIRTH"] / 365).round(1)
df = df.drop(columns=["DAYS_BIRTH"])
df = df[(df["AGE_YEARS"] >= 17) & (df["AGE_YEARS"] <= 27)].reset_index(drop=True)

n = len(df)
print(f"Rows after filtering to age 17-27: {n}")

target = df["TARGET"].values


def synth_feature(good_mean, bad_mean, std, low=0, high=100):
    """Generate a feature correlated with default label, but with enough
    overlap between classes to avoid data leakage (see earlier fix)."""
    means = np.where(target == 1, bad_mean, good_mean)
    vals = np.random.normal(loc=means, scale=std)
    return np.clip(vals, low, high)


# ---------- 2. Behavioral synthetic features (student-appropriate) ----------
df["fee_payment_punctuality"] = synth_feature(good_mean=68, bad_mean=48, std=18)
df["subscription_regularity"] = synth_feature(good_mean=65, bad_mean=48, std=18)
df["savings_consistency"]     = synth_feature(good_mean=62, bad_mean=45, std=18)
df["gig_income_stability"]    = synth_feature(good_mean=60, bad_mean=45, std=20)

# Trust-circle co-vouching score: replaces family status. Represents an
# average of vouches from peers/family who have their own CampusScores.
df["trust_circle_vouch_score"] = synth_feature(good_mean=64, bad_mean=46, std=20)

# ---------- 3. Returning-applicant features ----------
# ~30% of the synthetic population are "returning" students who already
# have a small prior loan and a repayment track record. The rest are
# first-timers, where these fields are 0 (handled explicitly, not just
# left missing, since the model needs a real number in every cell).
is_returning = np.random.rand(n) < 0.3

prior_loan_amount = np.where(
    is_returning,
    np.random.uniform(500, 5000, n),  # small ticket sizes, as discussed
    0.0,
)
# On-time repayment rate: correlated with TARGET for returning users only
repayment_rate = np.where(
    is_returning,
    synth_feature(good_mean=85, bad_mean=45, std=20),
    0.0,
)

df["AMT_CREDIT"] = prior_loan_amount          # 0 = first-time applicant
df["on_time_repayment_rate"] = repayment_rate  # 0 = first-time applicant
df["is_returning_applicant"] = is_returning.astype(int)

# ---------- 4. Save ----------
df.to_csv("campusscore_training_data.csv", index=False)
print("Saved campusscore_training_data.csv")
print(df.head())
print("\nColumns:", list(df.columns))
print(f"\nReturning applicants: {is_returning.sum()} / {n}")