-- ============================================================
-- SQL 05 - Data Cleaning | 01_schema.sql
-- Raw layer: the Excel sheet loaded 1:1 as TEXT (nothing is converted, trimmed
-- or dropped at load time). All cleaning happens in SQL in 03_clean.sql.
-- ============================================================

DROP TABLE IF EXISTS raw_amazon CASCADE;

CREATE TABLE raw_amazon (
    raw_row_id           INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,   -- order of the rows in the sheet
    product_id           TEXT,
    product_name         TEXT,
    category             TEXT,
    discounted_price     TEXT,
    actual_price         TEXT,
    discount_percentage  TEXT,
    rating               TEXT,
    rating_count         TEXT,
    about_product        TEXT,
    user_id              TEXT,      -- comma-separated list of reviewers (1 row per product)
    user_name            TEXT,
    review_id            TEXT,      -- comma-separated list of review ids
    review_title         TEXT,
    review_content       TEXT,
    img_link             TEXT,
    product_link         TEXT,
    -- the sheet also carries 16 unnamed trailing columns (spill-over text); kept raw so they can be profiled
    overflow_01 TEXT, overflow_02 TEXT, overflow_03 TEXT, overflow_04 TEXT,
    overflow_05 TEXT, overflow_06 TEXT, overflow_07 TEXT, overflow_08 TEXT,
    overflow_09 TEXT, overflow_10 TEXT, overflow_11 TEXT, overflow_12 TEXT,
    overflow_13 TEXT, overflow_14 TEXT, overflow_15 TEXT, overflow_16 TEXT
);
