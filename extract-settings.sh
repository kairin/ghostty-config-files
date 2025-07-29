#!/bin/bash

# VS Code Settings Extractor and Sync Tool
# This script extracts ALL current VS Code settings and keeps them synced

echo "🔧 VS Code Settings Extractor & Sync Tool"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# VS Code configuration paths
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    VSCODE_USER_DIR="$HOME/.config/Code/User"
    VSCODE_EXTENSIONS_DIR="$HOME/.vscode/extensions"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
    VSCODE_EXTENSIONS_DIR="$HOME/.vscode/extensions"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    VSCODE_USER_DIR="$APPDATA/Code/User"
    VSCODE_EXTENSIONS_DIR="$HOME/.vscode/extensions"
else
    echo -e "${RED}✗${NC} Unsupported operating system: $OSTYPE"
    exit 1
fi

# Function to check VS Code Settings Sync status
check_settings_sync() {
    echo -e "\n${BLUE}Checking VS Code Settings Sync Status${NC}"
    echo "====================================="

    local sync_state_file="$VSCODE_USER_DIR/globalState.json"
    if [[ -f "$sync_state_file" ]]; then
        if grep -q "userDataSyncStore.resource" "$sync_state_file" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} Settings Sync appears to be enabled"
        else
            echo -e "${YELLOW}!${NC} Settings Sync may not be properly configured"
        fi
    else
        echo -e "${RED}✗${NC} VS Code user data not found"
    fi

    echo ""
    echo "To ensure Settings Sync is working properly:"
    echo "1. Open VS Code"
    echo "2. Press Ctrl+Shift+P"
    echo "3. Type 'Settings Sync: Show Settings'"
    echo "4. Ensure all categories are enabled"
    echo "5. Check that you're signed in to the correct account"
}

