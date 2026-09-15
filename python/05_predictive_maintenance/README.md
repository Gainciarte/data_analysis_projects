# Python 05 - Predictive Maintenance: Machine Failure Classification

## Objective

Build a machine learning pipeline to predict machine failure in an industrial milling process using sensor and process data. Compare a baseline linear model against an ensemble model under severe class imbalance, and identify which process variables drive failure risk.

---

## Dataset

| Field | Detail |
|---|---|
| Source | UCI Machine Learning Repository - [AI4I 2020 Predictive Maintenance Dataset](https://archive.ics.uci.edu/dataset/601/ai4i+2020+predictive+maintenance+dataset) |
| Type | Synthetic dataset modeled on real industrial milling machine behavior |
| Records | 10,000 machine operating instances |
| File | `ai4i2020.csv` |

**Key variables:** `Type`, `Air temperature [K]`, `Process temperature [K]`, `Rotational speed [rpm]`, `Torque [Nm]`, `Tool wear [min]`, `Machine failure` (target), plus 5 individual failure-mode flags (`TWF`, `HDF`, `PWF`, `OSF`, `RNF`)

---

## Methodology

### Data Validation
- Confirmed no missing values and no duplicated rows across all 10,000 records
- Checked the `Machine failure` flag against the sum of the 5 individual failure-mode flags: 27 rows (0.27%) show a disagreement, consistent with the label noise documented for this dataset

### Feature Engineering
- **Temp diff [K]:** Process temperature minus air temperature - a small differential limits heat dissipation
- **Power [W]:** Torque x angular velocity (derived from rotational speed) - mechanical load on the tool
- **Excluded by design:** `TWF`/`HDF`/`PWF`/`OSF`/`RNF` were left out of the feature set because their sum determines the `Machine failure` label - including them would leak the target

### Modeling
- Stratified 80/20 train/test split (preserves the 3.39% failure rate in both sets)
- Preprocessing: `StandardScaler` on numeric features, `OneHotEncoder` on `Type`
- Two models compared, both with `class_weight="balanced"` to compensate for class imbalance:
  - **Logistic Regression** (baseline)
  - **Random Forest** (300 trees)
- Evaluated with precision/recall/F1 per class, confusion matrix, ROC-AUC and PR-AUC (PR-AUC is the more informative metric here given the imbalance)

---

## File Structure

```
python/05_predictive_maintenance/
├── 05_predictive_maintenance.ipynb    <- Main Jupyter Notebook with complete analysis
├── ai4i2020.csv                       <- Original dataset
├── test_set_predictions.csv           <- Random Forest predictions on the held-out test set
├── feature_importance.csv             <- Random Forest feature importances
├── requirements.txt                   <- Python dependencies
└── README.md                          <- This file
```

---

## Key Findings

1. **Severe class imbalance:** only 3.39% of machines failed (339 of 10,000), a 28.5:1 ratio of healthy to failed instances.
2. **Random Forest clearly outperforms the linear baseline:** ROC-AUC 0.978 vs. 0.934, and PR-AUC 0.863 vs. 0.466. At the default threshold, Random Forest catches 73.5% of real failures (50/68) with only 3 false alarms across 1,932 healthy machines in the test set - Logistic Regression catches slightly more failures (86.8%) but at the cost of 273 false alarms, making it impractical for real maintenance scheduling.
3. **Torque, rotational speed, tool wear and power are the dominant drivers** of failure, each contributing 18.8-22.2% of Random Forest's feature importance. Temperatures and product type contribute comparatively little (under 9% combined for temperature, under 1.5% for type).
4. **Torque and Power are almost perfectly correlated (r = 0.98)** as expected from their physical relationship, and both correlate strongly and negatively with rotational speed (r = -0.88/-0.81) - the failure signal is concentrated in the mechanical-load side of the process, not the thermal side.
5. **Failure rate varies by product type:** Low-quality variants (Type L) fail at 3.92%, nearly double the rate of High-quality variants (Type H) at 2.09%.

---

## Limitations

- **Synthetic dataset:** patterns are realistic but simulated, not captured from a real production line.
- **Static snapshot per instance:** each row is an independent operating point, not a time series - the model cannot learn degradation trends leading up to a failure.
- **No cost-sensitive threshold tuning:** the default 0.5 probability threshold was used for the reported confusion matrices; a real deployment would tune the threshold against the actual cost of a false alarm vs. a missed failure.
- **Failure-mode-specific classification not modeled:** the pipeline predicts the binary `Machine failure` flag only, not which of the 5 failure modes is expected.

---

## Tools Used

| Tool | Purpose |
|---|---|
| Python 3.11 | Primary programming language |
| pandas | Data manipulation, cleaning and analysis |
| numpy | Numerical operations (power calculation) |
| matplotlib | Base charting library |
| seaborn | Statistical visualization and styling |
| scikit-learn | Preprocessing, model training and evaluation |
| Jupyter Notebook | Interactive environment for documented analysis |

---

## Future Enhancements

- Tune the classification threshold against an explicit cost matrix (false alarm vs. missed failure)
- Model each failure mode (TWF/HDF/PWF/OSF/RNF) as a separate multi-label classification target
- Try gradient boosting models (XGBoost/LightGBM) and compare against the Random Forest baseline
- Add SHAP values for per-prediction explainability
