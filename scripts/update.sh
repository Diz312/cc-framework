#!/usr/bin/env bash
# cc-framework update script
# Pulls latest changes and re-runs install
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== cc-framework Update ==="
echo ""

# Check we're in the right repo
if [[ ! -f "$REPO_DIR/core/CLAUDE.md" ]]; then
    echo "ERROR: Not in cc-framework directory"
    exit 1
fi

# Pull latest
echo "Pulling latest changes..."
cd "$REPO_DIR"
git pull --rebase

echo ""
echo "Re-running installer..."
"$SCRIPT_DIR/install.sh" "$@"

echo ""
echo "=== Update Complete ==="
