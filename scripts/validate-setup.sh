#!/usr/bin/env bash
# cc-framework validation script
# Verifies that the framework is correctly installed
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
PASS=0
FAIL=0
WARN=0

pass() { echo "  [PASS] $1"; ((PASS++)); }
fail() { echo "  [FAIL] $1"; ((FAIL++)); }
warn() { echo "  [WARN] $1"; ((WARN++)); }

echo "=== cc-framework Installation Validation ==="
echo ""

# --- Core Files ---
echo "Layer 1: Core Files"

[[ -f "$CLAUDE_DIR/CLAUDE.md" ]] && pass "CLAUDE.md exists" || fail "CLAUDE.md missing"
[[ -f "$CLAUDE_DIR/CODING_STANDARDS.md" ]] && pass "CODING_STANDARDS.md exists" || fail "CODING_STANDARDS.md missing"
[[ -f "$CLAUDE_DIR/settings.json" ]] && pass "settings.json exists" || fail "settings.json missing"

# --- Rules ---
echo ""
echo "Layer 1: Rules"

for rule in security git-workflow code-review; do
    if [[ -f "$CLAUDE_DIR/rules/$rule.md" ]]; then
        # Check for valid frontmatter
        if head -1 "$CLAUDE_DIR/rules/$rule.md" | grep -q "^---"; then
            pass "rules/$rule.md exists with frontmatter"
        else
            warn "rules/$rule.md exists but missing YAML frontmatter"
        fi
    else
        fail "rules/$rule.md missing"
    fi
done

# --- Skills ---
echo ""
echo "Layer 1: Skills"

for skill in format-and-lint test-runner client-onboard discovery design build test deploy; do
    if [[ -f "$CLAUDE_DIR/skills/$skill/SKILL.md" ]]; then
        pass "skills/$skill/SKILL.md exists"
    else
        fail "skills/$skill/SKILL.md missing"
    fi
done

# --- Agents ---
echo ""
echo "Layer 1: Agents"

for agent in framework-verifier test-writer solution-architect requirements-collector brownfield-analyzer; do
    if [[ -f "$CLAUDE_DIR/agents/$agent.md" ]]; then
        pass "agents/$agent.md exists"
    else
        fail "agents/$agent.md missing"
    fi
done

# --- Tools ---
echo ""
echo "Layer 1: Tools"

for tool in run_tests.py format_lint.py; do
    if [[ -f "$CLAUDE_DIR/tools/$tool" ]]; then
        if [[ -x "$CLAUDE_DIR/tools/$tool" ]] || head -1 "$CLAUDE_DIR/tools/$tool" | grep -q "python"; then
            pass "tools/$tool exists"
        else
            warn "tools/$tool exists but may not be executable"
        fi
    else
        fail "tools/$tool missing"
    fi
done

# --- Domain Modules (optional) ---
echo ""
echo "Layer 2: Domain Modules (optional)"

for domain in data-engineering analytics; do
    if [[ -d "$CLAUDE_DIR/domain/$domain" ]] || ls "$CLAUDE_DIR/rules/domain-$domain"* &>/dev/null 2>&1; then
        pass "Domain module '$domain' detected"
    else
        warn "Domain module '$domain' not installed (optional)"
    fi
done

# --- Platform Modules (optional) ---
echo ""
echo "Layer 3: Platform Modules (optional)"

for platform in gcp aws azure databricks snowflake; do
    if [[ -d "$CLAUDE_DIR/platform/$platform" ]] || ls "$CLAUDE_DIR/rules/platform-$platform"* &>/dev/null 2>&1; then
        pass "Platform module '$platform' detected"
    else
        warn "Platform module '$platform' not installed (optional)"
    fi
done

# --- Settings Validation ---
echo ""
echo "Settings Validation"

if [[ -f "$CLAUDE_DIR/settings.json" ]]; then
    if python3 -c "import json; json.load(open('$CLAUDE_DIR/settings.json'))" 2>/dev/null; then
        pass "settings.json is valid JSON"
    else
        fail "settings.json is invalid JSON"
    fi
fi

# --- Managed Settings (Enterprise) ---
echo ""
echo "Enterprise: Managed Settings"

if [[ "$(uname)" == "Darwin" ]]; then
    MANAGED_PATH="/Library/Application Support/ClaudeCode/managed-settings.json"
else
    MANAGED_PATH="/etc/claude-code/managed-settings.json"
fi

if [[ -f "$MANAGED_PATH" ]]; then
    if python3 -c "import json; json.load(open('$MANAGED_PATH'))" 2>/dev/null; then
        pass "managed-settings.json exists and is valid"
    else
        fail "managed-settings.json exists but is invalid JSON"
    fi
else
    warn "managed-settings.json not deployed (enterprise feature)"
fi

# --- Summary ---
echo ""
echo "=== Summary ==="
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo "  Warnings: $WARN"
echo ""

if [[ $FAIL -gt 0 ]]; then
    echo "RESULT: FAILED — $FAIL issue(s) need attention"
    exit 1
else
    echo "RESULT: PASSED"
    [[ $WARN -gt 0 ]] && echo "  ($WARN warning(s) — optional items not installed)"
    exit 0
fi
