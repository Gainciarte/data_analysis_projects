-- ============================================================
-- SQL 02 - Sales Reporting | 04_reports_retail.sql
-- Management reports on UCI Online Retail II (GBP). Each statement is labelled
-- '-- [name] title'; run_sales_reporting.py saves every result as results/<name>.csv.
-- "revenue" = gross revenue of valid SALE lines; cancellations are shown separately (see 02_model.sql).
-- Growth rates are left NULL when a month / quarter / year is not fully covered by the data.
-- ============================================================

-- [q01_data_funnel] What every raw line became (line_type) - nothing is dropped silently
SELECT line_type,
       COUNT(*)                                         AS lines,
       COUNT(DISTINCT invoice)                          AS invoices,
       SUM(line_amount)                                 AS amount,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_lines
FROM retail.fact_lines
GROUP BY line_type
ORDER BY lines DESC;

-- [q02_non_product_codes] Non-product stock codes kept out of revenue (top 12 by absolute amount)
SELECT f.stock_code,
       p.description,
       COUNT(*)                AS lines,
       SUM(f.line_amount)      AS amount,
       RANK() OVER (ORDER BY SUM(ABS(f.line_amount)) DESC) AS abs_amount_rank
FROM retail.fact_lines f
JOIN retail.dim_product p USING (stock_code)
WHERE f.line_type = 'NON_PRODUCT'
GROUP BY f.stock_code, p.description
ORDER BY abs_amount_rank
LIMIT 12;

-- [q03_headline] Headline KPIs: gross, cancellations, net, orders, average order value
SELECT MIN(invoice_date) FILTER (WHERE line_type = 'SALE')                           AS first_date,
       MAX(invoice_date) FILTER (WHERE line_type = 'SALE')                           AS last_date,
       SUM(line_amount)  FILTER (WHERE line_type = 'SALE')                           AS gross_revenue,
       SUM(line_amount)  FILTER (WHERE line_type = 'CANCELLATION')                   AS cancellations,
       SUM(line_amount)  FILTER (WHERE line_type IN ('SALE', 'CANCELLATION'))        AS net_revenue,
       ROUND(-100.0 * SUM(line_amount) FILTER (WHERE line_type = 'CANCELLATION')
             / SUM(line_amount) FILTER (WHERE line_type = 'SALE'), 2)                AS cancellation_pct,
       COUNT(DISTINCT invoice) FILTER (WHERE line_type = 'SALE')                     AS orders,
       SUM(quantity)     FILTER (WHERE line_type = 'SALE')                           AS units,
       ROUND(SUM(line_amount) FILTER (WHERE line_type = 'SALE')
             / COUNT(DISTINCT invoice) FILTER (WHERE line_type = 'SALE'), 2)         AS avg_order_value,
       COUNT(DISTINCT stock_code)  FILTER (WHERE line_type = 'SALE')                 AS products_sold,
       COUNT(DISTINCT customer_id) FILTER (WHERE line_type = 'SALE')                 AS identified_customers,
       ROUND(100.0 * SUM(line_amount) FILTER (WHERE line_type = 'SALE' AND customer_id IS NULL)
             / SUM(line_amount) FILTER (WHERE line_type = 'SALE'), 2)                AS guest_revenue_pct
FROM retail.fact_lines;

-- [q04_yearly_yoy] Revenue per business year (Dec-Nov) with YoY growth (LAG); the last year is only 9 days
WITH y AS (
    SELECT d.fy,
           MIN(d.date_id) AS first_day_in_data,
           MAX(d.date_id) AS last_day_in_data,
           SUM(v.line_amount)           AS revenue,
           COUNT(DISTINCT v.invoice)    AS orders,
           COUNT(DISTINCT v.customer_id) AS customers,
           COUNT(DISTINCT v.invoice_date) AS trading_days,
           -- complete = the data covers the whole Dec 1 .. Nov 30 year
           (MIN(v.invoice_date) <= make_date(d.fy - 1, 12, 1) + 6
            AND MAX(v.invoice_date) >= make_date(d.fy, 11, 30) - 6) AS is_complete
    FROM retail.v_sales_enriched v
    JOIN retail.dim_date d ON d.date_id = v.invoice_date
    GROUP BY d.fy
)
SELECT fy,
       first_day_in_data AS first_sale,
       last_day_in_data  AS last_sale,
       trading_days,
       orders,
       customers,
       revenue,
       ROUND(revenue / orders, 2) AS avg_order_value,
       CASE WHEN is_complete AND LAG(is_complete) OVER (ORDER BY fy)
            THEN ROUND(100 * (revenue / LAG(revenue) OVER (ORDER BY fy) - 1), 1) END AS yoy_pct,
       is_complete
