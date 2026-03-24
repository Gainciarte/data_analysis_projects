# Python 01 - Sales EDA: Amazon Sales Analysis

## Objective

Perform an Exploratory Data Analysis (EDA) on an Amazon India sales dataset to identify consumption patterns in technology categories, evaluate the effectiveness of discount strategies, and analyze customer satisfaction through ratings.

---

## Dataset

| Field | Detail |
|---|---|
| Source | Kaggle - [Amazon Sales Dataset](https://www.kaggle.com/datasets/karkavelrajaj/amazon-sales-dataset) |
| Author | karkavelrajaj |
| Records | ~1,400 products |
| Period | Historical sales data from Amazon India |
| Categories | Electronics, Computers, Home, and more |
| File | `amazon.xlsx` - processed from `raw_data` sheet |

**Key variables:** `product_name`, `main_category`, `discounted_price`, `actual_price`, `rating`, `discount_percentage`

---

## Methodology

### Data Cleaning
- **Price cleaning:** Used Regular Expressions (`re`) to remove special characters and currency symbols (`₹`), converting prices from string to float
- **Rating sanitization:** Handled non-numeric values, imputing the global mean (4.10) to missing records to preserve dataset integrity
- **Category simplification:** Extracted primary category using string split on `|` delimiter for high-level analysis

### Business Metrics Calculated
- **Discount Amount:** Absolute difference between original and discounted price
- **Real Discount %:** Recalculated from raw prices to validate accuracy of reported discounts
- **Star Products:** Products with rating >= 4.5 and discount >= 50% — high value recommendations

---

## File Structure

```
python/01_sales_eda/
├── 01_sales_eda.ipynb          <- Main Jupyter Notebook with complete analysis
├── amazon.xlsx                 <- Original dataset (raw_data sheet)
├── amazon_sales_cleaned.csv    <- Cleaned dataset exported after processing
└── README.md                   <- This file
```

---

## Key Findings

1. **Tech dominance:** Electronics and Computers & Accessories concentrate the highest product volume and sales activity.
2. **Aggressive discounting:** Average discount is 47.6%, reaching up to 94% in extreme cases — highly competitive, price-driven market.
3. **Quality vs. price:** Pearson correlation between discount % and rating is near 0, indicating higher discounts do not guarantee better customer satisfaction.
4. **Overall satisfaction:** Average rating of 4.10/5.0 reflects a healthy quality standard across the catalog.

---

## Limitations

- **Currency encoding:** Original data contains inconsistencies in Indian Rupee symbol encoding requiring regex-based cleaning.
- **No sales volume:** Dataset does not include units sold, limiting total revenue or profitability analysis.
- **Static ratings:** Analysis based on current ratings with no historical evolution over time.

---

## Tools Used

| Tool | Purpose |
|---|---|
| Python 3.x | Primary programming language |
| pandas | Data manipulation, cleaning and analysis |
| matplotlib | Base charting library |
| seaborn | Statistical visualization and styling |
| re | Regular expressions for currency string cleaning |
| Jupyter Notebook | Interactive environment for documented analysis |
