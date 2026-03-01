---
name: client-onboard
description: One-time engagement onboarding — configure cc-framework for a new client environment
version: 1.0.0
---

# client-onboard

Configure the cc-framework for a new client environment. This skill is run **once per client** by a
lead engineer when first stepping into a new engagement. It collects enterprise knowledge, analyzes
it against framework defaults, proposes configuration, and applies it after human approval.

**Interaction model**: Agentic + Human-in-the-Loop (HIL)
**Scope**: Modifies Layer 2 (Domain) and above only. Layer 1 (Core) is immutable.
**Output**: `managed-settings.json`, CLAUDE.md overlay, `rules/`, `.mcp.json`, `engagement-config.md`

---

## Prerequisites

Before running this skill, confirm:

1. The lead engineer has access to the client's enterprise documentation (Confluence, SharePoint, Git repos, or local files).
2. The cc-framework repository has been cloned and Layer 1 (`core/`) is intact.
3. The lead engineer can answer questions about the client's technology stack, cloud accounts, and development workflow.

---

## Phase 1: Guided Knowledge Intake (HIL)

Walk the lead engineer through six intake steps. At each step:

1. Explain what information is needed and why.
2. Ask the engineer to provide links, file paths, or paste content.
3. Read/fetch each source the engineer provides.
4. Extract structured facts from the source material.
5. Summarize what was extracted and ask the engineer to confirm accuracy before moving on.

If the engineer cannot provide documentation for a step, record the gap and continue. Do not block
the entire onboarding on a single missing input.

---

### Step 1: Enterprise Architecture

**Prompt to the engineer:**

> I need to understand this client's Enterprise Architecture standards. Please provide any of the
> following:
>
> - Architecture decision records (ADRs)
> - Reference architecture diagrams or documents
> - Approved technology radar / technology standards
> - Integration patterns (event-driven, REST, gRPC, batch)
> - Service catalog or platform capabilities list
>
> You can share Confluence URLs, file paths, or paste content directly.

**What the agent extracts:**

- Approved languages and runtimes (e.g., Python 3.11+, Java 17, Node 20)
- Approved frameworks (e.g., FastAPI, Spring Boot, Next.js)
- Approved databases (e.g., PostgreSQL, BigQuery, DynamoDB)
- Approved message brokers (e.g., Kafka, Pub/Sub, SQS)
- Integration patterns in use (sync REST, async events, batch ETL)
- Microservices vs. monolith stance
- API design standards (REST conventions, versioning strategy, OpenAPI requirement)
- Constraints or prohibitions (e.g., "no MongoDB", "must use internal API gateway")

**Confirmation prompt:**

> Here is what I extracted from your EA documentation:
>
> [structured summary]
>
> Is this accurate? Anything to add, correct, or clarify?

---

### Step 2: Cloud Platform & Infrastructure

**Prompt to the engineer:**

> I need to understand the client's cloud platform setup. Please provide any of the following:
>
> - Cloud provider and account/project structure (AWS org, GCP project hierarchy, Azure subscriptions)
> - Infrastructure-as-Code standards (Terraform, Pulumi, CloudFormation)
> - Naming conventions for resources (projects, buckets, service accounts)
> - FinOps / cost allocation structure (labels, tags, billing accounts)
> - Approved managed services list
> - Network topology overview (VPCs, peering, private connectivity)
> - Container platform (GKE, EKS, Cloud Run, ECS)
>
> Share links, files, or paste content.

**What the agent extracts:**

- Primary cloud provider and region strategy
- Project/account naming convention and hierarchy
- IaC tool and module structure
- Approved compute services (Cloud Run, GKE, Lambda, ECS, etc.)
- Approved storage services (GCS, S3, BigQuery, Redshift, etc.)
- Approved networking patterns (private endpoints, VPC peering, service mesh)
- Resource naming convention (prefix-environment-service-resource pattern)
- Cost allocation labels/tags required on all resources
- Container registry and image naming standards

**Key principle applied:** Maximize use of the client's cloud platform and native services. If the
client is on GCP, prefer BigQuery over Snowflake, Cloud Run over self-managed K8s, Pub/Sub over
Kafka, etc. Only recommend external tools when no native equivalent exists or the client has
explicitly approved the external tool.

