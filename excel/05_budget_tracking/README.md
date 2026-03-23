# Excel 05 - Budget Tracking: Budget vs Actual Analysis

## Objective

Build a budget tracking model to compare planned vs actual expenditure across 6 cost categories over 12 months. The goal is to calculate variances, identify categories with significant deviations, and provide an executive summary of annual budget compliance.

---

## Dataset

| Field | Detail |
|---|---|
| Source | Kaggle - [Financial Dataset - Expenses Budget vs Actual](https://www.kaggle.com/datasets/saharsyed/financial-dataset-expenses-budget-vs-actual) |
| Author | saharsyed |
| Records | 24 rows (12 months x 2 types: Budget and Actual) |
| Period | January 2023 - December 2023 |
| Categories | 6 cost categories |
| File | Financial_analysis_Data_Set.xlsx - included in repository |

**Cost categories:** Development Costs, Operational Costs, Marketing Costs, Travelling Cost, Training Cost, Maintenance Cost

---

## Methodology

### Data Preparation
- Separated Budget and Actual records using pivot tables filtered by Type field
- Built Budget Analysis table with 72 rows (12 months x 6 categories)
- Calculated variance as Actual - Budget (positive = overspend, negative = underspend)
- Applied 10% threshold for status classification

### Variance Classification

| Status | Condition |
|---|---|
| Over Budget | Variance % > 10% |
| On Track | -10% <= Variance % <= 10% |
| Under Budget | Variance % < -10% |

### Annual Summary
Aggregated monthly data by category using SUMIF to produce annual Budget, Actual, Variance and Variance % per category.

---

## File Structure

```
05_budget_tracking/
├── 05_budget_tracking.xlsx    <- Main analysis file
└── README.md                  <- This file
```

**Sheets in the Excel file:**

| Sheet | Description |
|---|---|
| Raw Data | Original dataset as downloaded |
| Clean Data | Corrected headers, auxiliary columns |
| Pivot | PT_Budget and PT_Actual pivot tables |
| Budget Analysis | Monthly variance table by category + annual summary |
| Dashboard | Executive dashboard with KPIs, summary table and chart |

---

## Key Findings

| Category | Annual Budget | Annual Actual | Variance % | Status |
|---|---|---|---|---|
| Development Costs | $1,340,200 | $1,314,635 | -1.9% | On Track |
| Operational Costs | $165,000 | $174,082 | +5.5% | On Track |
| Marketing Costs | $75,000 | $69,676 | -7.1% | On Track |
| Travelling Cost | $48,000 | $41,300 | -14.0% | Under Budget |
| Training Cost | $86,000 | $68,000 | -20.9% | Under Budget |
| Maintenance Cost | $48,000 | $50,487 | +5.2% | On Track |
| **Total** | **$1,762,200** | **$1,718,180** | **-2.5%** | **On Track** |

1. **Overall budget compliance at 97.5%** - total underspend of $44,020 against annual budget.
2. **Training Cost shows the largest deviation at -20.9%** - likely due to cancelled or deferred training sessions during the year.
3. **Travelling Cost also underperformed at -14.0%** - fewer business trips than planned.
4. **Operational and Maintenance costs exceeded budget marginally** - typical for variable operational expenses.
5. **Development Costs, the largest category at 76% of total budget, remained tightly controlled at -1.9% variance.**

---

## Limitations

- **Single year of data** - variance analysis is limited to 2023. Multi-year comparison would provide better context on whether deviations are structural or one-off.
- **No department or project breakdown** - analysis is at category level only. Drill-down by department or cost center would add operational value.
- **Binary budget** - the dataset has a fixed monthly budget per category. In practice, budgets are often revised mid-year, which this model does not account for.

---

## Tools Used

- Microsoft Excel (Advanced)
- Pivot Tables with Type filter
- SUMIF, VLOOKUP
- Conditional Formatting
- Clustered Bar Chart
