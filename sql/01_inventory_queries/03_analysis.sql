-- ============================================================
-- SQL 01 - Inventory Queries | 03_analysis.sql
-- Analysis queries. Run top to bottom (psql -f or run_inventory_queries.py).
-- Lines "-- [name] title" label each query; the runner saves every
-- result set to results/<name>.csv
-- ============================================================

-- [q01_data_check] Data sanity check: row counts and coverage
SELECT 'sales order lines'                         AS metric, COUNT(*)::text AS value FROM sales
UNION ALL SELECT 'SKUs in inventory',               COUNT(*)::text FROM inventory
UNION ALL SELECT 'SKUs with at least 1 sale',       COUNT(DISTINCT sku_id)::text FROM sales
UNION ALL SELECT 'SKUs never sold',                 COUNT(*)::text FROM inventory i
                                                    WHERE NOT EXISTS (SELECT 1 FROM sales s WHERE s.sku_id = i.sku_id)
UNION ALL SELECT 'first order date',                MIN(order_date)::text FROM sales
UNION ALL SELECT 'last order date',                 MAX(order_date)::text FROM sales
UNION ALL SELECT 'total inventory value',     TO_CHAR(SUM(total_value), 'FM999,999,999,990') FROM inventory;

-- [q02_stock_status] Stock status summary (coverage vs lead time)
SELECT stock_status,
       COUNT(*)                                              AS skus,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)    AS pct_skus,
       ROUND(SUM(total_value))                               AS inventory_value,
       ROUND(100.0 * SUM(total_value) / SUM(SUM(total_value)) OVER (), 1) AS pct_value
FROM v_sku_status
GROUP BY stock_status
ORDER BY skus DESC;

-- [q03_reorder_risk] Top 15 critical SKUs: stock covers less than the average lead time
SELECT sku_id, sku_name, vendor_name, warehouse_id,
       on_hand_qty, ROUND(avg_daily_qty, 1) AS daily_demand,
       days_of_cover, avg_lead_days,
       avg_lead_days - days_of_cover                     AS days_short,
       ROUND(annual_consumption_value)                   AS annual_consumption_value
FROM v_sku_status
WHERE stock_status = 'Critical (cover < avg lead time)'
ORDER BY annual_consumption_value DESC
LIMIT 15;

-- [q04_abc] ABC classification by 12-month consumption value (Pareto with window functions)
CREATE TEMP TABLE abc AS
WITH ranked AS (
    SELECT sku_id, annual_consumption_value,
           SUM(annual_consumption_value) OVER (ORDER BY annual_consumption_value DESC, sku_id) AS cum_value,
           SUM(annual_consumption_value) OVER ()                                              AS total_value
    FROM v_sku_status
)
SELECT sku_id, annual_consumption_value,
       RANK() OVER (ORDER BY annual_consumption_value DESC)      AS value_rank,
       ROUND(100.0 * cum_value / total_value, 2)                 AS cum_pct,
       CASE WHEN (cum_value - annual_consumption_value) / total_value < 0.80 THEN 'A'
            WHEN (cum_value - annual_consumption_value) / total_value < 0.95 THEN 'B'
            ELSE 'C' END                                         AS abc_class
FROM ranked;

-- [q05_abc_summary] ABC summary: share of SKUs vs share of consumption value
SELECT a.abc_class,
       COUNT(*)                                                    AS skus,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)          AS pct_skus,
       ROUND(100.0 * SUM(a.annual_consumption_value) / SUM(SUM(a.annual_consumption_value)) OVER (), 1) AS pct_consumption,
       ROUND(SUM(s.total_value))                                   AS stock_value,
       ROUND(100.0 * SUM(s.total_value) / SUM(SUM(s.total_value)) OVER (), 1) AS pct_stock_value
FROM abc a
JOIN v_sku_status s USING (sku_id)
GROUP BY a.abc_class
ORDER BY a.abc_class;

-- [q06_xyz_matrix] ABC-XYZ matrix (X: CV <= 0.5, Y: 0.5-1.0, Z: > 1.0 or no demand) - SKU counts
SELECT a.abc_class,
       COUNT(*) FILTER (WHERE s.cv_monthly <= 0.5)                              AS x_stable,
       COUNT(*) FILTER (WHERE s.cv_monthly > 0.5 AND s.cv_monthly <= 1.0)       AS y_variable,
       COUNT(*) FILTER (WHERE s.cv_monthly > 1.0 OR s.cv_monthly IS NULL)       AS z_erratic,
       COUNT(*)                                                                 AS total
FROM abc a
JOIN v_sku_status s USING (sku_id)
GROUP BY a.abc_class
ORDER BY a.abc_class;

-- [q07_dead_stock] Dead / slow stock: SKUs with stock and no sales in the last 12 months or last sale > 180 days ago
WITH ref AS (SELECT MAX(order_date) AS max_date FROM sales)
SELECT s.sku_id, s.sku_name, s.vendor_name, s.warehouse_id,
       s.on_hand_qty, ROUND(s.total_value) AS tied_up_value,
       ls.last_sale_ever,
       (r.max_date - ls.last_sale_ever)    AS days_since_last_sale
FROM v_sku_status s
CROSS JOIN ref r
LEFT JOIN v_sku_last_sale ls ON ls.sku_id = s.sku_id
WHERE s.on_hand_qty > 0
  AND (ls.last_sale_ever IS NULL OR r.max_date - ls.last_sale_ever > 180)
