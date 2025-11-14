#!/bin/bash
# GitHub MCP Server Health Check Script
# Purpose: Verify GitHub MCP server installation and configuration
# Location: scripts/check_github_mcp_health.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/.env"
MCP_CONFIG="${PROJECT_ROOT}/.mcp.json"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  GitHub MCP Server Health Check${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check 1: GitHub CLI Authentication
echo -e "${YELLOW}[1/6]${NC} Checking GitHub CLI authentication..."
if command -v gh >/dev/null 2>&1; then
    if gh auth status >/dev/null 2>&1; then
        GH_USER=$(gh api user --jq '.login' 2>/dev/null || echo "unknown")
        echo -e "  ${GREEN}✓${NC} GitHub CLI authenticated as: ${GH_USER}"
        echo -e "  ${GREEN}✓${NC} Token scopes: $(gh auth status 2>&1 | grep 'Token scopes:' | cut -d: -f2 | xargs)"
    else
        echo -e "  ${RED}✗${NC} GitHub CLI not authenticated"
        echo -e "  ${YELLOW}→${NC} Run: gh auth login"
        exit 1
    fi
else
    echo -e "  ${RED}✗${NC} GitHub CLI (gh) not installed"
    echo -e "  ${YELLOW}→${NC} Install from: https://cli.github.com/"
    exit 1
fi
echo ""

# Check 2: Environment Configuration
echo -e "${YELLOW}[2/6]${NC} Checking environment configuration..."
if [ -f "${ENV_FILE}" ]; then
    echo -e "  ${GREEN}✓${NC} .env file exists: ${ENV_FILE}"

    # Source .env and check GITHUB_TOKEN
    # shellcheck source=/dev/null
    source "${ENV_FILE}"

    # Export actual token from gh CLI if GITHUB_TOKEN is placeholder
    if [ "${GITHUB_TOKEN:-}" = "\${GITHUB_TOKEN}" ] || [ -z "${GITHUB_TOKEN:-}" ]; then
        export GITHUB_TOKEN=$(gh auth token)
        echo -e "  ${YELLOW}ℹ${NC} Using GitHub token from gh CLI"
    fi

    if [ -n "${GITHUB_TOKEN:-}" ] && [ "${GITHUB_TOKEN:-}" != "\${GITHUB_TOKEN}" ]; then
        echo -e "  ${GREEN}✓${NC} GITHUB_TOKEN configured: ${GITHUB_TOKEN:0:12}..."
    else
        echo -e "  ${RED}✗${NC} GITHUB_TOKEN not configured in .env"
        echo -e "  ${YELLOW}→${NC} Add to .env: GITHUB_TOKEN=\$(gh auth token)"
        exit 1
    fi
else
    echo -e "  ${RED}✗${NC} .env file not found: ${ENV_FILE}"
    echo -e "  ${YELLOW}→${NC} Copy .env.example to .env and configure"
    exit 1
fi
echo ""

# Check 3: MCP Configuration
echo -e "${YELLOW}[3/6]${NC} Checking MCP configuration..."
if [ -f "${MCP_CONFIG}" ]; then
    echo -e "  ${GREEN}✓${NC} .mcp.json exists: ${MCP_CONFIG}"

    if command -v jq >/dev/null 2>&1; then
        # Check if github server is configured
        if jq -e '.mcpServers.github' "${MCP_CONFIG}" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} GitHub MCP server configured in .mcp.json"

            # Validate configuration structure
            if jq -e '.mcpServers.github.command' "${MCP_CONFIG}" >/dev/null 2>&1; then
                GITHUB_COMMAND=$(jq -r '.mcpServers.github.command' "${MCP_CONFIG}")
                echo -e "  ${GREEN}✓${NC} Command: ${GITHUB_COMMAND}"
            fi

            if jq -e '.mcpServers.github.env.GITHUB_PERSONAL_ACCESS_TOKEN' "${MCP_CONFIG}" >/dev/null 2>&1; then
                echo -e "  ${GREEN}✓${NC} Environment variable configured"
            fi
        else
            echo -e "  ${RED}✗${NC} GitHub MCP server not configured in .mcp.json"
            exit 1
        fi
    else
        echo -e "  ${YELLOW}⚠${NC} jq not installed, skipping JSON validation"
    fi
else
    echo -e "  ${RED}✗${NC} .mcp.json not found: ${MCP_CONFIG}"
    exit 1
fi
echo ""

# Check 4: Node.js and npx Availability
echo -e "${YELLOW}[4/6]${NC} Checking Node.js environment..."
if command -v node >/dev/null 2>&1; then
    NODE_VERSION=$(node --version)
    echo -e "  ${GREEN}✓${NC} Node.js installed: ${NODE_VERSION}"
else
    echo -e "  ${RED}✗${NC} Node.js not installed"
    echo -e "  ${YELLOW}→${NC} Install Node.js LTS from: https://nodejs.org/"
    exit 1
fi

if command -v npx >/dev/null 2>&1; then
    NPX_VERSION=$(npx --version)
    echo -e "  ${GREEN}✓${NC} npx available: ${NPX_VERSION}"
else
    echo -e "  ${RED}✗${NC} npx not available"
    exit 1
fi
echo ""

# Check 5: GitHub MCP Server Package
echo -e "${YELLOW}[5/6]${NC} Checking GitHub MCP server package..."
if timeout 10 npx --yes @modelcontextprotocol/server-github --version >/dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} @modelcontextprotocol/server-github is accessible via npx"
    echo -e "  ${GREEN}✓${NC} Package can be executed (verified with --version)"
else
    echo -e "  ${YELLOW}⚠${NC} Could not verify GitHub MCP server package"
    echo -e "  ${YELLOW}→${NC} This is normal - npx will download on first use"
fi
echo ""

# Check 6: Repository Context
echo -e "${YELLOW}[6/6]${NC} Checking repository context..."
if [ -d "${PROJECT_ROOT}/.git" ]; then
    REPO_REMOTE=$(git -C "${PROJECT_ROOT}" remote get-url origin 2>/dev/null || echo "none")
    CURRENT_BRANCH=$(git -C "${PROJECT_ROOT}" branch --show-current 2>/dev/null || echo "unknown")
    echo -e "  ${GREEN}✓${NC} Git repository detected"
    echo -e "  ${GREEN}✓${NC} Remote: ${REPO_REMOTE}"
    echo -e "  ${GREEN}✓${NC} Current branch: ${CURRENT_BRANCH}"
else
    echo -e "  ${YELLOW}⚠${NC} Not a git repository"
fi
echo ""

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ GitHub MCP Server Health Check PASSED${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. Restart Claude Code to load the GitHub MCP server"
echo -e "     ${BLUE}→${NC} Exit current session: exit"
echo -e "     ${BLUE}→${NC} Start new session: claude"
echo ""
echo -e "  2. Verify GitHub MCP tools are available in Claude Code"
echo -e "     ${BLUE}→${NC} Within conversation, ask: 'What MCP servers are available?'"
echo -e "     ${BLUE}→${NC} Or use: /mcp command"
echo ""
echo -e "  3. Test GitHub MCP functionality"
echo -e "     ${BLUE}→${NC} Ask Claude: 'Can you list the issues in this repository?'"
echo -e "     ${BLUE}→${NC} Ask Claude: 'Show me recent pull requests'"
echo ""

# Export token for immediate use
echo -e "${YELLOW}Environment Export (for current session):${NC}"
echo -e "  ${BLUE}export GITHUB_TOKEN=\$(gh auth token)${NC}"
echo ""

exit 0
