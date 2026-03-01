---
description: SQL coding standards enforced in all data engineering sessions. Defines formatting, naming, and structural conventions for SQL code.
globs: "*.sql"
---

# SQL Standards

## Formatting

### Keywords and Identifiers

- **Uppercase all SQL keywords**: `SELECT`, `FROM`, `WHERE`, `JOIN`, `ON`, `GROUP BY`, `ORDER BY`, `HAVING`, `UNION`, `INSERT`, `UPDATE`, `DELETE`, `CREATE`, `ALTER`, `DROP`, `WITH`, `AS`, `AND`, `OR`, `NOT`, `IN`, `BETWEEN`, `LIKE`, `IS`, `NULL`, `CASE`, `WHEN`, `THEN`, `ELSE`, `END`, `OVER`, `PARTITION BY`, `CAST`, `COALESCE`
- **Lowercase all identifiers**: table names, column names, aliases, schema names, CTE names
- **snake_case for all identifiers**: `customer_id`, `order_date`, `total_revenue` — never camelCase or PascalCase

### Commas and Line Breaks

- **Trailing commas** in column lists (column on its own line, comma at the end):

```sql
SELECT
    o.order_id,
    o.order_date,
    o.customer_id,
    c.customer_name,
FROM orders AS o
```

- One column per line in SELECT, GROUP BY, and ORDER BY clauses
- Each JOIN on its own line
- Each WHERE condition on its own line
- Indent continuation lines by 4 spaces

### Alignment

- Align major clauses at the left margin: `SELECT`, `FROM`, `WHERE`, `GROUP BY`, `ORDER BY`, `HAVING`, `LIMIT`
- Indent column lists, join conditions, and filter conditions by 4 spaces
- Indent CTE body by 4 spaces from the CTE name

---

## CTEs Over Subqueries

Always use Common Table Expressions (CTEs) instead of nested subqueries:

```sql
-- CORRECT: CTEs are readable, testable, and reusable
WITH daily_orders AS (
    SELECT
        customer_id,
        DATE(order_date) AS order_day,
        COUNT(*) AS order_count,
        SUM(order_total) AS daily_total,
    FROM orders AS o
    WHERE o.order_date >= '2025-01-01'
    GROUP BY
        customer_id,
        DATE(order_date)
),

customer_summary AS (
    SELECT
        do.customer_id,
        AVG(do.daily_total) AS avg_daily_spend,
        MAX(do.order_count) AS max_daily_orders,
    FROM daily_orders AS do
    GROUP BY do.customer_id
)

SELECT
    cs.customer_id,
    c.customer_name,
    cs.avg_daily_spend,
    cs.max_daily_orders,
FROM customer_summary AS cs
INNER JOIN customers AS c
    ON cs.customer_id = c.customer_id
ORDER BY cs.avg_daily_spend DESC
```

```sql
-- WRONG: Nested subqueries are hard to read and debug
SELECT
    customer_id,
    customer_name,
    avg_daily_spend
FROM (
    SELECT
        customer_id,
        AVG(daily_total) AS avg_daily_spend
    FROM (
        SELECT customer_id, DATE(order_date) AS order_day, SUM(order_total) AS daily_total
        FROM orders
        WHERE order_date >= '2025-01-01'
        GROUP BY customer_id, DATE(order_date)
    )
    GROUP BY customer_id
)
JOIN customers USING (customer_id)
```

### CTE Naming

- Use descriptive, business-meaningful names: `daily_revenue`, `active_customers`, `filtered_transactions`
- Never use generic names: `tmp`, `cte1`, `sub`, `t1`
- Prefix staging CTEs with `stg_` if they mirror a staging transformation

---

## Explicit Column Lists

Never use `SELECT *` in production SQL:

```sql
-- CORRECT: explicit columns
SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    o.order_total,
FROM orders AS o

-- WRONG: fragile to schema changes, wastes resources
SELECT * FROM orders
```

