# Python 04 - ETL Pipeline: Brazilian E-Commerce (Olist)

## Objective

Build an end-to-end ETL (Extract, Transform, Load) pipeline using a multi-source relational dataset. Demonstrate extraction from multiple CSV files, data transformation including type correction, null handling, feature engineering and category translation, and loading into a normalized SQLite database via SQLAlchemy. Generate business-relevant SQL queries from the loaded data.

---

## Dataset

| Field | Detail |
|---|---|
| Source | Brazilian E-Commerce Public Dataset by Olist |
| Origin | [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) |
| Type | Real anonymized e-commerce transaction data |
| Period | September 2016 - August 2018 |
| Files | 9 CSV files with relational structure |
| Total source rows | 1,550,922 |
| Orders | 99,441 |
| Order items | 112,650 |

### Source table structure

| Table | Rows | Description |
|---|---|---|
| olist_orders_dataset | 99,441 | Order headers with status and timestamps |
| olist_order_items_dataset | 112,650 | Line items with product, seller, price and freight |
| olist_customers_dataset | 99,441 | Customer location data |
| olist_products_dataset | 32,951 | Product catalog with categories and dimensions |
| olist_sellers_dataset | 3,095 | Seller location data |
| olist_order_payments_dataset | 103,886 | Payment method and value per order |
| olist_order_reviews_dataset | 99,224 | Customer ratings and optional comments |
| olist_geolocation_dataset | 1,000,163 | ZIP code to lat/lon mapping |
| product_category_name_translation | 71 | Portuguese to English category translation |

---

## Methodology

### Extract
- Loaded all 9 CSV files into pandas DataFrames using a dictionary-based loader
- Performed initial inspection of shapes, column names, and first rows
- Verified file integrity and consistent row counts across related tables

### Explore & Validate
- Audited data types per column - identified 8 datetime columns incorrectly typed as string
- Mapped null values per table and column with counts and percentages
- Validated referential integrity across all 6 key foreign key relationships (orders, order_items, customers, products, sellers, payments) - all checks passed with zero orphan keys

### Transform

**Data type correction**
- Converted 8 datetime columns across orders, order_items and reviews from string to datetime64 using `pd.to_datetime()` with `errors='coerce'`

**Null handling**
- Orders: delivery date nulls retained as NaT - represent cancelled or in-transit orders (valid business data)
- Products: missing category name filled with `"unknown"` placeholder; 2 missing physical dimension values filled with column median
- Reviews: null comment titles (88.3%) and messages (58.7%) retained - represent users who submitted a star rating only

**Category translation**
- Merged products table with translation table on `product_category_name`
- Added `product_category_name_english` column using left join to preserve all products
- Translation coverage: 98.1% (623 products remained as `"unknown"`)

**Feature engineering**
- `delivery_days_actual`: days between purchase timestamp and actual delivery
- `delivery_days_estimated`: days between purchase timestamp and estimated delivery date
- `delivery_delay_days`: difference between actual and estimated (positive = late, negative = early)
- `delivered_on_time`: binary flag (1 = on time or early, 0 = late)
- `purchase_year` and `purchase_month`: extracted from purchase timestamp for time series analysis
- `line_total`: price plus freight value per order line

**Master analytical table**
- Built a 112,650-row x 20-column master table joining order_items, orders, products, sellers and customers
- Designed for direct business analysis without requiring joins at query time

### Load
- Created SQLite database (`olist_etl.db`) using SQLAlchemy engine
- Loaded 8 tables: 7 transformed source tables plus the master analytical table
- Used `if_exists='replace'` for idempotent pipeline execution
- Verified load by querying row counts directly from SQLite independently of pandas DataFrames

### Validate & Query
Executed 4 business SQL queries against the loaded database:
1. On-time delivery rate by year
2. Top 10 product categories by revenue
3. Average delivery delay by seller state
4. Monthly order volume and revenue trend (2017-2018)

---

## File Structure

```
04_etl_pipeline/
├── data/
│   ├── raw/                           <- Original 9 CSV files from Kaggle (not tracked in git)
│   └── processed/
│       ├── olist_etl.db               <- SQLite database with 8 loaded tables
│       └── olist_master.csv           <- Exported master analytical table (not tracked in git)
├── 04_etl_pipeline.ipynb              <- Main Jupyter Notebook with complete ETL pipeline
├── requirements.txt                   <- Python dependencies
└── README.md                          <- This file
```

---

## Key Findings

1. **On-time delivery rate declined with growth:** Rate dropped from 98.9% in 2016 to 91.2% in 2018 as order volume scaled from 267 to 52,783 delivered orders annually. Logistics capacity did not keep pace with demand growth.

2. **Olist uses conservative delivery estimates:** Average delivery delay of -11.3 days means orders typically arrive 11 days before the promised date. This is a deliberate customer experience strategy.

3. **Amazonas (AM) is the only chronically late region:** The only seller state with a positive average delay (+9.3 days). All other states deliver ahead of schedule. Geographic isolation explains the logistics gap.

4. **Health & Beauty leads revenue:** Top category with $1,412,089 in total revenue across 8,647 delivered orders. Watches & Gifts has the highest average unit price at $199.

5. **Black Friday effect is clearly visible:** November 2017 shows 7,593 orders - nearly double October's 4,698. Revenue jumped from $751K to $1.15M in a single month.

6. **Orders consistently grew through 2017:** Volume increased from 799 orders in January 2017 to 7,593 in November 2017, an 850% increase in eleven months, before stabilizing in 2018.

---

## Limitations

- **Geolocation table not used in pipeline:** The 1,000,163-row geolocation table was loaded but excluded from the master table due to its size and the ZIP-code-level granularity not being required for the business queries defined.
- **Reviews text not analyzed:** Comment titles and messages were retained in the database but no NLP or sentiment analysis was performed.
- **2016 data is partial:** Only 267 delivered orders in 2016, making year-over-year comparisons with 2017 and 2018 unreliable for trend analysis.
- **Payment table not in master:** Payment data is available in SQLite but was not merged into the master table to avoid row multiplication from orders with multiple payment installments.

---

## Tools Used

| Tool | Purpose |
|---|---|
| Python 3.11 | Primary programming language |
| pandas | Data loading, transformation, and feature engineering |
| numpy | Numerical operations and median imputation |
| SQLAlchemy | Database engine creation and table loading |
| SQLite | Lightweight relational database for structured storage |
| pathlib | File system path management |
| Jupyter Notebook | Interactive environment for documented pipeline |

---

## Future Enhancements

- Add geolocation join to enable geographic revenue and delivery maps
- Implement NLP sentiment analysis on review comment messages
- Build incremental load logic to append new data without full reload
- Add data quality checks as assertions that halt the pipeline on failure
- Export business query results to Excel or CSV for reporting use
- Connect the SQLite database to Power BI or Tableau for visual dashboards
