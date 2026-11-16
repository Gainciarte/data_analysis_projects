-- ============================================================
-- SQL 02 - Sales Reporting | 03_reports.sql
-- Management reports. Run top to bottom (psql -f or run_sales_reporting.py).
-- "-- [name] title" labels each query; results go to results/<name>.csv
-- ============================================================

-- [q01_headline_kpis] Headline KPIs for the whole period
SELECT COUNT(*)                         AS orders,
       SUM(order_qty)::bigint           AS units,
       SUM(revenue)::bigint             AS revenue,
       ROUND(AVG(revenue))              AS avg_order_value,
       COUNT(DISTINCT sku_id)           AS skus_sold,
       MIN(order_date)::text            AS first_date,
       MAX(order_date)::text            AS last_date
FROM sales;

-- [q02_yearly_yoy] Yearly revenue with YoY growth (2023 is a partial year: Jan-Jul)
SELECT year,
       COUNT(*)                                                   AS orders,
       SUM(revenue)::bigint                                       AS revenue,
       ROUND(100.0 * (SUM(revenue) - LAG(SUM(revenue)) OVER (ORDER BY year))
                    / LAG(SUM(revenue)) OVER (ORDER BY year), 1)  AS yoy_pct,
       MIN(order_date)::text                                      AS first_order,
       MAX(order_date)::text                                      AS last_order
FROM v_sales_enriched
GROUP BY year
ORDER BY year;

-- [q03_ytd_like_for_like] Like-for-like: January-July of each year
SELECT year,
       SUM(revenue)::bigint                                       AS revenue_jan_jul,
       COUNT(*)                                                   AS orders_jan_jul,
       ROUND(100.0 * (SUM(revenue) - LAG(SUM(revenue)) OVER (ORDER BY year))
                    / LAG(SUM(revenue)) OVER (ORDER BY year), 1)  AS yoy_pct
FROM v_sales_enriched
WHERE month <= 7
GROUP BY year
ORDER BY year;

-- [q04_monthly_mom] Monthly revenue: MoM growth (LAG), YTD running total and 3-month moving average
SELECT year_month,
       revenue::bigint                                                         AS revenue,
       ROUND(100.0 * (revenue - LAG(revenue) OVER w) / LAG(revenue) OVER w, 1)  AS mom_pct,
       SUM(revenue) OVER (PARTITION BY year ORDER BY month_start)::bigint       AS ytd_revenue,
       ROUND(AVG(revenue) OVER (ORDER BY month_start ROWS BETWEEN 2 PRECEDING AND CURRENT ROW))::bigint AS moving_avg_3m,
       orders
FROM mv_monthly_sales
WINDOW w AS (ORDER BY month_start)
ORDER BY month_start;

-- [q05_quarterly_yoy] Quarterly revenue vs same quarter of the previous year
SELECT year, quarter,
       SUM(revenue)::bigint                                                   AS revenue,
       LAG(SUM(revenue)::bigint) OVER (PARTITION BY quarter ORDER BY year)    AS same_qtr_prev_year,
       ROUND(100.0 * (SUM(revenue) - LAG(SUM(revenue)) OVER (PARTITION BY quarter ORDER BY year))
                    / LAG(SUM(revenue)) OVER (PARTITION BY quarter ORDER BY year), 1) AS yoy_pct
FROM v_sales_enriched
GROUP BY year, quarter
ORDER BY year, quarter;

-- [q06_customer_type] Revenue by customer type with share and average order value
SELECT customer_type,
       COUNT(*)                                                        AS orders,
       SUM(revenue)::bigint                                            AS revenue,
       ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1)      AS pct_revenue,
       ROUND(AVG(revenue))                                             AS avg_order_value,
       ROUND(SUM(revenue) / SUM(order_qty), 2)                         AS revenue_per_unit
FROM sales
GROUP BY customer_type
ORDER BY revenue DESC;

-- [q07_year_by_customer_type] Pivot: revenue by year and customer type (conditional aggregation)
SELECT year,
       SUM(revenue) FILTER (WHERE customer_type = 'Wholesale')::bigint   AS wholesale,
       SUM(revenue) FILTER (WHERE customer_type = 'Distributor')::bigint AS distributor,
       SUM(revenue) FILTER (WHERE customer_type = 'Export')::bigint      AS export,
       SUM(revenue)::bigint                                               AS total
FROM v_sales_enriched
GROUP BY year
ORDER BY year;

-- [q08_warehouse_province] Revenue by warehouse (joined to city / province)
SELECT warehouse_id, city, province,
       COUNT(*)                                                    AS orders,
       SUM(revenue)::bigint                                        AS revenue,
       ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1)  AS pct_revenue,
       ROUND(AVG(revenue))                                         AS avg_order_value
