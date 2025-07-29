#!/bin/bash

# VS Code Profile Manager Script
# Shows current profiles and helps manage them

echo "🔍 VS Code Profile Inspector"
echo "============================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# VS Code configuration paths
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    VSCODE_USER_DIR="$HOME/.config/Code/User"
    VSCODE_CONFIG_DIR="$HOME/.config/Code"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
    VSCODE_CONFIG_DIR="$HOME/Library/Application Support/Code"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    VSCODE_USER_DIR="$APPDATA/Code/User"
    VSCODE_CONFIG_DIR="$APPDATA/Code"
else
    echo -e "${RED}✗${NC} Unsupported operating system: $OSTYPE"
    exit 1
fi

# Function to check current profiles
check_profiles() {
    echo -e "\n${BLUE}Current VS Code Profile Status${NC}"
    echo "=============================="
    
    # Check for profile directories
    echo -e "${YELLOW}Profile directories:${NC}"
    find "$VSCODE_CONFIG_DIR" -name "*profile*" -type d 2>/dev/null | while read -r dir; do
        echo -e "  ${GREEN}✓${NC} $dir"
    done
    
    # Check sync profiles
    local sync_profiles_file="$VSCODE_USER_DIR/sync/profiles/lastSyncprofiles.json"
    if [[ -f "$sync_profiles_file" ]]; then
        echo -e "\n${YELLOW}Sync profiles status:${NC}"
        cat "$sync_profiles_file" 2>/dev/null | jq . 2>/dev/null || cat "$sync_profiles_file"
    else
        echo -e "\n${YELLOW}No sync profiles file found${NC}"
    fi
    
    # Check for actual profile configurations
    local profiles_dir="$VSCODE_USER_DIR/profiles"
    if [[ -d "$profiles_dir" ]]; then
        echo -e "\n${YELLOW}Available profiles:${NC}"
        ls -la "$profiles_dir"
    else
        echo -e "\n${GREEN}✓${NC} No custom profiles directory found (using default only)"
    fi
}

# Function to show settings sync status
check_settings_sync() {
    echo -e "\n${BLUE}Settings Sync Configuration${NC}"
    echo "=========================="
    
    local settings_file="$VSCODE_USER_DIR/settings.json"
    if [[ -f "$settings_file" ]]; then
        echo -e "${GREEN}✓${NC} Found settings.json"
        
        # Check sync-related settings
        echo -e "\n${YELLOW}Sync-related settings:${NC}"
        grep -E "(settingsSync|sync)" "$settings_file" 2>/dev/null || echo "  No sync settings found in settings.json"
    else
        echo -e "${RED}✗${NC} No settings.json found"
    fi
    
    # Check sync state files
    local sync_dir="$VSCODE_USER_DIR/sync"
    if [[ -d "$sync_dir" ]]; then
        echo -e "\n${YELLOW}Sync directory contents:${NC}"
        ls -la "$sync_dir"
        
        # Check for sync state
        local sync_state="$sync_dir/syncState.json"
        if [[ -f "$sync_state" ]]; then
            echo -e "\n${YELLOW}Sync state:${NC}"
            cat "$sync_state" 2>/dev/null | head -5
        fi
    else
        echo -e "\n${YELLOW}No sync directory found${NC}"
    fi
}

# Function to show VS Code commands to run
show_commands() {
    echo -e "\n${BLUE}Commands to Run in VS Code${NC}"
    echo "========================="
    
    echo -e "${YELLOW}To check your profiles in VS Code:${NC}"
    echo "1. Open VS Code"
    echo "2. Press Ctrl+Shift+P"
    echo "3. Type: Profiles: Show Profiles"
    echo ""
    
    echo -e "${YELLOW}To check settings sync:${NC}"
    echo "1. Press Ctrl+Shift+P"
    echo "2. Type: Settings Sync: Show Settings"
    echo ""
    
    echo -e "${YELLOW}If you have multiple profiles (BAD):${NC}"
    echo "1. Press Ctrl+Shift+P"
    echo "2. Type: Profiles: Show Profiles"
    echo "3. Delete all except 'Default'"
    echo "4. Make sure you're using 'Default'"
    echo ""
    
    echo -e "${YELLOW}To reset and fix sync:${NC}"
    echo "1. Press Ctrl+Shift+P"
    echo "2. Type: Settings Sync: Turn Off"
    echo "3. Type: Settings Sync: Turn On"
    echo "4. Sign in with GitHub"
    echo "5. Type: Settings Sync: Configure"
    echo "6. Enable ALL options (Settings, Keybindings, Extensions, Snippets, UI State)"
}

