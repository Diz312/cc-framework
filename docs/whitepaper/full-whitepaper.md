# Policy-as-Code: Governing AI-Assisted Engineering at Enterprise Scale

**A Framework for Deploying AI Coding Assistants with Embedded Governance**

---

## 1. The Case for AI-Assisted Engineering

### Market Adoption

AI coding assistants have crossed the enterprise adoption threshold. Key data points:

- **90%** of engineering organizations now use AI in their development workflow (DORA 2025 State of DevOps)
- **72%** of enterprises report AI adoption across at least one business function (McKinsey 2024 Global Survey)
- **78%** of developers use AI coding tools at least weekly (GitHub 2024 Developer Survey)

The question is no longer whether to adopt AI-assisted engineering, but how to govern it.

### Productivity Evidence

Organizations with structured AI adoption report significant gains:

| Metric | Improvement | Source |
|--------|-------------|--------|
| Task completion rate | +21% | Faros AI 2025 |
| PR merge rate | +98% | Jellyfish 2025 |
| Cycle time reduction | -24% | Jellyfish 2025 |
| Code review turnaround | -40% | GitHub Copilot Enterprise data |
| Developer satisfaction | +15% NPS | Internal survey data |

### The Governance Gap

Despite rapid adoption, governance lags dramatically:

- **Only 20%** of companies have mature governance for AI agents (Deloitte 2026 Technology Trends)
- **67%** of organizations lack formal policies for AI-generated code (Gartner 2025)
- **DORA's central finding**: AI is an amplifier, not a fix — it magnifies existing strengths AND weaknesses equally

This gap creates real risks: inconsistent code quality, security vulnerabilities in generated code, compliance failures, and technical debt accumulation.

---

## 2. Why Policy-as-Code

### The Shift-Left Principle Applied to AI Governance

Traditional governance approaches — review boards, periodic audits, post-deployment checks — fail for AI-assisted development because:

1. **Volume**: AI increases code output velocity. Manual review cannot scale proportionally.
2. **Speed**: By the time a review board convenes, the code is deployed.
3. **Consistency**: Written guidelines are interpreted differently by different engineers (and by AI).
4. **Enforcement**: Policies in documents are advisory; policies in code are enforced.

Policy-as-code embeds governance rules directly into the AI assistant's configuration, ensuring they are applied on every interaction, not just when someone remembers to check.

### Industry Precedent

The policy-as-code approach aligns with established patterns:

**GitHub Copilot Enterprise** introduced a policy cascade model: organization policies override repository policies, which override user preferences. Admins can block specific patterns, enforce code review requirements, and restrict Copilot's access to sensitive repositories.

**Amazon Q Developer** uses a phased rollout model with IAM-based controls, allowing organizations to gate AI access by team, project, and security classification.

**Google Gemini Code Assist** leverages existing GCP IAM for access control and integrates with Cloud Audit Logs for traceability.

All three converge on the same principle: **the governance layer wraps the AI layer, not the other way around.**

### Alignment with Governance Frameworks

| Framework | Key Principle | How Policy-as-Code Implements It |
|-----------|--------------|----------------------------------|
| NIST AI RMF | "Govern" function: establish policies and processes | Managed settings enforce organizational policies |
| ISO 42001 | AI management system with continuous improvement | Layered rules with promotion pipeline (project → global) |
| McKinsey RAI | Embed responsible AI in workflow, not as afterthought | Rules and hooks enforce standards on every interaction |
| Gartner AI TRiSM | Trust, risk, and security management for AI | Security rules, audit trails, deny patterns, compliance API |

---

## 3. Our Framework: cc-framework

### Architecture: The Four-Layer Model

```
┌─────────────────────────────────────────────────────────┐
│  Layer 4: CLIENT / ENGAGEMENT                           │
│  Per-project configuration, client EA patterns,         │
│  Jira/Confluence integration, engagement SOPs           │
├─────────────────────────────────────────────────────────┤
│  Layer 3: PLATFORM                                      │
│  Cloud-specific patterns (GCP / AWS / Azure)            │
│  MCP server configurations, platform-native rules       │
├─────────────────────────────────────────────────────────┤
│  Layer 2: DOMAIN                                        │
│  Data engineering, analytics/BI, ML/DS, full-stack      │
│  Domain-specific standards, agents, rules               │
├─────────────────────────────────────────────────────────┤
│  Layer 1: CORE (universal, immutable per client)        │
│  Coding standards, security, testing, SDLC workflows,   │
│  managed settings, base permissions                     │
└─────────────────────────────────────────────────────────┘
```

