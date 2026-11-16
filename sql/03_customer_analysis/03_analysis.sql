-- ============================================================
-- SQL 03 - Customer Analysis | 03_analysis.sql
-- Run top to bottom. "-- [name] title" labels each query; every result set
-- is saved to results/<name>.csv by run_customer_analysis.py
-- ============================================================

-- [q01_data_funnel] Data funnel: raw lines -> valid customer sales lines (why rows were excluded)
SELECT step, rows_kept
FROM (
    SELECT 1 AS n, 'raw transaction lines'                                        AS step, COUNT(*) AS rows_kept FROM raw_transactions
    UNION ALL SELECT 2, 'minus cancellations / adjustments (invoice starts with a letter)',
                         COUNT(*) FROM raw_transactions WHERE invoice !~ '^[A-Za-z]'
    UNION ALL SELECT 3, 'minus non-positive quantity or price',
                         COUNT(*) FROM raw_transactions WHERE invoice !~ '^[A-Za-z]' AND quantity > 0 AND unit_price > 0
    UNION ALL SELECT 4, 'minus guest checkouts (no customer id)',
                         COUNT(*) FROM raw_transactions WHERE invoice !~ '^[A-Za-z]' AND quantity > 0 AND unit_price > 0
                                                          AND customer_id IS NOT NULL
    UNION ALL SELECT 5, 'minus non-product stock codes (POST, DOT, M, BANK CHARGES ...) = sales_lines',
                         COUNT(*) FROM sales_lines
) f
ORDER BY n;

-- [q02_headline] Headline customer KPIs
SELECT COUNT(DISTINCT customer_id)                              AS customers,
       COUNT(*)                                                 AS orders,
       ROUND(SUM(order_value))::bigint                          AS revenue,
       ROUND(AVG(order_value), 2)                               AS avg_order_value,
       ROUND(COUNT(*)::numeric / COUNT(DISTINCT customer_id), 2) AS orders_per_customer,
       COUNT(DISTINCT country)                                  AS countries,
       MIN(order_date)::text                                    AS first_order,
       MAX(order_date)::text                                    AS last_order
FROM orders;

-- [q03_monthly_new_vs_returning] Monthly active customers: new vs returning (window MIN over customer)
WITH monthly AS (
    SELECT date_trunc('month', o.order_date)::date AS month,
           o.customer_id,
           SUM(o.order_value)                      AS revenue,
           f.cohort_month
    FROM orders o
    JOIN customer_first_order f USING (customer_id)
    GROUP BY 1, o.customer_id, f.cohort_month
)
SELECT TO_CHAR(month, 'YYYY-MM')                                     AS month,
       COUNT(*)                                                      AS active_customers,
       COUNT(*) FILTER (WHERE cohort_month = month)                  AS new_customers,
       COUNT(*) FILTER (WHERE cohort_month < month)                  AS returning_customers,
       ROUND(100.0 * COUNT(*) FILTER (WHERE cohort_month < month) / COUNT(*), 1) AS pct_returning,
       ROUND(SUM(revenue))::bigint                                   AS revenue
FROM monthly
GROUP BY month
ORDER BY month;

-- [q04_rfm_segments] RFM segments (NTILE(5) scores): size, revenue and behaviour
SELECT segment,
       COUNT(*)                                                      AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)            AS pct_customers,
       ROUND(SUM(monetary))::bigint                                  AS revenue,
       ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1)  AS pct_revenue,
       ROUND(AVG(recency_days))                                      AS avg_recency_days,
       ROUND(AVG(frequency), 1)                                      AS avg_orders,
       ROUND(AVG(monetary))                                          AS avg_spend
FROM v_customer_rfm
GROUP BY segment
ORDER BY revenue DESC;

-- [q05_rfm_score_distribution] Average spend and orders by R score x F score (heat-map input)
SELECT r_score, f_score,
       COUNT(*)                         AS customers,
       ROUND(AVG(monetary))             AS avg_spend,
       ROUND(AVG(frequency), 1)         AS avg_orders
FROM v_customer_rfm
GROUP BY r_score, f_score
ORDER BY r_score DESC, f_score DESC;

-- [q06_revenue_deciles] Customer value deciles (NTILE(10)) and share of revenue
WITH d AS (
    SELECT customer_id, revenue, NTILE(10) OVER (ORDER BY revenue DESC) AS decile
    FROM v_customer_summary
)
SELECT decile,
       COUNT(*)                                                        AS customers,
       ROUND(SUM(revenue))::bigint                                     AS revenue,
       ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1)      AS pct_revenue,
       ROUND(100.0 * SUM(SUM(revenue)) OVER (ORDER BY decile) / SUM(SUM(revenue)) OVER (), 1) AS cum_pct_revenue,
       ROUND(AVG(revenue))                                             AS avg_revenue
FROM d
GROUP BY decile
ORDER BY decile;

