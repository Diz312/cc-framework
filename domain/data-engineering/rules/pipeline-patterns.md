---
description: Data pipeline design patterns enforced in all data engineering sessions. Covers idempotency, error handling, configuration, logging, and incremental processing.
globs: "*.py,*.yaml,*.yml"
---

# Pipeline Design Patterns

## Idempotent Operations

Every pipeline operation must produce the same result regardless of how many times it runs.

### Write Patterns

- **Upsert (MERGE) over INSERT**: Default write pattern for dimension tables and any table with a natural key. Use `MERGE` / `INSERT ... ON CONFLICT` / `REPLACE INTO` depending on the engine.
- **Partition-level overwrite**: For fact tables and event data, delete the target partition then insert. This is atomic on most platforms (BigQuery, Redshift, Databricks).
- **Full table replace**: Acceptable only for small reference tables (< 100K rows). Write to a staging table, then swap.
- **Append-only**: Acceptable only when paired with deduplication downstream or when the target is an append-only log.

```python
# CORRECT: idempotent partition overwrite
def load_daily_orders(date: str, df: DataFrame) -> None:
    """Load orders for a specific date, replacing any existing data for that partition."""
    target_table = "analytics.fct_orders"
    partition_filter = f"order_date = '{date}'"

    # Delete existing data for this partition
    client.query(f"DELETE FROM {target_table} WHERE {partition_filter}")

    # Insert fresh data
    df.to_sql(target_table, method="append")


# WRONG: non-idempotent append
def load_daily_orders(date: str, df: DataFrame) -> None:
    df.to_sql("analytics.fct_orders", method="append")  # duplicates on re-run
```

### Read Patterns

- Always filter source data by the processing window (date range, watermark)
- Never read unbounded datasets — always apply a time or key range filter
- Use `SELECT ... WHERE updated_at > :last_watermark` for incremental reads

---

## Schema Evolution Handling

### Backward Compatible Changes (Safe)

These changes can be deployed without downstream coordination:
- Adding a new nullable column
- Adding a new table
- Widening a column type (e.g., `INT` to `BIGINT`, `VARCHAR(50)` to `VARCHAR(100)`)
- Adding a new enum value to the end of an enum list

### Breaking Changes (Require Migration)

These changes require a migration plan with downstream impact assessment:
- Removing or renaming a column
- Changing a column's data type (narrowing)
- Changing the grain of a table
- Altering primary key composition
- Changing partition scheme

### Migration Script Requirements

Every breaking schema change must include:
1. A numbered migration script (`migrations/V003__rename_customer_email.sql`)
2. A rollback script (or documented rollback procedure)
3. An impact assessment listing all downstream consumers
4. A deployment plan with timing and communication

```python
# Schema change detection pattern
def validate_schema(expected_schema: dict, actual_schema: dict) -> list[str]:
    """Compare expected vs actual schema, return list of violations."""
    violations = []
    for col_name, col_type in expected_schema.items():
        if col_name not in actual_schema:
            violations.append(f"Missing column: {col_name}")
        elif actual_schema[col_name] != col_type:
            violations.append(
                f"Type mismatch for {col_name}: "
                f"expected {col_type}, got {actual_schema[col_name]}"
            )
    return violations
```

---

## Error Handling Patterns

### Dead Letter Queues (DLQ)

For row-level failures in streaming or batch pipelines:
- Route failed records to a dead letter table/queue — never silently drop them
- Include: the original record, the error message, the timestamp, the pipeline run ID
- Alert when DLQ depth exceeds threshold
- Process DLQ records on a schedule (manual review or automated retry)

```python
# Dead letter pattern
def process_records(records: list[dict]) -> tuple[list[dict], list[dict]]:
    """Process records, separating successes from failures."""
    successes = []
    failures = []

    for record in records:
        try:
            transformed = transform(record)
            validate(transformed)
            successes.append(transformed)
        except (ValidationError, TransformError) as e:
            failures.append({
                "original_record": record,
                "error_type": type(e).__name__,
                "error_message": str(e),
                "failed_at": datetime.utcnow().isoformat(),
                "pipeline_run_id": get_run_id(),
            })

    if failures:
        write_to_dlq(failures)
        logger.warning(
            "Records sent to DLQ",
            extra={"dlq_count": len(failures), "total_count": len(records)},
        )

    return successes, failures
```