# Function to extract current VS Code settings
extract_current_settings() {
    echo -e "\n${BLUE}Extracting Current VS Code Settings${NC}"
    echo "=================================="

    local settings_file="$VSCODE_USER_DIR/settings.json"
    local keybindings_file="$VSCODE_USER_DIR/keybindings.json"
    local snippets_dir="$VSCODE_USER_DIR/snippets"

    # Extract user settings
    if [[ -f "$settings_file" ]]; then
        echo -e "${GREEN}✓${NC} Found user settings.json"
        cp "$settings_file" "$SCRIPT_DIR/extracted-user-settings.json"
        echo -e "${GREEN}✓${NC} Copied to extracted-user-settings.json"

        # Count settings
        local setting_count=$(grep -c '".*":' "$settings_file" 2>/dev/null || echo "0")
        echo -e "  ${YELLOW}→${NC} Contains $setting_count settings"
    else
        echo -e "${RED}✗${NC} User settings.json not found"
        echo "{}" > "$SCRIPT_DIR/extracted-user-settings.json"
    fi

    # Extract keybindings
    if [[ -f "$keybindings_file" ]]; then
        echo -e "${GREEN}✓${NC} Found keybindings.json"
        cp "$keybindings_file" "$SCRIPT_DIR/extracted-keybindings.json"
        echo -e "${GREEN}✓${NC} Copied to extracted-keybindings.json"
    else
        echo -e "${YELLOW}!${NC} No custom keybindings found"
        echo "[]" > "$SCRIPT_DIR/extracted-keybindings.json"
    fi

    # Extract snippets
    if [[ -d "$snippets_dir" ]]; then
        echo -e "${GREEN}✓${NC} Found snippets directory"
        mkdir -p "$SCRIPT_DIR/extracted-snippets"
        cp -r "$snippets_dir"/* "$SCRIPT_DIR/extracted-snippets/" 2>/dev/null
        local snippet_count=$(find "$snippets_dir" -name "*.json" | wc -l)
        echo -e "  ${YELLOW}→${NC} Contains $snippet_count snippet files"
    else
        echo -e "${YELLOW}!${NC} No custom snippets found"
        mkdir -p "$SCRIPT_DIR/extracted-snippets"
    fi
}

# Function to extract installed extensions
extract_extensions() {
    echo -e "\n${BLUE}Extracting Installed Extensions${NC}"
    echo "=============================="

    if command -v code &> /dev/null; then
        echo -e "${GREEN}✓${NC} VS Code CLI found"

        # Get list of installed extensions
        local extensions_list=$(code --list-extensions 2>/dev/null)
        local extension_count=$(echo "$extensions_list" | wc -l)

        if [[ -n "$extensions_list" ]]; then
            echo -e "${GREEN}✓${NC} Found $extension_count installed extensions"

            # Create comprehensive extensions.json
            echo '{' > "$SCRIPT_DIR/complete-extensions.json"
            echo '  "recommendations": [' >> "$SCRIPT_DIR/complete-extensions.json"

            local first=true
            while IFS= read -r ext; do
                if [[ -n "$ext" ]]; then
                    if [[ "$first" == true ]]; then
                        echo "    \"$ext\"" >> "$SCRIPT_DIR/complete-extensions.json"
                        first=false
                    else
                        echo "    ,\"$ext\"" >> "$SCRIPT_DIR/complete-extensions.json"
                    fi
                fi
            done <<< "$extensions_list"

            echo '  ]' >> "$SCRIPT_DIR/complete-extensions.json"
            echo '}' >> "$SCRIPT_DIR/complete-extensions.json"

            echo -e "${GREEN}✓${NC} Created complete-extensions.json with all $extension_count extensions"
        else
            echo -e "${YELLOW}!${NC} No extensions found or VS Code CLI not working"
        fi
    else
        echo -e "${RED}✗${NC} VS Code CLI not found in PATH"
        echo "Install VS Code or add 'code' command to PATH"
    fi
}

# Function to merge settings with template
merge_settings() {
    echo -e "\n${BLUE}Merging Settings with Template${NC}"
    echo "============================"

    local extracted_file="$SCRIPT_DIR/extracted-user-settings.json"
    local template_file="$SCRIPT_DIR/template-settings.json"
    local merged_file="$SCRIPT_DIR/merged-complete-settings.json"

    if [[ -f "$extracted_file" ]] && [[ -f "$template_file" ]]; then
        # Use jq if available, otherwise manual merge
        if command -v jq &> /dev/null; then
            echo -e "${GREEN}✓${NC} Using jq for smart merge"
            jq -s '.[0] * .[1]' "$template_file" "$extracted_file" > "$merged_file"
        else
            echo -e "${YELLOW}!${NC} jq not found, using manual merge"
            # Simple manual merge - just copy extracted for now
            cp "$extracted_file" "$merged_file"
        fi

        echo -e "${GREEN}✓${NC} Created merged-complete-settings.json"

        # Count final settings
        local final_count=$(grep -c '".*":' "$merged_file" 2>/dev/null || echo "0")
        echo -e "  ${YELLOW}→${NC} Final merged file contains $final_count settings"
    else
        echo -e "${RED}✗${NC} Cannot merge - missing source files"
    fi
}

# Function to create VS Code profiles fix
fix_profiles() {
    echo -e "\n${BLUE}Creating Single Profile Setup${NC}"
    echo "============================"

    cat > "$SCRIPT_DIR/profile-fix-instructions.md" << 'EOF'
# VS Code Profile Fix Instructions

## Problem
You mentioned that sync settings restored an old version and functions are gone. This usually happens when:
- Multiple profiles exist and sync is confused
- Wrong account is being used for sync
- Sync data got corrupted

## Solution: Reset to Single Default Profile

### Step 1: Check Current Profiles
1. Open VS Code
2. Press `Ctrl+Shift+P`
3. Type "Profiles: Show Profiles"
4. Note how many profiles you have

### Step 2: Reset to Default Profile
1. Press `Ctrl+Shift+P`
2. Type "Profiles: Switch Profile"
3. Select "Default"
4. Delete any other profiles you don't need

### Step 3: Reset Settings Sync
1. Press `Ctrl+Shift+P`
2. Type "Settings Sync: Turn Off"
3. Confirm to turn off
4. Type "Settings Sync: Turn On"
5. Sign in with your preferred account
6. Choose "Replace Local" to get cloud settings OR "Merge" to combine

### Step 4: Verify Sync Settings
1. Press `Ctrl+Shift+P`
2. Type "Settings Sync: Show Settings"
3. Ensure ALL items are checked:
   - ✅ Settings
   - ✅ Keybindings
   - ✅ Extensions
   - ✅ User Snippets
   - ✅ UI State

### Step 5: Force Sync
1. Make a small change (like change theme)
2. Press `Ctrl+Shift+P`
3. Type "Settings Sync: Sync Now"
4. Verify sync works

## If Sync Still Has Issues

### Option A: Manual Restore
1. Use the extracted settings from this tool
2. Copy `merged-complete-settings.json` to `.vscode/settings.json`
3. Install extensions from `complete-extensions.json`

### Option B: Fresh Start
1. Turn off Settings Sync
2. Backup your current settings (this tool does that)
3. Reset VS Code settings to default
4. Turn on Settings Sync as fresh start
5. Manually restore important settings
EOF

    echo -e "${GREEN}✓${NC} Created profile-fix-instructions.md"
}

# Function to create auto-sync script
create_auto_sync() {
    echo -e "\n${BLUE}Creating Auto-Sync System${NC}"
    echo "========================"

    cat > "$SCRIPT_DIR/auto-update-repo.sh" << 'EOF'
#!/bin/bash

# Auto-update repository with current VS Code settings
# Run this script whenever you install new extensions or change settings

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

echo "🔄 Auto-updating repository with current VS Code settings..."

# Extract current settings
./extract-settings.sh extract-all

# Update the main template with current settings if they're more comprehensive
if [[ -f "merged-complete-settings.json" ]]; then
    CURRENT_COUNT=$(grep -c '".*":' "merged-complete-settings.json" 2>/dev/null || echo "0")
    TEMPLATE_COUNT=$(grep -c '".*":' "template-settings.json" 2>/dev/null || echo "0")

    if [[ $CURRENT_COUNT -gt $TEMPLATE_COUNT ]]; then
        echo "📈 Current settings ($CURRENT_COUNT) more comprehensive than template ($TEMPLATE_COUNT)"
        echo "🔄 Updating template-settings.json..."
        cp "merged-complete-settings.json" "template-settings.json"
    fi
fi

# Update extensions list if current is more comprehensive
if [[ -f "complete-extensions.json" ]]; then
    CURRENT_EXT_COUNT=$(grep -c '".*\.[^"]*"' "complete-extensions.json" 2>/dev/null || echo "0")
    TEMPLATE_EXT_COUNT=$(grep -c '".*\.[^"]*"' ".vscode/extensions.json" 2>/dev/null || echo "0")

    if [[ $CURRENT_EXT_COUNT -gt $TEMPLATE_EXT_COUNT ]]; then
        echo "📦 Current extensions ($CURRENT_EXT_COUNT) more than template ($TEMPLATE_EXT_COUNT)"
        echo "🔄 Updating .vscode/extensions.json..."
        cp "complete-extensions.json" ".vscode/extensions.json"
    fi
fi

# Git operations (if this is a git repo)
if [[ -d ".git" ]]; then
    echo "📝 Checking for changes to commit..."

    if git diff --quiet && git diff --staged --quiet; then
        echo "✅ No changes to commit"
    else
        echo "💾 Committing updated settings..."
        git add .
        git commit -m "Auto-update: VS Code settings and extensions $(date '+%Y-%m-%d %H:%M')"

        echo "🚀 Pushing to remote..."
        git push origin main || echo "⚠️  Push failed - you may need to pull first"
    fi
fi

echo "✅ Auto-update complete!"
EOF

    chmod +x "$SCRIPT_DIR/auto-update-repo.sh"
    echo -e "${GREEN}✓${NC} Created auto-update-repo.sh"
}

# Function to create scheduled sync
create_scheduled_sync() {
    echo -e "\n${BLUE}Creating Scheduled Sync (Optional)${NC}"
    echo "================================="

    cat > "$SCRIPT_DIR/setup-cron.sh" << 'EOF'
#!/bin/bash

# Setup automatic sync every day at 6 PM
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up daily auto-sync..."

# Add to crontab
(crontab -l 2>/dev/null; echo "0 18 * * * cd '$REPO_DIR' && ./auto-update-repo.sh >> '$REPO_DIR/auto-sync.log' 2>&1") | crontab -

echo "✅ Scheduled daily sync at 6 PM"
echo "📝 Logs will be written to auto-sync.log"
echo ""
echo "To remove:"
echo "crontab -e"
echo "# Delete the line containing auto-update-repo.sh"
EOF

    chmod +x "$SCRIPT_DIR/setup-cron.sh"
    echo -e "${GREEN}✓${NC} Created setup-cron.sh (optional scheduled sync)"
}

# Main menu
case "$1" in
    "extract-all")
        check_settings_sync
        extract_current_settings
        extract_extensions
        merge_settings
        ;;
    "fix-profiles")
        fix_profiles
        ;;
    "create-auto-sync")
        create_auto_sync
        create_scheduled_sync
        ;;
    "full-setup")
        echo -e "${GREEN}Running complete settings extraction and sync setup...${NC}\n"
        check_settings_sync
        extract_current_settings
        extract_extensions
        merge_settings
        fix_profiles
        create_auto_sync
        create_scheduled_sync
        echo -e "\n${GREEN}🎉 Complete setup finished!${NC}"
        echo "Next steps:"
        echo "1. Read profile-fix-instructions.md"
        echo "2. Fix your VS Code profiles"
        echo "3. Run ./auto-update-repo.sh when you make changes"
        ;;
    *)
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  extract-all      - Extract all current VS Code settings and extensions"
        echo "  fix-profiles     - Create profile fix instructions"
        echo "  create-auto-sync - Create auto-sync system"
        echo "  full-setup       - Run complete setup process"
        echo ""
        echo "Examples:"
        echo "  $0 full-setup    # Complete setup"
        echo "  $0 extract-all   # Just extract current settings"
        ;;
esac

echo -e "\n${GREEN}Done!${NC} 🎉"
