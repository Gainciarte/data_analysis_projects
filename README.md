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
└── python/
    ├── 01_sales_eda/
    ├── 02_inventory_optimization/
    ├── 03_web_scraping/
    ├── 04_etl_pipeline/
    └── 05_predictive_maintenance/
```

See [Roadmap](#️-roadmap) below for planned additions (Tableau, Power BI, SQL, Machine Learning).

---

## 🔧 Tools & Technologies (in use)

| Category | Tools |
|---|---|
| Spreadsheets | Microsoft Excel (Advanced), Power Query |
| Programming | Python (pandas, numpy, scipy, matplotlib, seaborn, requests, BeautifulSoup, sqlalchemy) |
| Databases | SQLite |
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
| 01 | Sales EDA | Exploratory data analysis on Amazon India sales dataset to identify consumption patterns, discount effectiveness, and customer satisfaction | pandas, matplotlib, seaborn |
| 02 | Inventory Optimization | Calculate optimal inventory parameters (EOQ, Safety Stock, Reorder Point) for 303 SKUs using 2.5 years of sales data with ABC classification and risk assessment | pandas, numpy, scipy, matplotlib, seaborn |
| 03 | Web Scraping | Extract, clean and analyze book data from public e-commerce website. Demonstrates HTTP requests, HTML parsing with BeautifulSoup, pagination handling, and data export | requests, BeautifulSoup, pandas |
| 04 | ETL Pipeline | End-to-end ETL pipeline on a 9-file relational e-commerce dataset (Olist, 100K orders). Covers multi-source extraction, datetime correction, null handling, feature engineering, category translation, SQLite loading via SQLAlchemy, and business SQL queries | pandas, numpy, sqlalchemy |
| 05 | Predictive Maintenance | Binary classification of machine failure on 10,000 industrial sensor records under severe class imbalance (3.39%). Compares Logistic Regression vs. Random Forest (ROC-AUC 0.978, PR-AUC 0.863) with feature importance analysis | pandas, numpy, scikit-learn, matplotlib, seaborn |

---

## 🚀 Getting Started

### Prerequisites

- Python 3.9+
- pip or conda

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
- Excel 01: Stock Status analysis was excluded as the dataset contains sales data only, not inventory levels. This limitation is documented in the project README.

---

## 🗺️ Roadmap

Planned expansions — not started yet, listed here separately so the structure above only reflects what's actually built:

- **Tableau**: Logistics Dashboard, Sales Performance, Customer Segmentation, Supply Chain Map, Financial Overview.
- **Power BI**: Warehouse KPIs, Procurement Analysis, Project Tracking, HR Headcount, Operational Costs.
- **SQL** (MySQL/PostgreSQL): Inventory Queries, Sales Reporting, Customer Analysis, Supply Chain Queries, Data Cleaning.
- **Machine Learning** (scikit-learn, statsmodels): Demand Forecasting, Anomaly Detection, Classification Model, Customer Clustering, Regression Analysis.

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
| Python 05 - Predictive Maintenance | AI4I 2020 Predictive Maintenance Dataset | [UCI ML Repository](https://archive.ics.uci.edu/dataset/601/ai4i+2020+predictive+maintenance+dataset) |

---

## 👤 Author

**Gustavo Inciarte**
Mechanical Engineer | Data & Logistics Analyst
[LinkedIn](https://linkedin.com/in/gainciarte) · [GitHub](https://github.com/Gainciarte)

---

*This portfolio is part of an ongoing professional development initiative focused on data analysis applied to logistics, supply chain and operations.*
