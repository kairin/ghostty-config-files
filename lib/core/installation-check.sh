#!/usr/bin/env bash
#
# lib/core/installation-check.sh - Actual installation status checking
#
# Purpose: Check REAL installation status, not state file
# - Checks if binaries actually exist
# - Checks versions
# - Determines if upgrade needed
#
# Constitutional Compliance: Check actual state, not assumptions
#

set -euo pipefail

# Source guard
[ -z "${INSTALLATION_CHECK_SH_LOADED:-}" ] || return 0
INSTALLATION_CHECK_SH_LOADED=1

# Source required libraries
INSTALL_CHECK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${INSTALL_CHECK_DIR}/logging.sh"
source "${INSTALL_CHECK_DIR}/utils.sh"

#
# Check if Ghostty is actually installed
#
# Returns:
#   0 = installed
#   1 = not installed
#   2 = installed but outdated
#
check_ghostty_installed() {
    # Use command -v to detect Ghostty regardless of installation location
    # This works for both Snap installations (/usr/bin/ghostty) and
    # manual builds (~/.local/share/ghostty/bin/ghostty)
    if command -v ghostty >/dev/null 2>&1; then
        return 0  # Installed and in PATH
    fi

    return 1  # Not installed
}

#
# Check if Gum is actually installed
#
check_gum_installed() {
    if command_exists "gum"; then
        return 0  # Installed
    fi
    return 1  # Not installed
}

#
# Check if ZSH is actually installed
#
check_zsh_installed() {
    if command_exists "zsh"; then
        # Check if Oh My Zsh is installed
        if [ -d "$HOME/.oh-my-zsh" ]; then
            return 0  # ZSH + Oh My Zsh installed
        fi
    fi
    return 1  # Not fully installed
}

#
# Check if Go is actually installed
#
check_go_installed() {
    if command_exists "go"; then
        return 0  # Installed
    fi
    return 1  # Not installed
}

#
# Check if Python UV is actually installed
#
check_uv_installed() {
    if command_exists "uv"; then
        return 0  # Installed
    fi
    return 1  # Not installed
}

#
# Check if Node.js FNM is actually installed
#
check_fnm_installed() {
    if command_exists "fnm"; then
        return 0  # Installed
    fi
    return 1  # Not installed
}

#
# Check if AI tools are actually installed
#
check_ai_tools_installed() {
    # Check if at least one AI tool is installed
    if command_exists "claude" || command_exists "gemini"; then
        return 0  # At least one installed
    fi
    return 1  # None installed
}

#
# Check if context menu integration is installed
#
check_context_menu_installed() {
    # Check for Nautilus right-click context menu script
    local script_path="$HOME/.local/share/nautilus/scripts/Open in Ghostty"
    if [ -f "$script_path" ] && [ -x "$script_path" ]; then
        return 0  # Installed
    fi
    return 1  # Not installed
}

#
# Verify context menu installation (for use by start.sh TASK_REGISTRY)
#
# Returns:
#   0 = context menu installed and functional
#   1 = not installed
#
verify_context_menu() {
    local script_path="$HOME/.local/share/nautilus/scripts/Open in Ghostty"
    [ -f "$script_path" ] && [ -x "$script_path" ]
}

#
# Universal installation checker
#
# Arguments:
#   $1 - Component name (ghostty, gum, zsh, uv, fnm, ai-tools, context-menu)
#
# Returns:
#   0 = installed
#   1 = not installed
#   2 = installed but needs upgrade
#
# Usage:
#   if check_component_installed "ghostty"; then
#       echo "Ghostty is installed"
#   fi
#
check_component_installed() {
    local component="$1"

    case "$component" in
        ghostty)
            check_ghostty_installed
            ;;
        gum)
            check_gum_installed
            ;;
        zsh)
            check_zsh_installed
            ;;
        go)
            check_go_installed
            ;;
        uv)
            check_uv_installed
            ;;
        fnm)
            check_fnm_installed
            ;;
        ai-tools)
            check_ai_tools_installed
            ;;
        context-menu)
            check_context_menu_installed
            ;;
        *)
            log "ERROR" "Unknown component: $component"
            return 1
            ;;
    esac
}

#
# Determine action needed for component
#
# Arguments:
#   $1 - Component name
#
# Returns:
#   "install" = needs fresh installation
#   "upgrade" = needs upgrade
#   "skip" = already installed and up-to-date
#
# Usage:
#   action=$(get_component_action "ghostty")
#
get_component_action() {
    local component="$1"

    if check_component_installed "$component"; then
        # TODO: Add version checking logic here
        # For now, if installed, we skip
        echo "skip"
    else
        echo "install"
    fi
}

# Export functions
export -f check_ghostty_installed
export -f check_gum_installed
export -f check_zsh_installed
export -f check_go_installed
export -f check_uv_installed
export -f check_fnm_installed
export -f check_ai_tools_installed
export -f check_context_menu_installed
export -f verify_context_menu
export -f check_component_installed
export -f get_component_action

log "INFO" "installation-check.sh loaded successfully"
