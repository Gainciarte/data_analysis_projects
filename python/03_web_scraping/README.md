# Python 03 - Web Scraping: Books to Scrape Data Extraction

## Objective

Extract, clean, and analyze book data from a public e-commerce website using web scraping techniques. Demonstrate end-to-end data extraction pipeline: HTTP requests, HTML parsing, data cleaning, exploratory analysis, and export to structured format.

---

## Dataset

| Field | Detail |
|---|---|
| Source | Books to Scrape - [http://books.toscrape.com/](http://books.toscrape.com/) |
| Type | Public sandbox website designed for web scraping practice |
| Records | 100 books scraped from 5 pages |
| Data Points | Title, Price, Rating, Availability, URL |
| File | Raw HTML scraped from website, no pre-downloaded dataset |

**Note:** This website is specifically designed for practicing web scraping and does not contain real e-commerce data.

---

## Methodology

### Website Exploration
- Identified target website structure and HTML elements
- Analyzed pagination pattern (page-1.html, page-2.html, etc.)
- Verified website allows scraping (no robots.txt restrictions for this practice site)

### HTTP Requests & HTML Parsing
- Used `requests` library to fetch HTML content from web pages
- Verified successful connections with HTTP status code checks (200 = OK)
- Parsed HTML using `BeautifulSoup` to navigate DOM structure
- Identified book containers: `<article class="product_pod">`

### Data Extraction
- Created reusable extraction function for consistent data parsing
- Extracted key fields from each book:
  - **Title:** From `<h3><a title="...">` attribute
  - **Price:** From `<p class="price_color">` text content
  - **Rating:** From `<p class="star-rating [One|Two|Three|Four|Five]">` class
  - **Availability:** From `<p class="instock availability">` text
  - **URL:** From `<a href="...">` attribute
- Applied extraction function to all books across multiple pages

### Multi-Page Scraping (Pagination)
- Implemented loop to scrape 5 pages (100 books total)
- Constructed dynamic URLs using string formatting: `page-{}.html`
- Added `time.sleep(0.5)` delays between requests (ethical scraping practice)
- Handled potential request failures with status code validation

### Data Cleaning & Transformation
- **Price cleaning:** Removed currency symbol encoding issues (`Â£` → `£`), converted to float
- **Rating conversion:** Mapped word ratings to numeric values (`'Three'` → `3`)
- **Availability cleaning:** Stripped whitespace and newline characters
- **URL completion:** Converted relative paths to absolute URLs
- Created new columns with clean, analysis-ready data types

### Exploratory Data Analysis
- Calculated descriptive statistics (mean, median, std, min, max)
- Analyzed rating distribution across 1-5 stars
- Identified top 10 most expensive and cheapest books
- Calculated price-rating correlation to test if higher ratings command higher prices

### Data Visualization
- **Price distribution:** Histogram showing price frequency across ranges
- **Rating distribution:** Bar chart showing book counts by star rating
- **Price vs Rating:** Scatter plot revealing relationship between variables
- **Average price by rating:** Bar chart comparing mean prices across rating levels

---

## File Structure

```
03_web_scraping/
├── 03_web_scraping.ipynb          ← Main Jupyter Notebook with complete scraping workflow
├── books_scraped_data.csv         ← Exported clean dataset (100 books)
├── requirements.txt               ← Python dependencies
└── README.md                      ← This file
```

---

## Key Findings

1. **Price distribution is relatively uniform:** Mean (£35.85) is close to median (£35.75), indicating balanced price distribution across the catalog.

2. **Ratings skew positive:** Average rating of 3.0 stars with relatively even distribution across all rating levels. Most common rating varies but no extreme bias toward 5-star reviews.

3. **Weak price-rating correlation:** Correlation coefficient near 0 indicates that book ratings do not significantly depend on price. Higher prices do not guarantee better ratings.

4. **High availability:** Majority of scraped books show "In stock" status, typical of a well-stocked fictional e-commerce site.

5. **Price range is wide:** Books range from under £10 to over £50, demonstrating diverse pricing tiers suitable for different customer segments.

---

## Limitations

- **Small sample size:** Only 100 books scraped from ~1000 available. Full dataset would provide more robust statistical insights.
- **Fictional data:** Website contains synthetic data, so patterns may not reflect real e-commerce behavior.
- **Static snapshot:** Scraping captures data at a single point in time. Real-world applications would require periodic re-scraping.
- **No category data extracted:** Did not scrape book categories/genres, which would enable segmentation analysis.
- **No detailed descriptions:** Only scraped summary-level data from listing pages, not individual product detail pages.

---

## Web Scraping Best Practices Demonstrated

✅ **Ethical scraping:** Added delays between requests to avoid overloading server  
✅ **Error handling:** Validated HTTP status codes before processing responses  
✅ **Data validation:** Checked data types and null values after extraction  
✅ **Reusable code:** Created functions for repetitive extraction tasks  
✅ **Legal compliance:** Used a website specifically designed for scraping practice  
✅ **Data preservation:** Maintained original columns alongside cleaned versions  

---

## Tools Used

| Tool | Purpose |
|---|---|
| Python 3.x | Primary programming language |
| requests | HTTP library for making web requests and fetching HTML |
| BeautifulSoup | HTML/XML parser for extracting data from web pages |
| pandas | Data manipulation, cleaning, and analysis |
| matplotlib | Base charting library for visualizations |
| seaborn | Statistical visualization styling |
| time | Adding delays between requests (polite scraping) |
| re | Regular expressions for text pattern matching |
| Jupyter Notebook | Interactive environment for documented analysis |

---

## Future Enhancements

- Scrape all ~1000 books from all 50 pages for comprehensive analysis
- Extract additional fields: book categories, descriptions, ISBN
- Scrape individual product detail pages for richer data
- Implement concurrent scraping with rate limiting for faster extraction
- Add sentiment analysis on book descriptions/reviews
- Create automated scraping pipeline with scheduled execution
- Store data in database (SQLite/PostgreSQL) instead of CSV
