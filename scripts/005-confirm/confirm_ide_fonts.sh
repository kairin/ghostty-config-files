#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

# ============================================================
# IDE Font Configuration - Post-Processing Stage
# ============================================================
# Configures Nerd Fonts for terminal emulators in IDEs
# Currently supports: Antigravity, VS Code
# ============================================================

log "INFO" "Starting IDE font configuration check..."

# Configuration templates (can be overridden via environment)
FONT_CONFIG_TERMINAL="${GHOSTTY_IDE_TERMINAL_FONT:-FiraCode Nerd Font Mono}"
FONT_CONFIG_EDITOR="${GHOSTTY_IDE_EDITOR_FONT:-FiraCode Nerd Font}"
FONT_SIZE_TERMINAL="${GHOSTTY_IDE_TERMINAL_SIZE:-14}"
FONT_SIZE_EDITOR="${GHOSTTY_IDE_EDITOR_SIZE:-15}"

# ============================================================
# Utility Functions
# ============================================================

# Check if jq is available (required for JSON manipulation)
check_jq() {
    if ! command -v jq &> /dev/null; then
        log "WARNING" "jq not installed - cannot configure IDE fonts"
        log "INFO" "Install with: sudo apt install jq"
        return 1
    fi
    return 0
}

# Check if Nerd Fonts are installed
check_nerdfonts() {
    if fc-list : family | grep -qi "Nerd"; then
        return 0
    else
        log "WARNING" "Nerd Fonts not detected - skipping IDE font configuration"
        log "INFO" "Install Nerd Fonts first: ./scripts/004-reinstall/install_nerdfonts.sh"
        return 1
    fi
}

# Create backup of settings file
backup_settings() {
    local settings_file="$1"
    local backup_file="${settings_file}.backup-$(date +%Y%m%d-%H%M%S)"

    if [ -f "$settings_file" ]; then
        cp "$settings_file" "$backup_file"
        log "INFO" "Backup created: $backup_file"
    fi
}

# ============================================================
# Antigravity IDE Configuration
# ============================================================

configure_antigravity() {
    local config_dir="$HOME/.config/Antigravity/User"
    local settings_file="$config_dir/settings.json"

    log "INFO" "Checking Antigravity IDE..."

    # Check if Antigravity is installed (config directory exists)
    if [ ! -d "$config_dir" ]; then
        log "INFO" "Antigravity not detected - skipping"
        return 0
    fi

    log "INFO" "Antigravity detected at: $config_dir"

    # Create settings file if doesn't exist
    if [ ! -f "$settings_file" ]; then
        log "INFO" "Creating new settings.json..."
        mkdir -p "$config_dir"
        echo "{}" > "$settings_file"
    fi

    # Check current configuration
    local current_terminal_font=$(jq -r '.["terminal.integrated.fontFamily"] // ""' "$settings_file" 2>/dev/null)
    local current_editor_font=$(jq -r '.["editor.fontFamily"] // ""' "$settings_file" 2>/dev/null)

    # Check if already configured with Nerd Fonts
    if [[ "$current_terminal_font" == *"Nerd Font"* ]] && [[ "$current_editor_font" == *"Nerd Font"* ]]; then
        log "SUCCESS" "Antigravity already configured with Nerd Fonts"
        return 0
    fi

    # Backup before modification
    backup_settings "$settings_file"

    # Apply font configuration (merge with existing settings)
    log "INFO" "Applying Nerd Font configuration..."

    local temp_file=$(mktemp)
    jq --arg tf "$FONT_CONFIG_TERMINAL" \
       --arg ef "$FONT_CONFIG_EDITOR, monospace" \
       --argjson ts "$FONT_SIZE_TERMINAL" \
       --argjson es "$FONT_SIZE_EDITOR" \
       '. + {
           "terminal.integrated.fontFamily": $tf,
           "terminal.integrated.fontSize": $ts,
           "terminal.integrated.fontLigatures.enabled": true,
           "editor.fontFamily": $ef,
           "editor.fontSize": $es,
           "editor.fontLigatures": true
       }' "$settings_file" > "$temp_file"

    if [ $? -eq 0 ] && [ -s "$temp_file" ]; then
        mv "$temp_file" "$settings_file"
        log "SUCCESS" "Antigravity font configuration applied (with terminal ligatures)"
        log "INFO" "Terminal font: $FONT_CONFIG_TERMINAL ($FONT_SIZE_TERMINAL pt)"
        log "INFO" "Editor font: $FONT_CONFIG_EDITOR ($FONT_SIZE_EDITOR pt)"
    else
        rm -f "$temp_file"
        log "ERROR" "Failed to apply Antigravity configuration"
        return 1
    fi

    return 0
}