ORDER BY s.total_value DESC
LIMIT 15;

-- [q08_overstock] Overstock concentration: SKUs with more than 365 days of cover
SELECT COUNT(*)                                   AS overstock_skus,
       ROUND(SUM(total_value))                    AS overstock_value,
       ROUND(100.0 * SUM(total_value) / (SELECT SUM(total_value) FROM inventory), 1) AS pct_of_total_value,
       ROUND(AVG(days_of_cover))                  AS avg_days_of_cover
FROM v_sku_status
WHERE stock_status = 'Overstock (> 365 days)';

-- [q09_warehouse_turnover] Inventory turnover and cover by warehouse (join with warehouse dimension)
SELECT w.warehouse_id, w.city, w.province,
       COUNT(*)                                                         AS skus,
       ROUND(SUM(s.total_value))                                        AS inventory_value,
       ROUND(SUM(s.annual_consumption_value))                           AS cogs_12m,
       ROUND(SUM(s.annual_consumption_value) / NULLIF(SUM(s.total_value), 0), 2) AS turnover_x,
       ROUND(365 * SUM(s.total_value) / NULLIF(SUM(s.annual_consumption_value), 0)) AS days_inventory
FROM v_sku_status s
JOIN warehouses w ON w.warehouse_id = s.warehouse_id
GROUP BY w.warehouse_id, w.city, w.province
ORDER BY inventory_value DESC;

-- [q10_vendor_concentration] Inventory value by vendor with cumulative share (window functions)
SELECT vendor_name,
       COUNT(*)                                                           AS skus,
       ROUND(SUM(total_value))                                            AS inventory_value,
       ROUND(100.0 * SUM(total_value) / SUM(SUM(total_value)) OVER (), 1) AS pct_value,
       ROUND(100.0 * SUM(SUM(total_value)) OVER (ORDER BY SUM(total_value) DESC)
                   / SUM(SUM(total_value)) OVER (), 1)                    AS cum_pct_value
FROM v_sku_status
GROUP BY vendor_name
ORDER BY inventory_value DESC;

-- [q11_reorder_plan] Reorder recommendations: ROP = d x LT + 1.645 x sigma_d x sqrt(LT) (95% service level)
WITH calc AS (
    SELECT s.sku_id, s.sku_name, s.vendor_name, s.on_hand_qty, s.avg_lead_days, s.avg_daily_qty,
           s.annual_consumption_value, a.abc_class,
           d.sd_monthly_qty / SQRT(30.0)                                       AS sd_daily
    FROM v_sku_status s
    JOIN v_sku_demand_12m d USING (sku_id)
    JOIN abc a USING (sku_id)
    WHERE s.units_12m > 0
),
rop AS (
    SELECT *,
           ROUND(1.645 * sd_daily * SQRT(avg_lead_days))                       AS safety_stock,
           ROUND(avg_daily_qty * avg_lead_days + 1.645 * sd_daily * SQRT(avg_lead_days)) AS reorder_point
    FROM calc
)
SELECT abc_class,
       COUNT(*)                                                      AS skus_with_demand,
       COUNT(*) FILTER (WHERE on_hand_qty <= reorder_point)          AS at_or_below_rop,
       ROUND(100.0 * COUNT(*) FILTER (WHERE on_hand_qty <= reorder_point) / COUNT(*), 1) AS pct_at_or_below_rop,
       ROUND(SUM(GREATEST(reorder_point - on_hand_qty, 0)))          AS units_short_vs_rop
FROM rop
GROUP BY abc_class
ORDER BY abc_class;

-- [q12_top_a_skus_rop] Class A SKUs already at or below the reorder point (most urgent first)
WITH calc AS (
    SELECT s.sku_id, s.sku_name, s.vendor_name, s.on_hand_qty, s.avg_lead_days, s.avg_daily_qty,
           s.annual_consumption_value, a.abc_class,
           d.sd_monthly_qty / SQRT(30.0) AS sd_daily
    FROM v_sku_status s
    JOIN v_sku_demand_12m d USING (sku_id)
    JOIN abc a USING (sku_id)
    WHERE s.units_12m > 0 AND a.abc_class = 'A'
)
SELECT sku_id, vendor_name, on_hand_qty,
       ROUND(avg_daily_qty * avg_lead_days + 1.645 * sd_daily * SQRT(avg_lead_days)) AS reorder_point,
       ROUND(avg_daily_qty * avg_lead_days + 1.645 * sd_daily * SQRT(avg_lead_days)) - on_hand_qty AS units_below_rop,
       avg_lead_days,
       ROUND(annual_consumption_value) AS annual_consumption_value
FROM calc
WHERE on_hand_qty <= avg_daily_qty * avg_lead_days + 1.645 * sd_daily * SQRT(avg_lead_days)
ORDER BY annual_consumption_value DESC
LIMIT 10;

-- [q13_validate_value] Validation: stored total_value vs on_hand_qty x unit_cost
SELECT COUNT(*)                                                         AS skus,
       COUNT(*) FILTER (WHERE ABS(total_value - on_hand_qty * unit_cost) > 1) AS mismatches,
       ROUND(SUM(total_value))                                          AS stored_total,
       ROUND(SUM(on_hand_qty * unit_cost))                              AS recomputed_total
FROM inventory;
