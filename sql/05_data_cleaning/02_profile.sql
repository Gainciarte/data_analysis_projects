-- ============================================================
-- SQL 05 - Data Cleaning | 02_profile.sql
-- BEFORE: profile the raw table. Every query is read-only.
-- "-- [name] title" labels each query; results go to results/<name>.csv
-- ============================================================

-- [p01_raw_shape] Raw shape and key problems
SELECT COUNT(*)                                                         AS raw_rows,
       COUNT(DISTINCT product_id)                                       AS distinct_product_ids,
       COUNT(*) - COUNT(DISTINCT product_id)                            AS surplus_rows_by_product_id,
       COUNT(*) FILTER (WHERE category IS NULL AND discounted_price IS NULL
                          AND actual_price IS NULL AND rating IS NULL)  AS rows_with_no_business_data
FROM raw_amazon;

-- [p02_null_profile] Null / blank profile of the business columns
SELECT col, nulls, ROUND(100.0 * nulls / total, 2) AS pct_null
FROM (
    SELECT COUNT(*) AS total,
           COUNT(*) FILTER (WHERE product_name IS NULL OR TRIM(product_name) = '')               AS product_name,
           COUNT(*) FILTER (WHERE category IS NULL OR TRIM(category) = '')                       AS category,
           COUNT(*) FILTER (WHERE discounted_price IS NULL OR TRIM(discounted_price) = '')       AS discounted_price,
           COUNT(*) FILTER (WHERE actual_price IS NULL OR TRIM(actual_price) = '')               AS actual_price,
           COUNT(*) FILTER (WHERE discount_percentage IS NULL OR TRIM(discount_percentage) = '') AS discount_percentage,
           COUNT(*) FILTER (WHERE rating IS NULL OR TRIM(rating) = '')                           AS rating,
           COUNT(*) FILTER (WHERE rating_count IS NULL OR TRIM(rating_count) = '')               AS rating_count,
           COUNT(*) FILTER (WHERE user_id IS NULL OR TRIM(user_id) = '')                         AS user_id,
           COUNT(*) FILTER (WHERE product_link IS NULL OR TRIM(product_link) = '')               AS product_link
    FROM raw_amazon
) t
CROSS JOIN LATERAL (VALUES ('product_name', t.product_name), ('category', t.category),
                           ('discounted_price', t.discounted_price), ('actual_price', t.actual_price),
                           ('discount_percentage', t.discount_percentage), ('rating', t.rating),
                           ('rating_count', t.rating_count), ('user_id', t.user_id),
                           ('product_link', t.product_link)) AS v(col, nulls)
ORDER BY nulls DESC, col;

-- [p03_format_issues] Format problems found by pattern checks (rows affected)
SELECT issue, rows_affected, example
FROM (
    SELECT 'price stored as text with currency symbol / thousands separator' AS issue,
           COUNT(*) FILTER (WHERE discounted_price !~ '^[0-9.]+$')      AS rows_affected,
           MIN(discounted_price) FILTER (WHERE discounted_price !~ '^[0-9.]+$') AS example
    FROM raw_amazon
    UNION ALL
    SELECT 'discount_percentage stored as a 0-1 fraction, not a percentage',
           COUNT(*) FILTER (WHERE discount_percentage::numeric <= 1),
           MIN(discount_percentage) FILTER (WHERE discount_percentage::numeric <= 1)
    FROM raw_amazon WHERE discount_percentage ~ '^[0-9.]+$'
    UNION ALL
    SELECT 'rating is not a number (placeholder character)',
           COUNT(*), MIN(rating)
    FROM raw_amazon WHERE rating IS NOT NULL AND rating !~ '^[0-5](\.[0-9])?$'
    UNION ALL
    SELECT 'rating_count with thousands separators (incl. Indian 4,26,973 style)',
           COUNT(*), MIN(rating_count)
    FROM raw_amazon WHERE rating_count LIKE '%,%'
    UNION ALL
    SELECT 'mojibake (UTF-8 decoded as Windows-1252) in product_name',
           COUNT(*), MIN(LEFT(product_name, 40))
    FROM raw_amazon WHERE product_name ~ '[âÃÂ]'
    UNION ALL
    SELECT 'category path is CamelCase / glued with "&" (needs standardising)',
           COUNT(*), MIN(category)
    FROM raw_amazon WHERE category ~ '[a-z][A-Z]|&'
    UNION ALL
    SELECT 'reviewers packed in one cell (comma-separated user_id list)',
           COUNT(*), NULL
    FROM raw_amazon WHERE user_id LIKE '%,%'
    UNION ALL
    SELECT 'extra unnamed spill-over columns with data',
           COUNT(*), NULL
    FROM raw_amazon
    WHERE COALESCE(overflow_01, overflow_02, overflow_03, overflow_04, overflow_05, overflow_06, overflow_07,
                   overflow_08, overflow_09, overflow_10, overflow_11, overflow_12, overflow_13, overflow_14,
                   overflow_15, overflow_16) IS NOT NULL
) x;

-- [p04_duplicates] Duplicate analysis: exact duplicate rows vs same product_id with different attributes
WITH by_id AS (
    SELECT product_id, COUNT(*) AS n,
           COUNT(DISTINCT (product_name, discounted_price, actual_price, rating, rating_count, img_link, product_link)) AS distinct_variants
    FROM raw_amazon
    GROUP BY product_id
    HAVING COUNT(*) > 1
)
SELECT COUNT(*)                                          AS product_ids_repeated,
       SUM(n - 1)::int                                   AS surplus_rows,
       COUNT(*) FILTER (WHERE distinct_variants = 1)     AS ids_with_identical_rows,
       COUNT(*) FILTER (WHERE distinct_variants > 1)     AS ids_with_conflicting_values,
       MAX(n)                                            AS max_rows_per_id
FROM by_id;

-- [p05_main_category_raw] Raw first-level categories (before standardising)
SELECT split_part(category, '|', 1) AS raw_main_category, COUNT(*) AS rows
FROM raw_amazon
GROUP BY 1
ORDER BY rows DESC;