**Design principles:**
- **Layers compose, not override**: A financial services client on Azure gets Core + Data Engineering + Azure + Client. A retail client on GCP gets Core + Analytics + GCP + Client.
- **Core is immutable**: Layer 1 represents organizational engineering standards. It does not change per client. Clients customize Layers 2-4.
- **Platform-native first**: Each engagement maximizes the client's existing cloud platform and native services before introducing external tools.
- **Open contribution**: Engineers can contribute new components and promote them through layers as patterns prove universal.

### Configuration Mechanisms

The framework leverages six Claude Code Enterprise extension points:

| Mechanism | Purpose | Enforcement Level |
|-----------|---------|-------------------|
| **Managed Settings** | Organization-wide policies | Cannot be overridden |
| **CLAUDE.md** | Persistent context and instructions | Always loaded |
| **Rules** | Path-scoped standards | Loaded when matching files accessed |
| **Skills** | Invocable multi-step workflows | Developer-triggered |
| **Agents** | Isolated reasoning tasks | Programmatically spawned |
| **Hooks** | Deterministic lifecycle automation | Automatic on events |

### SDLC Phase Coverage

The framework provides orchestrator skills for every SDLC phase:

**Discovery** — Standardized requirements gathering with green-field and brown-field paths. Brown-field projects get current-state analysis first (codebase, schemas, pipelines, technical debt), then requirements, then gap analysis.

**Design** — Architecture proposals constrained by client EA patterns. When EA precedent exists, proposals honor the pattern. When no precedent exists, the agent performs deep research and proposes 2-3 options with trade-offs.

**Build** — Implementation guidance with standards enforcement. Bottom-up order: data layer, business logic, API, orchestration, infrastructure. Framework verification before coding. Tests alongside code.

**Test** — Six-category testing: unit tests, data quality validations, schema compatibility, SQL best practices, security scans, integration tests. Deployment readiness checklist with mandatory gates.

**Deploy** — PR creation with standardized templates, CI/CD verification, Jira ticket updates, Confluence documentation, post-deploy health checks.

Each phase produces standardized artifacts consumed by the next, creating a traceable chain from requirements to deployment.

---

## 4. The Cornerstone: Agentic Onboarding

### The Problem with Manual Configuration

Traditional onboarding to a new client environment requires:
1. Reading hundreds of pages of EA documentation
2. Manually translating architecture patterns into configuration
3. Setting up tool integrations (Jira, Confluence, cloud platforms)
4. Configuring security policies and access controls
5. Documenting everything for the next engineer

This process takes days, is error-prone, and produces inconsistent results.

### The Agentic + Human-in-the-Loop Solution

`/client-onboard` is an agentic workflow that:

**Phase 1: Guided Knowledge Intake** — The agent walks the lead engineer through six structured steps, reading provided documents (Confluence pages, PDFs, uploaded files) at each step: Enterprise Architecture, Cloud Platform, Security & Compliance, Development Workflow, Data Governance, Atlassian Setup.

**Phase 2: Analysis & Synthesis** — The agent cross-references all inputs against framework standards, identifies alignment and divergence, determines platform modules needed, and maps the client's technology landscape.

**Phase 3: Proposal** — The agent presents a comprehensive configuration proposal: managed settings, CLAUDE.md overlay, rules, MCP configuration, module recommendations, and identified gaps.

**Phase 4: Review & Apply** — The lead engineer reviews each artifact, modifies as needed, and approves. The agent generates all files and commits an auditable record.

This reduces onboarding time from days to hours while improving consistency and completeness.

---

## 5. Implementation Approach

### Phased Rollout

**Phase 1: Pilot (Weeks 1-3)**
- Install framework on one team
- Run through one engagement with `/client-onboard`
- Complete one project Discovery-to-Deploy cycle
- Collect feedback, refine

**Phase 2: Scale (Weeks 4-8)**
- Roll out to additional teams
- Open contribution pipeline
- Add platform modules (AWS, Azure, Databricks, Snowflake)
- Measure productivity and quality metrics

