# GCP Platform Engineering Standards

Layer 3 platform module for Google Cloud Platform engagements. These standards supplement
the core engineering standards (Layer 1) and domain standards (Layer 2) with GCP-specific
patterns, conventions, and guardrails.

**Principle**: Platform-native first. Prefer GCP-managed services over self-hosted alternatives.
BigQuery over Spark for analytics. Dataflow over third-party ETL. Cloud Composer over
self-hosted Airflow. Cloud Run over self-managed containers.

---

## BigQuery

### Dataset Organization

Use a layered dataset architecture. Each layer is a separate BigQuery dataset with clear
ownership and access patterns:

```
project-env-raw          # Landing zone: ingested data, append-only, no transformations
project-env-staging      # Cleaned, deduplicated, typed — intermediate processing
project-env-curated      # Business-modeled, tested, documented — source of truth
project-env-analytics    # Aggregated, denormalized — optimized for consumption
project-env-sandbox      # Ad-hoc exploration, no SLA, auto-expire tables (7-day default)
```

Rules:
- Raw datasets are append-only — never update or delete raw records
- Staging tables are idempotent — re-running produces identical results
- Curated tables have schema documentation, column descriptions, and data classification labels
- Analytics tables are optimized for BI tool access patterns (pre-aggregated, wide tables)
- Sandbox datasets have default table expiration (7 days) to prevent cost creep

### Partitioning

Partition every table over 1 GB. Choose the right strategy:

- **Time-based (ingestion time)**: Default for event/log data. Use `_PARTITIONTIME` pseudo-column.
  Partition by DAY unless query patterns require HOUR (streaming) or MONTH (historical).
- **Time-based (column)**: Preferred when a timestamp column exists in the data. Enables
  partition pruning on business dates (e.g., `order_date`, `event_timestamp`).
- **Integer-range**: Use for tables keyed on numeric IDs where time partitioning does not apply.
  Define start, end, and interval based on data distribution.

```sql
-- Time-unit column partitioning (preferred for most tables)
CREATE TABLE project.dataset.orders (
  order_id STRING,
  order_date DATE,
  customer_id STRING,
  total_amount NUMERIC
)
PARTITION BY order_date
CLUSTER BY customer_id
OPTIONS (
  partition_expiration_days = 365,
  require_partition_filter = true,
  description = 'Customer orders partitioned by order date'
);
```

Always set `require_partition_filter = true` on large tables to prevent full-scan queries.

### Clustering

Cluster tables by columns that appear frequently in WHERE and JOIN clauses. BigQuery supports
up to four clustering columns. Order matters — put the highest-cardinality filter first.

Common patterns:
- Event tables: `CLUSTER BY user_id, event_type`
- Transaction tables: `CLUSTER BY customer_id, product_category`
- Log tables: `CLUSTER BY severity, service_name`

Clustering is free to apply and automatically maintained by BigQuery. Re-cluster older data
with scheduled queries or `bq update --clustering_fields`.

### Slot Management and Cost Optimization

**On-demand vs. Flat-rate decision framework**:
- On-demand: best for unpredictable workloads, < $10K/month BigQuery spend
- Standard edition (slots): predictable workloads, need cost ceiling, > $10K/month
- Enterprise edition: need multi-region, advanced security, > $50K/month
- Enterprise Plus: mission-critical, highest SLA requirements

**Cost optimization rules**:
- Never use `SELECT *` in production queries — always specify columns
- Use `LIMIT` during development and exploration (but note: LIMIT does not reduce bytes scanned
  on non-clustered columns — it only limits output rows)
- Run query dry-runs before executing expensive queries:
  `bq query --dry_run --use_legacy_sql=false 'SELECT ...'`
- Use `INFORMATION_SCHEMA` views for metadata queries instead of scanning tables
- Materialize intermediate results for queries run more than once per day
- Set `maximum_bytes_billed` on queries to prevent runaway costs
- Monitor with `INFORMATION_SCHEMA.JOBS` and set up BigQuery cost alerts
- Use BI Engine for sub-second dashboard queries (reserve BI Engine capacity)
- Prefer `MERGE` over DELETE + INSERT for slowly changing dimensions

