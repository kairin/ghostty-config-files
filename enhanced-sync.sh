#!/bin/bash

# Enhanced Cross-Repository VS Code Settings Sync with Intentional Removal Support
# This version handles intentional extension/setting removals

echo "🔄 Enhanced Cross-Repository VS Code Settings Sync"
echo "=================================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Get the template repository path
TEMPLATE_REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Configuration files
EXCLUDED_EXTENSIONS_FILE="$TEMPLATE_REPO_DIR/.sync-excluded-extensions"
EXCLUDED_SETTINGS_FILE="$TEMPLATE_REPO_DIR/.sync-excluded-settings"

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

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  capture              Capture current VS Code settings and extensions"
    echo "  exclude-extension    Mark an extension as intentionally removed"
    echo "  exclude-setting      Mark a setting as intentionally removed"
    echo "  include-extension    Re-include a previously excluded extension"
    echo "  include-setting      Re-include a previously excluded setting"
    echo "  list-excluded        Show all excluded extensions and settings"
    echo "  clean-excluded       Remove all exclusions (reset to auto-sync everything)"
    echo ""
    echo "Examples:"
    echo "  $0 capture                                    # Normal sync"
    echo "  $0 exclude-extension ms-vscode.live-server    # Exclude Live Server"
    echo "  $0 exclude-setting \"workbench.colorTheme\"     # Exclude theme setting"
    echo "  $0 list-excluded                              # Show what's excluded"
}

# Function to exclude an extension
exclude_extension() {
    local extension="$1"
    if [[ -z "$extension" ]]; then
        echo -e "${RED}✗${NC} Please specify an extension to exclude"
        echo "Example: $0 exclude-extension ms-vscode.live-server"
        return 1
    fi

    # Create excluded file if it doesn't exist
    touch "$EXCLUDED_EXTENSIONS_FILE"

    # Check if already excluded
    if grep -q "^$extension$" "$EXCLUDED_EXTENSIONS_FILE" 2>/dev/null; then
        echo -e "${YELLOW}!${NC} Extension '$extension' is already excluded"
        return 0
    fi

    # Add to excluded list
    echo "$extension" >> "$EXCLUDED_EXTENSIONS_FILE"
    echo -e "${GREEN}✓${NC} Excluded extension: $extension"
    echo -e "${BLUE}ℹ${NC} This extension will no longer be auto-installed or synced"

    # Remove from template if present
    if [[ -f "$TEMPLATE_REPO_DIR/.vscode/extensions.json" ]]; then
        # Create backup
        cp "$TEMPLATE_REPO_DIR/.vscode/extensions.json" "$TEMPLATE_REPO_DIR/.vscode/extensions.json.backup"

        # Remove the extension from recommendations
        sed -i "/$extension/d" "$TEMPLATE_REPO_DIR/.vscode/extensions.json"
        echo -e "${GREEN}✓${NC} Removed from template extensions.json"
    fi
}

# Function to exclude a setting
exclude_setting() {
    local setting="$1"
    if [[ -z "$setting" ]]; then
        echo -e "${RED}✗${NC} Please specify a setting to exclude"
        echo "Example: $0 exclude-setting \"workbench.colorTheme\""
        return 1
    fi

    # Create excluded file if it doesn't exist
    touch "$EXCLUDED_SETTINGS_FILE"

    # Check if already excluded
    if grep -q "^$setting$" "$EXCLUDED_SETTINGS_FILE" 2>/dev/null; then
        echo -e "${YELLOW}!${NC} Setting '$setting' is already excluded"
        return 0
    fi

    # Add to excluded list
    echo "$setting" >> "$EXCLUDED_SETTINGS_FILE"
    echo -e "${GREEN}✓${NC} Excluded setting: $setting"
    echo -e "${BLUE}ℹ${NC} This setting will no longer be synced to the template"
}

# Function to include (re-enable) an extension
include_extension() {
    local extension="$1"
    if [[ -z "$extension" ]]; then
        echo -e "${RED}✗${NC} Please specify an extension to re-include"
        return 1
    fi

    if [[ -f "$EXCLUDED_EXTENSIONS_FILE" ]]; then
        sed -i "/^$extension$/d" "$EXCLUDED_EXTENSIONS_FILE"
        echo -e "${GREEN}✓${NC} Re-included extension: $extension"
        echo -e "${BLUE}ℹ${NC} This extension will now be synced again"
    else
        echo -e "${YELLOW}!${NC} No excluded extensions file found"
    fi
}

