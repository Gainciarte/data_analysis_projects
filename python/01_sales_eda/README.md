# Python 01 - Sales EDA: Amazon Sales Analysis

## Objective
Perform an Exploratory Data Analysis (EDA) on an Amazon India sales dataset to identify consumption patterns in technology categories, evaluate the effectiveness of discount strategies, and analyze customer satisfaction through ratings.

---

## Dataset
| Field | Detail |
|---|---|
| Source | Kaggle - [Amazon Sales Dataset](https://www.kaggle.com/datasets/karkavelrajaj/amazon-sales-dataset) |
| Records | ~1,400 products |
| Period | Historical sales data from Amazon India |
| Categories | Electronics, Computers, Home, and more |
| File | `amazon.xlsx` (processed in `raw_data` sheet) |

**Key Variables:** `product_name`, `main_category`, `discounted_price`, `actual_price`, `rating`, `discount_percentage`.

---

## Methodology

### Data Cleaning & Preparation
- **Format Conversion:** Implemented robust cleaning using Regular Expressions (`re`) to remove special characters and currency symbols (`₹`, `â‚¹`), converting prices from string to `float`.
- **Rating Sanitization:** Handled non-numeric values in the rating column, imputing the general mean (**4.10**) to missing records to maintain dataset integrity.
- **Categorization:** Simplified category hierarchy using string processing (`split`) to extract the primary category for high-level analysis.

### Business Metrics (KPIs)
- **Discount Amount:** Absolute difference between original and discounted price.
- **Real Discount %:** Recalculated discount percentage to validate offer accuracy.
- **Top Value Analysis:** Identification of "Star Products" with high ratings (>= 4.5) and aggressive discounts (>= 50%).

# Python 01 - Sales EDA: Amazon Sales Analysis

## Objective
Perform an Exploratory Data Analysis (EDA) on an Amazon India sales dataset to identify consumption patterns in technology categories, evaluate the effectiveness of discount strategies, and analyze customer satisfaction through ratings.

---

## Project Structure

```text
python/
└── 01_sales_eda/
    ├── 01_sales_eda.ipynb       # Main Jupyter Notebook with complete analysis
    ├── amazon.xlsx              # Original dataset (processed in 'raw_data' sheet)
    ├── amazon_sales_cleaned.csv # Cleaned dataset exported after processing
    └── README.md                # Project documentation
```
---

## Key Insights

1. **Tech Dominance:** The **Electronics** and **Computers & Accessories** categories concentrate the highest volume of products and sales activity.
2. **Aggressive Discounting:** The average discount is **47.6%**, reaching up to **94%** in extreme cases, suggesting a highly competitive price-based market.
3. **Quality vs. Price:** The correlation coefficient between discount percentage and rating is near **0**, indicating that higher discounts do not guarantee better customer satisfaction; ratings are tied to product quality.
4. **Overall Satisfaction:** The site's average rating is **4.10/5.0**, demonstrating a healthy quality standard across the analyzed catalog.

---

## Limitations
- **Currency Bias:** Original data contains encoding inconsistencies in Indian currency symbols.
- **Sales Volume Missing:** The dataset does not include units sold, limiting total profitability analysis.
- **Static Ratings:** Analysis is based on current ratings without historical evolution over time.

---

## Tools Used
| Tool | Purpose |
|---|---|
| **Python 3.x** | Primary programming language for data processing. |
| **Pandas** | Data manipulation, cleaning, and professional formatting. |
| **Matplotlib** | Base library for static data visualization. |
| **Seaborn** | Advanced statistical charts and aesthetic styling. |
| **Regular Expressions (re)** | Complex string cleaning and pattern matching for currency symbols. |
| **Jupyter Notebook** | Interactive environment for documented code execution. |