### Authorized Views and Row-Level Security

Use authorized views to share data across projects without granting direct table access:

```sql
-- Create a view that filters to the user's allowed data
CREATE VIEW project.curated.customer_view AS
SELECT * FROM project.curated.customers
WHERE region IN (
  SELECT allowed_region FROM project.curated.user_access
  WHERE user_email = SESSION_USER()
);

-- Authorize the view (via bq CLI or Terraform)
-- bq update --view project:curated.customer_view --authorize_view project:curated.customers
```

For row-level security, use BigQuery row-level access policies:

```sql
CREATE ROW ACCESS POLICY region_filter
ON project.curated.customers
GRANT TO ('group:analysts@company.com')
FILTER USING (region = 'APAC');
```

Use authorized datasets for cross-project access — more maintainable than individual view authorization.

---

## Cloud Storage

### Bucket Naming

Convention: `{project-id}-{env}-{purpose}-{region}`

Examples:
- `myproject-prod-data-lake-us-central1`
- `myproject-dev-temp-processing-us-central1`
- `myproject-prod-ml-artifacts-us`

Rules:
- Always include environment and purpose in bucket names
- Include region for single-region buckets
- Use hyphens, lowercase only (GCS requirement)
- Never use personally identifiable information in bucket names

### Lifecycle Policies

Apply lifecycle rules to every bucket. Common patterns:

```json
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "SetStorageClass", "storageClass": "NEARLINE"},
        "condition": {"age": 30, "matchesStorageClass": ["STANDARD"]}
      },
      {
        "action": {"type": "SetStorageClass", "storageClass": "COLDLINE"},
        "condition": {"age": 90, "matchesStorageClass": ["NEARLINE"]}
      },
      {
        "action": {"type": "SetStorageClass", "storageClass": "ARCHIVE"},
        "condition": {"age": 365, "matchesStorageClass": ["COLDLINE"]}
      },
      {
        "action": {"type": "Delete"},
        "condition": {"age": 2555, "matchesStorageClass": ["ARCHIVE"]}
      }
    ]
  }
}
```

Temp/scratch buckets: delete objects after 7 days. No exceptions.

### Object Versioning

- Enable versioning on all production data buckets
- Set a lifecycle rule to delete old versions after N days (30 for most, 90 for critical)
- Never enable versioning on temp/scratch buckets (wastes storage)

### IAM Patterns

- Use **uniform bucket-level access** (not fine-grained ACLs) — this is now the GCS default
- Grant roles at the project level for broad access, bucket level for specific access
- Common roles:
  - `roles/storage.objectViewer` — read-only (default for consumers)
  - `roles/storage.objectCreator` — write without delete (pipelines writing data)
  - `roles/storage.objectAdmin` — full CRUD (data engineers managing the bucket)
  - `roles/storage.admin` — bucket management (infrastructure team only)
- Never use `allUsers` or `allAuthenticatedUsers` on data buckets

### Data Classification Labels

Apply labels to every bucket indicating data sensitivity:

```
data-classification: public | internal | confidential | restricted
data-owner: team-name
retention-days: 30 | 90 | 365 | 2555
environment: dev | staging | prod
cost-center: department-code
```

---

## Dataflow (Apache Beam)

### Pipeline Patterns

Use Apache Beam's Python SDK (preferred) or Java SDK. Follow these patterns:

```python
# Standard pipeline structure
import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions

def run():
    options = PipelineOptions([
        '--runner=DataflowRunner',
        '--project=PROJECT_ID',
        '--region=REGION',
        '--temp_location=gs://BUCKET/temp/',
        '--staging_location=gs://BUCKET/staging/',
        '--save_main_session',  # Required for pickling
    ])

    with beam.Pipeline(options=options) as p:
        (
            p
            | 'Read' >> beam.io.ReadFromBigQuery(
                query='SELECT * FROM dataset.table WHERE date = @date',
                use_standard_sql=True
            )
            | 'Transform' >> beam.ParDo(TransformFn())
            | 'Write' >> beam.io.WriteToBigQuery(
                'project:dataset.output_table',
                write_disposition=beam.io.BigQueryDisposition.WRITE_TRUNCATE,
                create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED,
                schema='field1:STRING,field2:INTEGER'
            )
        )
```