FROM y
ORDER BY fy;

-- [q05_monthly_mom] Monthly revenue: MoM (LAG 1), YoY (LAG 12), calendar YTD running total, 3-month moving average
WITH m AS (
    SELECT month_start, year_month, year, revenue, orders, returns_amount, is_partial,
           LAG(revenue)     OVER w AS prev_month,
           LAG(revenue, 12) OVER w AS prev_year,
           SUM(revenue) OVER (PARTITION BY year ORDER BY month_start)                             AS ytd_revenue,
           AVG(revenue) OVER (ORDER BY month_start ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)       AS ma3
    FROM retail.mv_monthly_revenue
    WINDOW w AS (ORDER BY month_start)
)
SELECT year_month,
       revenue,
       orders,
       ROUND(revenue / orders, 2)                                  AS avg_order_value,
       returns_amount                                              AS cancellations,
       revenue + returns_amount                                    AS net_revenue,
       CASE WHEN NOT is_partial THEN ROUND(100 * (revenue / prev_month - 1), 1) END AS mom_pct,
       CASE WHEN NOT is_partial THEN ROUND(100 * (revenue / prev_year  - 1), 1) END AS yoy_pct,
       ytd_revenue,
       CASE WHEN NOT is_partial THEN ROUND(ma3, 0) END             AS moving_avg_3m,
       is_partial
FROM m
ORDER BY month_start;

-- [q06_quarterly_yoy] Quarterly revenue vs the same quarter a year earlier (only when both quarters are complete)
WITH q AS (
    SELECT quarter_start,
           year,
           quarter,
           SUM(revenue)  AS revenue,
           SUM(orders)   AS orders,
           (COUNT(*) = 3 AND NOT BOOL_OR(is_partial)) AS is_complete
    FROM retail.mv_monthly_revenue
    GROUP BY quarter_start, year, quarter
)
SELECT year || '-Q' || quarter AS quarter,
       revenue,
       orders,
       ROUND(revenue / orders, 2) AS avg_order_value,
       LAG(revenue) OVER (PARTITION BY quarter ORDER BY year) AS revenue_same_q_prev_year,
       CASE WHEN is_complete AND LAG(is_complete) OVER (PARTITION BY quarter ORDER BY year)
            THEN ROUND(100 * (revenue / LAG(revenue) OVER (PARTITION BY quarter ORDER BY year) - 1), 1) END AS yoy_pct,
       is_complete
FROM q
ORDER BY quarter_start;

-- [q07_like_for_like] Like-for-like windows that exist in every year of the data
WITH s AS (
    SELECT EXTRACT(YEAR  FROM invoice_date)::int AS y,
           EXTRACT(MONTH FROM invoice_date)::int AS m,
           EXTRACT(DAY   FROM invoice_date)::int AS dd,
           line_amount
    FROM retail.fact_lines
    WHERE line_type = 'SALE'
),
p AS (
    SELECT 'Jan-Nov (11 full months)' AS period,
           NULL::numeric AS rev_2009,
           SUM(line_amount) FILTER (WHERE y = 2010 AND m <= 11) AS rev_2010,
           SUM(line_amount) FILTER (WHERE y = 2011 AND m <= 11) AS rev_2011
    FROM s
    UNION ALL
    SELECT 'Dec 1-9 (the only December days present in 2011)',
           SUM(line_amount) FILTER (WHERE y = 2009 AND m = 12 AND dd <= 9),
           SUM(line_amount) FILTER (WHERE y = 2010 AND m = 12 AND dd <= 9),
           SUM(line_amount) FILTER (WHERE y = 2011 AND m = 12 AND dd <= 9)
    FROM s
)
SELECT period,
       rev_2009,
       rev_2010,
       rev_2011,
       ROUND(100 * (rev_2010 / rev_2009 - 1), 1) AS yoy_2010_pct,
       ROUND(100 * (rev_2011 / rev_2010 - 1), 1) AS yoy_2011_pct