# Function to analyze current state
analyze_state() {
    echo -e "\n${BLUE}Analysis & Recommendations${NC}"
    echo "========================="
    
    # Check if using default profile only
    local profiles_dir="$VSCODE_USER_DIR/profiles"
    if [[ ! -d "$profiles_dir" ]]; then
        echo -e "${GREEN}✅ GOOD:${NC} Using default profile only (no custom profiles)"
    else
        echo -e "${RED}⚠️  WARNING:${NC} Custom profiles directory exists"
        echo "  You should delete custom profiles and use only Default"
    fi
    
    # Check sync configuration
    local settings_file="$VSCODE_USER_DIR/settings.json"
    if [[ -f "$settings_file" ]]; then
        if grep -q "settingsSync" "$settings_file"; then
            echo -e "${GREEN}✅ GOOD:${NC} Sync settings found in configuration"
        else
            echo -e "${YELLOW}⚠️  INFO:${NC} No sync settings in settings.json (may be default)"
        fi
    fi
    
    # Check sync directory
    local sync_dir="$VSCODE_USER_DIR/sync"
    if [[ -d "$sync_dir" ]]; then
        echo -e "${GREEN}✅ GOOD:${NC} Sync directory exists"
        
        # Count sync files
        local sync_files=$(find "$sync_dir" -type f | wc -l)
        echo -e "  ${YELLOW}→${NC} Contains $sync_files sync files"
    else
        echo -e "${RED}⚠️  WARNING:${NC} No sync directory found"
        echo "  Settings Sync may not be enabled"
    fi
}

# Function to create fix script
create_fix_script() {
    echo -e "\n${BLUE}Creating Profile Fix Script${NC}"
    echo "=========================="
    
    cat > "fix-vscode-profiles.sh" << 'EOF'
#!/bin/bash

# VS Code Profile Fix Script
echo "🔧 Fixing VS Code Profiles..."

# Backup current configuration
echo "Creating backup..."
cp -r ~/.config/Code/User ~/.config/Code/User.backup.$(date +%Y%m%d-%H%M%S) 2>/dev/null

# Remove custom profiles directory if it exists
if [[ -d ~/.config/Code/User/profiles ]]; then
    echo "Removing custom profiles directory..."
    rm -rf ~/.config/Code/User/profiles
    echo "✅ Custom profiles removed"
fi

# Clear profile sync state
if [[ -f ~/.config/Code/User/sync/profiles/lastSyncprofiles.json ]]; then
    echo '{"ref":"0","syncData":null}' > ~/.config/Code/User/sync/profiles/lastSyncprofiles.json
    echo "✅ Reset sync profiles state"
fi

echo "✅ Profile cleanup complete!"
echo "Now run these commands in VS Code:"
echo "1. Ctrl+Shift+P → Settings Sync: Turn Off"
echo "2. Ctrl+Shift+P → Settings Sync: Turn On"
echo "3. Sign in with GitHub"
echo "4. Ctrl+Shift+P → Settings Sync: Configure"
echo "5. Enable ALL sync options"
EOF

    chmod +x "fix-vscode-profiles.sh"
    echo -e "${GREEN}✅${NC} Created fix-vscode-profiles.sh"
}

# Main menu
case "$1" in
    "profiles")
        check_profiles
        ;;
    "sync")
        check_settings_sync
        ;;
    "analyze")
        check_profiles
        check_settings_sync
        analyze_state
        ;;
    "commands")
        show_commands
        ;;
    "fix")
        create_fix_script
        echo -e "${GREEN}✅${NC} Run ./fix-vscode-profiles.sh to clean up profiles"
        ;;
    "all"|*)
        echo -e "${GREEN}Running complete profile inspection...${NC}\n"
        check_profiles
        check_settings_sync
        analyze_state
        show_commands
        create_fix_script
        echo -e "\n${GREEN}🎉 Inspection complete!${NC}"
        ;;
esac

echo -e "\n${GREEN}Done!${NC} 🎉"
