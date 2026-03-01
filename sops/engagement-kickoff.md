# SOP: Engagement Kickoff

Standard operating procedure for starting a new client engagement with cc-framework.

---

## Pre-Requisites

Before starting, ensure:

- [ ] cc-framework installed (`./scripts/validate-setup.sh` passes)
- [ ] Claude Code Enterprise license active
- [ ] Access to client's Jira instance (URL, project key, API token or SSO)
- [ ] Access to client's Confluence space (URL, space key)
- [ ] Access to client's cloud platform (GCP/AWS/Azure account, appropriate IAM roles)
- [ ] Client EA documentation gathered (architecture patterns, approved technologies)
- [ ] Client security policies available (data classification, compliance requirements)
- [ ] Client development standards available (branching strategy, CI/CD, code review process)

---

## Phase 1: Gather Client Documentation

Collect the following before running `/client-onboard`:

### Enterprise Architecture
- [ ] Reference architectures and approved patterns
- [ ] Technology standards and approved technology list
- [ ] Architecture review board (ARB) process documentation
- Sources: Client Confluence, EA team, solution architects

### Cloud Platform
- [ ] Cloud account/project structure
- [ ] Naming conventions for resources
- [ ] FinOps/cost management policies
- [ ] Network topology (VPCs, peering, private access)
- Sources: Platform team, cloud console, IaC repos

### Security & Compliance
- [ ] Data classification scheme
- [ ] Security policies (access control, encryption, logging)
- [ ] Compliance requirements (HIPAA, SOC 2, GDPR, PCI-DSS)
- [ ] Incident response procedures
- Sources: InfoSec team, compliance team, security documentation

### Development Workflow
- [ ] Branching strategy (trunk-based, GitFlow, etc.)
- [ ] CI/CD pipeline documentation
- [ ] Code review requirements (approvals, CODEOWNERS)
- [ ] Testing requirements and standards
- Sources: Engineering leads, DevOps team, pipeline configs

### Data Governance
- [ ] Data quality standards and tools
- [ ] PII handling procedures
- [ ] Data retention policies
- [ ] Data catalog/lineage requirements
- Sources: Data governance team, compliance team

### Atlassian Setup
- [ ] Jira instance URL and project key(s)
- [ ] Confluence space URL(s)
- [ ] Workflow configuration (statuses, transitions)
- [ ] Custom fields and issue types
- Sources: Jira admin, project manager

---

## Phase 2: Run /client-onboard

Launch Claude Code and run the onboarding skill:

```
/client-onboard
```

### What to Expect

The agent walks through six structured steps:

1. **Enterprise Architecture** — Provide links to or upload EA docs. The agent reads, extracts patterns, and confirms understanding.

2. **Cloud Platform** — Provide cloud account details, naming docs. The agent maps topology and conventions.

3. **Security & Compliance** — Provide security policies. The agent extracts handling rules, classification scheme, and access patterns.

4. **Development Workflow** — Provide dev standards. The agent captures branching, CI/CD, review requirements.

5. **Data Governance** — Provide governance policies. The agent extracts quality rules, PII handling, retention.

6. **Atlassian Setup** — Provide Jira/Confluence details. The agent tests connectivity, maps project structure.

### Tips

- Have documentation open in browser tabs for quick sharing
- Provide Confluence links when possible — the agent can read Confluence via MCP
- If documentation is missing for a section, tell the agent — it will note the gap
- The agent processes each input before moving to the next step

---

## Phase 3: Review the Proposal

After completing the intake, the agent presents:

### Review Checklist

- [ ] **managed-settings.json** — Verify permission denials match client security requirements. Check that allow rules are appropriate for the team.

- [ ] **CLAUDE.md overlay** — Verify EA patterns are accurately captured. Check naming conventions, architecture patterns, technology constraints.

- [ ] **rules/ files** — Verify each rule aligns with client documentation. Check that constraints are not too restrictive (blocking productivity) or too loose (missing governance).

- [ ] **.mcp.json** — Verify Jira/Confluence URLs are correct. Test MCP connectivity.

- [ ] **Recommended modules** — Verify the right domain (data-engineering, analytics) and platform (gcp, aws, azure) modules are selected.

- [ ] **Gaps identified** — Review areas where client documentation was insufficient. Plan to fill these gaps with the client team.

### Common Adjustments

- **Too restrictive permissions**: Loosen deny rules if they block common dev workflows
- **Missing EA patterns**: Add patterns the agent missed from verbal knowledge
- **MCP connectivity issues**: Check authentication tokens, network access, URL format
- **Platform module mismatch**: If client uses multiple platforms, install additional modules

---

## Phase 4: Post-Onboarding Verification

After approving the proposal:

- [ ] Run `./scripts/validate-setup.sh` to verify installation
- [ ] Open a new Claude Code session to verify CLAUDE.md loads correctly
- [ ] Test Jira connectivity: ask Claude Code to list recent Jira issues
- [ ] Test Confluence connectivity: ask Claude Code to read a known Confluence page
- [ ] Test cloud platform MCP: ask Claude Code to list cloud resources
- [ ] Review the generated `engagement-config.md` audit trail

---

## Phase 5: First Project Setup

With the engagement configured, start the first project:

```
/discovery
```

See `sops/daily-workflow.md` for the daily development workflow.

---

## Phase 6: Team Onboarding

Getting other engineers set up:

1. **Install cc-framework**: Each engineer runs `./scripts/install.sh`
2. **Copy engagement config**: Share the project `.claude/` directory (committed to repo)
3. **Configure credentials**: Each engineer sets up their own Jira/Confluence tokens and cloud auth
4. **Verify**: Each engineer runs `./scripts/validate-setup.sh`
5. **Orient**: Walk through `sops/daily-workflow.md` with the team

### Team Permissions Note

Managed settings apply organization-wide. Individual engineers may need:
- Personal Jira API tokens (do not share tokens)
- Cloud platform authentication (`gcloud auth login`)
- Confluence access tokens
- SSH keys for Git operations
