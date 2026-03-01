---
name: test
description: SDLC Phase 4 — Comprehensive testing, validation, and deployment readiness assessment.
version: 1.0.0
---

# Test Phase Orchestrator

Runs comprehensive testing beyond the unit tests written during Build. Validates data quality,
schema integrity, security posture, SQL best practices, and integration behavior. Produces a
deployment readiness report.

> **Prerequisite**: Build phase completed. All unit tests passing, code formatted and linted.

---

## Invocation

```
/test
```

The orchestrator begins by verifying Build phase completion:

1. Confirm all unit tests pass (`/test-runner`)
2. Confirm code passes `/format-and-lint`
3. Read Design artifacts for expected behavior and acceptance criteria
4. Read Jira Stories to understand what was built

---

## Test Execution Sequence

Tests run in this order. Each category must complete before the next begins.
Failures in earlier categories may block later ones.

```
1. Unit Tests (re-run)          — Baseline confirmation
2. Data Quality Validations     — Source and transformed data correctness
3. Schema Validation            — No breaking changes, evolution safety
4. SQL Best Practices Review    — Query quality and performance
5. Security Vulnerability Scan  — Dependency and code-level security
6. Integration Tests            — Cross-component and external system tests
```

---

## 1. Unit Tests

Re-run the full unit test suite with coverage reporting:

```bash
python ~/.claude/tools/run_tests.py --coverage --verbose
```

**Pass criteria**:
- All tests pass (zero failures)
- Coverage >= 70% overall
- Coverage >= 90% for critical business logic (services/, models/)
- No skipped tests without documented reason

**Output**: Coverage report with per-module breakdown.

---

## 2. Data Quality Validations

Validate data at every stage of the pipeline using Great Expectations, dbt tests, or
equivalent framework per the client's approved stack.

### Source Data Validation

| Check | Description |
|---|---|
| **Schema conformance** | Source data matches expected schema (types, columns) |
| **Completeness** | Required fields are non-null at expected rates |
| **Uniqueness** | Primary key / unique columns have no duplicates |
| **Referential integrity** | Foreign key references resolve |
| **Value ranges** | Numeric and date fields within expected bounds |
| **Freshness** | Data is not stale (last updated within SLA) |

### Transformation Validation

| Check | Description |
|---|---|
| **Row count reconciliation** | Output row count matches expected based on input + logic |
| **Aggregation accuracy** | Sums, counts, averages match manual spot-checks |
| **Business rule compliance** | Derived fields follow documented business rules |
| **Null propagation** | Nulls handled per design (coalesced, filtered, or preserved) |
| **Deduplication** | No unintended duplicate records in output |

### Output Data Validation

| Check | Description |
|---|---|
| **Consumer contract** | Output matches the schema expected by downstream consumers |
| **Timeliness** | Data available within SLA window |
| **Idempotency** | Re-running pipeline produces identical output |

**Output**: Data quality report with pass/fail per check, sample failures.

---

## 3. Schema Validation

Verify that schema changes do not break existing consumers.

### Checks

- **Backward compatibility**: New schema is a superset of previous (no dropped columns,
  no type narrowing)
- **Migration safety**: Migration scripts are idempotent and reversible
- **Index integrity**: All indexes defined in Design exist and are correct
- **Constraint enforcement**: Primary keys, foreign keys, NOT NULL, CHECK constraints
  are all present
- **Naming conventions**: Tables, columns, indexes follow client naming standards

### For Brown-Field Projects

- Compare new schema against as-is schema from Discovery
- Identify all breaking changes
- Verify migration scripts handle each breaking change
- Confirm rollback scripts exist for each migration

**Output**: Schema validation report with compatibility matrix.

---

## 4. SQL Best Practices Review

Review all SQL in the project (queries, migrations, dbt models, stored procedures).

### Checks

| Category | What to Check |
|---|---|
| **Performance** | Missing indexes on JOIN/WHERE columns, full table scans, N+1 patterns |
| **Correctness** | Implicit type conversions, NULL handling in comparisons, GROUP BY completeness |
| **Security** | Parameterized queries (no string concatenation), least-privilege grants |
| **Maintainability** | CTEs over nested subqueries, meaningful aliases, comments on complex logic |
| **Platform-specific** | Dialect-appropriate syntax, use of platform-native features (partitioning, clustering) |

**Output**: SQL review report with findings categorized by severity (Critical/Warning/Info).

---

## 5. Security Vulnerability Scan

Scan for security issues at the dependency and code level.

### Dependency Scan

- Check `pyproject.toml` / `requirements.txt` for known vulnerabilities (CVEs)
- Verify all dependencies are pinned to exact versions
- Flag any dependencies with no recent maintenance (>12 months since last release)
- Check license compatibility

