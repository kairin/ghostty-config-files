#!/bin/bash

# VS Code Dual Setup: Settings Sync + Template Repository
# This script sets up both VS Code Settings Sync and repository-based templates

echo "🚀 VS Code Dual Setup Tool"
echo "=================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo -e "\n${BLUE}Step 1: Setting up VS Code Settings Sync${NC}"
echo "=========================================="

setup_settings_sync() {
    echo "To enable VS Code Settings Sync:"
    echo "1. Press Ctrl+Shift+P in VS Code"
    echo "2. Type 'Settings Sync: Turn On'"
    echo "3. Sign in with your Microsoft/GitHub account"
    echo "4. Choose what to sync (Settings, Extensions, Keybindings, etc.)"
    echo ""
    echo -e "${GREEN}✓${NC} This will sync your personal preferences across ALL devices"
    echo -e "${YELLOW}!${NC} This includes themes, personal settings, and user preferences"
}

echo -e "\n${BLUE}Step 2: Repository-based Templates${NC}"
echo "=================================="

setup_repo_templates() {
    echo "Your template repository contains:"
    echo "- Extension recommendations"
    echo "- Project-specific settings"
    echo "- Team-shareable configurations"
    echo ""
    echo -e "${GREEN}✓${NC} Safe to make public (no personal data)"
    echo -e "${GREEN}✓${NC} Version controlled and team-shareable"
}

echo -e "\n${BLUE}Step 3: Clone to Other Devices${NC}"
echo "================================"

show_clone_instructions() {
    local repo_url="https://github.com/kairin/ghostty-config-files.git"

    echo "To use on other devices:"
    echo ""
    echo -e "${YELLOW}Option A: Clone as a standalone template repo${NC}"
    echo "git clone $repo_url ~/vscode-templates"
    echo "cd ~/vscode-templates"
    echo "./sync-workspaces.sh sync-all . ~/Projects"
    echo ""
    echo -e "${YELLOW}Option B: Download directly into project${NC}"
    echo "cd ~/Projects/my-project"
    echo "mkdir -p .vscode"
    echo "wget -c https://raw.githubusercontent.com/kairin/ghostty-config-files/main/template-settings.json -O .vscode/settings.json"
    echo "wget -c https://raw.githubusercontent.com/kairin/ghostty-config-files/main/.vscode/extensions.json -O .vscode/extensions.json"
    echo ""
    echo -e "${YELLOW}Option C: Use as git submodule${NC}"
    echo "cd ~/Projects/my-project"
    echo "git submodule add $repo_url .vscode-templates"
    echo "cp .vscode-templates/template-settings.json .vscode/settings.json"
    echo "cp .vscode-templates/.vscode/extensions.json .vscode/extensions.json"
}

echo -e "\n${BLUE}Step 4: Privacy Check${NC}"
echo "====================="

privacy_check() {
    echo "Files safe for public repository:"
    echo -e "${GREEN}✓${NC} .vscode/extensions.json"
    echo -e "${GREEN}✓${NC} template-settings.json"
    echo -e "${GREEN}✓${NC} sync-workspaces.sh"
    echo -e "${GREEN}✓${NC} Documentation files"
    echo ""
    echo "Never commit:"
    echo -e "${RED}✗${NC} Personal authentication tokens"
    echo -e "${RED}✗${NC} User-specific file paths"
    echo -e "${RED}✗${NC} Private API keys"
    echo -e "${RED}✗${NC} Machine-specific configurations"
}

echo -e "\n${BLUE}Step 5: Install Extensions${NC}"
echo "=========================="

install_extensions() {
    echo "Installing recommended extensions..."

    if ! command -v code &> /dev/null; then
        echo -e "${RED}✗${NC} VS Code command 'code' not found in PATH"
        echo "Please install VS Code or add it to your PATH"
        return 1
    fi

    if [ -f "$SCRIPT_DIR/.vscode/extensions.json" ]; then
        # Extract extension IDs from JSON
        extensions=$(grep -o '"[^"]*\.[^"]*"' "$SCRIPT_DIR/.vscode/extensions.json" | tr -d '"')

        for ext in $extensions; do
            echo -e "Installing ${YELLOW}$ext${NC}..."
            if code --install-extension "$ext" &>/dev/null; then
                echo -e "${GREEN}✓${NC} Installed $ext"
            else
                echo -e "${RED}✗${NC} Failed to install $ext"
            fi
        done
    else
        echo -e "${RED}✗${NC} Extensions file not found"
    fi
}

# Main menu
case "$1" in
    "settings-sync")
        setup_settings_sync
        ;;
    "templates")
        setup_repo_templates
        ;;
    "clone-help")
        show_clone_instructions
        ;;
    "privacy")
        privacy_check
        ;;
    "install")
        install_extensions
        ;;
    "full-setup")
        echo -e "${GREEN}Running full setup...${NC}\n"
        setup_settings_sync
        echo ""
        setup_repo_templates
        echo ""
        show_clone_instructions
        echo ""
        privacy_check
        echo ""
        install_extensions
        ;;
    *)
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  settings-sync    - Show Settings Sync setup instructions"
        echo "  templates        - Show template repository info"
        echo "  clone-help       - Show how to clone on other devices"
        echo "  privacy          - Show privacy and security info"
        echo "  install          - Install recommended extensions"
        echo "  full-setup       - Run complete setup process"
        echo ""
        echo "Examples:"
        echo "  $0 full-setup    # Complete setup process"
        echo "  $0 install       # Just install extensions"
        ;;
esac

echo -e "\n${GREEN}Done!${NC} 🎉"
