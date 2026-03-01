# SOP: Code Review with Claude Code

How to use Claude Code effectively for code review, including self-review and peer review.

---

## Self-Review Before Submitting PR

### Step 1: Review Against Checklist

Ask Claude Code to review your staged changes:

```
Review my changes against the code review checklist from the code-review rule
```

The `code-review` rule provides a comprehensive checklist:
- **Correctness**: Logic errors, edge cases, error handling
- **Security**: Input validation, secrets exposure, SQL injection, XSS
- **Performance**: N+1 queries, missing indexes, unnecessary computation
- **Readability**: Naming, structure, comments where needed
- **Test Coverage**: New code has tests, edge cases covered
- **Architecture**: Follows established patterns, no unnecessary complexity

### Step 2: Domain-Specific Review

For data engineering code:
```
Review this code for data engineering best practices: idempotency, schema compatibility, data quality
```

For SQL:
```
Review this SQL against our sql-standards rule
```

For API code:
```
Review this API for backward compatibility, proper status codes, and input validation
```

### Step 3: Check for Common Issues

```
Check for: hardcoded credentials, missing error handling, TODO comments without Jira refs, SELECT * in SQL
```

---

## Reviewing Others' PRs

### Step 1: Checkout the PR

```bash
gh pr checkout 123
```

### Step 2: Understand the Context

```
Read the PR description and linked design docs. Summarize what this PR is doing and why.
```

### Step 3: Review the Changes

```
Review all changes in this PR for correctness, security, and adherence to our standards
```

### Step 4: Check Test Coverage

```
Are there adequate tests for the new/changed code? What edge cases are missing?
```

### Step 5: Provide Feedback

Use Claude Code to help draft review comments, but always apply your own judgment before submitting.

---

## What Claude Code Is Good At

- Catching formatting inconsistencies and style violations
- Identifying common security anti-patterns (SQL injection, XSS, secrets in code)
- Checking for missing error handling and edge cases
- Verifying test coverage patterns
- Ensuring naming conventions are followed
- Spotting N+1 query patterns and obvious performance issues
- Checking SQL against standards (CTEs, aliasing, explicit columns)

## What Claude Code Is NOT Good At

- **Business logic correctness**: Claude Code doesn't know your business rules. You must verify that the logic is correct for the domain.
- **Domain expertise**: A data engineer should review data pipeline code. Claude Code can check patterns but not domain-specific correctness.
- **Architecture judgment**: Whether a particular design is the right choice requires human judgment about the broader system.
- **Performance under load**: Claude Code can spot obvious issues but cannot predict production performance.
- **Security threat modeling**: Automated checks catch common vulnerabilities but not sophisticated attack vectors.

**Rule: Claude Code assists review; it does not replace human review.**

---

## Review Checklist Summary

### All Code
- [ ] Logic is correct and handles edge cases
- [ ] Error handling is present and appropriate
- [ ] No hardcoded credentials or secrets
- [ ] Input validation at system boundaries
- [ ] Tests exist and cover the new/changed code
- [ ] Naming follows conventions
- [ ] No unnecessary complexity or over-engineering

### Data Engineering
- [ ] Operations are idempotent
- [ ] Schema changes are backward compatible
- [ ] Data quality tests are included
- [ ] SQL follows sql-standards rule
- [ ] Partitioning and clustering are appropriate
- [ ] Audit columns are present on new tables

### API
- [ ] Endpoints follow REST conventions
- [ ] Request/response models use Pydantic
- [ ] Status codes are correct
- [ ] Backward compatible with existing clients
- [ ] Rate limiting and pagination where appropriate

### ML/DS
- [ ] Experiments are reproducible (seeds, versions)
- [ ] No data leakage between train/test
- [ ] Model artifacts are versioned
- [ ] Feature engineering is documented
