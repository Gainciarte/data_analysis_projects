### q01_validation - Model validation: raw vs normalised vendor names, lead-time rules

| distinct_vendor_names_raw | vendors_after_trim | rows_with_untrimmed_vendor | skus_max_lt_below_avg | skus |
|---|---|---|---|---|
| 16 | 16 | 26 | 0 | 303 |

### q02_lead_time_buckets - SKU distribution by average lead-time bucket

| lead_time_bucket | skus | pct_skus | stock_value | avg_lt_variability |
|---|---|---|---|---|
| 1) <= 30 days | 126 | 41.60 | 9,357,892 | 0.47 |
| 2) 31-60 days | 118 | 38.90 | 28,508,744 | 0.46 |
| 3) 61-90 days | 27 | 8.90 | 8,882,187 | 0.43 |
| 4) > 90 days | 32 | 10.60 | 7,381,646 | 0.45 |

### q03_vendor_scorecard - Vendor scorecard: lead time, variability, margin, stock and revenue-at-risk exposure

| vendor_name | skus | avg_lead_days | avg_max_lead_days | lt_variability | avg_margin_pct | stock_value | skus_late_to_order | revenue_at_risk |
|---|---|---|---|---|---|---|---|---|
| Mylan Group | 12 | 58.80 | 84.70 | 0.44 | 30 | 2,503,290 | 2 | 1,697,800 |
| Apotex Corp | 25 | 56.80 | 80.80 | 0.43 | 30 | 4,614,340 | 6 | 1,666,516 |
| Fullerton Corp | 15 | 60 | 87.10 | 0.45 | 30 | 635,418 | 5 | 818,254 |
| Heritage | 24 | 60.60 | 86.30 | 0.43 | 30 | 4,173,786 | 5 | 714,426 |
| Cixi Group | 27 | 52 | 75.60 | 0.46 | 30 | 5,944,117 | 4 | 624,572 |
| Lake Ltd | 44 | 51.70 | 73.80 | 0.44 | 30 | 6,757,440 | 9 | 262,989 |
| Macoven Group | 22 | 51.40 | 75.10 | 0.48 | 30 | 2,276,799 | 3 | 255,341 |
| McKesson Corp | 18 | 50 | 74.30 | 0.48 | 30 | 2,966,322 | 3 | 225,280 |
| ALK-Abello, Corp | 28 | 53 | 79.30 | 0.48 | 30 | 4,450,312 | 6 | 158,753 |
| Kinray Ltd | 14 | 43.90 | 64 | 0.47 | 30 | 3,784,050 | 2 | 124,766 |
| Sun Ltd | 16 | 48.80 | 69.60 | 0.46 | 30 | 4,114,968 | 2 | 65,778 |
| Allermed Group | 24 | 60.60 | 87.70 | 0.44 | 30 | 4,011,390 | 2 | 3,311 |
| SUPERVALU Group | 10 | 53.50 | 80.70 | 0.51 | 30 | 887,786 | 1 | 981 |
| Major Corp | 11 | 38.60 | 56.70 | 0.47 | 30 | 3,777,364 | 0 | 0 |
| AstraZeneca | 2 | 30 | 43 | 0.49 | 30 | 901,954 | 0 | 0 |
| Accord Ltd | 11 | 45 | 66.70 | 0.47 | 30 | 2,331,136 | 0 | 0 |

### q04_vendor_ranking - Vendor performance index: rank on 3 metrics (lower is better) and average the ranks