### Circuit Breakers

Prevent cascading failures when upstream systems are degraded:
- Track consecutive failure counts per upstream source
- Open the circuit (stop retrying) after N consecutive failures (default: 5)
- Half-open after a cooldown period — allow one test request
- Close the circuit when the test request succeeds

```python
class CircuitBreaker:
    """Simple circuit breaker for external service calls."""

    def __init__(
        self,
        failure_threshold: int = 5,
        cooldown_seconds: int = 300,
    ) -> None:
        self.failure_threshold = failure_threshold
        self.cooldown_seconds = cooldown_seconds
        self.failure_count: int = 0
        self.last_failure_time: float | None = None
        self.state: str = "closed"  # closed, open, half-open

    def can_execute(self) -> bool:
        if self.state == "closed":
            return True
        if self.state == "open":
            elapsed = time.time() - (self.last_failure_time or 0)
            if elapsed >= self.cooldown_seconds:
                self.state = "half-open"
                return True
            return False
        return True  # half-open: allow one attempt

    def record_success(self) -> None:
        self.failure_count = 0
        self.state = "closed"

    def record_failure(self) -> None:
        self.failure_count += 1
        self.last_failure_time = time.time()
        if self.failure_count >= self.failure_threshold:
            self.state = "open"
```

### Retry with Backoff

- Default retry strategy: 3 attempts with exponential backoff
- Use jitter to prevent thundering herd: `delay = base_delay * 2^attempt + random(0, base_delay)`
- Set a maximum delay cap (e.g., 5 minutes)
- Log every retry attempt with attempt number and delay

```python
import time
import random

def retry_with_backoff(
    func,
    max_retries: int = 3,
    base_delay: float = 1.0,
    max_delay: float = 300.0,
) -> any:
    """Execute function with exponential backoff and jitter."""
    for attempt in range(max_retries + 1):
        try:
            return func()
        except Exception as e:
            if attempt == max_retries:
                raise
            delay = min(base_delay * (2 ** attempt) + random.uniform(0, base_delay), max_delay)
            logger.warning(
                "Retry attempt",
                extra={
                    "attempt": attempt + 1,
                    "max_retries": max_retries,
                    "delay_seconds": round(delay, 2),
                    "error": str(e),
                },
            )
            time.sleep(delay)
```

---

## Configuration Externalization

### Rules

- **No hardcoded connection strings** — ever. Use environment variables or a secrets manager.
- **No hardcoded bucket/container names** — parameterize all storage paths.
- **No hardcoded project/account IDs** — inject via environment or configuration.
- **No hardcoded table names in transformation logic** — use configuration or templating.
- **No hardcoded date ranges** — parameterize all date filters.

### Configuration Hierarchy

```python
# CORRECT: externalized configuration
import os

config = {
    "project_id": os.environ["GCP_PROJECT_ID"],
    "dataset": os.environ["BQ_DATASET"],
    "source_bucket": os.environ["SOURCE_BUCKET"],
    "target_table": os.environ.get("TARGET_TABLE", "analytics.fct_orders"),
    "batch_size": int(os.environ.get("BATCH_SIZE", "10000")),
}


# WRONG: hardcoded values
config = {
    "project_id": "my-project-123",
    "dataset": "analytics",
    "source_bucket": "gs://my-bucket-prod",
    "target_table": "analytics.fct_orders",
}
```

### Secrets

- Use the client's secrets manager (GCP Secret Manager, AWS Secrets Manager, Azure Key Vault)
- Never pass secrets as command-line arguments (visible in process listings)
- Never log secrets — even at DEBUG level
- Rotate secrets on a defined schedule and after any suspected compromise

