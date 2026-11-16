-- ============================================================
-- SQL 02 - Sales Reporting | 05_reports_amazon.sql
-- Second, smaller report: Amazon India shipped order lines ('Clean Data' sheet), 31 Mar - 29 Jun 2022, INR.
-- Dates are the REPAIRED dates (see 02_model.sql). The sample covers 91 days, so there is no YoY here:
-- growth is week-over-week and month-over-month on average daily revenue.
-- Result names start with 'a' (a01 ... a12); the retail reports are q01 ... q19.
-- ============================================================

-- [a01_date_repair] Why the repair is needed: date range and months as stored vs after swapping day and month
SELECT 'as stored in the workbook' AS version,
       MIN(stored_date)            AS first_date,
       MAX(stored_date)            AS last_date,
       COUNT(DISTINCT stored_date) AS distinct_days,
       COUNT(DISTINCT date_trunc('month', stored_date)) AS distinct_months,
       0::bigint                   AS lines_swapped
FROM amazon.fact_order_lines
UNION ALL
SELECT 'repaired (day <= 12: day and month swapped)',
       MIN(order_date),
       MAX(order_date),
       COUNT(DISTINCT order_date),
       COUNT(DISTINCT date_trunc('month', order_date)),
       COUNT(*) FILTER (WHERE order_date <> stored_date)
FROM amazon.fact_order_lines
ORDER BY lines_swapped;

-- [a02_headline] Headline KPIs
SELECT MIN(order_date)                              AS first_date,
       MAX(order_date)                              AS last_date,
       COUNT(DISTINCT order_date)                   AS days,
       COUNT(*)                                     AS order_lines,
       SUM(qty)                                     AS units,
       SUM(amount)                                  AS revenue_inr,
       ROUND(SUM(amount) / COUNT(*), 2)             AS avg_revenue_per_line,
       ROUND(SUM(amount) / COUNT(DISTINCT order_date), 0) AS avg_daily_revenue,
       COUNT(DISTINCT sku)                          AS skus,
       (SELECT COUNT(*) FROM amazon.dim_category)   AS categories
FROM amazon.fact_order_lines;

-- [a03_daily] Daily revenue with day-over-day change (LAG) and 7-day moving average
SELECT order_date,
       weekday,
       order_lines,
       units,
       revenue,
       ROUND(100 * (revenue / LAG(revenue) OVER (ORDER BY order_date) - 1), 1)                   AS dod_pct,
       CASE WHEN ROW_NUMBER() OVER (ORDER BY order_date) >= 7
            THEN ROUND(AVG(revenue) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 0) END AS moving_avg_7d,
       SUM(revenue) OVER (ORDER BY order_date)                                                    AS cumulative_revenue
FROM amazon.mv_daily_sales
ORDER BY order_date;

-- [a04_weekly_growth] Weekly revenue (ISO weeks, Monday start) and growth on AVERAGE DAILY revenue.
-- The first week (31 Mar - 3 Apr) and the last (27-29 Jun) are partial, so growth is only shown between complete weeks.
WITH w AS (
    SELECT week_start,
           COUNT(*)       AS days_in_data,
           SUM(order_lines) AS order_lines,
           SUM(units)     AS units,
           SUM(revenue)   AS revenue
    FROM amazon.mv_daily_sales
    GROUP BY week_start
)
SELECT week_start,
       days_in_data,
       order_lines,
       units,
       revenue,
       ROUND(revenue / days_in_data, 0)  AS avg_daily_revenue,
       CASE WHEN days_in_data = 7 AND LAG(days_in_data) OVER (ORDER BY week_start) = 7
            THEN ROUND(100 * (revenue / LAG(revenue) OVER (ORDER BY week_start) - 1), 1) END AS wow_pct,
       ROUND(100 * revenue / SUM(revenue) OVER (), 1) AS pct_of_total,
       (days_in_data < 7)                AS is_partial
FROM w
ORDER BY week_start;

-- [a05_monthly] Monthly revenue: March is a single day (31 Mar) and June stops on the 29th, so compare daily averages
WITH m AS (
    SELECT year_month,
           COUNT(*)       AS days_in_data,
           SUM(order_lines) AS order_lines,
           SUM(units)     AS units,
           SUM(revenue)   AS revenue
    FROM amazon.mv_daily_sales
    GROUP BY year_month
)
SELECT year_month,
       days_in_data,
       order_lines,
       units,
       revenue,
       ROUND(revenue / days_in_data, 0) AS avg_daily_revenue,
       CASE WHEN days_in_data > 1
             AND LAG(days_in_data) OVER (ORDER BY year_month) > 1
            THEN ROUND(100 * (revenue / days_in_data
                              / (LAG(revenue) OVER (ORDER BY year_month) / LAG(days_in_data) OVER (ORDER BY year_month)) - 1), 1)
            END AS daily_avg_mom_pct
