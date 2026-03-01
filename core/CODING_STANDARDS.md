# Universal Coding Standards & Preferences

**Purpose**: This file contains universal coding standards, tooling decisions, and architectural patterns that apply to all projects where Claude Code is used. These preferences were established and validated through real-world implementation.

**Last Updated**: 2026-02-14

---

## Core Principles

### 1. Simplicity Over Abstraction
- Build what's needed, refactor later
- Three similar lines > premature abstraction
- Direct, readable code over clever code
- Flat structure > deep nesting
- Only add features when explicitly needed

### 2. Build Reusable Tools First
- Create custom skills/agents before main application
- Design for reusability (60-95% across projects)
- Well-documented tools accelerate future development
- Test tools in isolation before integration

### 3. Local-First Architecture
- SQLite for development (single file, easy backup)
- All files stored locally initially
- Offline-first: app works without internet
- Clear migration path to cloud/PostgreSQL for production

### 4. Single Source of Truth
- One authoritative location for each concern
- Auto-generate downstream artifacts (types, configs, docs)
- Validate synchronization automatically
- Never manually duplicate what can be generated

### 5. Deterministic Where Possible
- Use LLM agents ONLY for reasoning/creativity
- Deterministic workflows for reproducible operations
- Clear agent hierarchy prevents chaos
- Reserve AI for tasks truly requiring intelligence

---

## Claude Code Tooling Organization

### Purpose of `.claude/` Folder

**CRITICAL**: The `.claude/` folder is ONLY for Claude Code development tooling - tools that help Claude Code (the AI assistant) develop applications more effectively.

