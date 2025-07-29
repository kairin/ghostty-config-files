#!/bin/bash

# VS Code Workspace Sync Script
# This script helps synchronize VS Code settings and extensions across multiple workspaces

echo "🚀 VS Code Workspace Sync Tool"
echo "================================"

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to create .vscode directory if it doesn't exist
create_vscode_dir() {
    local workspace_path="$1"
    if [ ! -d "$workspace_path/.vscode" ]; then
        mkdir -p "$workspace_path/.vscode"
        echo -e "${GREEN}✓${NC} Created .vscode directory in $workspace_path"
    fi
}

# Function to copy settings
copy_settings() {
    local source_dir="$1"
    local target_dir="$2"

    if [ -f "$source_dir/template-settings.json" ]; then
        cp "$source_dir/template-settings.json" "$target_dir/.vscode/settings.json"
        echo -e "${GREEN}✓${NC} Copied settings to $target_dir"
    else
        echo -e "${RED}✗${NC} Template settings file not found in $source_dir"
    fi
}

# Function to copy extensions recommendations
copy_extensions() {
    local source_dir="$1"
    local target_dir="$2"

    if [ -f "$source_dir/.vscode/extensions.json" ]; then
        cp "$source_dir/.vscode/extensions.json" "$target_dir/.vscode/extensions.json"
        echo -e "${GREEN}✓${NC} Copied extensions recommendations to $target_dir"
    else
        echo -e "${YELLOW}!${NC} Extensions file not found in $source_dir"
    fi
}

# Main function
sync_workspace() {
    local source_path="$1"
    local target_path="$2"

    echo -e "\n${BLUE}Syncing:${NC} $source_path → $target_path"

    if [ ! -d "$target_path" ]; then
        echo -e "${RED}✗${NC} Target directory does not exist: $target_path"
        return 1
    fi

    create_vscode_dir "$target_path"
    copy_settings "$source_path" "$target_path"
    copy_extensions "$source_path" "$target_path"
}

# Usage instructions
show_usage() {
    echo "Usage:"
    echo "  $0 sync <source_workspace> <target_workspace>    # Sync specific workspaces"
    echo "  $0 sync-all <source_workspace> <base_directory>  # Sync to all subdirectories"
    echo "  $0 install-extensions                             # Install recommended extensions"
    echo ""
    echo "Examples:"
    echo "  $0 sync /path/to/template /path/to/target"
    echo "  $0 sync-all /path/to/template ~/Projects"
    echo "  $0 install-extensions"
}

# Install recommended extensions
install_extensions() {
    echo -e "\n${BLUE}Installing recommended extensions...${NC}"

    # List of essential extensions
    extensions=(
        "ms-vscode.vscode-json"
        "redhat.vscode-yaml"
        "ms-python.python"
        "esbenp.prettier-vscode"
        "ms-vscode.live-server"
        "github.copilot"
        "github.copilot-chat"
    )

    for ext in "${extensions[@]}"; do
        echo -e "Installing ${YELLOW}$ext${NC}..."
        code --install-extension "$ext" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓${NC} Installed $ext"
        else
            echo -e "${RED}✗${NC} Failed to install $ext"
        fi
    done
}

# Sync to all subdirectories
sync_all() {
    local source_path="$1"
    local base_directory="$2"

    echo -e "\n${BLUE}Syncing to all workspaces in:${NC} $base_directory"

    for dir in "$base_directory"/*; do
        if [ -d "$dir" ] && [ "$dir" != "$source_path" ]; then
            sync_workspace "$source_path" "$dir"
        fi
    done
}

# Main script logic
case "$1" in
    "sync")
        if [ $# -ne 3 ]; then
            echo -e "${RED}Error:${NC} Please provide source and target paths"
            show_usage
            exit 1
        fi
        sync_workspace "$2" "$3"
        ;;
    "sync-all")
        if [ $# -ne 3 ]; then
            echo -e "${RED}Error:${NC} Please provide source path and base directory"
            show_usage
            exit 1
        fi
        sync_all "$2" "$3"
        ;;
    "install-extensions")
        install_extensions
        ;;
    *)
        show_usage
        ;;
esac

echo -e "\n${GREEN}Done!${NC} 🎉"