FROM p;

-- [q08_top_products] Top 15 products by gross revenue: RANK (revenue), DENSE_RANK (units), returns, net rank, shares
SELECT RANK() OVER (ORDER BY revenue DESC)       AS revenue_rank,
       stock_code,
       description,
       revenue,
       units,
       orders,
       DENSE_RANK() OVER (ORDER BY units DESC)   AS units_dense_rank,
       ROUND(100 * revenue / SUM(revenue) OVER (), 2) AS pct_revenue,
       ROUND(100 * SUM(revenue) OVER (ORDER BY revenue DESC, stock_code) / SUM(revenue) OVER (), 2) AS cum_pct_revenue,
       returns_amount                            AS cancellations,
       RANK() OVER (ORDER BY revenue + returns_amount DESC) AS net_revenue_rank
FROM retail.mv_product_revenue
ORDER BY revenue_rank
LIMIT 15;

-- [q09_top_products_by_year] Top 5 products per business year (RANK OVER PARTITION BY fy) and rank in the previous year
-- FY2012 is excluded (9 days of data)
WITH p AS (
    SELECT fy, stock_code, SUM(line_amount) AS revenue
    FROM retail.v_sales_enriched
    WHERE fy IN (2010, 2011)
    GROUP BY fy, stock_code
),
r AS (
    SELECT fy, stock_code, revenue,
           RANK() OVER (PARTITION BY fy ORDER BY revenue DESC) AS rnk,
           ROUND(100 * revenue / SUM(revenue) OVER (PARTITION BY fy), 2) AS pct_fy_revenue
    FROM p
)
SELECT r.fy,
       r.rnk                 AS revenue_rank,
       r.stock_code,
       dp.description,
       r.revenue,
       r.pct_fy_revenue,
       prev.rnk              AS rank_previous_fy
FROM r
JOIN retail.dim_product dp ON dp.stock_code = r.stock_code
LEFT JOIN r prev ON prev.stock_code = r.stock_code AND prev.fy = r.fy - 1
WHERE r.rnk <= 5
ORDER BY r.fy, r.rnk;

-- [q10_pareto_abc] Product contribution (Pareto): A = products making the first 80% of revenue, B = next 15%, C = last 5%
WITH p AS (
    SELECT stock_code, revenue,
           SUM(revenue) OVER (ORDER BY revenue DESC, stock_code) AS cum,
           SUM(revenue) OVER ()                                  AS total
    FROM retail.mv_product_revenue
),
c AS (
    SELECT revenue,
           CASE WHEN (cum - revenue) / total < 0.80 THEN 'A'
                WHEN (cum - revenue) / total < 0.95 THEN 'B'
                ELSE 'C' END AS abc_class
    FROM p
)
SELECT abc_class,
       COUNT(*)                                                  AS products,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)        AS pct_products,
       SUM(revenue)                                              AS revenue,
       ROUND(100 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1)  AS pct_revenue,
       ROUND(AVG(revenue), 0)                                    AS avg_revenue_per_product
FROM c
GROUP BY abc_class
ORDER BY abc_class;