# ============================================================
# VS Code Configuration
# ============================================================

configure_vscode() {
    local config_dir="$HOME/.config/Code/User"
    local settings_file="$config_dir/settings.json"

    log "INFO" "Checking VS Code..."

    # Check if VS Code is installed
    if [ ! -d "$config_dir" ]; then
        log "INFO" "VS Code not detected - skipping"
        return 0
    fi

    log "INFO" "VS Code detected at: $config_dir"

    # Create settings file if doesn't exist
    if [ ! -f "$settings_file" ]; then
        log "INFO" "Creating new settings.json..."
        mkdir -p "$config_dir"
        echo "{}" > "$settings_file"
    fi

    # Check current configuration
    local current_terminal_font=$(jq -r '.["terminal.integrated.fontFamily"] // ""' "$settings_file" 2>/dev/null)
    local current_editor_font=$(jq -r '.["editor.fontFamily"] // ""' "$settings_file" 2>/dev/null)

    # Check if already configured with Nerd Fonts
    if [[ "$current_terminal_font" == *"Nerd Font"* ]] && [[ "$current_editor_font" == *"Nerd Font"* ]]; then
        log "SUCCESS" "VS Code already configured with Nerd Fonts"
        return 0
    fi

    # Backup before modification
    backup_settings "$settings_file"

    # Apply font configuration (merge with existing settings)
    log "INFO" "Applying Nerd Font configuration..."

    local temp_file=$(mktemp)
    jq --arg tf "$FONT_CONFIG_TERMINAL" \
       --arg ef "$FONT_CONFIG_EDITOR, monospace" \
       --argjson ts "$FONT_SIZE_TERMINAL" \
       --argjson es "$FONT_SIZE_EDITOR" \
       '. + {
           "terminal.integrated.fontFamily": $tf,
           "terminal.integrated.fontSize": $ts,
           "terminal.integrated.fontLigatures.enabled": true,
           "editor.fontFamily": $ef,
           "editor.fontSize": $es,
           "editor.fontLigatures": true
       }' "$settings_file" > "$temp_file"

    if [ $? -eq 0 ] && [ -s "$temp_file" ]; then
        mv "$temp_file" "$settings_file"
        log "SUCCESS" "VS Code font configuration applied (with terminal ligatures)"
    else
        rm -f "$temp_file"
        log "ERROR" "Failed to apply VS Code configuration"
        return 1
    fi

    return 0
}

# ============================================================
# Main Execution
# ============================================================

main() {
    local exit_code=0

    # Prerequisites check
    if ! check_jq; then
        exit 1
    fi

    if ! check_nerdfonts; then
        log "WARNING" "Continuing without font configuration"
        exit 0  # Not a fatal error - fonts just won't be configured
    fi

    # Configure each supported IDE
    configure_antigravity || exit_code=1
    configure_vscode || exit_code=1

    # Summary
    if [ $exit_code -eq 0 ]; then
        log "SUCCESS" "IDE font configuration complete"

        # Generate artifact manifest for future verification
        local script_dir="$(dirname "$0")"
        local font_count=$(fc-list : family | grep -ci "Nerd" || echo "0")
        "$script_dir/generate_manifest.sh" ide_fonts "${font_count}-fonts" config > /dev/null 2>&1 || log "WARNING" "Failed to generate manifest"
        log "SUCCESS" "Artifact manifest generated for pre-reinstall verification"
    else
        log "WARNING" "Some IDE configurations failed - check logs"
    fi

    return $exit_code
}

# Run main if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
