-- ============================================================
-- SQL 05 - Data Cleaning | 03_clean.sql
-- Raw -> typed -> deduplicated -> clean tables. Run top to bottom.
-- Every step writes its row count to cleaning_log (before/after audit).
-- ============================================================

DROP TABLE IF EXISTS cleaning_log, rejected_rows, stg_typed, clean_products, product_reviewers CASCADE;
DROP VIEW  IF EXISTS v_category_summary;

CREATE TABLE cleaning_log (
    step_no  SERIAL PRIMARY KEY,
    step     TEXT NOT NULL,
    row_count BIGINT NOT NULL
);

-- ---------------------------------------------------------------
-- Helper functions
-- ---------------------------------------------------------------
-- UTF-8 text that was decoded as Windows-1252 ("â€“" instead of "–")
CREATE OR REPLACE FUNCTION fix_mojibake(t TEXT) RETURNS TEXT
LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
    pairs TEXT[][] := ARRAY[
        ['â€“', '–'], ['â€”', '—'], ['â€™', '’'], ['â€˜', '‘'], ['â€œ', '“'], ['â€¦', '…'],
        ['â„¢', '™'], ['â‚¹', '₹'], ['Â®', '®'], ['Â©', '©'], ['Â°', '°'], ['Ã—', '×'],
        [E'â€', '”'], [E'â€Ž', ''],
        ['Â ', ' '], ['Â', '']
    ];
    i INT;
BEGIN
    IF t IS NULL THEN RETURN NULL; END IF;
    FOR i IN 1 .. array_length(pairs, 1) LOOP
        t := replace(t, pairs[i][1], pairs[i][2]);
    END LOOP;
    RETURN t;
END $$;

-- 'Computers&Accessories' -> 'Computers & Accessories', 'OfficeProducts' -> 'Office Products'
CREATE OR REPLACE FUNCTION std_category(t TEXT) RETURNS TEXT
LANGUAGE sql IMMUTABLE AS $$
    SELECT NULLIF(TRIM(regexp_replace(
               regexp_replace(
                 regexp_replace(
                   regexp_replace(t, '\s*&\s*', ' & ', 'g'),
                   '([a-z])([A-Z])', '\1 \2', 'g'),
                 '([A-Z])([A-Z][a-z])', '\1 \2', 'g'),
               '\s*,\s*', ', ', 'g')), '')
$$;

INSERT INTO cleaning_log (step, row_count) SELECT '0. raw rows loaded', COUNT(*) FROM raw_amazon;

-- ---------------------------------------------------------------
-- Step 1: type casting + text standardisation (still one row per raw row)
-- ---------------------------------------------------------------
CREATE TABLE stg_typed AS
SELECT raw_row_id,
       UPPER(TRIM(product_id))                                                        AS product_id,
       TRIM(regexp_replace(fix_mojibake(product_name), '\s+', ' ', 'g'))              AS product_name,
       std_category(split_part(category, '|', 1))                                     AS main_category,
       std_category(NULLIF(split_part(category, '|', 2), ''))                         AS sub_category,
       std_category(NULLIF(split_part(category, '|', 3), ''))                         AS leaf_category,
       NULLIF(regexp_replace(discounted_price, '[^0-9.]', '', 'g'), '')::NUMERIC(10,2) AS discounted_price,
       NULLIF(regexp_replace(actual_price,     '[^0-9.]', '', 'g'), '')::NUMERIC(10,2) AS actual_price,
       -- 0.64 (fraction) -> 64.00 (percent)
       ROUND(NULLIF(TRIM(discount_percentage), '')::NUMERIC * 100, 2)                 AS discount_pct,
       -- placeholder '|' and any non 0-5 value become NULL (not imputed)
       CASE WHEN rating ~ '^[0-5](\.[0-9])?$' THEN rating::NUMERIC(2,1) END          AS rating,
       -- '4,26,973' / '24,269' -> integer
       NULLIF(regexp_replace(rating_count, '[^0-9]', '', 'g'), '')::INT              AS rating_count,
       fix_mojibake(TRIM(about_product))                                              AS about_product,
       NULLIF(TRIM(img_link), '')                                                     AS img_link,
       NULLIF(TRIM(product_link), '')                                                 AS product_link,
       user_id, review_id
FROM raw_amazon;

INSERT INTO cleaning_log (step, row_count) SELECT '1. after typing & standardising', COUNT(*) FROM stg_typed;

-- ---------------------------------------------------------------
-- Step 2: quarantine rows that carry no business data
-- ---------------------------------------------------------------
CREATE TABLE rejected_rows (
    raw_row_id  INT PRIMARY KEY,
    product_id  TEXT,
    reason      TEXT NOT NULL
);

