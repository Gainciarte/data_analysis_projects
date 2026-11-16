-- ============================================================
-- SQL 02 - Sales Reporting | 02_model.sql
-- Fills the star schemas from the raw tables and creates the indexes.
--
-- RETAIL: every raw line is kept in fact_lines and tagged with a line_type, so nothing is
--         silently dropped. Priority of the rules (first match wins):
--   1. ADJUSTMENT   invoice starts with 'A'            (bad-debt adjustments, not sales)
--   2. NON_PRODUCT  stock code does not start with 5 digits: POST, DOT, M, D, S, B, BANK CHARGES,
--                   AMAZONFEE, ADJUST, CRUK, gift vouchers ... (carriage, fees, manual entries)
--   3. CANCELLATION invoice starts with 'C'            (credit notes, negative quantity)
--   4. INVALID      quantity <= 0 or unit_price <= 0   (write-offs, damaged / lost stock, free items)
--   5. SALE         everything else = valid product sale
-- Revenue = SUM(line_amount) of SALE lines (gross). Cancellations are reported separately and
-- as net revenue = SALE + CANCELLATION. Guest checkouts (no customer id) ARE sales and stay in
-- the revenue; they are only excluded from the customer-level reports (new vs returning).
--
-- AMAZON: the workbook has day and month swapped for every date whose stored day is <= 12
--         (e.g. 2022-04-01 was stored as 2022-01-04). The repair swaps them back in SQL:
--         the repaired range is 2022-03-31 .. 2022-06-29.
-- ============================================================

-- ---------------------------- RETAIL ----------------------------
INSERT INTO retail.dim_date
SELECT d::date,
       EXTRACT(YEAR    FROM d)::int,
       EXTRACT(QUARTER FROM d)::int,
       EXTRACT(MONTH   FROM d)::int,
       TO_CHAR(d, 'YYYY-MM'),
       date_trunc('month', d)::date,
       (date_trunc('month', d) + INTERVAL '1 month' - INTERVAL '1 day')::date,
       date_trunc('quarter', d)::date,
       TO_CHAR(d, 'Dy'),
       EXTRACT(ISODOW FROM d)::int,
       EXTRACT(YEAR FROM d + INTERVAL '1 month')::int
FROM generate_series(DATE '2009-12-01', DATE '2011-12-31', INTERVAL '1 day') AS g(d);

INSERT INTO retail.dim_country (country)
SELECT DISTINCT COALESCE(NULLIF(TRIM(country), ''), 'Unspecified')
FROM retail.raw_transactions
ORDER BY 1;

-- Stock codes are upper-cased / trimmed (the raw file mixes '15056bl' and '15056BL').
-- Description = the most frequent one for the code.
INSERT INTO retail.dim_product (stock_code, description, product_kind)
WITH d AS (
    SELECT UPPER(TRIM(stock_code)) AS stock_code, TRIM(description) AS description, COUNT(*) AS n
    FROM retail.raw_transactions
    GROUP BY 1, 2
),
best AS (
    SELECT DISTINCT ON (stock_code) stock_code, description
    FROM d
    ORDER BY stock_code, (description IS NULL), n DESC, description
)
SELECT stock_code,
       description,
       CASE WHEN stock_code ~ '^[0-9]{5}' THEN 'PRODUCT' ELSE 'NON_PRODUCT' END
FROM best;

INSERT INTO retail.fact_lines (invoice, invoice_ts, invoice_date, invoice_hour, stock_code, customer_id,
                               country_id, line_type, quantity, unit_price, line_amount)
SELECT r.invoice,
       r.invoice_ts,
       r.invoice_ts::date,
       EXTRACT(HOUR FROM r.invoice_ts)::smallint,
       UPPER(TRIM(r.stock_code)),
       r.customer_id,
       c.country_id,
       CASE WHEN r.invoice ~ '^A'                           THEN 'ADJUSTMENT'
            WHEN UPPER(TRIM(r.stock_code)) !~ '^[0-9]{5}'   THEN 'NON_PRODUCT'
            WHEN r.invoice ~ '^C'                           THEN 'CANCELLATION'
            WHEN r.quantity <= 0 OR r.unit_price <= 0       THEN 'INVALID'
            ELSE 'SALE' END,
       r.quantity,
       r.unit_price,
       ROUND(r.quantity * r.unit_price, 2)
