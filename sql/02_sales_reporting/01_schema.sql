-- ============================================================
-- SQL 02 - Sales Reporting | 01_schema.sql
-- Star-style model: 1 fact table (sales) + 3 dimensions
-- (sku_items, warehouses, dim_date). PostgreSQL 16.
-- ============================================================

DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS sku_items CASCADE;
DROP TABLE IF EXISTS warehouses CASCADE;
DROP TABLE IF EXISTS dim_date CASCADE;

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

CREATE TABLE sales (
    order_number    VARCHAR(20) PRIMARY KEY,
    order_date      DATE NOT NULL,
    sku_id          VARCHAR(10) NOT NULL REFERENCES sku_items(sku_id),
    warehouse_id    VARCHAR(10) NOT NULL REFERENCES warehouses(warehouse_id),
    customer_type   VARCHAR(20) NOT NULL,
    order_qty       NUMERIC(18,6) NOT NULL CHECK (order_qty > 0),
    unit_sale_price NUMERIC(14,5) NOT NULL,
    revenue         NUMERIC(16,2) NOT NULL CHECK (revenue >= 0)
);

-- Calendar dimension generated in SQL (covers the full history)
CREATE TABLE dim_date AS
SELECT d::date                          AS date_id,
       EXTRACT(YEAR    FROM d)::int     AS year,
       EXTRACT(QUARTER FROM d)::int     AS quarter,
       EXTRACT(MONTH   FROM d)::int     AS month,
       TO_CHAR(d, 'YYYY-MM')            AS year_month,
       TO_CHAR(d, 'Dy')                 AS weekday,
       EXTRACT(ISODOW  FROM d)::int     AS iso_weekday
FROM generate_series(DATE '2021-01-01', DATE '2023-12-31', INTERVAL '1 day') AS g(d);
ALTER TABLE dim_date ADD PRIMARY KEY (date_id);

-- Indexes for the typical reporting filters / joins
CREATE INDEX idx_sales_date       ON sales (order_date);
CREATE INDEX idx_sales_sku        ON sales (sku_id);
CREATE INDEX idx_sales_wh_date    ON sales (warehouse_id, order_date);
CREATE INDEX idx_sales_cust_type  ON sales (customer_type);
