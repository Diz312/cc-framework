# Analytics / BI Standards

This file **supplements** the core `CLAUDE.md` — it does not replace it. All core principles (simplicity, platform-native first, 12-Factor, security) still apply. This overlay adds analytics-specific standards for metric definitions, semantic layers, dashboard design, data visualization, and analytics governance.

---

## Metric Definition Standards

Every business metric must have a formal, unambiguous definition before it appears in any dashboard, report, or analytics output.

### Required Fields

Every metric definition must include:

| Field | Description | Example |
|-------|-------------|---------|
| **Metric Name** | Business-friendly name, unique across the organization | Monthly Recurring Revenue (MRR) |
| **Business Definition** | Plain-English explanation any stakeholder can understand | Total contracted monthly revenue from active subscriptions, excluding one-time fees and usage-based charges |
| **Technical Definition** | SQL or pseudocode that computes the metric unambiguously | `SUM(subscription_amount) WHERE status = 'active' AND fee_type = 'recurring'` |
| **Grain** | What level the metric is computed at | Per customer, per month |
| **Dimensions** | Which dimensions the metric can be sliced by | date, customer_segment, product_tier, geo_region |
| **Filters** | Default filters applied (and which are removable) | Excludes internal test accounts; date filter is user-adjustable |
| **Aggregation** | How the metric rolls up across dimensions | Additive across customers and products; not additive across time (use latest for point-in-time) |
| **Edge Cases** | Documented handling of known ambiguities | Mid-month upgrades: prorated for the partial month. Cancelled accounts: included until effective_to date. |
| **Data Source** | Authoritative source system and table | `analytics.fct_subscriptions` sourced from billing system |
| **Refresh Frequency** | How often the metric is updated | Daily at 06:00 UTC |
| **Owner** | Team or individual responsible for the metric definition | Revenue Operations |
| **SLA** | Availability and accuracy expectations | Available by 07:00 UTC, accurate to within 0.1% of billing system |

### Metric Naming Conventions

- Use business-friendly names, not technical jargon
- Prefix with the business domain: `Revenue: MRR`, `Support: Avg Resolution Time`
- Suffix with the time period if baked into the definition: `Monthly Active Users`, `7-Day Retention Rate`
- Never use abbreviations without defining them in a glossary
- Version metric definitions when the business logic changes: `MRR v2 (excl. trials)`

### Metric Classification

| Type | Description | Example | Aggregation Rules |
|------|-------------|---------|-------------------|
| **Additive** | Can be summed across all dimensions | Revenue, Units Sold | SUM across any dimension |
| **Semi-Additive** | Can be summed across some dimensions but not time | Account Balance, Inventory Count | SUM across non-time dimensions; use latest/average for time |
| **Non-Additive** | Cannot be summed at all | Ratio, Percentage, Distinct Count | Must be recomputed from atomic data at each aggregation level |

---

## Semantic Layer Patterns

### Centralized Metric Definitions

- **One canonical definition per metric** — no duplicate or conflicting definitions across dashboards
- Define metrics in a semantic layer tool (dbt metrics, Looker LookML, Cube.js, Tableau Data Models, Power BI measures) or a documented metric registry
- All dashboards and reports consume metrics from the semantic layer — they do not re-derive them
- Changes to a metric definition propagate to all consumers automatically

### Semantic Layer Architecture

```
Source Systems
    |
    v
Staging Layer (stg_)          -- raw data, minimal transformation
    |
    v
Intermediate Layer (int_)     -- joins, deduplication, business logic
    |
    v
Marts Layer (fct_, dim_)      -- dimensional model, single source of truth
    |
    v
Semantic Layer                 -- metric definitions, dimension hierarchies, access controls
    |
    v
Consumption (dashboards, ad-hoc queries, APIs, exports)
```

### Implementation Patterns

- **dbt Semantic Layer**: define metrics in `schema.yml` with `metrics:` block; expose via dbt Semantic Layer API
- **Looker/LookML**: define measures and dimensions in `.lkml` files; use `explores` for curated join paths
- **Power BI**: define DAX measures in the semantic model; publish as shared datasets
- **Tableau**: define calculated fields and LOD expressions in published data sources
- **Custom**: maintain a metrics YAML registry with SQL definitions, consumed by a query generation layer

### Governance Rules

