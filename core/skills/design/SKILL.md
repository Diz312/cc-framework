---
name: design
description: SDLC Phase 2 — Solution architecture and technical design constrained by client EA patterns and platform-native principles.
version: 1.0.0
---

# Design Phase Orchestrator

Takes Discovery artifacts and produces a complete technical design. Every architecture decision
is cross-referenced against client EA patterns and industry best practices.

> **Prerequisite**: Discovery phase completed. Requires requirements spec, data source catalog,
> and gap analysis (if brown-field).

---

## Invocation

```
/design
```

The orchestrator begins by ingesting Discovery artifacts:

1. Read the Requirements Specification
2. Read the Data Source Catalog
3. Read the Gap Analysis (brown-field projects)
4. Read client EA patterns from Layer 2 config (engagement onboarding rules)

---

## Architecture Decision Process

For **every** significant architecture decision, follow this protocol:

### Decision Gate

```
1. Check: Does a client EA pattern exist for this decision?
   ├── YES → Propose options that HONOR the existing pattern
   │         - Explain how each option aligns with the EA precedent
   │         - Flag any deviations and justify them
   │         - Default recommendation follows the EA pattern
   └── NO  → Deep research required
             - WebSearch: industry best practices, platform-native options
             - WebFetch: official docs for candidate technologies
             - Propose 2-3 options with trade-off analysis
             - Apply platform-native first principle
             - Document as new ADR for future EA reference
```

### Trade-Off Analysis Format

For each option presented:

```markdown
### Option [N]: [Name]

**Description**: [What it is and how it works]

**Alignment**:
- EA Pattern: [Honors / Deviates — explain]
- Platform-Native: [Yes / Partial / No — explain]
- Approved Stack: [Within / Requires approval]

**Pros**:
- [pro 1]
- [pro 2]

**Cons**:
- [con 1]
- [con 2]

**Effort**: [S/M/L/XL]
**Risk**: [Low/Medium/High]
**Recommendation**: [Recommended / Acceptable / Not Recommended]
```

---

## Sub-Agents

The Design orchestrator spawns specialized sub-agents for each design domain.
Coordinate their outputs into a cohesive architecture.

### solution-architect

Responsible for overall system architecture:
- Component diagram (services, data stores, integrations)
- Communication patterns (sync/async, request-reply, event-driven)
- Deployment topology (regions, zones, scaling strategy)
- Security architecture (authN/authZ, encryption, network boundaries)
- Observability strategy (logging, metrics, tracing, alerting)

### schema-designer

Responsible for database and schema design:
- Logical data model (entities, relationships, cardinality)
- Physical schema (tables, columns, types, constraints, indexes)
- Partitioning strategy (if applicable)
- Schema evolution plan (migration strategy, backward compatibility)
- Naming conventions (per client standards or framework defaults)

### pipeline-architect

Responsible for data pipeline design:
- Pipeline topology (source → staging → transform → target)
- Orchestration pattern (scheduler, DAG structure, dependencies)
- Error handling strategy (retry, dead-letter, alerting)
- Data quality checkpoints (where validations run)
- Idempotency and reprocessing strategy
- Backfill plan

### data-modeler

Responsible for analytical data modeling:
- Dimensional model (facts, dimensions, grain)
- Slowly changing dimensions strategy
- Aggregation layers
- Semantic layer / metrics definitions
- Data catalog entries

---

## Artifacts

### 1. Solution Architecture Document

```markdown
# Solution Architecture: [Project Name]

## Overview
[1-paragraph summary of the solution]

## Context
- Business Objectives: [from requirements]
- Constraints: [from requirements + EA patterns]
- Key Decisions: [list ADR references]

## Architecture Diagram
[Component diagram — describe textually, note that a visual diagram should be created]

## Components
### [Component 1]
- Purpose: [what it does]
- Technology: [specific service/tool]
- Interfaces: [APIs, events, files]
- Scaling: [strategy]

### [Component 2]
...

## Data Flow
[End-to-end data flow from sources to consumers]

## Security
- Authentication: [method]
- Authorization: [method]
- Encryption: [at-rest, in-transit]
- Network: [VPC, firewall rules, private endpoints]

## Observability
- Logging: [where, format, retention]
- Metrics: [what, where, alerting thresholds]
- Tracing: [distributed tracing approach]

## Deployment
- Environment strategy: [dev/staging/prod]
- IaC approach: [Terraform/Pulumi/CDK]
- CI/CD: [pipeline design]
- Rollback strategy: [how to revert]

## Non-Functional Requirements
| Requirement | Target | How Achieved |
|---|---|---|
| Latency | [target] | [approach] |
| Throughput | [target] | [approach] |
| Availability | [target] | [approach] |
| Recovery | [RTO/RPO] | [approach] |
```