### Code-Level Scan

| Category | What to Check |
|---|---|
| **Secrets** | Hardcoded passwords, API keys, tokens, connection strings |
| **Injection** | SQL injection, command injection, path traversal |
| **Authentication** | Missing auth on endpoints, weak token handling |
| **Data exposure** | Sensitive data in logs, error messages, API responses |
| **Configuration** | Debug mode in production config, permissive CORS, missing rate limits |

**Output**: Security scan report with findings categorized by severity
(Critical/High/Medium/Low).

---

## 6. Integration Tests

Test interactions between components and with external systems.

### Internal Integration

- API endpoints return correct responses for valid and invalid inputs
- Pipeline stages connect correctly (output of stage N is valid input for stage N+1)
- Database operations work end-to-end (CRUD through service layer)
- Error handling propagates correctly across component boundaries

### External Integration

- External API calls succeed with valid credentials (use sandbox/test environments)
- Retry logic works for transient failures (simulate with mocks)
- Circuit breakers trigger at configured thresholds
- Timeout handling works correctly

### End-to-End Scenarios

For each key user journey in the requirements:

1. Set up test data
2. Execute the full flow (source → transform → target → consumer)
3. Verify final output matches expected results
4. Verify side effects (Jira tickets, notifications, logs)

**Output**: Integration test report with scenario results.

---

## Test Report

Consolidate all test results into a single report:

```markdown
# Test Report: [Project Name]

**Date**: [date]
**Build**: [commit hash / branch]
**Phase**: Test

## Summary

| Category | Total | Passed | Failed | Skipped | Coverage |
|---|---|---|---|---|---|
| Unit Tests | [n] | [n] | [n] | [n] | [X]% |
| Data Quality | [n] | [n] | [n] | — | — |
| Schema Validation | [n] | [n] | [n] | — | — |
| SQL Review | [n] | [n] | [n] | — | — |
| Security Scan | [n] | [n] | [n] | — | — |
| Integration Tests | [n] | [n] | [n] | [n] | — |

## Overall Status: [PASS / FAIL / PASS WITH WARNINGS]

## Failures

### [Category]: [Test Name]
- **Severity**: [Critical / High / Medium / Low]
- **Description**: [What failed]
- **Impact**: [What this means]
- **Recommended Fix**: [How to fix it]

## Warnings

[Non-blocking issues that should be addressed]

## Coverage Details

[Per-module coverage breakdown]

## Security Findings

[Summary of vulnerability scan results]

## Data Quality Summary

[Summary of data validation results]
```

---

## Deployment Readiness Checklist

The final output of the Test phase is a sign-off checklist:

```markdown
# Deployment Readiness: [Project Name]

## Mandatory (all must be YES)

- [ ] All unit tests pass
- [ ] Code coverage >= 70%
- [ ] No critical or high security vulnerabilities
- [ ] All data quality checks pass
- [ ] No breaking schema changes without migration
- [ ] All SQL review critical findings resolved
- [ ] All critical integration tests pass
- [ ] No secrets in codebase

## Recommended (should be YES, exceptions documented)

- [ ] Code coverage >= 90% for critical modules
- [ ] All medium security vulnerabilities addressed
- [ ] All SQL review warnings addressed
- [ ] All integration test scenarios pass
- [ ] Performance benchmarks within targets
- [ ] Rollback procedure tested

## Sign-Off

- [ ] Developer confirms readiness
- [ ] Test report attached to Confluence
- [ ] Jira Stories updated with test results

## Decision: [READY FOR DEPLOY / NOT READY — requires: ...]
```

---

## MCP Integrations

| MCP Server | Usage |
|---|---|
| **Jira** | Update Stories with test results, transition status, flag blockers |
| **Confluence** | Publish Test Report and Deployment Readiness Checklist |

---

## Handoff to Deploy

Test is complete when:

1. Test Report is generated with all categories
2. Deployment Readiness Checklist is filled out
3. All mandatory items are YES (or failures are documented with developer-approved exceptions)
4. Developer confirms readiness to deploy

Next phase: `/deploy` — pass the test report and readiness checklist as inputs.

---

## Principles

- **Test what matters** — Focus on behavior and business rules, not implementation details
- **Fail fast, fail loud** — Critical failures block deployment; no silent passes
- **Data quality is non-negotiable** — Data pipelines are only as good as their validation
- **Security is not optional** — Every project gets a vulnerability scan
- **Reproducible results** — Tests produce the same results when re-run on the same code
- **Evidence-based readiness** — Deployment decision is based on objective test results, not opinion