- No metric can go live without: a documented definition, an owner, at least one test
- Breaking changes to metric definitions require: a version bump, stakeholder notification, transition period
- Deprecated metrics must display a warning in all consuming dashboards for 30 days before removal

---

## Dashboard Design Principles

### Information Hierarchy

Design dashboards in layers of detail:

1. **Executive Summary** (top of page): 3-5 headline KPIs with trend indicators and comparison to target
2. **Trend Analysis** (middle): time-series charts showing patterns and anomalies
3. **Detail Tables** (bottom or drill-through): supporting data for investigation

### Progressive Disclosure

- Start with the high-level answer, let users drill into details on demand
- Use drill-through links (not overcrowded single pages) for detailed analysis
- Provide filter panels for user-driven exploration, but set sensible defaults
- Maximum 7-10 visual elements per dashboard page — more than that creates cognitive overload

### Layout Rules

- Read flow: left-to-right, top-to-bottom (most important KPIs at top-left)
- Group related metrics visually (use sections, dividers, or color-coded backgrounds)
- Consistent card sizes — avoid jagged layouts
- Mobile-responsive: dashboards must be usable on tablet screens (test at 768px width)
- White space is valuable — do not pack every pixel with data

### Interactivity

- Cross-filtering: clicking one chart filters related charts on the same page
- Date range selector: always present, defaults to a useful period (last 30 days, current quarter)
- Drill-down: dimension hierarchies should be navigable (Year -> Quarter -> Month -> Day)
- Export: users can export underlying data as CSV for ad-hoc analysis
- Bookmarkable filters: URL parameters capture the current filter state

---

## Data Visualization Best Practices

### Chart Type Selection

| Data Relationship | Recommended Chart | Avoid |
|-------------------|-------------------|-------|
| Trend over time | Line chart | Pie chart, 3D anything |
| Part of whole | Stacked bar, treemap | Pie chart (> 5 categories) |
| Comparison | Bar chart (horizontal for many items) | Radar chart |
| Distribution | Histogram, box plot | Table of raw values |
| Correlation | Scatter plot | Dual-axis line chart |
| Single KPI | Big number with sparkline | Gauge (hard to read) |
| Geographic | Choropleth map | 3D globe |
| Ranking | Horizontal bar chart | Vertical bar with rotated labels |

### Color

- Use a consistent, accessible color palette across all dashboards
- Maximum 5-7 colors in any single chart — more colors reduce comprehension
- Use sequential palettes (light to dark) for quantitative data
- Use categorical palettes (distinct hues) for nominal data
- Red/green: use sparingly and never as the only differentiator (color blindness affects ~8% of males)
- Test all dashboards with a color blindness simulator (Coblis, Color Oracle)
- Reserve red for negative/alert and green for positive/success — but always pair with an icon or label

### Labeling

- Every chart must have: title, axis labels, data labels (or tooltip), and a legend (if > 1 series)
- Titles should state the insight, not just the metric: "Revenue Trending Up 12% QoQ" vs. "Revenue"
- Format numbers for readability: `$1.2M` not `$1,234,567.89`; `23.4%` not `0.234`
- Include the time period in the title or subtitle: "MRR by Region (Last 12 Months)"
- Avoid abbreviations in labels unless space-constrained (and provide a legend/glossary)

### Anti-Patterns

- **Dual-axis charts**: misleading because scales are independent. Use two separate charts or index to a common baseline.
- **3D charts**: distort perception of values. Always use 2D.
- **Pie charts with > 5 slices**: unreadable. Use a horizontal bar chart instead.
- **Truncated axes**: starting a bar chart at a value other than zero exaggerates differences. Always start bar charts at zero.
- **Spaghetti line charts**: > 5 lines on one chart. Use small multiples instead.
- **Dashboard as a data dump**: many tables with no visual summary. Lead with charts, support with tables.

---

## Self-Service Analytics Patterns

### Governed Access

- **Certified datasets**: mark official, approved datasets that analysts should use for production reporting
- **Sandbox datasets**: provide exploration-friendly datasets with appropriate guardrails (row limits, no PII)
- **Role-based access**: control which dimensions and measures are visible per user group
- **Promote path**: analyst-created reports can be promoted to certified dashboards through a review process

### Parameterized Reports

- Templates with user-selectable parameters (date range, region, product line)
- Default parameters that produce a useful result (do not show an empty report)
- Parameter validation: prevent invalid combinations, date ranges that are too wide, or queries that would time out
- Scheduled delivery: allow users to subscribe to reports at a cadence (daily, weekly, monthly)

