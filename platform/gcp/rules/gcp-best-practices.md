---
description: GCP best practices enforced in all sessions on Google Cloud Platform engagements. These rules ensure consistent, secure, and cost-effective use of GCP services.
globs: *
---

# GCP Best Practices

## Project Structure

- Use separate GCP projects for each environment: `{org}-{app}-dev`, `{org}-{app}-staging`, `{org}-{app}-prod`
- Never run production and development workloads in the same project
- Use a Shared VPC host project for networking — spoke projects attach as service projects
- Create a dedicated `{org}-shared-services` project for shared infrastructure (Artifact Registry, Secret Manager, monitoring)
- Use folder-level organization: `Organization > Department > Team > Environment`
- Enable Organization Policy constraints at the org/folder level, not per-project
- Create a `{org}-billing-exports` project for centralized cost analysis

## Resource Naming Convention

All resources follow: `{project}-{env}-{service}-{resource}-{qualifier}`

Examples:
- BigQuery dataset: `myapp_prod_orders_curated`
- GCS bucket: `myapp-prod-data-lake-us-central1`
- Service account: `sa-etl-pipeline-prod@myapp-prod.iam.gserviceaccount.com`
- Cloud Run service: `myapp-prod-api-orders`
- Pub/Sub topic: `myapp-prod-orders-created-v1`
- Dataflow job: `myapp-prod-orders-enrichment`
- VPC network: `myapp-prod-vpc`
- Subnet: `myapp-prod-subnet-us-central1`

Rules:
- Use hyphens for resource names (GCS buckets, Cloud Run, Compute)
- Use underscores for BigQuery datasets and tables (BigQuery requirement)
- Always include environment identifier
- Keep names under 63 characters (GCP limit for most resources)
- Use lowercase exclusively — GCP resources are case-sensitive

## IAM

### Forbidden Patterns

- Never use `allUsers` or `allAuthenticatedUsers` bindings on any resource — no exceptions without explicit security review and documented business justification
- Never grant `roles/editor` or `roles/owner` to service accounts — use specific predefined roles
- Never grant `roles/bigquery.admin` to service accounts — use `roles/bigquery.dataEditor` and `roles/bigquery.jobUser`
- Never create user-managed service account keys unless Workload Identity Federation is technically impossible — document the exception
- Never grant IAM roles directly to individual user accounts — use Google Groups

### Required Patterns

- One service account per workload/service — never share service accounts across services
- Grant roles at the narrowest scope possible: resource > dataset > project > folder > org
- Use Google Groups for team access — grant roles to groups, not individuals
- Review IAM policies quarterly — remove stale bindings
- Use IAM Recommender to identify over-provisioned roles
- Enable IAM audit logs on all projects (admin activity is logged by default; enable data access logs for sensitive projects)
- Use IAM Conditions for time-bound or attribute-based access when appropriate

### Service Account Naming

Format: `sa-{workload}-{env}@{project}.iam.gserviceaccount.com`

Examples:
- `sa-etl-pipeline-prod@myapp-prod.iam.gserviceaccount.com`
- `sa-api-backend-dev@myapp-dev.iam.gserviceaccount.com`
- `sa-cicd-deploy-prod@myapp-shared.iam.gserviceaccount.com`

## BigQuery

### Mandatory Practices

- Always specify dataset location at creation time — it cannot be changed later and defaults may not match your region requirements
- Partition every table over 1 GB — prefer time-based partitioning on a date/timestamp column
- Cluster tables by columns commonly used in WHERE and JOIN clauses — up to 4 columns, highest selectivity first
- Set `require_partition_filter = true` on all partitioned tables over 10 GB to prevent accidental full scans
- Never use `SELECT *` in production queries — always specify required columns
- Always use Standard SQL (`#standardSQL` or `use_legacy_sql=false`) — legacy SQL is deprecated
- Set `maximum_bytes_billed` on all scheduled queries and application queries to prevent runaway costs
- Use authorized datasets for cross-project data sharing — more maintainable than individual view authorization
- Add column descriptions and table descriptions to all curated/analytics tables

### Query Cost Control

