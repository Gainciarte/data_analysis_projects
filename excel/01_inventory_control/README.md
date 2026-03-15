# Excel 01 — Inventory Control: ABC/XYZ Analysis

## Objective

Classify a catalog of 7,116 SKUs from an Amazon e-commerce dataset using ABC and XYZ analysis to identify high-value products, understand demand variability, and define appropriate inventory management strategies.

---

## Dataset

| Field | Detail |
|---|---|
| Source | Kaggle — [Amazon Sale Report](https://www.kaggle.com/datasets/thedevastator/unlock-profits-with-e-commerce-sales-data?resource=download&select=Amazon+Sale+Report.csv) |
| Author | thedevastator |
| Records | ~130,000 transactions (shipped orders only) |
| Period | April 2022 — June 2022 (12 months of SKU activity) |
| File | Not included due to file size — download from source link above |

**Columns used:** `SKU`, `Category`, `Size`, `Date`, `Qty`, `Amount`

---

## Methodology

### Data Cleaning
- Filtered `Status = Shipped` only — cancelled and pending orders excluded
- Converted `Date` column from mixed text formats (`MM-DD-YY` and `MM-DD-YYYY`) to Excel date values
- Converted `Amount` from text with decimal point to numeric format
- Retained columns: SKU, Category, Size, Date, Qty, Amount
- Category names localized from Indian garment terminology to standard apparel terms

### ABC Analysis
Classification by **annual sales value** (Amount):

| Class | Criterion | SKUs | % of SKUs |
|---|---|---|---|
| A | Top 80% of total value | 1,967 | 27.6% |
| B | Next 15% of total value | 2,143 | 30.1% |
| C | Bottom 5% of total value | 2,972 | 41.8% |

> Note: ABC was calculated using sales value (revenue), not cost value, as cost data was not available in this dataset.

### XYZ Analysis
Classification by **demand variability** using Coefficient of Variation (CV = Std Dev / Mean of monthly Qty):

| Class | Criterion | SKUs | % of SKUs |
|---|---|---|---|
| X | CV < 0.5 — stable demand | 34 | 0.5% |
| Y | 0.5 ≤ CV < 1.0 — variable demand | 234 | 3.3% |
| Z | CV ≥ 1.0 — erratic demand | 6,848 | 96.2% |

---

## File Structure

```
01_inventory_control/
├── 01_inventory_control.xlsx    ← Main analysis file
└── README.md                    ← This file
```

**Sheets in the Excel file:**

| Sheet | Description |
|---|---|
| Raw Data | Original dataset as downloaded |
| Clean Data | Filtered and cleaned data (Shipped only, formatted dates and amounts) |
| ABC Analysis | SKU classification by annual sales value with cumulative % |
| XYZ Analysis | SKU classification by demand variability (CV) |
| Summary | Executive dashboard with KPIs and key insights |

---

## Key Findings

1. **Pareto confirmed:** 27.6% of SKUs (Class A) represent 80% of total sales value.
2. **Demand is highly erratic:** 96.2% of SKUs are Class Z — typical of high-SKU e-commerce with seasonal and trend-driven demand.
3. **Dominant combination is A–Z:** high-value products with unpredictable demand. This profile requires dynamic replenishment and elevated safety stock rather than fixed order quantities.
4. **Fixed replenishment systems are not recommended** for this catalog given the near-absence of stable (X-class) SKUs.

---

## Limitations

- **No cost data available** — ABC was calculated on revenue, not consumption cost. Results reflect sales importance, not procurement value.
- **Stock Status analysis excluded** — the dataset contains sales transactions only, with no inventory level data (current stock, min/max). A dedicated inventory dataset would be required for that analysis.
- **Short time window** — the dataset covers approximately 3 months of transactions, which limits the robustness of the XYZ variability analysis. A 12-month window is recommended for production use.

---

## Tools Used

- Microsoft Excel (Advanced)
- Pivot Tables
- SUMIF, COUNTIF, VLOOKUP
- Conditional Formatting
- TEXT, DATE, DATEVALUE functions