-- [q11_pareto_curve] How concentrated is revenue? Products needed for X% of revenue, and revenue share of the top X% of products
WITH p AS (
    SELECT ROW_NUMBER() OVER (ORDER BY revenue DESC, stock_code) AS rn,
           COUNT(*)     OVER ()                                  AS n,
           SUM(revenue) OVER (ORDER BY revenue DESC, stock_code) AS cum,
           SUM(revenue) OVER ()                                  AS total
    FROM retail.mv_product_revenue
),
a AS (
    SELECT 'products needed for ' || s.pct || '% of revenue' AS metric,
           MIN(p.rn)::bigint                                  AS products,
           ROUND(100.0 * MIN(p.rn) / MAX(p.n), 1)             AS pct_of_products,
           s.pct::numeric                                     AS pct_of_revenue,
           s.pct                                              AS sort_key
    FROM (VALUES (50), (80), (95)) AS s(pct)
    JOIN p ON p.cum >= p.total * s.pct / 100.0
    GROUP BY s.pct
),
b AS (
    SELECT 'top ' || s.pct || '% of products' AS metric,
           MAX(p.rn)::bigint                   AS products,
           s.pct::numeric                      AS pct_of_products,
           ROUND(100 * MAX(p.cum) / MAX(p.total), 1) AS pct_of_revenue,
           100 + s.pct                         AS sort_key
    FROM (VALUES (1), (5), (10), (20), (50)) AS s(pct)
    JOIN p ON p.rn <= CEIL(p.n * s.pct / 100.0)
    GROUP BY s.pct
)
SELECT metric, products, pct_of_products, pct_of_revenue
FROM (SELECT * FROM a UNION ALL SELECT * FROM b) u
ORDER BY sort_key;

-- [q12_top_countries] Top 10 countries: RANK by revenue, DENSE_RANK by orders, share and average order value
WITH c AS (
    SELECT country,
           SUM(line_amount)               AS revenue,
           COUNT(DISTINCT invoice)        AS orders,
           COUNT(DISTINCT customer_id)    AS customers
    FROM retail.v_sales_enriched
    GROUP BY country
)
SELECT RANK() OVER (ORDER BY revenue DESC)        AS revenue_rank,
       country,
       revenue,
       ROUND(100 * revenue / SUM(revenue) OVER (), 2) AS pct_revenue,
       orders,
       DENSE_RANK() OVER (ORDER BY orders DESC)   AS orders_dense_rank,
       ROUND(revenue / orders, 2)                 AS avg_order_value,
       customers
FROM c
ORDER BY revenue_rank
LIMIT 10;

-- [q13_country_rank_by_year] Country revenue by business year with YoY and rank movement (RANK in each year)
WITH c AS (
    SELECT country,
           SUM(line_amount) FILTER (WHERE fy = 2010) AS revenue_fy2010,
           SUM(line_amount) FILTER (WHERE fy = 2011) AS revenue_fy2011
    FROM retail.v_sales_enriched
    GROUP BY country
),
r AS (
    SELECT country, revenue_fy2010, revenue_fy2011,
           RANK() OVER (ORDER BY revenue_fy2010 DESC NULLS LAST) AS rank_fy2010,
           RANK() OVER (ORDER BY revenue_fy2011 DESC NULLS LAST) AS rank_fy2011
    FROM c
)
SELECT country,
       revenue_fy2010,
       revenue_fy2011,
       ROUND(100 * (revenue_fy2011 / revenue_fy2010 - 1), 1) AS yoy_pct,
       rank_fy2010,
       rank_fy2011,
       rank_fy2010 - rank_fy2011                             AS places_gained
FROM r
ORDER BY rank_fy2011
LIMIT 10;

-- [q14_weekday] Revenue by weekday (trading days = distinct dates with at least one sale)
SELECT weekday,
       SUM(line_amount)                                        AS revenue,
       ROUND(100 * SUM(line_amount) / SUM(SUM(line_amount)) OVER (), 1) AS pct_revenue,
       COUNT(DISTINCT invoice)                                 AS orders,
       ROUND(SUM(line_amount) / COUNT(DISTINCT invoice), 2)    AS avg_order_value,
       COUNT(DISTINCT invoice_date)                            AS trading_days,
       ROUND(SUM(line_amount) / COUNT(DISTINCT invoice_date), 0) AS revenue_per_trading_day
FROM retail.v_sales_enriched
GROUP BY iso_weekday, weekday
ORDER BY iso_weekday;

-- [q15_hour] Revenue and orders by hour of the day
SELECT invoice_hour                                          AS hour,
       SUM(line_amount)                                      AS revenue,
       ROUND(100 * SUM(line_amount) / SUM(SUM(line_amount)) OVER (), 1) AS pct_revenue,
       COUNT(DISTINCT invoice)                               AS orders,
       ROUND(SUM(line_amount) / COUNT(DISTINCT invoice), 2)  AS avg_order_value
