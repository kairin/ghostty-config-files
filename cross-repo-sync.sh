#!/bin/bash

# Cross-Repository VS Code Settings Sync
# Run this script to capture settings from ANY VS Code workspace and sync them back to your template repo

echo "🔄 Cross-Repository VS Code Settings Sync"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get the template repository path (where this script is located)
TEMPLATE_REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# VS Code configuration paths
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    VSCODE_USER_DIR="$HOME/.config/Code/User"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    VSCODE_USER_DIR="$APPDATA/Code/User"
else
    echo -e "${RED}✗${NC} Unsupported operating system: $OSTYPE"
    exit 1
fi

# Function to capture current global VS Code settings
capture_global_settings() {
    echo -e "\n${BLUE}Capturing Global VS Code Settings${NC}"
    echo "=================================="

    local settings_file="$VSCODE_USER_DIR/settings.json"

    if [[ -f "$settings_file" ]]; then
        echo -e "${GREEN}✓${NC} Found global settings.json"

        # Count current settings
        local current_count=$(grep -c '".*":' "$settings_file" 2>/dev/null || echo "0")
        local template_count=$(grep -c '".*":' "$TEMPLATE_REPO_DIR/template-settings.json" 2>/dev/null || echo "0")

        echo -e "  ${YELLOW}→${NC} Global settings: $current_count"
        echo -e "  ${YELLOW}→${NC} Template settings: $template_count"

        # Copy current settings
        cp "$settings_file" "$TEMPLATE_REPO_DIR/current-global-settings.json"
        echo -e "${GREEN}✓${NC} Saved current global settings"

        # Update template if current has more settings
        if [[ $current_count -gt $template_count ]]; then
            echo -e "${BLUE}📈${NC} Global settings are more comprehensive, updating template..."
            cp "$settings_file" "$TEMPLATE_REPO_DIR/template-settings.json"
            echo -e "${GREEN}✓${NC} Updated template-settings.json"
        fi
    else
        echo -e "${RED}✗${NC} Global settings.json not found"
    fi
}

# Function to capture currently installed extensions
capture_extensions() {
    echo -e "\n${BLUE}Capturing Currently Installed Extensions${NC}"
    echo "========================================"

    if command -v code &> /dev/null; then
        echo -e "${GREEN}✓${NC} VS Code CLI found"

        # Get current extensions
        local extensions_list=$(code --list-extensions 2>/dev/null)
        local extension_count=$(echo "$extensions_list" | wc -l)

        if [[ -n "$extensions_list" ]]; then
            echo -e "${GREEN}✓${NC} Found $extension_count installed extensions"

            # Create updated extensions.json
            echo '{' > "$TEMPLATE_REPO_DIR/current-extensions.json"
            echo '  "recommendations": [' >> "$TEMPLATE_REPO_DIR/current-extensions.json"

            local first=true
            while IFS= read -r ext; do
                if [[ -n "$ext" ]]; then
                    if [[ "$first" == true ]]; then
                        echo "    \"$ext\"" >> "$TEMPLATE_REPO_DIR/current-extensions.json"
                        first=false
                    else
                        echo "    ,\"$ext\"" >> "$TEMPLATE_REPO_DIR/current-extensions.json"
                    fi
                fi
            done <<< "$extensions_list"

            echo '  ]' >> "$TEMPLATE_REPO_DIR/current-extensions.json"
            echo '}' >> "$TEMPLATE_REPO_DIR/current-extensions.json"

            # Check if we should update the template
            local template_ext_count=$(grep -c '".*\.[^"]*"' "$TEMPLATE_REPO_DIR/.vscode/extensions.json" 2>/dev/null || echo "0")

            echo -e "  ${YELLOW}→${NC} Current extensions: $extension_count"
            echo -e "  ${YELLOW}→${NC} Template extensions: $template_ext_count"

            if [[ $extension_count -gt $template_ext_count ]]; then
                echo -e "${BLUE}📦${NC} More extensions found, updating template..."
                cp "$TEMPLATE_REPO_DIR/current-extensions.json" "$TEMPLATE_REPO_DIR/.vscode/extensions.json"
                echo -e "${GREEN}✓${NC} Updated .vscode/extensions.json"
            fi
        else
            echo -e "${YELLOW}!${NC} No extensions found"
        fi
    else
        echo -e "${RED}✗${NC} VS Code CLI not found"
    fi
}

