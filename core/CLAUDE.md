# CC-Framework: Global Engineering Standards

These instructions apply to every project and session. They represent our universal engineering
standards and are **immutable per client** (Layer 1 — Core).

---

## Behavior & Communication

- Concise, direct — no preamble, no padding, get to the point
- Experienced engineers — skip basic explanations
- No emojis unless explicitly requested
- Full autonomy to write files and run commands
- Only commit when explicitly asked
- Build per plan, functionality over polish (MVP first)

---

## Coding Standards

Full reference: `CODING_STANDARDS.md` in this framework — read this when starting any new
project or making technology decisions.

### Universal Python Stack
- Runtime: `uv` + `pyproject.toml`
- Format: `black` (line length 100)
- Lint: `ruff`
- Types: `mypy` (required, no exceptions)
- Tests: `pytest` (>70% coverage)
- Pre-commit: mandatory on all projects

### Multi-Language
Single source of truth: Python -> auto-generate TypeScript. Never duplicate type definitions.

---

## Core Principles

1. **Simplicity over abstraction** — build what's needed, refactor later
2. **Reusable tools first** — skills/agents/tools before main app code
3. **Platform-native first** — maximize use of client's cloud platform and native services before introducing external tools
4. **Single source of truth** — auto-generate, never duplicate
5. **Deterministic where possible** — LLM only for reasoning/creativity
6. **12-Factor App** — config in env, stateless processes, logs to stdout, dev/prod parity
7. **Agentic apps** — clear hierarchy, streaming updates, confidence scoring, cost tracking

---

## Code Accuracy Protocol

Before writing framework-specific code:
1. **WebSearch** — latest versions, breaking changes, best practices
2. **WebFetch** — official docs for specific APIs
3. Write with confidence

Stop and verify if: framework not used in 12+ months, writing auth/security from memory,
assuming default behavior, using specific method names without checking.

---

## Project Code Boundaries

**`.claude/`** = Claude Code tooling only (instructions, skills, agents, commands, scripts)
**`src/`** = Application code — agents, services, tools built as part of the app live here
**`docs/`** = Documentation

Golden rule: if the deployed app needs it, it does not go in `.claude/`.

---

## SDLC Phase Orchestration

This framework provides phase orchestrator skills for the full development lifecycle:

- `/discovery` — Requirements gathering (green-field) or current-state analysis + requirements (brown-field)
- `/design` — Solution architecture, constrained by client EA patterns
- `/build` — Implementation with coding standards enforcement
- `/test` — Comprehensive testing (unit, data quality, schema, security)
- `/deploy` — PR creation, CI/CD, ticket updates, documentation

Each orchestrator guides the developer through standardized workflows and produces
artifacts that feed into the next phase.

---

## Starting a New Engagement

1. Run `/client-onboard` to configure the framework for the client environment
2. This generates Layer 2+ configuration (managed-settings, CLAUDE.md overlay, rules, MCP config)
3. Layer 1 (this file) never changes per client

## Starting a New Project

1. Run `/discovery` to collect requirements and understand scope
2. Run `/design` to create solution architecture
3. Run `/build` to implement the solution
4. Run `/test` to validate everything
5. Run `/deploy` to ship it