### Windowing Strategies

Choose windowing based on use case:
- **Fixed windows**: Regular intervals (1 min, 1 hour) — use for periodic aggregations
- **Sliding windows**: Overlapping intervals — use for moving averages, trend detection
- **Session windows**: Gap-based grouping — use for user session analysis
- **Global window**: Default for batch — use `Combine.globally()` for full-dataset aggregations

Always set allowed lateness and accumulation mode for streaming pipelines:

```python
windowed = (
    events
    | beam.WindowInto(
        beam.window.FixedWindows(60),  # 1-minute windows
        trigger=beam.trigger.AfterWatermark(
            early=beam.trigger.AfterProcessingTime(10),
            late=beam.trigger.AfterCount(1)
        ),
        accumulation_mode=beam.trigger.AccumulationMode.ACCUMULATING,
        allowed_lateness=beam.utils.timestamp.Duration(seconds=3600)
    )
)
```

### Autoscaling

- Set `--autoscaling_algorithm=THROUGHPUT_BASED` (default for streaming)
- Set `--max_num_workers` to cap costs — never leave unlimited
- Set `--num_workers` for initial parallelism (batch jobs)
- Use `--machine_type=n1-standard-4` as default; scale up for memory-intensive transforms
- For streaming, set `--update` to update in-place without data loss

### Dead Letter Patterns

Always implement dead letter queues for streaming pipelines:

```python
results = (
    records
    | 'Parse' >> beam.ParDo(ParseRecordFn()).with_outputs('dead_letter', main='parsed')
)

# Main output continues to processing
results.parsed | 'Process' >> beam.ParDo(ProcessFn())

# Dead letters go to a separate table for investigation
results.dead_letter | 'WriteDLQ' >> beam.io.WriteToBigQuery(
    'project:dataset.dead_letter_table',
    write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND
)
```

---

## Cloud Composer (Airflow)

### DAG Design

- One DAG per logical data pipeline — do not overload a single DAG with unrelated tasks
- Use `schedule_interval` with cron expressions, not `timedelta` (clearer intent)
- Set `catchup=False` unless historical backfill is explicitly required
- Set `max_active_runs=1` for pipelines that should not overlap
- Set meaningful `default_args` with retries, retry_delay, and email alerts

### Task Operator Selection

Prefer native GCP operators over Bash/Python operators calling CLI:

| Task | Preferred Operator | Avoid |
|------|--------------------|-------|
| BigQuery query | `BigQueryInsertJobOperator` | `BashOperator` with `bq query` |
| BigQuery data transfer | `BigQueryInsertJobOperator` (COPY) | `GCSToBigQueryOperator` for simple loads |
| GCS file operations | `GCSToGCSOperator` | `BashOperator` with `gsutil` |
| Dataflow job | `DataflowStartFlexTemplateOperator` | `BashOperator` with `gcloud dataflow` |
| Pub/Sub publish | `PubSubPublishMessageOperator` | Python with `google-cloud-pubsub` |
| Cloud Function trigger | `CloudFunctionInvokeFunctionOperator` | HTTP requests via `SimpleHttpOperator` |

### Sensor Patterns

- Use sensors sparingly — they consume worker slots while waiting
- Prefer `mode='reschedule'` over `mode='poke'` (frees the worker slot between checks)
- Set `timeout` on all sensors (default 7 days is almost never correct)
- Use `BigQueryTableExistenceSensor` or `GCSObjectExistenceSensor` for data dependency checks

### Variable and Connection Management

- Store connections in Airflow connections (via UI or Terraform), never in code
- Store small config values in Airflow variables, not environment variables
- For secrets, use the Secret Manager backend:
  `AIRFLOW__SECRETS__BACKEND=airflow.providers.google.cloud.secrets.secret_manager.CloudSecretManagerBackend`
- Never commit connection strings, passwords, or keys in DAG files

---

## Vertex AI

