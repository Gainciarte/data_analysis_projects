-- ============================================================
-- SQL 04 - Supply Chain Queries | 03_views.sql
-- Demand window = last 12 full calendar months (Aug-2022 .. Jul-2023)
-- ============================================================

CREATE OR REPLACE VIEW v_sku_demand_12m AS
WITH bounds AS (
    SELECT MAX(order_date) AS max_date,
           (date_trunc('month', MAX(order_date)) - INTERVAL '11 months')::date AS win_start
    FROM sales
),
month_grid AS (
    SELECT i.sku_id, g.m::date AS month_start
    FROM inventory i
    CROSS JOIN bounds b
    CROSS JOIN LATERAL generate_series(b.win_start, b.max_date, INTERVAL '1 month') AS g(m)
),
monthly AS (
    SELECT mg.sku_id, mg.month_start, COALESCE(SUM(s.order_qty), 0) AS qty
    FROM month_grid mg
    LEFT JOIN sales s ON s.sku_id = mg.sku_id
                     AND date_trunc('month', s.order_date)::date = mg.month_start
    GROUP BY mg.sku_id, mg.month_start
)
SELECT m.sku_id,
       SUM(m.qty)                                        AS units_12m,
       ROUND(SUM(m.qty) / (b.max_date - b.win_start + 1), 4) AS avg_daily_qty,
       COALESCE(STDDEV_SAMP(m.qty), 0) / SQRT(30.0)      AS sd_daily_qty
FROM monthly m
CROSS JOIN bounds b
GROUP BY m.sku_id, b.max_date, b.win_start;

-- One row per SKU: supplier, lead time, coverage, margin and "order-by" timing
CREATE OR REPLACE VIEW v_sku_supply AS
SELECT i.sku_id,
       v.vendor_name,
       i.warehouse_id,
       w.city, w.province,
       i.on_hand_qty,
       i.unit_cost,
       i.unit_price,
       ROUND(i.on_hand_qty * i.unit_cost, 2)                               AS stock_value,
       i.avg_lead_days,
       i.max_lead_days,
       ROUND((i.max_lead_days - i.avg_lead_days)::numeric / i.avg_lead_days, 2) AS lt_variability,
       d.units_12m,
       d.avg_daily_qty,
       d.sd_daily_qty,
       CASE WHEN d.avg_daily_qty > 0 THEN ROUND(i.on_hand_qty / d.avg_daily_qty, 1) END AS days_of_cover,
       -- days from today (snapshot) until an order must be placed to avoid a stock-out
       CASE WHEN d.avg_daily_qty > 0
            THEN ROUND(i.on_hand_qty / d.avg_daily_qty - i.avg_lead_days, 1) END        AS days_to_order_by,
       ROUND((i.unit_price - i.unit_cost) / NULLIF(i.unit_price, 0), 4)                 AS gross_margin_pct
FROM inventory i
JOIN vendors    v ON v.vendor_id = i.vendor_id
JOIN warehouses w ON w.warehouse_id = i.warehouse_id
JOIN v_sku_demand_12m d ON d.sku_id = i.sku_id;