# Function to include (re-enable) a setting
include_setting() {
    local setting="$1"
    if [[ -z "$setting" ]]; then
        echo -e "${RED}✗${NC} Please specify a setting to re-include"
        return 1
    fi

    if [[ -f "$EXCLUDED_SETTINGS_FILE" ]]; then
        sed -i "/^$setting$/d" "$EXCLUDED_SETTINGS_FILE"
        echo -e "${GREEN}✓${NC} Re-included setting: $setting"
        echo -e "${BLUE}ℹ${NC} This setting will now be synced again"
    else
        echo -e "${YELLOW}!${NC} No excluded settings file found"
    fi
}

# Function to list excluded items
list_excluded() {
    echo -e "\n${PURPLE}📋 Excluded Extensions:${NC}"
    if [[ -f "$EXCLUDED_EXTENSIONS_FILE" && -s "$EXCLUDED_EXTENSIONS_FILE" ]]; then
        while IFS= read -r ext; do
            echo -e "  ${RED}✗${NC} $ext"
        done < "$EXCLUDED_EXTENSIONS_FILE"
    else
        echo -e "  ${GREEN}(none)${NC}"
    fi

    echo -e "\n${PURPLE}📋 Excluded Settings:${NC}"
    if [[ -f "$EXCLUDED_SETTINGS_FILE" && -s "$EXCLUDED_SETTINGS_FILE" ]]; then
        while IFS= read -r setting; do
            echo -e "  ${RED}✗${NC} $setting"
        done < "$EXCLUDED_SETTINGS_FILE"
    else
        echo -e "  ${GREEN}(none)${NC}"
    fi
}

# Function to clean all exclusions
clean_excluded() {
    echo -e "${YELLOW}⚠${NC} This will remove all exclusions and sync everything again."
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f "$EXCLUDED_EXTENSIONS_FILE" "$EXCLUDED_SETTINGS_FILE"
        echo -e "${GREEN}✓${NC} All exclusions cleared"
        echo -e "${BLUE}ℹ${NC} Next sync will include everything again"
    else
        echo -e "${BLUE}ℹ${NC} Cancelled - exclusions kept"
    fi
}

# Function to check if extension is excluded
is_extension_excluded() {
    local extension="$1"
    [[ -f "$EXCLUDED_EXTENSIONS_FILE" ]] && grep -q "^$extension$" "$EXCLUDED_EXTENSIONS_FILE"
}

# Function to check if setting is excluded
is_setting_excluded() {
    local setting="$1"
    [[ -f "$EXCLUDED_SETTINGS_FILE" ]] && grep -q "^$setting$" "$EXCLUDED_SETTINGS_FILE"
}

