---
description: Client enterprise architecture patterns and constraints. Populated during /client-onboard or manually by the lead engineer. These patterns constrain all architecture decisions and code generation.
globs: "*"
---

# Client Enterprise Architecture Patterns

This file defines the client's enterprise architecture constraints. All architecture decisions, technology selections, and implementation patterns must respect these constraints.

**Source:** <!-- Link to client EA documentation or "captured during /client-onboard" -->
**Last Updated:** <!-- YYYY-MM-DD -->

---

## Approved Technology Stack

<!-- FILL: List all technologies approved by the client's EA team. Only these may be used unless an exception is approved via ADR. -->

### Languages & Runtimes
- <!-- e.g., Python 3.11+, Java 17, TypeScript 5.x -->

### Frameworks
- <!-- e.g., FastAPI, Spring Boot, dbt, Airflow -->

### Databases & Storage
- <!-- e.g., BigQuery, Cloud SQL (PostgreSQL), GCS -->

### Cloud Services
- <!-- e.g., Cloud Composer, Dataflow, Cloud Functions, Pub/Sub -->

### Prohibited Technologies
- <!-- e.g., No self-hosted Kafka (use Pub/Sub), No MongoDB (use Cloud SQL), No Lambda (AWS not approved) -->

---

## Architecture Patterns

<!-- FILL: Document the client's approved architecture patterns. These constrain /design phase proposals. -->

### Data Architecture
- <!-- e.g., Medallion architecture (Bronze → Silver → Gold) -->
- <!-- e.g., Event-driven with Pub/Sub for real-time, batch with Composer for daily -->
- <!-- e.g., Centralized data lake in GCS, curated datasets in BigQuery -->

### Application Architecture
- <!-- e.g., Microservices on Cloud Run, API Gateway for external -->
- <!-- e.g., Monorepo with shared libraries, polyrepo for independent services -->

### Integration Patterns
- <!-- e.g., REST APIs for synchronous, Pub/Sub for async, Cloud Tasks for deferred -->
- <!-- e.g., API versioning via URL path (/v1/, /v2/) -->

---

## Naming Conventions

<!-- FILL: Client's resource naming standards. Enforced during /build phase. -->

### Cloud Resources
- **Projects:** <!-- e.g., {org}-{team}-{env} → acme-data-prod -->
- **Datasets:** <!-- e.g., {domain}_{layer} → sales_raw, sales_curated -->
- **Tables:** <!-- e.g., {prefix}_{entity} → fct_orders, dim_customers -->
- **Buckets:** <!-- e.g., {project}-{purpose}-{env} → acme-data-landing-prod -->
- **Service Accounts:** <!-- e.g., sa-{service}-{env}@{project}.iam.gserviceaccount.com -->

### Code
- **Modules:** <!-- e.g., snake_case, domain-prefixed -->
- **Classes:** <!-- e.g., PascalCase -->
- **Functions:** <!-- e.g., snake_case, verb_noun -->
- **Constants:** <!-- e.g., UPPER_SNAKE_CASE -->

---

## Security Requirements

<!-- FILL: Client's security posture. Enforced by managed-settings.json and security rule. -->

### Authentication & Authorization
- <!-- e.g., OAuth 2.0 with client's IdP, service accounts for service-to-service -->
- <!-- e.g., IAM roles: viewer for read, editor for dev, owner restricted to platform team -->

### Data Classification
- <!-- e.g., Public, Internal, Confidential, Restricted -->
- <!-- e.g., Confidential data: encrypted at rest (CMEK), no export to non-prod without masking -->

### Encryption
- <!-- e.g., AES-256 at rest (Google-managed or CMEK), TLS 1.3 in transit -->
- <!-- e.g., CMEK required for all Restricted data -->

### Network Security
- <!-- e.g., VPC Service Controls perimeter for data projects -->
- <!-- e.g., Private Google Access, no public IPs on compute resources -->

---

## Data Governance

<!-- FILL: Client's data governance policies. Enforced during /discovery and /build phases. -->

### PII Handling
- <!-- e.g., PII columns must be tagged in metadata, masked in non-prod environments -->
- <!-- e.g., No PII in logs, error messages, or exception traces -->

### Data Retention
- <!-- e.g., Raw data: 90 days in GCS, 1 year in Coldline -->
- <!-- e.g., Curated data: 7 years in BigQuery, partitioned by date -->

### Data Quality
- <!-- e.g., All pipelines must have Great Expectations suites -->
- <!-- e.g., Data quality scores published to central dashboard -->

### Lineage & Cataloging
- <!-- e.g., All datasets registered in Data Catalog -->
- <!-- e.g., Column-level lineage required for Restricted data -->

---

## Deployment Patterns

<!-- FILL: Client's CI/CD and deployment standards. Enforced during /deploy phase. -->

### Environments
- <!-- e.g., dev → staging → prod, with promotion gates -->
- <!-- e.g., Feature branches deploy to dev automatically -->

### CI/CD Pipeline
- <!-- e.g., GitHub Actions with Cloud Build for deployment -->
- <!-- e.g., Required checks: lint, type check, unit tests, security scan -->

### Deployment Strategy
- <!-- e.g., Blue-green for APIs, rolling update for pipelines -->
- <!-- e.g., Canary deployments for ML model serving -->

### Infrastructure as Code
- <!-- e.g., Terraform with remote state in GCS, module registry in Artifact Registry -->
- <!-- e.g., No manual resource creation — everything via IaC -->

---

## Exceptions Process

When a requirement conflicts with these EA patterns or a technology not on the approved list is needed:

1. Document the need in an Architecture Decision Record (ADR)
2. Present alternatives that stay within approved patterns
3. Get written approval from client EA team
4. Update this file with the approved exception
5. Link the ADR in the exception entry

### Active Exceptions
<!-- List any approved exceptions with ADR links -->
- None