Exceptions:
- `SELECT COUNT(*)` is acceptable
- `SELECT * FROM cte_name` within the same query is acceptable only when the CTE already defines explicit columns
- Ad-hoc exploration in notebooks or CLI is acceptable (but never in committed code)

---

## Column Qualification

Qualify every column reference with its table alias, even when unambiguous:

```sql
-- CORRECT: fully qualified
SELECT
    o.order_id,
    o.order_date,
    c.customer_name,
FROM orders AS o
INNER JOIN customers AS c
    ON o.customer_id = c.customer_id

-- WRONG: ambiguous and fragile
SELECT
    order_id,
    order_date,
    customer_name
FROM orders
JOIN customers ON customer_id = customer_id
```

### Aliasing Rules

- Always use the `AS` keyword for aliases: `FROM orders AS o`, not `FROM orders o`
- Table aliases: use meaningful abbreviations (2-4 characters): `orders AS o`, `customers AS c`, `line_items AS li`
- Column aliases: use descriptive names that reflect business meaning
- Never alias a column to the same name it already has

---

## Window Functions

Prefer window functions over self-joins or correlated subqueries:

```sql
-- CORRECT: window function for running total
SELECT
    o.order_id,
    o.order_date,
    o.order_total,
    SUM(o.order_total) OVER (
        PARTITION BY o.customer_id
        ORDER BY o.order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total,
FROM orders AS o

-- WRONG: self-join for running total (expensive, hard to read)
SELECT
    o1.order_id,
    o1.order_date,
    o1.order_total,
    SUM(o2.order_total) AS running_total
FROM orders AS o1
INNER JOIN orders AS o2
    ON o1.customer_id = o2.customer_id
    AND o2.order_date <= o1.order_date
GROUP BY o1.order_id, o1.order_date, o1.order_total
```

### Window Function Formatting

- Name the window if reused: `WINDOW w AS (PARTITION BY ... ORDER BY ...)`
- Each window clause element on its own line when the window spec exceeds 80 characters
- Always specify frame clause explicitly when using aggregate window functions (`ROWS BETWEEN ...`)

---

## COALESCE Over Platform-Specific Functions

Use `COALESCE` for null handling — it is ANSI SQL and works across all engines:

```sql
-- CORRECT: portable
COALESCE(o.discount_amount, 0) AS discount_amount

-- WRONG: platform-specific
IFNULL(o.discount_amount, 0)   -- MySQL/BigQuery
NVL(o.discount_amount, 0)      -- Oracle/Snowflake
ISNULL(o.discount_amount, 0)   -- SQL Server
```

---

## Date and Timestamp Handling

### Timezone Awareness

- Always store timestamps in UTC
- Convert to local timezone only at the presentation layer
- Use explicit timezone functions: `TIMESTAMP_TRUNC(ts, DAY, 'UTC')`, not `DATE(ts)`
- Document the timezone assumption for every date/timestamp column

### Date Format

- Use ISO 8601 format in all date literals: `'2025-01-15'`, `'2025-01-15T14:30:00Z'`
- Never use ambiguous formats: `'01/15/2025'`, `'15-Jan-2025'`

### Date Functions

- Use `DATE_TRUNC` / `TIMESTAMP_TRUNC` for rounding (not string manipulation)
- Use `DATE_DIFF` / `TIMESTAMP_DIFF` for intervals (not arithmetic on date parts)
- Cast explicitly between DATE and TIMESTAMP: `CAST(order_date AS TIMESTAMP)`

---

## JOIN Syntax

### Explicit Join Types

Always specify the join type explicitly:

```sql
-- CORRECT
INNER JOIN customers AS c ON o.customer_id = c.customer_id
LEFT JOIN returns AS r ON o.order_id = r.order_id

-- WRONG: implicit join (comma syntax)
FROM orders o, customers c
WHERE o.customer_id = c.customer_id

-- WRONG: unspecified join type
JOIN customers AS c ON o.customer_id = c.customer_id
```

