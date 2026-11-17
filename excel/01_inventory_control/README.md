# Excel 01 — Inventory Control: ABC/XYZ Analysis

## Objective

Classify a catalog of 7,082 SKUs from an Amazon e-commerce dataset using ABC and XYZ analysis to identify high-value products, understand demand variability, and define appropriate inventory management strategies.

---

## Dataset

| Field | Detail |
|---|---|
| Source | Kaggle — [Amazon Sale Report](https://www.kaggle.com/datasets/thedevastator/unlock-profits-with-e-commerce-sales-data?resource=download&select=Amazon+Sale+Report.csv) |
| Author | thedevastator |
| Records | 107,160 shipped order lines (of ~129,000 in the source file) covering 7,082 SKUs |
| Period | 31 March 2022 — 29 June 2022 (about 3 months; April, May and June are full months) |
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
Classification by **sales value** over the 3-month window (Amount):

| Class | Criterion | SKUs | % of SKUs |
|---|---|---|---|
| A | Top 80% of total value | 1,967 | 27.8% |
| B | Next 15% of total value | 2,143 | 30.3% |
| C | Bottom 5% of total value | 2,972 | 42.0% |

> Note: ABC was calculated using sales value (revenue), not cost value, as cost data was not available in this dataset. Percentages use the 7,082 classified SKUs as denominator. (The previous `Summary` sheet divided by a hard-coded 7,116; it now divides by the number of classified SKUs.)

### XYZ Analysis
Classification by **demand variability** using Coefficient of Variation (CV = Std Dev / Mean of monthly Qty):

| Class | Criterion | SKUs | % of SKUs |
|---|---|---|---|
| X | CV < 0.5 — stable demand | 1,528 | 21.6% |
| Y | 0.5 ≤ CV < 1.0 — variable demand | 2,583 | 36.5% |
| Z | CV ≥ 1.0 — erratic demand | 2,970 | 41.9% |

CV is computed over the three full months (April–June 2022) for the 7,081 SKUs with sales in that window. Combined with ABC:

| | X | Y | Z |
|---|---|---|---|
| **A** | 760 | 967 | 240 |
| **B** | 554 | 1,006 | 583 |
| **C** | 214 | 610 | 2,147 |

> **Data correction (applied to the workbook).** In the workbook's `Clean Data` sheet the day and month were swapped for every date with a day ≤ 12 (the text `MM-DD-YY` was read with a day-first locale). That spread three months of sales over twelve calendar months and made almost every SKU look erratic (the earlier `XYZ Analysis` sheet showed 0 X / 234 Y / 6,848 Z). The ABC result is not affected because it only uses total value. The workbook now has the dates repaired in `Clean Data` (31 Mar to 29 Jun 2022), the pivot table refreshed, and the `XYZ Analysis` sheet rebuilt on units sold in the three full months (March keeps only 31 March and is shown for reference). `Summary` also gets the ABC x XYZ matrix, its XYZ ranges were shifted by one row and the key insight now names the real dominant combination (C-Z). [`verify_xyz.py`](verify_xyz.py) recomputes everything independently from `Clean Data` and writes `results/xyz_recomputed.csv` and `results/abc_xyz_matrix.csv`; its output matches the workbook (1,528 X / 2,583 Y / 2,970 Z, 0 class mismatches).

---

## File Structure

```
01_inventory_control/
├── 01_inventory_control.xlsx    ← Main analysis file
├── verify_xyz.py                ← Repairs the dates and recomputes XYZ / ABC×XYZ
├── results/                     ← Output of verify_xyz.py
├── images/                      ← Charts used in this README
└── README.md                    ← This file
```

**Sheets in the Excel file:**

| Sheet | Description |
|---|---|
| Raw Data | Original dataset as downloaded |
| Clean Data | Filtered and cleaned data (Shipped only, formatted dates and amounts) |
| ABC Analysis | SKU classification by sales value (31 Mar - 29 Jun 2022) with cumulative % |
| XYZ Analysis | SKU classification by demand variability (CV of monthly units, Apr-Jun) with the ABC class alongside |
| Summary | Executive dashboard with KPIs and key insights |

---

## Results Preview

![Abc pareto](images/01_abc_pareto.png)

![Abc xyz matrix](images/02_abc_xyz_matrix.png)

---

## Key Findings

1. **Pareto confirmed:** 27.8% of SKUs (Class A) represent 80% of total sales value.
2. **Demand is variable, with a long erratic tail:** 41.9% of SKUs are Class Z and 21.6% are Class X. Z is concentrated in the low-value tail (2,147 of the 2,972 Class C SKUs), not in the high-value SKUs.
3. **High-value SKUs are the most predictable:** 1,727 of the 1,967 Class A SKUs are X or Y (only 240 are Z). Class A–X (760 SKUs) is the natural candidate for fixed-cycle replenishment and tight control; C–Z (2,147 SKUs) calls for make-to-order or minimal stock.
4. **Policy by cell, not one rule for the catalog:** A–X/A–Y suit forecast-based replenishment with safety stock; B–Y and C–Y suit periodic review; Z items should not carry safety stock without a business case.

---

## Limitations

- **No cost data available** — ABC was calculated on revenue, not consumption cost. Results reflect sales importance, not procurement value.
- **Stock Status analysis excluded** — the dataset contains sales transactions only, with no inventory level data (current stock, min/max). A dedicated inventory dataset would be required for that analysis.
- **Short time window** — the dataset covers about 3 months, so each SKU has at most three monthly observations and CV is coarse (a SKU that sells once is automatically Z). A 12-month window is recommended for production use. The value in the ABC sheet is therefore a three-month value, not annual.

---

## Tools Used

- Microsoft Excel (Advanced)
- Pivot Tables
- SUMIF, COUNTIF, VLOOKUP
- Conditional Formatting
- TEXT, DATE, DATEVALUE functions
