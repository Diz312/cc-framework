---
description: Code review rules enforced in all sessions. Defines review standards, checklists, and domain-specific review requirements.
globs: *
---

# Code Review Rules

## Core Principles

- All code must be reviewed by at least one other engineer before merge
- The reviewer must understand the design context - link to design docs in the PR
- Reviews focus on **architecture and logic**, not style (formatters and linters handle style)
- Reviews are collaborative, not adversarial - the goal is better code, not scoring points

## Review Checklist

Every reviewer must evaluate the following:

### Correctness
- Does the code do what the PR description says it does?
- Are edge cases handled (nulls, empty collections, boundary values)?
- Are error conditions handled gracefully (retries, fallbacks, meaningful errors)?
- Is the logic correct under concurrent execution (if applicable)?

### Security
- No secrets, credentials, or tokens in the code
- Inputs validated at system boundaries
- SQL uses parameterized queries (no string interpolation)
- Sensitive data not logged or exposed in error messages
- AuthZ checks present on all protected endpoints
- Dependencies free of known CVEs

### Performance
- No obvious N+1 query patterns
- Appropriate use of indexes for database queries
- No unbounded data fetching (missing LIMIT, no pagination)
- Expensive operations not in hot paths without caching or batching
- Resource cleanup handled (connections, file handles, temp files)

### Readability
- Code is self-documenting (clear naming, small functions, single responsibility)
- Complex logic has explanatory comments (why, not what)
- Public APIs have docstrings
- No dead code, commented-out blocks, or debugging artifacts left in

### Test Coverage
- New functionality has corresponding tests
- Tests cover happy path, edge cases, and error conditions
- Tests are deterministic (no flaky tests, no dependency on external state)
- Test names describe the behavior being tested
- Mocks are used appropriately (mock boundaries, not implementation)

### Architecture
- Code follows established project patterns (unless changing them via ADR)
- No unnecessary coupling between components
- Dependencies point inward (domain does not depend on infrastructure)
- Configuration externalized (no hardcoded values that should be environment-specific)
- Code that bypasses established patterns must have ADR justification

## Domain-Specific Review Requirements

### Data Engineering

- **Data Contracts**: Schema changes are backward-compatible or have a migration plan
- **Schema Compatibility**: New columns have sensible defaults, removed columns are deprecated first
- **Idempotency**: Pipeline runs produce the same result when re-executed (no duplicates, no data loss)
- **Data Quality**: Assertions or tests validate data quality post-transformation
- **Partitioning**: Large tables use appropriate partitioning strategy
- **Incremental Logic**: Incremental loads handle late-arriving data correctly
- **Lineage**: Transformations are traceable from source to target

### Machine Learning

- **Reproducibility**: Random seeds set, data splits deterministic, environment pinned
- **Feature Leakage**: No target variable information leaks into feature engineering
- **Model Validation**: Appropriate metrics used, cross-validation performed, holdout set preserved
- **Data Drift**: Monitoring for input distribution changes in production
- **Model Versioning**: Model artifacts versioned and traceable to training data and code
- **Bias Assessment**: Model evaluated for fairness across relevant demographic groups

### API Development

- **Backward Compatibility**: Existing endpoints not broken (versioning if needed)
- **Error Responses**: Consistent error format, appropriate HTTP status codes
- **Pagination**: List endpoints paginated with reasonable defaults
- **Rate Limiting**: Public endpoints have rate limiting configured
- **Documentation**: OpenAPI spec updated for new/changed endpoints

## Review Process

### Before Requesting Review
- Self-review your own PR first (read the diff as if you are the reviewer)
- Ensure CI passes (tests, lint, type checks)
- PR description is complete (summary, test plan, Jira link)
- Mark any specific areas where you want reviewer attention

### During Review
- Respond to all comments (resolve or discuss, do not ignore)
- Use "nit:" prefix for minor suggestions that do not block approval
- Use "blocking:" prefix for issues that must be fixed before merge
- If a comment requires discussion, move it to a thread or call rather than long comment chains

### After Review
- Address all blocking comments before re-requesting review
- Do not resolve other people's comments - let the commenter resolve after verifying the fix
- Squash fixup commits before merge (or rely on squash merge)
- Update Jira ticket with PR status

## What NOT to Review

- **Formatting**: Handled by `black`, `prettier`, or configured formatter
- **Import ordering**: Handled by `isort`, `ruff`, or configured tool
- **Lint violations**: Handled by `ruff`, `eslint`, or configured linter
- **Type errors**: Handled by `mypy`, `tsc`, or configured type checker

If these are showing up in review, the project's pre-commit hooks need fixing - file a ticket.

## Review Anti-Patterns to Avoid

- **Rubber stamping**: Approving without reading the code
- **Bike-shedding**: Spending review time on trivial naming while missing logic bugs
- **Blocking on preferences**: Blocking approval for stylistic preferences not covered by standards
- **Drive-by reviews**: Leaving comments without following up on responses
- **Review hoarding**: Holding PRs without providing feedback for days
