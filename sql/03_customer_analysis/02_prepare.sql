-- ============================================================
-- SQL 03 - Customer Analysis | 02_prepare.sql
-- Builds the analysis layer from the raw lines:
--   sales_lines  = valid product sales attributable to a known customer
--   orders       = one row per invoice
--   v_customer_rfm = Recency / Frequency / Monetary scores with NTILE
-- ============================================================

DROP VIEW  IF EXISTS v_customer_rfm, v_customer_summary CASCADE;
DROP TABLE IF EXISTS customer_first_order, orders, sales_lines CASCADE;

-- Valid sales lines. Excluded: cancellations ('C...'), non-positive qty/price,
-- guest checkouts (no customer id) and non-product stock codes (POST, DOT, M, BANK CHARGES, ...)
CREATE TABLE sales_lines AS
SELECT invoice,
       stock_code,
       description,
       quantity,
       invoice_ts,
       invoice_ts::date                  AS invoice_date,
       unit_price,
       ROUND(quantity * unit_price, 2)   AS line_amount,
       customer_id,
       country
FROM raw_transactions
WHERE invoice !~ '^[A-Za-z]'               -- plain numeric invoices only (drops 'C' credit notes and 'A' adjustments)
  AND quantity > 0
  AND unit_price > 0
  AND customer_id IS NOT NULL
  AND stock_code ~ '^[0-9]{5}';            -- real product codes start with 5 digits

CREATE INDEX idx_sales_lines_customer ON sales_lines (customer_id, invoice_date);
CREATE INDEX idx_sales_lines_invoice  ON sales_lines (invoice);
CREATE INDEX idx_sales_lines_date     ON sales_lines (invoice_date);

-- One row per invoice (a customer has exactly one country in an invoice)
CREATE TABLE orders AS
SELECT invoice,
       customer_id,
       MIN(invoice_date)                   AS order_date,
       MIN(country)                        AS country,
       COUNT(*)                            AS lines,
       SUM(quantity)                       AS units,
       ROUND(SUM(line_amount), 2)          AS order_value
FROM sales_lines
GROUP BY invoice, customer_id;

ALTER TABLE orders ADD PRIMARY KEY (invoice);
CREATE INDEX idx_orders_customer ON orders (customer_id, order_date);
CREATE INDEX idx_orders_date     ON orders (order_date);

-- First order month per customer (cohort definition)
CREATE TABLE customer_first_order AS
SELECT customer_id,
       MIN(order_date)                                   AS first_order_date,
       date_trunc('month', MIN(order_date))::date        AS cohort_month
FROM orders
GROUP BY customer_id;

ALTER TABLE customer_first_order ADD PRIMARY KEY (customer_id);

-- Customer-level totals
CREATE VIEW v_customer_summary AS
SELECT o.customer_id,
       COUNT(*)                                  AS orders,
       SUM(o.order_value)                        AS revenue,
       ROUND(AVG(o.order_value), 2)              AS avg_order_value,
       MIN(o.order_date)                         AS first_order_date,
       MAX(o.order_date)                         AS last_order_date
FROM orders o
GROUP BY o.customer_id;

-- RFM scoring. Snapshot = last invoice date + 1 day.
-- NTILE(5): 5 = best. Recency: fewer days is better, so it is ordered DESC.
CREATE VIEW v_customer_rfm AS
WITH snap AS (
    SELECT MAX(order_date) + 1 AS snapshot_date FROM orders
),
base AS (
    SELECT s.customer_id,
           (snap.snapshot_date - s.last_order_date)  AS recency_days,
           s.orders                                  AS frequency,
           s.revenue                                 AS monetary
    FROM v_customer_summary s
    CROSS JOIN snap
),
scored AS (
    SELECT *,
           NTILE(5) OVER (ORDER BY recency_days DESC, customer_id) AS r_score,
           NTILE(5) OVER (ORDER BY frequency,        customer_id)  AS f_score,
           NTILE(5) OVER (ORDER BY monetary,         customer_id)  AS m_score
    FROM base
)
SELECT *,
       r_score::text || f_score::text || m_score::text AS rfm_code,
       CASE
           WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
           WHEN r_score >= 3 AND f_score >= 4                  THEN 'Loyal Customers'
           WHEN r_score >= 4 AND f_score <= 2                  THEN 'New / Promising'
           WHEN r_score >= 3 AND f_score = 3                   THEN 'Potential Loyalists'
           WHEN r_score <= 2 AND f_score >= 4                  THEN 'At Risk (high value)'
           WHEN r_score = 1  AND f_score <= 2                  THEN 'Lost'
           WHEN r_score <= 2                                   THEN 'Hibernating'
           ELSE 'Needs Attention'
       END AS segment
FROM scored;

ANALYZE;
