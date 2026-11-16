-- ============================================================
-- SQL 04 - Supply Chain Queries | 01_schema.sql
-- Normalised model: vendors become their own dimension (built from the
-- raw inventory sheet in 02_transform.sql). PostgreSQL 16.
-- ============================================================

DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS stg_inventory CASCADE;
DROP TABLE IF EXISTS vendors CASCADE;
DROP TABLE IF EXISTS sku_items CASCADE;
DROP TABLE IF EXISTS warehouses CASCADE;

CREATE TABLE warehouses (
    warehouse_id  VARCHAR(10) PRIMARY KEY,
    city          TEXT NOT NULL,
    province      TEXT NOT NULL,
    country       TEXT NOT NULL
);

CREATE TABLE sku_items (
    sku_id    VARCHAR(10) PRIMARY KEY,
    sku_name  TEXT NOT NULL
);

-- Raw copy of the 'Inventory Control' sheet exactly as received
CREATE TABLE stg_inventory (
    sku_id         VARCHAR(10),
    vendor_name    TEXT,
    warehouse_id   VARCHAR(10),
    on_hand_qty    NUMERIC(18,6),
    unit_cost      NUMERIC(14,4),
    total_value    NUMERIC(16,2),
    uom            VARCHAR(10),
    avg_lead_days  INT,
    max_lead_days  INT,
    unit_price     NUMERIC(14,4)
);

CREATE TABLE vendors (
    vendor_id    SERIAL PRIMARY KEY,
    vendor_name  TEXT NOT NULL UNIQUE
);

CREATE TABLE inventory (
    sku_id         VARCHAR(10) PRIMARY KEY REFERENCES sku_items(sku_id),
    vendor_id      INT NOT NULL REFERENCES vendors(vendor_id),
    warehouse_id   VARCHAR(10) NOT NULL REFERENCES warehouses(warehouse_id),
    on_hand_qty    NUMERIC(18,6) NOT NULL CHECK (on_hand_qty >= 0),
    unit_cost      NUMERIC(14,4) NOT NULL CHECK (unit_cost >= 0),
    avg_lead_days  INT NOT NULL CHECK (avg_lead_days > 0),
    max_lead_days  INT NOT NULL,
    unit_price     NUMERIC(14,4) NOT NULL,
    CONSTRAINT chk_lead_time CHECK (max_lead_days >= avg_lead_days)
);

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

CREATE INDEX idx_sales_sku_date   ON sales (sku_id, order_date);
CREATE INDEX idx_inventory_vendor ON inventory (vendor_id);
CREATE INDEX idx_inventory_wh     ON inventory (warehouse_id);
