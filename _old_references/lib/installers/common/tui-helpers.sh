#!/usr/bin/env bash
# lib/installers/common/tui-helpers.sh - TUI helper functions (Orchestrator)
# Coordinates visual rendering and user input for installer UIs
#
# This file acts as an orchestrator, sourcing modular components:
# - lib/ui/tui/render.sh - Visual rendering (headers, footers, progress)
# - lib/ui/tui/input.sh  - User input (confirmations, selections)

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_TUI_HELPERS_SOURCED:-}" ]] && return 0
readonly _TUI_HELPERS_SOURCED=1

# Determine script directory for relative sourcing
SCRIPT_DIR="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="${SCRIPT_DIR%/*}"

# Calculate path to lib/ui/tui modules
# From lib/installers/common/ we need to go up to lib/
LIB_DIR="${SCRIPT_DIR}/../.."

# Source modular components
# shellcheck source=lib/ui/tui/render.sh
if [[ -f "${LIB_DIR}/ui/tui/render.sh" ]]; then
    source "${LIB_DIR}/ui/tui/render.sh"
fi

# shellcheck source=lib/ui/tui/input.sh
if [[ -f "${LIB_DIR}/ui/tui/input.sh" ]]; then
    source "${LIB_DIR}/ui/tui/input.sh"
fi

#######################################
# log - Log message (stub if not defined elsewhere)
# Arguments:
#   $1 - Log level
#   $2 - Message
#######################################
if ! declare -f log &>/dev/null; then
    log() {
        local level="$1"
        local message="$2"
        echo "[$level] $message" >&2
    }
fi

# Re-export all functions from sourced modules for backward compatibility
# This ensures existing code that sources tui-helpers.sh continues to work

# Render functions (from lib/ui/tui/render.sh)
export -f show_component_header 2>/dev/null || true
export -f show_component_footer 2>/dev/null || true
export -f format_duration 2>/dev/null || true
export -f show_progress_bar 2>/dev/null || true
export -f show_spinner 2>/dev/null || true
export -f print_header 2>/dev/null || true
export -f print_status_line 2>/dev/null || true

# Input functions (from lib/ui/tui/input.sh)
export -f validate_step_format 2>/dev/null || true
export -f calculate_total_duration 2>/dev/null || true
export -f confirm_action 2>/dev/null || true
export -f select_option 2>/dev/null || true
export -f get_text_input 2>/dev/null || true
export -f get_password_input 2>/dev/null || true
export -f select_multiple 2>/dev/null || true
export -f wait_for_key 2>/dev/null || true
