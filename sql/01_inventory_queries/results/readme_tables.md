### q01_data_check - Data sanity check: row counts and coverage

| metric | value |
|---|---|
| sales order lines | 33919 |
| SKUs in inventory | 303 |
| SKUs with at least 1 sale | 290 |
| SKUs never sold | 13 |
| first order date | 2021-01-01 |
| last order date | 2023-07-30 |
| total inventory value | 54,130,478 |

### q02_stock_status - Stock status summary (coverage vs lead time)

| stock_status | skus | pct_skus | inventory_value | pct_value |
|---|---|---|---|---|
| Overstock (> 365 days) | 120 | 39.60 | 33,769,460 | 62.40 |
| Healthy | 103 | 34 | 15,126,966 | 27.90 |
| Critical (cover < avg lead time) | 49 | 16.20 | 3,307,523 | 6.10 |
| Low (cover < max lead time) | 17 | 5.60 | 1,897,654 | 3.50 |
| Out of stock | 10 | 3.30 | 0 | 0 |
| No demand (12m) | 4 | 1.30 | 28,875 | 0.10 |

### q03_reorder_risk - Top 15 critical SKUs: stock covers less than the average lead time

| sku_id | sku_name | vendor_name | warehouse_id | on_hand_qty | daily_demand | days_of_cover | avg_lead_days | days_short | annual_consumption_value |
|---|---|---|---|---|---|---|---|---|---|
| 1244AA | Product 016 | Apotex Corp | GUT930 | 2,834 | 551.40 | 5.10 | 45 | 39.90 | 8,429,912 |
| 1295CA | Product 022 | Mylan Group | AXW291 | 5 | 0.10 | 40.80 | 120 | 79.20 | 5,457,148 |
| 1281BA | Product 020 | Heritage | NXH382 | 3 | 0.10 | 22.70 | 60 | 37.30 | 4,693,731 |
| 2117BA | Product 132 | Cixi Group | AXW291 | 372 | 4.90 | 76.20 | 120 | 43.80 | 3,014,932 |
| 2473CA | Product 174 | Apotex Corp | AXW291 | 73,915 | 1,463 | 50.50 | 60 | 9.50 | 2,217,735 |
| 1967BA | Product 107 | McKesson Corp | NXH382 | 4,190 | 44.40 | 94.40 | 120 | 25.60 | 2,020,076 |
| 3007CA | Product 238 | Cixi Group | NXH382 | 5 | 0.30 | 14.70 | 30 | 15.30 | 1,631,669 |
| 2331CA | Product 158 | Macoven Group | FLR025 | 227 | 23.90 | 9.50 | 60 | 50.50 | 1,278,185 |
| 1876AA | Product 094 | ALK-Abello, Corp | NXH382 | 5 | 0.20 | 23.30 | 30 | 6.70 | 1,253,164 |
| 3178CA | Product 259 | Sun Ltd | NXH382 | 4 | 0.20 | 22.70 | 30 | 7.30 | 1,167,171 |
| 1224AA | Product 014 | Apotex Corp | GUT930 | 194 | 6.30 | 30.60 | 90 | 59.40 | 1,125,734 |
| 2528CA | Product 186 | ALK-Abello, Corp | GUT930 | 3,996 | 200 | 20 | 30 | 10 | 1,069,921 |
| 3016BA | Product 239 | Lake Ltd | GUT930 | 6 | 0.20 | 35 | 60 | 25 | 872,467 |
| 2317CA | Product 156 | Fullerton Corp | NXH382 | 3,420 | 81.10 | 42.20 | 60 | 17.80 | 770,132 |
| 1367CA | Product 033 | Lake Ltd | FLR025 | 5 | 0.10 | 41.80 | 90 | 48.20 | 670,091 |

### q05_abc_summary - ABC summary: share of SKUs vs share of consumption value

| abc_class | skus | pct_skus | pct_consumption | stock_value | pct_stock_value |
|---|---|---|---|---|---|
| A | 46 | 15.20 | 80 | 21,531,245 | 39.80 |
| B | 67 | 22.10 | 15 | 19,555,883 | 36.10 |
| C | 190 | 62.70 | 5 | 13,043,349 | 24.10 |

### q06_xyz_matrix - ABC-XYZ matrix (X: CV <= 0.5, Y: 0.5-1.0, Z: > 1.0 or no demand) - SKU counts

| abc_class | x_stable | y_variable | z_erratic | total |
|---|---|---|---|---|
| A | 0 | 23 | 23 | 46 |
| B | 0 | 15 | 52 | 67 |
| C | 1 | 65 | 124 | 190 |

### q07_dead_stock - Dead / slow stock: SKUs with stock and no sales in the last 12 months or last sale > 180 days ago