| vendor_name | skus | avg_lead_days | lt_variability | pct_skus_late_to_order | rank_lead_time | rank_variability | rank_late_orders | avg_rank | performance_quartile |
|---|---|---|---|---|---|---|---|---|---|
| Major Corp | 11 | 38.60 | 0.47 | 0 | 2 | 9 | 1 | 4 | 1 |
| Accord Ltd | 11 | 45 | 0.47 | 0 | 4 | 11 | 1 | 5.30 | 1 |
| AstraZeneca | 2 | 30 | 0.49 | 0 | 1 | 15 | 1 | 5.70 | 1 |
| Sun Ltd | 16 | 48.80 | 0.46 | 12.50 | 5 | 7 | 6 | 6 | 1 |
| Kinray Ltd | 14 | 43.90 | 0.47 | 14.30 | 3 | 10 | 7 | 6.70 | 2 |
| Allermed Group | 24 | 60.60 | 0.44 | 8.70 | 15 | 5 | 4 | 8 | 2 |
| Lake Ltd | 44 | 51.70 | 0.44 | 21.40 | 8 | 4 | 12 | 8 | 2 |
| Cixi Group | 27 | 52 | 0.46 | 14.80 | 9 | 8 | 9 | 8.70 | 2 |
| Macoven Group | 22 | 51.40 | 0.48 | 14.30 | 7 | 12 | 7 | 8.70 | 3 |
| Mylan Group | 12 | 58.80 | 0.44 | 18.20 | 13 | 3 | 11 | 9 | 3 |
| Apotex Corp | 25 | 56.80 | 0.43 | 26.10 | 12 | 1 | 15 | 9.30 | 3 |
| McKesson Corp | 18 | 50 | 0.48 | 16.70 | 6 | 13 | 10 | 9.70 | 3 |
| Heritage | 24 | 60.60 | 0.43 | 22.70 | 15 | 2 | 13 | 10 | 4 |
| SUPERVALU Group | 10 | 53.50 | 0.51 | 10 | 11 | 16 | 5 | 10.70 | 4 |
| Fullerton Corp | 15 | 60 | 0.45 | 38.50 | 14 | 6 | 16 | 12 | 4 |
| ALK-Abello, Corp | 28 | 53 | 0.48 | 23.10 | 10 | 14 | 14 | 12.70 | 4 |

### q05_order_by_calendar - Replenishment calendar: when must POs be placed (days_to_order_by = cover - lead time)

| order_window | skus | pct_skus | annual_purchase_value |
|---|---|---|---|
| 1) Late (already inside lead time) | 50 | 17.20 | 41,354,562 |
| 2) Order within 30 days | 21 | 7.20 | 11,629,156 |
| 3) Order in 31-90 days | 22 | 7.60 | 4,579,796 |
| 4) Order in 91-365 days | 88 | 30.30 | 24,819,105 |
| 5) More than 1 year away | 109 | 37.60 | 8,679,061 |

### q06_late_skus_top - Top 12 late-to-order SKUs ranked by revenue at risk

| sku_id | vendor_name | warehouse_id | on_hand_qty | daily_demand | days_of_cover | avg_lead_days | days_late | revenue_at_risk |
|---|---|---|---|---|---|---|---|---|
| 1295CA | Mylan Group | AXW291 | 5 | 0.10 | 40.80 | 120 | 79.20 | 1,696,464 |
| 1244AA | Apotex Corp | GUT930 | 2,834 | 551.40 | 5.10 | 45 | 39.90 | 1,320,069 |
| 1283CA | Fullerton Corp | GUT930 | 0 | 0.10 | 0 | 60 | 60 | 759,920 |
| 1281BA | Heritage | NXH382 | 3 | 0.10 | 22.70 | 60 | 37.30 | 687,363 |
| 2117BA | Cixi Group | AXW291 | 372 | 4.90 | 76.20 | 120 | 43.80 | 518,264 |
| 1224AA | Apotex Corp | GUT930 | 194 | 6.30 | 30.60 | 90 | 59.40 | 262,437 |
| 2331CA | Macoven Group | FLR025 | 227 | 23.90 | 9.50 | 60 | 50.50 | 253,329 |
| 1967BA | McKesson Corp | NXH382 | 4,190 | 44.40 | 94.40 | 120 | 25.60 | 202,959 |
| 1367CA | Lake Ltd | FLR025 | 5 | 0.10 | 41.80 | 90 | 48.20 | 126,718 |
| 1161AA | Kinray Ltd | NXH382 | 197 | 12.30 | 16 | 90 | 74 | 124,266 |
| 3007CA | Cixi Group | NXH382 | 5 | 0.30 | 14.70 | 30 | 15.30 | 97,966 |
| 3016BA | Lake Ltd | GUT930 | 6 | 0.20 | 35 | 60 | 25 | 85,625 |

### q07_warehouse_comparison - Warehouse comparison: network profile + sales served (join inventory side and sales side)

| warehouse_id | city | province | skus | stock_value | avg_lead_days | lt_variability | skus_late | orders | revenue | stock_as_pct_of_revenue |
|---|---|---|---|---|---|---|---|---|---|---|
| AXW291 | Stanstead | Quebec | 69 | 15,498,258 | 52.20 | 0.46 | 8 | 15,938 | 237,912,192 | 6.50 |
| GUT930 | Martensville | Saskatchewan | 101 | 16,858,264 | 54.70 | 0.47 | 13 | 7,861 | 114,496,446 | 14.70 |
| NXH382 | Saint-Pamphile | Quebec | 81 | 10,773,609 | 51.90 | 0.44 | 19 | 6,657 | 104,433,140 | 10.30 |
| FLR025 | Estevan | Saskatchewan | 52 | 11,000,339 | 52.30 | 0.45 | 10 | 3,463 | 56,964,841 | 19.30 |

