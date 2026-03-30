# Python 02 - Inventory Optimization: EOQ, Safety Stock & Reorder Point

## Objective

Calculate optimal inventory parameters (Economic Order Quantity, Safety Stock, and Reorder Point) for 303 SKUs using 2.5 years of historical sales data. The goal is to minimize total inventory costs while maintaining a 95% service level and identifying high-risk items requiring special attention.

---

## Dataset

| Field | Detail |
|---|---|
| Source | Kaggle - [Dynamic Inventory Dataset - Kaizen Analytics](https://www.kaggle.com/datasets/andrewniko/dynamic-inventory-dataset-kaizen-analytics) |
| Author | andrewniko |
| Records | 33,919 sales transactions + 303 SKU inventory records |
| Period | January 2021 - July 2023 (2.5 years) |
| Warehouses | 4 locations in Canada (Saskatchewan, Quebec) |
| File | `dataset_kaizen analytics.xlsx` (4 sheets) |

**Key variables:** `Order Date`, `SKU ID`, `Order Quantity`, `Cost per SKU`, `Average Lead Time`, `Maximum Lead Time`, `Unit Price`, `Vendor Name`

---

## Methodology

### Data Cleaning & Preparation
- Dropped 5 empty columns (`Unnamed: 8` through `Unnamed: 12`) from sales data
- Created time features: Year, Month, Quarter, Year-Month for temporal analysis
- Calculated monthly and daily demand aggregations by SKU
- Merged sales history with inventory control data and SKU catalog

### Demand Analysis
- Calculated Coefficient of Variation (CV) to measure demand variability
- Classified demand as Low (CV < 50%), Medium (50-100%), or High (CV > 100%)
- Analyzed demand trends over time and distribution by year
- Visualized demand patterns using histograms, line charts, and box plots

### ABC Classification
- Calculated annual consumption value = Total Demand × Cost per SKU
- Sorted SKUs by descending value and computed cumulative percentage
- Classified as A (top 80% of value), B (next 15%), or C (last 5%)
- Created Pareto chart and pie chart visualizations

### Inventory Parameter Calculation
**Safety Stock:**
- Formula: `Safety Stock = Z × σ × √LT`
- Where Z = 1.645 (95% service level), σ = demand standard deviation, LT = lead time
- Higher variability and longer lead times result in higher safety stock

**Reorder Point:**
- Formula: `Reorder Point = (Avg Daily Demand × Avg Lead Time) + Safety Stock`
- Represents the inventory level at which a new order should be placed

**Economic Order Quantity (EOQ):**
- Formula: `EOQ = √((2 × D × S) / H)`
- Where D = annual demand, S = order cost ($100), H = holding cost (20% of unit cost)
- Minimizes total inventory costs (ordering + holding)
- Set minimum EOQ = 1 to avoid division by zero for low-demand items

**Orders per Year & Days Between Orders:**
- Orders per Year = Annual Demand / EOQ
- Days Between Orders = 365 / Orders per Year

### Risk Assessment
- Flagged high-risk SKUs: CV > 100% AND Average Lead Time > 60 days
- High-risk items require increased monitoring and potentially higher safety stock

---

## File Structure

```
02_inventory_optimization/
├── 02_inventory_optimization.ipynb       ← Main Jupyter Notebook with complete analysis
├── dataset_kaizen analytics.xlsx         ← Original dataset (4 sheets: Sales, Inventory, SKU, Warehouse)
├── inventory_optimization_results.csv    ← Exported results with all calculated parameters
├── requirements.txt                      ← Python dependencies
└── README.md                             ← This file
```

---

## Key Findings

1. **ABC Classification confirms Pareto principle:** 27.7% of SKUs (Class A) represent 80% of total annual consumption value.
2. **High demand variability dominates:** 96.4% of SKUs have CV > 100% (High variability), indicating erratic demand patterns typical of multi-warehouse distribution.
3. **Wide range of order frequencies:** Orders per year range from 2 (semi-annual) to 68 (weekly), with an average of 19 orders per year per SKU.
4. **Lead time variability:** Average lead times range from 14 to 140 days, with longer lead times requiring significantly higher safety stock.
5. **High-risk SKUs identified:** SKUs combining high demand variability (CV > 100%) and long lead times (> 60 days) require immediate attention and potentially alternative suppliers.

---

## Limitations

- **Order cost and holding cost are estimated:** Used industry-standard assumptions ($100 per order, 20% holding cost rate) as the dataset does not include actual cost data.
- **Service level is uniform:** Applied 95% service level to all SKUs. In practice, Class A SKUs may warrant 99% service level while Class C could use 90%.
- **No seasonality adjustment:** EOQ calculation assumes constant demand throughout the year. Seasonal products may require dynamic EOQ adjustments.
- **Lead time treated as constant:** Safety stock calculation uses average lead time. Lead time variability could be incorporated for more robust protection.
- **No minimum order quantity (MOQ) constraints:** Real-world supplier MOQs may require adjusting EOQ results.

---

## Tools Used

| Tool | Purpose |
|---|---|
| Python 3.x | Primary programming language |
| pandas | Data manipulation, aggregation, and analysis |
| numpy | Mathematical calculations (sqrt, array operations) |
| matplotlib | Base charting library for visualizations |
| seaborn | Statistical visualization and styling |
| scipy.stats | Normal distribution calculations for Z-scores (safety stock) |
| Jupyter Notebook | Interactive environment for documented analysis |
