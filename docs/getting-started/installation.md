# Installation Guide

## Prerequisites

- **Claude Code CLI** installed and authenticated (`claude --version` to verify)
- **Claude Code Enterprise** license (for managed settings and compliance features)
- **Git** 2.30+
- **macOS** (Apple Silicon or Intel) or **Linux** (Ubuntu 20.04+, RHEL 8+)
- **Python 3.11+** with `uv` package manager

## Quick Install

```bash
git clone https://github.com/your-org/cc-framework.git
cd cc-framework
./scripts/install.sh
```

This installs **Layer 1 (Core)** — universal engineering standards that apply to all projects.

## What Gets Installed

### Layer 1: Core (always installed)

| Source | Destination | Purpose |
|--------|-------------|---------|
| `core/CLAUDE.md` | `~/.claude/CLAUDE.md` | Global engineering standards |
| `core/CODING_STANDARDS.md` | `~/.claude/CODING_STANDARDS.md` | Full coding standards reference |
| `core/settings.json` | `~/.claude/settings.json` | Default permission rules |
| `core/rules/*.md` | `~/.claude/rules/` | Security, git, code review rules |
| `core/skills/*/` | `~/.claude/skills/` | Universal skills (format-and-lint, test-runner, etc.) |
| `core/agents/*.md` | `~/.claude/agents/` | Universal agents (framework-verifier, test-writer, etc.) |
| `core/tools/*.py` | `~/.claude/tools/` | CLI tools backing skills |

**Note:** The installer will **not overwrite** existing `CLAUDE.md` or `settings.json` files. If you have customizations, merge manually or use `--force` to replace.

### Layer 2: Domain Modules (optional)

Install domain-specific standards for your engineering discipline:

```bash
./scripts/install.sh --domain data-engineering
./scripts/install.sh --domain analytics
```

Available domains:
- `data-engineering` — Pipeline patterns, SQL standards, schema design, data quality
- `analytics` — Metric definitions, dashboard standards, BI patterns

### Layer 3: Platform Modules (optional)

Install cloud platform patterns and MCP server configurations:

```bash
./scripts/install.sh --platform gcp
```

Available platforms:
- `gcp` — BigQuery, Dataflow, Cloud Composer, Vertex AI, GCS patterns

Coming soon: `aws`, `azure`, `databricks`, `snowflake`

### Install Everything

```bash
./scripts/install.sh --all
```

Installs Core + all domain modules + all platform modules.

## Managed Settings (Enterprise)

For organization-wide policy enforcement, deploy managed settings to the system directory:

```bash
# macOS
sudo cp core/managed-settings.json /Library/Application\ Support/ClaudeCode/managed-settings.json

# Linux
sudo cp core/managed-settings.json /etc/claude-code/managed-settings.json
```

**Important:** Managed settings cannot be overridden by users. Use the `/client-onboard` skill to generate client-specific managed settings — do not edit the template directly.

## Verify Installation

```bash
./scripts/validate-setup.sh
```

This checks:
- Core files are in place
- Skills are registered and invocable
- Agents are loadable
- Rules have valid frontmatter
- Tools are executable
- Selected domain/platform modules are installed

## Post-Installation

### 1. Set Up Your First Engagement

If you're starting work with a new client, run the onboarding skill:

```
/client-onboard
```

This agentic workflow walks you through connecting to the client's tools (Jira, Confluence, cloud platform), capturing their EA patterns, and generating engagement-specific configuration. See [First Project](first-project.md) for details.

### 2. Start Your First Project

Once the engagement is configured, start a project:

```
/discovery
```

This launches the Discovery phase — green-field or brown-field — and produces standardized artifacts that feed into Design.

### 3. Daily Workflow

See `sops/daily-workflow.md` for the standard daily developer workflow with Claude Code and the framework.

## Updating

Pull the latest framework and re-install:

```bash
cd /path/to/cc-framework
git pull
./scripts/install.sh
```

Or use the update script:

```bash
./scripts/update.sh
```

## Uninstalling

The framework installs to `~/.claude/`. To remove:

```bash
# Remove framework-installed files (preserves your custom files)
./scripts/install.sh --uninstall
```

Or manually remove files from `~/.claude/skills/`, `~/.claude/agents/`, `~/.claude/rules/`, and `~/.claude/tools/`.

## Troubleshooting

### Skills not showing up

Skills require the `SKILL.md` file in the correct location:
```
~/.claude/skills/<skill-name>/SKILL.md
```

Verify with: `ls ~/.claude/skills/`

### Agents not available

Agents are markdown files in `~/.claude/agents/`:
```
~/.claude/agents/<agent-name>.md
```

Verify with: `ls ~/.claude/agents/`

### Permission errors on managed settings

Managed settings require elevated privileges (sudo) to install to the system directory. If you don't have sudo access, contact your IT administrator.

### MCP servers not connecting

MCP server configuration is project-specific (`.mcp.json` in project root). Verify:
1. The `.mcp.json` file exists in the project root
2. Authentication tokens/credentials are configured
3. Network connectivity to the service (Jira, Confluence, cloud APIs)
4. Run `claude mcp list` to check registered servers

### Conflicts with existing configuration

If you have existing `~/.claude/` configuration:
1. Back up your current files: `cp -r ~/.claude ~/.claude.backup`
2. Run the installer — it skips existing CLAUDE.md and settings.json
3. Manually merge any conflicting rules or skills
