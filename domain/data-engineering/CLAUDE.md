# Data Engineering Standards

This file **supplements** the core `CLAUDE.md` — it does not replace it. All core principles (simplicity, platform-native first, 12-Factor, security) still apply. This overlay adds data engineering-specific standards for pipeline design, SQL authoring, schema modeling, and data quality.

---

## Data Pipeline Design Principles

### Idempotency

Every pipeline operation must be safely re-runnable without side effects:
- Use `MERGE`/upsert patterns instead of blind `INSERT`
- Partition-level overwrites for batch loads (delete-then-insert at partition granularity)
- Design transformations as pure functions of their inputs — same input always produces same output
- Never rely on row order or auto-increment IDs for correctness

### Exactly-Once Semantics

- Prefer at-least-once delivery with idempotent consumers over complex exactly-once infrastructure
- Use natural keys or deterministic surrogate keys to deduplicate at the target
- For streaming pipelines, leverage framework-native checkpointing (Kafka offsets, Dataflow checkpoints, Flink savepoints)
- Record high-watermarks in a metadata table to track processing state

### Schema Evolution

- All schema changes must be backward compatible (additive only in production)
- New columns must have defaults or be nullable — never add a NOT NULL column without a default to an existing table
- Maintain a schema registry or migration history for all managed datasets
- Version data contracts: breaking changes require a new version (e.g., `v1/`, `v2/`)
- Document deprecation timelines before removing columns or tables

### Backfill Capability

- Every pipeline must support historical reprocessing without code changes
- Parameterize date ranges — no hardcoded date logic
- Backfills must be partition-aware: reprocess only affected partitions
- Maintain backfill runbooks documenting: estimated duration, resource requirements, downstream impact, rollback procedure

---

## SQL Standards

Full rules in `rules/sql-standards.md`. Key principles:

- **CTEs over subqueries** — always. Subqueries are harder to test, debug, and reuse.
- **Explicit column lists** — never `SELECT *` in production code (fragile to schema changes)
- **Qualify all columns** — every column reference includes its table alias
- **Trailing commas** — easier diffs, fewer merge conflicts
- **Uppercase keywords** — `SELECT`, `FROM`, `WHERE`, `JOIN`, etc.
- **Lowercase identifiers** — table names, column names, aliases
- **COALESCE over IFNULL/NVL** — ANSI standard, portable across engines

---

## Schema Design Patterns

### Slowly Changing Dimensions (SCD)

Choose the appropriate SCD strategy per dimension:

| Type | Use When | Pattern |
|------|----------|---------|
| SCD Type 1 | History not needed (e.g., typo corrections) | Overwrite in place |
| SCD Type 2 | Full history required (e.g., customer address changes) | New row with `effective_from`, `effective_to`, `is_current` |
| SCD Type 3 | Only previous value needed | Add `previous_` column |
| SCD Type 6 | Hybrid (current + history) | Combine Type 1 + 2 + 3 columns |

Default to **SCD Type 2** unless there is a documented reason for a simpler approach.

### Surrogate Keys

- Every dimension table gets a surrogate key (integer or hash-based)
- Never expose natural keys as the primary join key in the dimensional model — natural keys change
- Use deterministic hashing (`MD5`/`SHA256` of business key columns) for Data Vault or load-independent key generation
- Document the business key composition for every surrogate key

### Audit Columns

Every table must include:

```sql
created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
created_by      STRING NOT NULL,       -- pipeline name or user
_loaded_at      TIMESTAMP NOT NULL,    -- when the ETL loaded this row
_source_system  STRING NOT NULL        -- originating system identifier
```

### Soft Deletes

- Production tables use soft deletes: `is_deleted BOOLEAN DEFAULT FALSE`, `deleted_at TIMESTAMP`
- Hard deletes only for PII/GDPR compliance (document and audit)
- Downstream queries must filter on `is_deleted = FALSE` or `WHERE deleted_at IS NULL`
- Create views that pre-filter soft deletes for analyst consumption

---

## Data Quality Requirements

### Testing Framework

- Every pipeline must have data quality tests — no exceptions
- Use **Great Expectations**, **dbt tests**, **Soda**, or platform-native equivalents (BigQuery assertions, Databricks expectations)
- Tests run automatically as part of the pipeline DAG, not as a separate process

### Mandatory Test Categories

1. **Schema tests**: column presence, data types, not-null constraints
2. **Uniqueness tests**: primary keys, natural keys, business keys
3. **Referential integrity**: foreign key relationships (even in warehouses without enforcement)
4. **Freshness tests**: data arrives within expected SLA window
5. **Volume tests**: row counts within expected bounds (alert on anomalies > 2 standard deviations)
6. **Value range tests**: numeric values within business-valid ranges
7. **Null checks**: critical columns have acceptable null rates (define thresholds per column)

### Quality Gates

- **Hard fail**: Pipeline stops, no data published. For: uniqueness violations on primary keys, schema drift on critical columns, zero-row outputs for expected-populated tables.
- **Soft fail**: Pipeline continues, alert fires. For: null rate above threshold, row count anomalies, freshness warnings.
- Document the quality gate classification for every test.