FROM m
ORDER BY year_month;

-- [a06_category_mix] Revenue mix by category (RANK) with units, average price and cumulative share
SELECT RANK() OVER (ORDER BY SUM(amount) DESC)                               AS revenue_rank,
       category,
       COUNT(*)                                                              AS order_lines,
       SUM(qty)                                                              AS units,
       SUM(amount)                                                           AS revenue,
       ROUND(100 * SUM(amount) / SUM(SUM(amount)) OVER (), 2)                AS pct_revenue,
       ROUND(100 * SUM(SUM(amount)) OVER (ORDER BY SUM(amount) DESC) / SUM(SUM(amount)) OVER (), 2) AS cum_pct_revenue,
       ROUND(SUM(amount) / SUM(qty), 2)                                      AS avg_price_per_unit,
       COUNT(DISTINCT sku)                                                   AS skus
FROM amazon.v_orders_enriched
GROUP BY category
ORDER BY revenue_rank;

-- [a07_size_mix] Size mix in the natural order XS ... 6XL, Free
SELECT size,
       COUNT(*)                                                 AS order_lines,
       SUM(qty)                                                 AS units,
       SUM(amount)                                              AS revenue,
       ROUND(100 * SUM(amount) / SUM(SUM(amount)) OVER (), 2)   AS pct_revenue,
       ROUND(SUM(amount) / SUM(qty), 2)                         AS avg_price_per_unit
FROM amazon.v_orders_enriched
GROUP BY size, size_order
ORDER BY size_order;

