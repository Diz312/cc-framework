# cc-framework

**Policy-as-Code Framework for Claude Code Enterprise**

A four-layer configuration framework that codifies engineering standards and SDLC best practices
into Claude Code artifacts — skills, agents, MCP servers, hooks, rules, and managed settings.

Built for tech services teams delivering data platforms and data products across multiple clients
on AWS, GCP, Azure, Databricks, and Snowflake.

---

## Architecture: The Four-Layer Model

```
┌─────────────────────────────────────────────────────────┐
│  Layer 4: CLIENT / ENGAGEMENT                           │
│  Per-project .claude/ directory                         │
│  Client EA patterns, Jira/Confluence config, SOPs       │
├─────────────────────────────────────────────────────────┤
│  Layer 3: PLATFORM                                      │
│  Installable modules (opt-in per engagement)            │
│  AWS / Azure / GCP / Databricks / Snowflake             │
├─────────────────────────────────────────────────────────┤
│  Layer 2: DOMAIN                                        │
│  Data engineering, analytics, ML/DS, full-stack data    │
│  Data quality, pipeline patterns, schema design         │
├─────────────────────────────────────────────────────────┤
│  Layer 1: CORE (universal, immutable per client)        │
│  Coding standards, SDLC orchestrators, testing,         │
│  formatting, security, governance                       │
└─────────────────────────────────────────────────────────┘
```

**Layer 1 (Core)** never changes per client — it represents our engineering standards.
**Layers 2-4** are configured per engagement via the `/client-onboard` skill.

---

## Quick Start

### 1. Install the framework

```bash
git clone https://github.com/YOUR_ORG/cc-framework.git
cd cc-framework
./scripts/install.sh
```

### 2. Onboard to a new client

```bash
# In Claude Code, run:
/client-onboard
```

This walks you through a structured Q&A to configure the framework for the client's
environment (EA patterns, cloud platform, security, Jira/Confluence, data governance).

### 3. Start a project

```bash
/discovery    # Collect requirements (green-field or brown-field)
/design       # Create solution architecture
/build        # Implement the solution
/test         # Comprehensive testing
/deploy       # Ship it
```

---

## What's Included

### SDLC Phase Orchestrators (Skills)
| Skill | Phase | Purpose |
|-------|-------|---------|
| `/client-onboard` | Pre-project | Configure framework for client environment |
| `/discovery` | Discovery | Requirements gathering, current-state analysis |
| `/design` | Design | Solution architecture, constrained by EA |
| `/build` | Build | Implementation with standards enforcement |
| `/test` | Test | Unit, data quality, schema, security testing |
| `/deploy` | Deploy | PR creation, CI/CD, ticket updates |

### Utility Skills
| Skill | Purpose |
|-------|---------|
| `/format-and-lint` | Python code formatting (black, ruff, mypy) |
| `/test-runner` | pytest with coverage reporting |

### Agents (Sub-agents for complex tasks)
| Agent | Purpose |
|-------|---------|
| `solution-architect` | Propose architecture options (EA-aware, research-backed) |
| `requirements-collector` | Standardized requirements gathering |
| `brownfield-analyzer` | Current-state analysis for existing systems |
| `framework-verifier` | Verify framework APIs before coding |
| `test-writer` | Write comprehensive pytest suites |
| `schema-designer` | Database schema design (Domain: data-engineering) |
| `api-integrator` | FastAPI REST API builder (Domain: full-stack-data) |

### Rules (Always-on constraints)
| Rule | Scope |
|------|-------|
| `security.md` | Security patterns, secrets handling, OWASP |
| `git-workflow.md` | Branching, commits, PR standards |
| `code-review.md` | Review checklist and standards |

### Platform Modules (Layer 3)
| Platform | Status |
|----------|--------|
| GCP | MVP |
| AWS | Planned |
| Azure | Planned |
| Databricks | Planned |
| Snowflake | Planned |

### Domain Modules (Layer 2)
| Domain | Status |
|--------|--------|
| Data Engineering | MVP |
| Analytics/BI | MVP |
| ML/Data Science | Planned |
| Full-Stack Data | Planned |

---

## Repository Structure

```
cc-framework/
├── core/                    # Layer 1: Universal (immutable per client)
│   ├── CLAUDE.md            # Global engineering standards
│   ├── CODING_STANDARDS.md  # Authoritative coding standards
│   ├── settings.json        # Default permissions
│   ├── skills/              # Phase orchestrators + utility skills
│   ├── agents/              # Universal sub-agents
│   ├── rules/               # Always-on constraints
│   └── tools/               # CLI tools backing skills
├── domain/                  # Layer 2: Domain-specific
│   ├── data-engineering/    # Data engineering standards
│   ├── analytics/           # Analytics/BI standards
│   ├── ml-ds/               # ML/Data Science standards
│   └── full-stack-data/     # Full-stack data app standards
├── platform/                # Layer 3: Cloud platform modules
│   ├── aws/
│   ├── azure/
│   ├── gcp/
│   ├── databricks/
│   └── snowflake/
├── client/                  # Layer 4: Engagement templates
│   ├── templates/           # Scaffolding templates
│   ├── examples/            # Example client setups
│   └── onboarding/          # Onboarding guides
├── scripts/                 # Installation and management
├── sops/                    # Standard Operating Procedures
└── docs/                    # Documentation
    ├── getting-started/
    ├── architecture/
    ├── sdlc/
    ├── playbooks/
    ├── reference/
    └── whitepaper/
```

---

## Key Principles

1. **Layer 1 is immutable** — Core engineering standards never change per client
2. **Platform-native first** — Maximize client's cloud platform before external tools
3. **Agentic + HIL** — Agents propose, humans approve
4. **Green-field / brown-field aware** — Discovery adapts to project context
5. **EA-constrained design** — Architecture honors client enterprise patterns
6. **Standardized artifacts** — Each phase produces artifacts feeding the next
7. **Auditable** — All engagement configuration is version-controlled

---

## Research Backing

This framework's design is informed by:
- **DORA 2025**: "AI is an amplifier, not a fix" — governance must precede AI tooling
- **NIST AI RMF**: Embed governance in workflow, not bolted on
- **ISO 42001**: International standard for AI management systems
- **GitHub Copilot Enterprise**: Policy cascade pattern (Enterprise > Org > User)
- **Deloitte 2026**: Only 1 in 5 companies have mature AI agent governance
- **KPMG Data Product Lifecycle**: Standardized phases for data product delivery

See `docs/whitepaper/` for the full research-backed analysis.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add skills, agents, platform modules,
and domain extensions.

---

## License

Internal use. See LICENSE for details.
