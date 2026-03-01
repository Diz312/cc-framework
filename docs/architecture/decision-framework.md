# Decision Framework: Skills vs Agents vs Hooks vs Rules vs MCP

When extending the cc-framework, choosing the right extension mechanism is critical.
Each Claude Code mechanism serves a different purpose.

## Quick Reference

| Need | Use | Why |
|------|-----|-----|
| Repeatable developer workflow | **Skill** | Invokable, step-by-step, can call agents |
| Complex isolated reasoning task | **Agent** | Separate context, specialized tools, focused prompt |
| Persistent instruction/constraint | **Rule** | Always loaded, path-scoped, no invocation needed |
| Deterministic automation on lifecycle event | **Hook** | Runs on every commit/session/etc., no LLM needed |
| External tool/data connection | **MCP Server** | Bridges Claude Code to Jira, cloud APIs, databases |
| Global persistent context | **CLAUDE.md** | Loaded every session, universal instructions |
| Organization-wide policy enforcement | **Managed Settings** | Cannot be overridden by users |

## Decision Tree

```
Is this an external tool or data source connection?
  YES → MCP Server
  NO ↓

Should this run automatically on a lifecycle event (commit, session start/stop)?
  YES → Hook
  NO ↓

Is this an organization-wide policy that users must not override?
  YES → Managed Settings
  NO ↓

Is this a persistent instruction that should always be in context?
  YES → Is it path-scoped (only relevant for certain files)?
    YES → Rule (with globs)
    NO  → CLAUDE.md
  NO ↓

Is this a multi-step workflow a developer invokes?
  YES → Skill (may delegate to agents internally)
  NO ↓

Is this a focused, complex task that benefits from isolated context?
  YES → Agent
  NO → Consider if it belongs in CLAUDE.md or a Rule
```

## Detailed Comparison

### Skills (`~/.claude/skills/<name>/SKILL.md`)

**What:** Invocable workflows triggered by `/skill-name`. Contains step-by-step instructions that Claude Code follows.

**Use when:**
- A developer needs to invoke a repeatable workflow
- The workflow has multiple steps with decision points
- The workflow needs to orchestrate multiple agents
- Human-in-the-loop checkpoints are needed

**Examples in cc-framework:**
- `/discovery` — SDLC discovery phase orchestrator
- `/build` — Build phase with scaffolding, implementation, testing loop
- `/client-onboard` — Agentic engagement onboarding
- `/format-and-lint` — Code formatting and linting

**Do NOT use when:**
- The task is a single focused reasoning step (use Agent)
- The behavior should always be active (use Rule)
- The task is a deterministic script (use Hook)

### Agents (`~/.claude/agents/<name>.md`)

**What:** Isolated sub-agent definitions spawned via the Task tool. Run in separate context with specified tools.

**Use when:**
- The task requires deep, focused reasoning in isolation
- You want to protect the main context from noise
- The task needs specific tools (e.g., WebSearch for research)
- Multiple instances can run in parallel

**Examples in cc-framework:**
- `solution-architect` — Proposes EA-constrained architecture options
- `brownfield-analyzer` — Deep analysis of existing codebases
- `framework-verifier` — Verifies framework APIs before coding
- `test-writer` — Writes comprehensive test suites

**Do NOT use when:**
- The task needs back-and-forth with the developer (use Skill with HIL)
- The behavior should persist across sessions (use Rule)
- The task is simple enough for inline handling

### Rules (`~/.claude/rules/<name>.md`)

**What:** Persistent instruction files with YAML frontmatter. Always loaded into context when matching files are accessed.

**Use when:**
- Instructions should always be active (no invocation needed)
- Instructions are scoped to specific file types (e.g., `*.sql`, `*.py`)
- You're encoding constraints or standards
- The instructions are relatively concise

**Examples in cc-framework:**
- `security.md` — Security rules always enforced
- `git-workflow.md` — Git conventions always active
- `sql-standards.md` — SQL formatting rules for `*.sql` files
- `client-ea.md` — Client EA constraints

**Do NOT use when:**
- The rule needs complex multi-step execution (use Skill)
- The rule needs external data (use MCP + Rule combination)
- The content is too large for always-on context

### Hooks

**What:** Shell commands that execute deterministically on Claude Code lifecycle events (pre-commit, post-session, etc.).

**Use when:**
- You need deterministic behavior on every event (no LLM variance)
- The task is a shell command (formatting, linting, git operations)
- You need guaranteed execution (not "usually follows instructions")
- Speed matters (hooks run instantly, no LLM call)

**Examples:**
- Pre-commit: run `black` + `ruff` on staged files
- Post-session: clean up temporary files, prune worktrees
- Stop: send desktop notification

**Do NOT use when:**
- The task requires reasoning or judgment (use Skill/Agent)
- The task needs user interaction (use Skill with HIL)
- The behavior should be optional/invocable (use Skill)

### MCP Servers

**What:** External tool and data source connections that give Claude Code access to APIs, databases, and services.

**Use when:**
- Claude Code needs to interact with external systems
- You're connecting to Jira, Confluence, cloud platforms, databases
- The tool needs real-time data from an external source
- Authentication and authorization are handled by the MCP server

**Examples in cc-framework:**
- Atlassian MCP — Jira read/write, Confluence read/write
- GCP MCP — BigQuery, GCS, Vertex AI access
- AWS MCP — S3, Glue, Lambda access

**Do NOT use when:**
- The tool can be accessed via simple CLI/API calls (consider Bash permissions)
- The integration is one-time (use a script)
- The data is static (include in CLAUDE.md or rules)

### Managed Settings

**What:** Organization-wide JSON configuration deployed to the system directory. Cannot be overridden by users.

**Use when:**
- Policies must be enforced organization-wide
- Users should not be able to bypass certain restrictions
- You need to control permissions, hooks, or MCP servers centrally
- Compliance requires enforceable policies

**Examples:**
- Deny dangerous commands (`rm -rf`, `git push --force`)
- Restrict MCP server sources to approved marketplaces
- Prevent bypassing permission mode
- Enforce specific hooks on all sessions

**Do NOT use when:**
- The policy is per-project (use project settings.json)
- The policy is optional guidance (use rules)
- The setting should be user-customizable

## Layer Placement Guide

When adding a new component, determine which layer it belongs to:

| Question | Answer | Layer |
|----------|--------|-------|
| Does every engineer need this regardless of client or domain? | Yes | **Core (Layer 1)** |
| Is this specific to a discipline (data eng, analytics, ML)? | Yes | **Domain (Layer 2)** |
| Is this specific to a cloud platform (GCP, AWS, Azure)? | Yes | **Platform (Layer 3)** |
| Is this specific to one client engagement? | Yes | **Client (Layer 4)** |

When in doubt, start at a higher layer number (more specific) and promote upward as the pattern proves universal.
