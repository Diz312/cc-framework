#!/usr/bin/env bash
#
# cc-framework installer
#
# Installs the framework into ~/.claude/ for use with Claude Code.
# Supports selective layer installation.
#
# Usage:
#   ./scripts/install.sh                    # Install core only
#   ./scripts/install.sh --domain data-engineering  # Install core + data engineering
#   ./scripts/install.sh --platform gcp     # Install core + GCP module
#   ./scripts/install.sh --all              # Install everything
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$HOME/.claude"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Parse arguments
INSTALL_ALL=false
DOMAINS=()
PLATFORMS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            INSTALL_ALL=true
            shift
            ;;
        --domain)
            DOMAINS+=("$2")
            shift 2
            ;;
        --platform)
            PLATFORMS+=("$2")
            shift 2
            ;;
        --help|-h)
            echo "Usage: install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --all                Install all layers"
            echo "  --domain NAME        Install domain module (data-engineering, analytics, ml-ds, full-stack-data)"
            echo "  --platform NAME      Install platform module (aws, azure, gcp, databricks, snowflake)"
            echo "  -h, --help           Show this help"
            echo ""
            echo "Core (Layer 1) is always installed."
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo ""
echo "======================================"
echo "  cc-framework installer"
echo "======================================"
echo ""

# Verify Claude Code is available
if ! command -v claude &> /dev/null; then
    log_warn "Claude Code CLI not found. Framework will be installed but won't be active until Claude Code is installed."
fi

# Create ~/.claude/ if it doesn't exist
mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/skills"
mkdir -p "$CLAUDE_DIR/agents"
mkdir -p "$CLAUDE_DIR/rules"
mkdir -p "$CLAUDE_DIR/tools"

# ============================================================
# Layer 1: Core (always installed)
# ============================================================
log_info "Installing Layer 1: Core..."

# CLAUDE.md — only install if not already present (don't overwrite user's customizations)
if [[ ! -f "$CLAUDE_DIR/CLAUDE.md" ]]; then
    cp "$REPO_DIR/core/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    log_ok "Installed CLAUDE.md"
else
    log_warn "CLAUDE.md already exists — skipping (compare with core/CLAUDE.md for updates)"
fi

# CODING_STANDARDS.md
cp "$REPO_DIR/core/CODING_STANDARDS.md" "$CLAUDE_DIR/CODING_STANDARDS.md" 2>/dev/null || true

# Settings — merge, don't overwrite
if [[ ! -f "$CLAUDE_DIR/settings.json" ]]; then
    cp "$REPO_DIR/core/settings.json" "$CLAUDE_DIR/settings.json"
    log_ok "Installed settings.json"
else
    log_warn "settings.json already exists — review core/settings.json for recommended permissions"
fi

# Skills
for skill_dir in "$REPO_DIR/core/skills"/*/; do
    if [[ -d "$skill_dir" ]]; then
        skill_name=$(basename "$skill_dir")
        target="$CLAUDE_DIR/skills/$skill_name"
        mkdir -p "$target"
        cp -r "$skill_dir"* "$target/" 2>/dev/null || true
        log_ok "Installed skill: $skill_name"
    fi
done

# Agents
for agent_file in "$REPO_DIR/core/agents"/*.md; do
    if [[ -f "$agent_file" ]]; then
        cp "$agent_file" "$CLAUDE_DIR/agents/"
        log_ok "Installed agent: $(basename "$agent_file" .md)"
    fi
done

# Rules
for rule_file in "$REPO_DIR/core/rules"/*.md; do
    if [[ -f "$rule_file" ]]; then
        mkdir -p "$CLAUDE_DIR/rules"
        cp "$rule_file" "$CLAUDE_DIR/rules/"
        log_ok "Installed rule: $(basename "$rule_file" .md)"
    fi
done

# Tools
for tool_file in "$REPO_DIR/core/tools"/*.py; do
    if [[ -f "$tool_file" ]]; then
        cp "$tool_file" "$CLAUDE_DIR/tools/"
        log_ok "Installed tool: $(basename "$tool_file")"
    fi
done

log_ok "Layer 1 (Core) installed."

# ============================================================
# Layer 2: Domain modules
# ============================================================
install_domain() {
    local domain=$1
    local domain_dir="$REPO_DIR/domain/$domain"

    if [[ ! -d "$domain_dir" ]]; then
        log_error "Domain module not found: $domain"
        return 1
    fi

    log_info "Installing Layer 2: $domain..."

    # Domain CLAUDE.md — append to rules
    if [[ -f "$domain_dir/CLAUDE.md" ]]; then
        mkdir -p "$CLAUDE_DIR/rules"
        cp "$domain_dir/CLAUDE.md" "$CLAUDE_DIR/rules/domain-$domain.md"
        log_ok "Installed domain overlay: $domain"
    fi

    # Domain skills
    if [[ -d "$domain_dir/skills" ]]; then
        for skill_dir in "$domain_dir/skills"/*/; do
            if [[ -d "$skill_dir" ]]; then
                skill_name=$(basename "$skill_dir")
                target="$CLAUDE_DIR/skills/$skill_name"
                mkdir -p "$target"
                cp -r "$skill_dir"* "$target/" 2>/dev/null || true
                log_ok "Installed domain skill: $skill_name"
            fi
        done
    fi

    # Domain agents
    if [[ -d "$domain_dir/agents" ]]; then
        for agent_file in "$domain_dir/agents"/*.md; do
            if [[ -f "$agent_file" ]]; then
                cp "$agent_file" "$CLAUDE_DIR/agents/"
                log_ok "Installed domain agent: $(basename "$agent_file" .md)"
            fi
        done
    fi

    # Domain rules
    if [[ -d "$domain_dir/rules" ]]; then
        for rule_file in "$domain_dir/rules"/*.md; do
            if [[ -f "$rule_file" ]]; then
                mkdir -p "$CLAUDE_DIR/rules"
                cp "$rule_file" "$CLAUDE_DIR/rules/"
                log_ok "Installed domain rule: $(basename "$rule_file" .md)"
            fi
        done
    fi

    log_ok "Layer 2 ($domain) installed."
}

if $INSTALL_ALL; then
    for domain_dir in "$REPO_DIR/domain"/*/; do
        if [[ -d "$domain_dir" ]]; then
            install_domain "$(basename "$domain_dir")"
        fi
    done
