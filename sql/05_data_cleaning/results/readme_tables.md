### p01_raw_shape - Raw shape and key problems

| raw_rows | distinct_product_ids | surplus_rows_by_product_id | rows_with_no_business_data |
|---|---|---|---|
| 1,464 | 1,351 | 113 | 1 |

### p02_null_profile - Null / blank profile of the business columns

| col | nulls | pct_null |
|---|---|---|
| product_link | 375 | 25.61 |
| user_id | 337 | 23.02 |
| rating_count | 3 | 0.20 |
| actual_price | 1 | 0.07 |
| category | 1 | 0.07 |
| discount_percentage | 1 | 0.07 |
| discounted_price | 1 | 0.07 |
| rating | 1 | 0.07 |
| product_name | 0 | 0 |

### p03_format_issues - Format problems found by pattern checks (rows affected)

| issue | rows_affected | example |
|---|---|---|
| extra unnamed spill-over columns with data | 4 | NULL |
| discount_percentage stored as a 0-1 fraction, not a percentage | 1,463 | 0 |
| reviewers packed in one cell (comma-separated user_id list) | 1,123 | NULL |
| rating is not a number (placeholder character) | 1 | | |
| category path is CamelCase / glued with "&" (needs standardising) | 1,463 | Car&Motorbike|CarAccessories|InteriorAccessories|AirPurifiers&Ionizers |
| rating_count with thousands separators (incl. Indian 4,26,973 style) | 46 | 1,03,052 |
| mojibake (UTF-8 decoded as Windows-1252) in product_name | 109 | 7SEVENÂ® Bluetooth Voice Command Remote  |
| price stored as text with currency symbol / thousands separator | 1,463 | â‚¹1,043 |

### p04_duplicates - Duplicate analysis: exact duplicate rows vs same product_id with different attributes

| product_ids_repeated | surplus_rows | ids_with_identical_rows | ids_with_conflicting_values | max_rows_per_id |
|---|---|---|---|---|
| 91 | 113 | 11 | 80 | 3 |

### p05_main_category_raw - Raw first-level categories (before standardising)

| raw_main_category | rows |
|---|---|
| Electronics | 524 |
| Computers&Accessories | 453 |
| Home&Kitchen | 448 |
| OfficeProducts | 31 |
| MusicalInstruments | 2 |
| HomeImprovement | 2 |
| Toys&Games | 1 |
| Car&Motorbike | 1 |
| Health&PersonalCare | 1 |
| NULL | 1 |

### v01_before_after - Row-count audit of every cleaning step

| step_no | step | row_count | change_vs_previous |
|---|---|---|---|
| 1 | 0. raw rows loaded | 1,464 | NULL |
| 2 | 1. after typing & standardising | 1,464 | 0 |
| 3 | 2. after removing empty rows | 1,463 | -1 |
| 4 | 3. after deduplicating = clean_products | 1,350 | -113 |
| 5 | 4. product_reviewers (1 row per review) | 8,119 | 6,769 |

### v02_rejected_summary - What was removed and why (quarantine table)

| reason | rows |
|---|---|
| duplicate product_id (less complete copy) | 113 |
| no price, category or rating (empty listing) | 1 |

### v03_integrity_checks - Validation checks (violations must be 0)

| check_name | violations |
|---|---|
| category is never null | 0 |
| discount_pct matches recomputed value (tolerance 0.6 pp) | 0 |
| discounted_price <= actual_price | 0 |
| every product_id looks like an ASIN (B + 9 alphanumerics) | 0 |
| no leading/trailing/double spaces in product_name | 0 |
| no mojibake left in product_name | 0 |
| prices are positive | 0 |
| product_id is unique | 0 |
| rating between 0 and 5 | 0 |
| reviewers reference an existing product | 0 |

### v04_null_profile_after - Remaining nulls after cleaning (not imputed on purpose)

| rating_null | rating_count_null | sub_category_null | product_link_null | clean_rows |
|---|---|---|---|---|
| 1 | 2 | 0 | 351 | 1,350 |

