#!/usr/bin/env bash
#
# lib/core/errors.sh - Error handling with recovery suggestions
# Constitutional Compliance: Principle VIII - Error Handling & Recovery
#

set -euo pipefail

# Source guard - prevent redundant loading
[ -z "${ERRORS_SH_LOADED:-}" ] || return 0
ERRORS_SH_LOADED=1

# Source logging module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/logging.sh"

#
# Handle error with diagnostics and recovery suggestions
#
# Arguments:
#   $1 - Task name (human-readable)
#   $2 - Error code (exit code from failed command)
#   $3 - Error message (what went wrong)
#   $4... - Recovery suggestions (array, one suggestion per argument)
#
# Usage:
#   handle_error "Ghostty Installation" 127 \
#       "Zig compiler not found" \
#       "Install Zig 0.14.0+ from https://ziglang.org/download/" \
#       "Or use apt: sudo apt install zig" \
#       "Then re-run: ./start.sh --resume"
#
handle_error() {
    local task_name="$1"
    local error_code="$2"
    local error_message="$3"
    shift 3
    local recovery_suggestions=("$@")

    # Log error
    log "ERROR" "Task '$task_name' failed with code $error_code"
    log "ERROR" "Error: $error_message"

    # Display error diagnostics
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ ERROR: $task_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "What failed: $task_name"
    echo "Exit code:   $error_code"
    echo "Why failed:  $error_message"
    echo ""

    # Show recovery suggestions
    if [ ${#recovery_suggestions[@]} -gt 0 ]; then
        echo "How to fix:"
        for i in "${!recovery_suggestions[@]}"; do
            echo "  $((i + 1)). ${recovery_suggestions[i]}"
        done
        echo ""
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Offer continue or abort
    offer_continue_or_abort
}

#
# Offer user choice to continue or abort installation
#
# Returns:
#   0 if user chose to continue
#   Exits script if user chose to abort
#
offer_continue_or_abort() {
    local choice

    echo "Options:"
    echo "  [c] Continue to next task"
    echo "  [a] Abort installation"
    echo ""

    # Check if gum is available for interactive prompt
    if command -v gum &>/dev/null; then
        choice=$(gum choose "Continue" "Abort" --header "What would you like to do?")

        if [ "$choice" = "Abort" ]; then
            log "ERROR" "Installation aborted by user"
            echo ""
            echo "Installation aborted. To resume later, run: ./start.sh --resume"
            echo ""
            exit 1
        fi
    else
        # Fallback to read prompt
        while true; do
            read -rp "Continue or Abort? [c/a]: " choice
            case "$choice" in
                c|C)
                    log "WARNING" "User chose to continue despite error"
                    return 0
                    ;;
                a|A)
                    log "ERROR" "Installation aborted by user"
                    echo ""
                    echo "Installation aborted. To resume later, run: ./start.sh --resume"
                    echo ""
                    exit 1
                    ;;
                *)
                    echo "Invalid choice. Please enter 'c' to continue or 'a' to abort."
                    ;;
            esac
        done
    fi

    log "WARNING" "Continuing to next task despite error"
    return 0
}

#
# Handle command not found error
#
# Arguments:
#   $1 - Command name
#   $2... - Installation suggestions
#
# Usage:
#   handle_command_not_found "zig" \
#       "Install Zig from https://ziglang.org/download/" \
#       "Or use apt: sudo apt install zig"
#
handle_command_not_found() {
    local command_name="$1"
    shift
    local suggestions=("$@")

    handle_error \
        "Command Not Found" \
        127 \
        "'$command_name' command not found in PATH" \
        "${suggestions[@]}"
}

#
# Handle network error
#
# Arguments:
#   $1 - URL that failed
#   $2 - Error message
#
# Usage:
#   handle_network_error "https://github.com/ghostty-org/ghostty.git" \
#       "Connection timeout after 30 seconds"
#
handle_network_error() {
    local url="$1"
    local error_message="$2"

    handle_error \
        "Network Error" \
        1 \
        "Failed to connect to $url: $error_message" \
        "Check internet connectivity: ping -c 3 8.8.8.8" \
        "Check DNS resolution: nslookup github.com" \
        "Try again in a few moments" \
        "Check firewall/proxy settings"
}

#
# Handle permission error
#
# Arguments:
#   $1 - File or directory path
#   $2 - Operation attempted
#
# Usage:
#   handle_permission_error "/usr/local/bin/ghostty" "write"
#
handle_permission_error() {
    local path="$1"
    local operation="$2"

    handle_error \
        "Permission Denied" \
        13 \
        "Cannot $operation to $path (permission denied)" \
        "Grant permissions: sudo chmod +w $path" \
        "Or install to user directory instead" \
        "Check if passwordless sudo is configured: sudo -n true"
}

#
# Handle verification failure
#
# Arguments:
#   $1 - Component name
#   $2 - Verification check that failed
#   $3 - Expected result
#   $4 - Actual result
#
# Usage:
#   handle_verification_failure "Ghostty" \
#       "Version check" \
#       "1.1.4+" \
#       "1.0.0 (outdated)"
#
handle_verification_failure() {
    local component="$1"
    local check_name="$2"
    local expected="$3"
    local actual="$4"

    handle_error \
        "$component Verification Failed" \
        1 \
        "$check_name failed: Expected '$expected', got '$actual'" \
        "Reinstall $component: ./start.sh --force-all" \
        "Check installation logs in /tmp/ghostty-start-logs/" \
        "Manually verify: command -v ${component,,} && ${component,,} --version"
}

#
# Handle build error
#
# Arguments:
#   $1 - Component being built
#   $2 - Build command that failed
#   $3 - Error output (excerpt)
#
# Usage:
#   handle_build_error "Ghostty" \
#       "zig build -Doptimize=ReleaseFast" \
#       "error: unable to find zig compiler"
#
handle_build_error() {
    local component="$1"
    local build_command="$2"
    local error_output="$3"

    handle_error \
        "$component Build Failed" \
        1 \
        "Build command failed: $build_command" \
        "Error output: $error_output" \
        "Check build dependencies are installed" \
        "Review full build log in /tmp/ghostty-start-logs/" \
        "Try cleaning build directory and rebuilding"
}

#
# Trap handler for unexpected errors
#
# Usage:
#   trap 'error_trap_handler $? $LINENO' ERR
#
error_trap_handler() {
    local error_code="$1"
    local line_number="$2"

    log "ERROR" "Unexpected error at line $line_number (exit code: $error_code)"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ UNEXPECTED ERROR"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "An unexpected error occurred at line $line_number"
    echo "Exit code: $error_code"
    echo ""
    echo "Debug information:"
    echo "  Script: ${BASH_SOURCE[1]}"
    echo "  Function: ${FUNCNAME[1]}"
    echo "  Command: ${BASH_COMMAND}"
    echo ""
    echo "Check logs in /tmp/ghostty-start-logs/ for more details"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Save state before exiting
    if declare -f save_state &>/dev/null; then
        save_state
    fi

    exit "$error_code"
}

# Export functions for use in other modules
export -f handle_error
export -f offer_continue_or_abort
export -f handle_command_not_found
export -f handle_network_error
export -f handle_permission_error
export -f handle_verification_failure
export -f handle_build_error
export -f error_trap_handler