### SQL Access

- Provide read-only SQL access to marts-layer tables for power users
- Enforce query timeouts and cost limits (BigQuery slot reservations, Snowflake warehouse size limits)
- Maintain a query library of common analytical patterns (templates, not just documentation)
- Log all ad-hoc queries for usage analysis and data governance

---

## Performance Optimization

### Materialized Views

- Pre-compute common aggregation patterns (daily revenue by region, weekly user counts by segment)
- Refresh materialized views on a schedule aligned with the underlying data refresh
- Name with `agg_` prefix to distinguish from base tables
- Monitor query patterns to identify new materialization candidates (most expensive/frequent queries)

### Aggregate Tables

For BI workloads with known access patterns, create aggregate tables at common grain levels:

| Base Table | Aggregate | Grain | Refresh |
|-----------|-----------|-------|---------|
| fct_orders | agg_daily_orders_by_region | day, region | Daily |
| fct_orders | agg_monthly_orders_by_product | month, product | Daily |
| fct_pageviews | agg_hourly_pageviews_by_page | hour, page_url | Hourly |

### Caching Strategies

- **Query result caching**: enable platform-native caching (BigQuery cache, Snowflake result cache)
- **Dashboard caching**: configure BI tool caching (Looker PDTs, Tableau extracts, Power BI incremental refresh)
- **Cache invalidation**: align cache TTL with data refresh frequency — stale cache is worse than no cache
- **Pre-warming**: for executive dashboards with tight SLAs, trigger cache warming after each data refresh

### Query Optimization Checklist

- Use `WHERE` filters that align with table partitioning (enable partition pruning)
- Avoid `SELECT DISTINCT` — fix the underlying data or join instead
- Use approximate aggregations where precision is not critical (`APPROX_COUNT_DISTINCT`)
- Limit ad-hoc queries with `LIMIT` and cost controls
- Profile query plans for expensive dashboards — optimize the slowest chart first

---

## Governance

### Metric Ownership

- Every metric has a named owner (team or individual) responsible for its definition, accuracy, and relevance
- Ownership is documented in the metric registry and visible in dashboards
- Owners review metric definitions quarterly (or when source data changes)
- Disputes about metric definitions are escalated to the data governance council

### Change Management

- Changes to metric definitions require: a PR to the metric registry, review by the metric owner, stakeholder notification
- Breaking changes (different numbers for the same metric name) require a new metric version
- All changes are version-controlled (metric definitions live in code, not in BI tool configurations alone)
- Maintain a changelog for every metric showing: what changed, when, why, who approved

### Version Control for Definitions

- Metric definitions stored as code (YAML, LookML, dbt `schema.yml`, or equivalent)
- Dashboard configurations stored as code where the BI tool supports it (Looker, Grafana, Superset)
- Changes go through the same PR review process as application code
- CI/CD validates metric definitions (syntax, required fields, test coverage)

### Data Quality for Analytics

- Every metric must have at least one automated test (value range, freshness, cross-check against source)
- Dashboard data freshness indicators: show the last refresh timestamp prominently
- Alert the metric owner if a metric's underlying data fails quality checks
- Publish a data quality scorecard alongside the metric catalog

---

## File Organization

When working in an analytics/BI project, follow this structure:

```
src/
  metrics/              # Metric definitions (YAML, LookML, dbt metrics)
  models/               # Semantic models, dbt models, LookML views
  dashboards/           # Dashboard definitions (if codified)
  reports/              # Scheduled report definitions
  quality/              # Analytics-specific data quality tests
docs/
  metrics-catalog/      # Human-readable metric documentation
  dashboard-specs/      # Dashboard wireframes and specifications
  governance/           # Governance policies, ownership matrix
tests/
  metrics/              # Metric computation validation tests
  dashboards/           # Dashboard rendering and data accuracy tests
```

---

## Integration with Core Framework

- `/discovery` phase: capture metric requirements, KPI definitions, dashboard audience, access patterns
- `/design` phase: use the `metric-definer` agent for metric specifications, define semantic layer architecture
- `/build` phase: enforce analytics patterns via rules, implement metric definitions in the semantic layer
- `/test` phase: validate metric computations against known values, test dashboard rendering
- `/deploy` phase: publish dashboards, notify stakeholders, update metric catalog
