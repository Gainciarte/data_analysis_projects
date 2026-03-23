# Excel 04 - Supplier Evaluation: Multi-Criteria Decision Model

## Objective

Build a weighted multi-criteria decision model (MCDM) to evaluate and rank 35 suppliers across 12 criteria. The goal is to identify preferred suppliers, classify the full vendor base, and provide a data-driven recommendation for top supplier selection.

---

## Dataset

| Field | Detail |
|---|---|
| Source | Kaggle - [Suppliers Ranking Grades](https://www.kaggle.com/datasets/michaelclodeemil/suppliers-ranking-grades) |
| Author | michaelclodeemil |
| Records | 35 suppliers |
| Criteria | 12 evaluation criteria |
| File | supplier_ranking_grades.xlsx - included in repository |

---

## Methodology

### Data Preparation
- Identified three distinct data scales requiring normalization:
  - Scale 1-5: quality, conditions of payment, flexibility, delivery time
  - Scale 1-9: serviceability, reputation, financial condition, assets, business results, price
  - Absolute values: quantity (units) and location (distance in km)
- Applied Min-Max normalization to all criteria to convert to uniform 0-1 scale
- Inverted normalization for price (lower price = higher score) and location (shorter distance = higher score)

### Normalization Formula
- Standard (higher is better): `(value - min) / (max - min)`
- Inverted (lower is better): `1 - (value - min) / (max - min)`

### Weighting Model

| Criteria | Weight | Justification |
|---|---|---|
| Quality | 15% | Product conformance |
| Price | 15% | Direct cost impact |
| Delivery Time | 12% | Operational continuity |
| Reputation and Competence | 10% | Long-term reliability |
| Conditions of Payment | 8% | Cash flow impact |
| Serviceability | 8% | Operational support |
| Flexibility | 8% | Supply chain resilience |
| Financial Condition | 8% | Supplier stability |
| Quantity | 5% | Supply capacity |
| Condition of Assets | 5% | Production capability |
| Business Results | 5% | Supplier health |
| Location and Traffic | 1% | Logistics cost |

### Scoring
- Weighted score calculated using SUMPRODUCT of normalized scores and weights
- Suppliers ranked 1-35 by weighted score
- Classification thresholds:
  - Preferred: Rank 1-7 (top 20%)
  - Approved: Rank 8-21 (next 40%)
  - Conditional: Rank 22-35 (bottom 40%)

---

## File Structure

```
04_supplier_evaluation/
├── 04_supplier_evaluation.xlsx    <- Main analysis file
└── README.md                      <- This file
```

**Sheets in the Excel file:**

| Sheet | Description |
|---|---|
| Raw Data - Suppliers | Original dataset as downloaded |
| Normalized Data | Min-Max normalized scores for all criteria |
| Weights | Criteria weights and justification |
| Scoring | Weighted scores, ranking and classification per supplier |
| Dashboard | Executive dashboard with market overview and Top recommendations |

---

## Key Findings

1. **Supplier 9 is the top ranked supplier** (score 0.704) with perfect scores in quality, serviceability and flexibility. Main weakness: business results and employees (0.20).
2. **Supplier 24 ranks second** (score 0.681) with perfect scores in reputation and delivery time. Main weakness: quantity capacity (0.31).
3. **Supplier 14 ranks third** (score 0.658) with perfect score in conditions of payment and strong serviceability. Main weakness: quantity capacity (0.44).
4. **Quantity is the weakest market criteria** (avg 0.31) - supply capacity limitations are widespread across the vendor base.
5. **Location and traffic is the strongest market criteria** (avg 0.76) - suppliers are generally well located.
6. **All other criteria are Moderate** - indicating a competitive but undifferentiated market where no single criteria clearly separates suppliers.

---

## Top 3 Recommendation

| Rank | Supplier | Score | Best Feature | Weakness | Recommendation |
|---|---|---|---|---|---|
| 1 | Supplier 9 | 0.704 | Quality | Business results | Primary supplier for quality-critical items |
| 2 | Supplier 24 | 0.681 | Reputation | Quantity capacity | Strategic supplier for long-term contracts |
| 3 | Supplier 14 | 0.658 | Payment conditions | Quantity capacity | Preferred for high-volume, cost-sensitive procurement |

---

## Limitations

- **Static evaluation** - scores reflect a single point in time and should be updated periodically.
- **Uniform weights** - weights are based on general supply chain best practices. In practice, weights should be adjusted per procurement category and business priority.
- **No performance history** - model does not incorporate historical delivery compliance or quality rejection rates.
- **Quantity data interpretation** - quantity column units are not documented in the original dataset and may represent order size rather than production capacity.

---

## Tools Used

- Microsoft Excel (Advanced)
- SUMPRODUCT, VLOOKUP, INDEX, MATCH
- MIN, MAX, AVERAGE, OFFSET
- Conditional Formatting
- RANK, COUNTIF