# Enhanced capture function that respects exclusions
capture_with_exclusions() {
    echo -e "\n${BLUE}Capturing VS Code Settings (with exclusions)${NC}"
    echo "============================================="

    local settings_file="$VSCODE_USER_DIR/settings.json"

    if [[ -f "$settings_file" ]]; then
        echo -e "${GREEN}✓${NC} Found global settings.json"

        # Create filtered settings file
        local temp_settings=$(mktemp)

        # Copy settings but exclude the ones in exclusion list
        if [[ -f "$EXCLUDED_SETTINGS_FILE" ]]; then
            # Use jq if available, otherwise use basic filtering
            if command -v jq &> /dev/null; then
                local exclude_filter=""
                while IFS= read -r setting; do
                    exclude_filter="$exclude_filter | del(.\"$setting\")"
                done < "$EXCLUDED_SETTINGS_FILE"

                if [[ -n "$exclude_filter" ]]; then
                    jq "$exclude_filter" "$settings_file" > "$temp_settings"
                else
                    cp "$settings_file" "$temp_settings"
                fi
            else
                # Basic filtering without jq
                cp "$settings_file" "$temp_settings"
                while IFS= read -r setting; do
                    sed -i "/\"$setting\":/d" "$temp_settings"
                done < "$EXCLUDED_SETTINGS_FILE"
            fi
        else
            cp "$settings_file" "$temp_settings"
        fi

        # Count settings
        local current_count=$(grep -c '".*":' "$temp_settings" 2>/dev/null || echo "0")
        local template_count=$(grep -c '".*":' "$TEMPLATE_REPO_DIR/template-settings.json" 2>/dev/null || echo "0")
        local excluded_count=0
        [[ -f "$EXCLUDED_SETTINGS_FILE" ]] && excluded_count=$(wc -l < "$EXCLUDED_SETTINGS_FILE")

        echo -e "  ${YELLOW}→${NC} Global settings: $current_count (excluding $excluded_count)"
        echo -e "  ${YELLOW}→${NC} Template settings: $template_count"

        # Update template if needed
        if [[ $current_count -gt $template_count ]]; then
            echo -e "${BLUE}📈${NC} Updating template with filtered settings..."
            cp "$temp_settings" "$TEMPLATE_REPO_DIR/template-settings.json"
            echo -e "${GREEN}✓${NC} Updated template-settings.json"
        fi

        # Save current (for reference)
        cp "$temp_settings" "$TEMPLATE_REPO_DIR/current-global-settings.json"
        rm "$temp_settings"
    else
        echo -e "${RED}✗${NC} Global settings.json not found"
    fi

    # Handle extensions with exclusions
    echo -e "\n${BLUE}Capturing Extensions (with exclusions)${NC}"
    echo "======================================"

    if command -v code &> /dev/null; then
        echo -e "${GREEN}✓${NC} VS Code CLI found"

        # Get current extensions
        local extensions_list=$(code --list-extensions 2>/dev/null)
        local filtered_extensions=""
        local excluded_ext_count=0

        # Filter out excluded extensions
        while IFS= read -r ext; do
            if [[ -n "$ext" ]]; then
                if is_extension_excluded "$ext"; then
                    ((excluded_ext_count++))
                    echo -e "  ${YELLOW}↳${NC} Skipping excluded: $ext"
                else
                    filtered_extensions="$filtered_extensions$ext\n"
                fi
            fi
        done <<< "$extensions_list"

        local extension_count=$(echo -e "$filtered_extensions" | grep -c "." || echo "0")
        local template_ext_count=$(grep -c '".*\.[^"]*"' "$TEMPLATE_REPO_DIR/.vscode/extensions.json" 2>/dev/null || echo "0")

        echo -e "${GREEN}✓${NC} Found $extension_count extensions (excluding $excluded_ext_count)"
        echo -e "  ${YELLOW}→${NC} Current extensions: $extension_count"
        echo -e "  ${YELLOW}→${NC} Template extensions: $template_ext_count"

        # Update template extensions if needed
        if [[ $extension_count -gt 0 ]]; then
            echo '{' > "$TEMPLATE_REPO_DIR/current-extensions.json"
            echo '  "recommendations": [' >> "$TEMPLATE_REPO_DIR/current-extensions.json"

            local first=true
            echo -e "$filtered_extensions" | while IFS= read -r ext; do
                if [[ -n "$ext" ]]; then
                    if [[ "$first" == true ]]; then
                        echo "    \"$ext\"" >> "$TEMPLATE_REPO_DIR/current-extensions.json"
                        first=false
                    else
                        echo "    ,\"$ext\"" >> "$TEMPLATE_REPO_DIR/current-extensions.json"
                    fi
                fi
            done

            echo '  ]' >> "$TEMPLATE_REPO_DIR/current-extensions.json"
            echo '}' >> "$TEMPLATE_REPO_DIR/current-extensions.json"
        fi
    fi

    echo -e "\n${GREEN}🎉 Sync complete!${NC}"
    if [[ $excluded_ext_count -gt 0 ]] || [[ $excluded_count -gt 0 ]]; then
        echo -e "${BLUE}ℹ${NC} Respected $excluded_ext_count excluded extensions and $excluded_count excluded settings"
    fi
}

# Main execution
case "$1" in
    "capture")
        capture_with_exclusions
        ;;
    "exclude-extension")
        exclude_extension "$2"
        ;;
    "exclude-setting")
        exclude_setting "$2"
        ;;
    "include-extension")
        include_extension "$2"
        ;;
    "include-setting")
        include_setting "$2"
        ;;
    "list-excluded")
        list_excluded
        ;;
    "clean-excluded")
        clean_excluded
        ;;
    "help"|"--help"|"-h"|"")
        show_help
        ;;
    *)
        echo -e "${RED}✗${NC} Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
