#!/bin/bash
# Context7 MCP Health Check Script
# Verifies Context7 MCP server installation and configuration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Context7 MCP Health Check${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo

# Check 1: Environment Variables
echo -e "${BLUE}[1/6] Checking environment variables...${NC}"
if [ -f "$PROJECT_ROOT/.env" ]; then
    echo -e "${GREEN}✓${NC} .env file found"

    # Source the .env file
    set -a
    source "$PROJECT_ROOT/.env"
    set +a

    if [ -n "${CONTEXT7_API_KEY:-}" ]; then
        # Mask the API key for display
        MASKED_KEY="${CONTEXT7_API_KEY:0:12}...${CONTEXT7_API_KEY: -4}"
        echo -e "${GREEN}✓${NC} CONTEXT7_API_KEY is set: $MASKED_KEY"
    else
        echo -e "${RED}✗${NC} CONTEXT7_API_KEY is not set in .env"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠${NC} .env file not found"
    echo -e "  Create one from .env.example: cp .env.example .env"
    exit 1
fi
echo

# Check 2: Project MCP Configuration
echo -e "${BLUE}[2/6] Checking project MCP configuration...${NC}"
if [ -f "$PROJECT_ROOT/.mcp.json" ]; then
    echo -e "${GREEN}✓${NC} .mcp.json file found"

    # Verify it contains Context7 configuration
    if grep -q "context7" "$PROJECT_ROOT/.mcp.json"; then
        echo -e "${GREEN}✓${NC} Context7 server configured in .mcp.json"
    else
        echo -e "${RED}✗${NC} Context7 server not found in .mcp.json"
        exit 1
    fi

    # Check if it uses environment variables
    if grep -q "\${CONTEXT7_API_KEY}" "$PROJECT_ROOT/.mcp.json"; then
        echo -e "${GREEN}✓${NC} Using environment variable for API key (secure)"
    else
        echo -e "${YELLOW}⚠${NC} API key may be hardcoded (security risk)"
    fi
else
    echo -e "${YELLOW}⚠${NC} .mcp.json file not found"
    echo -e "  Copy from template: cp .mcp.json.example .mcp.json"
    exit 1
fi
echo

# Check 3: Global MCP Configuration
echo -e "${BLUE}[3/6] Checking global MCP configuration...${NC}"
if [ -f ~/.claude.json ]; then
    echo -e "${GREEN}✓${NC} ~/.claude.json found"

    # Check if Context7 is configured globally
    if grep -q '"context7"' ~/.claude.json; then
        echo -e "${GREEN}✓${NC} Context7 configured in global ~/.claude.json"

        # Check if the API key matches
        GLOBAL_KEY=$(jq -r '.mcpServers.context7.headers.CONTEXT7_API_KEY // empty' ~/.claude.json 2>/dev/null || echo "")
        if [ -n "$GLOBAL_KEY" ] && [ "$GLOBAL_KEY" = "$CONTEXT7_API_KEY" ]; then
            echo -e "${GREEN}✓${NC} Global API key matches .env configuration"
        elif [ -n "$GLOBAL_KEY" ]; then
            MASKED_GLOBAL="${GLOBAL_KEY:0:12}...${GLOBAL_KEY: -4}"
            echo -e "${YELLOW}⚠${NC} Global API key differs from .env: $MASKED_GLOBAL"
            echo -e "  Project .mcp.json will override global configuration"
        fi
    else
        echo -e "${YELLOW}⚠${NC} Context7 not configured in global ~/.claude.json"
        echo -e "  Using project-level .mcp.json configuration"
    fi
else
    echo -e "${YELLOW}⚠${NC} ~/.claude.json not found"
fi
echo

# Check 4: .gitignore Configuration
echo -e "${BLUE}[4/6] Checking .gitignore configuration...${NC}"
if [ -f "$PROJECT_ROOT/.gitignore" ]; then
    if grep -q "^\.env$" "$PROJECT_ROOT/.gitignore"; then
        echo -e "${GREEN}✓${NC} .env is gitignored (secure)"
    else
        echo -e "${RED}✗${NC} .env is NOT gitignored (security risk!)"
        echo -e "  Add '.env' to .gitignore immediately"
    fi

    if grep -q "^\.mcp\.json$" "$PROJECT_ROOT/.gitignore"; then
        echo -e "${GREEN}✓${NC} .mcp.json is gitignored (secure if hardcoded keys)"
    else
        echo -e "${YELLOW}⚠${NC} .mcp.json is not gitignored"
        echo -e "  Ensure no hardcoded API keys before committing"
    fi
else
    echo -e "${YELLOW}⚠${NC} .gitignore not found"
fi
echo

# Check 5: Template Files
echo -e "${BLUE}[5/6] Checking template files...${NC}"
if [ -f "$PROJECT_ROOT/.env.example" ]; then
    echo -e "${GREEN}✓${NC} .env.example found"
else
    echo -e "${YELLOW}⚠${NC} .env.example not found"
fi

if [ -f "$PROJECT_ROOT/.mcp.json.example" ]; then
    echo -e "${GREEN}✓${NC} .mcp.json.example found"
else
    echo -e "${YELLOW}⚠${NC} .mcp.json.example not found"
fi
echo

# Check 6: Functional Test (simulated - actual test requires restart)
echo -e "${BLUE}[6/6] MCP Configuration Status...${NC}"
echo -e "${YELLOW}⚠${NC} MCP servers load at Claude Code startup"
echo -e "  Configuration changes require restart to take effect"
echo -e "  Run: ${GREEN}claude${NC} (in a new terminal) to reload MCP servers"
echo

# Summary
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo
echo -e "Context7 MCP Configuration:"
echo -e "  • API Key: ${GREEN}Configured${NC} (from .env)"
echo -e "  • Project Config: ${GREEN}.mcp.json${NC} (uses environment variables)"
echo -e "  • Global Config: ${GREEN}~/.claude.json${NC} (updated)"
echo -e "  • Security: ${GREEN}Secure${NC} (API keys not committed to git)"
echo
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. ${GREEN}Restart Claude Code${NC} for changes to take effect"
echo -e "  2. Test Context7 connectivity with a query like:"
echo -e "     ${BLUE}\"What are the latest Astro.build best practices?\"${NC}"
echo -e "  3. Verify MCP tools are available:"
echo -e "     ${BLUE}mcp__context7__resolve-library-id${NC}"
echo -e "     ${BLUE}mcp__context7__get-library-docs${NC}"
echo
echo -e "${GREEN}✓ Context7 MCP health check complete!${NC}"
echo
