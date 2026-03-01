#!/usr/bin/env python3
"""
format-and-lint: Format and lint Python code with black, ruff, and mypy

Usage:
    python ~/.claude/tools/format_lint.py                    # Format and lint all code
    python ~/.claude/tools/format_lint.py src/backend/       # Format specific path
    python ~/.claude/tools/format_lint.py --check            # Check only (no fixes)
    python ~/.claude/tools/format_lint.py --no-mypy          # Skip type checking
"""

import argparse
import subprocess
import sys
from pathlib import Path
from typing import List, Tuple


def find_project_root() -> Path:
    """Find project root by looking for common markers."""
    current = Path.cwd()
    markers = ["pyproject.toml", "setup.py", ".git"]

    while current != current.parent:
        if any((current / marker).exists() for marker in markers):
            return current
        current = current.parent

    return Path.cwd()


def run_command(cmd: List[str], cwd: Path, description: str) -> Tuple[bool, str]:
    """
    Run a command and return success status and output.

    Args:
        cmd: Command to run as list
        cwd: Working directory
        description: Human-readable description

    Returns:
        Tuple of (success: bool, output: str)
    """
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=True,
            text=True,
            check=False
        )

        success = result.returncode == 0
        output = result.stdout + result.stderr

        return success, output

    except FileNotFoundError:
        return False, f"Command not found: {cmd[0]}"


def format_with_black(path: str, check_only: bool, project_root: Path) -> bool:
    """Run black formatter."""
    print(f"🎨 Running black formatter...")

    cmd = ["black"]
    if check_only:
        cmd.append("--check")
    cmd.append(path if path else "src/")

    success, output = run_command(cmd, project_root, "black")

    if not success and check_only:
        print(f"❌ Black found formatting issues:\n{output}")
        return False
    elif not success:
        print(f"❌ Black failed:\n{output}")
        return False
    else:
        if check_only:
            print("✅ Black: All files formatted correctly")
        else:
            print("✅ Black: All files formatted")
        return True


def lint_with_ruff(path: str, check_only: bool, project_root: Path) -> bool:
    """Run ruff linter."""
    print(f"\n🔍 Running ruff linter...")

    cmd = ["ruff", "check"]
    if not check_only:
        cmd.append("--fix")
    cmd.append(path if path else "src/")

    success, output = run_command(cmd, project_root, "ruff")

    if not success:
        print(f"❌ Ruff found issues:\n{output}")
        return False
    else:
        if check_only:
            print("✅ Ruff: No issues found")
        else:
            print("✅ Ruff: All fixable issues resolved")
        return True


def check_types_with_mypy(path: str, project_root: Path) -> bool:
    """Run mypy type checker."""
    print(f"\n🔎 Running mypy type checker...")

    cmd = ["mypy"]
    cmd.append(path if path else "src/")

    success, output = run_command(cmd, project_root, "mypy")

    if not success:
        print(f"❌ Mypy found type issues:\n{output}")
        return False
    else:
        print("✅ Mypy: No type issues found")
        return True


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Format and lint Python code with black, ruff, and mypy"
    )
    parser.add_argument(
        "path",
        nargs="?",
        default="",
        help="Specific file or directory to process (default: src/)"
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Check only, don't fix (useful for CI)"
    )
    parser.add_argument(
        "--no-mypy",
        action="store_true",
        help="Skip mypy type checking"
    )

    args = parser.parse_args()

    project_root = find_project_root()
    print(f"📁 Project root: {project_root}\n")

    all_passed = True

    # Run black
    if not format_with_black(args.path, args.check, project_root):
        all_passed = False

    # Run ruff
    if not lint_with_ruff(args.path, args.check, project_root):
        all_passed = False

    # Run mypy
    if not args.no_mypy:
        if not check_types_with_mypy(args.path, project_root):
            all_passed = False

    # Summary
    print("\n" + "=" * 60)
    if all_passed:
        print("✅ All checks passed! Code is ready to commit.")
        return 0
    else:
        print("❌ Some checks failed. Please fix issues above.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
