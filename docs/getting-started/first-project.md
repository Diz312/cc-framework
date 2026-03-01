# First Project Guide

This guide walks you through starting your first project using the cc-framework, from engagement onboarding through to your first deployment.

## Before You Start

Ensure:
- [ ] cc-framework is installed (`./scripts/validate-setup.sh` passes)
- [ ] You have access to the client's Jira and Confluence instances
- [ ] You have access to the client's cloud platform (GCP/AWS/Azure)
- [ ] You have gathered or have access to client EA documentation

## Step 1: Engagement Onboarding (First Time Per Client)

If this is a new client engagement, run the onboarding skill first:

```
/client-onboard
```

### What Happens

The onboarding agent walks you through a structured knowledge intake process:

1. **Enterprise Architecture** — Provide links to or upload the client's EA docs (reference architectures, approved technologies, patterns). The agent reads and extracts architecture constraints.

2. **Cloud Platform & Infrastructure** — Share cloud account structure, project layout, FinOps docs. The agent maps the cloud topology and naming conventions.

3. **Security & Compliance** — Provide security policies, data classification schemes, compliance requirements. The agent extracts handling rules and access patterns.

4. **Development Workflow** — Share branching strategy, CI/CD pipeline docs, code review process. The agent captures coding conventions and workflow gates.

5. **Data Governance** — Provide data governance policies, quality standards, lineage requirements. The agent extracts data quality rules and PII handling patterns.

6. **Atlassian Setup** — Provide Jira instance URL, project keys, Confluence space URLs. The agent tests connectivity and maps project structure.

### What You Get

After analysis, the agent proposes:
- **managed-settings.json** — Organization-wide policies tailored to this client
- **CLAUDE.md overlay** — Project instructions with EA patterns embedded
- **rules/** — Client-specific rules with justification tied to their docs
- **.mcp.json** — MCP server configuration for their tools
- **Recommended modules** — Which domain and platform modules to install

Review each artifact, request changes if needed, then approve. The agent commits an `engagement-config.md` audit trail.

### If Onboarding Is Already Done

Skip to Step 2. The engagement configuration persists in the project's `.claude/` directory.

## Step 2: Project Discovery

Every project starts with Discovery. This is different from engagement onboarding — Discovery is per-project and focuses on understanding what you're building.

```
/discovery
```

### The First Question

The agent asks: **Is this a green-field or brown-field project?**

### Green-Field Path (Building New)

For projects where you're building from scratch:

1. **Requirements Collection** — The agent walks you through stakeholders, business objectives, data sources, consumers, SLAs, constraints. Uses the `requirements-collector` agent.

2. **Data Source Inventory** — Catalog all data sources: formats, volumes, freshness, owners, access patterns.

3. **Feasibility Assessment** — The agent cross-references requirements against the client's approved tech stack (from onboarding) and assesses feasibility.

**Artifacts produced:**
- Requirements specification (structured, machine-readable)
- Data source catalog
- Feasibility report
- Jira Epic + Stories created from requirements
- Confluence Discovery Summary page

### Brown-Field Path (Extending Existing)

For projects extending or integrating with existing systems:

1. **Current-State Analysis** — The `brownfield-analyzer` agent reads the existing codebase, schemas, pipelines, data flows, infrastructure, and runbooks. Produces a comprehensive as-is assessment. **This happens FIRST.**

2. **Requirements Collection** — Same standardized process as green-field, but informed by the current-state assessment.

3. **Gap Analysis** — What exists vs. what's needed. Technical debt assessment. Integration points. Categorized as Extend/Replace/New/Retire.

**Artifacts produced:**
- Current-state assessment (as-is)
- Technical debt report
- Integration point map
- Requirements specification
- Gap analysis
- Jira Epic + Stories
- Confluence Discovery Summary page

## Step 3: Design

With Discovery artifacts in hand:

```
/design
```

The Design phase proposes solution architecture constrained by client EA patterns:

1. **Ingest Discovery artifacts** — Requirements, data source catalog, gap analysis
2. **Cross-reference EA patterns** — From engagement onboarding
3. **Architecture decisions** — For each decision:
   - EA precedent exists: propose options honoring the pattern
   - No precedent: deep research on industry best practices, propose 2-3 options with trade-offs
4. **Present proposals** — Review and select architecture options
5. **Generate design artifacts** — Architecture doc, ADRs, schemas, pipeline design

**Artifacts produced:**
- Solution architecture document
- Architecture Decision Records (ADRs)
- Database schema design (DDL)
- Pipeline design (DAG, transformations)
- API design (if applicable)
- Jira Stories for Build phase
- Confluence Design Summary page

## Step 4: Build

With Design artifacts approved:

```
/build
```

The Build phase guides implementation in priority order:

1. **Data layer** — Database schemas, migrations, models
2. **Business logic** — Core transformations, validations, business rules
3. **API layer** — REST endpoints, serialization, authentication
4. **Orchestration** — Pipeline DAGs, scheduling, monitoring
5. **Infrastructure** — IaC (Terraform/Pulumi), deployment configs

For each module: verify APIs (framework-verifier) → implement → format/lint → write tests → run tests → update Jira.

## Step 5: Test

Before deployment:

```
/test
```

Runs six test categories in order:
1. Unit tests (pytest with coverage)
2. Data quality validations (Great Expectations / dbt)
3. Schema validation (backward compatibility)
4. SQL best practices review
5. Security vulnerability scan
6. Integration tests

Produces a deployment readiness checklist. All mandatory items must pass before proceeding.

## Step 6: Deploy

When tests pass:

```
/deploy
```

Handles:
1. PR creation with standardized template (linked to design docs and test reports)
2. CI/CD pipeline verification
3. Jira ticket updates (link PRs, transition status)
4. Confluence documentation updates
5. Post-deploy verification (health checks, smoke tests)

## Summary: The Full Flow

```
/client-onboard     →  One-time per client engagement
    ↓
/discovery          →  Per project (green-field or brown-field)
    ↓
/design             →  Architecture proposals, EA-constrained
    ↓
/build              →  Implementation with standards enforcement
    ↓
/test               →  Comprehensive test suite
    ↓
/deploy             →  PR, CI/CD, Jira updates, deploy
```

Each phase produces standardized artifacts consumed by the next. All artifacts are tracked in Jira and documented in Confluence.

## Tips for Your First Project

1. **Start small.** Pick a well-scoped project for your first run-through.
2. **Don't skip Discovery.** Even if you "know what to build," the structured artifacts catch gaps.
3. **Review agent proposals carefully.** The framework proposes; you decide.
4. **Use the SOPs.** `sops/daily-workflow.md` has the daily development rhythm.
5. **Feed back improvements.** If a rule or agent needs tuning, update it. See `sops/contributing-new-skill.md`.