FROM retail.v_sales_enriched
GROUP BY invoice_hour
ORDER BY invoice_hour;

-- [q16_aov_monthly] Average and median order value per month (orders = invoices with valid sales)
WITH o AS (
    SELECT invoice,
           MIN(month_start)   AS month_start,
           SUM(line_amount)   AS order_value,
           COUNT(*)           AS lines,
           SUM(quantity)      AS units
    FROM retail.v_sales_enriched
    GROUP BY invoice
)
SELECT TO_CHAR(month_start, 'YYYY-MM')                                       AS year_month,
       COUNT(*)                                                              AS orders,
       ROUND(AVG(order_value), 2)                                            AS avg_order_value,
       ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY order_value))::numeric, 2) AS median_order_value,
       ROUND(AVG(lines), 1)                                                  AS avg_lines_per_order,
       ROUND(AVG(units), 1)                                                  AS avg_units_per_order,
       ROUND(100 * (AVG(order_value) / LAG(AVG(order_value), 12) OVER (ORDER BY month_start) - 1), 1) AS aov_yoy_pct
FROM o
GROUP BY month_start
ORDER BY month_start;

-- [q17_new_vs_returning] Monthly revenue of new vs returning customers (and guests) - Jan-2010 .. Nov-2011
-- (Dec-2009 is skipped: every customer would look 'new' because the data starts there; Dec-2011 is partial)
WITH s AS (
    SELECT v.month_start,
           v.line_amount,
           v.customer_id,
           CASE WHEN v.customer_id IS NULL                  THEN 'guest'
                WHEN c.first_order_month = v.month_start    THEN 'new'
                ELSE 'returning' END AS customer_type
    FROM retail.v_sales_enriched v
    LEFT JOIN retail.dim_customer c ON c.customer_id = v.customer_id
    WHERE v.month_start BETWEEN DATE '2010-01-01' AND DATE '2011-11-01'
)
SELECT TO_CHAR(month_start, 'YYYY-MM')                                    AS year_month,
       SUM(line_amount) FILTER (WHERE customer_type = 'new')              AS revenue_new,
       SUM(line_amount) FILTER (WHERE customer_type = 'returning')        AS revenue_returning,
       SUM(line_amount) FILTER (WHERE customer_type = 'guest')            AS revenue_guest,
       ROUND(100.0 * SUM(line_amount) FILTER (WHERE customer_type = 'new') / SUM(line_amount), 1)       AS pct_new,
       ROUND(100.0 * SUM(line_amount) FILTER (WHERE customer_type = 'returning') / SUM(line_amount), 1) AS pct_returning,
       ROUND(100.0 * SUM(line_amount) FILTER (WHERE customer_type = 'guest') / SUM(line_amount), 1)     AS pct_guest,
       COUNT(DISTINCT customer_id) FILTER (WHERE customer_type = 'new')       AS new_customers,
       COUNT(DISTINCT customer_id) FILTER (WHERE customer_type = 'returning') AS returning_customers
FROM s
GROUP BY month_start
ORDER BY month_start;

-- [q18_cancellations_monthly] Cancellations (credit notes of product lines) vs gross revenue, per month
SELECT year_month,
       revenue                                              AS gross_revenue,
       returns_amount                                       AS cancellations,
       revenue + returns_amount                             AS net_revenue,
       ROUND(-100 * returns_amount / revenue, 2)            AS cancellation_pct,
       cancel_invoices,
       units_cancelled,
       is_partial
FROM retail.mv_monthly_revenue
ORDER BY month_start;

-- [q19_outlier_orders] The 8 biggest single sale lines and how much of each the same customer cancelled afterwards
-- (gross revenue keeps such lines; net revenue and q18 show the cancellation)
SELECT f.invoice,
       f.invoice_date,
       f.stock_code,
       p.description,
       f.customer_id,
       f.quantity,
       f.line_amount,
       c.cancelled_amount,
       ROUND(-100.0 * c.cancelled_amount / f.line_amount, 1) AS pct_cancelled
