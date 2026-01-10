#!/bin/bash
# setup_mcp_config.sh - Generate MCP configuration for Claude Code
# Creates .mcp.json with machine-specific paths if it doesn't exist

source "$(dirname "$0")/../006-logs/logger.sh"

# Get repo root directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
MCP_CONFIG="$REPO_DIR/.mcp.json"

log "INFO" "Setting up MCP configuration for Claude Code..."

# Check if config already exists
if [ -f "$MCP_CONFIG" ]; then
    log "INFO" "MCP configuration already exists at $MCP_CONFIG"
    log "INFO" "Skipping generation to preserve existing config"
    exit 0
fi

# Check prerequisites (warn but continue)
log "INFO" "Checking prerequisites..."

WARNINGS=0

if ! command -v gh &> /dev/null; then
    log "WARNING" "gh CLI not found - GitHub MCP server will not work"
    ((WARNINGS++))
elif ! gh auth status &> /dev/null 2>&1; then
    log "WARNING" "gh CLI not authenticated - run 'gh auth login' first"
    ((WARNINGS++))
fi

if ! command -v uvx &> /dev/null; then
    log "WARNING" "uvx not found - markitdown MCP server will not work"
    ((WARNINGS++))
fi

if ! command -v npx &> /dev/null; then
    log "WARNING" "npx not found - GitHub MCP server will not work"
    ((WARNINGS++))
fi

# Generate the configuration with machine-specific paths
log "INFO" "Generating MCP configuration..."

cat > "$MCP_CONFIG" << EOF
{
  "mcpServers": {
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp"
    },
    "github": {
      "command": "bash",
      "args": ["-c", "GITHUB_PERSONAL_ACCESS_TOKEN=\$(gh auth token) npx @modelcontextprotocol/server-github"]
    },
    "markitdown": {
      "command": "uvx",
      "args": ["markitdown-mcp"]
    },
    "playwright": {
      "command": "$HOME/.local/bin/playwright-mcp-wrapper.sh"
    }
  }
}
EOF

if [ $? -eq 0 ]; then
    log "SUCCESS" "MCP configuration created at $MCP_CONFIG"

    if [ $WARNINGS -gt 0 ]; then
        log "WARNING" "$WARNINGS prerequisite(s) missing - some MCP servers may not work"
        log "INFO" "Install missing tools and re-run to fix"
    fi

    log "INFO" "Restart Claude Code to load MCP servers: exit && claude"
    log "INFO" "Verify with: /mcp (should show 4 connected servers)"
else
    log "ERROR" "Failed to create MCP configuration"
    exit 1
fi