### Experiment Tracking

- Create one Vertex AI Experiment per model development initiative
- Log all hyperparameters, metrics, and artifacts using the Vertex AI SDK
- Tag experiments with metadata: `model_type`, `dataset_version`, `owner`
- Compare runs programmatically before promoting to model registry

```python
from google.cloud import aiplatform

aiplatform.init(
    project='PROJECT_ID',
    location='REGION',
    experiment='experiment-name'
)

with aiplatform.start_run('run-001') as run:
    run.log_params({'learning_rate': 0.01, 'epochs': 100})
    run.log_metrics({'accuracy': 0.95, 'f1_score': 0.92})
    run.log_model(model, artifact_uri='gs://bucket/models/run-001/')
```

### Model Registry

- Register all production models in the Vertex AI Model Registry
- Use model versioning — never overwrite a deployed model
- Tag models with: `model_type`, `training_dataset`, `owner`, `approval_status`
- Require approval metadata before endpoint deployment
- Track model lineage: training data -> experiment run -> registered model -> endpoint

### Feature Store

- Use Vertex AI Feature Store for features shared across models
- Define feature groups by entity type (customer, product, transaction)
- Set feature monitoring for drift detection on high-importance features
- Use online serving for low-latency inference, batch serving for training data generation
- Document feature definitions, owners, and freshness requirements

### Pipeline Components

Use Vertex AI Pipelines (Kubeflow Pipelines v2) for ML workflows:

- One pipeline per model lifecycle (training, evaluation, deployment)
- Use `@component` decorator for lightweight Python components
- Use pre-built Google Cloud Pipeline Components where available
- Store pipeline artifacts in GCS, metadata in Vertex ML Metadata
- Schedule pipelines via Cloud Scheduler triggering Cloud Functions

---

## Pub/Sub

### Topic and Subscription Naming

Convention: `{project}-{env}-{domain}-{event}-{version}`

Examples:
- Topic: `myproject-prod-orders-created-v1`
- Subscription: `myproject-prod-orders-created-v1-analytics-sub`
- Dead letter topic: `myproject-prod-orders-created-v1-dlq`

Rules:
- Include version in topic names to support schema evolution
- Subscription names include the consumer identity (who is reading)
- Always create a dead letter topic for each primary topic

### Message Ordering

- Enable message ordering on the topic when event sequence matters
- Use ordering keys based on entity ID (e.g., `customer_id`, `order_id`)
- Ordering adds latency — only enable when required
- Ordered messages are guaranteed within a single region

### Exactly-Once Processing

- Use Pub/Sub's exactly-once delivery (subscriber-side deduplication)
- Enable `exactly_once_delivery` on the subscription
- Design consumers to be idempotent regardless — exactly-once is not a guarantee across retries
- Use unique message IDs for deduplication

### Dead Letter Topics

- Set `max_delivery_attempts` (default 5) on subscriptions
- Route failed messages to a dead letter topic automatically
- Monitor dead letter topic message count — alert when non-zero
- Build a reprocessing workflow to replay dead letters after fixing consumer bugs

---

## Cloud Functions / Cloud Run

### Serverless Data Processing Patterns

**Cloud Functions** (event-driven, short-lived):
- File arrival triggers: GCS `finalize` event -> Cloud Function -> BigQuery load
- Pub/Sub triggers: message arrival -> Cloud Function -> transform + write
- Scheduled triggers: Cloud Scheduler -> Cloud Function -> data quality check
- Max execution time: 9 minutes (1st gen) / 60 minutes (2nd gen)

**Cloud Run** (HTTP/container-based, longer-lived):
- API endpoints for data services
- Long-running batch processing (up to 60 min for jobs, 1 hour for services)
- Container-based workloads with custom dependencies
- Cloud Run Jobs for batch processing without serving traffic

### Cold Start Mitigation

- **Cloud Functions 2nd gen**: Set `min_instances=1` for latency-sensitive functions
- **Cloud Run**: Set `min-instances=1` and configure CPU to be always-allocated
- Keep container images small — use distroless or slim base images
- Lazy-load heavy libraries; initialize clients outside the handler function
- Use global scope for reusable connections (e.g., BigQuery client, Pub/Sub publisher)

