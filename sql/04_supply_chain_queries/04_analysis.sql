-- ============================================================
-- SQL 04 - Supply Chain Queries | 04_analysis.sql
-- Run top to bottom. "-- [name] title" labels each query; every result
-- set is saved to results/<name>.csv by run_supply_chain.py
-- ============================================================

-- [q01_validation] Model validation: raw vs normalised vendor names, lead-time rules
SELECT (SELECT COUNT(DISTINCT vendor_name) FROM stg_inventory)                    AS distinct_vendor_names_raw,
       (SELECT COUNT(*) FROM vendors)                                             AS vendors_after_trim,
       (SELECT COUNT(*) FROM stg_inventory WHERE vendor_name <> TRIM(vendor_name)) AS rows_with_untrimmed_vendor,
       (SELECT COUNT(*) FROM inventory WHERE max_lead_days < avg_lead_days)       AS skus_max_lt_below_avg,
       (SELECT COUNT(*) FROM inventory)                                           AS skus;

-- [q02_lead_time_buckets] SKU distribution by average lead-time bucket
SELECT CASE WHEN avg_lead_days <= 30 THEN '1) <= 30 days'
            WHEN avg_lead_days <= 60 THEN '2) 31-60 days'
            WHEN avg_lead_days <= 90 THEN '3) 61-90 days'
            ELSE '4) > 90 days' END                                   AS lead_time_bucket,
       COUNT(*)                                                       AS skus,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)             AS pct_skus,
       ROUND(SUM(stock_value))                                        AS stock_value,
       ROUND(AVG(lt_variability), 2)                                  AS avg_lt_variability
FROM v_sku_supply
GROUP BY 1
ORDER BY 1;

-- [q03_vendor_scorecard] Vendor scorecard: lead time, variability, margin, stock and revenue-at-risk exposure
WITH sku_risk AS (
    SELECT *,
           CASE WHEN days_to_order_by < 0 THEN -days_to_order_by * avg_daily_qty * unit_price ELSE 0 END AS revenue_at_risk
    FROM v_sku_supply
)
SELECT vendor_name,
       COUNT(*)                                                         AS skus,
       ROUND(AVG(avg_lead_days), 1)                                     AS avg_lead_days,
       ROUND(AVG(max_lead_days), 1)                                     AS avg_max_lead_days,
       ROUND(AVG(lt_variability), 2)                                    AS lt_variability,
       ROUND(100 * AVG(gross_margin_pct), 1)                            AS avg_margin_pct,
       ROUND(SUM(stock_value))                                          AS stock_value,
       COUNT(*) FILTER (WHERE days_to_order_by < 0)                     AS skus_late_to_order,
       ROUND(SUM(revenue_at_risk))                                      AS revenue_at_risk
FROM sku_risk
GROUP BY vendor_name
ORDER BY revenue_at_risk DESC;

-- [q04_vendor_ranking] Vendor performance index: rank on 3 metrics (lower is better) and average the ranks
WITH m AS (
    SELECT vendor_name,
           COUNT(*)                                                                AS skus,
           AVG(avg_lead_days)                                                      AS avg_lt,
           AVG(lt_variability)                                                     AS lt_var,
           100.0 * COUNT(*) FILTER (WHERE days_to_order_by < 0)
                 / NULLIF(COUNT(*) FILTER (WHERE days_to_order_by IS NOT NULL), 0) AS pct_late
    FROM v_sku_supply
    GROUP BY vendor_name
),
r AS (
    SELECT *,
           RANK() OVER (ORDER BY avg_lt)    AS rank_lead_time,
           RANK() OVER (ORDER BY lt_var)    AS rank_variability,
           RANK() OVER (ORDER BY pct_late)  AS rank_late_orders
    FROM m
)
SELECT vendor_name, skus,
       ROUND(avg_lt, 1)   AS avg_lead_days,
       ROUND(lt_var, 2)   AS lt_variability,
       ROUND(pct_late, 1) AS pct_skus_late_to_order,
       rank_lead_time, rank_variability, rank_late_orders,
       ROUND((rank_lead_time + rank_variability + rank_late_orders) / 3.0, 1) AS avg_rank,
       NTILE(4) OVER (ORDER BY rank_lead_time + rank_variability + rank_late_orders) AS performance_quartile
FROM r
ORDER BY avg_rank, vendor_name;

-- [q05_order_by_calendar] Replenishment calendar: when must POs be placed (days_to_order_by = cover - lead time)
SELECT CASE WHEN days_to_order_by < 0   THEN '1) Late (already inside lead time)'
            WHEN days_to_order_by <= 30 THEN '2) Order within 30 days'
            WHEN days_to_order_by <= 90 THEN '3) Order in 31-90 days'
            WHEN days_to_order_by <= 365 THEN '4) Order in 91-365 days'
            ELSE '5) More than 1 year away' END                            AS order_window,
       COUNT(*)                                                            AS skus,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)                  AS pct_skus,
       ROUND(SUM(units_12m * unit_cost))                                   AS annual_purchase_value
FROM v_sku_supply
WHERE days_to_order_by IS NOT NULL
GROUP BY 1
ORDER BY 1;

-- [q06_late_skus_top] Top 12 late-to-order SKUs ranked by revenue at risk
SELECT sku_id, vendor_name, warehouse_id, on_hand_qty,
       ROUND(avg_daily_qty, 1)                       AS daily_demand,
       days_of_cover, avg_lead_days,
       ROUND(-days_to_order_by, 1)                   AS days_late,
       ROUND(-days_to_order_by * avg_daily_qty * unit_price) AS revenue_at_risk