FROM v_sales_enriched
GROUP BY warehouse_id, city, province
ORDER BY revenue DESC;

-- [q09_top10_skus] Top 10 SKUs by revenue with cumulative share
WITH sku_rev AS (
    SELECT sku_id, sku_name, SUM(revenue) AS revenue, SUM(order_qty) AS units
    FROM v_sales_enriched
    GROUP BY sku_id, sku_name
)
SELECT RANK() OVER (ORDER BY revenue DESC)                                        AS rnk,
       sku_id, sku_name,
       revenue::bigint                                                            AS revenue,
       units::bigint                                                              AS units,
       ROUND(100.0 * revenue / SUM(revenue) OVER (), 2)                           AS pct_revenue,
       ROUND(100.0 * SUM(revenue) OVER (ORDER BY revenue DESC) / SUM(revenue) OVER (), 2) AS cum_pct
FROM sku_rev
ORDER BY rnk
LIMIT 10;

-- [q10_top3_per_warehouse] Top 3 SKUs inside each warehouse (RANK + PARTITION BY)
WITH ranked AS (
    SELECT warehouse_id, city, sku_id, SUM(revenue) AS revenue,
           RANK() OVER (PARTITION BY warehouse_id ORDER BY SUM(revenue) DESC) AS rnk
    FROM v_sales_enriched
    GROUP BY warehouse_id, city, sku_id
)
SELECT warehouse_id, city, rnk, sku_id, revenue::bigint AS revenue
FROM ranked
WHERE rnk <= 3
ORDER BY warehouse_id, rnk;

-- [q11_weekday] Weekday pattern (orders and revenue)
SELECT iso_weekday, weekday,
       COUNT(*)                                                      AS orders,
       SUM(revenue)::bigint                                          AS revenue,
       ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1)    AS pct_revenue
FROM v_sales_enriched
GROUP BY iso_weekday, weekday
ORDER BY iso_weekday;

-- [q12_sku_cohorts] SKU cohorts by first-sale quarter: how many SKUs are still selling in the last 12 months
WITH first_sale AS (
    SELECT sku_id, MIN(order_date) AS first_date, MAX(order_date) AS last_date
    FROM sales
    GROUP BY sku_id
),
cohort AS (
    SELECT TO_CHAR(date_trunc('quarter', first_date), 'YYYY-"Q"Q') AS first_sale_qtr,
           COUNT(*)                                                      AS skus,
           COUNT(*) FILTER (WHERE last_date >= DATE '2022-08-01')        AS active_last_12m
    FROM first_sale
    GROUP BY 1
)
SELECT first_sale_qtr, skus, active_last_12m,
       ROUND(100.0 * active_last_12m / skus, 1) AS pct_still_active
FROM cohort
ORDER BY first_sale_qtr;

-- [q13_concentration] How many SKUs generate 50 / 80 / 95% of revenue (window + CTE)
WITH sku_rev AS (
    SELECT sku_id, SUM(revenue) AS revenue FROM sales GROUP BY sku_id
),
cum AS (
    SELECT sku_id, revenue,
           ROW_NUMBER() OVER (ORDER BY revenue DESC)                                  AS n,
           SUM(revenue) OVER (ORDER BY revenue DESC) / SUM(revenue) OVER ()           AS cum_share
    FROM sku_rev
)
SELECT COUNT(*) FILTER (WHERE cum_share - revenue / (SELECT SUM(revenue) FROM sku_rev) < 0.50) AS skus_for_50pct,
       COUNT(*) FILTER (WHERE cum_share - revenue / (SELECT SUM(revenue) FROM sku_rev) < 0.80) AS skus_for_80pct,
       COUNT(*) FILTER (WHERE cum_share - revenue / (SELECT SUM(revenue) FROM sku_rev) < 0.95) AS skus_for_95pct,
       COUNT(*)                                                                                  AS total_skus
FROM cum;

-- [q14_reconciliation] Reconciliation: stored revenue vs qty x unit price, and view vs base table
SELECT (SELECT SUM(revenue)::bigint FROM sales)                        AS base_revenue,
       (SELECT SUM(revenue)::bigint FROM v_sales_enriched)             AS view_revenue,
       (SELECT SUM(revenue)::bigint FROM mv_monthly_sales)             AS monthly_mv_revenue,
       (SELECT COUNT(*) FROM sales WHERE ABS(revenue - order_qty * unit_sale_price) > 1) AS lines_off_by_more_than_1;
