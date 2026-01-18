#!/bin/bash
# setup_mcp_config.sh - Set up all 7 MCP servers for Claude Code
# Configures MCP servers at user scope for availability across all projects
#
# Usage:
#   ./setup_mcp_config.sh           # Interactive setup
#   ./setup_mcp_config.sh --dry-run # Show commands without executing
#   ./setup_mcp_config.sh --verify  # Only verify existing setup

set -euo pipefail

source "$(dirname "$0")/../006-logs/logger.sh"

# Get repo root directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SECRETS_TEMPLATE="$REPO_DIR/configs/mcp/.mcp-secrets.template"
SECRETS_FILE="$HOME/.mcp-secrets"
PLAYWRIGHT_WRAPPER="$HOME/.local/bin/playwright-mcp-wrapper.sh"

# Parse arguments
DRY_RUN=false
VERIFY_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verify)
            VERIFY_ONLY=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

log "INFO" "═══════════════════════════════════════════════════════════════════"
log "INFO" "  MCP Server Setup (All 7 Servers)"
log "INFO" "═══════════════════════════════════════════════════════════════════"

# Check prerequisites
check_prerequisites() {
    log "INFO" "Checking prerequisites..."
    local WARNINGS=0

    # Check Claude Code CLI
    if ! command -v claude &> /dev/null; then
        log "ERROR" "Claude Code CLI not found - install first"
        exit 1
    fi
    log "SUCCESS" "✓ Claude Code CLI installed"

    # Check GitHub CLI
    if ! command -v gh &> /dev/null; then
        log "WARNING" "gh CLI not found - install from https://cli.github.com/"
        ((WARNINGS++))
    elif ! gh auth status &> /dev/null 2>&1; then
        log "WARNING" "gh CLI not authenticated - run 'gh auth login' first"
        ((WARNINGS++))
    else
        log "SUCCESS" "✓ GitHub CLI authenticated"
    fi

    # Check uvx
    if ! command -v uvx &> /dev/null; then
        log "WARNING" "uvx not found - install with: curl -LsSf https://astral.sh/uv/install.sh | sh"
        ((WARNINGS++))
    else
        log "SUCCESS" "✓ Python UV (uvx) installed"
    fi

    # Check fnm/Node.js
    if ! command -v fnm &> /dev/null; then
        log "WARNING" "fnm not found - install with: curl -fsSL https://fnm.vercel.app/install | bash"
        ((WARNINGS++))
    else
        log "SUCCESS" "✓ fnm installed"
    fi

    if ! command -v npx &> /dev/null; then
        log "WARNING" "npx not found - install Node.js via fnm: fnm install --lts"
        ((WARNINGS++))
    else
        log "SUCCESS" "✓ Node.js (npx) installed"
    fi

    # Check secrets file
    if [ -f "$SECRETS_FILE" ]; then
        log "SUCCESS" "✓ Secrets file exists: $SECRETS_FILE"
    else
        log "WARNING" "Secrets file not found: $SECRETS_FILE"
        log "INFO" "  Create with: cp $SECRETS_TEMPLATE ~/.mcp-secrets"
        ((WARNINGS++))
    fi

    # Check Context7 API key (required for header auth)
    if [ -n "${CONTEXT7_API_KEY:-}" ]; then
        log "SUCCESS" "✓ CONTEXT7_API_KEY is set"
    else
        log "WARNING" "CONTEXT7_API_KEY not set in environment"
        log "INFO" "  Set in ~/.mcp-secrets and source it: source ~/.mcp-secrets"
        ((WARNINGS++))
    fi

    if [ $WARNINGS -gt 0 ]; then
        log "WARNING" "$WARNINGS prerequisite(s) need attention"
        if [ "$VERIFY_ONLY" = true ]; then
            return
        fi
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Create wrapper scripts
create_wrapper_scripts() {
    log "INFO" "Creating wrapper scripts..."

    mkdir -p "$HOME/.local/bin"

    if [ "$DRY_RUN" = true ]; then
        log "INFO" "[DRY-RUN] Would create: $PLAYWRIGHT_WRAPPER"
        return
    fi

    # Playwright wrapper
    if [ ! -f "$PLAYWRIGHT_WRAPPER" ]; then
        cat > "$PLAYWRIGHT_WRAPPER" << 'EOF'
#!/bin/bash
# Playwright MCP Wrapper for Claude Code
export PATH="$HOME/.local/bin:$PATH"
if command -v fnm &> /dev/null; then
    eval "$(fnm env)"
fi
exec npx -y @playwright/mcp@latest "$@"
EOF
        chmod +x "$PLAYWRIGHT_WRAPPER"
        log "SUCCESS" "Created: $PLAYWRIGHT_WRAPPER"
    else
        log "INFO" "Wrapper already exists: $PLAYWRIGHT_WRAPPER"
    fi
}

# Add MCP servers
add_mcp_servers() {
    log "INFO" ""
    log "INFO" "Adding MCP servers to user scope..."

    # Define all 7 servers
    declare -A SERVERS=(
        ["context7"]="--transport http context7 https://mcp.context7.com/mcp --header 'CONTEXT7_API_KEY: '\$CONTEXT7_API_KEY"
        ["github"]="github -- bash -c 'GITHUB_PERSONAL_ACCESS_TOKEN=\$(gh auth token) npx -y @modelcontextprotocol/server-github'"
        ["markitdown"]="markitdown -- uvx markitdown-mcp"
        ["playwright"]="playwright -- $PLAYWRIGHT_WRAPPER"
        ["hf-mcp-server"]="--transport http hf-mcp-server https://huggingface.co/mcp"
        ["shadcn"]="shadcn -- npx shadcn@latest mcp"
        ["shadcn-ui"]="shadcn-ui -- bash -c 'GITHUB_PERSONAL_ACCESS_TOKEN=\$(gh auth token) npx @jpisnice/shadcn-ui-mcp-server'"
    )

    # Order for adding
    local ORDER=("context7" "github" "markitdown" "playwright" "hf-mcp-server" "shadcn" "shadcn-ui")

    for server in "${ORDER[@]}"; do
        local args="${SERVERS[$server]}"

        if [ "$DRY_RUN" = true ]; then
            log "INFO" "[DRY-RUN] claude mcp add --scope user $args"
            continue
        fi

        log "INFO" "Adding $server..."

        # Remove existing first (ignore errors)
        claude mcp remove --scope user "$server" 2>/dev/null || true

        # Add server
        if eval "claude mcp add --scope user $args" 2>/dev/null; then
            log "SUCCESS" "✓ Added $server"
        else
            log "WARNING" "Failed to add $server"
        fi
    done
}

# Verify setup
verify_setup() {
    log "INFO" ""
    log "INFO" "Verifying MCP server connectivity..."

    if [ "$DRY_RUN" = true ]; then
        log "INFO" "[DRY-RUN] Would run: claude mcp list"
        return
    fi

    local OUTPUT
    OUTPUT=$(claude mcp list 2>&1) || true

    log "INFO" ""
    log "INFO" "$OUTPUT"
    log "INFO" ""

    # Count connected servers
    local CONNECTED
    CONNECTED=$(echo "$OUTPUT" | grep -c "✓ Connected" || echo "0")

    if [ "$CONNECTED" -eq 7 ]; then
        log "SUCCESS" "All 7 MCP servers connected!"
    elif [ "$CONNECTED" -gt 0 ]; then
        log "WARNING" "$CONNECTED/7 servers connected"
    else
        log "ERROR" "No servers connected - check configuration"
    fi
}

# NOTE: Project-level .mcp.json is NOT created
# All MCP servers are configured at user scope (~/.claude.json) only
# This prevents conflicts and ensures servers are available across all projects

# Main execution
main() {
    if [ "$DRY_RUN" = true ]; then
        log "INFO" "Running in DRY-RUN mode - no changes will be made"
        log "INFO" ""
    fi

    if [ "$VERIFY_ONLY" = true ]; then
        check_prerequisites
        verify_setup
        exit 0
    fi

    check_prerequisites
    create_wrapper_scripts
    add_mcp_servers
    verify_setup

    log "INFO" ""
    log "INFO" "═══════════════════════════════════════════════════════════════════"
    log "INFO" "  Setup Complete!"
    log "INFO" "═══════════════════════════════════════════════════════════════════"
    log "INFO" ""
    log "INFO" "MCP servers are configured at user scope (~/.claude.json)"
    log "INFO" "They are now available across ALL projects."
    log "INFO" ""
    log "INFO" "To verify in Claude Code, type: /mcp"
    log "INFO" ""
    log "INFO" "Documentation: .claude/instructions-for-agents/guides/mcp-new-machine-setup.md"
}

main "$@"
