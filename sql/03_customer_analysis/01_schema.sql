-- ============================================================
-- SQL 03 - Customer Analysis | 01_schema.sql
-- Raw transaction table of UCI "Online Retail II" (1,067,371 lines).
-- ============================================================

DROP TABLE IF EXISTS raw_transactions CASCADE;

CREATE TABLE raw_transactions (
    invoice      TEXT NOT NULL,          -- 'C' prefix = cancellation / credit note
    stock_code   TEXT,
    description  TEXT,
    quantity     INT NOT NULL,
    invoice_ts   TIMESTAMP NOT NULL,
    unit_price   NUMERIC(12,3) NOT NULL,
    customer_id  INT,                    -- NULL for guest checkouts
    country      TEXT
);
