---
tools:
  format_lint: ~/.claude/tools/format_lint.py
---

# format-and-lint

Format and lint Python code using black, ruff, and mypy.

## Usage

```bash
# Format and lint all code
python ~/.claude/tools/format_lint.py

# Format and lint specific file/directory
python ~/.claude/tools/format_lint.py src/backend/services/

# Check only (no fixes)
python ~/.claude/tools/format_lint.py --check

# Skip type checking
python ~/.claude/tools/format_lint.py --no-mypy
```

## When to Use

- Before committing code
- After writing significant code changes
- When pre-commit hooks fail
- To ensure code quality

## Requirements

- black, ruff, mypy installed in project venv
- pyproject.toml with tool configurations

## Output

- Formatted files with black
- Linting issues fixed by ruff (auto-fix)
- Type checking results from mypy
- Summary of all changes made
