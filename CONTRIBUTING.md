# Contributing to cc-framework

This framework is designed to grow through contributions from our engineering community.
Here's how to add new components.

---

## What You Can Contribute

| Component | Location | When to Add |
|-----------|----------|-------------|
| **Skill** | `core/skills/` or `domain/*/skills/` | Reusable workflow needed across projects |
| **Agent** | `core/agents/` or `domain/*/agents/` | Complex multi-step task requiring specialized reasoning |
| **Rule** | `core/rules/` or `domain/*/rules/` | Constraint that should always be enforced |
| **Platform Module** | `platform/[cloud]/` | New cloud platform support |
| **Domain Module** | `domain/[domain]/` | New domain specialization |
| **SOP** | `sops/` | Standard operating procedure for common workflows |
| **Playbook** | `docs/playbooks/` | Step-by-step guide for specific project types |

---

## Contribution Process

### 1. Check if it belongs here

Ask yourself:
- Is this reusable across multiple projects? (>60% of engagements) → **Core**
- Is this specific to a domain (data eng, analytics, ML)? → **Domain module**
- Is this specific to a cloud platform? → **Platform module**
- Is it specific to one client? → **Does NOT belong here** (keep in project `.claude/`)

### 2. Create a branch

```bash
git checkout -b feature/add-[component-name]
```

### 3. Write the component

Follow the patterns below for each component type.

### 4. Test locally

Install your changes locally and verify they work:
```bash
./scripts/install.sh
# Then test in a Claude Code session
```

### 5. Submit a PR

```bash
gh pr create --title "feat: add [component] skill/agent/rule" --body "..."
```

PR must include:
- Description of what the component does
- Which layer it belongs to and why
- Example usage
- How you tested it

---

## Component Patterns

### Skill Pattern

Skills go in `[layer]/skills/[skill-name]/SKILL.md`:

```markdown
---
name: skill-name
description: One-line description shown to users
version: 1.0.0
tools:
  tool_name: path/to/tool.py  # Optional: if skill uses a CLI tool
---

# skill-name

[What this skill does and when to use it]

## Usage

[How to invoke and common patterns]

## Workflow

[Step-by-step what the skill does]

## Output

[What artifacts it produces]

## Requirements

[What must be in place for this skill to work]
```

### Agent Pattern

Agents go in `[layer]/agents/[agent-name].md`:

```markdown
---
name: agent-name
description: What the agent does (shown when spawning)
tools: Read, Write, Grep, Glob  # Only tools this agent needs
model: sonnet  # or haiku for lightweight tasks
maxTurns: 15
---

[System prompt and detailed instructions for the agent]

## Process
1. Step-by-step workflow

## Output Format
What files/artifacts the agent produces

## Best Practices
What to always/never do

## Remember
Key principles
```

### Rule Pattern

Rules go in `[layer]/rules/[rule-name].md`:

```markdown
# Rule: [Name]

[What this rule enforces and why]

## Requirements

- Requirement 1
- Requirement 2

## Examples

### Correct
[Example of compliant code/behavior]

### Incorrect
[Example of non-compliant code/behavior]
```

### Platform Module Pattern

Platform modules go in `platform/[cloud]/`:

```
platform/[cloud]/
├── CLAUDE.md              # Platform-specific standards and patterns
├── mcp-config.json        # MCP server configuration template
├── skills/                # Platform-specific skills
├── rules/                 # Platform-specific rules
└── agents/                # Platform-specific agents (if needed)
```

---

## Layer Placement Guide

| Question | If Yes → |
|----------|----------|
| Does every engineer on every project need this? | `core/` |
| Is it specific to data engineering? | `domain/data-engineering/` |
| Is it specific to analytics/BI? | `domain/analytics/` |
| Is it specific to ML/Data Science? | `domain/ml-ds/` |
| Is it specific to full-stack data apps? | `domain/full-stack-data/` |
| Is it specific to AWS? | `platform/aws/` |
| Is it specific to Azure? | `platform/azure/` |
| Is it specific to GCP? | `platform/gcp/` |
| Is it specific to Databricks? | `platform/databricks/` |
| Is it specific to Snowflake? | `platform/snowflake/` |
| Is it a step-by-step procedure? | `sops/` |
| Is it a project-type guide? | `docs/playbooks/` |

---

## Promotion Pipeline

Sometimes you discover a useful pattern during a project. To promote it to the framework:

1. **Validate** — confirm it works reliably across at least 2 projects
2. **Generalize** — remove project-specific details
3. **Document** — write it in the appropriate pattern (skill/agent/rule)
4. **Submit PR** — include evidence of cross-project applicability
5. **Review** — framework maintainers review for quality and placement

### Strict Test (all must be true):
- Applicable to new projects from day 1?
- Validated through real-world use?
- Durable (not a workaround for a temporary issue)?
- Wanted by >60% of engineers?

---

## Code Style

- Markdown files: clear headers, concise prose, examples over theory
- Python tools: follow `core/CODING_STANDARDS.md` (black, ruff, mypy, pytest)
- Commit messages: `feat:`, `fix:`, `docs:`, `refactor:` prefixes
- Keep skills under 500 lines — split into sub-agents if larger
