-- ============================================================
-- SQL 05 - Data Cleaning | 04_validation.sql
-- AFTER: validation queries on the clean layer + before/after audit.
-- Every "violations" column must be 0.
-- ============================================================

-- [v01_before_after] Row-count audit of every cleaning step
SELECT step_no, step, row_count,
       row_count - LAG(row_count) OVER (ORDER BY step_no) AS change_vs_previous
FROM cleaning_log
ORDER BY step_no;

-- [v02_rejected_summary] What was removed and why (quarantine table)
SELECT reason, COUNT(*) AS rows
FROM rejected_rows
GROUP BY reason
ORDER BY rows DESC;

-- [v03_integrity_checks] Validation checks (violations must be 0)
SELECT check_name, violations
FROM (
    SELECT 'product_id is unique'                              AS check_name,
           COUNT(*) - COUNT(DISTINCT product_id)               AS violations FROM clean_products
    UNION ALL SELECT 'discounted_price <= actual_price',        COUNT(*) FROM clean_products WHERE discounted_price > actual_price
    UNION ALL SELECT 'prices are positive',                      COUNT(*) FROM clean_products WHERE discounted_price <= 0 OR actual_price <= 0
    UNION ALL SELECT 'rating between 0 and 5',                   COUNT(*) FROM clean_products WHERE rating NOT BETWEEN 0 AND 5
    UNION ALL SELECT 'discount_pct matches recomputed value (tolerance 0.6 pp)',
                    COUNT(*) FROM clean_products
                    WHERE ABS(discount_pct - ROUND(100 * (1 - discounted_price / actual_price), 2)) > 0.6
    UNION ALL SELECT 'category is never null',                   COUNT(*) FROM clean_products WHERE main_category IS NULL
    UNION ALL SELECT 'no mojibake left in product_name',         COUNT(*) FROM clean_products WHERE product_name ~ '[âÃÂ]'
    UNION ALL SELECT 'no leading/trailing/double spaces in product_name',
                    COUNT(*) FROM clean_products WHERE product_name <> TRIM(product_name) OR product_name ~ '\s\s'
    UNION ALL SELECT 'every product_id looks like an ASIN (B + 9 alphanumerics)',
                    COUNT(*) FROM clean_products WHERE product_id !~ '^B[0-9A-Z]{9}$'
    UNION ALL SELECT 'reviewers reference an existing product',
                    COUNT(*) FROM product_reviewers r LEFT JOIN clean_products c USING (product_id) WHERE c.product_id IS NULL
) v
ORDER BY violations DESC, check_name;

-- [v04_null_profile_after] Remaining nulls after cleaning (not imputed on purpose)
SELECT COUNT(*) FILTER (WHERE rating IS NULL)        AS rating_null,
       COUNT(*) FILTER (WHERE rating_count IS NULL)  AS rating_count_null,
       COUNT(*) FILTER (WHERE sub_category IS NULL)  AS sub_category_null,
       COUNT(*) FILTER (WHERE product_link IS NULL)  AS product_link_null,
       COUNT(*)                                      AS clean_rows
FROM clean_products;

-- [v05_category_before_after] Standardised main categories with counts (clean layer)
SELECT main_category, products, avg_discount_pct, avg_rating, total_ratings
FROM v_category_summary
ORDER BY products DESC;

-- [v06_sample_fixes] Examples: raw value -> cleaned value
SELECT r.raw_row_id,
       r.discounted_price                 AS raw_price,
       c.discounted_price                 AS clean_price,
       r.rating_count                     AS raw_rating_count,
       c.rating_count                     AS clean_rating_count,
       r.discount_percentage              AS raw_discount,
       c.discount_pct                     AS clean_discount_pct,
       r.category                         AS raw_category,
       c.main_category || ' > ' || COALESCE(c.sub_category, '-') AS clean_category
FROM raw_amazon r
JOIN clean_products c ON c.product_id = UPPER(TRIM(r.product_id))
WHERE r.rating_count LIKE '%,%,%'
ORDER BY r.raw_row_id
LIMIT 6;

-- [v07_mojibake_fixed] Product names repaired from encoding damage
SELECT LEFT(r.product_name, 60) AS raw_name_start,
       LEFT(c.product_name, 60) AS clean_name_start
FROM raw_amazon r
JOIN clean_products c ON c.product_id = UPPER(TRIM(r.product_id))
WHERE r.product_name ~ '[âÃÂ]'
ORDER BY r.raw_row_id
LIMIT 5;

-- [v08_reviewer_integrity] Reviewer normalisation: id-list lengths agree between user_id and review_id
SELECT COUNT(*)                                                                                   AS products_with_reviews,
       COUNT(*) FILTER (WHERE array_length(string_to_array(user_id, ','), 1)
                            = array_length(string_to_array(review_id, ','), 1))                   AS lists_same_length,
       (SELECT COUNT(*) FROM product_reviewers)                                                   AS review_rows,
       (SELECT COUNT(DISTINCT user_id) FROM product_reviewers)                                    AS distinct_reviewers
FROM raw_amazon
WHERE user_id IS NOT NULL AND review_id IS NOT NULL;