FROM v_sku_supply
WHERE days_to_order_by < 0
ORDER BY revenue_at_risk DESC
LIMIT 12;

-- [q07_warehouse_comparison] Warehouse comparison: network profile + sales served (join inventory side and sales side)
WITH inv AS (
    SELECT warehouse_id, COUNT(*) AS skus, SUM(stock_value) AS stock_value,
           AVG(avg_lead_days) AS avg_lead_days, AVG(lt_variability) AS lt_variability,
           COUNT(*) FILTER (WHERE days_to_order_by < 0) AS skus_late
    FROM v_sku_supply
    GROUP BY warehouse_id
),
sal AS (
    SELECT warehouse_id, COUNT(*) AS orders, SUM(revenue) AS revenue
    FROM sales
    GROUP BY warehouse_id
)
SELECT w.warehouse_id, w.city, w.province,
       inv.skus, ROUND(inv.stock_value) AS stock_value,
       ROUND(inv.avg_lead_days, 1)      AS avg_lead_days,
       ROUND(inv.lt_variability, 2)     AS lt_variability,
       inv.skus_late,
       sal.orders, ROUND(sal.revenue) AS revenue,
       ROUND(inv.stock_value / sal.revenue * 100, 1) AS stock_as_pct_of_revenue
FROM warehouses w
JOIN inv USING (warehouse_id)
JOIN sal USING (warehouse_id)
ORDER BY revenue DESC;

-- [q08_province_rollup] Province > warehouse roll-up of stock value (GROUPING SETS / ROLLUP)
SELECT COALESCE(province, 'ALL')      AS province,
       COALESCE(warehouse_id, 'ALL')  AS warehouse_id,
       COUNT(*)                       AS skus,
       ROUND(SUM(stock_value))        AS stock_value
FROM v_sku_supply
GROUP BY ROLLUP (province, warehouse_id)
ORDER BY province NULLS LAST, warehouse_id NULLS LAST;

-- [q09_vendor_dependency] Vendor dependency inside each warehouse: share of stock value (window) - top vendor per warehouse
WITH vw AS (
    SELECT warehouse_id, vendor_name, SUM(stock_value) AS stock_value, COUNT(*) AS skus
    FROM v_sku_supply
    GROUP BY warehouse_id, vendor_name
),
ranked AS (
    SELECT *,
           ROUND(100.0 * stock_value / SUM(stock_value) OVER (PARTITION BY warehouse_id), 1) AS pct_of_warehouse,
           ROW_NUMBER() OVER (PARTITION BY warehouse_id ORDER BY stock_value DESC)          AS rn
    FROM vw
)
SELECT warehouse_id, rn AS rank_in_warehouse, vendor_name, skus, ROUND(stock_value) AS stock_value, pct_of_warehouse
FROM ranked
WHERE rn <= 3
ORDER BY warehouse_id, rn;

-- [q10_safety_stock_investment] Safety stock needed for a 95% service level, by vendor (versus current stock)
WITH ss AS (
    SELECT vendor_name,
           ROUND(1.645 * sd_daily_qty * SQRT(avg_lead_days::numeric) * unit_cost)                AS safety_stock_value,
           ROUND(avg_daily_qty * avg_lead_days * unit_cost)                             AS lead_time_demand_value,
           stock_value
    FROM v_sku_supply
    WHERE units_12m > 0
)
SELECT vendor_name,
       SUM(safety_stock_value)::bigint                  AS safety_stock_value,
       SUM(lead_time_demand_value)::bigint              AS lead_time_demand_value,
       ROUND(SUM(stock_value))                          AS current_stock_value,
       ROUND(100.0 * SUM(safety_stock_value) / SUM(SUM(safety_stock_value)) OVER (), 1) AS pct_of_total_safety_stock
FROM ss
GROUP BY vendor_name
ORDER BY safety_stock_value DESC
LIMIT 10;

-- [q11_longest_lead_vs_margin] Long-lead SKUs (> 90 days): are they compensated by margin? (compare with the rest)
SELECT CASE WHEN avg_lead_days > 90 THEN 'Lead time > 90 days' ELSE 'Lead time <= 90 days' END AS segment,
       COUNT(*)                                          AS skus,
       ROUND(100 * AVG(gross_margin_pct), 1)             AS avg_margin_pct,
       ROUND((100 * PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gross_margin_pct))::numeric, 1) AS median_margin_pct,
       ROUND(AVG(lt_variability), 2)                     AS avg_lt_variability,
       ROUND(SUM(stock_value))                           AS stock_value
FROM v_sku_supply
GROUP BY 1
ORDER BY 1;

-- [q12_headline] Network headline numbers
SELECT COUNT(*)                                                       AS skus,
       (SELECT COUNT(*) FROM vendors)                                 AS vendors,
       ROUND(AVG(avg_lead_days), 1)                                   AS avg_lead_days,
       MAX(max_lead_days)                                             AS longest_max_lead_days,
       ROUND(SUM(stock_value))                                        AS stock_value,
       COUNT(*) FILTER (WHERE days_to_order_by < 0)                   AS skus_late_to_order,
       ROUND(SUM(CASE WHEN days_to_order_by < 0 THEN -days_to_order_by * avg_daily_qty * unit_price END)) AS revenue_at_risk
FROM v_sku_supply;