-- [a08_category_size] Size mix inside the 4 biggest categories (% of the category's units; FILTER pivot)
WITH top4 AS (
    SELECT category FROM amazon.v_orders_enriched GROUP BY category ORDER BY SUM(amount) DESC LIMIT 4
)
SELECT v.category,
       SUM(v.qty)                                                                        AS units,
       ROUND(100.0 * SUM(v.qty) FILTER (WHERE v.size IN ('XS', 'S'))  / SUM(v.qty), 1)    AS pct_xs_s,
       ROUND(100.0 * SUM(v.qty) FILTER (WHERE v.size = 'M')           / SUM(v.qty), 1)    AS pct_m,
       ROUND(100.0 * SUM(v.qty) FILTER (WHERE v.size = 'L')           / SUM(v.qty), 1)    AS pct_l,
       ROUND(100.0 * SUM(v.qty) FILTER (WHERE v.size = 'XL')          / SUM(v.qty), 1)    AS pct_xl,
       ROUND(100.0 * SUM(v.qty) FILTER (WHERE v.size = 'XXL')         / SUM(v.qty), 1)    AS pct_xxl,
       ROUND(100.0 * SUM(v.qty) FILTER (WHERE v.size IN ('3XL', '4XL', '5XL', '6XL')) / SUM(v.qty), 1) AS pct_3xl_plus
FROM amazon.v_orders_enriched v
JOIN top4 USING (category)
GROUP BY v.category
ORDER BY units DESC;

-- [a09_top_skus] Top 15 SKUs (each SKU is a style + size): RANK by revenue, DENSE_RANK by units, cumulative share
SELECT RANK() OVER (ORDER BY SUM(amount) DESC)           AS revenue_rank,
       sku,
       category,
       SUM(qty)                                           AS units,
       SUM(amount)                                        AS revenue,
       DENSE_RANK() OVER (ORDER BY SUM(qty) DESC)         AS units_dense_rank,
       ROUND(100 * SUM(amount) / SUM(SUM(amount)) OVER (), 2) AS pct_revenue,
       ROUND(100 * SUM(SUM(amount)) OVER (ORDER BY SUM(amount) DESC, sku) / SUM(SUM(amount)) OVER (), 2) AS cum_pct_revenue
FROM amazon.v_orders_enriched
GROUP BY sku, category
ORDER BY revenue_rank
LIMIT 15;

-- [a10_top_styles] Top 10 styles (SKU prefix before the first hyphen: all sizes and colours together)
SELECT RANK() OVER (ORDER BY SUM(amount) DESC)      AS revenue_rank,
       style_code,
       MIN(category)                                 AS category,
       COUNT(DISTINCT sku)                           AS sku_variants,
       SUM(qty)                                      AS units,
       SUM(amount)                                   AS revenue,
       ROUND(100 * SUM(amount) / SUM(SUM(amount)) OVER (), 2) AS pct_revenue
FROM amazon.v_orders_enriched
GROUP BY style_code
ORDER BY revenue_rank
LIMIT 10;

-- [a11_pareto_skus] Concentration: SKUs needed for 50% / 80% / 95% of revenue
WITH p AS (
    SELECT sku,
           ROW_NUMBER() OVER (ORDER BY SUM(amount) DESC, sku)  AS rn,
           COUNT(*)     OVER ()                                AS n,
           SUM(SUM(amount)) OVER (ORDER BY SUM(amount) DESC, sku) AS cum,
           SUM(SUM(amount)) OVER ()                            AS total
    FROM amazon.fact_order_lines
    GROUP BY sku
)
SELECT 'SKUs needed for ' || s.pct || '% of revenue' AS metric,
       MIN(p.rn)                                      AS skus,
       MAX(p.n)                                       AS total_skus,
       ROUND(100.0 * MIN(p.rn) / MAX(p.n), 1)         AS pct_of_skus
FROM (VALUES (50), (80), (95)) AS s(pct)
JOIN p ON p.cum >= p.total * s.pct / 100.0
GROUP BY s.pct
ORDER BY s.pct;

-- [a12_weekday] Revenue by weekday (repaired dates; the days column is how many of each weekday the 91-day window contains)
SELECT weekday,
       COUNT(*)                                                   AS days,
       SUM(order_lines)                                           AS order_lines,
       SUM(revenue)                                               AS revenue,
       ROUND(100 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1)   AS pct_revenue,
       ROUND(SUM(revenue) / COUNT(*), 0)                          AS avg_daily_revenue
FROM amazon.mv_daily_sales
GROUP BY iso_weekday, weekday
ORDER BY iso_weekday;

-- [a13_validation] Reconciliation of the repaired Amazon model
SELECT check_name, expected, actual, (expected = actual) AS ok
FROM (
    SELECT 'raw rows = fact rows' AS check_name,
           (SELECT COUNT(*) FROM amazon.raw_orders)::numeric AS expected,
           (SELECT COUNT(*) FROM amazon.fact_order_lines)::numeric AS actual
    UNION ALL SELECT 'revenue: raw vs fact',
           (SELECT SUM(amount) FROM amazon.raw_orders), (SELECT SUM(amount) FROM amazon.fact_order_lines)
    UNION ALL SELECT 'revenue: raw vs mv_daily_sales',
           (SELECT SUM(amount) FROM amazon.raw_orders), (SELECT SUM(revenue) FROM amazon.mv_daily_sales)
    UNION ALL SELECT 'revenue: raw vs sum by category',
           (SELECT SUM(amount) FROM amazon.raw_orders),
           (SELECT SUM(r) FROM (SELECT SUM(amount) AS r FROM amazon.v_orders_enriched GROUP BY category) x)
    UNION ALL SELECT 'revenue: raw vs sum by size',
           (SELECT SUM(amount) FROM amazon.raw_orders),
           (SELECT SUM(r) FROM (SELECT SUM(amount) AS r FROM amazon.v_orders_enriched GROUP BY size) x)
    UNION ALL SELECT 'revenue: raw vs sum by week',
           (SELECT SUM(amount) FROM amazon.raw_orders),
           (SELECT SUM(r) FROM (SELECT SUM(amount) AS r FROM amazon.v_orders_enriched GROUP BY week_start) x)
    UNION ALL SELECT 'days with data = days between first and last date (no gaps)',
           (SELECT (MAX(order_date) - MIN(order_date) + 1) FROM amazon.fact_order_lines)::numeric,
           (SELECT COUNT(DISTINCT order_date) FROM amazon.fact_order_lines)::numeric
    UNION ALL SELECT 'lines whose repaired date is outside 2022-03-31 .. 2022-06-29',
           0, (SELECT COUNT(*) FROM amazon.fact_order_lines
               WHERE order_date NOT BETWEEN DATE '2022-03-31' AND DATE '2022-06-29')::numeric
    UNION ALL SELECT 'lines with stored day <= 12 and day <> month are the ones that changed',
           (SELECT COUNT(*) FROM amazon.fact_order_lines
            WHERE EXTRACT(DAY FROM stored_date) <= 12
              AND EXTRACT(DAY FROM stored_date) <> EXTRACT(MONTH FROM stored_date))::numeric,
           (SELECT COUNT(*) FROM amazon.fact_order_lines WHERE order_date <> stored_date)::numeric
) v;
