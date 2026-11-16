-- ============================================================
-- SQL 02 - Sales Reporting | 03_views.sql
-- Reporting layer: enriched views + materialized views (with unique indexes).
--   retail.v_sales_enriched      SALE lines joined to every dimension
--   retail.mv_monthly_revenue    monthly KPIs (gross, cancellations, orders, customers, partial-month flag)
--   retail.mv_product_revenue    revenue / units / orders / returns per product
--   amazon.v_orders_enriched     order lines joined to every dimension (repaired dates)
--   amazon.mv_daily_sales        daily KPIs
-- ============================================================

DROP VIEW IF EXISTS retail.v_sales_enriched CASCADE;
DROP MATERIALIZED VIEW IF EXISTS retail.mv_monthly_revenue CASCADE;
DROP MATERIALIZED VIEW IF EXISTS retail.mv_product_revenue CASCADE;
DROP VIEW IF EXISTS amazon.v_orders_enriched CASCADE;
DROP MATERIALIZED VIEW IF EXISTS amazon.mv_daily_sales CASCADE;

-- ---------------------------- RETAIL ----------------------------
CREATE VIEW retail.v_sales_enriched AS
SELECT f.line_id,
       f.invoice,
       f.invoice_ts,
       f.invoice_date,
       f.invoice_hour,
       d.year,
       d.quarter,
       d.year_month,
       d.month_start,
       d.fy,
       d.weekday,
       d.iso_weekday,
       f.stock_code,
       p.description,
       c.country,
       f.customer_id,
       f.quantity,
       f.unit_price,
       f.line_amount
FROM retail.fact_lines f
JOIN retail.dim_date    d ON d.date_id    = f.invoice_date
JOIN retail.dim_product p ON p.stock_code = f.stock_code
JOIN retail.dim_country c ON c.country_id = f.country_id
WHERE f.line_type = 'SALE';

-- is_partial = the month is not fully covered by the data (first / last month of the dataset)
CREATE MATERIALIZED VIEW retail.mv_monthly_revenue AS
SELECT d.month_start,
       d.year_month,
       d.year,
       d.quarter,
       d.quarter_start,
       SUM(f.line_amount)              FILTER (WHERE f.line_type = 'SALE')         AS revenue,
       COUNT(DISTINCT f.invoice)       FILTER (WHERE f.line_type = 'SALE')         AS orders,
       SUM(f.quantity)                 FILTER (WHERE f.line_type = 'SALE')         AS units,
       COUNT(DISTINCT f.customer_id)   FILTER (WHERE f.line_type = 'SALE')         AS customers,
       COALESCE(SUM(f.line_amount)     FILTER (WHERE f.line_type = 'CANCELLATION'), 0) AS returns_amount,   -- negative
       COUNT(DISTINCT f.invoice)       FILTER (WHERE f.line_type = 'CANCELLATION') AS cancel_invoices,
       COALESCE(-SUM(f.quantity)       FILTER (WHERE f.line_type = 'CANCELLATION'), 0) AS units_cancelled,
       (d.month_start < b.first_date OR d.month_end > b.last_date)                 AS is_partial
FROM retail.fact_lines f
JOIN retail.dim_date d ON d.date_id = f.invoice_date
CROSS JOIN (SELECT MIN(invoice_date) AS first_date, MAX(invoice_date) AS last_date FROM retail.fact_lines) b
GROUP BY d.month_start, d.year_month, d.year, d.quarter, d.quarter_start, d.month_end, b.first_date, b.last_date;

CREATE UNIQUE INDEX ux_mv_monthly_revenue ON retail.mv_monthly_revenue (month_start);

CREATE MATERIALIZED VIEW retail.mv_product_revenue AS
SELECT f.stock_code,
       p.description,
       SUM(f.line_amount)            FILTER (WHERE f.line_type = 'SALE')         AS revenue,
       SUM(f.quantity)               FILTER (WHERE f.line_type = 'SALE')         AS units,
       COUNT(DISTINCT f.invoice)     FILTER (WHERE f.line_type = 'SALE')         AS orders,
       COALESCE(SUM(f.line_amount)   FILTER (WHERE f.line_type = 'CANCELLATION'), 0) AS returns_amount,
       MIN(f.invoice_date)           FILTER (WHERE f.line_type = 'SALE')         AS first_sale_date,
       MAX(f.invoice_date)           FILTER (WHERE f.line_type = 'SALE')         AS last_sale_date
FROM retail.fact_lines f
JOIN retail.dim_product p ON p.stock_code = f.stock_code
WHERE p.product_kind = 'PRODUCT'
GROUP BY f.stock_code, p.description
HAVING SUM(f.line_amount) FILTER (WHERE f.line_type = 'SALE') IS NOT NULL;

CREATE UNIQUE INDEX ux_mv_product_revenue ON retail.mv_product_revenue (stock_code);
CREATE INDEX idx_mv_product_revenue_rev ON retail.mv_product_revenue (revenue DESC);

-- ---------------------------- AMAZON ----------------------------
CREATE VIEW amazon.v_orders_enriched AS
SELECT f.line_id,
       f.order_date,
       d.year_month,
       d.week_start,
       d.weekday,
       d.iso_weekday,
       f.sku,
       p.style_code,
       c.category,
       f.size,
       s.size_order,
       f.qty,
       f.amount
FROM amazon.fact_order_lines f
JOIN amazon.dim_date     d ON d.date_id     = f.order_date
JOIN amazon.dim_product  p ON p.sku         = f.sku
JOIN amazon.dim_category c ON c.category_id = p.category_id
JOIN amazon.dim_size     s ON s.size        = f.size;

CREATE MATERIALIZED VIEW amazon.mv_daily_sales AS
SELECT d.date_id AS order_date,
       d.year_month,
       d.week_start,
       d.weekday,
       d.iso_weekday,
       COUNT(*)              AS order_lines,
       SUM(f.qty)            AS units,
       SUM(f.amount)         AS revenue,
       COUNT(DISTINCT f.sku) AS skus_sold
FROM amazon.fact_order_lines f
JOIN amazon.dim_date d ON d.date_id = f.order_date
GROUP BY d.date_id, d.year_month, d.week_start, d.weekday, d.iso_weekday;

CREATE UNIQUE INDEX ux_mv_daily_sales ON amazon.mv_daily_sales (order_date);