### v05_category_before_after - Standardised main categories with counts (clean layer)

| main_category | products | avg_discount_pct | avg_rating | total_ratings |
|---|---|---|---|---|
| Electronics | 489 | 49.90 | 4.08 | 14,202,208 |
| Home & Kitchen | 448 | 40.10 | 4.04 | 2,991,069 |
| Computers & Accessories | 375 | 53.20 | 4.15 | 6,335,182 |
| Office Products | 31 | 12.40 | 4.31 | 149,675 |
| Home Improvement | 2 | 57.50 | 4.25 | 8,566 |
| Musical Instruments | 2 | 46 | 3.90 | 88,882 |
| Car & Motorbike | 1 | 42 | 3.80 | 1,118 |
| Toys & Games | 1 | 0 | 4.30 | 15,867 |
| Health & Personal Care | 1 | 53 | 4 | 3,663 |

### v06_sample_fixes - Examples: raw value -> cleaned value

| raw_row_id | raw_price | clean_price | raw_rating_count | clean_rating_count | raw_discount | clean_discount_pct | raw_category | clean_category |
|---|---|---|---|---|---|---|---|---|
| 9 | â‚¹499 | 499 | 1,79,691 | 179,691 | 0.5 | 50 | Computers&Accessories|NetworkingDevices|NetworkAdapters|WirelessUSBAdapters | Computers & Accessories > Networking Devices |
| 13 | â‚¹219 | 219 | 4,26,973 | 426,973 | 0.69 | 69 | Electronics|HomeTheater,TV&Video|Accessories|Cables|HDMICables | Electronics > Home Theater, TV & Video |
| 41 | â‚¹209 | 209 | 1,07,687 | 107,687 | 0.7 | 70 | Computers&Accessories|Accessories&Peripherals|Cables&Accessories|Cables|USBCables | Computers & Accessories > Accessories & Peripherals |
| 48 | â‚¹309 | 309 | 4,26,973 | 426,973 | 0.35 | 35 | Electronics|HomeTheater,TV&Video|Accessories|Cables|HDMICables | Electronics > Home Theater, TV & Video |
| 57 | â‚¹649 | 649 | 1,79,691 | 179,691 | 0.54 | 54 | Computers&Accessories|NetworkingDevices|NetworkAdapters|WirelessUSBAdapters | Computers & Accessories > Networking Devices |
| 66 | â‚¹309 | 309 | 4,26,973 | 426,973 | 0.78 | 78 | Electronics|HomeTheater,TV&Video|Accessories|Cables|HDMICables | Electronics > Home Theater, TV & Video |

### v07_mojibake_fixed - Product names repaired from encoding damage

| raw_name_start | clean_name_start |
|---|---|
| Sounce 65W OnePlus Dash Warp Charge Cable, 6.5A Type-C to US | Sounce 65W OnePlus Dash Warp Charge Cable, 6.5A Type-C to US |
| Duracell Type C To Type C 5A (100W) Braided Sync & Fast Char | Duracell Type C To Type C 5A (100W) Braided Sync & Fast Char |
| 7SEVENÂ® Compatible for Samsung Smart 4K Ultra HD TV Monitor | 7SEVEN® Compatible for Samsung Smart 4K Ultra HD TV Monitor  |
| Lapster 65W compatible for OnePlus Dash Warp Charge Cable ,  | Lapster 65W compatible for OnePlus Dash Warp Charge Cable ,  |
| iFFALCON 80 cm (32 inches) HD Ready Smart LED TVÂ 32F53 (Bla | iFFALCON 80 cm (32 inches) HD Ready Smart LED TV 32F53 (Blac |

### v08_reviewer_integrity - Reviewer normalisation: id-list lengths agree between user_id and review_id

| products_with_reviews | lists_same_length | review_rows | distinct_reviewers |
|---|---|---|---|
| 1,127 | 1,127 | 8,119 | 6,976 |
