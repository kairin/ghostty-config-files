#!/bin/bash
# sync-mcp-secrets.sh - Helper for MCP secrets management
# Provides commands for managing and syncing MCP secrets between machines

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMPLATE_FILE="$REPO_DIR/configs/mcp/.mcp-secrets.template"
SECRETS_FILE="$HOME/.mcp-secrets"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  MCP Secrets Manager${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
}

print_usage() {
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  init      Create ~/.mcp-secrets from template"
    echo "  status    Check if secrets are configured"
    echo "  verify    Verify secrets are loaded in environment"
    echo "  export    Export secrets to private gist (requires gh CLI)"
    echo "  import    Import secrets from private gist"
    echo "  shell     Add source line to shell config"
    echo ""
    echo "Examples:"
    echo "  $0 init                  # Create secrets file from template"
    echo "  $0 export                # Backup to private gist"
    echo "  $0 import abc123def      # Restore from gist ID"
}

cmd_init() {
    echo -e "${BLUE}Initializing MCP secrets...${NC}"

    if [ -f "$SECRETS_FILE" ]; then
        echo -e "${YELLOW}Warning: $SECRETS_FILE already exists${NC}"
        read -p "Overwrite? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 1
        fi
    fi

    if [ -f "$TEMPLATE_FILE" ]; then
        cp "$TEMPLATE_FILE" "$SECRETS_FILE"
        chmod 600 "$SECRETS_FILE"
        echo -e "${GREEN}Created $SECRETS_FILE from template${NC}"
        echo ""
        echo -e "${YELLOW}Next steps:${NC}"
        echo "1. Edit $SECRETS_FILE with your API keys"
        echo "2. Run: $0 shell"
        echo "3. Run: source ~/.zshrc"
    else
        echo -e "${RED}Template not found: $TEMPLATE_FILE${NC}"
        exit 1
    fi
}

cmd_status() {
    echo -e "${BLUE}Checking MCP secrets status...${NC}"
    echo ""

    if [ -f "$SECRETS_FILE" ]; then
        echo -e "${GREEN}✓ Secrets file exists:${NC} $SECRETS_FILE"

        # Check permissions
        PERMS=$(stat -c "%a" "$SECRETS_FILE" 2>/dev/null || stat -f "%Lp" "$SECRETS_FILE")
        if [ "$PERMS" = "600" ]; then
            echo -e "${GREEN}✓ Permissions are secure (600)${NC}"
        else
            echo -e "${YELLOW}⚠ Permissions are $PERMS (should be 600)${NC}"
            echo "  Fix with: chmod 600 $SECRETS_FILE"
        fi

        # Check if sourced in shell config
        if grep -q "mcp-secrets" ~/.zshrc 2>/dev/null; then
            echo -e "${GREEN}✓ Sourced in ~/.zshrc${NC}"
        else
            echo -e "${YELLOW}⚠ Not sourced in ~/.zshrc${NC}"
            echo "  Fix with: $0 shell"
        fi
    else
        echo -e "${RED}✗ Secrets file not found${NC}"
        echo "  Create with: $0 init"
    fi
}

