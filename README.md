# 📊 Data Analysis Projects

A portfolio of data analysis projects across multiple tools and technologies, covering real-world use cases in logistics, operations, supply chain, and business intelligence.

---

## 🗂️ Repository Structure

```
data_analysis_projects/
│
├── excel/
│   ├── 01_inventory_control/
│   ├── 02_kpi_dashboard/
│   ├── 03_inventory_parameters/
│   ├── 04_supplier_evaluation/
│   └── 05_budget_tracking/
│
├── python/
│   ├── 01_sales_eda/
│   ├── 02_inventory_optimization/
│   ├── 03_web_scraping/
│   ├── 04_etl_pipeline/
│   └── 05_predictive_maintenance/
│
├── tableau/
│   ├── 01_logistics_dashboard/
│   ├── 02_sales_performance/
│   ├── 03_customer_segmentation/
│   ├── 04_supply_chain_map/
│   └── 05_financial_overview/
│
├── power_bi/
│   ├── 01_warehouse_kpis/
│   ├── 02_procurement_analysis/
│   ├── 03_project_tracking/
│   ├── 04_hr_headcount/
│   └── 05_operational_costs/
│
├── sql/
│   ├── 01_inventory_queries/
│   ├── 02_sales_reporting/
│   ├── 03_customer_analysis/
│   ├── 04_supply_chain_queries/
│   └── 05_data_cleaning/
│
└── machine_learning/
    ├── 01_demand_forecasting/
    ├── 02_anomaly_detection/
    ├── 03_classification_model/
    ├── 04_clustering_customers/
    └── 05_regression_analysis/
```

---

## 🔧 Tools & Technologies

| Category | Tools |
|---|---|
| Spreadsheets | Microsoft Excel (Advanced), Power Query |
| Programming | Python (pandas, numpy, matplotlib, seaborn, scikit-learn, requests, BeautifulSoup, sqlalchemy) |
| BI & Visualization | Tableau, Power BI |
| Databases | SQL (MySQL / PostgreSQL), SQLite |
| Machine Learning | scikit-learn, statsmodels |
| Version Control | Git, GitHub |

---

## 📁 Projects by Tool

### 📗 Excel

| # | Project | Description | Key Skills |
|---|---|---|---|
| 01 | Inventory Control | ABC/XYZ analysis on Amazon e-commerce sales data. Classifies 7,116 SKUs by value and demand variability across 12 months | Pivot Tables, SUMIF, COUNTIF, Conditional Formatting, VLOOKUP |
| 02 | KPI Dashboard | Operational sales KPI dashboard using Walmart weekly sales data across 45 stores and 3 years | Dashboard Design, Slicers, Dynamic Charts, Named Ranges |
| 03 | Inventory Parameters | Safety stock, reorder point, EOQ and value at risk calculation for 290 SKUs using 25 months of real sales history | NORM.S.INV, VLOOKUP, SQRT, CEILING, Pivot Tables |
| 04 | Supplier Evaluation | Multi-criteria decision model (MCDM) to evaluate and rank 35 suppliers across 12 weighted criteria | SUMPRODUCT, Min-Max Normalization, INDEX/MATCH, RANK |
| 05 | Budget Tracking | Budget vs actual variance analysis across 6 cost categories over 12 months with executive dashboard | SUMIF, Pivot Tables, Conditional Formatting, Clustered Bar Chart |

---

### 🐍 Python

| # | Project | Description | Key Libraries |
|---|---|---|---|
| 01 | Sales EDA | Exploratory data analysis on Amazon India sales dataset to identify consumption patterns, discount effectiveness, and customer satisfaction | pandas, matplotlib, seaborn, re |
| 02 | Inventory Optimization | Calculate optimal inventory parameters (EOQ, Safety Stock, Reorder Point) for 303 SKUs using 2.5 years of sales data with ABC classification and risk assessment | pandas, numpy, scipy, matplotlib, seaborn |
| 03 | Web Scraping | Extract, clean and analyze book data from public e-commerce website. Demonstrates HTTP requests, HTML parsing with BeautifulSoup, pagination handling, and data export | requests, BeautifulSoup, pandas, matplotlib, seaborn |
| 04 | ETL Pipeline | End-to-end ETL pipeline on a 9-file relational e-commerce dataset (Olist, 100K orders). Covers multi-source extraction, datetime correction, null handling, feature engineering, category translation, SQLite loading via SQLAlchemy, and business SQL queries | pandas, numpy, sqlalchemy |
| 05 | Predictive Maintenance | Failure prediction using classification model | scikit-learn, pandas |

---

### 📊 Tableau

| # | Project | Description |
|---|---|---|
| 01 | Logistics Dashboard | End-to-end shipment tracking and on-time delivery KPIs |
| 02 | Sales Performance | Regional sales breakdown with trend analysis |
| 03 | Customer Segmentation | RFM segmentation visualized by cluster |
| 04 | Supply Chain Map | Geographic flow map of supply chain network |
| 05 | Financial Overview | Revenue, cost and margin summary for management |

---

### 📈 Power BI

| # | Project | Description |
|---|---|---|
| 01 | Warehouse KPIs | Fill rate, turnover, accuracy - warehouse operations report |
| 02 | Procurement Analysis | Spend analysis by category, supplier and period |
| 03 | Project Tracking | Gantt-style project progress with milestone tracking |
| 04 | HR Headcount | Headcount evolution, turnover and department breakdown |
| 05 | Operational Costs | Cost center analysis with drill-through by category |

---

### 🗄️ SQL

| # | Project | Description |
|---|---|---|
| 01 | Inventory Queries | Stock level queries, reorder alerts, dead stock detection |
| 02 | Sales Reporting | Revenue aggregation, growth rates, top products |
| 03 | Customer Analysis | Purchase frequency, lifetime value, retention rate |
| 04 | Supply Chain Queries | Lead time analysis, supplier performance |
| 05 | Data Cleaning | Deduplication, null handling, type normalization |

---

### 🤖 Machine Learning

| # | Project | Description |
|---|---|---|
| 01 | Demand Forecasting | Time series model to predict future demand |
| 02 | Anomaly Detection | Detect outliers in operational or sensor data |
| 03 | Classification Model | Binary classification for risk or failure prediction |
| 04 | Customer Clustering | Unsupervised segmentation using K-Means |
| 05 | Regression Analysis | Predict continuous variable (cost, time, quantity) |

---

## 🚀 Getting Started

### Prerequisites

- Python 3.9+
- pip or conda
- Power BI Desktop (for .pbix files)
- Tableau Public or Tableau Desktop (for .twbx files)

### Python setup

```bash
git clone https://github.com/Gainciarte/data_analysis_projects.git
cd data_analysis_projects
pip install -r requirements.txt
```

---

## 📌 Notes

- Each project folder contains its own `README.md` with objective, data source, methodology and results.
- Raw data files are **not included** in this repository due to file size. Each project README links to the original data source.
- Datasets used are either publicly available or anonymized synthetic data.
- Projects are added progressively - check back for updates.
- Excel 01: Stock Status analysis was excluded as the dataset contains sales data only, not inventory levels. This limitation is documented in the project README.
- Excel 03: renamed from Demand Forecast to Inventory Parameters to better reflect the actual analysis performed.

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

---

## 👤 Author

**Gustavo Inciarte**
Mechanical Engineer | Data & Logistics Analyst
[LinkedIn](https://linkedin.com/in/gainciarte) · [GitHub](https://github.com/Gainciarte)

---

*This portfolio is part of an ongoing professional development initiative focused on data analysis applied to logistics, supply chain and operations.*