**`.claude/` folder = Claude Code tooling** (universal tools for development)
**`src/` folder = Application code** (the application's own agents, services, logic)
**`docs/` folder = Documentation** (reference material, domain knowledge)

### What Goes in `.claude/`

#### Universal Location: `~/.claude/`
Tools available across ALL projects:

**Skills** (`~/.claude/skills/`):
- Repeated operations Claude Code performs during development
- Examples: test-runner, format-and-lint, db-inspector, type-sync-validator
- Invoked with the Skill tool
- Python scripts with CLI interfaces

**Sub-Agents** (`~/.claude/agents/`):
- Complex isolated tasks Claude Code delegates
- Examples: framework-verifier, schema-designer, test-writer, api-integrator
- Spawned with the Task tool
- Markdown files with agent definitions

**Standards** (`~/.claude/`):
- CODING_STANDARDS.md - This file
- MEMORY.md - Quick reference loaded at startup
- QUICK_REFERENCE.md - Rapid lookup

#### Project-Specific: `ProjectName/.claude/`
**ONLY use for project-specific Claude Code tooling** (rare):
- Custom skills specific to one project's development workflow
- Custom sub-agents for specialized development tasks
- Project-specific Claude Code configuration

**NEVER put application code here** - that goes in `src/`

### What Does NOT Go in `.claude/`

❌ **Application agents** (Google ADK, LangChain, etc.) → Goes in `src/backend/agents/`
❌ **Application services** → Goes in `src/backend/services/`
❌ **Domain knowledge documentation** → Goes in `docs/`
❌ **Application utilities** → Goes in `src/backend/utils/`
❌ **Configuration for the application** → Goes in project root or `config/`

### Example: Electronics Knowledge

**WRONG** ❌:
```
.claude/agents/electronics-researcher.md  # This looks like Claude Code tooling but it's for the app
```

**CORRECT** ✅:
```
docs/ELECTRONICS_REFERENCE.md             # Domain knowledge documentation
src/backend/agents/schematic_analyzer.py  # Application agent that USES the documentation
src/backend/agents/context/              # Context files for Google ADK agents
```

### When to Create Claude Code Tools

Create tools in `.claude/` when:
- ✅ Claude Code will use it during development (testing, linting, validation)
- ✅ It's reusable across multiple projects
- ✅ It accelerates development workflow
- ✅ It isolates complex research/design tasks

Don't create tools in `.claude/` when:
- ❌ It's part of the application's runtime functionality
- ❌ It's domain knowledge (use `docs/` instead)
- ❌ It's a one-time script (put in `scripts/`)
- ❌ The application's agents will use it (put in `src/`)

### Separation Checklist

Before adding anything to `.claude/`, ask:
- [ ] Is this for Claude Code to use during development, or for the application to use at runtime?
- [ ] If I remove `.claude/` entirely, would the application still work? (It should!)
- [ ] Is this documentation/reference material? (Use `docs/` instead)
- [ ] Is this a service the application needs? (Use `src/` instead)

**Golden Rule**: If the deployed application needs it, it doesn't go in `.claude/`

---

## Code Accuracy Protocol: Zero-Hallucination Development

### Principle

**CRITICAL**: Never write code based solely on training data (cutoff: January 2025). Always verify current best practices, API signatures, and framework patterns before implementation.

### Simple Verification Process

Claude Code has **built-in WebSearch and WebFetch tools** - use them!

**Before writing ANY framework-specific code:**

1. **WebSearch** - Verify latest framework versions, breaking changes, best practices
2. **WebFetch** - Access official documentation for specific API signatures
3. **Document** - Add inline comment with verification source and date
4. **Write** - Code with confidence

**That's it.** No external APIs needed. No setup required.

### Documentation Pattern

Always document your verification:

```python
# Verified: 2026-02-14 via WebFetch https://fastapi.tiangolo.com/tutorial/dependencies/
# FastAPI 0.109+ uses Depends() for dependency injection
@app.get("/items/")
async def read_items(commons: dict = Depends(common_parameters)):
    return commons
```

```typescript
// Verified: 2026-02-14 via WebFetch https://nextjs.org/docs/app/building-your-application/data-fetching
// Next.js 15 uses async Server Components by default
export default async function Page() {
  const data = await fetch('https://api.example.com/data')
  return <div>{data}</div>
}
```

### Verification Checklist

**Before Implementing a Framework Feature:**
- [ ] WebSearch: `"[Framework] [version] [feature] best practices 2026"`
- [ ] WebFetch: Official docs page for that specific feature
- [ ] Check for deprecation warnings or migration guides
- [ ] Verify import paths and method signatures
- [ ] Document verification date and source URL

**Before Using a Third-Party Library:**
- [ ] WebSearch: `"[Library] latest version breaking changes 2026"`
- [ ] Check npm/PyPI for current version number
- [ ] Review changelog for versions since training cutoff
- [ ] Verify installation command matches current version

**Before Implementing Auth/Security:**
- [ ] **NEVER implement from memory alone** - security is critical
- [ ] WebFetch: Official security documentation
- [ ] Verify current OWASP recommendations
- [ ] Check for known vulnerabilities in approach

### Example Verification Workflow

**Scenario**: Implementing Next.js 15 API route with FastAPI backend

```bash
# Step 1: Verify Next.js 15 route handler syntax
WebSearch: "Next.js 15 route handlers app directory 2026"
WebFetch: https://nextjs.org/docs/app/building-your-application/routing/route-handlers

# Step 2: Verify FastAPI CORS setup
WebSearch: "FastAPI CORS configuration 2026 best practices"
WebFetch: https://fastapi.tiangolo.com/tutorial/cors/

# Step 3: Implement with documented sources
# [Write code with inline comments citing verification sources]

# Step 4: Test immediately
# [Run code to confirm it works as expected]
```

### Red Flags: When to STOP and Verify

🚨 **Immediate verification required if:**

- Writing code for a framework/library you haven't used in 12+ months
- Using specific method names without checking current API docs
- Implementing security/auth patterns from memory
- Making assumptions about default behavior
- Copying patterns from training data without verification
- Writing configuration files for tools you haven't researched recently

### Success Metrics

**You're doing it right when:**
- Zero "this method doesn't exist" errors
- No "module not found" due to outdated import paths
- Security implementations follow current OWASP standards
- Code works on first run after verification
- Inline comments document verification sources and dates

**You're NOT doing it right when:**
- Implementing from memory without verification
- Getting errors about deprecated methods
- Skipping verification "because it's probably the same"

---

---

## Python Development Standards

### Tooling Stack (Mandatory)

**Environment & Dependencies:**
- ✅ **uv** - Package manager (10-100x faster than pip)
- ✅ **pyproject.toml** - PEP 621 standard (NOT requirements.txt)
- ✅ **Python 3.11+** - Modern features, better performance

**Code Quality Tools:**
- ✅ **ruff** - Linting (Rust-based, combines 10+ tools)
- ✅ **mypy** - Type checking (industry standard)
- ✅ **black** - Auto-formatting (100 char lines, opinionated)
- ✅ **pytest** - Testing framework

**Automation:**
- ✅ **pre-commit** - Automated quality checks before commits

### uv Package Manager Specifics

**CRITICAL**: When using uv-managed virtual environments:

```bash
# ✅ CORRECT: Use 'uv pip' in uv-managed venvs
source .venv/bin/activate
uv pip install pytest
uv pip install -e '.[dev]'

# ❌ WRONG: Don't use plain 'pip' in uv venvs
pip install pytest  # May not use uv's resolution
```

**Why**: uv manages its own package resolution and installation. Using plain `pip` bypasses uv's optimizations and may cause dependency conflicts.

**Running Tests in venvs:**
```bash
# ✅ CORRECT: Explicit Python module execution
python3 -m pytest tests/ -v
python3 -m mypy src/

# ⚠️ Less Reliable: Direct command may use system Python
pytest tests/  # Might not use venv's pytest
```

**Why**: `python3 -m` explicitly uses the virtual environment's Python interpreter, ensuring you run the venv's version of tools.

### Code Standards

**Type Hints:**
```python
# REQUIRED: All functions must have type annotations
def process_data(items: List[Dict[str, Any]]) -> ProcessResult:
    """Clear docstring explaining purpose."""
    pass

# NEVER: Untyped functions
def process_data(items):  # ❌ No type hints
    pass
```

**Imports:**
```python
# Standard library first
import sys
from pathlib import Path
from typing import List, Dict, Optional

# Third-party second
import pandas as pd
from pydantic import BaseModel

# Local imports last
from models.types import Component
from services.inventory import InventoryService
```

**Error Handling:**
```python
# Specific exceptions with context
try:
    result = service.process(data)
except ValidationError as e:
    logger.error(f"Validation failed: {e}")
    raise ProcessingError(f"Invalid data: {e}") from e

# NOT generic catch-all
try:
    result = service.process(data)
except Exception:  # ❌ Too broad
    pass
```

**Line Length:**
- 100 characters (balance readability + screen space)
- Consistent across black, ruff, mypy

### File Organization

```python
# Standard module structure
"""Module docstring explaining purpose."""

# Imports (grouped by standard/third-party/local)
import sys
from typing import List

import pandas as pd

from models.types import Component


# Constants (uppercase)
DEFAULT_TIMEOUT = 30
MAX_RETRIES = 3


# Classes (PascalCase)
class ComponentService:
    """Service for component operations."""

    def __init__(self, db_path: str) -> None:
        self.db_path = db_path

    def search(self, query: str) -> List[Component]:
        """Search components by query."""
        pass


# Functions (snake_case)
def normalize_value(value: str) -> str:
    """Normalize component value."""
    return value.lower().strip()


# Main execution
if __name__ == "__main__":
    main()
```

---

## Multi-Language Projects (Python + TypeScript)

### Type Synchronization Strategy

**Pattern**: Single source of truth with auto-generation

```
Python (Pydantic) → Auto-Generate → TypeScript
         ↓
   Validate Sync (pre-commit)
```

**Implementation:**
1. Define types in Python (Pydantic models)
2. Auto-generate TypeScript with script
3. Validate sync in pre-commit hook
4. NEVER manually edit generated files

**Example Structure:**
```
src/
├── models/
│   ├── types.py              # Python (source of truth)
│   ├── types.generated.ts    # Auto-generated
│   └── types.ts              # Copy of generated (for frontend)
scripts/
├── generate-types.py         # Python → TypeScript generator
└── validate-types.py         # Sync validator
```

**Benefits:**
- Zero type drift possible
- Single source of truth
- Compile-time type safety across languages
- Automated synchronization

---

## Project Structure Standards

### Mandatory Files

**Root Directory:**
```
/project/
├── CLAUDE.md                  # Main guide for Claude Code
├── README.md                  # Public-facing overview
├── pyproject.toml             # Python config (if Python project)
├── PYTHON_DEVELOPMENT.md      # Python setup/workflow (if Python project)
├── .gitignore                 # Include Python, Node, data dirs
├── .pre-commit-config.yaml    # Pre-commit hooks
└── package.json               # Node scripts (if applicable)
```

**Python Projects - Additional Required File:**
- `PYTHON_DEVELOPMENT.md` - Comprehensive setup, workflow, and troubleshooting guide

### CLAUDE.md Template

Every project MUST have `CLAUDE.md` with these sections:

```markdown
# Project Name - Project Guide for Claude Code

## Project Overview
[Brief description, architecture, current status]

## Critical Requirements ⚠️
[Non-negotiable requirements from user]

## Tooling Setup
[Environment, dependencies, code quality tools]

## Architecture Principles
[Key architectural decisions]

## Project Structure
[Directory layout with explanations]

## Key File Locations
[Where to find critical files]

## Development Guidelines
[How to work with the codebase]

## Common Commands
[Frequently used commands]

## User Preferences
[User's communication preferences, autonomy level]
```

### PYTHON_DEVELOPMENT.md Template (Python Projects Only)

Every Python project MUST have `PYTHON_DEVELOPMENT.md` with these sections:

```markdown
# Python Development Guide

## Overview
- Tooling stack summary (uv, ruff, mypy, black, pytest)
- Type system approach (if applicable)
- Key architectural patterns

## Tooling Stack & Decisions
- Environment: uv
- Dependencies: pyproject.toml
- Linting: ruff
- Type Checking: mypy
- Formatting: black
- Testing: pytest
- Pre-commit: automated checks
- Python Version requirement

Document WHY each tool was chosen with specific rationale.

## Initial Setup
Step-by-step instructions:
1. Install uv
2. Create virtual environment
3. Install dependencies
4. Setup pre-commit hooks

## Development Workflow
Day-to-day commands:
- Format code
- Run linters
- Run tests
- Type generation (if applicable)
- CLI tools usage (project-specific)

## Tool Configuration
Complete pyproject.toml configuration with comments explaining choices.

## Pre-commit Hooks
List all hooks and what they check. Include skip instructions for emergencies.

## Dependency Management
- Adding dependencies
- Updating dependencies
- Lock files usage

## Troubleshooting
Common issues and solutions:
- ModuleNotFoundError
- Pre-commit failures
- Type generation issues
- Import errors

## Common Commands Cheat Sheet
Quick reference for daily workflow.
```

**Purpose**: This file answers "How do I work with Python in THIS project?" while CLAUDE.md answers "How does THIS project work?"

**Why Separate from CLAUDE.md:**
- Python-specific details would clutter main project guide
- Developers can reference Python setup independently
- Clear separation: project architecture vs. Python tooling
- Reusable template pattern across Python projects

**Creation Timing:**
- Create during Phase 1 (Foundation)
- Update when tooling decisions change
- Keep synchronized with pyproject.toml

### Documentation Standards

**MUST Document:**
1. **Critical Requirements** - Non-negotiable user needs
2. **Tooling Decisions** - Why specific tools were chosen
3. **Architecture Patterns** - How system is structured
4. **Setup Instructions** - Getting started from scratch
5. **Common Commands** - Developer workflow

**Documentation Files:**
- `CLAUDE.md` - Main guide (comprehensive)
- `README.md` - Public overview (concise)
- `PYTHON_DEVELOPMENT.md` - Python setup/workflow (Python projects only)
- `SETUP.md` - Detailed installation (optional)
- `DECISIONS.md` - Why certain choices were made (optional)

---

## Git & Version Control

### Commit Standards

**Commit Messages:**
```bash
# Good: Clear, imperative, concise
Add user authentication with JWT
Fix inventory search query performance
Update Python dependencies to latest

# Bad: Vague, past tense, too long
Fixed some stuff
Updated things
Changed a bunch of files to make the thing work better
```

**Co-Authored Commits:**
```bash
# Include when AI assisted significantly
git commit -m "Add schematic analysis feature

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

### What to Commit

**DO Commit:**
- Source code
- Configuration files (.env.example, NOT .env)
- Documentation
- Database schemas
- Tests

**NEVER Commit:**
- Secrets (.env, API keys, credentials)
- User data (private inventories, uploads)
- Generated files (can be regenerated)
- Large binaries
- Database files (.db)
- Virtual environments (.venv, node_modules)

### .gitignore Template

```gitignore
# Python
__pycache__/
*.py[cod]
.venv/
.pytest_cache/
.mypy_cache/
.ruff_cache/

# Node
node_modules/
.next/

# Environment
.env
.env.local

# Database
data/db/*.db
data/uploads/
data/exports/

# User Data (private)
data/imports/

# IDE
.idea/  # JetBrains IDEs (user-specific, don't commit)
# Note: .vscode/ should be COMMITTED (shared project settings)

# OS
.DS_Store
Thumbs.db
```

---

## Code Quality Standards

### MCP Server Setup (Optional, Not Mandatory)

**REVISED APPROACH**: MCP servers are powerful but NOT required. Most documentation needs are met through WebSearch/WebFetch + Brave Search API.

**What Are MCP Servers:**
- Model Context Protocol servers provide structured access to external data
- Official servers exist for: filesystem, GitHub, Brave Search, memory, Slack, etc.
- **Documentation-specific MCP servers DO NOT exist** as official packages

**Recommended Approach Instead:**
1. **Primary**: Use Code Accuracy Protocol (see above section)
2. **Built-in**: WebSearch + WebFetch (always available in Claude Code)
3. **Enhanced**: Brave Search API (recommended, $3-5/1K requests)
4. **Optional**: MCP servers for specific needs (filesystem, GitHub, etc.)

**Real MCP Servers (Verified 2026-02-14):**

**✅ Exist and Work:**
```json
{
  "mcpServers": {
    "brave-search": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-brave-search"],
      "env": {
        "BRAVE_API_KEY": "${BRAVE_API_KEY}"
      }
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/allowed/path"],
      "env": {}
    },
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "${DATABASE_URL}"
      }
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "env": {}
    }
  }
}
```

**❌ Don't Exist (Despite What You May See Elsewhere):**
- `@modelcontextprotocol/server-python-docs` - Not in npm registry
- `@modelcontextprotocol/server-nextjs-docs` - Not in npm registry
- `@modelcontextprotocol/server-typescript` - Not in npm registry
- `@modelcontextprotocol/server-web-docs` - Not in npm registry
- `@modelcontextprotocol/server-sqlite` - Archived, no longer maintained

**When to Use MCP Servers:**

**DO use for:**
- GitHub API access (easier than direct API calls)
- Brave Search integration (if using heavily)
- Filesystem operations (secure path restrictions)
- PostgreSQL database access (query abstraction)
- Long-term memory across sessions

**DON'T use for:**
- Accessing documentation (use WebSearch/WebFetch instead)
- One-off queries (built-in tools sufficient)
- Adding complexity without clear benefit

**Testing Real MCP Servers:**
```bash
# Verify package exists before configuring
npm view @modelcontextprotocol/server-brave-search
npm view @modelcontextprotocol/server-github
npm view @modelcontextprotocol/server-filesystem

# Test server execution
npx -y @modelcontextprotocol/server-brave-search --help
```

**When to Setup:**
- Only when you have a specific, repeated need
- NOT as "Phase 0" for every project
- After evaluating whether built-in tools suffice

**Development Workflow (CORRECTED):**
1. Follow Code Accuracy Protocol (WebSearch/WebFetch verification)
2. Add Brave Search API if doing heavy framework research
3. Add specific MCP servers only when there's clear ROI
4. Test MCP servers before relying on them in workflow

### Pre-commit Hooks (Mandatory)

All projects MUST use pre-commit hooks:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-json

  - repo: https://github.com/psf/black
    hooks:
      - id: black

  - repo: https://github.com/astral-sh/ruff-pre-commit
    hooks:
      - id: ruff
        args: [--fix]

  - repo: https://github.com/pre-commit/mirrors-mypy
    hooks:
      - id: mypy
```

### Testing Standards

**Coverage Requirements:**
- Minimum 70% for new code
- Critical paths must have tests
- Test business logic, not implementation

**Test Organization:**
```
tests/
├── unit/              # Fast, isolated tests
├── integration/       # Component interaction tests
└── e2e/               # Full workflow tests
```

**Test Naming:**
```python
# Descriptive test names
def test_search_components_returns_exact_matches_first():
    pass

def test_validate_bom_with_missing_components_returns_shopping_list():
    pass

# NOT vague names
def test_search():  # ❌ Too vague
    pass
```

---

## Architecture Patterns

### Repository Pattern

```python
class ComponentRepository:
    """Data access layer for components."""

    def __init__(self, db_path: str):
        self.db_path = db_path

    def find_by_id(self, component_id: str) -> Optional[Component]:
        """Find component by ID."""
        pass

    def search(self, query: str) -> List[Component]:
        """Search components."""
        pass
```

### Service Layer

```python
class ComponentService:
    """Business logic for components."""

    def __init__(self, repository: ComponentRepository):
        self.repo = repository

    def search_components(self, query: str) -> List[Component]:
        """Search with intelligence (fuzzy matching, substitutions)."""
        results = self.repo.search(query)
        return self._rank_by_relevance(results, query)
```

### Separation of Concerns

```
Repository → Service → API/CLI
   ↓           ↓         ↓
Database   Business   User
  Layer     Logic    Interface
```

---

## AI Agent Development

### When to Use LLM Agents

**✅ Use LLM Agents For:**
- Reasoning about complex problems
- Creative tasks (graphics, layouts)
- Natural language understanding
- Multi-pass analysis with confidence scoring
- Tasks requiring domain knowledge

**❌ Don't Use LLM Agents For:**
- Simple CRUD operations
- Deterministic workflows
- Data transformations
- File I/O operations
- Database queries

### Agent Hierarchy

```
Root (SequentialAgent)
  ├─ Stage 1 (LlmAgent)        # Requires reasoning
  ├─ Stage 2 (ParallelAgent)   # Independent tasks
  │   ├─ Task A (LlmAgent)
  │   └─ Task B (Function)     # Deterministic
  └─ Stage 3 (SequentialAgent) # Ordered steps
```

### Agent Documentation

Every agent MUST have:
1. Clear purpose statement
2. Input/output specifications
3. Tool descriptions
4. Context/domain knowledge
5. Example usage

---

## Communication & Collaboration

### With Claude Code

**User Preferences (default unless specified):**
- ✅ Full autonomy to write files, run commands
- ✅ Concise communication (no emojis unless requested)
- ✅ Only commit when explicitly asked
- ✅ Build autonomously per plan
- ✅ Functionality over polish (MVP first)

**Problem Solving:**
- Don't brute force blocked approaches
- Consider alternatives when stuck
- Ask questions when requirements unclear
- Use AskUserQuestion for clarification, not approval

### Code Reviews

**When Reviewing Code:**
1. Check type safety (all functions typed?)
2. Verify error handling (specific exceptions?)
3. Confirm tests exist (critical paths covered?)
4. Review documentation (clear and accurate?)
5. Check for security issues (SQL injection, XSS?)

---

## Security Standards

### Never

**❌ NEVER:**
- Commit secrets (.env, API keys, tokens)
- Use string concatenation for SQL queries
- Trust user input without validation
- Run destructive commands without confirmation
- Skip authentication for sensitive operations
- Log sensitive data (passwords, tokens)

### Always

**✅ ALWAYS:**
- Use parameterized queries (SQL injection prevention)
- Validate user input (Pydantic models)
- Hash passwords (never store plain text)
- Use HTTPS for external APIs
- Implement rate limiting
- Sanitize file paths (path traversal prevention)

### Example: Safe Database Query

```python
# Safe (parameterized)
cursor.execute(
    "SELECT * FROM components WHERE type = ?",
    (component_type,)
)

# UNSAFE (string concatenation)
cursor.execute(
    f"SELECT * FROM components WHERE type = '{component_type}'"
)  # ❌ SQL injection vulnerability
```

---

## Performance Considerations

### Optimization Strategy

1. **Make it work** (functionality first)
2. **Make it right** (clean code)
3. **Make it fast** (only if needed)

**Premature optimization is evil** - Don't optimize until you have metrics showing it's needed.

### Database Performance

**DO:**
- Use indexes on frequently queried columns
- Batch operations when possible
- Use transactions for multiple writes
- Close connections properly

**DON'T:**
- Select all columns when few needed (use specific fields)
- Run queries in loops (use batch queries)
- Ignore connection pooling
- Forget to optimize common queries

---

## Continuous Improvement

### After Each Project

**Document:**
1. What worked well?
2. What was challenging?
3. What would you do differently?
4. What patterns emerged?

**Update Standards:**
- Add new patterns that proved valuable
- Remove patterns that didn't work
- Refine existing standards based on experience

### Review Frequency

- **Per Project**: Update project-specific CLAUDE.md
- **Quarterly**: Review and update universal standards
- **Annual**: Major revision of all standards

---

## Decision Framework

### When Making Technical Decisions

**Ask:**
1. **Simplicity**: Is this the simplest solution?
2. **Maintainability**: Can future me understand this?
3. **Testability**: Can this be easily tested?
4. **Performance**: Is performance adequate? (Don't over-optimize)
5. **Security**: Are there security implications?

**Document:**
- Why this approach was chosen
- What alternatives were considered
- What trade-offs were made

### Choosing Technologies

**Criteria:**
1. **Maturity**: Is it production-ready?
2. **Community**: Active development and support?
3. **Documentation**: Well-documented?
4. **Performance**: Fast enough for needs?
5. **Learning Curve**: Reasonable for team?

**Avoid:**
- Shiny new tech without proven track record
- Technologies with small/inactive communities
- Tools with poor documentation
- Over-engineering for hypothetical future needs

---

## Project Lifecycle

### Phase 0: MCP Server Setup (CRITICAL - Do First!)

**Goals:**
- Setup MCP servers for all technologies in stack
- Verify servers respond correctly
- Document which servers are configured

**Why First:**
- Claude Code needs latest documentation access
- Prevents bugs from outdated knowledge
- Faster development with accurate context

**Steps:**
1. Create `.mcp/config.json`
2. Add MCP servers for your tech stack
3. Test each server with sample query
4. Document in README

**Time**: 15-30 minutes upfront saves hours debugging later

### Phase 1: Foundation

**Goals:**
- Define critical requirements
- Choose tooling stack
- Create reusable tools/skills
- Setup development environment
- Document decisions

**Deliverables:**
- CLAUDE.md
- README.md
- pyproject.toml (or equivalent)
- .gitignore
- Pre-commit hooks
- Custom skills (if applicable)

### Phase 2: Core Implementation

**Goals:**
- Build main application features
- Integrate tools/skills
- Write tests for critical paths
- Document as you go

**Deliverables:**
- Working MVP
- Test suite (>70% coverage)
- API documentation
- User guide

### Phase 3: Polish & Deploy

**Goals:**
- Optimize performance bottlenecks
- Comprehensive testing
- Security review
- Production deployment

**Deliverables:**
- Production-ready application
- Deployment documentation
- Monitoring setup
- Backup strategy

---

## Common Pitfalls to Avoid

1. **Over-engineering** - Build what's needed, not what might be needed
2. **Premature optimization** - Profile first, optimize after
3. **Incomplete documentation** - Document as you build, not after
4. **Ignoring errors** - Handle errors explicitly, never silently
5. **Manual processes** - Automate repetitive tasks (pre-commit, type generation)
6. **Tight coupling** - Keep components loosely coupled
7. **No tests** - Write tests for critical paths from start
8. **Unclear requirements** - Clarify before building
9. **Technical debt** - Address small issues before they compound
10. **Forgetting security** - Consider security from day one

---

## Quick Reference

### Starting a New Project

```bash
# 1. Create project structure
mkdir project-name && cd project-name

# 2. Setup MCP servers FIRST (critical!)
mkdir .mcp
# Create .mcp/config.json with appropriate servers for your stack
# Test: mcp-client <server-name> "test query"

# 3. Initialize Python (if Python project)
uv venv
source .venv/bin/activate
uv init  # Creates pyproject.toml

# 4. Setup pre-commit
pre-commit install

# 5. Create mandatory files
touch CLAUDE.md README.md .gitignore

# 6. Document decisions as you make them
```

**MCP Server Selection Guide:**
- **Next.js project**: nextjs, react, typescript, web-search
- **FastAPI project**: python-docs, fastapi, sqlite/postgres, web-search
- **Full-stack**: All of above + any AI framework servers
- **Always include**: web-search (for latest info)

### Daily Development Workflow

```bash
# Activate environment
source .venv/bin/activate

# Generate types (if multi-language)
npm run generate:types

# Format code
npm run format:py

# Run tests
npm test

# Commit (pre-commit runs automatically)
git add .
git commit -m "Your message"
```

---

## 12-Factor App Principles

Modern applications MUST follow the **12-Factor App** methodology for cloud-native, portable, maintainable systems.

### I. Codebase
**One codebase tracked in version control, many deploys**
- Single Git repository per application
- Deploy multiple environments (dev, staging, prod) from same codebase
- Use environment variables for config differences

### II. Dependencies
**Explicitly declare and isolate dependencies**
```python
# Python: pyproject.toml declares ALL dependencies
[project]
dependencies = [
    "fastapi>=0.109.0",
    "pydantic>=2.6.0",
]

# Node: package.json declares ALL dependencies
{
  "dependencies": {
    "next": "^15.0.0",
    "react": "^18.0.0"
  }
}
```

**Never rely on system-wide packages** - Use virtual environments (uv venv, node_modules)

### III. Config
**Store config in environment variables**
```python
# .env.local (NEVER commit)
DATABASE_URL=sqlite:///data/dev.db
ANTHROPIC_API_KEY=sk-ant-xxxxx
GOOGLE_API_KEY=AIza-xxxxx

# Code reads from environment
import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str
    anthropic_api_key: str
    google_api_key: str

    class Config:
        env_file = ".env"
```

**Config Template:**
```bash
# .env.example (commit this)
DATABASE_URL=sqlite:///data/pedalbuild.db
ANTHROPIC_API_KEY=your_key_here
GOOGLE_API_KEY=your_key_here
```

### IV. Backing Services
**Treat backing services as attached resources**
- Database, cache, message queue, external APIs are all "attached resources"
- Should be swappable without code changes (just config)

```python
# Abstract storage to allow swapping
class StorageAdapter(ABC):
    @abstractmethod
    def save(self, data): pass

class SQLiteAdapter(StorageAdapter):
    def __init__(self, db_url: str):
        self.db_url = db_url  # From config

class PostgreSQLAdapter(StorageAdapter):
    def __init__(self, db_url: str):
        self.db_url = db_url  # Same interface, different backing service
```

### V. Build, Release, Run
**Strictly separate build and run stages**

```bash
# Build: Create deployment artifact
npm run build          # Frontend
python -m build        # Python package

# Release: Combine build + config
export DATABASE_URL=...
export API_KEY=...

# Run: Execute release
npm start
uvicorn main:app
```

### VI. Processes
**Execute app as stateless processes**
- Processes are stateless and share-nothing
- Persistent data goes in backing service (database)
- Session state in cache (Redis) or database, NOT in memory

```python
# BAD: Stateful process
user_sessions = {}  # ❌ Lost on restart

# GOOD: Stateless process
def get_session(session_id: str):
    return db.query_session(session_id)  # ✅ Survives restart
```

### VII. Port Binding
**Export services via port binding**
```python
# Application binds to port, not relying on runtime injection
if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
```

### VIII. Concurrency
**Scale out via the process model**
- Horizontal scaling (more instances) > Vertical scaling (bigger instance)
- Use process managers (PM2, systemd, Kubernetes)

### IX. Disposability
**Maximize robustness with fast startup and graceful shutdown**
```python
import signal
import sys

def graceful_shutdown(signum, frame):
    """Handle shutdown gracefully."""
    logger.info("Shutting down gracefully...")
    db.close_all_connections()
    cache.flush()
    sys.exit(0)

signal.signal(signal.SIGTERM, graceful_shutdown)
```

### X. Dev/Prod Parity
**Keep development, staging, and production as similar as possible**

**Time Gap**: Deploy frequently (hours, not weeks)
**Personnel Gap**: Developers deploy their own code
**Tools Gap**: Same backing services in dev and prod

```python
# Development
DATABASE_URL=sqlite:///data/dev.db

# Production
DATABASE_URL=postgresql://user:pass@prod-db:5432/pedalbuild

# Same adapter pattern, easy migration
```

### XI. Logs
**Treat logs as event streams**
```python
import structlog
import sys

# Structured logging to stderr — not stdout
# stdout is for program output; stderr is for logs
logger = structlog.get_logger()
logger.info("user_login", user_id=123, ip="192.168.1.1")

# Don't manage log files in app code
# Let environment handle routing (shell redirect, Docker, systemd)
```

### XII. Admin Processes
**Run admin/management tasks as one-off processes**
```bash
# Database migrations
python scripts/migrate.py

# Data imports
python scripts/import-inventory.py data/inventory.csv

# Same environment, same codebase as main app
```

---

## Agentic Application Principles

When building applications with AI agents (LLM-powered), apply these **Agentic Application Principles** in addition to 12-Factor principles.

### 1. Agent Hierarchy & Orchestration
**Design clear agent hierarchies to prevent chaos**

```python
# Root orchestrator coordinates specialized agents
Root (SequentialAgent)
  ├─ Planning Agent (LlmAgent)        # High-level reasoning
  ├─ Execution Agent (ParallelAgent)  # Parallel tasks
  │   ├─ Data Agent (LlmAgent)
  │   └─ Validation Agent (Function)  # Deterministic
  └─ Review Agent (LlmAgent)          # Quality check
```

**Guidelines:**
- **Root agent**: Orchestrates workflow, makes high-level decisions
- **Specialist agents**: Focus on specific domain tasks
- **No peer-to-peer**: Agents don't call each other directly
- **Clear boundaries**: Each agent has well-defined responsibilities

### 2. Deterministic Where Possible
**Reserve LLM agents for tasks truly requiring intelligence**

**✅ Use LLM Agents:**
- Natural language understanding
- Creative generation (layouts, graphics, content)
- Multi-step reasoning with ambiguity
- Domain expertise application
- Decision making with trade-offs

**❌ Use Deterministic Code:**
- Data transformation (parsing, formatting)
- CRUD operations
- Mathematical calculations
- File I/O
- Database queries
- API calls with known structure

```python
# BAD: Using LLM for deterministic task
agent.add_tool(CalculateTotalTool())  # ❌ Simple math doesn't need LLM

# GOOD: Direct calculation
def calculate_total(items: List[Item]) -> float:
    return sum(item.price * item.quantity for item in items)
```

### 3. Context Engineering
**Provide agents with domain-specific context**

```markdown
# agent-context.md
You are an expert in electronic circuit analysis with 20 years experience.

## Domain Knowledge
- Resistor color codes: Brown=1, Red=2, Orange=3...
- Standard resistor values: E12 series (10, 12, 15, 18, 22...)
- Common IC pinouts: TL072 (op-amp), 2N3904 (NPN transistor)

## Task-Specific Guidelines
- Always check component polarity (electrolytic caps, diodes)
- Verify voltage ratings exceed circuit voltage by 20%
- Flag substitutions that may affect tone
```

**Load context in agent initialization:**
```python
with open("agent-context.md") as f:
    context = f.read()

agent = LlmAgent(
    name="CircuitAnalyzer",
    system_prompt=context,
    tools=[...],
)
```

### 4. Tool Design Patterns
**Create focused, composable tools**

```python
class Tool:
    """Single responsibility, clear interface."""

    name: str
    description: str  # LLM reads this to decide when to use

    def execute(self, **params) -> Result:
        """Pure function: same input → same output."""
        pass

# GOOD: Focused tool
class SearchComponentsTool:
    """Search component inventory by query."""
    def execute(self, query: str) -> List[Component]:
        pass

# BAD: Multi-purpose tool
class ComponentManagerTool:  # ❌ Too broad
    """Search, add, remove, update components."""
    pass
```

### 5. State Management for Agents
**Use appropriate state scopes**

**Session State** (temporary, per-session):
- Current user interaction
- Intermediate results
- Temporary files
- Form drafts

**User State** (persistent, per-user):
- User preferences
- User data (inventory, projects)
- Historical interactions
- Learned preferences

**Global State** (shared, all users):
- Reference data (component specs)
- Public catalogs
- System configuration
- Shared resources

```python
# ADK-style state management
state["session.current_project_id"] = project_id
state["user.component_inventory"] = inventory
state["global.component_catalog"] = catalog
```


### 6. Web Search for Agents (Application-Level)
**Agents may need real-time web access**

**Note**: This is for YOUR APPLICATION'S agents, not for Claude Code when writing code.

**When Agents Need Web Search:**
- Research agents gathering circuit information
- Specification download agents browsing pedal sites
- Price comparison agents checking component availability
- Documentation lookup agents accessing datasheets

**Recommended: Brave Search API**
- **Cost**: $3-5 per 1,000 requests
- **Free tier**: 2,000 queries/month
- **Why Brave**: Independent 35B page index, zero data retention, SOC2 compliant
- **LLM Context API**: Specifically designed for AI applications

**Setup:**
```bash
# .env
BRAVE_API_KEY=your_brave_api_key_here
```

**Usage in Agent Tools:**
```python
from brave_search import BraveSearchAPI

class WebResearchTool:
    """Tool for agents to search the web."""

    def __init__(self):
        self.api = BraveSearchAPI(api_key=os.getenv("BRAVE_API_KEY"))

    async def execute(self, query: str) -> List[SearchResult]:
        """Search web and return structured results."""
        results = await self.api.search(query, count=10)
        return [SearchResult(
            title=r.title,
            url=r.url,
            snippet=r.description
        ) for r in results]

# Add to agent
web_research_agent = LlmAgent(
    name="WebResearcher",
    tools=[WebResearchTool()],
)
```

**Alternative**: For simple cases, agents can use web scraping (Playwright, Puppeteer) instead of paid APIs.

### 13. Streaming & Real-time Feedback
**Provide live progress updates**

```typescript
// Frontend receives streaming updates
async function runWorkflow(onProgress: (update: AgentUpdate) => void) {
  const response = await fetch('/api/workflow', { method: 'POST' });
  const reader = response.body.getReader();

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    const update = JSON.parse(decoder.decode(value));
    onProgress(update);  // Update UI in real-time
  }
}
```

**Why it matters:**
- User sees progress (not black box)
- Can cancel long-running tasks
- Builds trust in AI system
- Better UX for multi-minute tasks

### 13. Confidence Scoring & Human-in-the-Loop
**Flag low-confidence results for human review**

```python
class AnalysisResult:
    components: List[Component]
    confidence: float  # 0.0-1.0

    @property
    def needs_review(self) -> bool:
        return self.confidence < 0.7

# Agent performs multi-pass analysis
result = await schematic_analyzer.analyze(image)

if result.needs_review:
    flagged = [c for c in result.components if c.confidence < 0.7]
    # Present to user for confirmation
    await request_user_review(flagged)
```

### 13. Idempotency & Retry Logic
**Agents should handle retries gracefully**

```python
@retry(max_attempts=3, backoff=exponential)
async def call_llm_agent(prompt: str) -> str:
    """Retry on transient failures."""
    try:
        return await agent.run(prompt)
    except APIError as e:
        if e.status_code in [429, 503]:  # Rate limit, service unavailable
            raise  # Retry
        else:
            raise  # Don't retry on 4xx client errors
```

### 13. Cost Management
**Track and optimize LLM usage**

```python
class AgentMetrics:
    """Track agent performance and cost."""
    total_calls: int
    total_tokens: int
    total_cost: float
    avg_latency: float

# Log every agent call
@log_metrics
async def run_agent(agent: LlmAgent, input: str):
    start = time.time()
    result = await agent.run(input)
    latency = time.time() - start

    metrics.record(
        agent=agent.name,
        tokens=result.usage.total_tokens,
        cost=calculate_cost(result.usage),
        latency=latency,
    )
```

**Optimization strategies:**
- Use smaller models (Haiku) for simple tasks
- Cache frequent queries
- Batch similar requests
- Implement result caching

### 13. Testing Agentic Systems
**Special considerations for testing AI agents**

```python
# Unit test: Mock LLM responses
@pytest.fixture
def mock_llm_agent(monkeypatch):
    async def mock_run(prompt: str) -> str:
        return "Mocked response"
    monkeypatch.setattr(agent, "run", mock_run)

# Integration test: Real LLM, controlled inputs
def test_circuit_analysis_with_known_schematic():
    result = await agent.analyze("test-schematics/simple-boost.png")
    assert len(result.components) == 24
    assert result.confidence > 0.9

# Evaluation set: Track quality over time
def test_schematic_analysis_accuracy():
    """Test against labeled dataset."""
    for schematic, expected in test_dataset:
        result = await agent.analyze(schematic)
        accuracy = compare_components(result, expected)
        assert accuracy > 0.95  # 95% accuracy threshold
```

### 13. Explainability & Debugging
**Make agent decisions traceable**

```python
class AgentTrace:
    """Record agent reasoning for debugging."""
    agent_name: str
    input: str
    reasoning: str  # Why agent made this decision
    tools_used: List[str]
    output: str
    timestamp: datetime

# Enable tracing
agent = LlmAgent(
    name="CircuitAnalyzer",
    enable_tracing=True,
)

# Review traces
for trace in agent.get_traces():
    print(f"{trace.agent_name}: {trace.reasoning}")
```

### 13. Graceful Degradation
**Handle agent failures without breaking workflow**

```python
async def analyze_schematic(image: bytes) -> AnalysisResult:
    """Attempt AI analysis, fall back to manual if needed."""
    try:
        result = await ai_agent.analyze(image)
        if result.confidence > 0.7:
            return result
    except AgentError as e:
        logger.warning(f"Agent failed: {e}, falling back to manual")

    # Fall back to manual extraction
    return await request_manual_extraction(image)
```

---

## IDE Configuration Standards

### VSCode Settings (Recommended)

Create `.vscode/settings.json` in project root:

```json
{
  "editor.formatOnSave": true,
  "editor.rulers": [100],
  "editor.tabSize": 4,
  "editor.insertSpaces": true,
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,

  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.organizeImports": "explicit"
    }
  },

  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true,
    "editor.tabSize": 2
  },

  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true,
    "editor.tabSize": 2
  },

  "python.linting.enabled": true,
  "python.linting.ruffEnabled": true,
  "python.linting.mypyEnabled": true,
  "python.testing.pytestEnabled": true,

  "search.exclude": {
    "**/.venv": true,
    "**/node_modules": true,
    "**/__pycache__": true,
    "**/.pytest_cache": true,
    "**/.mypy_cache": true,
    "**/.ruff_cache": true
  },

  "files.watcherExclude": {
    "**/.venv/**": true,
    "**/node_modules/**": true
  }
}
```

### VSCode Extensions (Recommended)

Create `.vscode/extensions.json`:

```json
{
  "recommendations": [
    "ms-python.python",
    "ms-python.vscode-pylance",
    "ms-python.black-formatter",
    "charliermarsh.ruff",
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "bradlc.vscode-tailwindcss",
    "prisma.prisma",
    "github.copilot",
    "eamodio.gitlens"
  ]
}
```

### Optimizing Layout for Wider Code Lines

**Problem**: You set formatter to 100 chars and added a ruler, but your IDE layout doesn't let you actually USE that horizontal space effectively.

**Solution**: Optimize panel layout and settings to maximize editor width.

#### Recommended Layout Optimizations

Add these settings to your `.vscode/settings.json`:

```json
{
  // Visual ruler at your line length limit
  "editor.rulers": [100],  // or 120, or your preference

  // Horizontal space optimizations
  "editor.minimap.enabled": false,  // Saves ~100px horizontal space
  "workbench.activityBar.location": "top",  // Move activity bar to top
  "editor.wordWrap": "off",  // Enforces line length discipline

  // Font size optimization
  "editor.fontSize": 13,  // Balance readability with horizontal space
  "editor.lineHeight": 20
}
```

#### Panel Management Strategy

**Use keyboard shortcuts to show/hide panels on-demand:**

| Panel | Shortcut | When to Show |
|-------|----------|--------------|
| Sidebar (files) | `Cmd+B` / `Ctrl+B` | Need to browse files |
| Terminal | `Cmd+J` / `Ctrl+J` | Running commands |
| AI Chat (Cursor) | `Cmd+L` / `Ctrl+L` | Need AI assistance |
| Problems | `Cmd+Shift+M` / `Ctrl+Shift+M` | Checking errors |

**Workflow**:
```
Coding:    Hide all panels → MAX editor width
Debug:     Show terminal at bottom (horizontal split)
Research:  Show AI chat temporarily, close when done
```

#### Optimal Layout Configuration

```
┌─────────────────────────────────────────────┐
│  Activity Bar (Top)                         │
├──────────────┬──────────────────────────────┤
│  File Tree   │  Editor (MAX WIDTH)          │
│  (200-250px) │                              │
│              │  ← 100 chars visible         │
│              │                              │
└──────────────┴──────────────────────────────┘
│  Terminal (Full Width, Bottom)              │
└─────────────────────────────────────────────┘
```

#### Quick Tips

1. **Zen Mode for Focus**: `Cmd+K Z` / `Ctrl+K Z` - Hides everything except editor
2. **Test Your Layout**: Write a comment exactly at your line limit to verify you can see it comfortably
3. **Font Size**: Start at 13-14pt, adjust based on monitor size and resolution
4. **Disable Minimap**: It's decorative but rarely useful, costs ~100px of horizontal space
5. **Bottom Terminal**: Horizontal terminal split preserves editor width better than side-by-side

#### Why This Matters

If you can't comfortably see and write up to your formatter's line limit, you'll:
- Artificially break lines too early
- Not utilize the space you've allocated
- Fight against your own formatting rules

Match your IDE layout to your code standards for best results.

### PyCharm / IntelliJ Configuration

```python
# pyproject.toml already configures most tools
# Additional PyCharm-specific settings:

# .idea/codeStyleSettings.xml
<project version="4">
  <component name="ProjectCodeStyleConfiguration">
    <option name="LINE_LENGTH" value="100" />
    <option name="USE_TAB_CHARACTER" value="false" />
    <option name="TAB_SIZE" value="4" />
  </component>
</project>
```

**Note**: Commit `.vscode/` directory but gitignore `.idea/` (IDE-specific)

---

## Container & Docker Standards

### Dockerfile Best Practices

```dockerfile
# Use official base images
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies (if needed)
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency files first (for layer caching)
COPY pyproject.toml .

# Install Python dependencies
RUN pip install uv && uv pip install --system -e .

# Copy application code
COPY . .

# Create non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser /app
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8000/health || exit 1

# Run application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Multi-Stage Builds (Production)

```dockerfile
# Stage 1: Build
FROM python:3.11-slim AS builder
WORKDIR /app
COPY pyproject.toml .
RUN pip install uv && uv pip install --system -e .

# Stage 2: Runtime
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY . .

RUN useradd -m -u 1000 appuser && chown -R appuser /app
USER appuser

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### docker-compose.yml

```yaml
version: '3.8'

services:
  backend:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/pedalbuild
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
    env_file:
      - .env
    volumes:
      - ./data:/app/data
    depends_on:
      - db
    restart: unless-stopped

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://backend:8000
    depends_on:
      - backend
    restart: unless-stopped

  db:
    image: postgres:16-alpine
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
      - POSTGRES_DB=pedalbuild
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  postgres_data:
```

### .dockerignore

```
# Python
__pycache__/
*.py[cod]
.venv/
*.egg-info/