cmd_verify() {
    echo -e "${BLUE}Verifying MCP secrets in environment...${NC}"
    echo ""

    local all_ok=true

    if [ -n "${CONTEXT7_API_KEY:-}" ]; then
        echo -e "${GREEN}✓ CONTEXT7_API_KEY:${NC} $(echo "$CONTEXT7_API_KEY" | head -c 10)..."
    else
        echo -e "${RED}✗ CONTEXT7_API_KEY: not set${NC}"
        all_ok=false
    fi

    if [ -n "${HUGGINGFACE_TOKEN:-}" ]; then
        echo -e "${GREEN}✓ HUGGINGFACE_TOKEN:${NC} $(echo "$HUGGINGFACE_TOKEN" | head -c 10)..."
    else
        echo -e "${YELLOW}⚠ HUGGINGFACE_TOKEN: not set (optional)${NC}"
    fi

    if [ -n "${HF_TOKEN:-}" ]; then
        echo -e "${GREEN}✓ HF_TOKEN:${NC} $(echo "$HF_TOKEN" | head -c 10)..."
    else
        echo -e "${YELLOW}⚠ HF_TOKEN: not set (optional)${NC}"
    fi

    # Check GitHub token
    if command -v gh &> /dev/null; then
        if gh auth status &> /dev/null; then
            echo -e "${GREEN}✓ GitHub:${NC} authenticated via gh CLI"
        else
            echo -e "${YELLOW}⚠ GitHub: gh CLI not authenticated${NC}"
            echo "  Fix with: gh auth login"
        fi
    else
        echo -e "${YELLOW}⚠ GitHub: gh CLI not installed${NC}"
    fi

    echo ""
    if [ "$all_ok" = true ]; then
        echo -e "${GREEN}All required secrets are configured!${NC}"
    else
        echo -e "${YELLOW}Some secrets need to be configured.${NC}"
        echo "Edit $SECRETS_FILE and source it."
    fi
}

cmd_export() {
    echo -e "${BLUE}Exporting secrets to private gist...${NC}"

    if ! command -v gh &> /dev/null; then
        echo -e "${RED}Error: gh CLI is required${NC}"
        echo "Install from: https://cli.github.com/"
        exit 1
    fi

    if [ ! -f "$SECRETS_FILE" ]; then
        echo -e "${RED}Error: $SECRETS_FILE not found${NC}"
        exit 1
    fi

    echo "Creating private gist..."
    GIST_URL=$(gh gist create "$SECRETS_FILE" --private --desc "MCP Secrets Backup $(date +%Y-%m-%d)")

    echo -e "${GREEN}Success! Gist created:${NC}"
    echo "$GIST_URL"
    echo ""
    echo "To import on another machine:"
    GIST_ID=$(echo "$GIST_URL" | grep -oE '[a-f0-9]{32}')
    echo "  $0 import $GIST_ID"
}

cmd_import() {
    local gist_id="${1:-}"

    if [ -z "$gist_id" ]; then
        echo -e "${RED}Error: Gist ID required${NC}"
        echo "Usage: $0 import <gist-id>"
        exit 1
    fi

    echo -e "${BLUE}Importing secrets from gist...${NC}"

    if ! command -v gh &> /dev/null; then
        echo -e "${RED}Error: gh CLI is required${NC}"
        exit 1
    fi

    if [ -f "$SECRETS_FILE" ]; then
        echo -e "${YELLOW}Warning: $SECRETS_FILE already exists${NC}"
        read -p "Overwrite? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 1
        fi
    fi

    gh gist view "$gist_id" --raw > "$SECRETS_FILE"
    chmod 600 "$SECRETS_FILE"

    echo -e "${GREEN}Success! Secrets imported to $SECRETS_FILE${NC}"
    echo "Run: source ~/.zshrc"
}

cmd_shell() {
    echo -e "${BLUE}Adding secrets source to shell config...${NC}"

    local SHELL_RC="$HOME/.zshrc"
    local SOURCE_LINE='[ -f ~/.mcp-secrets ] && source ~/.mcp-secrets'

    if grep -q "mcp-secrets" "$SHELL_RC" 2>/dev/null; then
        echo -e "${YELLOW}Already configured in $SHELL_RC${NC}"
    else
        echo "" >> "$SHELL_RC"
        echo "# MCP Secrets (synced between machines)" >> "$SHELL_RC"
        echo "$SOURCE_LINE" >> "$SHELL_RC"
        echo -e "${GREEN}Added to $SHELL_RC${NC}"
    fi

    echo ""
    echo "Run: source $SHELL_RC"
}

# Main
print_header
echo ""

case "${1:-}" in
    init)
        cmd_init
        ;;
    status)
        cmd_status
        ;;
    verify)
        cmd_verify
        ;;
    export)
        cmd_export
        ;;
    import)
        cmd_import "${2:-}"
        ;;
    shell)
        cmd_shell
        ;;
    *)
        print_usage
        ;;
esac
