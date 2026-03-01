---
description: Analytics and BI patterns enforced in all analytics sessions. Covers metric computation, time intelligence, naming conventions, materialization strategy, and query optimization for BI workloads.
globs: "*.sql,*.py,*.yaml"
---

# Analytics Patterns

## Metric Computation Patterns

### Additive Metrics

Metrics that can be summed across all dimensions. These are the simplest and most BI-friendly.

```sql
-- Revenue: fully additive
-- Can SUM across date, customer, product, region
SELECT
    d.fiscal_month,
    c.customer_segment,
    p.product_category,
    SUM(f.line_total) AS total_revenue,
    SUM(f.quantity) AS total_units,
FROM fct_orders AS f
INNER JOIN dim_date AS d
    ON f.order_date_key = d.date_key
INNER JOIN dim_customers AS c
    ON f.customer_key = c.customer_key
INNER JOIN dim_products AS p
    ON f.product_key = p.product_key
GROUP BY
    d.fiscal_month,
    c.customer_segment,
    p.product_category
```

### Semi-Additive Metrics

Metrics that can be summed across some dimensions but not across time. Common for balance and inventory metrics.

```sql
-- Inventory balance: semi-additive
-- Can SUM across products and locations, but NOT across time
-- For time: use the latest snapshot

-- CORRECT: latest snapshot per period
WITH latest_snapshot AS (
    SELECT
        f.product_key,
        f.location_key,
        f.quantity_on_hand,
        f.snapshot_date,
        ROW_NUMBER() OVER (
            PARTITION BY f.product_key, f.location_key
            ORDER BY f.snapshot_date DESC
        ) AS rn,
    FROM fct_daily_inventory AS f
    WHERE f.snapshot_date <= CURRENT_DATE()
)

SELECT
    p.product_category,
    SUM(ls.quantity_on_hand) AS current_inventory,
FROM latest_snapshot AS ls
INNER JOIN dim_products AS p
    ON ls.product_key = p.product_key
WHERE ls.rn = 1
GROUP BY p.product_category

-- WRONG: summing balance across time
SELECT
    DATE_TRUNC(snapshot_date, MONTH) AS month,
    SUM(quantity_on_hand) AS inventory -- meaningless: double-counts across days
FROM fct_daily_inventory
GROUP BY 1
```

### Non-Additive Metrics

Metrics that cannot be summed at any level. Must be recomputed from atomic data at each aggregation.

```sql
-- Distinct customer count: non-additive
-- Cannot SUM pre-aggregated counts — must COUNT DISTINCT from atomic data

-- CORRECT: compute at the desired grain
SELECT
    d.fiscal_quarter,
    COUNT(DISTINCT f.customer_key) AS unique_customers,
FROM fct_orders AS f
INNER JOIN dim_date AS d
    ON f.order_date_key = d.date_key
GROUP BY d.fiscal_quarter

-- WRONG: summing pre-aggregated distinct counts
-- Monthly uniques do not sum to quarterly uniques (customers overlap months)
SELECT
    fiscal_quarter,
    SUM(monthly_unique_customers) AS quarterly_unique_customers  -- INCORRECT
FROM agg_monthly_customer_counts
GROUP BY fiscal_quarter
```

### Ratio and Rate Metrics

Always compute numerator and denominator separately, then divide:

```sql
-- Conversion rate: non-additive ratio
-- Must compute from atomic data at each grain level

WITH funnel AS (
    SELECT
        d.fiscal_week,
        c.customer_segment,
        COUNT(DISTINCT CASE WHEN f.event_type = 'visit' THEN f.session_id END) AS visits,
        COUNT(DISTINCT CASE WHEN f.event_type = 'purchase' THEN f.session_id END) AS purchases,
    FROM fct_events AS f
    INNER JOIN dim_date AS d
        ON f.event_date_key = d.date_key
    INNER JOIN dim_customers AS c
        ON f.customer_key = c.customer_key
    GROUP BY
        d.fiscal_week,
        c.customer_segment
)

SELECT
    fiscal_week,
    customer_segment,
    visits,
    purchases,
    SAFE_DIVIDE(purchases, visits) AS conversion_rate,
FROM funnel
```

Never pre-aggregate a ratio and then try to aggregate it further — always recompute from the components.