### 2. Architecture Decision Records (ADRs)

One ADR per significant decision:

```markdown
# ADR-[NNN]: [Decision Title]

**Status**: Proposed | Accepted | Deprecated | Superseded
**Date**: [date]
**Context**: [Why this decision is needed]
**Decision**: [What was decided]
**Consequences**: [What follows from this decision — both positive and negative]
**Alternatives Considered**: [Options that were rejected and why]
**EA Alignment**: [How this aligns with client EA patterns, or why it deviates]
```

### 3. Database Schema

- DDL scripts for all tables/collections
- Entity-relationship description
- Index strategy with justification
- Migration scripts (for brown-field)
- Seed data scripts (if applicable)

### 4. Pipeline Design

- DAG definition (tasks, dependencies, schedule)
- Transformation specifications (source → target mapping for each pipeline step)
- Data quality rules (per checkpoint)
- Error handling flows
- SLA definitions

### 5. API Design

- Endpoint inventory (method, path, purpose)
- Request/response schemas (with types)
- Authentication requirements per endpoint
- Rate limiting strategy
- Versioning strategy

### 6. IaC Plan

- Resource inventory (what needs to be provisioned)
- Module structure (how IaC is organized)
- Environment parameterization (what varies per env)
- State management approach
- Cost estimate

---

## Research Protocol

When no EA precedent exists and deep research is required:

1. **WebSearch**: `"[technology] best practices [year]"`, `"[platform] [service] vs [alternative]"`
2. **WebFetch**: Official documentation for candidate technologies
3. **Cross-reference**: Check against platform-native offerings first
4. Document findings in the ADR under "Alternatives Considered"

Research is mandatory for:
- Any technology not in the client's approved stack
- Any pattern not documented in client EA
- Any integration with external systems
- Any security-sensitive decision

---

## MCP Integrations

| MCP Server | Usage |
|---|---|
| **Jira** | Create Build-phase Stories from design (one Story per component/pipeline/schema). Link to Epic. Add design labels. |
| **Confluence** | Write Design Summary page. Attach architecture doc, ADRs, schema DDL, pipeline specs. Link to Discovery page. |

If Jira or Confluence MCP is not configured, produce artifacts as local markdown files and
instruct the developer to upload manually.

---

## Output Checklist

Before completing Design, verify all artifacts exist:

- [ ] Solution Architecture Document
- [ ] ADRs for every significant decision
- [ ] Database schema (DDL + ER description)
- [ ] Pipeline design (DAG + transformation specs)
- [ ] API design (endpoints + schemas)
- [ ] IaC plan (resource inventory + module structure)
- [ ] Jira Stories for Build phase created
- [ ] Confluence Design Summary page published

---

## Handoff to Build

Design is complete when:

1. All artifacts are produced and reviewed with the developer
2. ADRs are accepted (developer confirms decisions)
3. Jira Stories for Build phase exist with design references
4. Confluence page is published

Next phase: `/build` — pass the solution architecture doc, schema DDL, pipeline design,
and API design as inputs.

---

## Principles

- **EA patterns are guardrails, not prisons** — Honor existing patterns but propose deviations with justification when they serve the project better
- **Platform-native first** — Always prefer the client's cloud platform native services before introducing external tools
- **Research before recommending** — Never recommend a technology without verifying its current state via WebSearch/WebFetch
- **Decisions are traceable** — Every significant choice has an ADR that links back to requirements
- **Design for change** — Schema evolution, API versioning, and pipeline reprocessing are designed in, not bolted on
- **Cost-aware** — IaC plan includes cost estimates; architecture avoids over-engineering