else
    for domain in "${DOMAINS[@]}"; do
        install_domain "$domain"
    done
fi

# ============================================================
# Layer 3: Platform modules
# ============================================================
install_platform() {
    local platform=$1
    local platform_dir="$REPO_DIR/platform/$platform"

    if [[ ! -d "$platform_dir" ]]; then
        log_error "Platform module not found: $platform"
        return 1
    fi

    log_info "Installing Layer 3: $platform..."

    # Platform CLAUDE.md — append to rules
    if [[ -f "$platform_dir/CLAUDE.md" ]]; then
        mkdir -p "$CLAUDE_DIR/rules"
        cp "$platform_dir/CLAUDE.md" "$CLAUDE_DIR/rules/platform-$platform.md"
        log_ok "Installed platform overlay: $platform"
    fi

    # Platform skills
    if [[ -d "$platform_dir/skills" ]]; then
        for skill_dir in "$platform_dir/skills"/*/; do
            if [[ -d "$skill_dir" ]]; then
                skill_name=$(basename "$skill_dir")
                target="$CLAUDE_DIR/skills/$skill_name"
                mkdir -p "$target"
                cp -r "$skill_dir"* "$target/" 2>/dev/null || true
                log_ok "Installed platform skill: $skill_name"
            fi
        done
    fi

    # Platform rules
    if [[ -d "$platform_dir/rules" ]]; then
        for rule_file in "$platform_dir/rules"/*.md; do
            if [[ -f "$rule_file" ]]; then
                mkdir -p "$CLAUDE_DIR/rules"
                cp "$rule_file" "$CLAUDE_DIR/rules/"
                log_ok "Installed platform rule: $(basename "$rule_file" .md)"
            fi
        done
    fi

    # MCP config — inform user, don't auto-install (project-specific)
    if [[ -f "$platform_dir/mcp-config.json" ]]; then
        log_warn "MCP config template available at: $platform_dir/mcp-config.json"
        log_warn "Copy to your project's .mcp.json and configure credentials."
    fi

    log_ok "Layer 3 ($platform) installed."
}

if $INSTALL_ALL; then
    for platform_dir in "$REPO_DIR/platform"/*/; do
        if [[ -d "$platform_dir" ]]; then
            install_platform "$(basename "$platform_dir")"
        fi
    done
else
    for platform in "${PLATFORMS[@]}"; do
        install_platform "$platform"
    done
fi

# ============================================================
# Summary
# ============================================================
echo ""
echo "======================================"
echo "  Installation Complete"
echo "======================================"
echo ""
log_ok "Core (Layer 1): installed"
for domain in "${DOMAINS[@]}"; do
    log_ok "Domain ($domain): installed"
done
for platform in "${PLATFORMS[@]}"; do
    log_ok "Platform ($platform): installed"
done
echo ""
log_info "Next steps:"
echo "  1. Start Claude Code in your project directory"
echo "  2. Run /client-onboard to configure for your client"
echo "  3. Run /discovery to start your first project"
echo ""
