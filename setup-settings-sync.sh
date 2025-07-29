#!/bin/bash

# VS Code Settings Sync Configuration Script
# Ensures all settings sync to GitHub profile and apply to all profiles

echo "🔧 VS Code Settings Sync Configuration"
echo "======================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Function to check if VS Code is running
check_vscode_running() {
    if pgrep -f "code" > /dev/null; then
        echo -e "${YELLOW}⚠️${NC} VS Code is currently running"
        echo "For best results, close VS Code and run this script again"
        echo "Or continue anyway? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Please close VS Code and run this script again"
            exit 1
        fi
    fi
}

# Function to backup current settings
backup_settings() {
    echo -e "\n${BLUE}Creating Backup of Current Settings${NC}"
    echo "=================================="

    local backup_dir="$HOME/vscode-settings-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"

    if [[ -d "$VSCODE_USER_DIR" ]]; then
        cp -r "$VSCODE_USER_DIR" "$backup_dir/"
        echo -e "${GREEN}✓${NC} Backup created at: $backup_dir"
    else
        echo -e "${YELLOW}!${NC} No existing VS Code settings found"
    fi
}

# Function to configure optimal sync settings
configure_sync_settings() {
    echo -e "\n${BLUE}Configuring Optimal Sync Settings${NC}"
    echo "================================="

    local settings_file="$VSCODE_USER_DIR/settings.json"

    # Create user directory if it doesn't exist
    mkdir -p "$VSCODE_USER_DIR"

    # Create or update settings.json
    if [[ -f "$settings_file" ]]; then
        echo -e "${GREEN}✓${NC} Found existing settings.json"
        # Backup existing settings
        cp "$settings_file" "$settings_file.backup"
        echo -e "${GREEN}✓${NC} Created backup of existing settings"
    else
        echo -e "${YELLOW}!${NC} No existing settings.json, creating new one"
        echo "{}" > "$settings_file"
    fi

    # Use jq to update settings if available, otherwise manual approach
    if command -v jq &> /dev/null; then
        echo -e "${GREEN}✓${NC} Using jq for settings update"

        # Update settings with optimal sync configuration
        jq '. + {
            "settingsSync.keybindingsPerPlatform": false,
            "settingsSync.ignoredExtensions": [],
            "settingsSync.ignoredSettings": [],
            "extensions.autoCheckUpdates": true,
            "extensions.autoUpdate": true,
            "workbench.settings.enableNaturalLanguageSearch": false,
            "workbench.settings.useSplitJSON": true,
            "git.enableSmartCommit": true,
            "git.confirmSync": false,
            "git.autofetch": "all"
        }' "$settings_file" > "$settings_file.tmp" && mv "$settings_file.tmp" "$settings_file"

        echo -e "${GREEN}✓${NC} Updated settings.json with optimal sync configuration"
    else
        echo -e "${YELLOW}!${NC} jq not found, manual configuration required"
        echo "Please manually add these settings to your VS Code settings:"
        echo "  - settingsSync.keybindingsPerPlatform: false"
        echo "  - settingsSync.ignoredExtensions: []"
        echo "  - settingsSync.ignoredSettings: []"
        echo "  - extensions.autoUpdate: true"
    fi
}

# Function to show manual steps
show_manual_steps() {
    echo -e "\n${BLUE}Manual Steps to Complete Setup${NC}"
    echo "=============================="

    echo -e "${YELLOW}1. Open VS Code${NC}"
    echo -e "${YELLOW}2. Press Ctrl+Shift+P${NC}"
    echo -e "${YELLOW}3. Type 'Settings Sync: Turn Off' and confirm${NC}"
    echo -e "${YELLOW}4. Type 'Profiles: Show Profiles' and delete all except Default${NC}"
    echo -e "${YELLOW}5. Type 'Settings Sync: Turn On'${NC}"
    echo -e "${YELLOW}6. Sign in with your GitHub account${NC}"
    echo -e "${YELLOW}7. Choose 'Replace Local' or 'Merge' as needed${NC}"
    echo -e "${YELLOW}8. Type 'Settings Sync: Configure' and enable ALL options:${NC}"
    echo "   ✅ Settings"
    echo "   ✅ Keybindings"
    echo "   ✅ Extensions"
    echo "   ✅ User Snippets"
    echo "   ✅ UI State"
    echo -e "${YELLOW}9. Type 'Settings Sync: Sync Now' to test${NC}"
}

