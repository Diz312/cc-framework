---
name: deploy
description: SDLC Phase 5 — Deployment orchestrator for PR creation, CI/CD, ticket management, documentation, and post-deploy verification.
version: 1.0.0
---

# Deploy Phase Orchestrator

Guides the deployment process from PR creation through post-deploy verification. Ensures
all artifacts are linked, tickets are updated, documentation is current, and the deployment
is verified in the target environment.

> **Prerequisite**: Test phase completed. Requires passing test report and approved
> deployment readiness checklist.

---

## Invocation

```
/deploy
```

The orchestrator begins by ingesting Test phase outputs:

1. Read the Test Report
2. Read the Deployment Readiness Checklist (confirm all mandatory items are YES)
3. Read Jira Stories to determine what is being deployed
4. Read Design artifacts for deployment topology and IaC plan

If the Deployment Readiness Checklist has any mandatory item marked NO, the orchestrator
stops and directs the developer back to `/test` or `/build` to resolve.

---

## Deployment Workflow

```
1. PR Creation             — Standardized PR with all references
2. CI/CD Pipeline          — Verify automated checks pass
3. Jira Updates            — Link PRs, transition Stories
4. Confluence Updates      — Deployment notes, runbooks
5. Post-Deploy Verification — Health checks and smoke tests
6. Deployment Summary      — Final report
```

---

## 1. PR Creation

Create a pull request with standardized format. All PRs follow this template:

```markdown
## Summary

[1-3 sentence description of what this PR delivers]

## Changes

- [Bulleted list of significant changes]

## Design References

- Solution Architecture: [link to Confluence page]
- ADRs: [links to relevant ADRs]
- Schema Design: [link if schema changes included]

## Test Evidence

- Test Report: [link to Confluence test report page]
- Unit Test Coverage: [X]%
- Data Quality: [PASS/FAIL]
- Security Scan: [PASS/FAIL]
- Integration Tests: [PASS/FAIL]

## Deployment Notes

- [ ] Database migrations required: [YES/NO — if YES, list migration files]
- [ ] Environment variables added: [YES/NO — if YES, list new vars (not values)]
- [ ] Infrastructure changes: [YES/NO — if YES, describe]
- [ ] Rollback procedure: [describe how to revert]

## Jira

- Epic: [PROJ-XXX](link)
- Stories: [PROJ-YYY](link), [PROJ-ZZZ](link)

## Checklist

- [ ] Code follows project coding standards
- [ ] All tests pass
- [ ] No secrets in code
- [ ] Documentation updated
- [ ] Migrations are reversible
```

### PR Best Practices

- **One logical change per PR** — If the build spans multiple epics, create separate PRs
- **Small PRs preferred** — Break large changes into reviewable increments when possible
- **Draft PR for early feedback** — Create draft PR early in Build for visibility
- **Link everything** — Every PR references its Jira Stories, Design docs, and Test Report

---

## 2. CI/CD Pipeline Checks

After PR creation, verify the CI/CD pipeline passes:

### Expected Pipeline Stages

| Stage | What Runs | Pass Criteria |
|---|---|---|
| **Lint** | black --check, ruff check | Zero violations |
| **Type Check** | mypy --strict | Zero errors |
| **Unit Tests** | pytest with coverage | All pass, coverage >= threshold |
| **Security Scan** | Dependency vulnerability check | No critical/high CVEs |
| **Build** | Application build (Docker, package, etc.) | Successful build |
| **Integration Tests** | Cross-component tests | All pass |
| **IaC Validation** | terraform plan / pulumi preview | No unexpected changes |

### If Pipeline Fails

1. Read the CI/CD logs to identify the failure
2. Determine if the failure is in code (fix needed) or infrastructure (flaky test, env issue)
3. Fix code issues and push updated commits
4. For infrastructure issues, document and escalate to the developer

Do not merge a PR with failing pipeline checks.

---

## 3. Jira Updates

Update all related Jira tickets:

| Action | Details |
|---|---|
| **Link PR to Stories** | Add PR URL as a link on each related Story |
| **Transition Stories** | Move from "In Review" to "Done" (or client's equivalent status) |
| **Update Epic** | Add comment summarizing deployment. If all Stories are Done, close the Epic |
| **Add deployment label** | Tag Stories with deployment identifier (e.g., `deployed-2026-03-01`) |
| **Log blockers** | If any Stories could not be completed, document why and leave them open |

---

## 4. Confluence Updates

Update project documentation to reflect the deployed state:

### Deployment Notes Page

Create a new Confluence page (or append to existing deployment log):

```markdown
# Deployment: [Project Name] — [Date]

## What Was Deployed
[Summary of changes — reference PR and Jira Stories]

## Environment
- Target: [production / staging / dev]
- Deployment method: [CI/CD pipeline / manual / IaC apply]
- Commit: [hash]
- PR: [link]

## Database Changes
[List of migrations applied, if any]

## Configuration Changes
[New environment variables, feature flags, etc.]

## Rollback Procedure
[Step-by-step rollback instructions]

## Known Issues
[Any issues discovered during deployment that are not blockers]

## Verification Results
[Post-deploy check results — see Section 5]
```

### Runbook Updates

If the deployment introduces new operational procedures:

- Update existing runbook or create new entries
- Document: monitoring dashboards, alerting rules, common failure modes, troubleshooting steps
- Include contact information for escalation

### Architecture Documentation

If the deployment changes the architecture:

- Update the Solution Architecture page on Confluence
- Update component diagrams
- Update data flow documentation

---

## 5. Post-Deploy Verification

After deployment completes, verify the system is healthy.

### Health Checks

| Check | What to Verify |
|---|---|
| **Service availability** | All endpoints respond (HTTP 200 on health endpoints) |
| **Database connectivity** | Application can connect and query |
| **Pipeline execution** | Trigger a test run, verify completion |
| **External integrations** | Downstream systems receiving data |
| **Monitoring** | Dashboards showing metrics, no error spikes |
| **Logging** | Logs appearing in expected location with correct format |

### Smoke Tests

Run a minimal set of end-to-end tests against the deployed environment:

1. **Happy path**: Execute the primary user journey end-to-end
2. **Data flow**: Verify data moves from source to target correctly
3. **API contract**: Call key endpoints with expected inputs, verify responses
4. **Auth**: Verify authentication and authorization work in the deployed environment

### Verification Decision

```
All health checks pass + All smoke tests pass → DEPLOYMENT VERIFIED
Any health check fails                        → INVESTIGATE (may need rollback)
Any smoke test fails                          → INVESTIGATE (may need rollback)
```

If rollback is needed:
1. Execute the rollback procedure documented in the PR
2. Verify rollback was successful (re-run health checks)
3. Document the failure and rollback in Confluence
4. Reopen Jira Stories as needed
5. Return to `/build` or `/test` depending on failure root cause

---

## 6. Deployment Summary

Final artifact of the Deploy phase:

```markdown
# Deployment Summary: [Project Name]

**Date**: [date]
**Environment**: [target environment]
**Status**: [VERIFIED / ROLLED BACK / PARTIAL]

## Scope
- Jira Epic: [link]
- Stories Delivered: [count] ([links])
- PRs Merged: [count] ([links])

## Changes Deployed
- [Bulleted summary of changes]

## Verification Results
| Check | Status |
|---|---|
| Health Checks | [PASS/FAIL] |
| Smoke Tests | [PASS/FAIL] |
| Monitoring | [PASS/FAIL] |

## Metrics
- Build Duration: [time from first commit to deploy]
- Test Coverage: [final coverage %]
- Security Issues: [count resolved / count remaining]

## Follow-Up Items
- [Any post-deploy tasks, monitoring to watch, deferred items]

## Lessons Learned
- [What went well]
- [What could improve]
```

---

## MCP Integrations

| MCP Server | Usage |
|---|---|
| **Jira** | Link PRs to Stories, transition statuses, update Epic, add deployment labels |
| **Confluence** | Write Deployment Notes page, update Runbooks, update Architecture docs |
| **GitHub** (via `gh` CLI) | Create PR, monitor CI checks, merge when approved |

If MCP integrations are not available, produce artifacts as local markdown files and provide
the developer with manual steps.

---

## Output Checklist

Before completing Deploy, verify:

- [ ] PR created with standardized format
- [ ] CI/CD pipeline passes all checks
- [ ] PR merged (after developer approval)
- [ ] Jira Stories transitioned to Done
- [ ] Jira Epic updated
- [ ] Confluence Deployment Notes page published
- [ ] Runbooks updated (if applicable)
- [ ] Post-deploy health checks pass
- [ ] Post-deploy smoke tests pass
- [ ] Deployment Summary generated

---

## SDLC Complete

The project lifecycle is complete when:

1. All Jira Stories in the Epic are Done
2. All documentation is current on Confluence
3. Post-deploy verification passes
4. Deployment Summary is published
5. Developer confirms project delivery

---

## Principles

- **Nothing merges red** — CI/CD must pass before merge. No exceptions.
- **Link everything** — PR references Design, Test, and Jira. Nothing exists in isolation.
- **Rollback is planned, not improvised** — Every deployment has a documented rollback procedure before it ships
- **Verify in production** — Health checks and smoke tests are mandatory, not optional
- **Documentation is part of delivery** — A feature is not done until the docs are updated
- **Close the loop** — Jira Stories, Confluence pages, and deployment summary all reflect final state
