---
name: discovery
description: SDLC Phase 1 — Requirements gathering and current-state analysis for green-field and brown-field projects.
version: 1.0.0
---

# Discovery Phase Orchestrator

First phase of every new project. Collects requirements, profiles data sources, and assesses
feasibility. Adapts workflow based on green-field vs. brown-field context.

> **Prerequisite**: Client engagement must be onboarded (`/client-onboard` completed).
> Discovery reads Layer 2 config (approved stack, EA patterns, Jira/Confluence MCP endpoints).

---

## Invocation

```
/discovery
```

The orchestrator starts by asking a single question:

> **Is this a green-field project (new build) or a brown-field project (existing system)?**

All subsequent workflow branches from that answer.

---

## Workflow: Green-Field

### Step 1 — Requirements Collection

Gather the following through structured developer conversation:

| Category | What to Capture |
|---|---|
| **Stakeholders** | Who owns the project, who are the consumers, who approves |
| **Business Objectives** | What problem is being solved, success metrics, timeline |
| **Data Sources** | Source systems, formats, volumes, refresh frequency, access methods |
| **Data Consumers** | Downstream systems, dashboards, APIs, reports, ML models |
| **Constraints** | Approved stack (from Layer 2), compliance requirements, budget, SLAs |
| **Non-Functional** | Performance targets, availability, data retention, security classification |

For each data source identified:

1. Ask the developer for connection details or sample files
2. Profile the source — schema, row counts, data types, null rates, cardinality
3. Assess data quality — completeness, consistency, timeliness
4. Document access patterns — batch vs. streaming, auth method, rate limits

### Step 2 — Feasibility Assessment

Evaluate feasibility within the client's approved stack:

- Can the approved platform handle the data volumes?
- Are the required connectors/integrations available natively?
- Are there licensing or access blockers?
- What is the estimated effort (T-shirt sizing: S/M/L/XL)?

Flag any requirements that cannot be met within the approved stack and propose alternatives.

### Step 3 — Artifact Generation

Produce the following artifacts:

1. **Requirements Specification** — Structured document with all captured requirements, priorities (MoSCoW), and acceptance criteria
2. **Data Source Catalog** — One entry per source: name, type, schema, volume, quality assessment, access method, owner
3. **Feasibility Report** — Stack fit analysis, risk register, effort estimate, recommendations

### Step 4 — Jira & Confluence

- **Jira**: Create an Epic for the project. Create Stories for each major requirement group. Link Stories to the Epic. Set priority based on MoSCoW.
- **Confluence**: Write a Discovery Summary page under the project space. Attach or inline all artifacts. Link to the Jira Epic.

---

## Workflow: Brown-Field

### Step 1 — Current-State Analysis

**This step happens BEFORE requirements collection.** Understanding what exists is mandatory.

Analyze the existing system by reading:

| Source | What to Extract |
|---|---|
| **Codebase** | Languages, frameworks, project structure, entry points, dependencies |
| **Schemas** | Database schemas, table relationships, column types, constraints, indexes |
| **Pipelines** | ETL/ELT flows, orchestration (Airflow, dbt, etc.), schedules, dependencies |
| **Data Flows** | Source-to-target lineage, transformation logic, data contracts |
| **Infrastructure** | Cloud services, IaC (Terraform/Pulumi), networking, compute, storage |
| **Runbooks** | Operational procedures, incident response, monitoring, alerting |
| **Documentation** | Existing Confluence pages, READMEs, architecture diagrams |

Use `Read`, `Glob`, `Grep` to analyze the codebase. Use Confluence MCP to read existing docs.

Produce an **As-Is Assessment**:

```markdown
# As-Is Assessment: [Project Name]

## System Overview
[High-level description of what the system does today]

## Architecture
- Platform: [cloud provider, services]
- Languages: [with versions]
- Frameworks: [with versions]
- Databases: [types, engines, versions]
- Orchestration: [scheduler, workflow engine]

## Data Flow
[Source → Transform → Target for each pipeline]

## Schema Summary
[Key tables/collections, relationships, volumes]

## Infrastructure
[IaC summary, compute, storage, networking]

## Operational Health
- Monitoring: [what exists]
- Alerting: [what exists]
- Incident history: [recent issues if available]

## Technical Debt
[Known issues, outdated dependencies, missing tests, hardcoded values]

## Strengths
[What works well, what to preserve]

## Risks
[What is fragile, what lacks documentation, what has single points of failure]
```

### Step 2 — Requirements Collection

Same as green-field Step 1, but informed by the as-is assessment. Ask:

- What needs to change?
- What needs to be preserved?
- What is the desired end state?
- Are there migration constraints (zero-downtime, data continuity)?

### Step 3 — Gap Analysis

Compare current state to desired state:

```markdown
# Gap Analysis: [Project Name]

| Area | Current State | Desired State | Gap | Effort | Priority |
|---|---|---|---|---|---|
| [area] | [what exists] | [what is needed] | [delta] | [S/M/L/XL] | [MoSCoW] |
```

Categorize gaps:
- **Extend**: Current system can be extended to meet the requirement
- **Replace**: Component must be replaced entirely
- **New**: Net-new capability required
- **Retire**: Component should be decommissioned

### Step 4 — Artifact Generation

Produce all green-field artifacts PLUS:

4. **As-Is Assessment** — From Step 1
5. **Gap Analysis** — From Step 3

### Step 5 — Jira & Confluence

Same as green-field, but:
- Jira Stories include gap categorization labels (Extend/Replace/New/Retire)
- Confluence page includes As-Is Assessment and Gap Analysis sections
- Link to existing documentation where relevant

---

## MCP Integrations

| MCP Server | Usage |
|---|---|
| **Jira** | Read existing tickets, create Epics/Stories, set priorities, add labels |
| **Confluence** | Read existing project docs, write Discovery Summary page, attach artifacts |

If Jira or Confluence MCP is not configured, produce artifacts as local markdown files and
instruct the developer to upload manually.

---

## Output Checklist

Before completing Discovery, verify all artifacts exist:

- [ ] Requirements Specification (with MoSCoW priorities and acceptance criteria)
- [ ] Data Source Catalog (with quality profiles)
- [ ] Feasibility Report (with effort estimates)
- [ ] As-Is Assessment (brown-field only)
- [ ] Gap Analysis (brown-field only)
- [ ] Jira Epic + Stories created
- [ ] Confluence Discovery Summary page published

---

## Handoff to Design

Discovery is complete when:

1. All artifacts are produced and reviewed with the developer
2. Jira Epic and Stories exist
3. Confluence page is published
4. Developer confirms requirements are complete

Next phase: `/design` — pass the requirements spec, data source catalog, and gap analysis
(if brown-field) as inputs.

---

## Principles

- **Ask, don't assume** — Every requirement must come from the developer or existing documentation
- **Profile before promising** — Data source profiling happens during Discovery, not Build
- **Brown-field: read first** — Never collect requirements for an existing system without understanding what exists
- **Platform-native first** — Feasibility is assessed against the client's approved stack, not ideal-world tooling
- **Traceable requirements** — Every requirement maps to a Jira Story with acceptance criteria