**Confirmation prompt:**

> Here is the cloud platform profile I extracted:
>
> [structured summary]
>
> Is this accurate? Anything to add, correct, or clarify?

---

### Step 3: Security & Compliance

**Prompt to the engineer:**

> I need to understand the client's security and compliance posture. Please provide any of the
> following:
>
> - Information security policy
> - Data classification scheme (e.g., Public, Internal, Confidential, Restricted)
> - Compliance frameworks in scope (SOC 2, HIPAA, PCI-DSS, GDPR, FedRAMP, etc.)
> - Access control standards (RBAC model, least privilege policies)
> - Secrets management approach (Vault, Secret Manager, Parameter Store)
> - Network security requirements (mTLS, WAF, DDoS protection)
> - Logging and audit requirements (SIEM integration, audit log retention)
> - Vulnerability management / SAST / DAST requirements
> - Approved authentication patterns (OAuth2, SAML, OIDC providers)
>
> Share links, files, or paste content.

**What the agent extracts:**

- Data classification levels and handling rules per level
- Compliance frameworks the engagement must satisfy
- Encryption requirements (at-rest, in-transit, key management)
- Access control model (RBAC roles, service account conventions)
- Secrets management tool and rotation policy
- Required security scanning tools (Snyk, SonarQube, Trivy, etc.)
- Audit logging requirements (what to log, retention period, destination)
- Authentication and authorization patterns
- PII handling rules (masking, tokenization, geographic restrictions)
- Incident response requirements relevant to development (e.g., vulnerability SLAs)

**Confirmation prompt:**

> Here is the security and compliance profile I extracted:
>
> [structured summary]
>
> Is this accurate? Anything to add, correct, or clarify?

---

### Step 4: Development Workflow

**Prompt to the engineer:**

> I need to understand how this client develops and ships software. Please provide any of the
> following:
>
> - Coding standards or style guide
> - Git branching strategy (GitFlow, trunk-based, GitHub Flow)
> - Code review process and approval requirements
> - CI/CD platform and pipeline standards (GitHub Actions, GitLab CI, Jenkins, Cloud Build)
> - Testing requirements (unit test coverage thresholds, integration test expectations)
> - Artifact management (container registry, package registry)
> - Release strategy (semantic versioning, release trains, continuous deployment)
> - Environment promotion workflow (dev -> staging -> prod)
> - PR template or commit message conventions
>
> Share links, files, or paste content.

**What the agent extracts:**

- Git platform (GitHub, GitLab, Bitbucket) and branching model
- Branch naming conventions
- Commit message format (conventional commits, Jira ticket prefix, etc.)
- PR requirements (number of approvals, required reviewers, CI must pass)
- CI/CD platform and pipeline structure
- Required CI checks (lint, test, security scan, build)
- Test coverage thresholds
- Environment names and promotion path
- Deployment strategy (blue-green, canary, rolling)
- Artifact naming and versioning conventions
- Any client-specific coding standards that diverge from cc-framework defaults

**Confirmation prompt:**

> Here is the development workflow profile I extracted:
>
> [structured summary]
>
> Is this accurate? Anything to add, correct, or clarify?

---

### Step 5: Data Governance

**Prompt to the engineer:**

> I need to understand the client's data governance standards. Please provide any of the following:
>
> - Data governance policy
> - Data quality standards and SLAs
> - Data lineage requirements (tools, metadata standards)
> - Data catalog setup (Dataplex, Collibra, Alation, etc.)
> - PII / sensitive data handling procedures
> - Data retention and deletion policies
> - Master data management standards
> - Schema management and evolution standards
>
> If this client does not have formal data governance documentation, let me know and we will
> establish sensible defaults.
>
> Share links, files, or paste content.

**What the agent extracts:**

- Data quality rules (completeness, accuracy, freshness SLAs)
- Data classification applied to datasets (maps to Step 3 classification scheme)
- PII detection and handling rules (masking, hashing, encryption, access restrictions)
- Data retention periods by classification level
- Data lineage tool and metadata requirements
- Data catalog integration requirements
- Schema evolution strategy (backward compatible, versioned, etc.)
- Data ownership model (data stewards, domain owners)
- Data quality testing tools (Great Expectations, dbt tests, Soda, custom)