| sku_id | sku_name | vendor_name | warehouse_id | on_hand_qty | tied_up_value | last_sale_ever | days_since_last_sale |
|---|---|---|---|---|---|---|---|
| 2680BA | Product 205 | Allermed Group | GUT930 | 4,097 | 618,233 | 2022-12-05 | 237 |
| 2714CA | Product 206 | Lake Ltd | FLR025 | 9,014 | 314,218 | 2023-01-09 | 202 |
| 2646AA | Product 199 | Apotex Corp | FLR025 | 277 | 176,126 | 2022-12-29 | 213 |
| 1921AA | Product 100 | SUPERVALU Group | AXW291 | 4 | 140,000 | 2022-12-30 | 212 |
| 2223AA | Product 143 | Sun Ltd | FLR025 | 150 | 96,464 | 2022-12-29 | 213 |
| 2661CA | Product 200 | Sun Ltd | NXH382 | 711 | 90,581 | 2023-01-20 | 191 |
| 2524AA | Product 185 | Allermed Group | NXH382 | 3,996 | 39,161 | 2023-01-20 | 191 |
| 3003AA | Product 236 | Major Corp | FLR025 | 4 | 36,910 | 2022-12-11 | 231 |
| 2884AA | Product 220 | Lake Ltd | FLR025 | 690 | 14,490 | NULL | NULL |
| 2895CA | Product 221 | Apotex Corp | NXH382 | 470 | 9,870 | NULL | NULL |
| 3579CA | Product 299 | Allermed Group | GUT930 | 116 | 7,036 | 2022-12-31 | 211 |
| 2925CA | Product 223 | Macoven Group | GUT930 | 131 | 4,402 | 2022-09-25 | 308 |
| 2982AA | Product 232 | ALK-Abello, Corp | AXW291 | 200 | 4,200 | NULL | NULL |
| 2987AA | Product 233 | Apotex Corp | AXW291 | 15 | 315 | NULL | NULL |
| 1668CA | Product 068 | Lake Ltd | AXW291 | 400 | 238 | 2023-01-01 | 210 |

### q08_overstock - Overstock concentration: SKUs with more than 365 days of cover

| overstock_skus | overstock_value | pct_of_total_value | avg_days_of_cover |
|---|---|---|---|
| 120 | 33,769,460 | 62.40 | 3,658 |

### q09_warehouse_turnover - Inventory turnover and cover by warehouse (join with warehouse dimension)

| warehouse_id | city | province | skus | inventory_value | cogs_12m | turnover_x | days_inventory |
|---|---|---|---|---|---|---|---|
| GUT930 | Martensville | Saskatchewan | 101 | 16,858,274 | 27,952,663 | 1.66 | 220 |
| AXW291 | Stanstead | Quebec | 69 | 15,498,259 | 29,484,206 | 1.90 | 192 |
| FLR025 | Estevan | Saskatchewan | 52 | 11,000,338 | 12,625,632 | 1.15 | 318 |
| NXH382 | Saint-Pamphile | Quebec | 81 | 10,773,607 | 20,999,179 | 1.95 | 187 |

### q10_vendor_concentration - Inventory value by vendor with cumulative share (window functions)

| vendor_name | skus | inventory_value | pct_value | cum_pct_value |
|---|---|---|---|---|
| Lake Ltd | 44 | 6,757,440 | 12.50 | 12.50 |
| Cixi Group | 27 | 5,944,119 | 11 | 23.50 |
| Apotex Corp | 25 | 4,614,340 | 8.50 | 32 |
| ALK-Abello, Corp | 28 | 4,450,310 | 8.20 | 40.20 |
| Heritage | 24 | 4,173,787 | 7.70 | 47.90 |
| Sun Ltd | 16 | 4,114,967 | 7.60 | 55.50 |
| Allermed Group | 24 | 4,011,388 | 7.40 | 62.90 |
| Kinray Ltd | 14 | 3,784,055 | 7 | 69.90 |
| Major Corp | 11 | 3,777,364 | 7 | 76.90 |
| McKesson Corp | 18 | 2,966,321 | 5.50 | 82.40 |
| Mylan Group | 12 | 2,503,293 | 4.60 | 87 |
| Accord Ltd | 11 | 2,331,136 | 4.30 | 91.30 |
| Macoven Group | 22 | 2,276,799 | 4.20 | 95.50 |
| AstraZeneca | 2 | 901,954 | 1.70 | 97.20 |
| SUPERVALU Group | 10 | 887,786 | 1.60 | 98.80 |
| Fullerton Corp | 15 | 635,418 | 1.20 | 100 |

### q11_reorder_plan - Reorder recommendations: ROP = d x LT + 1.645 x sigma_d x sqrt(LT) (95% service level)

| abc_class | skus_with_demand | at_or_below_rop | pct_at_or_below_rop | units_short_vs_rop |
|---|---|---|---|---|
| A | 46 | 27 | 58.70 | 462,527 |
| B | 67 | 18 | 26.90 | 18,525 |
| C | 177 | 44 | 24.90 | 16,608 |

### q12_top_a_skus_rop - Class A SKUs already at or below the reorder point (most urgent first)

| sku_id | vendor_name | on_hand_qty | reorder_point | units_below_rop | avg_lead_days | annual_consumption_value |
|---|---|---|---|---|---|---|
| 1244AA | Apotex Corp | 2,834 | 48,520 | 45,686 | 45 | 8,429,912 |
| 1295CA | Mylan Group | 5 | 24 | 19 | 120 | 5,457,148 |
| 1281BA | Heritage | 3 | 16 | 13 | 60 | 4,693,731 |
| 3205AA | Apotex Corp | 14 | 21 | 7 | 60 | 3,491,010 |
| 1283CA | Fullerton Corp | 0 | 15 | 15 | 60 | 3,227,306 |
| 2117BA | Cixi Group | 372 | 939 | 567 | 120 | 3,014,932 |
| 2422BA | Kinray Ltd | 11,006 | 16,765 | 5,759 | 30 | 2,644,198 |
| 2418CA | Accord Ltd | 120,860 | 170,840 | 49,980 | 60 | 2,347,641 |
| 2473CA | Apotex Corp | 73,915 | 199,755 | 125,840 | 60 | 2,217,735 |
| 1967BA | McKesson Corp | 4,190 | 11,347 | 7,156 | 120 | 2,020,076 |

### q13_validate_value - Validation: stored total_value vs on_hand_qty x unit_cost

| skus | mismatches | stored_total | recomputed_total |
|---|---|---|---|
| 303 | 8 | 54,130,478 | 54,130,469 |