---

## Time Intelligence Patterns

### Year-to-Date (YTD)

```sql
-- YTD Revenue: running total from start of fiscal year
SELECT
    d.calendar_date,
    SUM(f.line_total) AS daily_revenue,
    SUM(SUM(f.line_total)) OVER (
        PARTITION BY d.fiscal_year
        ORDER BY d.calendar_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS ytd_revenue,
FROM fct_orders AS f
INNER JOIN dim_date AS d
    ON f.order_date_key = d.date_key
WHERE d.fiscal_year = 2025
GROUP BY
    d.calendar_date,
    d.fiscal_year
ORDER BY d.calendar_date
```

### Month-to-Date (MTD)

```sql
-- MTD Revenue: running total from start of calendar month
SELECT
    d.calendar_date,
    SUM(f.line_total) AS daily_revenue,
    SUM(SUM(f.line_total)) OVER (
        PARTITION BY d.calendar_year, d.calendar_month
        ORDER BY d.calendar_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS mtd_revenue,
FROM fct_orders AS f
INNER JOIN dim_date AS d
    ON f.order_date_key = d.date_key
GROUP BY
    d.calendar_date,
    d.calendar_year,
    d.calendar_month
ORDER BY d.calendar_date
```

### Rolling Averages

```sql
-- 7-day rolling average of daily revenue
WITH daily_revenue AS (
    SELECT
        d.calendar_date,
        COALESCE(SUM(f.line_total), 0) AS revenue,
    FROM dim_date AS d
    LEFT JOIN fct_orders AS f
        ON d.date_key = f.order_date_key
    WHERE d.calendar_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) AND CURRENT_DATE()
    GROUP BY d.calendar_date
)

SELECT
    dr.calendar_date,
    dr.revenue AS daily_revenue,
    AVG(dr.revenue) OVER (
        ORDER BY dr.calendar_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_7day_avg,
    AVG(dr.revenue) OVER (
        ORDER BY dr.calendar_date
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS rolling_30day_avg,
FROM daily_revenue AS dr
ORDER BY dr.calendar_date
```

Important: LEFT JOIN from `dim_date` to ensure days with zero activity are included (not gaps in the rolling window).

### Period-over-Period Comparison

```sql
-- Month-over-month comparison
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC(d.calendar_date, MONTH) AS revenue_month,
        SUM(f.line_total) AS monthly_revenue,
    FROM fct_orders AS f
    INNER JOIN dim_date AS d
        ON f.order_date_key = d.date_key
    GROUP BY DATE_TRUNC(d.calendar_date, MONTH)
)

SELECT
    mr.revenue_month,
    mr.monthly_revenue,
    LAG(mr.monthly_revenue, 1) OVER (ORDER BY mr.revenue_month) AS prev_month_revenue,
    mr.monthly_revenue - LAG(mr.monthly_revenue, 1) OVER (ORDER BY mr.revenue_month) AS mom_change,
    SAFE_DIVIDE(
        mr.monthly_revenue - LAG(mr.monthly_revenue, 1) OVER (ORDER BY mr.revenue_month),
        LAG(mr.monthly_revenue, 1) OVER (ORDER BY mr.revenue_month)
    ) AS mom_change_pct,
    LAG(mr.monthly_revenue, 12) OVER (ORDER BY mr.revenue_month) AS same_month_prior_year,
    SAFE_DIVIDE(
        mr.monthly_revenue - LAG(mr.monthly_revenue, 12) OVER (ORDER BY mr.revenue_month),
        LAG(mr.monthly_revenue, 12) OVER (ORDER BY mr.revenue_month)
    ) AS yoy_change_pct,
FROM monthly_revenue AS mr
ORDER BY mr.revenue_month
```

### Fiscal vs. Calendar Time

- Always use the `dim_date` table for time intelligence — never compute fiscal periods inline
- `dim_date` must contain both calendar and fiscal columns: `calendar_year`, `calendar_quarter`, `fiscal_year`, `fiscal_quarter`, `fiscal_month`
- Default to fiscal periods for financial reporting, calendar periods for operational reporting
- Document which time frame is used in every metric definition

---

## Slowly Changing Dimension Handling in Analytics

### Current View (SCD Type 1 Equivalent)

