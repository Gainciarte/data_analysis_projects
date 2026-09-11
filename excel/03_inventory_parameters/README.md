# Excel 03 - Inventory Parameters: Safety Stock, EOQ & Replenishment Analysis

## Objective

Calculate key inventory management parameters for a 290-SKU catalog using 25 months of real sales history. The goal is to determine safety stock levels, reorder points, and optimal order quantities per SKU, and identify the highest-risk items requiring immediate replenishment action.

---

## Dataset

| Field | Detail |
|---|---|
| Source | Kaggle - [Dynamic Inventory Analytics](https://www.kaggle.com/datasets/andrewniko/dynamic-inventory-dataset-kaizen-analytics) |
| Author | Kaizen Analytics |
| Sales Records | 33,919 orders |
| Period | January 2021 - January 2023 (25 months) |
| SKUs | 290 active products |
| File | Not included due to file size - download from source link above |

**Sheets used:**
- `Sales Data` - order history with quantities and dates
- `Inventory Control` - current stock levels, unit costs, lead times
- `SKU Items` - product names

---

## Methodology

### Data Cleaning
- Verified date format and numeric fields
- Added auxiliary columns: `Month-Year`, `Year`, `Month`, `Week`
- Built monthly demand pivot table per SKU (25 months x 290 SKUs)

### Parameters Calculated

| Parameter | Formula | Notes |
|---|---|---|
| Avg Daily Demand | Avg Monthly Demand / 30 | Per SKU from 25-month history |
| Std Dev Daily | Std Dev Monthly / √30 | Converted to daily units for consistency with lead time |
| Z Score | NORM.S.INV(Service Level) | 95% service level → Z = 1.645 |
| Safety Stock | Z x Std Dev Daily x √Avg Lead Time | Covers demand variability during replenishment |
| Reorder Point | (Avg Daily Demand x Avg Lead Time) + Safety Stock | Trigger point for purchase order |
| Annual Demand | Avg Daily Demand x 365 | Annualized for EOQ calculation |
| EOQ | √(2 x Annual Demand x Order Cost / Holding Cost Rate x Unit Cost) | Optimal order quantity |
| Adjusted EOQ | CEILING(EOQ; MOQ) | Rounded up to supplier minimum order quantity |
| Inventory Gap | MAX(Reorder Point - Current Stock; 0) | Units short of reorder point |
| Value at Risk | Inventory Gap x Unit Cost | Financial exposure per SKU |

### Configurable Parameters

| Parameter | Default Value | Description |
|---|---|---|
| Service Level | 95% | Target probability of no stockout |
| Order Cost | $50 | Fixed cost per purchase order issued |
| Holding Cost Rate | 25% | Annual cost of holding inventory as % of unit cost |
| MOQ | 100 | Minimum order quantity per supplier |

### Stock Status Classification

| Status | Condition |
|---|---|
| CRITICAL | Current Stock < Safety Stock |
| REORDER | Current Stock < Reorder Point |
| OK | Current Stock >= Reorder Point |

---

## File Structure

```
03_inventory_parameters/
├── 03_inventory_parameters.xlsx    <- Main analysis file
└── README.md                       <- This file
```

**Sheets in the Excel file:**

| Sheet | Description |
|---|---|
| Raw Data - Sales | Original sales order history |
| Raw Data - Inventory | Current stock, costs and lead times per SKU |
| Raw Data - SKU | Product name reference table |
| Raw Data - Warehouse | Warehouse location data |
| Clean Data | Filtered sales data with auxiliary date columns |
| Demand Analysis | Monthly demand pivot table + avg, std dev, total per SKU |
| Inventory Parameters | Full parameter calculation per SKU |
| Pivot | Supporting pivot tables for dashboard charts |
| Dashboard | Executive dashboard with KPIs and insights |

---

## Key Findings

1. **49% of SKUs require immediate attention** - 83 SKUs below safety stock (CRITICAL) and 60 below reorder point (REORDER).
2. **SKU 1295CA is the highest priority** with $3.4M in value at risk due to inventory gap.
3. **Top 10 SKUs by value at risk represent over $18.7M** in total financial exposure requiring prioritized replenishment.
4. **Safety stock calculation uses daily demand variability** - Std Dev was converted from monthly to daily units (Std Dev / √30) to maintain unit consistency with lead times expressed in days.

---

## Limitations

- **Static snapshot** - current stock levels reflect a single point in time and may not account for in-transit inventory or pending purchase orders.
- **Uniform service level** - all SKUs use 95% service level. In practice, critical or high-value SKUs may warrant higher levels (98-99%) while low-value SKUs could use lower levels (90%).
- **Simplified holding cost** - holding cost rate of 25% is an industry estimate. Actual rates vary by warehouse, product category and capital cost.
- **No supplier constraints beyond MOQ** - analysis does not account for supplier lead time variability, volume discounts or contract minimums.

---

## Tools Used

- Microsoft Excel (Advanced)
- Pivot Tables
- VLOOKUP, NORM.S.INV, SQRT, CEILING, MAX
- COUNTIF, COUNTA, SUMIF
- Pie chart, Horizontal bar chart
- Custom configurable parameters table
