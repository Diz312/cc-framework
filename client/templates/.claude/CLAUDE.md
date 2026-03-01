# Project: <!-- PROJECT_NAME -->

**Client:** <!-- CLIENT_NAME -->
**Engagement Type:** <!-- green-field | brown-field -->
**Start Date:** <!-- YYYY-MM-DD -->
**Lead Engineer:** <!-- NAME -->

---

## Stack & Technology

<!-- Filled during /client-onboard or manually from client EA docs -->

- **Language:** <!-- e.g., Python 3.12 -->
- **Runtime:** uv + pyproject.toml
- **Framework:** <!-- e.g., FastAPI, Flask, dbt, Airflow -->
- **Database:** <!-- e.g., BigQuery, PostgreSQL, Snowflake -->
- **Cloud Platform:** <!-- e.g., GCP, AWS, Azure -->
- **Orchestration:** <!-- e.g., Cloud Composer, Airflow, Step Functions -->
- **CI/CD:** <!-- e.g., GitHub Actions, Cloud Build, Jenkins -->
- **IaC:** <!-- e.g., Terraform, Pulumi, CloudFormation -->

---

## Project Structure

<!-- Update as project takes shape -->

```
src/
  pipelines/          # Pipeline DAG definitions
  transformations/    # SQL and Python transformation logic
  models/             # Data models / dbt models
  schemas/            # DDL, migrations
  quality/            # Data quality test definitions
  utils/              # Shared utilities
docs/
  architecture/       # Architecture decisions, data flow diagrams
  runbooks/           # Operational runbooks
  discovery/          # Discovery phase artifacts
  design/             # Design phase artifacts
tests/
  unit/               # Unit tests
  integration/        # Integration tests
```

---

## Client Conventions

<!-- From /client-onboard EA analysis — replace placeholders -->

### Naming Conventions
- **Services:** <!-- e.g., {team}-{service}-{env} -->
- **Databases:** <!-- e.g., {domain}_{layer}_{name} -->
- **APIs:** <!-- e.g., /api/v{n}/{resource} -->
- **Cloud Resources:** <!-- e.g., {project}-{env}-{service}-{resource} -->

### Architecture Patterns
<!-- e.g., Event-driven microservices, Medallion architecture, Hub-and-spoke -->

### Security Requirements
- **Authentication:** <!-- e.g., OAuth 2.0, SAML, API keys -->
- **Data Classification:** <!-- e.g., Public, Internal, Confidential, Restricted -->
- **Encryption:** <!-- e.g., AES-256 at rest, TLS 1.3 in transit -->

---

## SDLC Workflow

- **Jira Project:** <!-- PROJECT_KEY -->
- **Confluence Space:** <!-- SPACE_KEY -->
- **Active Phases:** Discovery, Design, Build, Test, Deploy
- **Branch Strategy:** <!-- e.g., trunk-based, GitFlow, GitHub Flow -->
- **Review Requirements:** <!-- e.g., 1 approval, CODEOWNERS -->

### Phase Artifacts Location
- Discovery: `docs/discovery/`
- Design: `docs/design/`
- Test Reports: `docs/test-reports/`
- Deployment Notes: `docs/deployment/`

---

## Environment Setup

```bash
# Clone and setup
git clone <!-- REPO_URL -->
cd <!-- PROJECT_DIR -->
uv sync

# Configure environment
cp .env.example .env
# Edit .env with your credentials

# Verify setup
uv run pytest
uv run black --check .
uv run ruff check .
uv run mypy .
```

---

## Key Contacts

| Role | Name | Contact |
|------|------|---------|
| Lead Engineer | <!-- NAME --> | <!-- EMAIL --> |
| Client Tech Lead | <!-- NAME --> | <!-- EMAIL --> |
| Product Owner | <!-- NAME --> | <!-- EMAIL --> |

---

## Data Sensitivity

- **Classification Level:** <!-- e.g., Confidential -->
- **PII Present:** <!-- Yes/No — if yes, list categories -->
- **Compliance Frameworks:** <!-- e.g., HIPAA, SOC 2, GDPR -->
- **Data Retention:** <!-- e.g., 7 years -->

**Rules:**
- Never commit client data to version control
- Use anonymized/masked data for development
- Follow `sops/client-data-handling.md` for all data operations

---

## Platform Notes

<!-- Filled by /client-onboard based on platform module selection -->
<!-- e.g., GCP-specific notes, BigQuery dataset structure, service account setup -->
