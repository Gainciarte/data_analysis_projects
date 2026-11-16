# 📊 Data Analysis Projects

A portfolio of data analysis projects across multiple tools and technologies, covering real-world use cases in logistics, operations, supply chain, and business intelligence. Built by a mechanical engineer with 8+ years in supply chain, warehousing and procurement, adding data analysis tools to that background.

**Status:** 25 of 30 planned projects completed (Excel, Python, SQL, Machine Learning and Power BI). The 5 Tableau dashboards are in progress (see [Tableau](#-tableau-in-progress)); they will be added to the project tables as each one is finished and published.

---

## 🗂️ Repository Structure

```
data_analysis_projects/
│
├── excel/    01_inventory_control · 02_kpi_dashboard · 03_inventory_parameters
│             04_supplier_evaluation · 05_budget_tracking
├── python/   01_sales_eda · 02_inventory_optimization · 03_web_scraping
│             04_etl_pipeline · 05_predictive_maintenance
├── sql/      01_inventory_queries · 02_sales_reporting · 03_customer_analysis
│             04_supply_chain_queries · 05_data_cleaning
├── ml/       01_demand_forecasting · 02_anomaly_detection · 03_classification_model
│             04_customer_clustering · 05_regression_analysis
└── powerbi/  01_warehouse_kpis · 02_procurement_analysis · 03_project_tracking
              04_hr_headcount · 05_operational_costs
```

---

## 🔧 Tools & Technologies (in use)

| Category | Tools |
|---|---|
| Spreadsheets | Microsoft Excel (Advanced), Power Query |
| Programming | Python (pandas, numpy, scipy, matplotlib, seaborn, requests, BeautifulSoup, sqlalchemy) |
| Databases | PostgreSQL 16 (SQL projects), SQLite |
| BI | Power BI Desktop (DAX, Power Query, PBIP projects); Tableau Public (in progress) |
| Machine Learning | scikit-learn, statsmodels |
| Version Control | Git, GitHub |

---

## 📁 Projects by Tool

### 📗 Excel

| # | Project | Description | Key Skills |
|---|---|---|---|
| 01 | Inventory Control | ABC/XYZ analysis on Amazon e-commerce sales data. Classifies 7,082 SKUs by value and demand variability over 3 months of sales | Pivot Tables, SUMIF, COUNTIF, Conditional Formatting, VLOOKUP |
| 02 | KPI Dashboard | Operational sales KPI dashboard using Walmart weekly sales data across 45 stores and 3 years | Dashboard Design, Slicers, Dynamic Charts, Named Ranges |
| 03 | Inventory Parameters | Safety stock, reorder point, EOQ and value at risk calculation for 290 SKUs using 25 months of real sales history | NORM.S.INV, VLOOKUP, SQRT, CEILING, Pivot Tables |
| 04 | Supplier Evaluation | Multi-criteria decision model (MCDM) to evaluate and rank 35 suppliers across 12 weighted criteria | SUMPRODUCT, Min-Max Normalization, INDEX/MATCH, RANK |
| 05 | Budget Tracking | Budget vs actual variance analysis across 6 cost categories over 12 months with executive dashboard | SUMIF, Pivot Tables, Conditional Formatting, Clustered Bar Chart |

---

### 🐍 Python

| # | Project | Description | Key Libraries |
|---|---|---|---|
| 01 | Sales EDA | Exploratory data analysis on Amazon India sales dataset to identify consumption patterns, discount effectiveness, and customer satisfaction | pandas, matplotlib, seaborn |
| 02 | Inventory Optimization | Calculate optimal inventory parameters (EOQ, Safety Stock, Reorder Point) for 303 SKUs using 2.5 years of sales data with ABC classification and risk assessment | pandas, numpy, scipy, matplotlib, seaborn |
| 03 | Web Scraping | Extract, clean and analyze book data from public e-commerce website. Demonstrates HTTP requests, HTML parsing with BeautifulSoup, pagination handling, and data export | requests, BeautifulSoup, pandas |
| 04 | ETL Pipeline | End-to-end ETL pipeline on a 9-file relational e-commerce dataset (Olist, 100K orders). Covers multi-source extraction, datetime correction, null handling, feature engineering, category translation, SQLite loading via SQLAlchemy, and business SQL queries | pandas, numpy, sqlalchemy |
| 05 | Predictive Maintenance | Binary classification of machine failure on 10,000 industrial sensor records under severe class imbalance (3.39%). Compares Logistic Regression vs. Random Forest (ROC-AUC 0.978, PR-AUC 0.863) with feature importance analysis | pandas, numpy, scikit-learn, matplotlib, seaborn |

---

---

### 🗄️ SQL (PostgreSQL)

Each project has numbered `.sql` scripts that run top to bottom, a small Python loader that reproduces the results, the real query outputs in `results/` and charts in `images/`.

| # | Project | Description | Key Skills |
|---|---|---|---|
| 01 | Inventory Queries | Stock status, reorder risk, ABC/XYZ, dead stock and overstock for 303 SKUs, with reusable views | CTEs, window functions, `FILTER`, views |
| 02 | Sales Reporting | 33,919 orders as a small star schema: monthly KPIs, MoM/YoY, running totals, moving averages and top-N rankings | `LAG`, `RANK`, running `SUM`, materialized view |
| 03 | Customer Analysis | RFM scoring, repeat purchase, customer lifetime value and monthly cohort retention on 1M+ real transaction lines | `NTILE`, cohorts, indexes, constraints |
| 04 | Supply Chain Queries | Vendor lead times, replenishment timing, revenue at risk and warehouse comparison | `ROLLUP`, `PERCENTILE_CONT`, `NTILE` |
| 05 | Data Cleaning | Raw Amazon India product export cleaned in SQL only: profiling, deduplication, quarantine table, validation checks | Text cleaning, `UNNEST`, validation queries |

---

### 🤖 Machine Learning

Each project is an executed Jupyter notebook with its README, saved results and charts. Validation is explicit (time-based splits, stratified or grouped CV, baselines, leakage audit) and limitations are documented.

| # | Project | Description | Key Libraries |
|---|---|---|---|
| 01 | Demand Forecasting | Monthly demand of the top SKUs: naive, moving average, Holt-Winters/ETS and SARIMA with rolling-origin evaluation, and the effect of forecast error on safety stock | statsmodels, pandas |
| 02 | Anomaly Detection | Isolation Forest, LOF and robust z-scores on industrial sensor data and on order quantities with injected spikes | scikit-learn |
| 03 | Classification Model | Late-delivery prediction on public USAID health-commodity shipments (logistic regression, random forest, gradient boosting) with a chronological test | scikit-learn |
| 04 | Customer Clustering | RFM + KMeans/hierarchical clustering of UCI Online Retail II customers, with segment profiles and a forward-looking validation | scikit-learn, scipy |
| 05 | Regression Analysis | Freight-cost regression (OLS with robust errors vs regularized and tree models) with grouped cross-validation | statsmodels, scikit-learn |

---

### 📊 Power BI

Five dashboards saved as **Power BI Projects (`.pbip`)**: the semantic model (tables, relationships, DAX measures) is TMDL text and the report is PBIR JSON, so changes are reviewable in Git. Each project folder has a README with the data model, key DAX measures, screenshots exported from Power BI Desktop, findings and limitations. Every headline number was recomputed independently with pandas ([`powerbi/verify_numbers.py`](powerbi/verify_numbers.py)).

| # | Project | Description | Key Skills |
|---|---|---|---|
| 01 | [Warehouse KPIs](powerbi/01_warehouse_kpis) | Stock value, days of cover against lead time, overstock, turnover and sales by warehouse (synthetic Kaizen data, flagged as such) | DAX, calculated columns, `SWITCH(TRUE())`, `RANKX` |
| 02 | [Procurement Analysis](powerbi/02_procurement_analysis) | Spend, vendor concentration, sourcing route, freight and delivery performance on USAID shipments | Star model, `TOPN`, time intelligence, `DIVIDE` |
| 03 | [Project Tracking](powerbi/03_project_tracking) | On-time performance and schedule variance across 142 project codes | Calculated buckets, `sortByColumn`, `CALCULATE` |
| 04 | [HR Headcount](powerbi/04_hr_headcount) | Workforce profile and attrition drivers (fictional IBM HR sample, flagged as such) | Measures vs. columns, ordered bands, benchmarks |
| 05 | [Operational Costs](powerbi/05_operational_costs) | Freight and insurance by mode, weight band and country | Ratio measures, data-coverage measure, `HASONEVALUE` |

---

### 📈 Tableau (in progress)

Not published yet. Each dashboard will be listed in a table like the ones above, with its data source, a screenshot and a link, only once it is finished.

| Tool | Planned projects | Status |
|---|---|---|
| Tableau | Logistics Dashboard, Sales Performance, Customer Segmentation, Supply Chain Map, Financial Overview | 🚧 In progress |

---

## 🚀 Getting Started

### Prerequisites

- Python 3.9+ (3.12 recommended for the SQL projects)
- pip or conda

### Python / ML setup

```bash
git clone https://github.com/Gainciarte/data_analysis_projects.git
cd data_analysis_projects
pip install -r requirements.txt        # everything, or use the requirements.txt inside each project folder
```

### SQL projects

They use an **embedded PostgreSQL 16** through the `pgserver` package, so no database installation is needed. From each project folder:

```bash
pip install -r requirements.txt
python run_<name>.py
```

`pgserver` publishes wheels for Python 3.9-3.12 only.

---

## 📌 Notes

- Each project folder contains its own `README.md` with objective, data source, methodology and results.
- Small datasets are included in the repository; large ones are **not**, and each project README links to the original source (some loaders download the file on first run).
- Datasets used are either publicly available or anonymized synthetic data.
- Excel 01: Stock Status analysis was excluded as the dataset contains sales data only, not inventory levels. A date-parsing issue in the workbook's XYZ sheet was found and corrected in the README (see `excel/01_inventory_control/verify_xyz.py`). Both points are documented in the project README.
- The Kaizen Analytics inventory dataset looks synthetic (for example, unit price is cost / 0.7 for every SKU), so margin-based conclusions on it are not meaningful. This is flagged in the projects that use it.

---

## 🗺️ Roadmap

The repository structure above only shows what is built. Remaining work: the 5 Tableau dashboards (see the in-progress table), then a final pass on the Excel 01 workbook so its XYZ sheet matches the corrected results.

---

## 🗃️ Data Sources

| Project | Dataset | Source |
|---|---|---|
| Excel 01 - Inventory Control | Amazon Sale Report (e-commerce sales data) | [Kaggle](https://www.kaggle.com/datasets/thedevastator/unlock-profits-with-e-commerce-sales-data?resource=download&select=Amazon+Sale+Report.csv) |
| Excel 02 - KPI Dashboard | Walmart Sales (45 stores, weekly sales 2010-2012) | [Kaggle](https://www.kaggle.com/datasets/mikhail1681/walmart-sales) |
| Excel 03 - Inventory Parameters | Dynamic Inventory Analytics - Kaizen Analytics | [Kaggle](https://www.kaggle.com/datasets/andrewniko/dynamic-inventory-dataset-kaizen-analytics) |
| Excel 04 - Supplier Evaluation | Suppliers Ranking Grades | [Kaggle](https://www.kaggle.com/datasets/michaelclodeemil/suppliers-ranking-grades) |
| Excel 05 - Budget Tracking | Financial Dataset - Expenses Budget vs Actual | [Kaggle](https://www.kaggle.com/datasets/saharsyed/financial-dataset-expenses-budget-vs-actual) |
| Python 01 - Sales EDA | Amazon Sales Dataset | [Kaggle](https://www.kaggle.com/datasets/karkavelrajaj/amazon-sales-dataset) |
| Python 02 - Inventory Optimization | Dynamic Inventory Dataset - Kaizen Analytics | [Kaggle](https://www.kaggle.com/datasets/andrewniko/dynamic-inventory-dataset-kaizen-analytics) |
| Python 03 - Web Scraping | Books to Scrape (practice website) | [http://books.toscrape.com/](http://books.toscrape.com/) |
| Python 04 - ETL Pipeline | Brazilian E-Commerce Public Dataset by Olist | [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) |
| Python 05 - Predictive Maintenance | AI4I 2020 Predictive Maintenance Dataset | [Kaggle](https://www.kaggle.com/datasets/stephanmatzka/predictive-maintenance-dataset-ai4i-2020) |
| SQL 01, 02, 04 / ML 01, 02 | Kaizen Analytics inventory and sales workbook (in `python/02_inventory_optimization/`) | [Kaggle](https://www.kaggle.com/datasets/andrewniko/dynamic-inventory-dataset-kaizen-analytics) |
| SQL 03 / ML 04 | Online Retail II | [UCI Machine Learning Repository](https://archive.ics.uci.edu/dataset/502/online+retail+ii) |
| SQL 05 | Amazon India product data (raw sheet) | [Kaggle](https://www.kaggle.com/datasets/karkavelrajaj/amazon-sales-dataset) |
| ML 02 | AI4I 2020 Predictive Maintenance Dataset | [Kaggle](https://www.kaggle.com/datasets/stephanmatzka/predictive-maintenance-dataset-ai4i-2020) |
| ML 03, 05 / Power BI 02, 03, 05 | Supply Chain Shipment Pricing Data (USAID / PEPFAR SCMS) | [USAID Data](https://data.usaid.gov/HIV-AIDS/Supply-Chain-Shipment-Pricing-Data/a3rc-nmf6) |
| Power BI 01 | Kaizen Analytics inventory and sales workbook (same file as SQL 01/04) | [Kaggle](https://www.kaggle.com/datasets/andrewniko/dynamic-inventory-dataset-kaizen-analytics) |
| Power BI 04 | IBM HR Analytics Employee Attrition sample (fictional data) | [IBM/employee-attrition-aif360](https://github.com/IBM/employee-attrition-aif360) |

---

## 👤 Author

**Gustavo Inciarte**
Mechanical Engineer | Data & Logistics Analyst
[LinkedIn](https://linkedin.com/in/gainciarte) · [GitHub](https://github.com/Gainciarte)

---

*This portfolio is part of an ongoing professional development initiative focused on data analysis applied to logistics, supply chain and operations. Licensed under Apache 2.0 (see [LICENSE](LICENSE)).*
