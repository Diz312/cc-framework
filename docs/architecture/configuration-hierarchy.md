# Configuration Hierarchy

How Claude Code resolves configuration across all sources, and how cc-framework maps to it.

## Claude Code Configuration Precedence

Claude Code loads configuration from multiple sources, with higher-precedence sources
overriding lower ones:

```
Highest Priority
  │
  ├── 1. Managed Settings (system directory)
  │      macOS: /Library/Application Support/ClaudeCode/managed-settings.json
  │      Linux: /etc/claude-code/managed-settings.json
  │      Cannot be overridden by users
  │
  ├── 2. CLI Arguments
  │      Per-invocation overrides
  │
  ├── 3. Local Settings (.claude/settings.local.json)
  │      Per-project, personal (gitignored)
  │
  ├── 4. Project Settings (.claude/settings.json)
  │      Per-project, shared (committed to git)
  │
  ├── 5. User Settings (~/.claude/settings.json)
  │      All projects for this user
  │
Lowest Priority
```

**Array settings** (permissions allow/deny, hooks) merge across all scopes.
**Deny rules** always take precedence over allow rules at any scope.

## CLAUDE.md Loading Order

Claude Code loads instruction files in this order (all are loaded, not overridden):

1. **Managed CLAUDE.md** — System directories (enterprise-enforced)
2. **`~/.claude/CLAUDE.md`** — User global instructions
3. **`CLAUDE.md`** or **`.claude/CLAUDE.md`** — Project root
4. **`CLAUDE.local.md`** — Project, personal (gitignored)
5. **`.claude/rules/*.md`** — Path-scoped rules (project-level)
6. **`~/.claude/rules/*.md`** — User-level rules
7. **Subdirectory `CLAUDE.md`** files — Loaded when accessing that directory

All files are concatenated into the agent's context. They don't override each other —
they accumulate. This is why rules should avoid contradicting higher layers.

## How cc-framework Maps to This

| Framework Layer | Claude Code Config | Installed To |
|-----------------|-------------------|--------------|
| **Layer 1: Core** | `managed-settings.json` + `~/.claude/CLAUDE.md` + `~/.claude/settings.json` + `~/.claude/rules/security.md` etc. | System dir + `~/.claude/` |
| **Layer 2: Domain** | `~/.claude/rules/domain-*.md` + `~/.claude/skills/*` + `~/.claude/agents/*` | `~/.claude/` |
| **Layer 3: Platform** | `~/.claude/rules/platform-*.md` + `~/.claude/skills/*` + project `.mcp.json` | `~/.claude/` + project |
| **Layer 4: Client** | `.claude/CLAUDE.md` + `.claude/settings.json` + `.claude/rules/*` + `.mcp.json` | Project directory |

## Extension Mechanisms Used

| Mechanism | What It Does | cc-framework Usage |
|-----------|-------------|-------------------|
| **CLAUDE.md** | Persistent context loaded every session | Core standards, client EA patterns |
| **Skills** | Invocable workflows (`/skill-name`) | Phase orchestrators, utility tools |
| **Agents** | Isolated sub-agent execution contexts | Solution architect, test writer, etc. |
| **MCP Servers** | External tool/data connections | Jira, Confluence, cloud platforms |
| **Hooks** | Deterministic scripts on lifecycle events | Pre-commit checks, post-session cleanup |
| **Rules** | Path-scoped instruction files | Security, git workflow, domain patterns |
| **Managed Settings** | Enterprise-enforced policies | Security baseline, permission denials |

## Managed Settings: Enterprise Controls

The `managed-settings.json` file provides organization-wide policy enforcement.
Key managed-only settings:

| Setting | Purpose |
|---------|---------|
| `allowManagedPermissionRulesOnly` | If true, users cannot add their own permission rules |
| `allowManagedHooksOnly` | If true, users cannot add their own hooks |
| `allowManagedMcpServersOnly` | If true, users cannot add their own MCP servers |
| `disableBypassPermissionsMode` | Prevent bypassing all permissions |
| `strictKnownMarketplaces` | Only allow plugins from approved marketplaces |
| `blockedMarketplaces` | Block specific plugin marketplaces |

In cc-framework, the `/client-onboard` skill generates the appropriate `managed-settings.json`
based on the client's security and compliance requirements.

## Permission Rules

Permissions use a deny > ask > allow evaluation order:

```json
{
  "permissions": {
    "deny": [
      "Bash(rm -rf *)",
      "Bash(git push --force*)"
    ],
    "allow": [
      "WebFetch",
      "WebSearch",
      "Bash(pytest *)",
      "Bash(black *)",
      "Bash(ruff *)"
    ]
  }
}
```

Pattern syntax supports wildcards: `Bash(npm run *)`, `Read(.env*)`, `WebFetch(domain:*.example.com)`.