---

## Logging Standards

### Structured JSON Logging

All pipeline logs must be structured JSON — not plain text:

```python
import structlog

logger = structlog.get_logger()

# CORRECT: structured, queryable
logger.info(
    "pipeline_step_completed",
    pipeline="daily_orders",
    step="extract",
    source="salesforce",
    rows_extracted=15432,
    duration_seconds=12.5,
    run_id="abc-123",
)

# WRONG: unstructured plain text
print(f"Extracted 15432 rows from salesforce in 12.5s")
```

### Required Log Fields

Every log entry must include:
- `pipeline` — pipeline name
- `run_id` — unique identifier for this pipeline run (correlation ID)
- `step` — which step in the pipeline (extract, transform, load, validate)
- `timestamp` — ISO 8601 UTC

### Sensitive Data in Logs

- **Never log PII**: names, emails, phone numbers, addresses, SSNs
- **Never log credentials**: passwords, API keys, tokens, connection strings
- **Never log full SQL with parameter values** — log the template with placeholders
- **Acceptable**: row counts, table names, column names, durations, error messages (without PII)

### Log Levels

| Level | Use For |
|-------|---------|
| `DEBUG` | Detailed diagnostic info (row-level tracing, SQL templates) — disabled in production |
| `INFO` | Normal operational events (step started, step completed, row counts) |
| `WARNING` | Recoverable issues (retries, soft quality failures, degraded performance) |
| `ERROR` | Failures requiring attention (step failed, quality hard fail, unrecoverable error) |
| `CRITICAL` | System-level failures (cannot connect to database, secrets unavailable) |

---

## Data Validation at Boundaries

Validate data at every transition point — do not trust upstream data:

### Ingestion Boundary

- Validate schema (column names, types) before processing
- Check for unexpected nulls in required fields
- Verify row counts are within expected range
- Detect and handle encoding issues (UTF-8 validation)

### Transformation Output

- Assert grain: verify primary key uniqueness after every join
- Validate computed columns against known ranges
- Check for unintended fanout (row count before join vs. after)
- Verify referential integrity for foreign keys

### Load Boundary

- Validate row counts match between transformation output and target
- Verify no data was silently dropped during load
- Check partition alignment (data landed in the correct partition)
- Confirm timestamps are in UTC

```python
def validate_at_boundary(
    df: DataFrame,
    expected_columns: list[str],
    primary_key: list[str],
    not_null_columns: list[str],
) -> list[str]:
    """Validate a DataFrame at a pipeline boundary."""
    violations = []

    # Schema check
    missing_cols = set(expected_columns) - set(df.columns)
    if missing_cols:
        violations.append(f"Missing columns: {missing_cols}")

    # Primary key uniqueness
    dup_count = df.duplicated(subset=primary_key).sum()
    if dup_count > 0:
        violations.append(f"Primary key duplicates: {dup_count} rows")

    # Not-null check
    for col in not_null_columns:
        if col in df.columns:
            null_count = df[col].isna().sum()
            if null_count > 0:
                violations.append(f"Null values in {col}: {null_count} rows")

    # Empty DataFrame check
    if len(df) == 0:
        violations.append("DataFrame is empty — expected at least one row")

    return violations
```

---

## Incremental Processing Patterns

### Watermark-Based

Track the last successfully processed position (timestamp, ID, offset):

