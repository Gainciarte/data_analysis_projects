-- ============================================================
-- SQL 01 - Inventory Queries | 02_views.sql
-- Reusable views. Demand window = the last 12 full calendar
-- months of the sales history (Aug-2022 .. Jul-2023).
-- ============================================================

-- 12-month demand profile per SKU (months with no sales are zero-filled so
-- that the standard deviation is not overstated)
CREATE OR REPLACE VIEW v_sku_demand_12m AS
WITH bounds AS (
    SELECT MAX(order_date)                                        AS max_date,
           (date_trunc('month', MAX(order_date)) - INTERVAL '11 months')::date AS win_start
    FROM sales
),
month_grid AS (
    SELECT i.sku_id, g.month_start::date AS month_start
    FROM inventory i
    CROSS JOIN bounds b
    CROSS JOIN LATERAL generate_series(b.win_start, b.max_date, INTERVAL '1 month') AS g(month_start)
),
monthly AS (
    SELECT mg.sku_id,
           mg.month_start,
           COALESCE(SUM(s.order_qty), 0) AS qty
    FROM month_grid mg
    LEFT JOIN sales s
           ON s.sku_id = mg.sku_id
          AND date_trunc('month', s.order_date)::date = mg.month_start
    GROUP BY mg.sku_id, mg.month_start
),
agg AS (
    SELECT sku_id,
           SUM(qty)                 AS units_12m,
           AVG(qty)                 AS avg_monthly_qty,
           COALESCE(STDDEV_SAMP(qty), 0) AS sd_monthly_qty
    FROM monthly
    GROUP BY sku_id
)
SELECT a.sku_id,
       a.units_12m,
       COALESCE(o.orders_12m, 0)    AS orders_12m,
       o.last_order_date,
       ROUND(a.avg_monthly_qty, 2)  AS avg_monthly_qty,
       ROUND(a.sd_monthly_qty, 2)   AS sd_monthly_qty,
       CASE WHEN a.avg_monthly_qty > 0
            THEN ROUND(a.sd_monthly_qty / a.avg_monthly_qty, 3) END AS cv_monthly,
       ROUND(a.units_12m / (b.max_date - b.win_start + 1), 4)  AS avg_daily_qty
FROM agg a
CROSS JOIN bounds b
LEFT JOIN (
    SELECT s.sku_id, COUNT(*) AS orders_12m, MAX(s.order_date) AS last_order_date
    FROM sales s, bounds bb
    WHERE s.order_date >= bb.win_start
    GROUP BY s.sku_id
) o ON o.sku_id = a.sku_id;

-- Last order date over the whole history (for SKUs that stopped selling)
CREATE OR REPLACE VIEW v_sku_last_sale AS
SELECT sku_id, MAX(order_date) AS last_sale_ever
FROM sales
GROUP BY sku_id;

-- One row per SKU with the stock position and a coverage-based status
CREATE OR REPLACE VIEW v_sku_status AS
SELECT i.sku_id,
       k.sku_name,
       i.vendor_name,
       i.warehouse_id,
       i.on_hand_qty,
       i.unit_cost,
       i.total_value,
       i.avg_lead_days,
       i.max_lead_days,
       d.units_12m,
       d.avg_daily_qty,
       d.cv_monthly,
       ROUND(d.units_12m * i.unit_cost, 2)                      AS annual_consumption_value,
       CASE WHEN d.avg_daily_qty > 0
            THEN ROUND(i.on_hand_qty / d.avg_daily_qty, 1) END   AS days_of_cover,
       CASE
           WHEN i.on_hand_qty = 0                                         THEN 'Out of stock'
           WHEN d.units_12m = 0                                           THEN 'No demand (12m)'
           WHEN i.on_hand_qty / d.avg_daily_qty < i.avg_lead_days         THEN 'Critical (cover < avg lead time)'
           WHEN i.on_hand_qty / d.avg_daily_qty < i.max_lead_days         THEN 'Low (cover < max lead time)'
           WHEN i.on_hand_qty / d.avg_daily_qty > 365                     THEN 'Overstock (> 365 days)'
           ELSE 'Healthy'
       END AS stock_status
FROM inventory i
JOIN sku_items k          ON k.sku_id = i.sku_id
JOIN v_sku_demand_12m d   ON d.sku_id = i.sku_id;