# Node
node_modules/
.next/

# Git
.git/
.gitignore

# IDE
.vscode/
.idea/

# Data
data/db/*.db
data/uploads/

# Secrets
.env
.env.local

# Tests
.pytest_cache/
coverage/
```

---

## CI/CD Pipeline Standards

### GitHub Actions Workflow

Create `.github/workflows/ci.yml`:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test-python:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install uv
        run: pip install uv

      - name: Install dependencies
        run: uv pip install -e '.[dev]'

      - name: Run ruff
        run: ruff check .

      - name: Run mypy
        run: mypy src/

      - name: Run black
        run: black --check .

      - name: Run pytest
        run: pytest --cov=src --cov-report=xml

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.xml

  test-typescript:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm ci

      - name: Run ESLint
        run: npm run lint

      - name: Run TypeScript compiler
        run: npm run type-check

      - name: Run tests
        run: npm test

  build-docker:
    runs-on: ubuntu-latest
    needs: [test-python, test-typescript]
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: username/pedalbuild:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy:
    runs-on: ubuntu-latest
    needs: build-docker
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy to production
        run: |
          # Your deployment script
          echo "Deploying to production..."
```

### Pre-deployment Checklist

Create `.github/workflows/pre-deploy-check.yml`:

```yaml
name: Pre-deployment Checks

on:
  workflow_dispatch:
  push:
    tags:
      - 'v*'

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Trivy security scan
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          severity: 'CRITICAL,HIGH'

      - name: Check for secrets
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./

  load-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run load tests
        run: |
          # Use k6, locust, or similar
          echo "Running load tests..."
```

---

## API Documentation Standards

### OpenAPI / Swagger Setup (FastAPI)

```python
from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi

app = FastAPI(
    title="PedalBuild API",
    description="API for guitar pedal building workflow",
    version="0.1.0",
    docs_url="/docs",      # Swagger UI
    redoc_url="/redoc",    # ReDoc
)

# Custom OpenAPI schema
def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema

    openapi_schema = get_openapi(
        title="PedalBuild API",
        version="0.1.0",
        description="Complete API documentation for PedalBuild",
        routes=app.routes,
    )

    # Add custom tags
    openapi_schema["tags"] = [
        {"name": "circuits", "description": "Circuit management"},
        {"name": "inventory", "description": "Component inventory"},
        {"name": "workflow", "description": "Build workflow operations"},
    ]

    app.openapi_schema = openapi_schema
    return app.openapi_schema

app.openapi = custom_openapi

# Documented endpoints
@app.get(
    "/api/circuits/{circuit_id}",
    tags=["circuits"],
    summary="Get circuit by ID",
    response_description="Circuit details",
)
async def get_circuit(circuit_id: str) -> Circuit:
    """
    Retrieve a specific circuit by ID.

    - **circuit_id**: Unique circuit identifier

    Returns complete circuit specification including:
    - Metadata (name, difficulty, category)
    - Schematic image URL
    - Bill of materials
    - Build documentation
    """
    pass
```

### API Documentation Structure

```markdown
# API Documentation (docs/API.md)

## Authentication
All endpoints require API key in header:
```
Authorization: Bearer YOUR_API_KEY
```

## Endpoints

### Circuits

#### `GET /api/circuits`
List all circuits with pagination.

**Query Parameters:**
- `category` (optional): Filter by category
- `difficulty` (optional): Filter by difficulty (1-5)
- `page` (optional, default: 1)
- `limit` (optional, default: 20)

**Response:**
```json
{
  "circuits": [...],
  "total": 42,
  "page": 1,
  "limit": 20
}
```

### Inventory

#### `POST /api/inventory/components`
Add component to inventory.

**Request Body:**
```json
{
  "type": "resistor",
  "value": "10k",
  "quantity": 100
}
```

**Response:**
```json
{
  "id": "comp_123",
  "type": "resistor",
  "value": "10k",
  "quantity": 100,
  "created_at": "2026-02-14T10:00:00Z"
}
```

## Error Handling

All errors follow this format:
```json
{
  "error": "ERROR_CODE",
  "message": "Human-readable description",
  "details": {}
}
```

Common error codes:
- `INVALID_INPUT` (400)
- `NOT_FOUND` (404)
- `RATE_LIMIT_EXCEEDED` (429)
- `INTERNAL_ERROR` (500)
```

---

## Monitoring & Logging Standards

**Philosophy**: Start simple, add complexity only when needed and with explicit approval.

### Phase 1-2: Basic Monitoring (MANDATORY)

These are required for all projects from day one. Simple, effective, no infrastructure overhead.

#### 1. Structured Logging to Stderr

**Always include**: module/component/script identification so you know WHERE logs originate.

```python
import structlog
import sys

# Configure structured logging — stderr, not stdout
# stdout is for program output; keep them separate so stdout can be piped/parsed cleanly
structlog.configure(
    processors=[
        structlog.stdlib.add_log_level,
        structlog.stdlib.add_logger_name,  # Adds logger name (module)
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.ExceptionRenderer(),  # NOT format_exc_info (deprecated/removed)
        structlog.dev.ConsoleRenderer() if app_env == "development" else structlog.processors.JSONRenderer(),
    ],
    wrapper_class=structlog.make_filtering_bound_logger(log_level),
    context_class=dict,
    logger_factory=structlog.PrintLoggerFactory(sys.stderr),  # explicit stderr
    cache_logger_on_first_use=True,
)

# Get logger with module name
logger = structlog.get_logger(__name__)  # __name__ = current module

# Usage with context (includes module, component, script)
logger.info(
    "user_action",
    module=__name__,           # e.g., "services.inventory"
    component="InventoryService",
    action="search_components",
    user_id="user_123",
    query="10k resistor",
    results_count=42,
)

# Error logging with full context
try:
    result = process_data(input)
except ValidationError as e:
    logger.error(
        "validation_failed",
        module=__name__,
        component="DataProcessor",
        error=str(e),
        input_data=input,
        exc_info=True,  # Includes stack trace
    )
```

**Output Example (JSON to stderr):**
```json
{
  "event": "user_action",
  "level": "info",
  "timestamp": "2026-02-14T15:30:45.123Z",
  "logger": "services.inventory",
  "module": "services.inventory",
  "component": "InventoryService",
  "action": "search_components",
  "user_id": "user_123",
  "query": "10k resistor",
  "results_count": 42
}
```

**Why This Works:**
- Logs go to stderr — stdout stays clean for program output (pipes, `jq`, etc.)
- Structured JSON for easy parsing
- Module/component identification for debugging
- No log file management in app code — infra decides where stderr goes

**File routing (when needed):** Use a launcher script, never in app code:
```bash
#!/usr/bin/env bash
# scripts/run-api.sh
set -euo pipefail
if [[ -f .env ]]; then set -o allexport; source .env; set +o allexport; fi
LOG_TO_FILE="${LOG_TO_FILE:-false}"
if [[ "$LOG_TO_FILE" == "true" ]]; then
  mkdir -p logs
  exec uvicorn src.api.main:app --host 0.0.0.0 --port 8000 --reload 2>>logs/api.log
else
  exec uvicorn src.api.main:app --host 0.0.0.0 --port 8000 --reload
fi
```

For Docker services, use a separate compose overlay (not the base file):
```yaml
# docker-compose.file-logging.yml — apply only when file capture wanted
services:
  worker:
    volumes:
      - ./logs:/logs
    command: sh -c "celery -A src.workers.celery_app worker 2>>/logs/worker.log"
```
```bash
# normal
docker compose up -d worker
# with file logging
docker compose -f docker-compose.yml -f docker-compose.file-logging.yml up -d worker
```

#### 2. Log Levels (Use Appropriately)

```python
# Get logger with module context
logger = structlog.get_logger(__name__)

# CRITICAL: System unusable
logger.critical(
    "database_unreachable",
    module=__name__,
    component="DatabaseAdapter",
    error=str(e)
)

# ERROR: Functionality broken
logger.error(
    "api_request_failed",
    module=__name__,
    component="CircuitAPI",
    endpoint="/api/circuits",
    status=500
)

# WARNING: Unexpected but handled
logger.warning(
    "low_stock",
    module=__name__,
    component="InventoryService",
    component_id="comp_123",
    quantity=2
)

# INFO: Normal operations
logger.info(
    "user_login",
    module=__name__,
    component="AuthService",
    user_id="user_123",
    ip="192.168.1.1"
)

# DEBUG: Detailed diagnostics (dev only)
logger.debug(
    "cache_hit",
    module=__name__,
    component="CacheService",
    key="circuit_42",
    ttl=3600
)
```

#### 3. Health Check Endpoint (Always Required)

```python
from fastapi import FastAPI
from fastapi.responses import JSONResponse
from datetime import datetime

app = FastAPI()

@app.get("/health")
async def health_check():
    """
    Basic health check for monitoring.

    Returns 200 if healthy, 503 if unhealthy.
    """
    checks = {
        "database": await check_database(),
        "api_keys": check_api_keys_configured(),
    }

    all_healthy = all(check["status"] == "ok" for check in checks.values())
    status_code = 200 if all_healthy else 503

    return JSONResponse(
        status_code=status_code,
        content={
            "status": "healthy" if all_healthy else "unhealthy",
            "timestamp": datetime.now().isoformat(),
            "checks": checks,
            "version": "0.1.0",
        }
    )

async def check_database() -> dict:
    """Check database connectivity."""
    try:
        await db.execute("SELECT 1")
        return {"status": "ok"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

def check_api_keys_configured() -> dict:
    """Check required API keys are present."""
    required = ["ANTHROPIC_API_KEY", "GOOGLE_API_KEY"]
    missing = [key for key in required if not os.getenv(key)]

    if missing:
        return {"status": "error", "message": f"Missing keys: {missing}"}
    return {"status": "ok"}
```

**That's it for Phase 1-2!** Simple, effective, zero infrastructure overhead.

---

### Phase 3+: Enterprise Monitoring (REQUIRES USER APPROVAL)

**⚠️ CRITICAL**: Do NOT implement these without explicit user approval. These add significant complexity and should only be added when:
- Application is production-ready
- Multiple instances running
- Team needs shared dashboards
- SLO/SLA monitoring required

#### When to Ask for Approval

Before implementing, ask user:
> "Your application is ready for production monitoring. Would you like to implement enterprise observability (Prometheus + Grafana + Loki)? This adds:
> - Metrics collection & visualization
> - Log aggregation across instances
> - ~3 additional Docker containers
> - Configuration & maintenance overhead
>
> Alternative: Continue with simple stdout logging and basic health checks until you have specific monitoring needs."

#### Enterprise Stack (If Approved)

**Prometheus Metrics Collection:**

```python
from prometheus_client import Counter, Histogram, Gauge, make_asgi_app

# Define metrics
request_count = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

request_duration = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency',
    ['method', 'endpoint']
)

active_users = Gauge(
    'active_users',
    'Number of active users'
)

# Add metrics endpoint to FastAPI
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

# Instrument endpoints
@app.get("/api/circuits")
async def get_circuits():
    with request_duration.labels(method="GET", endpoint="/api/circuits").time():
        request_count.labels(method="GET", endpoint="/api/circuits", status=200).inc()
        return circuits
```

**Grafana + Prometheus + Loki Stack:**

```yaml
# docker-compose.monitoring.yml (Only if user approved)
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/dashboards:/etc/grafana/provisioning/dashboards
    ports:
      - "3001:3000"
    depends_on:
      - prometheus
    restart: unless-stopped

  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"
    volumes:
      - loki_data:/loki
    restart: unless-stopped

volumes:
  prometheus_data:
  grafana_data:
  loki_data:
```

**Remember**: This is Phase 3+. Most projects don't need this initially. Start simple!

---
---

## Adaptation Guidelines

**This file contains universal standards**, but:
- Projects may have specific needs
- Standards can be overridden in project CLAUDE.md
- Document why you're deviating from standards
- Propose improvements to standards based on experience

**When in doubt:**
1. Check this file
2. Check project CLAUDE.md
3. Ask user for clarification

---

**Remember**: These standards exist to make development faster, safer, and more maintainable. They're guidelines, not laws. Use judgment, document exceptions, and continuously improve based on real-world experience.

**Version**: 2.0
**Last Updated**: 2026-02-14
**Source Project**: PedalBuild (validated through implementation)
