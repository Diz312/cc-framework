#!/usr/bin/env python3
"""
test-runner: Run pytest tests with coverage and detailed reporting

Usage:
    python ~/.claude/tools/run_tests.py                              # Run all tests
    python ~/.claude/tools/run_tests.py tests/test_file.py          # Run specific test
    python ~/.claude/tools/run_tests.py --coverage                  # Run with coverage
    python ~/.claude/tools/run_tests.py --verbose                   # Verbose output
"""

import argparse
import subprocess
import sys
from pathlib import Path


def find_project_root() -> Path:
    """Find project root by looking for common markers."""
    current = Path.cwd()

    # Look for markers of project root
    markers = ["pyproject.toml", "setup.py", "pytest.ini", ".git"]

    while current != current.parent:
        if any((current / marker).exists() for marker in markers):
            return current
        current = current.parent

    # Default to current directory
    return Path.cwd()


def run_tests(
    test_path: str = "",
    coverage: bool = False,
    verbose: bool = False
) -> int:
    """
    Run pytest tests with specified options.

    Args:
        test_path: Specific test file/directory to run (empty = all tests)
        coverage: Whether to run with coverage reporting
        verbose: Whether to use verbose output

    Returns:
        Exit code (0 = success, non-zero = failure)
    """
    project_root = find_project_root()

    print(f"📁 Project root: {project_root}")
    print(f"🧪 Running tests...\n")

    # Build pytest command
    cmd = ["pytest"]

    # Add test path if specified
    if test_path:
        cmd.append(test_path)

    # Add verbose flag
    if verbose:
        cmd.append("-v")
    else:
        cmd.append("-q")  # Quiet mode by default

    # Add coverage flags
    if coverage:
        cmd.extend([
            "--cov=src",
            "--cov-report=term-missing",
            "--cov-report=html"
        ])

    # Always show summary
    cmd.append("-ra")  # Show summary of all test outcomes

    # Run pytest
    try:
        result = subprocess.run(
            cmd,
            cwd=project_root,
            check=False
        )

        if result.returncode == 0:
            print("\n✅ All tests passed!")
            if coverage:
                print(f"📊 Coverage report: {project_root}/htmlcov/index.html")
        else:
            print("\n❌ Some tests failed!")

        return result.returncode

    except FileNotFoundError:
        print("❌ Error: pytest not found. Is the virtual environment activated?")
        print("   Run: source .venv/bin/activate")
        return 1
    except Exception as e:
        print(f"❌ Error running tests: {e}")
        return 1


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Run pytest tests with coverage and reporting"
    )
    parser.add_argument(
        "test_path",
        nargs="?",
        default="",
        help="Specific test file or directory to run (default: all tests)"
    )
    parser.add_argument(
        "--coverage",
        "-c",
        action="store_true",
        help="Run with coverage reporting"
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Verbose output"
    )

    args = parser.parse_args()

    return run_tests(
        test_path=args.test_path,
        coverage=args.coverage,
        verbose=args.verbose
    )


if __name__ == "__main__":
    sys.exit(main())