---

## Orchestration Patterns

### DAG Design

- **One DAG per logical pipeline** — do not mix unrelated workloads in a single DAG
- **Task granularity**: one task = one logical unit of work (extract one source, transform one model, load one target)
- Keep DAGs shallow (< 5 levels deep) — deep DAGs are hard to debug and retry
- Use task groups (Airflow) or sub-pipelines to organize complex DAGs without nesting
- Separate extraction, transformation, and loading into distinct task groups

### Retry Policies

- All tasks must have retry configuration — no silent failures
- Default: 3 retries with exponential backoff (30s, 60s, 120s)
- Idempotent tasks can retry aggressively; non-idempotent tasks retry cautiously
- Set maximum retry delay caps to prevent infinite backoff
- External API calls: respect rate limits in retry logic

### Alerting

- **Critical alerts** (page): pipeline failure after all retries exhausted, SLA breach, data quality hard fail
- **Warning alerts** (ticket): data quality soft fail, unusual latency, resource threshold exceeded
- **Informational** (log only): successful completions, backfill progress, row counts
- Route alerts to the owning team, not a shared channel
- Include runbook links in every alert message

---

## Platform-Native First

Use the client's cloud-native services before introducing external tools:

| Capability | GCP | AWS | Azure |
|-----------|-----|-----|-------|
| Orchestration | Cloud Composer | MWAA / Step Functions | Data Factory |
| Warehouse | BigQuery | Redshift / Athena | Synapse / Fabric |
| Streaming | Pub/Sub + Dataflow | Kinesis + Glue Streaming | Event Hubs + Stream Analytics |
| Batch ETL | Dataflow / Dataproc | Glue / EMR | Databricks / HDInsight |
| CDC | Datastream | DMS | Change Feed |
| Data Lake | GCS | S3 | ADLS Gen2 |
| Metadata | Data Catalog | Glue Catalog | Purview |
| Quality | BigQuery assertions | Glue DQ | Purview DQ |

Only recommend non-native tools (Airflow on K8s, Spark standalone, Fivetran, etc.) when there is a documented technical or cost justification in an ADR.

---

## Partitioning and Clustering Strategy

### Partitioning

- Partition every table expected to exceed 1 GB or 10M rows
- Default partition key: date/timestamp column aligned with most common query filter
- Ingestion-time partitioning for append-only event tables
- Integer-range partitioning for ID-based access patterns
- Document partition key choice and expected partition sizes

### Clustering

- Cluster on columns frequently used in `WHERE`, `JOIN`, and `GROUP BY` after the partition key
- Order clustering columns by selectivity (most selective first)
- Limit to 3-4 clustering columns (diminishing returns beyond that)
- Re-cluster on schedule if the platform does not auto-cluster (e.g., Redshift SORTKEY)

### Anti-Patterns

- Never partition on a high-cardinality column that creates millions of micro-partitions
- Never skip partitioning on large tables "because we'll add it later" — retrofitting is expensive
- Never cluster on columns with low cardinality (< 100 distinct values) as the only cluster key

---

## Data Lineage and Documentation

### Lineage Requirements

- Every dataset must have documented upstream sources and downstream consumers
- Use platform-native lineage (BigQuery lineage, Purview, OpenLineage) where available
- For custom pipelines, emit OpenLineage events or maintain a lineage metadata table
- Lineage must be queryable: "what happens if I change column X in table Y?"

### Documentation Standards

- Every table: description, owner, SLA, refresh frequency, grain, primary key, partitioning
- Every column: description, data type, business definition, allowed values/ranges, null policy
- Every pipeline: purpose, schedule, dependencies, SLA, runbook link, contact/owner
- Store documentation alongside code (dbt `schema.yml`, inline SQL comments, or a data catalog)
- Review and update documentation as part of every PR that changes a pipeline or schema

---

## File Organization

When working in a data engineering project, follow this structure:

```
src/
  pipelines/            # Pipeline DAG definitions
  transformations/      # SQL and Python transformation logic
  models/               # dbt models or equivalent
  schemas/              # DDL, schema definitions, migrations
  quality/              # Data quality test definitions
  utils/                # Shared utilities (logging, config, connections)
docs/
  architecture/         # Architecture decisions, data flow diagrams
  runbooks/             # Operational runbooks per pipeline
  data-dictionary/      # Table and column documentation
tests/
  unit/                 # Unit tests for transformation logic
  integration/          # Integration tests for pipeline end-to-end
  quality/              # Data quality test configurations
```

---

## Integration with Core Framework

- `/discovery` phase: include data source inventory, volume estimates, SLA requirements, data quality expectations
- `/design` phase: use the `pipeline-architect` agent for pipeline DAG design, `data-modeler` agent for schema design
- `/build` phase: enforce SQL standards and pipeline patterns via rules
- `/test` phase: data quality tests are mandatory, not optional
- `/deploy` phase: include data quality gates in CI/CD, migration scripts in deployment
