---
name: build
description: SDLC Phase 3 — Implementation orchestrator that scaffolds, builds, and enforces coding standards per Design artifacts.
version: 1.0.0
---

# Build Phase Orchestrator

Guides implementation of the solution defined in Design artifacts. Enforces coding standards,
security rules, and platform-native patterns throughout the build.

> **Prerequisite**: Design phase completed. Requires solution architecture doc, schema DDL,
> pipeline design, and API design.

---

## Invocation

```
/build
```

The orchestrator begins by ingesting Design artifacts:

1. Read the Solution Architecture Document
2. Read the Database Schema (DDL)
3. Read the Pipeline Design
4. Read the API Design
5. Read the IaC Plan
6. Read ADRs for technology decisions
7. Read Jira Stories for the Build phase

---

## Implementation Priority

Build follows a strict bottom-up order. Each layer must be solid before the next begins.

```
1. Data Layer         — schemas, migrations, seed data, data access
2. Business Logic     — services, transformations, validations, domain models
3. API / Interface    — endpoints, contracts, serialization
4. Orchestration      — pipelines, schedulers, workflow coordination
5. Infrastructure     — IaC, CI/CD, environment configuration
```

Within each layer, implement in order of dependency (no forward references).

---

## Scaffolding

Before writing application code, scaffold the project structure:

```
project-root/
├── src/
│   ├── models/          # Data models, schemas, types
│   ├── services/        # Business logic
│   ├── api/             # API endpoints, route handlers
│   ├── pipelines/       # ETL/ELT pipeline code
│   ├── utils/           # Shared utilities
│   └── config/          # Configuration management
├── tests/
│   ├── unit/            # Unit tests (mirror src/ structure)
│   ├── integration/     # Integration tests
│   └── conftest.py      # Shared fixtures
├── infra/               # IaC (Terraform/Pulumi/CDK)
├── migrations/          # Database migrations
├── docs/                # Project documentation
├── pyproject.toml       # Project config (uv, black, ruff, mypy, pytest)
├── .pre-commit-config.yaml
└── .env.example         # Environment variable template
```

Adapt structure to match Design artifacts (e.g., if no API, omit `api/`). Use the client's
established conventions from Layer 2 if they differ from this default.

Setup tooling:
- `uv init` + `pyproject.toml` with all tool configs (black, ruff, mypy, pytest)
- `.pre-commit-config.yaml` with hooks for black, ruff, mypy
- `.env.example` with all required environment variables (no secrets)

---

## Sub-Agents

The Build orchestrator spawns specialized sub-agents at key moments.

### framework-verifier

**When**: Before writing any framework-specific code (FastAPI routes, dbt models, Terraform
resources, etc.).

**What it does**: Uses WebSearch and WebFetch to verify current API signatures, best practices,
and breaking changes. Produces a verification report.

**Trigger rule**: If the code uses a framework or library not previously verified in this
project, invoke `framework-verifier` before writing.

### test-writer

**When**: After implementing each significant module or service.

**What it does**: Writes pytest test cases following TDD principles. Produces unit tests
with fixtures, parametrization, and edge case coverage.

**Trigger rule**: No module ships without tests. The Build orchestrator blocks progress to
the next module until tests exist and pass for the current one.

### api-integrator

**When**: When implementing integrations with external APIs or services.

**What it does**: Verifies API contracts, writes integration code with proper error handling,
retry logic, and circuit breakers. Tests against API documentation.

**Trigger rule**: Any code that calls an external HTTP endpoint or SDK must go through
`api-integrator` verification.

---

## Coding Standards Enforcement

Every significant code change must pass quality gates before moving forward.

### Automated Checks

Run `/format-and-lint` after each significant change:

1. **black** — Code formatting (line length 100)
2. **ruff** — Linting with auto-fix
3. **mypy** — Type checking (strict mode, no exceptions)

### Manual Review Points

The orchestrator pauses and reviews with the developer at these points:

- After Data Layer is complete
- After Business Logic is complete
- After API layer is complete
- Before any IaC is applied

### Security Rules

Enforce throughout the build:

- No secrets in code (use environment variables)
- No hardcoded connection strings
- Input validation on all external inputs
- SQL parameterization (no string concatenation)
- Dependency pinning (exact versions in pyproject.toml)
- Least-privilege IAM policies in IaC

### Platform-Native Patterns

Enforce the client's platform patterns from Layer 2:

- Use platform-native services per Design ADRs
- Follow platform SDK conventions (not raw HTTP when SDK exists)
- Use platform-native auth (IAM roles, service accounts, managed identity)
- Use platform-native secrets management

---

## Implementation Workflow Per Module

For each module (service, pipeline, API endpoint):

```
1. Read Design spec for this module
2. framework-verifier → verify APIs/patterns if needed
3. Write implementation code
4. /format-and-lint → fix formatting and type issues
5. test-writer → generate test suite
6. /test-runner → run tests, verify passing
7. Update Jira Story → link code, add comments
8. Move to next module
```

Do not proceed to the next module until steps 1-7 are complete for the current one.

---

## Progress Tracking

Track progress against Jira Stories throughout the build:

| Action | When |
|---|---|
| Transition Story to "In Progress" | When starting implementation |
| Add comment with approach | After reviewing Design spec for the Story |
| Add comment with test results | After tests pass |
| Transition Story to "In Review" | When module is complete and tested |
| Link related Stories | When dependencies between Stories are discovered |

If Jira MCP is not available, maintain a local progress log:

```markdown
# Build Progress: [Project Name]

| Story | Status | Module | Tests | Notes |
|---|---|---|---|---|
| [PROJ-123] | Done | src/services/transform.py | 12/12 passing | |
| [PROJ-124] | In Progress | src/api/routes.py | 0/0 | Blocked: awaiting API key |
```

---

## Error Handling Standards

All code must follow these error handling patterns:

```python
# Custom exceptions per domain
class DataValidationError(Exception):
    """Raised when input data fails validation."""
    pass

# Structured error responses in APIs
# Retry with exponential backoff for transient failures
# Dead-letter handling for pipeline failures
# Logging at appropriate levels (ERROR for failures, WARNING for retries, INFO for operations)
```

---

## Output Checklist

Before completing Build, verify:

- [ ] All modules implemented per Design specs
- [ ] All code passes `/format-and-lint` (black + ruff + mypy)
- [ ] All modules have test suites (unit tests at minimum)
- [ ] All tests pass via `/test-runner`
- [ ] No secrets in code (env vars used)
- [ ] Database migrations are idempotent and reversible
- [ ] IaC is written and plan-validated (terraform plan / pulumi preview)
- [ ] `.env.example` is complete
- [ ] All Jira Stories updated with progress

---

## Handoff to Test

Build is complete when:

1. All Design-specified modules are implemented
2. All code passes format, lint, and type checks
3. All unit tests pass
4. Jira Stories are updated
5. Developer confirms implementation is complete

Next phase: `/test` — comprehensive testing beyond unit tests (data quality, schema validation,
security scanning, integration tests).

---

## Principles

- **Bottom-up builds** — Data layer first, orchestration last. No forward references.
- **Verify before writing** — Framework APIs are checked via `framework-verifier` before implementation
- **Test with every module** — No module ships without passing tests
- **Format on every change** — `/format-and-lint` runs after every significant edit
- **No secrets in code** — Environment variables for all configuration
- **One module at a time** — Complete, test, and verify each module before starting the next
- **Progress is visible** — Jira Stories reflect actual implementation state
