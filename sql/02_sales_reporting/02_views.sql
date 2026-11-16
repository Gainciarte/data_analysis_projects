-- ============================================================
-- SQL 02 - Sales Reporting | 02_views.sql
-- ============================================================

-- Fact table joined to every dimension (one place for business logic)
CREATE OR REPLACE VIEW v_sales_enriched AS
SELECT s.order_number, s.order_date,
       d.year, d.quarter, d.month, d.year_month, d.weekday, d.iso_weekday,
       s.sku_id, k.sku_name,
       s.warehouse_id, w.city, w.province,
       s.customer_type,
       s.order_qty, s.unit_sale_price, s.revenue
FROM sales s
JOIN dim_date   d ON d.date_id = s.order_date
JOIN sku_items  k ON k.sku_id = s.sku_id
JOIN warehouses w ON w.warehouse_id = s.warehouse_id;

-- Monthly KPI table - materialized because every report starts here
DROP MATERIALIZED VIEW IF EXISTS mv_monthly_sales;
CREATE MATERIALIZED VIEW mv_monthly_sales AS
SELECT date_trunc('month', order_date)::date AS month_start,
       year_month,
       year,
       month,
       COUNT(*)                         AS orders,
       SUM(order_qty)                   AS units,
       SUM(revenue)                     AS revenue,
       ROUND(SUM(revenue) / COUNT(*), 2) AS avg_order_value,
       COUNT(DISTINCT sku_id)           AS active_skus
FROM v_sales_enriched
GROUP BY 1, 2, 3, 4;

CREATE UNIQUE INDEX idx_mv_monthly_sales ON mv_monthly_sales (month_start);