**Phase 3: Optimize (Weeks 9+)**
- Analyze incident data and refine rules
- Promote proven patterns from client to core
- Publish community contributions
- Continuous improvement based on usage data

### The Test Pilot Model

Each new engagement is a "test pilot" for the framework:
- The lead engineer runs `/client-onboard` and reports gaps
- The team uses phase orchestrators and reports friction
- Issues become framework improvements
- Improvements benefit all future engagements

This creates a virtuous cycle where every engagement makes the framework better.

---

## 6. Expected Outcomes

### Quantified Benefits

| Category | Metric | Expected Impact |
|----------|--------|-----------------|
| **Productivity** | Task completion | +21% (DORA/Faros) |
| **Velocity** | PR merge rate | +98% (Jellyfish) |
| **Speed** | Cycle time | -24% (Jellyfish) |
| **Onboarding** | Engagement setup time | -60% (vs. manual) |
| **Quality** | Security incidents from AI code | Near-zero with deny rules |
| **Consistency** | Cross-engagement standards adherence | 100% (enforced by Core layer) |
| **Governance** | Audit trail completeness | 100% (Claude Code Enterprise logs) |

### Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| AI generates insecure code | Security rules + deny patterns + managed settings |
| AI uses wrong framework APIs | framework-verifier agent validates before coding |
| AI ignores client EA patterns | Rules auto-generated from client docs during onboarding |
| AI produces inconsistent quality | Universal Core layer enforces standards organization-wide |
| Compliance violations | Managed settings enforce regulatory controls; 180-day audit logs |
| Knowledge loss between engagements | Standardized artifacts and version-controlled configuration |

### Competitive Advantage

Organizations with embedded AI governance will:
1. **Win more deals**: Clients increasingly require AI governance policies in RFPs
2. **Deliver faster**: Standardized workflows reduce ramp-up time per engagement
3. **Scale better**: New engineers are productive faster with framework guardrails
4. **Reduce risk**: Fewer incidents, better compliance, auditable processes
5. **Attract talent**: Engineers prefer working with well-governed, productive tools

---

## 7. Conclusion

The AI-assisted engineering revolution is here. The organizations that thrive will not be those that adopt AI fastest, but those that govern it best. Policy-as-code transforms AI governance from a compliance checkbox into a competitive advantage — embedded in every interaction, enforced automatically, and improving continuously.

cc-framework provides the architecture, tools, and workflows to make this happen. Starting today.

---

## Appendix

### A. Research Sources

- DORA 2025 State of DevOps Report — "AI is an amplifier"
- Deloitte 2026 Technology Trends — AI agent governance maturity
- McKinsey 2024 Global AI Survey — Enterprise adoption rates
- Faros AI 2025 — AI impact on engineering productivity
- Jellyfish 2025 — AI impact on cycle time and merge rates
- NIST AI Risk Management Framework (AI RMF)
- ISO/IEC 42001 — AI Management Systems
- Gartner AI TRiSM 2025 — Trust, Risk, Security Management
- GitHub Copilot Enterprise Documentation — Policy cascade model
- Claude Code Enterprise Documentation — Managed settings, compliance API

### B. Framework Component Catalog

**Skills (10):** client-onboard, discovery, design, build, test, deploy, format-and-lint, test-runner, code-review, security-scan

**Agents (8):** solution-architect, requirements-collector, brownfield-analyzer, framework-verifier, test-writer, schema-designer, pipeline-architect, data-modeler, metric-definer

**Rules (6+):** security, git-workflow, code-review, sql-standards, pipeline-patterns, gcp-best-practices (+ client EA rules per engagement)

**Platform Modules:** GCP (available), AWS/Azure/Databricks/Snowflake (roadmap)

**Domain Modules:** Data Engineering, Analytics/BI (available), ML/DS, Full-Stack Data (roadmap)

### C. Technology Stack

- **Claude Code Enterprise** — AI assistant platform
- **Claude Code Managed Settings** — Policy enforcement
- **Model Context Protocol (MCP)** — External tool integration
- **Atlassian MCP** — Jira + Confluence integration
- **Cloud Platform MCPs** — GCP/AWS/Azure native access
- **Python + uv** — Primary development runtime
- **Git + GitHub** — Version control and collaboration
