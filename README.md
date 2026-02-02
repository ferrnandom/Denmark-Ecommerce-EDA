# Denmark E-commerce Sales & Customer Analysis

## Executive Summary

This analysis examines the sales performance, customer segmentation, and geographic distribution of a high-end electronics e-commerce platform in Denmark. 

**Key Findings:**
- **Extreme Revenue Concentration:** Just three products—**MacBook Pro M3 Max**, **Sony Alpha a7 IV**, and **Samsung 75\" QLED TV**—drive over **70% of total revenue**.
- **The February Peak:** February is the dominant sales month, accounting for **34% of total annual orders**, suggesting a highly effective recurring seasonal promotion.
- **High-Value Customer Base:** While the customer base is small (200 unique users), the loyalty is exceptional, with an average of **20 orders per customer**.
- **VIP Dominance:** A core group of **40 VIP customers** accounts for a disproportionate share of wealth, with an average Lifetime Value (LTV) of over **478,000 DKK**.
- **Geographic Centralization:** **Region Hovedstaden** is the primary market, commanding a **72.3% market share**.

---
<img width="1024" height="1024" alt="Image" src="https://github.com/user-attachments/assets/5064470c-fd5b-4493-9aac-b512b9c0b483" />
---
## Business Problem

The platform faces challenges related to inventory dependency and customer churn:
1.  **Inventory Dependency:** 56.6% of revenue is tied to the **Computing** category.
2.  **Customer Retention Gap:** 109 customers (over 50%) are currently \"At Risk.\"
3.  **Low Accessory Attachment:** High unit volume in accessories translates to only **1.1% of revenue**.

---

## Data Cleaning & Preparation

The initial dataset was **synthetic and "dirty"**, containing inconsistent casing, missing values, duplicate entries, and calculation errors. A multi-stage SQL pipeline was used to create the `ecommerce_cleaned` view:

- **Stage 1 (Text Standardization):** Applied `TRIM` to all string fields and `INITCAP` to city names to fix casing inconsistencies (e.g., \"KØBENHAVN\" vs \"København\").
- **Stage 2 (Logical Imputation):** Handled missing `store_id` values by imputing the mode and recalculated `total_amount` (`unit_price * quantity`) to ensure financial accuracy.
- **Stage 3 (Temporal Validation):** Filtered out future-dated placeholder records (e.g., year 2099) and ensured all orders fell within the valid range (2023 to present).
- **Stage 4 (Customer Identity):** Used `COALESCE` and window functions (`FIRST_VALUE`) to fill missing customer names based on their unique `customer_id`.
- **Stage 5 & 6 (Deduplication):** Utilized `ROW_NUMBER()` over order and product keys to identify and remove duplicate transaction records.
- **Stage 7 (Quality Scoring):** Implemented a **Data Quality Score** (0.0 to 1.0) for every row based on four criteria: valid date, known customer name, valid city, and accurate total calculation.

---

## Key Metrics & Insights

### 1. Product Performance
- **MacBook Pro M3 Max**: **#1 Revenue Driver** ($13.7M).
- **Sony Alpha a7 IV Camera**: **#2 Revenue Driver** ($9.6M).
- **Volume vs. Value:** The **HDMI 2.1 Cable** is the most sold unit (593), yet revenue impact is low without bundling.

### 2. Customer Segmentation (RFM)
| Segment | Count | Avg. Lifetime Value | Strategic Priority |
| :--- | :--- | :--- | :--- |
| **VIP** | 40 | 478,557 | Retention & Early Access |
| **Loyal/Active** | 51 | ~156,000 | Upsell to Pro Kits |
| **At Risk** | 109 | 142,477 | Win-back Campaigns |

---

## Strategic Recommendations

1.  **Launch "Pro Bundles"** – Bundle mice and cables with every MacBook sale to increase accessory margins.
2.  **VIP Loyalty Program** – Give our top 40 customers special trade-in credits whenever a new flagship product is released. This makes it easier for them to upgrade and keeps our most important shoppers happy.
3.  **Hovedstaden Optimization** – Leverage the 72% geographic concentration to offer localized same-day delivery in the capital region.

---

## Data Limitations

- **Synthetic Origins:** The dataset was generated through **Generative AI** and is not reflective of real-world consumer behavior or actual Danish market trends.
- **Small Sample Size:** With only 200 unique customers, the statistical significance of segment-level insights is limited.

---

## Conclusion
Despite its synthetic nature, the analysis highlights a clear business model: a **high-ticket electronics specialist** centered in **Copenhagen**. Future growth lies in re-engaging the dormant \"At Risk\" segment and increasing margin through accessory bundling.