-- [q07_repeat_purchase] Repeat purchase rate and order-count distribution
WITH c AS (
    SELECT customer_id, orders,
           CASE WHEN orders = 1 THEN '1) 1 order'
                WHEN orders = 2 THEN '2) 2 orders'
                WHEN orders BETWEEN 3 AND 5 THEN '3) 3-5 orders'
                WHEN orders BETWEEN 6 AND 10 THEN '4) 6-10 orders'
                ELSE '5) 11+ orders' END AS order_bucket
    FROM v_customer_summary
)
SELECT order_bucket,
       COUNT(*)                                                           AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)                 AS pct_customers,
       ROUND(100.0 * SUM(COUNT(*)) FILTER (WHERE order_bucket <> '1) 1 order') OVER ()
                   / SUM(COUNT(*)) OVER (), 1)                            AS repeat_rate_pct
FROM c
GROUP BY order_bucket
ORDER BY order_bucket;

-- [q08_days_between_orders] Time between consecutive orders of repeat customers (LAG)
WITH gaps AS (
    SELECT customer_id, order_date,
           order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date, invoice) AS gap_days
    FROM orders
)
SELECT COUNT(*)                                                                   AS repeat_orders,
       ROUND(AVG(gap_days), 1)                                                    AS avg_gap_days,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap_days)                      AS median_gap_days,
       COUNT(*) FILTER (WHERE gap_days = 0)                                       AS same_day_orders,
       ROUND(100.0 * COUNT(*) FILTER (WHERE gap_days <= 30) / COUNT(*), 1)        AS pct_within_30_days
FROM gaps
WHERE gap_days IS NOT NULL;

-- [q09_clv_by_cohort_year] Historical customer lifetime value by first-order half-year cohort
SELECT TO_CHAR(f.cohort_month, 'YYYY') || '-H' || CASE WHEN EXTRACT(MONTH FROM f.cohort_month) <= 6 THEN '1' ELSE '2' END AS cohort_half,
       COUNT(*)                                       AS customers,
       ROUND(AVG(s.revenue))                          AS avg_clv_to_date,
       ROUND(AVG(s.orders), 1)                        AS avg_orders,
       ROUND(AVG(s.avg_order_value))                  AS avg_order_value,
       ROUND(100.0 * COUNT(*) FILTER (WHERE s.orders >= 2) / COUNT(*), 1) AS repeat_rate_pct
FROM customer_first_order f
JOIN v_customer_summary s USING (customer_id)
GROUP BY 1
ORDER BY 1;

-- [q10_clv_projection] Simple projected CLV: annual revenue per active customer x retention / (1 - retention)
-- Year 1 = 2009-12-01..2010-11-30, Year 2 = 2010-12-01..2011-11-30 (Dec-2011 is a partial month and excluded)
WITH y1 AS (
    SELECT customer_id, SUM(order_value) AS revenue
    FROM orders WHERE order_date BETWEEN DATE '2009-12-01' AND DATE '2010-11-30'
    GROUP BY customer_id
),
y2 AS (
    SELECT customer_id, SUM(order_value) AS revenue
    FROM orders WHERE order_date BETWEEN DATE '2010-12-01' AND DATE '2011-11-30'
    GROUP BY customer_id
)
SELECT (SELECT COUNT(*) FROM y1)                                                      AS customers_year1,
       COUNT(*)                                                                       AS retained_in_year2,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM y1), 1)                         AS annual_retention_pct,
       ROUND((SELECT AVG(revenue) FROM y1))                                           AS avg_annual_revenue_year1,
       ROUND(AVG(y2.revenue))                                                         AS avg_annual_revenue_retained_year2,
       ROUND((SELECT AVG(revenue) FROM y1)
             * (COUNT(*)::numeric / (SELECT COUNT(*) FROM y1))
             / (1 - COUNT(*)::numeric / (SELECT COUNT(*) FROM y1)))                   AS projected_clv
FROM y1
JOIN y2 USING (customer_id);

-- [q11_cohort_retention] Monthly cohort retention (% of the cohort ordering again after N months) - first 12 cohorts, months 0-6 and 12
WITH activity AS (
    SELECT DISTINCT o.customer_id, f.cohort_month,
           (EXTRACT(YEAR FROM date_trunc('month', o.order_date)) - EXTRACT(YEAR FROM f.cohort_month)) * 12
         + (EXTRACT(MONTH FROM date_trunc('month', o.order_date)) - EXTRACT(MONTH FROM f.cohort_month)) AS month_offset
    FROM orders o
    JOIN customer_first_order f USING (customer_id)
),
sizes AS (
    SELECT cohort_month, COUNT(*) AS cohort_size FROM customer_first_order GROUP BY cohort_month
)
SELECT TO_CHAR(a.cohort_month, 'YYYY-MM')                                                        AS cohort,
       s.cohort_size,
       ROUND(100.0 * COUNT(*) FILTER (WHERE month_offset = 1)  / s.cohort_size, 1)               AS m1_pct,
       ROUND(100.0 * COUNT(*) FILTER (WHERE month_offset = 2)  / s.cohort_size, 1)               AS m2_pct,
       ROUND(100.0 * COUNT(*) FILTER (WHERE month_offset = 3)  / s.cohort_size, 1)               AS m3_pct,
       ROUND(100.0 * COUNT(*) FILTER (WHERE month_offset = 6)  / s.cohort_size, 1)               AS m6_pct,
       ROUND(100.0 * COUNT(*) FILTER (WHERE month_offset = 12) / s.cohort_size, 1)               AS m12_pct