# Function to identify new MCP-related extensions
identify_mcp_extensions() {
    echo -e "\n${BLUE}Identifying MCP and AI-Related Extensions${NC}"
    echo "========================================"

    if [[ -f "$TEMPLATE_REPO_DIR/current-extensions.json" ]]; then
        # Look for MCP, AI, and Claude-related extensions
        local mcp_patterns=("mcp" "claude" "anthropic" "ai" "copilot" "gpt" "openai" "model" "context" "protocol")

        echo -e "${YELLOW}Scanning for MCP/AI extensions:${NC}"

        for pattern in "${mcp_patterns[@]}"; do
            local matches=$(grep -i "$pattern" "$TEMPLATE_REPO_DIR/current-extensions.json" || true)
            if [[ -n "$matches" ]]; then
                echo -e "${GREEN}✓${NC} Found $pattern-related: $(echo "$matches" | tr -d '", ' | xargs)"
            fi
        done
    fi
}

# Function to apply settings to current workspace
apply_to_current_workspace() {
    local current_dir="$1"

    echo -e "\n${BLUE}Applying Template to Current Workspace${NC}"
    echo "====================================="

    if [[ -z "$current_dir" ]]; then
        current_dir="$(pwd)"
    fi

    echo -e "Target directory: ${YELLOW}$current_dir${NC}"

    # Create .vscode directory if it doesn't exist
    mkdir -p "$current_dir/.vscode"

    # Copy template files
    if [[ -f "$TEMPLATE_REPO_DIR/template-settings.json" ]]; then
        cp "$TEMPLATE_REPO_DIR/template-settings.json" "$current_dir/.vscode/settings.json"
        echo -e "${GREEN}✓${NC} Applied template settings to workspace"
    fi

    if [[ -f "$TEMPLATE_REPO_DIR/.vscode/extensions.json" ]]; then
        cp "$TEMPLATE_REPO_DIR/.vscode/extensions.json" "$current_dir/.vscode/extensions.json"
        echo -e "${GREEN}✓${NC} Applied extension recommendations to workspace"
    fi
}

# Function to commit and push changes
commit_changes() {
    echo -e "\n${BLUE}Committing Changes to Template Repository${NC}"
    echo "========================================"

    cd "$TEMPLATE_REPO_DIR"

    if git diff --quiet && git diff --staged --quiet; then
        echo -e "${YELLOW}!${NC} No changes to commit"
    else
        echo -e "${GREEN}✓${NC} Changes detected, committing..."
        git add .
        git commit -m "Auto-sync: Captured settings from workspace $(date '+%Y-%m-%d %H:%M')

- Updated from global VS Code settings
- Captured currently installed extensions
- Includes any new MCP apps and AI tools"

        echo -e "${BLUE}🚀${NC} Pushing to remote repository..."
        if git push origin main; then
            echo -e "${GREEN}✓${NC} Successfully pushed changes"
        else
            echo -e "${RED}✗${NC} Push failed - you may need to pull first"
        fi
    fi
}

# Main menu
show_usage() {
    echo "Usage: $0 [command] [workspace_path]"
    echo ""
    echo "Commands:"
    echo "  capture              - Capture current VS Code settings and extensions"
    echo "  apply [path]         - Apply template to specified workspace (default: current dir)"
    echo "  sync                 - Capture settings AND apply to current workspace"
    echo "  commit               - Commit captured changes to repository"
    echo "  full [path]          - Complete workflow: capture → apply → commit"
    echo ""
    echo "Examples:"
    echo "  $0 capture           # Capture current VS Code state"
    echo "  $0 apply .           # Apply template to current directory"
    echo "  $0 sync              # Capture and apply to current directory"
    echo "  $0 full ~/my-project # Capture, apply to project, and commit"
    echo ""
    echo "Use this when:"
    echo "- You've installed new MCP apps in VS Code"
    echo "- You've added extensions in another workspace"
    echo "- You want to sync settings across repositories"
}

# Main script logic
case "$1" in
    "capture")
        capture_global_settings
        capture_extensions
        identify_mcp_extensions
        ;;
    "apply")
        apply_to_current_workspace "$2"
        ;;
    "sync")
        capture_global_settings
        capture_extensions
        identify_mcp_extensions
        apply_to_current_workspace "$2"
        ;;
    "commit")
        commit_changes
        ;;
    "full")
        echo -e "${GREEN}Running complete cross-repository sync...${NC}\n"
        capture_global_settings
        capture_extensions
        identify_mcp_extensions
        apply_to_current_workspace "$2"
        commit_changes
        echo -e "\n${GREEN}🎉 Complete sync finished!${NC}"
        ;;
    *)
        show_usage
        ;;
esac

echo -e "\n${GREEN}Done!${NC} 🎉"
