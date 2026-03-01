# SOP: Daily Developer Workflow

Standard daily workflow for engineers using Claude Code with cc-framework.

---

## Session Start

### 1. Pull Latest Changes
```bash
git pull --rebase
```

### 2. Check Jira Board
Ask Claude Code to check your current sprint:
```
What are my assigned Jira tickets in the current sprint?
```

### 3. Plan the Day
Select which ticket(s) to work on. Check for any blockers, PRs awaiting review, or deploy items.

---

## Feature Development Cycle

### 1. Branch from Main
```bash
git checkout -b feat/PROJ-123-add-customer-pipeline
```

Follow the branch naming convention: `<type>/<ticket>-<description>`
- `feat/` — new feature
- `fix/` — bug fix
- `refactor/` — code restructuring
- `docs/` — documentation only

### 2. Reference Design Docs
Before coding, review the design artifacts:
```
Read the design document for PROJ-123 in docs/design/
```

### 3. Build Phase Workflow
For substantial features, use the build orchestrator:
```
/build
```

For smaller changes, code directly with Claude Code assistance while following the standards enforced by rules.

### 4. Format and Lint
After making changes:
```
/format-and-lint
```

This runs black, ruff, and mypy on your code.

### 5. Write and Run Tests
```
/test-runner
```

Or let the `/build` orchestrator handle testing as part of its workflow.

### 6. Commit
Follow semantic commit conventions:
```bash
git add <files>
git commit -m "feat(PROJ-123): add customer pipeline ingestion layer"
```

Commit message format: `<type>(<scope>): <description>`
- `feat`: new feature
- `fix`: bug fix
- `refactor`: restructuring
- `docs`: documentation
- `test`: adding/fixing tests
- `chore`: maintenance

---

## Testing

### Run the Test Phase
For comprehensive testing before PR:
```
/test
```

This runs all six test categories:
1. Unit tests with coverage
2. Data quality validations
3. Schema validation
4. SQL best practices review
5. Security vulnerability scan
6. Integration tests

### Interpreting Results
- **All pass**: Ready for PR
- **Unit test failure**: Fix the test or the code, re-run
- **Data quality failure**: Check data expectations, update quality tests if requirements changed
- **Security scan findings**: Address all HIGH/CRITICAL findings before PR

---

## Code Review

### Self-Review
Before submitting a PR, self-review using Claude Code:
```
Review my changes against the code review checklist
```

The code-review rule provides the full checklist covering correctness, security, performance, readability, test coverage, and architecture.

### Peer Review
When reviewing others' PRs:
```
gh pr checkout 123
```
Then ask Claude Code to review:
```
Review the changes in this PR for correctness, security, and adherence to our standards
```

---

## PR and Deploy

### Create PR
Use the deploy orchestrator or create manually:
```
/deploy
```

Or:
```bash
gh pr create --title "feat(PROJ-123): add customer pipeline" --body "..."
```

### Post-Merge
After PR is merged:
1. Jira ticket transitions automatically (if configured via `/deploy`)
2. CI/CD pipeline runs
3. Verify deployment in target environment

---

## Session End

### 1. Commit All Work
```bash
git status
git add <files>
git commit -m "wip(PROJ-123): progress on customer pipeline transformation layer"
```

### 2. Push to Remote
```bash
git push -u origin feat/PROJ-123-add-customer-pipeline
```

### 3. Update Jira
If not automated:
```
Update PROJ-123 status to In Progress and add a comment summarizing today's progress
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Format & lint code | `/format-and-lint` |
| Run tests | `/test-runner` |
| Full test suite | `/test` |
| Start discovery | `/discovery` |
| Design phase | `/design` |
| Build phase | `/build` |
| Deploy phase | `/deploy` |
| Check Jira tickets | Ask Claude Code |
| Create PR | `gh pr create` or `/deploy` |
