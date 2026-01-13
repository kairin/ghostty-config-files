#!/bin/bash
# setup_mcp_config.sh - Generate MCP configuration for Claude Code
# Creates empty .mcp.json and provides user-scoped setup instructions

source "$(dirname "$0")/../006-logs/logger.sh"

# Get repo root directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
MCP_CONFIG="$REPO_DIR/.mcp.json"

log "INFO" "Setting up MCP configuration for Claude Code..."

# Create empty project-level config (MCP servers are user-scoped)
if [ ! -f "$MCP_CONFIG" ]; then
    log "INFO" "Creating empty project-level .mcp.json..."
    echo '{"mcpServers": {}}' > "$MCP_CONFIG"
    log "SUCCESS" "Created $MCP_CONFIG"
else
    log "INFO" "Project .mcp.json already exists at $MCP_CONFIG"
fi

# Check prerequisites for user-scoped MCP setup
log "INFO" "Checking prerequisites for user-scoped MCP servers..."

WARNINGS=0

if ! command -v gh &> /dev/null; then
    log "WARNING" "gh CLI not found - install from https://cli.github.com/"
    ((WARNINGS++))
elif ! gh auth status &> /dev/null 2>&1; then
    log "WARNING" "gh CLI not authenticated - run 'gh auth login' first"
    ((WARNINGS++))
fi

if ! command -v uvx &> /dev/null; then
    log "WARNING" "uvx not found - install with: curl -LsSf https://astral.sh/uv/install.sh | sh"
    ((WARNINGS++))
fi

if ! command -v fnm &> /dev/null; then
    log "WARNING" "fnm not found - install with: curl -fsSL https://fnm.vercel.app/install | bash"
    ((WARNINGS++))
fi

if ! command -v npx &> /dev/null; then
    log "WARNING" "npx not found - install Node.js via fnm: fnm install --lts"
    ((WARNINGS++))
fi

# Display user-scoped setup instructions
log "INFO" ""
log "INFO" "═══════════════════════════════════════════════════════════════════"
log "INFO" "  MCP SERVERS ARE NOW USER-SCOPED"
log "INFO" "═══════════════════════════════════════════════════════════════════"
log "INFO" ""
log "INFO" "MCP servers are configured at user level (~/.claude.json),"
log "INFO" "making them available across ALL projects."
log "INFO" ""
log "INFO" "To set up MCP servers, run these commands:"
log "INFO" ""
log "INFO" "  # 1. Create Playwright wrapper script"
log "INFO" "  mkdir -p ~/.local/bin"
log "INFO" "  cat > ~/.local/bin/playwright-mcp-wrapper.sh << 'EOF'"
log "INFO" "  #!/bin/bash"
log "INFO" "  export PATH=\"\$HOME/.local/bin:\$PATH\""
log "INFO" "  if command -v fnm &> /dev/null; then eval \"\$(fnm env)\"; fi"
log "INFO" "  exec npx -y @playwright/mcp@latest"
log "INFO" "  EOF"
log "INFO" "  chmod +x ~/.local/bin/playwright-mcp-wrapper.sh"
log "INFO" ""
log "INFO" "  # 2. Add MCP servers (user scope)"
log "INFO" "  claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp \\"
log "INFO" "    --header \"CONTEXT7_API_KEY: <your-api-key>\""
log "INFO" ""
log "INFO" "  claude mcp add --scope user github -- bash -c 'export PATH=\"\$HOME/.local/bin:\$PATH\" && eval \"\$(fnm env)\" && GITHUB_PERSONAL_ACCESS_TOKEN=\$(gh auth token) npx -y @modelcontextprotocol/server-github'"
log "INFO" ""
log "INFO" "  claude mcp add --scope user markitdown -- uvx markitdown-mcp"
log "INFO" ""
log "INFO" "  claude mcp add --scope user playwright -- ~/.local/bin/playwright-mcp-wrapper.sh"
log "INFO" ""
log "INFO" "  # 3. Verify in Claude Code"
log "INFO" "  claude"
log "INFO" "  /mcp  # Should show 4 connected servers"
log "INFO" ""
log "INFO" "═══════════════════════════════════════════════════════════════════"
log "INFO" ""
log "INFO" "Full documentation: .claude/instructions-for-agents/guides/mcp-new-machine-setup.md"

if [ $WARNINGS -gt 0 ]; then
    log "WARNING" "$WARNINGS prerequisite(s) missing - install them before adding MCP servers"
fi