FROM (SELECT * FROM retail.fact_lines WHERE line_type = 'SALE' ORDER BY line_amount DESC, line_id LIMIT 8) f
JOIN retail.dim_product p ON p.stock_code = f.stock_code
LEFT JOIN LATERAL (
    SELECT SUM(x.line_amount) AS cancelled_amount
    FROM retail.fact_lines x
    WHERE x.line_type = 'CANCELLATION'
      AND x.customer_id = f.customer_id
      AND x.stock_code  = f.stock_code
      AND x.invoice_date >= f.invoice_date
) c ON TRUE
ORDER BY f.line_amount DESC, f.invoice;

-- [q20_validation] Reconciliation: every route to the same revenue must give the same number
WITH t AS (
    SELECT SUM(line_amount) AS total FROM retail.fact_lines WHERE line_type = 'SALE'
)
SELECT check_name, expected, actual, (expected = actual) AS ok
FROM (
    SELECT 'raw rows = fact rows'                          AS check_name,
           (SELECT COUNT(*) FROM retail.raw_transactions)::numeric AS expected,
           (SELECT COUNT(*) FROM retail.fact_lines)::numeric       AS actual
    UNION ALL SELECT 'SALE revenue: fact vs enriched view',
           (SELECT total FROM t), (SELECT SUM(line_amount) FROM retail.v_sales_enriched)
    UNION ALL SELECT 'SALE revenue: fact vs mv_monthly_revenue',
           (SELECT total FROM t), (SELECT SUM(revenue) FROM retail.mv_monthly_revenue)
    UNION ALL SELECT 'SALE revenue: fact vs mv_product_revenue',
           (SELECT total FROM t), (SELECT SUM(revenue) FROM retail.mv_product_revenue)
    UNION ALL SELECT 'SALE revenue: fact vs sum by country',
           (SELECT total FROM t),
           (SELECT SUM(r) FROM (SELECT SUM(line_amount) AS r FROM retail.v_sales_enriched GROUP BY country) x)
    UNION ALL SELECT 'SALE revenue: fact vs sum by business year',
           (SELECT total FROM t),
           (SELECT SUM(r) FROM (SELECT SUM(line_amount) AS r FROM retail.v_sales_enriched GROUP BY fy) x)
    UNION ALL SELECT 'SALE orders: sum of monthly orders = distinct invoices',
           (SELECT COUNT(DISTINCT invoice) FROM retail.fact_lines WHERE line_type = 'SALE')::numeric,
           (SELECT SUM(orders) FROM retail.mv_monthly_revenue)::numeric
    UNION ALL SELECT 'lines where line_amount <> ROUND(quantity x unit_price, 2)',
           0, (SELECT COUNT(*) FROM retail.fact_lines
               WHERE line_amount <> ROUND(quantity * unit_price, 2))::numeric
    UNION ALL SELECT 'SALE lines with quantity <= 0 or unit_price <= 0',
           0, (SELECT COUNT(*) FROM retail.fact_lines
               WHERE line_type = 'SALE' AND (quantity <= 0 OR unit_price <= 0))::numeric
    UNION ALL SELECT 'CANCELLATION lines with positive quantity',
           0, (SELECT COUNT(*) FROM retail.fact_lines
               WHERE line_type = 'CANCELLATION' AND quantity > 0)::numeric
    UNION ALL SELECT 'SALE lines on a non-product stock code',
           0, (SELECT COUNT(*) FROM retail.fact_lines f JOIN retail.dim_product p USING (stock_code)
               WHERE f.line_type = 'SALE' AND p.product_kind <> 'PRODUCT')::numeric
) v;

-- [q21_duplicate_lines] Fully identical raw lines (same invoice, product, quantity, timestamp, price, customer, country): kept, not removed
SELECT COUNT(*)                  AS repeated_lines,
       SUM(copies - 1)           AS surplus_copies,
       ROUND(100.0 * SUM(copies - 1) / (SELECT COUNT(*) FROM retail.raw_transactions), 2) AS pct_of_raw_lines
FROM (
    SELECT COUNT(*) AS copies
    FROM retail.raw_transactions
    GROUP BY invoice, stock_code, description, quantity, invoice_ts, unit_price, customer_id, country
    HAVING COUNT(*) > 1
) d;