### Join Rules

- `INNER JOIN` when both sides must exist
- `LEFT JOIN` when the right side is optional — never use `RIGHT JOIN` (reorder tables instead)
- `CROSS JOIN` only with explicit intent and a comment explaining why
- Never use `NATURAL JOIN` — it is fragile and implicit
- Join conditions go in `ON`, not in `WHERE` (except for filter conditions on the outer table in outer joins)
- Place the driving/larger table on the left side of the join

---

## WHERE Clause Ordering

Order WHERE conditions for readability and performance:

1. **Partition pruning filters first** (date ranges, partition keys)
2. **Most selective filters next** (filters that eliminate the most rows)
3. **Equality conditions before range conditions**
4. **Simple conditions before complex expressions**
5. **Conditions on indexed columns before non-indexed**

```sql
WHERE
    o.order_date >= '2025-01-01'                   -- partition pruning
    AND o.order_date < '2025-02-01'                -- partition pruning
    AND o.status = 'completed'                     -- selective equality
    AND o.customer_id IN (SELECT ...)              -- semi-join
    AND o.order_total BETWEEN 100 AND 10000        -- range
    AND LOWER(o.notes) LIKE '%refund%'             -- expensive expression last
```

---

## Comments

### Required Comments

- **CTE purpose**: one-line comment above each CTE explaining what it computes
- **Complex logic**: any non-obvious business rule, calculation, or filter
- **Workarounds**: any hack, platform-specific workaround, or known limitation
- **Magic numbers**: explain the meaning of any literal value that is not self-evident

### Comment Style

```sql
-- Single-line comments for brief explanations
-- Use double-dash style, not /* */ for inline comments

/*
Multi-line block comments for:
- Complex business rule explanations
- Historical context or known issues
- References to Jira tickets or documentation
*/

-- Calculate revenue net of returns and discounts
-- Business rule: returns within 30 days reduce revenue; after 30 days they do not
WITH net_revenue AS (
    ...
)
```

### Prohibited Comments

- Do not add comments that merely restate the SQL: `-- Select customer_id from customers`
- Do not leave commented-out code in production SQL — delete it and rely on version control
- Do not add TODO comments without a Jira ticket reference

---

## Naming Conventions

### Tables

| Layer | Prefix | Example |
|-------|--------|---------|
| Staging | `stg_` | `stg_salesforce_accounts` |
| Intermediate | `int_` | `int_customer_orders_joined` |
| Fact | `fct_` | `fct_orders` |
| Dimension | `dim_` | `dim_customers` |
| Aggregate | `agg_` | `agg_daily_revenue` |
| Snapshot | `snp_` | `snp_inventory_daily` |
| Seed/Reference | `ref_` | `ref_country_codes` |

### Columns

- Boolean columns: prefix with `is_`, `has_`, or `was_` (`is_active`, `has_returns`, `was_deleted`)
- Date columns: suffix with `_date` (`order_date`, `ship_date`)
- Timestamp columns: suffix with `_at` (`created_at`, `updated_at`, `_loaded_at`)
- Count columns: suffix with `_count` (`order_count`, `item_count`)
- Amount columns: suffix with `_amount` (`discount_amount`, `tax_amount`)
- ID columns: suffix with `_id` (`customer_id`, `order_id`) — or `_key` for surrogate keys (`customer_key`)

---

## Anti-Patterns to Avoid

- `SELECT DISTINCT` to mask a bad join — fix the join instead
- `ORDER BY` in subqueries or CTEs (it does nothing in most engines unless paired with LIMIT)
- `UNION` when `UNION ALL` suffices — `UNION` implies a sort-dedup that is usually unnecessary
- Implicit type coercion in join conditions (`ON o.id = CAST(s.id AS INT)` — fix the source instead)
- `HAVING` without `GROUP BY` — use `WHERE` instead
- Multiple columns with the same name from different tables (always alias to disambiguate)