```python
def get_watermark(pipeline_name: str, source_name: str) -> str:
    """Retrieve the last processed watermark from metadata table."""
    result = client.query(
        """
        SELECT watermark_value
        FROM pipeline_metadata.watermarks
        WHERE pipeline_name = @pipeline_name
          AND source_name = @source_name
        """,
        params={"pipeline_name": pipeline_name, "source_name": source_name},
    )
    return result.scalar() or "1970-01-01T00:00:00Z"  # default: beginning of time


def update_watermark(pipeline_name: str, source_name: str, new_value: str) -> None:
    """Update the watermark after successful processing."""
    client.query(
        """
        MERGE INTO pipeline_metadata.watermarks AS t
        USING (SELECT @pipeline_name AS pipeline_name, @source_name AS source_name) AS s
        ON t.pipeline_name = s.pipeline_name AND t.source_name = s.source_name
        WHEN MATCHED THEN UPDATE SET watermark_value = @new_value, updated_at = CURRENT_TIMESTAMP()
        WHEN NOT MATCHED THEN INSERT (pipeline_name, source_name, watermark_value, updated_at)
            VALUES (@pipeline_name, @source_name, @new_value, CURRENT_TIMESTAMP())
        """,
        params={
            "pipeline_name": pipeline_name,
            "source_name": source_name,
            "new_value": new_value,
        },
    )
```

### Change Data Capture (CDC)

- Prefer platform-native CDC (Datastream, DMS, Debezium) over polling-based CDC
- Process CDC events in order — use sequence numbers or timestamps
- Handle all CDC operation types: INSERT, UPDATE, DELETE
- Compact CDC logs before applying to the target (only keep the latest state per key)
- Maintain a CDC lag monitoring metric

### Micro-Batch

- For near-real-time requirements where true streaming is overkill
- Process in small time windows (1-15 minutes)
- Each micro-batch is a self-contained idempotent operation
- Use the same watermark pattern as batch, just with shorter intervals

---

## Orchestrator-Agnostic Design

Separate business logic from orchestration — pipeline code must be runnable without an orchestrator:

```python
# CORRECT: business logic is independent of orchestrator
# src/transformations/daily_orders.py
def extract_orders(source_config: dict, date_range: tuple[str, str]) -> DataFrame:
    """Extract orders for a date range. No Airflow/Prefect/Dagster imports."""
    ...

def transform_orders(raw_orders: DataFrame) -> DataFrame:
    """Apply business transformations. Pure function."""
    ...

def load_orders(transformed: DataFrame, target_config: dict) -> int:
    """Load transformed orders to target. Returns row count."""
    ...


# pipelines/daily_orders_dag.py (orchestrator-specific wrapper)
from airflow import DAG
from airflow.operators.python import PythonOperator
from transformations.daily_orders import extract_orders, transform_orders, load_orders

with DAG("daily_orders", schedule="0 6 * * *") as dag:
    extract = PythonOperator(task_id="extract", python_callable=extract_orders, ...)
    transform = PythonOperator(task_id="transform", python_callable=transform_orders, ...)
    load = PythonOperator(task_id="load", python_callable=load_orders, ...)
    extract >> transform >> load


# WRONG: business logic tightly coupled to Airflow
from airflow.models import Variable
from airflow.hooks.base import BaseHook

def transform_orders(**context):
    conn = BaseHook.get_connection("my_db")  # Airflow-specific
    date = context["ds"]  # Airflow-specific
    threshold = Variable.get("order_threshold")  # Airflow-specific
    ...
```

### Testing Implications

- Business logic functions are unit-testable without the orchestrator
- Orchestrator wrappers are thin — they just wire inputs/outputs and handle scheduling
- Integration tests run the full pipeline locally without the orchestrator
- Orchestrator-specific tests validate DAG structure, scheduling, and dependency ordering

---

## Pipeline Metadata

Every pipeline must maintain operational metadata:

```sql
CREATE TABLE pipeline_metadata.run_log (
    run_id          STRING NOT NULL,
    pipeline_name   STRING NOT NULL,
    step_name       STRING NOT NULL,
    status          STRING NOT NULL,     -- running, success, failed
    started_at      TIMESTAMP NOT NULL,
    completed_at    TIMESTAMP,
    rows_read       INT64,
    rows_written    INT64,
    error_message   STRING,
    parameters      JSON,                -- runtime parameters
    PRIMARY KEY (run_id, pipeline_name, step_name)
);
```

Track: run ID, pipeline name, step name, start/end time, row counts, status, error details.
Use this for: debugging, auditing, SLA monitoring, capacity planning.
