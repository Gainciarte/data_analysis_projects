-- ============================================================
-- SQL 01 - Inventory Queries | 01_schema.sql
-- Creates the 4 base tables (one per sheet of the Kaizen workbook)
-- and the supporting indexes. PostgreSQL 16.
-- ============================================================

DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS sku_items CASCADE;
DROP TABLE IF EXISTS warehouses CASCADE;

CREATE TABLE warehouses (
    warehouse_id  VARCHAR(10) PRIMARY KEY,
    city          TEXT NOT NULL,
    province      TEXT NOT NULL,
    country       TEXT NOT NULL,
    latitude      NUMERIC(9,6),
    longitude     NUMERIC(9,6)
);

CREATE TABLE sku_items (
    sku_id    VARCHAR(10) PRIMARY KEY,
    sku_name  TEXT NOT NULL
);

-- One row per SKU: current stock snapshot + supplier parameters
CREATE TABLE inventory (
    sku_id           VARCHAR(10) PRIMARY KEY REFERENCES sku_items(sku_id),
    vendor_name      TEXT NOT NULL,
    warehouse_id     VARCHAR(10) NOT NULL REFERENCES warehouses(warehouse_id),
    on_hand_qty      NUMERIC(18,6) NOT NULL CHECK (on_hand_qty >= 0),
    unit_cost        NUMERIC(14,4) NOT NULL CHECK (unit_cost >= 0),
    total_value      NUMERIC(16,2) NOT NULL,
    uom              VARCHAR(10),
    avg_lead_days    INT NOT NULL,
    max_lead_days    INT NOT NULL,
    unit_price       NUMERIC(14,4) NOT NULL
);

-- One row per sales order line
CREATE TABLE sales (
    order_number    VARCHAR(20) PRIMARY KEY,
    order_date      DATE NOT NULL,
    sku_id          VARCHAR(10) NOT NULL REFERENCES sku_items(sku_id),
    warehouse_id    VARCHAR(10) NOT NULL REFERENCES warehouses(warehouse_id),
    customer_type   VARCHAR(20) NOT NULL,
    order_qty       NUMERIC(18,6) NOT NULL,
    unit_sale_price NUMERIC(14,5) NOT NULL,
    revenue         NUMERIC(16,2) NOT NULL
);

-- Indexes: every analysis query joins sales -> inventory by SKU and filters by date
CREATE INDEX idx_sales_sku        ON sales (sku_id, order_date);
CREATE INDEX idx_sales_date       ON sales (order_date);
CREATE INDEX idx_sales_warehouse  ON sales (warehouse_id);
CREATE INDEX idx_inventory_vendor ON inventory (vendor_name);
CREATE INDEX idx_inventory_wh     ON inventory (warehouse_id);