- Use `--dry_run` flag before executing expensive ad-hoc queries to estimate cost
- Materialize intermediate results that are queried more than once per day
- Use `INFORMATION_SCHEMA` for metadata operations instead of scanning tables
- Prefer `MERGE` statements over DELETE + INSERT for upserts
- Use `TABLESAMPLE` for development queries on large tables
- Set up BigQuery custom cost controls: per-user daily query limits and project-level daily limits
- Monitor query costs via `INFORMATION_SCHEMA.JOBS_BY_PROJECT` — flag queries exceeding $10

### Schema Design

- Use `STRUCT` and `ARRAY` types for nested data — avoid unnecessary flattening that creates wide, sparse tables
- Use `STRING` for IDs (not `INT64`) — supports UUIDs, composite keys, and avoids implicit casting issues
- Use `TIMESTAMP` for point-in-time events, `DATE` for calendar dates, `DATETIME` for wall-clock times without timezone
- Use `NUMERIC` or `BIGNUMERIC` for financial calculations — never use `FLOAT64` for money
- Add `_loaded_at TIMESTAMP` and `_source STRING` metadata columns to all raw tables for lineage tracking

## Cloud Storage

### Mandatory Practices

- Enable uniform bucket-level access on all buckets — do not use fine-grained ACLs
- Apply lifecycle policies to every bucket — no bucket should exist without a retention/transition policy
- No public buckets without explicit written approval from the security team and a documented business justification
- Enable object versioning on all production data buckets
- Apply data classification labels (`data-classification: public | internal | confidential | restricted`) to every bucket
- Enable access logs on buckets containing confidential or restricted data
- Use customer-managed encryption keys (CMEK) for restricted data

### Storage Class Selection

| Use Case | Storage Class | Minimum Duration |
|----------|--------------|-----------------|
| Frequently accessed data | Standard | None |
| Accessed < 1x/month | Nearline | 30 days |
| Accessed < 1x/quarter | Coldline | 90 days |
| Accessed < 1x/year (compliance, archive) | Archive | 365 days |

Configure lifecycle rules to automatically transition objects between classes:
- Standard -> Nearline after 30 days
- Nearline -> Coldline after 90 days
- Coldline -> Archive after 365 days
- Delete after retention period expires

### Object Organization

Use a consistent path structure within buckets:

```
gs://bucket/raw/{source}/{table}/{year}/{month}/{day}/{file}
gs://bucket/staging/{pipeline}/{table}/{year}/{month}/{day}/{file}
gs://bucket/curated/{domain}/{table}/{year}/{month}/{day}/{file}
gs://bucket/temp/{job_id}/{timestamp}/{file}  # Auto-delete via lifecycle
```

- Use Hive-style partitioning (`year=2026/month=03/day=01/`) for BigQuery external tables
- Include file format in path or filename for clarity (`data.parquet`, `events.avro`)
- Prefix temp files with job/process IDs for easy cleanup

## Networking

### VPC Service Controls

- Enable VPC Service Controls on all projects containing confidential or restricted data
- Define a service perimeter that includes BigQuery, Cloud Storage, Pub/Sub, and any service processing sensitive data
- Use access levels to authorize specific networks, identities, and devices
- Configure ingress/egress rules for controlled cross-perimeter communication
- Always test with dry-run mode before enforcing — VPC-SC violations break applications silently
- Document all access levels and perimeter rules in Terraform

### Private Connectivity

- Enable Private Google Access on all subnets in private VPC networks
- Use Private Service Connect for accessing Google APIs from private networks
- Never expose database instances (Cloud SQL, Spanner, Bigtable) with public IPs in production
- Use Cloud NAT for outbound internet access from private instances — do not assign public IPs
- Use Internal Load Balancers for service-to-service communication within VPC

### Firewall Rules

- Default deny all ingress — explicitly allow only required traffic
- Use firewall rule priorities: deny rules at low priority (1000+), allow rules at higher priority (100-999)
- Tag-based firewall rules for service-to-service communication
- Log all denied traffic for security monitoring
- Review firewall rules quarterly — remove unused rules

## Logging

### Cloud Logging

- Use structured logging (JSON format) for all application logs — never use unstructured text in production
- Include these fields in every log entry: `severity`, `timestamp`, `message`, `service_name`, `trace_id`
- Use Log Router sinks for long-term retention:
  - Route audit logs to a dedicated BigQuery dataset for analysis
  - Route application logs to Cloud Storage for archival (Coldline after 30 days)
  - Route security logs to a SIEM/Security Operations sink
