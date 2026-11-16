-- ============================================================
-- SQL 04 - Supply Chain Queries | 02_transform.sql
-- Staging -> normalised tables. Vendor names are trimmed because the
-- raw sheet contains trailing spaces (e.g. 'Heritage ').
-- ============================================================

INSERT INTO vendors (vendor_name)
SELECT DISTINCT TRIM(vendor_name)
FROM stg_inventory
ORDER BY 1;

INSERT INTO inventory (sku_id, vendor_id, warehouse_id, on_hand_qty, unit_cost,
                       avg_lead_days, max_lead_days, unit_price)
SELECT s.sku_id, v.vendor_id, s.warehouse_id, s.on_hand_qty, s.unit_cost,
       s.avg_lead_days, s.max_lead_days, s.unit_price
FROM stg_inventory s
JOIN vendors v ON v.vendor_name = TRIM(s.vendor_name);

ANALYZE;
