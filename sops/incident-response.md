# SOP: Incident Response

What to do when Claude Code produces bad output — incorrect code, security vulnerabilities, data issues, or other problems.

---

## Severity Levels

| Level | Description | Examples | Response Time |
|-------|-------------|----------|---------------|
| **Critical** | Data loss, security breach, production impact | Deleted production data, exposed credentials, deployed broken code | Immediate |
| **High** | Incorrect code deployed, data quality issues | Wrong business logic in production, corrupted pipeline output | Within 1 hour |
| **Medium** | Incorrect code caught in review, test failures | Bad generated code caught by tests, wrong architecture pattern | Within 1 day |
| **Low** | Style issues, minor inaccuracies | Wrong formatting, suboptimal but functional code | Next sprint |

---

## Immediate Actions

### 1. Stop

- **Do not commit** any uncommitted generated code
- **Do not deploy** any pending changes
- **Do not run** any more Claude Code commands on the affected code
- Take a breath — assess before acting

### 2. Assess

Answer these questions:

- **What was generated?** Read the actual output carefully
- **What was applied?** Did code get committed? Deployed? Merged?
- **What is the blast radius?** Local only? Shared branch? Production?
- **Is this a security issue?** Credentials exposed? Injection vulnerability? Data leak?
- **Is there data impact?** Data corrupted? Lost? Exposed to wrong audience?

### 3. Contain

Based on assessment:

| Situation | Action |
|-----------|--------|
| Uncommitted bad code | `git checkout -- <files>` to discard |
| Committed but not pushed | `git reset HEAD~1` to uncommit |
| Pushed but not merged | Close/update the PR |
| Merged to main | `git revert <commit>` and push |
| Deployed to production | Follow client's rollback procedure |
| Credentials exposed | Rotate immediately, check access logs |
| Data corrupted | Restore from backup, investigate scope |

---

## Rollback Procedures

### Code Rollback

```bash
# Discard uncommitted changes
git checkout -- <affected-files>

# Undo last commit (keep changes staged)
git reset --soft HEAD~1

# Revert a merged commit
git revert <commit-hash>
git push
```

### Infrastructure Rollback

```bash
# Terraform
terraform plan  # Review what will change
terraform apply -target=<resource>  # Selective rollback

# Or restore from previous state
terraform state pull > current.tfstate
# Restore previous state from backup
```

### Data Rollback

- Restore from the most recent known-good backup
- For BigQuery: use time travel (`FOR SYSTEM_TIME AS OF`)
- For pipelines: re-run from the last known-good checkpoint
- Document what data was affected and what was restored

---

## Root Cause Analysis

After containing the issue, analyze what went wrong:

### Common Root Causes

| Category | Examples | Framework Fix |
|----------|----------|---------------|
| **Missing context** | Claude Code didn't know about a constraint | Add to CLAUDE.md or rules |
| **Wrong assumption** | Claude Code assumed a default behavior | Add explicit instruction in rules |
| **Stale information** | Framework API changed, Claude Code used old pattern | Update framework-verifier agent |
| **Prompt ambiguity** | Vague instruction led to wrong interpretation | Refine skill/agent instructions |
| **Missing guardrail** | Dangerous operation wasn't in deny list | Add to managed-settings.json deny rules |
| **Hallucinated API** | Claude Code invented a non-existent function | Always use framework-verifier before coding |

### Analysis Template

```markdown
## Incident: [Brief description]
**Date:** YYYY-MM-DD
**Severity:** Critical / High / Medium / Low
**Discovered by:** [Name]
**Affected scope:** [Files, services, data]

### What happened
[Describe the actual output/behavior]

### Expected behavior
[What should have happened]

### Root cause
[Why did Claude Code produce this output]

### Impact
[What was affected, who was impacted]

### Resolution
[What was done to fix it]

### Prevention
[What framework changes prevent recurrence]
```

---

## Improvement Actions

### Update Rules
If the issue was a missing constraint:
```
Add a rule to core/rules/ or .claude/rules/ that prevents this pattern
```

### Update Deny Patterns
If a dangerous operation should have been blocked:
```json
{
  "permissions": {
    "deny": ["Bash(dangerous-command*)"]
  }
}
```

### Update Skills/Agents
If the issue was in a skill or agent workflow:
- Refine the instructions to be more specific
- Add validation steps
- Add guard rails for the identified failure mode

### File Framework Issue
If the issue is systemic (affects all users):
1. Open an issue on the cc-framework repo
2. Include the incident analysis (sanitized — no client data)
3. Propose the fix
4. Submit a PR if you have the fix

---

## Reporting

### Internal Log
Every medium+ incident should be logged:
- Add to the engagement's incident log
- Include the analysis template above
- Link to the framework issue if one was filed

### Escalation Path
- **Low/Medium**: Engagement lead reviews, framework improvement filed
- **High**: Engagement lead + client tech lead notified
- **Critical**: Immediate escalation to engagement lead, client tech lead, and security team

### Metrics to Track
- Incidents per month by severity
- Time to detection
- Time to resolution
- Root cause distribution (missing context, wrong assumption, etc.)
- Framework improvements made per incident