FROM activity a
JOIN sizes s USING (cohort_month)
GROUP BY a.cohort_month, s.cohort_size
ORDER BY a.cohort_month
LIMIT 12;

-- [q12_cohort_matrix] Full cohort triangle in long format (used for the heat-map image)
WITH activity AS (
    SELECT DISTINCT o.customer_id, f.cohort_month,
           ((EXTRACT(YEAR FROM date_trunc('month', o.order_date)) - EXTRACT(YEAR FROM f.cohort_month)) * 12
          + (EXTRACT(MONTH FROM date_trunc('month', o.order_date)) - EXTRACT(MONTH FROM f.cohort_month)))::int AS month_offset
    FROM orders o
    JOIN customer_first_order f USING (customer_id)
),
sizes AS (
    SELECT cohort_month, COUNT(*) AS cohort_size FROM customer_first_order GROUP BY cohort_month
)
SELECT TO_CHAR(a.cohort_month, 'YYYY-MM')                          AS cohort,
       a.month_offset,
       COUNT(*)                                                    AS active_customers,
       ROUND(100.0 * COUNT(*) / s.cohort_size, 1)                  AS retention_pct
FROM activity a
JOIN sizes s USING (cohort_month)
WHERE a.month_offset <= 12
GROUP BY a.cohort_month, a.month_offset, s.cohort_size
ORDER BY a.cohort_month, a.month_offset;

-- [q13_country_mix] Customers and revenue by country (top 8) with share of total
SELECT country,
       COUNT(DISTINCT customer_id)                                    AS customers,
       COUNT(*)                                                       AS orders,
       ROUND(SUM(order_value))::bigint                                AS revenue,
       ROUND(100.0 * SUM(order_value) / SUM(SUM(order_value)) OVER (), 1) AS pct_revenue,
       ROUND(AVG(order_value))                                        AS avg_order_value
FROM orders
GROUP BY country
ORDER BY revenue DESC
LIMIT 8;

-- [q14_top_customers] Top 10 customers by revenue (RANK) with their RFM segment
SELECT RANK() OVER (ORDER BY s.revenue DESC)   AS rnk,
       s.customer_id,
       ROUND(s.revenue)::bigint                AS revenue,
       s.orders,
       ROUND(s.avg_order_value)                AS avg_order_value,
       r.recency_days,
       r.rfm_code,
       r.segment
FROM v_customer_summary s
JOIN v_customer_rfm r USING (customer_id)
ORDER BY rnk
LIMIT 10;

-- [q15_validation] Reconciliation checks
SELECT (SELECT ROUND(SUM(line_amount)) FROM sales_lines)                         AS lines_revenue,
       (SELECT ROUND(SUM(order_value)) FROM orders)                              AS orders_revenue,
       (SELECT ROUND(SUM(monetary)) FROM v_customer_rfm)                         AS rfm_revenue,
       (SELECT COUNT(*) FROM v_customer_rfm)                                     AS rfm_customers,
       (SELECT COUNT(*) FROM customer_first_order)                               AS cohort_customers,
       (SELECT COUNT(*) FROM sales_lines WHERE customer_id IS NULL)              AS lines_without_customer;

-- [q16_returns_impact] Gross vs net revenue: credit notes (invoice 'C...') of known customers on product codes
WITH x AS (
    SELECT * FROM raw_transactions
    WHERE customer_id IS NOT NULL AND stock_code ~ '^[0-9]{5}'
)
SELECT ROUND(SUM(quantity * unit_price) FILTER (WHERE invoice !~ '^[A-Za-z]' AND quantity > 0 AND unit_price > 0))  AS gross_sales,
       ROUND(-SUM(quantity * unit_price) FILTER (WHERE invoice LIKE 'C%'))                                          AS credit_notes,
       ROUND(100.0 * -SUM(quantity * unit_price) FILTER (WHERE invoice LIKE 'C%')
             / SUM(quantity * unit_price) FILTER (WHERE invoice !~ '^[A-Za-z]' AND quantity > 0 AND unit_price > 0), 1) AS credit_notes_pct_of_gross,
       COUNT(DISTINCT customer_id) FILTER (WHERE invoice LIKE 'C%')                                                 AS customers_with_credit_notes
FROM x;
