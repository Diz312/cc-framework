# cc-framework — Working on This Repo

This is the **framework development repo**, not a project that uses the framework.
`core/CLAUDE.md` is the Layer 1 artifact that ships to engineers — do not confuse it with this file.

---

## What This Is

Policy-as-code governance layer for Claude Code Enterprise. Embeds engineering standards,
SDLC best practices, and security policies into Claude Code artifacts (skills, agents, rules,
managed settings) for tech services teams delivering data platforms across multiple clients.

Four-layer cascade: Core → Domain → Platform → Client (per-engagement, auto-generated).

---

## Repo Map

```
core/           Layer 1 — universal, immutable per client
  CLAUDE.md         → ships to ~/.claude/ as global standard
  CODING_STANDARDS.md
  skills/           → /discovery /design /build /test /deploy /client-onboard /whitepaper
  agents/           → solution-architect, requirements-collector, brownfield-analyzer,
                      framework-verifier, test-writer
  rules/            → security.md, git-workflow.md, code-review.md
  tools/            → format_lint.py, run_tests.py, render_whitepaper.py

domain/         Layer 2 — discipline-specific
  data-engineering/ → CLAUDE.md, agents (schema-designer, pipeline-architect, data-modeler),
                      rules (sql-standards, pipeline-patterns)
  analytics/        → CLAUDE.md, agents (metric-definer), rules (analytics-patterns)
  full-stack-data/  → agents (api-integrator)
  ml-ds/            → PLANNED

platform/       Layer 3 — cloud-specific
  gcp/              → DONE: CLAUDE.md (BigQuery, Dataflow, Composer, Pub/Sub, Vertex AI, IAM),
                      rules, mcp-config.json
  aws/              → PLANNED
  azure/            → PLANNED
  databricks/       → PLANNED
  snowflake/        → PLANNED

client/         Layer 4 templates — scaffolding for /client-onboard output
scripts/        install.sh, new-engagement.sh, update.sh, validate-setup.sh
sops/           Standard Operating Procedures
docs/
  whitepaper/   executive-summary.md/.pdf, full-whitepaper.md/.pdf
  architecture/ four-layer-model.md, configuration-hierarchy.md, decision-framework.md
  getting-started/ installation.md, first-project.md
```

---

## MVP Status

### Done
- All 5 SDLC phase skills: `/discovery`, `/design`, `/build`, `/test`, `/deploy`
- Utility skills: `/format-and-lint`, `/test-runner`, `/whitepaper`
- Client onboarding: `/client-onboard`
- Core agents: 5 (solution-architect, requirements-collector, brownfield-analyzer, framework-verifier, test-writer)
- Domain: data-engineering (3 agents + 2 rules), analytics (1 agent + 1 rule), full-stack-data (1 agent)
- Platform: GCP (comprehensive — BigQuery, Dataflow, Composer, Cloud Storage, Pub/Sub, Vertex AI, IAM, cost)
- Tools: format_lint.py, run_tests.py, render_whitepaper.py (WeasyPrint + custom fonts)
- Docs: whitepaper (executive-summary + full, PDF rendered), architecture docs, getting-started
- Scripts: install.sh, new-engagement.sh, update.sh, deploy-managed-settings.sh, validate-setup.sh
- SOPs: 6 standard operating procedures

### Planned
- Platforms: AWS, Azure, Databricks, Snowflake
- Domain: ml-ds
- Hooks: pre-tool-use and post-tool-use for standards enforcement
- Promotion pipeline: pattern discovered in project → promoted to domain/platform layer
- Example client configs in client/examples/

---

## Conventions for This Repo

### Adding a Skill
1. Create `core/skills/<name>/SKILL.md`
2. Add backing tool to `core/tools/` if needed
3. Register in `core/CLAUDE.md` SDLC section
4. Update README.md skills table
5. Add SOP if operational guidance needed

### Adding an Agent
1. Create `core/agents/<name>.md` (core) or `domain/<d>/agents/<name>.md` (domain-specific)
2. Follow agent definition format: role, trigger, inputs, outputs, tools, model
3. Register in skill that spawns it (SKILL.md)
4. Update README.md agents table

### Adding a Platform Module
1. Create `platform/<name>/CLAUDE.md` — patterns, naming conventions, cost management
2. Create `platform/<name>/rules/<name>-best-practices.md` — always-on guardrails
3. Create `platform/<name>/mcp-config.json` if MCP integration available
4. Update README.md platform table
5. Update `scripts/new-engagement.sh` to support platform selection

### Adding a Domain Module
1. Create `domain/<name>/CLAUDE.md` — discipline-specific standards
2. Add `domain/<name>/agents/` and `domain/<name>/rules/` as needed
3. Update README.md domain table

---

## Key Commands (working on this repo)

```bash
# Install framework locally to test
./scripts/install.sh

# Validate installation
./scripts/validate-setup.sh

# Re-render whitepapers
python core/tools/render_whitepaper.py docs/whitepaper/executive-summary.md \
  --output docs/whitepaper/executive-summary.pdf
python core/tools/render_whitepaper.py docs/whitepaper/full-whitepaper.md \
  --output docs/whitepaper/full-whitepaper.pdf
```

---

## Deployment

- **Global**: `scripts/install.sh` copies `core/` to `~/.claude/` — shared across all projects
- **Per-engagement**: `/client-onboard` generates `.claude/` in project repo with Layers 2-4
- **Enterprise**: `managed-settings.json` deployed via `scripts/deploy-managed-settings.sh`