INSERT INTO rejected_rows (raw_row_id, product_id, reason)
SELECT raw_row_id, product_id, 'no price, category or rating (empty listing)'
FROM stg_typed
WHERE main_category IS NULL AND discounted_price IS NULL AND actual_price IS NULL AND rating IS NULL;

-- ---------------------------------------------------------------
-- Step 3: deduplicate by product_id (keep the most complete row; ties -> first row)
-- ---------------------------------------------------------------
WITH ranked AS (
    SELECT raw_row_id, product_id,
           ROW_NUMBER() OVER (
               PARTITION BY product_id
               ORDER BY (rating_count IS NOT NULL) DESC,
                        rating_count DESC NULLS LAST,
                        (product_link IS NOT NULL) DESC,
                        raw_row_id
           ) AS rn
    FROM stg_typed
    WHERE raw_row_id NOT IN (SELECT raw_row_id FROM rejected_rows)
)
INSERT INTO rejected_rows (raw_row_id, product_id, reason)
SELECT raw_row_id, product_id, 'duplicate product_id (less complete copy)'
FROM ranked
WHERE rn > 1;

INSERT INTO cleaning_log (step, row_count)
SELECT '2. after removing empty rows', COUNT(*) FROM stg_typed
WHERE raw_row_id NOT IN (SELECT raw_row_id FROM rejected_rows WHERE reason LIKE 'no price%');

-- ---------------------------------------------------------------
-- Step 4: clean table with constraints
-- ---------------------------------------------------------------
CREATE TABLE clean_products (
    product_id        CHAR(10) PRIMARY KEY,
    product_name      TEXT NOT NULL,
    main_category     TEXT NOT NULL,
    sub_category      TEXT,
    leaf_category     TEXT,
    discounted_price  NUMERIC(10,2) NOT NULL CHECK (discounted_price > 0),
    actual_price      NUMERIC(10,2) NOT NULL CHECK (actual_price > 0),
    discount_pct      NUMERIC(5,2)  NOT NULL CHECK (discount_pct BETWEEN 0 AND 100),
    rating            NUMERIC(2,1)  CHECK (rating BETWEEN 0 AND 5),
    rating_count      INT           CHECK (rating_count >= 0),
    about_product     TEXT,
    img_link          TEXT,
    product_link      TEXT,
    CONSTRAINT chk_price_order CHECK (discounted_price <= actual_price)
);

INSERT INTO clean_products
SELECT product_id, product_name, main_category, sub_category, leaf_category,
       discounted_price, actual_price, discount_pct, rating, rating_count,
       about_product, img_link, product_link
FROM stg_typed
WHERE raw_row_id NOT IN (SELECT raw_row_id FROM rejected_rows);

INSERT INTO cleaning_log (step, row_count) SELECT '3. after deduplicating = clean_products', COUNT(*) FROM clean_products;

CREATE INDEX idx_clean_main_category ON clean_products (main_category);
CREATE INDEX idx_clean_rating        ON clean_products (rating);

-- ---------------------------------------------------------------
-- Step 5: normalise the packed reviewer list into one row per review
-- (user_id / review_id never contain commas, so they split safely;
--  review_title / review_content do contain commas and are NOT split)
-- ---------------------------------------------------------------
CREATE TABLE product_reviewers AS
SELECT DISTINCT t.product_id::CHAR(10) AS product_id, ids.review_id, ids.user_id
FROM stg_typed t
JOIN clean_products c ON c.product_id = t.product_id::CHAR(10)
CROSS JOIN LATERAL (
    SELECT TRIM(r.review_id) AS review_id, TRIM(u.user_id) AS user_id
    FROM unnest(string_to_array(t.review_id, ',')) WITH ORDINALITY AS r(review_id, n)
    JOIN unnest(string_to_array(t.user_id,   ',')) WITH ORDINALITY AS u(user_id,  n) USING (n)
) ids
WHERE t.review_id IS NOT NULL AND t.user_id IS NOT NULL;

ALTER TABLE product_reviewers ADD PRIMARY KEY (product_id, review_id);
CREATE INDEX idx_reviewers_user ON product_reviewers (user_id);

INSERT INTO cleaning_log (step, row_count) SELECT '4. product_reviewers (1 row per review)', COUNT(*) FROM product_reviewers;

-- Analysis view on top of the clean layer
CREATE VIEW v_category_summary AS
SELECT main_category,
       COUNT(*)                          AS products,
       ROUND(AVG(discount_pct), 1)       AS avg_discount_pct,
       ROUND(AVG(rating), 2)             AS avg_rating,
       SUM(rating_count)                 AS total_ratings
FROM clean_products
GROUP BY main_category;

ANALYZE;
