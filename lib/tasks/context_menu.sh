#!/usr/bin/env bash
#
# lib/tasks/context_menu.sh - Nautilus "Open in Ghostty" context menu integration
#
# CONTEXT7 STATUS: API authentication failed (invalid key)
# FALLBACK STRATEGY: Constitutional compliance from CLAUDE.md/AGENTS.md
# - Right-click context menu integration for Nautilus file manager
# - "Open in Ghostty" action for folders and desktop
# - XDG-compliant installation (~/.local/share/nautilus/scripts/)
#
# Constitutional Compliance:
# - Principle V: Modular Architecture
# - Prerequisite: Ghostty installed (from task_install_ghostty)
# - XDG Base Directory compliance
# - Idempotent installation
#
# User Stories: US1 (Fresh Installation), US3 (Re-run Safety)
#
# Requirements:
# - FR-053: Idempotency (skip if already installed)
#

set -euo pipefail

# Source required utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../core/logging.sh"
source "${SCRIPT_DIR}/../core/utils.sh"
source "${SCRIPT_DIR}/../core/state.sh"
source "${SCRIPT_DIR}/../core/errors.sh"
source "${SCRIPT_DIR}/../verification/duplicate_detection.sh"
source "${SCRIPT_DIR}/../verification/unit_tests.sh"

# Installation constants
readonly NAUTILUS_SCRIPTS_DIR="${HOME}/.local/share/nautilus/scripts"
readonly CONTEXT_MENU_SCRIPT="${NAUTILUS_SCRIPTS_DIR}/Open in Ghostty"
readonly GHOSTTY_BINARY="${GHOSTTY_APP_DIR:-$HOME/.local/share/ghostty}/bin/ghostty"

#
# Check Ghostty prerequisite
#
# Verifies Ghostty is installed and functional
#
# Returns:
#   0 = Ghostty available
#   1 = Ghostty missing
#
check_ghostty_prerequisite() {
    log "INFO" "Checking Ghostty prerequisite..."

    if ! command_exists "ghostty"; then
        log "ERROR" "✗ Ghostty not found"
        log "ERROR" "  Context menu integration requires Ghostty"
        log "ERROR" "  Install Ghostty first: run task_install_ghostty()"
        return 1
    fi

    local ghostty_version
    ghostty_version=$(ghostty --version 2>&1 | head -n 1 || echo "unknown")
    log "INFO" "  Ghostty version: $ghostty_version"
    log "SUCCESS" "✓ Ghostty available"
    return 0
}

#
# Create Nautilus script directory
#
# Creates XDG-compliant directory for Nautilus scripts
#
create_nautilus_scripts_directory() {
    log "INFO" "Creating Nautilus scripts directory..."

    if [ -d "$NAUTILUS_SCRIPTS_DIR" ]; then
        log "INFO" "  ↷ Directory already exists: $NAUTILUS_SCRIPTS_DIR"
        return 0
    fi

    if ! mkdir -p "$NAUTILUS_SCRIPTS_DIR"; then
        log "ERROR" "✗ Failed to create directory: $NAUTILUS_SCRIPTS_DIR"
        return 1
    fi

    log "SUCCESS" "✓ Created directory: $NAUTILUS_SCRIPTS_DIR"
    return 0
}

#
# Create context menu script
#
# Creates executable script for "Open in Ghostty" action
#
create_context_menu_script() {
    log "INFO" "Creating 'Open in Ghostty' context menu script..."

    # Detect Ghostty binary path
    local ghostty_path
    if command_exists "ghostty"; then
        ghostty_path=$(command -v ghostty)
        log "INFO" "  Ghostty path: $ghostty_path"
    else
        log "ERROR" "✗ Cannot detect Ghostty path"
        return 1
    fi

    # Create script with proper shebang and execution logic
    cat > "$CONTEXT_MENU_SCRIPT" <<'SCRIPT_EOF'
#!/usr/bin/env bash
#
# Nautilus Script: Open in Ghostty
#
# Opens the selected directory (or current directory) in Ghostty terminal
#
# Usage:
#   - Right-click on folder → Scripts → Open in Ghostty
#   - Right-click on desktop/empty space → Scripts → Open in Ghostty
#

# Detect Ghostty binary
GHOSTTY_BIN="ghostty"

# Get selected directory or current directory
if [ -n "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" ]; then
    # Directory selected in Nautilus
    TARGET_DIR="$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"
elif [ -n "$NAUTILUS_SCRIPT_CURRENT_URI" ]; then
    # No selection, use current directory
    TARGET_DIR=$(echo "$NAUTILUS_SCRIPT_CURRENT_URI" | sed 's|^file://||' | sed 's/%20/ /g')
else
    # Fallback to home directory
    TARGET_DIR="$HOME"
fi

# If target is a file, use its parent directory
if [ -f "$TARGET_DIR" ]; then
    TARGET_DIR=$(dirname "$TARGET_DIR")
fi

# Launch Ghostty in target directory
if command -v "$GHOSTTY_BIN" > /dev/null 2>&1; then
    cd "$TARGET_DIR" || exit 1
    "$GHOSTTY_BIN" &
else
    # Fallback error notification
    zenity --error --text="Ghostty terminal not found.\n\nPlease install Ghostty first." 2>/dev/null || \
        notify-send "Error" "Ghostty terminal not found" 2>/dev/null || \
        echo "ERROR: Ghostty not found" >&2
    exit 1
fi
SCRIPT_EOF

    # Make script executable
    chmod +x "$CONTEXT_MENU_SCRIPT"

    log "SUCCESS" "✓ Created context menu script: $CONTEXT_MENU_SCRIPT"
    return 0
}

