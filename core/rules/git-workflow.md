---
description: Git workflow rules enforced in all sessions. Defines commit conventions, branching strategy, and PR requirements.
globs: *
---

# Git Workflow Rules

## Commit Messages

Use semantic commit messages with the following prefixes:

- `feat:` - New feature or capability
- `fix:` - Bug fix
- `refactor:` - Code restructuring without behavior change
- `docs:` - Documentation only changes
- `test:` - Adding or updating tests
- `chore:` - Build process, dependency updates, tooling changes
- `perf:` - Performance improvement
- `ci:` - CI/CD pipeline changes
- `style:` - Formatting only (no logic change)

Format: `<type>: <short description>` (imperative mood, lowercase, no period)

Examples:
- `feat: add BigQuery schema validation to ingestion pipeline`
- `fix: handle null values in customer dimension join`
- `refactor: extract common transformation logic into shared module`

For multi-line commits, add a body separated by a blank line explaining the **why**, not the **what**.

## Branch Naming

Follow this pattern: `<type>/<ticket>-<short-description>`

- `feature/JIRA-123-customer-dim-pipeline`
- `bugfix/JIRA-456-fix-null-handling`
- `hotfix/JIRA-789-production-data-loss`
- `refactor/JIRA-101-extract-common-transforms`
- `docs/JIRA-202-update-runbook`
- `test/JIRA-303-add-schema-tests`

Rules:
- Always include the Jira ticket number
- Use lowercase with hyphens (no underscores, no camelCase)
- Keep descriptions short but meaningful (3-5 words)
- Branch from `main` unless working on a release branch

## Pull Requests

### No Direct Commits to Main

- All changes go through pull requests, no exceptions
- The `main` branch is protected: direct pushes are blocked
- Emergency fixes still go through a PR (use `hotfix/` branch with expedited review)

### PR Requirements

Every PR must include:

1. **Title**: Follows semantic commit format (e.g., `feat: add customer dim pipeline`)
2. **Description**: Explains what changed and why (not just "see code")
3. **Jira Link**: Every PR links to at least one Jira ticket
4. **Test Plan**: How the changes were tested (unit tests, integration tests, manual verification)
5. **Design Doc Link**: For architectural changes, link to the relevant ADR or design doc

### PR Template

```markdown
## Summary
[What this PR does and why]

## Jira
[JIRA-NNN](https://jira.example.com/browse/JIRA-NNN)

## Changes
- [Change 1]
- [Change 2]

## Test Plan
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual verification: [describe what you tested]

## Design Docs
- [Link to ADR or design doc, if applicable]

## Checklist
- [ ] Code follows project coding standards
- [ ] Tests added/updated for changes
- [ ] Documentation updated
- [ ] No secrets or credentials committed
- [ ] Jira ticket updated with PR link
```

### Merge Strategy

- **Squash merge to main** for clean, linear history
- The squash commit message follows semantic commit format
- Delete the feature branch after merge (automated via repo settings)
- Never rebase or force-push on shared branches after others have pulled

### Review SLA

- PRs should be reviewed within 1 business day
- Small PRs (< 200 lines) should be reviewed within 4 hours
- If a PR is blocked for > 2 days, escalate to tech lead

## History Management

- Never rewrite published history (no force-push on shared branches)
- Use `git revert` instead of `git reset` to undo published changes
- Protect `main` with branch protection rules requiring: PR approval, status checks, up-to-date branch
- Tag releases using semantic versioning: `v1.2.3`

## Release Process

- Releases are tagged from `main` after all PRs are merged
- Release notes auto-generated from semantic commit messages
- Hotfixes branch from the release tag, merge back to both `main` and the release branch
