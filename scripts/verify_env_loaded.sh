#!/bin/bash
# Environment Variable Loading Verification Script
# Verifies that environment variables are properly exported for Claude Code MCP

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Environment Variable Loading Verification${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo

# Check 1: .env file exists
echo -e "${BLUE}[1/5] Checking .env file...${NC}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$PROJECT_ROOT/.env" ]; then
    echo -e "${GREEN}✓${NC} .env file found at: $PROJECT_ROOT/.env"
else
    echo -e "${RED}✗${NC} .env file not found"
    exit 1
fi
echo

# Check 2: Required variables exist in .env
echo -e "${BLUE}[2/5] Checking .env file contents...${NC}"
if grep -q "^CONTEXT7_API_KEY=" "$PROJECT_ROOT/.env"; then
    echo -e "${GREEN}✓${NC} CONTEXT7_API_KEY defined in .env"
else
    echo -e "${RED}✗${NC} CONTEXT7_API_KEY not found in .env"
    exit 1
fi

if grep -q "^GITHUB_TOKEN=" "$PROJECT_ROOT/.env"; then
    echo -e "${GREEN}✓${NC} GITHUB_TOKEN defined in .env"
else
    echo -e "${RED}✗${NC} GITHUB_TOKEN not found in .env"
    exit 1
fi
echo

# Check 3: Variables are exported in current shell
echo -e "${BLUE}[3/5] Checking if variables are exported...${NC}"
if [ -n "${CONTEXT7_API_KEY:-}" ]; then
    MASKED_KEY="${CONTEXT7_API_KEY:0:15}...${CONTEXT7_API_KEY: -4}"
    echo -e "${GREEN}✓${NC} CONTEXT7_API_KEY is exported: $MASKED_KEY"
else
    echo -e "${RED}✗${NC} CONTEXT7_API_KEY is NOT exported to shell environment"
    echo -e "${YELLOW}  Fix: Add environment loading to ~/.zshrc (see CONTEXT7_SETUP.md)${NC}"
    exit 1
fi

if [ -n "${GITHUB_TOKEN:-}" ]; then
    MASKED_TOKEN="${GITHUB_TOKEN:0:15}...${GITHUB_TOKEN: -4}"
    echo -e "${GREEN}✓${NC} GITHUB_TOKEN is exported: $MASKED_TOKEN"
else
    echo -e "${RED}✗${NC} GITHUB_TOKEN is NOT exported to shell environment"
    echo -e "${YELLOW}  Fix: Add environment loading to ~/.zshrc (see GITHUB_MCP_SETUP.md)${NC}"
    exit 1
fi
echo

# Check 4: Shell configuration has auto-loading
echo -e "${BLUE}[4/5] Checking shell configuration...${NC}"
if grep -q "source.*\.env" ~/.zshrc 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Shell configuration includes .env loading"
else
    echo -e "${YELLOW}⚠${NC} Shell configuration does not auto-load .env"
    echo -e "  Consider adding to ~/.zshrc:"
    echo -e "  ${BLUE}if [ -f $PROJECT_ROOT/.env ]; then${NC}"
    echo -e "  ${BLUE}    set -a; source $PROJECT_ROOT/.env; set +a${NC}"
    echo -e "  ${BLUE}fi${NC}"
fi
echo

# Check 5: .mcp.json uses environment variables
echo -e "${BLUE}[5/5] Checking .mcp.json configuration...${NC}"
if [ -f "$PROJECT_ROOT/.mcp.json" ]; then
    echo -e "${GREEN}✓${NC} .mcp.json file found"

    if grep -q "\${CONTEXT7_API_KEY}" "$PROJECT_ROOT/.mcp.json"; then
        echo -e "${GREEN}✓${NC} .mcp.json uses environment variable for CONTEXT7_API_KEY (secure)"
    else
        echo -e "${YELLOW}⚠${NC} .mcp.json may have hardcoded API key (security risk)"
    fi

    if grep -q "\${GITHUB_TOKEN}" "$PROJECT_ROOT/.mcp.json"; then
        echo -e "${GREEN}✓${NC} .mcp.json uses environment variable for GITHUB_TOKEN (secure)"
    else
        echo -e "${YELLOW}⚠${NC} .mcp.json may have hardcoded token (security risk)"
    fi
else
    echo -e "${RED}✗${NC} .mcp.json file not found"
    exit 1
fi
echo

# Summary
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo
echo -e "${GREEN}✓ All environment variables are properly configured and exported!${NC}"
echo
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. Restart Claude Code to ensure MCP servers load with correct env vars:"
echo -e "     ${BLUE}exit${NC} (if in Claude Code)"
echo -e "     ${BLUE}claude${NC} (start new session)"
echo -e "  2. Verify in Claude Code conversation:"
echo -e "     ${BLUE}/doctor${NC} (should show no environment variable warnings)"
echo -e "  3. Test MCP connectivity:"
echo -e "     ${BLUE}\"Use Context7 to get latest Astro.build best practices\"${NC}"
echo
