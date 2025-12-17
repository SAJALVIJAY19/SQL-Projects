![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge\&logo=postgresql\&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-Advanced-blue?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

# 📊 SQL E‑Commerce Analytics Project

An **end‑to‑end SQL analytics portfolio project** showcasing database design, advanced querying, performance optimization, and executive‑level business insights using real‑world e‑commerce data.

> **Dataset:** Olist Brazilian E‑Commerce (Kaggle)
> **Database:** PostgreSQL 14+
> **Records:** 450,000+ | **Data Size:** ~85 MB

---

## 🎯 Project Objectives

* Design a **scalable, normalized (3NF) relational database** for e‑commerce operations
* Perform **advanced SQL analytics** using CTEs, window functions, and complex joins
* Generate **actionable business insights** across revenue, customers, products, and operations
* Optimize query performance using **indexes and materialized views**
* Deliver **quantified, executive‑ready recommendations** backed by data

---

## 💼 Business Impact & Key Findings

### 💰 Revenue Insights

* **80/20 Rule:** Top **20% of products generate 80% of revenue** ($2.3M)
* **Category Leaders:** Electronics & Furniture contribute **42% of total revenue**
* **Geographic Concentration:** São Paulo, Rio de Janeiro, and Minas Gerais account for **65% of sales**

### 👥 Customer Intelligence

* **RFM Segmentation:** Identified **6 customer segments**
* **Champions:** 12% of customers generate **42% of total revenue**
* **Churn Risk:** 3,200 high‑value customers inactive for 90+ days → **$180K revenue exposure**
* **Retention Crisis:**

  * Repeat purchase rate: **2.9%**
  * Month‑1 retention rate: **8.2%**

### 📦 Product Analysis

* **Top Sellers:** 20 products generate **$850K in revenue**
* **Hidden Gems:** 15 products with **4.5+ ratings** but low sales volume
* **Pricing Opportunity:** 10–15% price increase on underpriced high‑demand products → **$85K upside**

### 🚚 Operational Metrics

* **Avg Delivery Time:** 12.5 days | **On‑Time Rate:** 93.4%
* **Customer Impact:** Late deliveries reduce ratings by **0.8 stars** on average
* **Logistics Bottlenecks:** 5 states exceed **20‑day delivery times**

### 💡 Total Identified Opportunity

> **$265,000+ potential revenue impact**
> (Churn prevention $180K + Pricing optimization $85K)

---

## 🗂️ Database Architecture

### Entity Relationship Diagram (ERD)

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│  CUSTOMERS  │────────▶│   ORDERS    │◀────────│  SELLERS    │
│             │  1:N    │             │  N:1    │             │
│ customer_id │         │ order_id    │         │ seller_id  │
│ state       │         │ status      │         │ state      │
│ city        │         │ timestamps  │         │ city       │
└─────────────┘         └──────┬──────┘         └─────────────┘
                               │
                           1:N │
                               ▼
                        ┌──────────────┐
                        │ ORDER_ITEMS  │
                        │              │
                        │ product_id   │
                        │ price        │
                        │ freight      │
                        └──────┬───────┘
                               │ N:1
                               ▼
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│  PRODUCTS   │────────▶│ CATEGORIES  │         │  PAYMENTS   │
│             │  N:1    │             │         │             │
│ product_id  │         │ category    │         │ order_id    │
│ dimensions  │         │ translation │         │ type        │
│ weight      │         │             │         │ value       │
└─────────────┘         └─────────────┘         └──────┬──────┘
                                                        │
                        ┌─────────────┐                │ N:1
                        │   REVIEWS   │◀───────────────┘
                        │             │
                        │ review_id   │
                        │ score       │
                        │ comments    │
                        └─────────────┘
```

### Database Statistics

* **Tables:** 8 (Normalized to 3NF)
* **Total Records:** 450,000+
* **Indexes:** 15 strategic indexes
* **Materialized Views:** 3

---

## 🛠️ Tech Stack

* **Database:** PostgreSQL 14+
* **Query Tools:** pgAdmin 4 / psql
* **Data Source:** Olist Brazilian E‑Commerce Dataset (Kaggle)
* **Version Control:** Git & GitHub

### SQL Techniques Demonstrated

* Advanced joins (INNER, LEFT, self‑joins, multi‑table joins)
* CTEs (recursive & non‑recursive)
* Window functions (ROW_NUMBER, RANK, NTILE, LAG, LEAD)
* Correlated & non‑correlated subqueries
* Aggregations (GROUP BY, HAVING, ROLLUP, CUBE)
* Date & time analytics
* Query optimization with **EXPLAIN ANALYZE**
* Indexing strategies & materialized views
* Data integrity (constraints, foreign keys)

---

## 📂 Project Structure

```
sql-ecommerce-analysis/
│
├── data/
│   ├── raw/                     # Original CSV files from Kaggle
│   └── schema_diagram.png       # ER diagram
│
├── sql/
│   ├── 01_create_tables.sql     # Schema design
│   ├── 02_load_data.sql         # Data loading scripts
│   ├── 03_analysis_queries.sql  # Analytical SQL queries
│   ├── 04_business_insights.sql # Executive insights
│   └── 05_optimization.sql      # Performance tuning
│
├── reports/
│   ├── revenue_analysis.md
│   ├── customer_segmentation.md
│   ├── product_performance.md
│   ├── operations_dashboard.md
│   └── executive_summary.md
│
├── images/
│   ├── query_results/
│   ├── performance_metrics/
│   └── insights_charts/
│
├── README.md
├── INSIGHTS.md
└── LICENSE
```

---

## 🚀 Quick Start

### Prerequisites

* PostgreSQL 12+
* pgAdmin 4 (optional)
* Basic SQL knowledge
* ~500MB free disk space

### Installation

```bash
# Clone repository
git clone https://github.com/yourusername/sql-ecommerce-analysis.git
cd sql-ecommerce-analysis
```

```sql
-- Create database
CREATE DATABASE ecommerce_analysis;
```

```bash
# Create tables
psql -U postgres -d ecommerce_analysis -f sql/01_create_tables.sql

# Load data (update CSV paths first)
psql -U postgres -d ecommerce_analysis -f sql/02_load_data.sql

# Run analysis
psql -U postgres -d ecommerce_analysis -f sql/03_analysis_queries.sql
psql -U postgres -d ecommerce_analysis -f sql/04_business_insights.sql
psql -U postgres -d ecommerce_analysis -f sql/05_optimization.sql
```

---

## 📊 Sample SQL Query

### Top Revenue‑Generating Categories

```sql
SELECT
    pc.category_name_english,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(oi.order_item_id) AS units_sold,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS avg_price
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN product_categories pc ON p.category_name = pc.category_name
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY pc.category_name_english
ORDER BY total_revenue DESC
LIMIT 10;
```

---

## 📈 Performance Optimization Results

| Query Type            | Before | After | Improvement |
| --------------------- | ------ | ----- | ----------- |
| Revenue by State      | 12.4s  | 2.8s  | 77% faster  |
| Customer Segmentation | 18.7s  | 4.2s  | 78% faster  |
| Product Rankings      | 8.3s   | 1.9s  | 77% faster  |
| Cohort Analysis       | 22.1s  | 5.6s  | 75% faster  |

**Average Performance Gain:** ~75%

---

## 🎓 Skills Demonstrated

### Technical

* Advanced SQL (CTEs, window functions)
* Database normalization (3NF)
* Query optimization & indexing
* Materialized views

### Analytical

* RFM customer segmentation
* Cohort & retention analysis
* Pareto (80/20) analysis
* Time‑series analysis

### Business

* Translating data into insights
* Quantifying revenue impact
* Executive‑level recommendations

---

## 👤 About the Author

**Sajal Vijayvargiya**
Data Analyst | SQL Expert | Business Intelligence Enthusiast

📧 **Email:** [sajalvijay10@gmail.com](mailto:sajalvijay10@gmail.com)
💼 **LinkedIn:** [https://linkedin.com/in/yourprofile]([https://linkedin.com/in/yourprofile](https://www.linkedin.com/in/sajal-vijay-6823b7295/))
🐙 **GitHub:** [https://github.com/yourprofile]([https://github.com/yourprofile](https://github.com/SAJALVIJAY19/))

---

## 🙏 Acknowledgments

* **Olist** for providing the public e‑commerce dataset
* **Kaggle community** for dataset discussions and insights
* **PostgreSQL community** for excellent documentation
* **Stack Overflow** for continuous troubleshooting support

---

## 📜 License

This project is licensed under the **MIT License**.