For dashboards that need current-state reporting:

```sql
-- Current customer dimension: one row per customer
CREATE VIEW dim_customers_current AS
SELECT *
FROM dim_customers
WHERE is_current = TRUE
```

### Historical View (SCD Type 2)

For point-in-time analysis:

```sql
-- Point-in-time customer attributes at time of order
SELECT
    f.order_id,
    f.order_date,
    c.customer_name,
    c.customer_segment,     -- segment at time of order
    c.geo_region,           -- region at time of order
FROM fct_orders AS f
INNER JOIN dim_customers AS c
    ON f.customer_key = c.customer_key
    AND f.order_date >= c.effective_from
    AND f.order_date < c.effective_to
```

### Analytics Best Practice

- Default to **current view** for operational dashboards (simpler queries, faster performance)
- Use **historical view** for trend analysis where attribute changes affect interpretation (e.g., segment migration analysis, revenue by historical region)
- Document which view is used in every dashboard and metric definition
- Pre-build point-in-time tables for frequently used historical joins (avoid runtime SCD lookups on large fact tables)

---

## Materialized View Strategy

### When to Materialize

| Signal | Action |
|--------|--------|
| Query runs > 30 seconds and is used daily | Materialize |
| Same aggregation pattern appears in 3+ dashboards | Materialize as shared aggregate |
| BI tool times out on complex joins | Create pre-joined materialized view |
| Real-time not needed, but query cost is high | Materialize with scheduled refresh |

### When NOT to Materialize

- Query is fast enough without materialization (< 5 seconds)
- Data changes too frequently for batch materialization and users need real-time accuracy
- Only one dashboard uses the pattern (optimize the query instead)
- The BI tool handles caching effectively

### Materialized View Naming

```
agg_{grain}_{measure_group}_by_{primary_dimension}

Examples:
  agg_daily_revenue_by_region
  agg_monthly_orders_by_product_category
  agg_weekly_user_counts_by_segment
```

### Refresh Strategy

- Align refresh schedule with the underlying data pipeline (materialize after the pipeline completes)
- Use incremental refresh where the platform supports it (append new partitions, do not recompute the entire view)
- Monitor materialized view freshness — stale aggregates cause confusion
- Include a `_materialized_at` timestamp column in every materialized view

---

## Query Optimization for BI Workloads

### Partition Pruning

Structure BI queries to leverage table partitioning:

```sql
-- CORRECT: partition pruning on date column
SELECT ...
FROM fct_orders AS f
WHERE f.order_date >= '2025-01-01'
  AND f.order_date < '2025-02-01'

-- WRONG: function on partition column prevents pruning
SELECT ...
FROM fct_orders AS f
WHERE DATE_TRUNC(f.order_date, MONTH) = '2025-01-01'

-- WRONG: casting prevents pruning
SELECT ...
FROM fct_orders AS f
WHERE CAST(f.order_date AS STRING) LIKE '2025-01%'
```

### Pre-Aggregation

For dashboards with predictable query patterns, pre-aggregate rather than scanning fact tables:

```sql
-- Pre-aggregated daily summary for dashboard consumption
CREATE TABLE agg_daily_orders_summary AS
SELECT
    f.order_date_key,
    d.calendar_date,
    d.fiscal_month,
    d.fiscal_quarter,
    d.fiscal_year,
    c.customer_segment,
    p.product_category,
    COUNT(*) AS order_count,
    COUNT(DISTINCT f.customer_key) AS unique_customers,
    SUM(f.line_total) AS total_revenue,
    SUM(f.quantity) AS total_units,
    SUM(f.discount_amount) AS total_discounts,
    CURRENT_TIMESTAMP() AS _materialized_at,
FROM fct_orders AS f
INNER JOIN dim_date AS d ON f.order_date_key = d.date_key
INNER JOIN dim_customers AS c ON f.customer_key = c.customer_key
INNER JOIN dim_products AS p ON f.product_key = p.product_key
GROUP BY
    f.order_date_key,
    d.calendar_date,
    d.fiscal_month,
    d.fiscal_quarter,
    d.fiscal_year,
    c.customer_segment,
    p.product_category
```

### Approximate Aggregations

Use approximate functions for large-scale analytics where exact precision is not required:

```sql
-- Approximate distinct count (much faster on large tables)
SELECT
    d.fiscal_month,
    APPROX_COUNT_DISTINCT(f.customer_key) AS approx_unique_customers,
FROM fct_orders AS f
INNER JOIN dim_date AS d ON f.order_date_key = d.date_key
GROUP BY d.fiscal_month

-- Approximate percentiles
SELECT
    p.product_category,
    APPROX_QUANTILES(f.line_total, 100)[OFFSET(50)] AS median_order_value,
    APPROX_QUANTILES(f.line_total, 100)[OFFSET(90)] AS p90_order_value,
FROM fct_orders AS f
INNER JOIN dim_products AS p ON f.product_key = p.product_key
GROUP BY p.product_category
```

Use exact functions when: financial reporting, compliance reporting, metric definitions that specify exact precision.

---

## Naming Conventions for Analytics Objects

### Table Prefixes

| Prefix | Layer | Purpose | Example |
|--------|-------|---------|---------|
| `stg_` | Staging | Raw data, minimal transformation | `stg_salesforce_opportunities` |
| `int_` | Intermediate | Business logic, joins, deduplication | `int_orders_enriched` |
| `fct_` | Marts (Fact) | Fact tables at atomic grain | `fct_orders` |
| `dim_` | Marts (Dimension) | Dimension tables with attributes | `dim_customers` |
| `agg_` | Aggregates | Pre-computed summaries for BI | `agg_daily_revenue_by_region` |
| `rpt_` | Reports | Report-specific views or tables | `rpt_executive_kpi_summary` |
| `ref_` | Reference | Static reference/seed data | `ref_country_codes` |
| `snp_` | Snapshots | Point-in-time snapshots | `snp_daily_inventory` |
| `tmp_` | Temporary | Ephemeral tables (auto-cleanup) | `tmp_backfill_staging` |

### Column Naming

| Type | Convention | Example |
|------|-----------|---------|
| Surrogate key | `{entity}_key` | `customer_key` |
| Natural key | `{entity}_id` | `customer_id` |
| Foreign key | `{related_entity}_key` | `customer_key` (in fct_orders) |
| Date | `{event}_date` | `order_date`, `ship_date` |
| Timestamp | `{event}_at` | `created_at`, `updated_at` |
| Boolean | `is_{condition}` / `has_{condition}` | `is_active`, `has_returns` |
| Count | `{noun}_count` | `order_count`, `item_count` |
| Amount | `{noun}_amount` | `discount_amount`, `tax_amount` |
| Total | `total_{noun}` | `total_revenue`, `total_units` |
| Rate/Ratio | `{noun}_rate` / `{noun}_pct` | `conversion_rate`, `churn_pct` |
| Average | `avg_{noun}` | `avg_order_value` |

### Dashboard Naming

```
[Domain] - [Audience] - [Purpose]

Examples:
  Revenue - Executive - Monthly KPI Summary
  Marketing - Ops - Campaign Performance
  Support - Team Lead - Ticket Resolution Dashboard
  Product - Analyst - Feature Adoption Deep Dive
```

### Metric Naming

```
[Domain]: [Metric Name] ([Time Period if inherent])

Examples:
  Revenue: Monthly Recurring Revenue (MRR)
  Revenue: Annual Recurring Revenue (ARR)
  Support: Average Resolution Time
  Product: 7-Day Retention Rate
  Marketing: Customer Acquisition Cost (CAC)
```

---

## Anti-Patterns to Avoid

- **Metric-per-dashboard**: redefining the same metric differently in each dashboard. Use the semantic layer.
- **Magic numbers in SQL**: unexplained constants (`WHERE status_code = 3`). Use a reference table or named CTE.
- **Over-aggregation**: computing metrics at a coarser grain than needed. Always start atomic and aggregate up.
- **Implicit time zones**: computing date-based metrics without specifying timezone. Always explicit.
- **Dashboard data island**: a dashboard that connects directly to a source system, bypassing the warehouse. All dashboards consume from the marts layer.
- **Unversioned metric changes**: changing a metric definition without versioning or notifying consumers.
- **Premature denormalization**: flattening everything into one wide table. Use dimensional joins unless there is a documented performance reason.
