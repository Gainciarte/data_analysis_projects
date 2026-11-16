-- ============================================================
-- SQL 02 - Sales Reporting | 01_schema.sql
-- Two real sources, two schemas of the same database:
--   retail  = UCI "Online Retail II" (1,067,371 lines, Dec-2009 .. Dec-2011, GBP)  -> main YoY / MoM reporting
--   amazon  = Amazon India "Clean Data" sheet (107,160 shipped lines, Mar-Jun 2022, INR) -> second, smaller report
-- Each schema = raw table (loaded with COPY) + a star schema (dimensions + fact table).
-- The star schemas are filled in 02_model.sql. PostgreSQL 13+.
-- ============================================================

DROP SCHEMA IF EXISTS retail CASCADE;
DROP SCHEMA IF EXISTS amazon CASCADE;
CREATE SCHEMA retail;
CREATE SCHEMA amazon;

-- ------------------------------------------------------------
-- RETAIL (Online Retail II)
-- ------------------------------------------------------------
CREATE TABLE retail.raw_transactions (
    invoice      TEXT NOT NULL,          -- 'C' prefix = cancellation / credit note, 'A' = bad-debt adjustment
    stock_code   TEXT NOT NULL,
    description  TEXT,
    quantity     INT NOT NULL,
    invoice_ts   TIMESTAMP NOT NULL,
    unit_price   NUMERIC(12,3) NOT NULL,
    customer_id  INT,                    -- NULL for guest checkouts
    country      TEXT
);

CREATE TABLE retail.dim_date (
    date_id        DATE PRIMARY KEY,
    year           INT  NOT NULL,
    quarter        INT  NOT NULL,
    month          INT  NOT NULL,
    year_month     TEXT NOT NULL,        -- 'YYYY-MM'
    month_start    DATE NOT NULL,
    month_end      DATE NOT NULL,
    quarter_start  DATE NOT NULL,
    weekday        TEXT NOT NULL,        -- 'Mon' ... 'Sun'
    iso_weekday    INT  NOT NULL,        -- 1 = Monday ... 7 = Sunday
    fy             INT  NOT NULL         -- business year Dec-Nov, named after the year it ends in (FY2010 = 2009-12-01 .. 2010-11-30)
);

CREATE TABLE retail.dim_country (
    country_id  SERIAL PRIMARY KEY,
    country     TEXT NOT NULL UNIQUE
);

CREATE TABLE retail.dim_product (
    stock_code    TEXT PRIMARY KEY,
    description   TEXT,                                           -- most frequent description of the code
    product_kind  TEXT NOT NULL CHECK (product_kind IN ('PRODUCT', 'NON_PRODUCT'))
);

CREATE TABLE retail.dim_customer (
    customer_id        INT PRIMARY KEY,
    first_order_date   DATE NOT NULL,
    first_order_month  DATE NOT NULL                              -- month of the first valid sale (new vs returning)
);

CREATE TABLE retail.fact_lines (
    line_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    invoice       TEXT NOT NULL,
    invoice_ts    TIMESTAMP NOT NULL,
    invoice_date  DATE NOT NULL REFERENCES retail.dim_date (date_id),
    invoice_hour  SMALLINT NOT NULL,
    stock_code    TEXT NOT NULL REFERENCES retail.dim_product (stock_code),
    customer_id   INT,                                            -- NULL = guest checkout
    country_id    INT NOT NULL REFERENCES retail.dim_country (country_id),
    line_type     TEXT NOT NULL CHECK (line_type IN ('SALE', 'CANCELLATION', 'NON_PRODUCT', 'ADJUSTMENT', 'INVALID')),
    quantity      INT NOT NULL,
    unit_price    NUMERIC(12,3) NOT NULL,
    line_amount   NUMERIC(14,2) NOT NULL                          -- quantity x unit_price (negative for cancellations)
);

-- ------------------------------------------------------------
-- AMAZON INDIA ('Clean Data' sheet of excel/01_inventory_control)
-- ------------------------------------------------------------
CREATE TABLE amazon.raw_orders (
    sku          TEXT NOT NULL,
    category     TEXT NOT NULL,
    stored_date  DATE NOT NULL,          -- date exactly as stored in the workbook (day/month swapped when day <= 12)
    size         TEXT NOT NULL,
    qty          INT  NOT NULL,
    amount       NUMERIC(12,2) NOT NULL  -- INR
);

CREATE TABLE amazon.dim_date (
    date_id      DATE PRIMARY KEY,
    year         INT  NOT NULL,
    month        INT  NOT NULL,
    year_month   TEXT NOT NULL,
    week_start   DATE NOT NULL,          -- Monday of the ISO week
    weekday      TEXT NOT NULL,
    iso_weekday  INT  NOT NULL
);

CREATE TABLE amazon.dim_category (
    category_id  SERIAL PRIMARY KEY,
    category     TEXT NOT NULL UNIQUE
);

CREATE TABLE amazon.dim_size (
    size        TEXT PRIMARY KEY,
    size_order  INT NOT NULL             -- XS < S < M < L < XL < XXL < 3XL ... 6XL, Free last
);

CREATE TABLE amazon.dim_product (
    sku          TEXT PRIMARY KEY,
    style_code   TEXT NOT NULL,          -- part of the SKU before the first hyphen (design shared by sizes / colours)
    category_id  INT NOT NULL REFERENCES amazon.dim_category (category_id)
);

CREATE TABLE amazon.fact_order_lines (
    line_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_date   DATE NOT NULL REFERENCES amazon.dim_date (date_id),   -- repaired date
    stored_date  DATE NOT NULL,                                        -- original (swapped) date, kept for audit
    sku          TEXT NOT NULL REFERENCES amazon.dim_product (sku),
    size         TEXT NOT NULL REFERENCES amazon.dim_size (size),
    qty          INT  NOT NULL CHECK (qty > 0),
    amount       NUMERIC(12,2) NOT NULL CHECK (amount > 0)
);
