# Excel 02 — KPI Dashboard: Walmart Sales Analysis

## Objective

Build an operational KPI dashboard using Walmart weekly sales data across 45 stores over 3 years. The goal is to identify top-performing stores, analyze sales trends over time, and quantify the impact of holiday weeks on sales performance.

---

## Dataset

| Field | Detail |
|---|---|
| Source | Kaggle - [Walmart Sales](https://www.kaggle.com/datasets/mikhail1681/walmart-sales) |
| Author | mikhail1681 |
| Records | 6,435 rows (45 stores x 143 weeks) |
| Period | February 2010 - October 2012 |
| File | Not included due to file size - download from source link above |

**Columns used:** `Store`, `Date`, `Weekly_Sales`, `Holiday_Flag`

**Columns excluded:** `Temperature`, `Fuel_Price`, `CPI`, `Unemployment` - retained for potential future analysis in Python or Machine Learning projects.

---

## Methodology

### Data Cleaning
- Converted `Date` column from text to Excel date values
- Added `Month-Year` auxiliary column (`yyyy-mm` format) for chronological sorting in charts
- Verified `Weekly_Sales` as numeric format
- Confirmed `Holiday_Flag` binary values (0 = Non-Holiday, 1 = Holiday)

### KPIs Calculated

| KPI | Value | Formula |
|---|---|---|
| Total Sales | $6,737,218,987 | SUM of all Weekly_Sales |
| Avg Weekly Sales | $1,046,965 | AVERAGE of all Weekly_Sales |
| Holiday Sales Lift | 8% | AVERAGEIF Holiday / AVERAGEIF Non-Holiday - 1 |
| Best Store | Store 20 | INDEX/MATCH on SUMIF by store |

### Charts Built

| Chart | Type | Source |
|---|---|---|
| Weekly Sales Trend | Line chart | Pivot table - sales by month |
| Sales by Store - Top 10 | Horizontal bar chart | Pivot table - sales by store (top 10 filter) |
| Holiday vs Non-Holiday | Clustered column chart | Pivot table - avg sales by holiday flag |

---

## File Structure

```
02_kpi_dashboard/
├── 02_kpi_dashboard.xlsx    <- Main dashboard file
└── README.md                <- This file
```

**Sheets in the Excel file:**

| Sheet | Description |
|---|---|
| Raw Data | Original dataset as downloaded |
| Clean Data | Formatted dates, auxiliary columns added |
| Pivot | Supporting pivot tables for all charts |
| Dashboard | KPI dashboard with charts and insights |

---

## Key Findings

1. **Store 20 is the top performer** across all 45 locations with the highest cumulative sales over the 3-year period.
2. **Holiday weeks generate 8% higher average sales** than non-holiday weeks - a statistically meaningful but moderate lift.
3. **Sales peaked in December 2010 and November 2011**, consistent with seasonal holiday demand patterns (Thanksgiving, Christmas).
4. **Sales trend is relatively stable** across the 3-year period with clear seasonal cycles, suggesting predictable demand planning opportunities.

---

## Limitations

- **No store size or format data available** - sales differences between stores may reflect store size rather than performance.
- **Holiday flag is binary** - does not distinguish between specific holidays (Thanksgiving, Christmas, Labor Day, etc.).
- **No category or department breakdown** - analysis is at store level only.

---

## Tools Used

- Microsoft Excel (Advanced)
- Pivot Tables with Top 10 filter
- AVERAGEIF, SUMIF, INDEX, MATCH
- Line chart, Bar chart, Column chart
- Custom color theme