```python
# Good: initialize outside handler, reuse across invocations
from google.cloud import bigquery
client = bigquery.Client()

def handle_event(event, context):
    # client is already initialized
    client.query('SELECT ...').result()
```

---

## IAM and Security

### Service Account Management

- Create one service account per service/workload — never share across services
- Name convention: `sa-{service}-{env}@{project}.iam.gserviceaccount.com`
- Apply least-privilege: use predefined roles, not primitive roles (Editor/Owner)
- Never grant `roles/editor` or `roles/owner` to service accounts
- Disable unused service accounts after 90 days; delete after 180 days
- Audit service account key usage — prefer Workload Identity over keys

### Workload Identity Federation

For CI/CD pipelines (GitHub Actions, GitLab CI, etc.), use Workload Identity Federation
instead of service account keys:

```yaml
# GitHub Actions example
- id: auth
  uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: 'projects/PROJECT_NUM/locations/global/workloadIdentityPools/POOL/providers/PROVIDER'
    service_account: 'sa-cicd-deploy@project.iam.gserviceaccount.com'
```

Benefits: no long-lived keys to rotate, automatic token expiration, audit trail in Cloud Logging.

### VPC Service Controls

Use VPC Service Controls for data perimeter protection on sensitive projects:

- Create a service perimeter around projects containing sensitive data
- Restrict BigQuery, Cloud Storage, and Pub/Sub within the perimeter
- Define access levels for authorized networks and identities
- Use ingress/egress rules for controlled cross-perimeter access
- Test with dry-run mode before enforcing

---

## Cost Management

### Labels Strategy

Apply labels consistently to all GCP resources:

```
environment: dev | staging | prod
team: data-engineering | analytics | ml
cost-center: CC-1234
project-code: PRJ-456
data-classification: internal | confidential | restricted
managed-by: terraform | manual | composer
```

Rules:
- Labels are mandatory on all resources — enforce via organization policies
- Use labels for cost attribution in billing exports
- Automate label compliance checks in CI/CD

### Budget Alerts

- Set budget alerts at project level: 50%, 80%, 100%, 120% thresholds
- Route alerts to Pub/Sub for automated responses (e.g., disable non-critical jobs at 120%)
- Set per-service budgets for BigQuery, Compute, and Storage separately
- Review billing exports in BigQuery monthly — `gcp_billing_export_v1`

### Committed Use Discounts

**Decision framework**:
- Compute CUDs: commit when steady-state usage is predictable (>60% utilization)
- BigQuery editions: commit when monthly BigQuery spend exceeds $10K consistently
- Cloud Storage: no CUDs — use lifecycle policies and storage class transitions instead
- Start with 1-year commitments; move to 3-year only after pattern is established

### BigQuery Cost Model Decision

| Factor | On-Demand | Editions (Flat-Rate) |
|--------|-----------|---------------------|
| Monthly spend | < $10K | > $10K |
| Query patterns | Unpredictable, bursty | Steady, predictable |
| Cost control | Per-query limits | Fixed monthly cost |
| Concurrency | Lower priority | Guaranteed slots |
| Use case | Exploration, dev | Production pipelines |

---

## MCP Server Ecosystem Note

GCP's MCP server ecosystem is maturing rapidly. As of March 2026:

**Official managed MCP servers**: BigQuery, Cloud Run, Compute Engine, GKE, Cloud SQL,
AlloyDB, Spanner, Firestore, Bigtable, Cloud Logging, Cloud Monitoring, Resource Manager.

**Community/CLI MCP servers**: gcloud-mcp (wraps entire gcloud CLI), storage-mcp,
observability-mcp, community BigQuery servers.

**No MCP server yet**: Dataflow, Cloud Composer, Pub/Sub (planned), Cloud Functions,
Vertex AI, Secret Manager, Cloud Scheduler, Cloud Tasks.

For services without MCP servers, use the `gcloud-mcp` server or Bash tool with `gcloud` CLI.
See `mcp-config.json` in this directory for the full configuration template.