- Set log retention periods: 30 days default, 90 days for application logs, 365+ days for audit logs
- Enable Data Access audit logs on projects with sensitive data (Admin Activity logs are enabled by default)
- Never log sensitive data: PII, credentials, tokens, or financial data — use structured logging with explicit field selection

### Log-Based Metrics

- Create log-based metrics for critical error patterns
- Alert on metric thresholds: error rate > 1%, latency p99 > threshold
- Use Cloud Monitoring dashboards to visualize log-based metrics alongside infrastructure metrics

## Terraform / Infrastructure as Code

### Mandatory Practices

- All infrastructure changes go through Terraform — no manual console changes in staging or production
- Store Terraform state in a GCS bucket with object versioning enabled
- Enable state locking using GCS backend (built-in with GCS)
- Always run `terraform plan` and review output before `terraform apply` — enforce this in CI/CD
- Use `-target` only for debugging, never in CI/CD pipelines

### Module Design

- Use modules for reusable components: VPC, GKE cluster, BigQuery dataset, Cloud Run service
- Pin module versions — never use `ref=main` in production
- Use the official Google Terraform modules where available: `terraform-google-modules/*`
- Keep modules focused: one module per logical resource group
- Document module inputs, outputs, and usage examples

### State Management

- One state file per environment per project — never mix dev and prod state
- Use workspaces only for simple environment separation; prefer separate backends for complex setups
- Backend configuration:

```hcl
terraform {
  backend "gcs" {
    bucket = "myapp-terraform-state"
    prefix = "prod/data-platform"
  }
}
```

- Protect the state bucket: enable versioning, restrict access to CI/CD service account and infrastructure team, enable CMEK encryption

### Code Organization

```
infrastructure/
  modules/           # Reusable modules
    bigquery/
    cloud-run/
    vpc/
    iam/
  environments/
    dev/
      main.tf
      variables.tf
      terraform.tfvars
    staging/
    prod/
  global/            # Org-level resources (policies, shared VPC)
```

## Secret Manager

### Mandatory Practices

- Never hardcode secrets in source code, configuration files, environment variables, or Terraform state
- Store all secrets in Google Secret Manager — no exceptions
- Use IAM for access control: grant `roles/secretmanager.secretAccessor` only to service accounts that need specific secrets
- Grant access at the secret level, not the project level
- Enable automatic rotation for service account keys and API credentials
- Set rotation reminders: 90 days for most secrets, 30 days for high-privilege credentials
- Use secret version aliases (`latest`, `previous`) for seamless rotation
- Enable audit logging on all secret access operations
- Reference secrets in Cloud Run/Functions via secret environment variables or mounted volumes — never fetch and log

### Secret Naming

Convention: `{env}-{service}-{secret-type}`

Examples:
- `prod-api-database-password`
- `prod-etl-service-account-key`
- `staging-analytics-api-key`

## Data Residency

### Region Selection Decision Framework

| Requirement | Region Strategy | Examples |
|-------------|----------------|---------|
| Lowest latency, single geography | Single region | `us-central1`, `europe-west1` |
| High availability within geography | Dual-region | `us` (Iowa + S. Carolina), `eu` (Belgium + Netherlands) |
| Maximum availability, global users | Multi-region | `US`, `EU`, `ASIA` |
| Data sovereignty / regulatory | Single region in jurisdiction | `europe-west1` (Belgium), `australia-southeast1` (Sydney) |
| Cost optimization (no redundancy need) | Single region, cheapest tier | `us-central1`, `us-east1` |

### Rules

- Document the data residency decision in the project design doc with business justification
- Set dataset/bucket location at creation time — it cannot be changed later
- BigQuery datasets and Cloud Storage buckets must be co-located for optimal performance and to avoid cross-region data transfer charges
- Never store EU personal data outside EU regions — enforce via Organization Policy constraints
- Use VPC Service Controls to prevent data exfiltration to unauthorized regions
- Monitor cross-region data transfer in billing — alert on unexpected charges
- For multi-region deployments, replicate processing logic (Dataflow, Cloud Run) to each region — do not transfer data cross-region for processing

### Cross-Region Considerations

- BigQuery cross-region queries incur data transfer charges — avoid them
- Cloud Storage transfer between regions is billed per GB — use Transfer Service for bulk migrations
- Pub/Sub messages stay within the region of the topic — plan topic placement accordingly
- Vertex AI training and prediction endpoints must be in the same region as training data