FROM retail.raw_transactions r
JOIN retail.dim_country c ON c.country = COALESCE(NULLIF(TRIM(r.country), ''), 'Unspecified');

-- Customers = identified buyers with at least one valid sale; first_order_month drives new vs returning
INSERT INTO retail.dim_customer (customer_id, first_order_date, first_order_month)
SELECT customer_id, MIN(invoice_date), date_trunc('month', MIN(invoice_date))::date
FROM retail.fact_lines
WHERE line_type = 'SALE' AND customer_id IS NOT NULL
GROUP BY customer_id;

-- Indexes for the typical reporting filters / joins
CREATE INDEX idx_fact_lines_date      ON retail.fact_lines (invoice_date);
CREATE INDEX idx_fact_lines_type_date ON retail.fact_lines (line_type, invoice_date);
CREATE INDEX idx_fact_lines_product   ON retail.fact_lines (stock_code);
CREATE INDEX idx_fact_lines_country   ON retail.fact_lines (country_id);
CREATE INDEX idx_fact_lines_customer  ON retail.fact_lines (customer_id, invoice_date);
CREATE INDEX idx_fact_lines_invoice   ON retail.fact_lines (invoice);
ANALYZE retail.fact_lines;

-- ---------------------------- AMAZON ----------------------------
-- Dates are repaired in SQL: stored day <= 12 -> swap day and month
INSERT INTO amazon.dim_date
SELECT d::date,
       EXTRACT(YEAR  FROM d)::int,
       EXTRACT(MONTH FROM d)::int,
       TO_CHAR(d, 'YYYY-MM'),
       date_trunc('week', d)::date,
       TO_CHAR(d, 'Dy'),
       EXTRACT(ISODOW FROM d)::int
FROM generate_series(DATE '2022-03-01', DATE '2022-06-30', INTERVAL '1 day') AS g(d);

INSERT INTO amazon.dim_category (category)
SELECT DISTINCT category FROM amazon.raw_orders ORDER BY 1;

INSERT INTO amazon.dim_size (size, size_order)
SELECT s, CASE s WHEN 'XS' THEN 1 WHEN 'S' THEN 2 WHEN 'M' THEN 3 WHEN 'L' THEN 4 WHEN 'XL' THEN 5
                 WHEN 'XXL' THEN 6 WHEN '3XL' THEN 7 WHEN '4XL' THEN 8 WHEN '5XL' THEN 9
                 WHEN '6XL' THEN 10 ELSE 99 END
FROM (SELECT DISTINCT size AS s FROM amazon.raw_orders) x;

INSERT INTO amazon.dim_product (sku, style_code, category_id)
SELECT r.sku, split_part(r.sku, '-', 1), MIN(c.category_id)
FROM amazon.raw_orders r
JOIN amazon.dim_category c ON c.category = r.category
GROUP BY r.sku;

INSERT INTO amazon.fact_order_lines (order_date, stored_date, sku, size, qty, amount)
SELECT CASE WHEN EXTRACT(DAY FROM stored_date) <= 12
            THEN make_date(EXTRACT(YEAR FROM stored_date)::int,
                           EXTRACT(DAY  FROM stored_date)::int,      -- stored day becomes the month
                           EXTRACT(MONTH FROM stored_date)::int)     -- stored month becomes the day
            ELSE stored_date END,
       stored_date, sku, size, qty, amount
FROM amazon.raw_orders;

CREATE INDEX idx_amz_fact_date ON amazon.fact_order_lines (order_date);
CREATE INDEX idx_amz_fact_sku  ON amazon.fact_order_lines (sku);
CREATE INDEX idx_amz_fact_size ON amazon.fact_order_lines (size);
CREATE INDEX idx_amz_prod_cat  ON amazon.dim_product (category_id);
ANALYZE amazon.fact_order_lines;
