---
tools:
  run_tests: ~/.claude/tools/run_tests.py
---

# test-runner

Run pytest tests with coverage reporting and detailed output.

## Usage

```bash
# Run all tests
python ~/.claude/tools/run_tests.py

# Run specific test file
python ~/.claude/tools/run_tests.py tests/test_component_inventory.py

# Run with coverage
python ~/.claude/tools/run_tests.py --coverage

# Run verbose
python ~/.claude/tools/run_tests.py --verbose
```

## When to Use

- After writing any new Python code
- Before committing changes
- When debugging test failures
- To verify test coverage

## Requirements

- pytest installed in project venv
- Project uses pytest for testing
- Tests located in `tests/` directory

## Output

- Test results with pass/fail status
- Coverage report (if --coverage flag used)
- Failed test details with tracebacks
- Summary statistics
