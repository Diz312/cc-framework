#!/usr/bin/env bash
# cc-framework new engagement scaffolding
# Creates project .claude/ directory from templates as a fallback when /client-onboard is not used
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$REPO_DIR/client/templates"

usage() {
    echo "Usage: $0 <project-directory> [options]"
    echo ""
    echo "Scaffolds a new client engagement project with cc-framework templates."
    echo "For full agentic onboarding, use '/client-onboard' in Claude Code instead."
    echo ""
    echo "Options:"
    echo "  --client NAME       Client name (used in templates)"
    echo "  --platform PLATFORM Cloud platform (gcp, aws, azure)"
    echo "  --help              Show this help"
    echo ""
    echo "Example:"
    echo "  $0 /path/to/project --client acme-corp --platform gcp"
}

# Parse args
PROJECT_DIR=""
CLIENT_NAME=""
PLATFORM=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --client) CLIENT_NAME="$2"; shift 2 ;;
        --platform) PLATFORM="$2"; shift 2 ;;
        --help) usage; exit 0 ;;
        -*) echo "Unknown option: $1"; usage; exit 1 ;;
        *) PROJECT_DIR="$1"; shift ;;
    esac
done

if [[ -z "$PROJECT_DIR" ]]; then
    echo "ERROR: Project directory required"
    usage
    exit 1
fi

# Validate
if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "ERROR: Directory does not exist: $PROJECT_DIR"
    exit 1
fi

if [[ -d "$PROJECT_DIR/.claude" ]]; then
    echo "ERROR: .claude/ directory already exists in $PROJECT_DIR"
    echo "Use /client-onboard in Claude Code to modify existing configuration."
    exit 1
fi

echo "=== Scaffolding New Engagement ==="
echo "  Project: $PROJECT_DIR"
[[ -n "$CLIENT_NAME" ]] && echo "  Client: $CLIENT_NAME"
[[ -n "$PLATFORM" ]] && echo "  Platform: $PLATFORM"
echo ""

# Copy templates
echo "Creating .claude/ directory..."
cp -r "$TEMPLATES_DIR/.claude" "$PROJECT_DIR/.claude"

echo "Creating .mcp.json..."
cp "$TEMPLATES_DIR/.mcp.json" "$PROJECT_DIR/.mcp.json"

# Substitute client name if provided
if [[ -n "$CLIENT_NAME" ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s/<!-- CLIENT_NAME -->/$CLIENT_NAME/g" "$PROJECT_DIR/.claude/CLAUDE.md"
    else
        sed -i "s/<!-- CLIENT_NAME -->/$CLIENT_NAME/g" "$PROJECT_DIR/.claude/CLAUDE.md"
    fi
    echo "  Replaced client name placeholders"
fi

# Add platform-specific notes if platform specified
if [[ -n "$PLATFORM" ]]; then
    PLATFORM_CLAUDE="$REPO_DIR/platform/$PLATFORM/CLAUDE.md"
    if [[ -f "$PLATFORM_CLAUDE" ]]; then
        echo "" >> "$PROJECT_DIR/.claude/CLAUDE.md"
        echo "## Platform: $PLATFORM" >> "$PROJECT_DIR/.claude/CLAUDE.md"
        echo "" >> "$PROJECT_DIR/.claude/CLAUDE.md"
        echo "See ~/.claude/platform/$PLATFORM/ for platform-specific standards." >> "$PROJECT_DIR/.claude/CLAUDE.md"
        echo "  Added platform reference to CLAUDE.md"
    else
        echo "  WARNING: Platform module '$PLATFORM' not found in framework"
    fi
fi

echo ""
echo "=== Scaffolding Complete ==="
echo ""
echo "Created:"
echo "  $PROJECT_DIR/.claude/settings.json"
echo "  $PROJECT_DIR/.claude/CLAUDE.md"
echo "  $PROJECT_DIR/.claude/rules/client-ea.md"
echo "  $PROJECT_DIR/.mcp.json"
echo ""
echo "Next steps:"
echo "  1. Edit .claude/CLAUDE.md with project details"
echo "  2. Edit .claude/rules/client-ea.md with client EA patterns"
echo "  3. Configure .mcp.json with Jira/Confluence credentials"
echo "  4. Or run '/client-onboard' in Claude Code for agentic onboarding"
