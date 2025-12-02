#!/bin/bash
# Check if Antigravity IDE is installed and font configuration status
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Checking for Antigravity IDE installation..."

ANTIGRAVITY_CONFIG_DIR="$HOME/.config/Antigravity/User"
ANTIGRAVITY_SETTINGS="$ANTIGRAVITY_CONFIG_DIR/settings.json"

# Detection: Check if Antigravity is installed
detect_antigravity() {
    local binary_path=""
    local method=""

    # Method 1: Binary in PATH or common locations
    if command -v antigravity &> /dev/null; then
        binary_path=$(command -v antigravity)
        method="PATH"
    elif [ -x "/usr/bin/antigravity" ]; then
        binary_path="/usr/bin/antigravity"
        method="System"
    elif [ -x "$HOME/.local/bin/antigravity" ]; then
        binary_path="$HOME/.local/bin/antigravity"
        method="Local"
    elif [ -d "/opt/antigravity" ]; then
        binary_path="/opt/antigravity"
        method="Opt"
    fi

    # Method 2: Config directory exists (IDE was used at least once)
    if [ -z "$binary_path" ] && [ -d "$ANTIGRAVITY_CONFIG_DIR" ]; then
        binary_path="config-only"
        method="ConfigOnly"
    fi

    echo "$binary_path|$method"
}

# Check font configuration status
check_font_config() {
    local settings_file="$1"

    if [ ! -f "$settings_file" ]; then
        echo "NO_FILE"
        return
    fi

    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        echo "NO_JQ"
        return
    fi

    # Check if font settings already configured
    local has_terminal_font=$(jq -r '.["terminal.integrated.fontFamily"] // "null"' "$settings_file" 2>/dev/null)
    local has_editor_font=$(jq -r '.["editor.fontFamily"] // "null"' "$settings_file" 2>/dev/null)

    if [[ "$has_terminal_font" == *"Nerd Font"* ]] && [[ "$has_editor_font" == *"Nerd Font"* ]]; then
        echo "CONFIGURED"
    elif [[ "$has_terminal_font" != "null" ]] || [[ "$has_editor_font" != "null" ]]; then
        echo "PARTIAL"
    else
        echo "NOT_CONFIGURED"
    fi
}

# Main execution
DETECTION=$(detect_antigravity)
BINARY_PATH=$(echo "$DETECTION" | cut -d'|' -f1)
METHOD=$(echo "$DETECTION" | cut -d'|' -f2)

if [ -n "$BINARY_PATH" ]; then
    FONT_STATUS=$(check_font_config "$ANTIGRAVITY_SETTINGS")
    VERSION="detected"  # Antigravity doesn't expose version easily
    log "SUCCESS" "Antigravity is installed (method: $METHOD, fonts: $FONT_STATUS)"
    echo "INSTALLED|$VERSION|$METHOD|$ANTIGRAVITY_SETTINGS|$FONT_STATUS"
else
    log "WARNING" "Antigravity is NOT installed"
    echo "NOT_INSTALLED|-|-|-|-"
fi