#
# Restart Nautilus to load new scripts
#
# Restarts Nautilus file manager to recognize new scripts
#
restart_nautilus() {
    log "INFO" "Restarting Nautilus to load new scripts..."

    # Check if Nautilus is running
    if ! pgrep -x nautilus > /dev/null; then
        log "INFO" "  ↷ Nautilus not running, no restart needed"
        return 0
    fi

    # Restart Nautilus (graceful)
    if nautilus -q 2>/dev/null; then
        log "INFO" "  ✓ Nautilus restarted"
        log "INFO" "  Note: New script will appear on next Nautilus launch"
    else
        log "WARNING" "  ⚠ Failed to restart Nautilus (non-critical)"
        log "INFO" "  Manual restart: nautilus -q && nautilus &"
    fi

    return 0
}

#
# Install Nautilus "Open in Ghostty" context menu
#
# Process:
#   1. Check duplicate detection (skip if already installed)
#   2. Verify Ghostty prerequisite
#   3. Create Nautilus scripts directory
#   4. Create context menu script
#   5. Make script executable
#   6. Restart Nautilus (optional)
#   7. Verify installation
#
# Returns:
#   0 = success
#   1 = failure
#
task_install_context_menu() {
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Installing Nautilus Context Menu Integration"
    log "INFO" "════════════════════════════════════════"

    local task_start
    task_start=$(get_unix_timestamp)

    # Step 1: Duplicate Detection (Idempotency)
    log "INFO" "Checking for existing context menu integration..."

    if verify_context_menu 2>/dev/null; then
        log "INFO" "↷ Context menu integration already installed"
        mark_task_completed "install-context-menu" 0  # 0 seconds (skipped)
        return 0
    fi

    # Step 2: Check Ghostty prerequisite
    if ! check_ghostty_prerequisite; then
        handle_error "install-context-menu" 1 "Ghostty prerequisite not met" \
            "Install Ghostty first: run task_install_ghostty()" \
            "Verify Ghostty: ghostty --version"
        return 1
    fi

    # Step 3: Create Nautilus scripts directory
    if ! create_nautilus_scripts_directory; then
        handle_error "install-context-menu" 2 "Failed to create Nautilus scripts directory" \
            "Check directory permissions" \
            "Try manual creation: mkdir -p $NAUTILUS_SCRIPTS_DIR"
        return 1
    fi

    # Step 4: Create context menu script
    if ! create_context_menu_script; then
        handle_error "install-context-menu" 3 "Failed to create context menu script" \
            "Check script creation logs" \
            "Verify write permissions to $NAUTILUS_SCRIPTS_DIR"
        return 1
    fi

    # Step 5: Restart Nautilus (optional, non-blocking)
    restart_nautilus || true

    # Step 6: Verify installation
    log "INFO" "Verifying installation..."

    if verify_context_menu; then
        local task_end
        task_end=$(get_unix_timestamp)
        local duration
        duration=$(calculate_duration "$task_start" "$task_end")

        mark_task_completed "install-context-menu" "$duration"

        log "SUCCESS" "════════════════════════════════════════"
        log "SUCCESS" "✓ Context menu integration installed successfully ($(format_duration "$duration"))"
        log "SUCCESS" "════════════════════════════════════════"
        log "INFO" ""
        log "INFO" "Usage instructions:"
        log "INFO" "  1. Open Nautilus file manager"
        log "INFO" "  2. Right-click on any folder"
        log "INFO" "  3. Select: Scripts → Open in Ghostty"
        log "INFO" "  4. Ghostty terminal will open in that directory"
        log "INFO" ""
        log "INFO" "Note: If 'Scripts' menu not visible, restart Nautilus:"
        log "INFO" "  nautilus -q && nautilus &"
        log "INFO" ""
        return 0
    else
        handle_error "install-context-menu" 4 "Installation verification failed" \
            "Check logs for errors" \
            "Verify script exists: ls -l '$CONTEXT_MENU_SCRIPT'"
        return 1
    fi
}

# Export functions
export -f check_ghostty_prerequisite
export -f create_nautilus_scripts_directory
export -f create_context_menu_script
export -f restart_nautilus
export -f task_install_context_menu