**Confirmation prompt:**

> Here is the data governance profile I extracted:
>
> [structured summary]
>
> Is this accurate? Anything to add, correct, or clarify?

---

### Step 6: Atlassian Setup

**Prompt to the engineer:**

> I need to connect to the client's Atlassian tools. Please provide:
>
> - Jira instance URL (e.g., https://client.atlassian.net)
> - Jira project key(s) for this engagement (e.g., DATA, PLAT, ENG)
> - Jira workflow details (status names, transitions, required fields)
> - Jira issue types in use (Story, Task, Bug, Epic, Sub-task, custom types)
> - Confluence space URL(s) for this engagement
> - Confluence page structure conventions (templates, naming)
> - Any Atlassian automation rules relevant to development
>
> If the client uses a different project management tool (Azure DevOps, Linear, Shortcut, etc.),
> provide equivalent details and I will adapt.

**What the agent extracts:**

- Jira instance URL and authentication method
- Project key(s) and their purpose
- Issue type mapping (what types are used for what purpose)
- Workflow states and transitions (To Do -> In Progress -> In Review -> Done, etc.)
- Required fields per issue type (story points, labels, components, fix version)
- Sprint cadence and board configuration
- Confluence space URL(s) and page hierarchy
- Documentation conventions (templates, naming patterns, approval workflows)
- Integration points (Jira <-> GitHub/GitLab, Jira <-> CI/CD)

**Connectivity test:** After collecting Jira/Confluence URLs, verify that MCP server connectivity
is possible. If the Atlassian MCP server is available, test a read operation against the provided
project. Report success or failure to the engineer.

**Confirmation prompt:**

> Here is the Atlassian setup I extracted:
>
> [structured summary]
>
> Connectivity test result: [PASS/FAIL with details]
>
> Is this accurate? Anything to add, correct, or clarify?

---

## Phase 2: Analysis & Synthesis (Agentic)

After all six intake steps are complete (or explicitly skipped), perform the following analysis
autonomously. Do not ask the engineer for input during this phase — work with what was collected.

### 2.1 Cross-Reference with Framework Defaults

Compare the client's standards against cc-framework Layer 1 defaults:

| Category | Framework Default | Client Standard | Alignment |
|---|---|---|---|
| Language | Python 3.11+ | [extracted] | ALIGNED / DIVERGENT / EXTENDS |
| Formatter | black (line-length 100) | [extracted] | ALIGNED / DIVERGENT / EXTENDS |
| Linter | ruff | [extracted] | ALIGNED / DIVERGENT / EXTENDS |
| Type checker | mypy | [extracted] | ALIGNED / DIVERGENT / EXTENDS |
| Test framework | pytest (>70% coverage) | [extracted] | ALIGNED / DIVERGENT / EXTENDS |
| Git workflow | [none prescribed] | [extracted] | NEW |
| CI/CD | [none prescribed] | [extracted] | NEW |
| Cloud provider | [none prescribed] | [extracted] | NEW |

For each item:
- **ALIGNED**: Client standard matches framework default. No override needed.
- **DIVERGENT**: Client standard conflicts with framework default. The client standard wins at
  Layer 2 (but Layer 1 core principles remain). Document the divergence and rationale.
- **EXTENDS**: Client standard adds requirements beyond framework defaults. Add as additional
  constraints.
- **NEW**: Client has standards in areas where the framework has no opinion. Add as new policies.

### 2.2 Determine Platform Module

Based on the cloud provider and service preferences, select the appropriate Layer 3 platform
module:

- `platform/gcp/` — Google Cloud Platform native services
- `platform/aws/` — Amazon Web Services native services
- `platform/azure/` — Microsoft Azure native services
- `platform/multi-cloud/` — Multi-cloud or cloud-agnostic patterns

Within the platform module, identify which service-specific sub-modules apply:
- Data warehouse (BigQuery / Redshift / Synapse)
- Compute (Cloud Run / Lambda / Container Apps)
- Orchestration (Cloud Composer / Step Functions / Data Factory)
- Storage (GCS / S3 / Blob Storage)
- Messaging (Pub/Sub / SQS+SNS / Service Bus)
- ML Platform (Vertex AI / SageMaker / Azure ML)

### 2.3 Select Domain Module

Based on the engagement scope and technology patterns, determine which Layer 2 domain module(s)
apply:

- `domain/data-engineering/` — ETL, data pipelines, warehouse modeling
- `domain/full-stack-data/` — API + frontend + data backend
- `domain/ml-engineering/` — ML pipelines, model training, serving
- Additional domain modules as the framework grows

### 2.4 Identify Gaps

List any areas where documentation was insufficient or missing:

- Missing documentation topics
- Ambiguous standards that need clarification
- Contradictions between different client documents
- Areas where the framework needs guidance but the client has no policy

### 2.5 Determine MCP Server Configuration

Based on the collected information, determine which MCP servers should be configured:

- **Atlassian** (Jira + Confluence) — if Step 6 provided instance details
- **GitHub/GitLab** — based on Git platform from Step 4
- **Cloud provider CLI** — based on Step 2 cloud platform
- **Database** — if direct database access is needed
- **Custom** — any client-specific MCP servers

### 2.6 Summary Report

Present the complete analysis to the engineer:

> ## Onboarding Analysis Complete
>
> **Intake Summary:**
> - Steps completed: [N/6]
> - Steps skipped: [list]
> - Sources processed: [count]
>
> **Alignment Summary:**
> - Aligned with framework defaults: [count]
> - Client extends framework: [count]
> - Client diverges from framework: [count]
> - New policies (framework has no opinion): [count]
>
> **Recommended Modules:**
> - Domain: [module name(s)]
> - Platform: [module name]
>
> **Gaps Identified:**
> - [list of gaps]
>
> I will now prepare the configuration proposal. This is read-only analysis — nothing will be
> written until you approve in Phase 4.

---

## Phase 3: Proposal (Agent -> Human)

Generate and present each proposed artifact. For every artifact, explain:
- What it does
- Why each setting was chosen (trace back to specific client documentation)
- How it differs from framework defaults

Present artifacts one at a time. Wait for the engineer to acknowledge before presenting the next.

### 3.1 Proposed managed-settings.json

This file contains machine-readable policies that other skills and agents in the framework
reference at runtime. It is the single source of truth for client-specific configuration.

```
Proposed: .claude/managed-settings.json

{
  "engagement": {
    "client": "<client name>",
    "onboarded": "<ISO date>",
    "onboarded_by": "<lead engineer name>",
    "framework_version": "<cc-framework version>"
  },
  "cloud": {
    "provider": "<aws|gcp|azure>",
    "region": "<primary region>",
    "project_naming": "<naming convention pattern>",
    "resource_naming": "<resource naming pattern>",
    "required_labels": ["<label1>", "<label2>"],
    "iac_tool": "<terraform|pulumi|cloudformation>",
    "preferred_services": {
      "compute": "<service>",
      "storage": "<service>",
      "database": "<service>",
      "messaging": "<service>",
      "orchestration": "<service>",
      "ml": "<service>"
    }
  },
  "security": {
    "data_classification_levels": ["<level1>", "<level2>"],
    "compliance_frameworks": ["<framework1>", "<framework2>"],
    "secrets_manager": "<tool>",
    "required_scanning": ["<tool1>", "<tool2>"],
    "encryption": {
      "at_rest": "<standard>",
      "in_transit": "<standard>"
    },
    "audit_log_retention_days": <number>,
    "pii_handling": "<masking|tokenization|encryption>"
  },
  "development": {
    "git_platform": "<github|gitlab|bitbucket>",
    "branching_model": "<trunk-based|gitflow|github-flow>",
    "branch_naming": "<pattern>",
    "commit_format": "<conventional|jira-prefix|freeform>",
    "pr_approvals_required": <number>,
    "ci_platform": "<github-actions|gitlab-ci|cloud-build|jenkins>",
    "test_coverage_threshold": <number>,
    "environments": ["<env1>", "<env2>", "<env3>"],
    "deployment_strategy": "<blue-green|canary|rolling>"
  },
  "data_governance": {
    "quality_tool": "<great-expectations|dbt-tests|soda|custom>",
    "lineage_tool": "<dataplex|openlineage|custom|none>",
    "catalog_tool": "<dataplex|collibra|alation|none>",
    "retention_policy": {
      "<classification>": "<retention period>"
    },
    "schema_evolution": "<backward-compatible|versioned|strict>"
  },
  "atlassian": {
    "jira_url": "<url>",
    "project_keys": ["<key1>", "<key2>"],
    "issue_types": {
      "feature": "<Story|User Story>",
      "task": "<Task>",
      "bug": "<Bug>",
      "epic": "<Epic>"
    },
    "workflow_states": {
      "todo": "<state name>",
      "in_progress": "<state name>",
      "in_review": "<state name>",
      "done": "<state name>"
    },
    "confluence_spaces": ["<space URL 1>", "<space URL 2>"]
  }
}
```

For each section, present the proposed values alongside the source documentation that justifies
them. For example:

> **cloud.preferred_services.compute**: `cloud-run`
> *Source: Client EA doc section 4.2 — "All new workloads must use Cloud Run unless container
> orchestration complexity requires GKE."*

---

### 3.2 Proposed CLAUDE.md Overlay

This is the project-level CLAUDE.md that gets placed in the engagement repository. It layers on
top of Layer 1 (core/CLAUDE.md) with client-specific instructions.

The overlay must:
- Reference Layer 1 as the base (`core/CLAUDE.md` remains canonical)
- Add client-specific coding standards (if they extend or diverge from defaults)
- Embed EA patterns as actionable instructions (e.g., "Always use Cloud Run for stateless services")
- Include client Git workflow instructions
- Reference managed-settings.json for machine-readable values
- Document the engagement scope and team conventions

Present the full proposed CLAUDE.md content with inline annotations explaining why each section
exists.

---

### 3.3 Proposed Rules

Rules are individual policy files in `rules/` that enforce specific client constraints. Each rule
is a standalone markdown file that agents and skills can reference.

Propose rules only where the client has explicit, documented policies. Do not invent rules.

Examples of rules that might be proposed:
- `rules/cloud-native-first.md` — Prefer platform-native services over external tools
- `rules/data-classification.md` — Data handling requirements per classification level
- `rules/branching-strategy.md` — Git workflow and branch naming enforcement
- `rules/pii-handling.md` — PII detection, masking, and access control rules
- `rules/testing-standards.md` — Test coverage, test types, and quality gates
- `rules/naming-conventions.md` — Resource, project, and code naming patterns

For each proposed rule, present:
- Filename
- Content
- Source documentation that justifies the rule

---

### 3.4 Proposed .mcp.json

The MCP server configuration file that enables agent connectivity to client tools.

```
Proposed: .mcp.json

{
  "mcpServers": {
    "<server-name>": {
      "command": "<command>",
      "args": ["<args>"],
      "env": {
        "<VAR>": "<value or placeholder>"
      }
    }
  }
}
```

For each MCP server entry:
- Explain what it connects to
- List environment variables that must be set (with placeholders, never actual secrets)
- Note if the server requires additional setup (API tokens, service accounts, etc.)

---

### 3.5 Recommended Module Installation

Based on analysis, list which framework modules should be activated:

> **Domain modules:**
> - `domain/data-engineering/` — [rationale]
>
> **Platform modules:**
> - `platform/gcp/` — [rationale]
>
> **Additional skills to enable:**
> - [skill] — [rationale]

---

### 3.6 Identified Gaps

Present documentation gaps that should be resolved:

> **Gaps requiring follow-up:**
>
> 1. [Gap description] — Impact: [what cannot be configured without this]
> 2. [Gap description] — Impact: [what cannot be configured without this]
>
> **Recommendation:** These gaps do not block onboarding, but should be resolved within the first
> sprint. Default values will be used until client documentation is provided.

---

## Phase 4: Review & Apply (HIL)

### 4.1 Artifact-by-Artifact Review

Present each artifact from Phase 3 for explicit approval. For each one:

> **Artifact: [filename]**
>
> [Full content shown above]
>
> **Actions:**
> - **Approve** — I will write this file as-is.
> - **Modify** — Tell me what to change and I will update the proposal.
> - **Reject** — I will skip this artifact.
> - **Re-analyze** — Provide additional documentation and I will re-run analysis for this section.

Do not proceed to write any file until the engineer explicitly approves it. If the engineer
requests modifications, update the proposal and present it again for approval.

### 4.2 Apply Approved Configuration

Once all artifacts are approved (or explicitly skipped), write them:

1. Write `.claude/managed-settings.json`
2. Write the project CLAUDE.md (engagement repository root)
3. Write each approved `rules/*.md` file
4. Write `.mcp.json`
5. Copy or symlink approved domain and platform modules

### 4.3 Generate Engagement Config (Audit Trail)

Write `engagement-config.md` as the permanent record of this onboarding. This file documents
what was configured, why, and by whom.

```markdown
# Engagement Configuration Record

## Metadata
- **Client**: <name>
- **Onboarded**: <ISO date>
- **Lead Engineer**: <name>
- **Framework Version**: <version>

## Sources Processed
| # | Source | Type | Step |
|---|--------|------|------|
| 1 | <source> | <Confluence/File/Paste> | <step number> |

## Configuration Decisions
| Setting | Value | Source | Rationale |
|---------|-------|--------|-----------|
| cloud.provider | <value> | <source> | <why> |

## Divergences from Framework Defaults
| Setting | Framework Default | Client Override | Rationale |
|---------|-------------------|-----------------|-----------|
| <setting> | <default> | <override> | <why> |

## Gaps
| # | Gap | Impact | Status |
|---|-----|--------|--------|
| 1 | <gap> | <impact> | Open |

## Artifacts Generated
- [ ] .claude/managed-settings.json
- [ ] CLAUDE.md (project overlay)
- [ ] rules/*.md ([count] rules)
- [ ] .mcp.json
- [ ] Module activation: [list]
```

### 4.4 Final Confirmation

> Engagement onboarding complete.
>
> **Files written:**
> - [list of all files written with paths]
>
> **Next steps:**
> 1. Set environment variables referenced in `.mcp.json` (see placeholders).
> 2. Review `engagement-config.md` and resolve open gaps.
> 3. Run `/discovery` to begin your first project on this engagement.
>
> Layer 1 (core/) was not modified. All changes are in Layer 2+ configuration.

---

## Error Handling

### Engineer provides no documentation for a step
Record the gap. Use framework defaults. Flag in the gaps section of the proposal. Continue to the
next step.

### Engineer provides conflicting documentation
Present both sources and the contradiction to the engineer. Ask them to clarify which takes
precedence. Do not guess.

### Client standards conflict with Layer 1 immutable principles
Layer 1 principles (core/CLAUDE.md) are immutable. If a client standard conflicts with a Layer 1
principle, explain the conflict to the engineer and propose the closest compliant alternative.
Never override Layer 1.

Example: If a client says "no type checking", the framework still requires mypy (Layer 1). The
proposal would note: "Client preference for no type checking conflicts with framework core
principle. mypy remains required. Strictness level can be adjusted at Layer 2."

### MCP connectivity test fails
Report the failure with details. Do not block onboarding. Note in `.mcp.json` that the server
requires setup, and add a gap to the engagement config.

### Engineer requests re-analysis
Return to Phase 2 with the new/updated inputs. Regenerate only the affected artifacts in Phase 3.
Do not re-present artifacts that were already approved.

---

## Output Files Summary

| File | Location | Purpose |
|------|----------|---------|
| `managed-settings.json` | `.claude/managed-settings.json` | Machine-readable client policies |
| `CLAUDE.md` | Project root | Human-readable instructions overlay |
| `rules/*.md` | `rules/` | Individual policy enforcement files |
| `.mcp.json` | Project root | MCP server configuration |
| `engagement-config.md` | Project root | Audit trail of onboarding decisions |
