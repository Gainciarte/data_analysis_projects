# Power BI Projects

Five dashboards built as **Power BI Projects (.pbip)**: the semantic model (tables, relationships, DAX measures) is stored as TMDL text and the report (pages, visuals) as PBIR JSON, so every change is reviewable in Git.

| # | Project | Dataset | Pages | Highlights |
|---|---|---|---|---|
| 01 | [Warehouse KPIs](01_warehouse_kpis) | Kaizen inventory and sales (synthetic) | 2 | stock value, cover vs lead time, overstock, turnover |
| 02 | [Procurement Analysis](02_procurement_analysis) | USAID SCMS shipments | 2 | spend, vendor concentration, sourcing route, freight, delivery |
| 03 | [Project Tracking](03_project_tracking) | USAID SCMS shipments | 2 | on-time %, schedule-variance buckets, worst project codes |
| 04 | [HR Headcount](04_hr_headcount) | IBM HR Analytics (fictional) | 2 | headcount profile, attrition drivers |
| 05 | [Operational Costs](05_operational_costs) | USAID SCMS shipments | 2 | freight and insurance by mode, weight band, country |

Common points:

- Data is read from CSV files inside each project's `data/` folder through a single `DataFolder` Power Query parameter (see each README for how to point it to your local path).
- Every headline number in the READMEs was recomputed independently with pandas; the script and its output are in `verify_numbers.py` and `verified_numbers.txt`.
- Screenshots in each project's `images/` folder are exported from Power BI Desktop itself.
- Datasets that look synthetic or fictional (Kaizen, IBM HR) are flagged as such in the project README.