### q08_province_rollup - Province > warehouse roll-up of stock value (GROUPING SETS / ROLLUP)

| province | warehouse_id | skus | stock_value |
|---|---|---|---|
| ALL | ALL | 303 | 54,130,469 |
| Quebec | ALL | 150 | 26,271,867 |
| Quebec | AXW291 | 69 | 15,498,258 |
| Quebec | NXH382 | 81 | 10,773,609 |
| Saskatchewan | ALL | 153 | 27,858,603 |
| Saskatchewan | FLR025 | 52 | 11,000,339 |
| Saskatchewan | GUT930 | 101 | 16,858,264 |

### q09_vendor_dependency - Vendor dependency inside each warehouse: share of stock value (window) - top vendor per warehouse

| warehouse_id | rank_in_warehouse | vendor_name | skus | stock_value | pct_of_warehouse |
|---|---|---|---|---|---|
| AXW291 | 1 | Cixi Group | 13 | 3,928,764 | 25.30 |
| AXW291 | 2 | Mylan Group | 10 | 2,394,499 | 15.50 |
| AXW291 | 3 | ALK-Abello, Corp | 10 | 2,151,315 | 13.90 |
| FLR025 | 1 | Major Corp | 9 | 2,087,823 | 19 |
| FLR025 | 2 | Heritage | 5 | 2,023,728 | 18.40 |
| FLR025 | 3 | Sun Ltd | 5 | 1,910,346 | 17.40 |
| GUT930 | 1 | Lake Ltd | 15 | 4,120,824 | 24.40 |
| GUT930 | 2 | Allermed Group | 15 | 3,473,973 | 20.60 |
| GUT930 | 3 | Apotex Corp | 10 | 2,119,511 | 12.60 |
| NXH382 | 1 | Sun Ltd | 9 | 2,038,722 | 18.90 |
| NXH382 | 2 | ALK-Abello, Corp | 9 | 1,658,359 | 15.40 |
| NXH382 | 3 | Lake Ltd | 15 | 1,412,467 | 13.10 |

### q10_safety_stock_investment - Safety stock needed for a 95% service level, by vendor (versus current stock)

| vendor_name | safety_stock_value | lead_time_demand_value | current_stock_value | pct_of_total_safety_stock |
|---|---|---|---|---|
| Apotex Corp | 3,192,650 | 2,689,487 | 4,604,155 | 15.80 |
| Cixi Group | 2,559,815 | 2,113,535 | 5,944,117 | 12.70 |
| Lake Ltd | 2,210,530 | 1,068,941 | 6,742,950 | 11 |
| Mylan Group | 1,615,838 | 2,121,517 | 2,503,290 | 8 |
| Heritage | 1,544,948 | 1,318,229 | 4,173,786 | 7.70 |
| McKesson Corp | 1,334,854 | 1,060,075 | 2,966,322 | 6.60 |
| Kinray Ltd | 1,228,942 | 715,975 | 3,784,050 | 6.10 |
| Major Corp | 1,050,357 | 678,216 | 3,777,364 | 5.20 |
| Macoven Group | 1,005,709 | 778,244 | 2,276,799 | 5 |
| Accord Ltd | 857,834 | 847,310 | 2,331,136 | 4.30 |

### q11_longest_lead_vs_margin - Long-lead SKUs (> 90 days): are they compensated by margin? (compare with the rest)

| segment | skus | avg_margin_pct | median_margin_pct | avg_lt_variability | stock_value |
|---|---|---|---|---|---|
| Lead time <= 90 days | 271 | 30 | 30 | 0.46 | 46,748,823 |
| Lead time > 90 days | 32 | 30 | 30 | 0.45 | 7,381,646 |

### q12_headline - Network headline numbers

| skus | vendors | avg_lead_days | longest_max_lead_days | stock_value | skus_late_to_order | revenue_at_risk |
|---|---|---|---|---|---|---|
| 303 | 16 | 52.90 | 192 | 54,130,469 | 50 | 6,618,769 |