# Function to create VS Code commands file for easy access
create_commands_reference() {
    echo -e "\n${BLUE}Creating VS Code Commands Reference${NC}"
    echo "=================================="

    cat > "vscode-sync-commands.md" << 'EOF'
# VS Code Settings Sync Commands Reference

## Setup Commands (Run in Command Palette Ctrl+Shift+P):

### Initial Setup:
1. `Settings Sync: Turn Off` - Reset sync completely
2. `Profiles: Show Profiles` - Check/delete extra profiles
3. `Settings Sync: Turn On` - Enable sync with GitHub
4. `Settings Sync: Configure` - Choose what to sync

### Daily Use:
- `Settings Sync: Sync Now` - Force sync
- `Settings Sync: Show Settings` - Check sync status
- `Settings Sync: Show Log` - View sync activity

### Troubleshooting:
- `Settings Sync: Reset Local` - Clear local sync data
- `Settings Sync: Reset Remote` - Clear cloud sync data
- `Developer: Reload Window` - Restart VS Code

## Settings to Enable in Configure:
✅ Settings (user settings.json)
✅ Keybindings (custom shortcuts)
✅ Extensions (all installed extensions)
✅ User Snippets (code templates)
✅ UI State (workbench layout)

## Key Settings (add to settings.json):
```json
{
    "settingsSync.keybindingsPerPlatform": false,
    "settingsSync.ignoredExtensions": [],
    "settingsSync.ignoredSettings": [],
    "extensions.autoUpdate": true
}
```
EOF

    echo -e "${GREEN}✓${NC} Created vscode-sync-commands.md reference file"
}

# Function to test VS Code CLI
test_vscode_cli() {
    echo -e "\n${BLUE}Testing VS Code CLI Integration${NC}"
    echo "=============================="

    if command -v code &> /dev/null; then
        echo -e "${GREEN}✓${NC} VS Code CLI is available"

        # Test if we can list extensions
        local ext_count=$(code --list-extensions 2>/dev/null | wc -l)
        echo -e "${GREEN}✓${NC} Found $ext_count extensions via CLI"

        # Show some extensions
        echo -e "${YELLOW}Current extensions:${NC}"
        code --list-extensions 2>/dev/null | head -5 | while read -r ext; do
            echo "  - $ext"
        done

        if [[ $ext_count -gt 5 ]]; then
            echo "  ... and $((ext_count - 5)) more"
        fi

    else
        echo -e "${RED}✗${NC} VS Code CLI not available"
        echo "To enable VS Code CLI:"
        echo "1. Open VS Code"
        echo "2. Press Ctrl+Shift+P"
        echo "3. Type 'Shell Command: Install code command in PATH'"
        echo "4. Restart terminal"
    fi
}

# Main menu
case "$1" in
    "backup")
        backup_settings
        ;;
    "configure")
        check_vscode_running
        backup_settings
        configure_sync_settings
        create_commands_reference
        show_manual_steps
        ;;
    "test")
        test_vscode_cli
        ;;
    "commands")
        create_commands_reference
        echo -e "${GREEN}✓${NC} Created commands reference file"
        ;;
    "full")
        echo -e "${GREEN}Running complete Settings Sync setup...${NC}\n"
        check_vscode_running
        backup_settings
        configure_sync_settings
        test_vscode_cli
        create_commands_reference
        show_manual_steps
        echo -e "\n${GREEN}🎉 Setup complete!${NC}"
        echo "Next: Follow the manual steps to complete VS Code Settings Sync"
        ;;
    *)
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  backup      - Backup current VS Code settings"
        echo "  configure   - Configure optimal sync settings"
        echo "  test        - Test VS Code CLI integration"
        echo "  commands    - Create commands reference file"
        echo "  full        - Run complete setup process"
        echo ""
        echo "Examples:"
        echo "  $0 full       # Complete setup"
        echo "  $0 configure  # Just configure settings"
        echo "  $0 test       # Test current setup"
        ;;
esac

echo -e "\n${GREEN}Done!${NC} 🎉"
