#!/usr/bin/env bash
#
# lib/ui/components/spinner.sh - Spinner animation for running tasks
#
# Dependencies: None (standalone module)
# Constitutional: Principle V - Modular Architecture (<300 lines)
#
# Functions:
#   - get_spinner_char(): Get current spinner character
#   - update_spinner(): Advance spinner animation
#   - start_spinner_loop(): Start background spinner
#   - stop_spinner_loop(): Stop background spinner
#

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_LIB_UI_COMPONENTS_SPINNER_SH:-}" ]] && return 0
readonly _LIB_UI_COMPONENTS_SPINNER_SH=1

# ============================================================================
# SPINNER CONFIGURATION
# ============================================================================

# Spinner character sets
readonly SPINNER_DOTS=("" "" "" "" "" "" "" "" "" "")
readonly SPINNER_BRAILLE=("" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "")
readonly SPINNER_SIMPLE=("-" "\\" "|" "/")
readonly SPINNER_GROWING=("" "" "" "" "" "" "" "")

# Default spinner (using braille dots for smooth animation)
declare -ga SPINNER_CHARS=("" "" "" "" "" "" "" "" "" "")

# State tracking
SPINNER_INDEX=0
SPINNER_PID=""

# ============================================================================
# SPINNER CONTROL
# ============================================================================

# Function: get_spinner_char
#   Current spinner character (stdout)
get_spinner_char() {
    echo "${SPINNER_CHARS[$SPINNER_INDEX]}"
}

# Function: update_spinner
update_spinner() {
    SPINNER_INDEX=$(( (SPINNER_INDEX + 1) % ${#SPINNER_CHARS[@]} ))
    return 0
}

# Function: reset_spinner
reset_spinner() {
    SPINNER_INDEX=0
    return 0
}

# Function: set_spinner_style
set_spinner_style() {
    local style="$1"

    case "$style" in
        dots)
            SPINNER_CHARS=("${SPINNER_DOTS[@]}")
            ;;
        braille)
            SPINNER_CHARS=("${SPINNER_BRAILLE[@]}")
            ;;
        simple)
            SPINNER_CHARS=("${SPINNER_SIMPLE[@]}")
            ;;
        growing)
            SPINNER_CHARS=("${SPINNER_GROWING[@]}")
            ;;
        *)
            echo "Unknown spinner style: $style" >&2
            return 1
            ;;
    esac

    SPINNER_INDEX=0
    return 0
}

# ============================================================================
# BACKGROUND SPINNER
# ============================================================================

# Function: start_spinner_loop
#   Spinner PID (via SPINNER_PID variable)
start_spinner_loop() {
    local interval="${1:-0.1}"
    local callback="${2:-}"

    # Don't start if already running
    if [[ -n "$SPINNER_PID" ]] && kill -0 "$SPINNER_PID" 2>/dev/null; then
        return 0
    fi

    # Start background process
    (
        while true; do
            update_spinner
            if [[ -n "$callback" ]] && declare -f "$callback" &>/dev/null; then
                "$callback"
            fi
            sleep "$interval"
        done
    ) &

    SPINNER_PID=$!

    # Write PID to temp file for external access
    echo "$SPINNER_PID" > "${TMPDIR:-/tmp}/ghostty_spinner.pid"

    return 0
}

# Function: stop_spinner_loop
# shellcheck disable=SC2120 # Function designed for external calls with optional args
stop_spinner_loop() {
    local pid="${1:-$SPINNER_PID}"

    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
    fi

    SPINNER_PID=""

    # Clean up temp file
    rm -f "${TMPDIR:-/tmp}/ghostty_spinner.pid"

    return 0
}

# Function: is_spinner_running
is_spinner_running() {
    [[ -n "$SPINNER_PID" ]] && kill -0 "$SPINNER_PID" 2>/dev/null
}

# ============================================================================
# INLINE SPINNER DISPLAY
# ============================================================================

# Function: show_spinner_inline
show_spinner_inline() {
    local message="$1"
    local duration="${2:-0}"

    local start_time
    start_time=$(date +%s)

    # Save cursor position
    echo -ne "\033[s"

    while true; do
        # Restore cursor and clear line
        echo -ne "\033[u\033[K"

        # Show spinner with message
        echo -ne "$(get_spinner_char) $message"

        update_spinner
        sleep 0.1

        # Check duration if specified
        if [[ $duration -gt 0 ]]; then
            local elapsed=$(( $(date +%s) - start_time ))
            [[ $elapsed -ge $duration ]] && break
        fi
    done

    # Clear spinner line
    echo -ne "\033[u\033[K"

    return 0
}

# Function: spinner_with_command
#   Command exit code
spinner_with_command() {
    local message="$1"
    shift
    local cmd=("$@")

    # Start spinner in background
    start_spinner_loop 0.1

    # Save cursor position
    echo -ne "\033[s"

    # Run command
    local exit_code=0
    "${cmd[@]}" &>/dev/null &
    local cmd_pid=$!

    # Show spinner while command runs
    while kill -0 "$cmd_pid" 2>/dev/null; do
        echo -ne "\033[u\033[K$(get_spinner_char) $message"
        sleep 0.1
    done

    # Get command exit code
    wait "$cmd_pid"
    exit_code=$?

    # Stop spinner
    stop_spinner_loop

    # Clear spinner line
    echo -ne "\033[u\033[K"

    return $exit_code
}

# ============================================================================
# STATUS SYMBOLS
# ============================================================================

# Function: get_status_symbol
#   Status symbol (stdout)
get_status_symbol() {
    local status="$1"

    case "$status" in
        pending)  echo "" ;;
        running)  get_spinner_char ;;
        success)  echo "" ;;
        failed)   echo "" ;;
        skipped)  echo "" ;;
        *)        echo "?" ;;
    esac
}

# NOTE: format_duration() is provided by lib/core/utils.sh
# Do NOT redefine it here - use the authoritative source
