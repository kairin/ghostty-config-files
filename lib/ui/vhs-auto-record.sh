#!/usr/bin/env bash
#
# lib/ui/vhs-auto-record.sh - Automatic VHS Recording Infrastructure
#
# Purpose: Enable transparent automatic VHS recording for scripts
# Architecture: Self-Exec Pattern with environment detection
#
# Usage:
#   source "${REPO_ROOT}/lib/ui/vhs-auto-record.sh"
#   maybe_start_vhs_recording "script-name" "$0" "$@"
#
# How It Works:
#   1. Detects if already running under VHS (checks environment)
#   2. If not under VHS and VHS available:
#      - Generates VHS tape file
#      - Execs into VHS (replaces current process - NO RETURN)
#   3. If under VHS or VHS not available:
#      - Returns normally (continues script execution)
#
# Environment Variables:
#   VHS_AUTO_RECORD   - Set to "false" to disable auto-recording (default: true)
#   VHS_RECORDING     - Set by VHS to indicate recording in progress
#   VHS_OUTPUT        - Set by this script with output file path
#
# Constitutional Compliance:
#   - Graceful degradation (no errors if VHS not installed)
#   - No blocking on recording failures
#   - Follows script proliferation prevention (enhances existing scripts)
#   - Zero-cost if VHS not available (single command -v check)
#
# Author: ghostty-config-files automation
# Version: 1.0
# Last Modified: 2025-11-23
#

# Source guard - prevent multiple sourcing
[ -z "${VHS_AUTO_RECORD_SH_LOADED:-}" ] || return 0
VHS_AUTO_RECORD_SH_LOADED=1

# ═══════════════════════════════════════════════════════════════
# VHS Detection Functions
# ═══════════════════════════════════════════════════════════════

#
# Check if VHS is available on the system
#
# Returns:
#   0 - VHS is installed and executable
#   1 - VHS not available
#
check_vhs_available() {
    command -v vhs &>/dev/null
}

#
# Check if currently running under VHS recording session
#
# VHS sets various environment variables when recording.
# We check for VHS_RECORDING (set by this script) or common VHS patterns.
#
# Returns:
#   0 - Running under VHS
#   1 - Not running under VHS
#
is_under_vhs() {
    # Check if we've set our own marker
    if [[ -n "${VHS_RECORDING:-}" ]]; then
        return 0
    fi

    # Check for VHS-related environment variables
    # VHS typically sets variables like VHS_WIDTH, VHS_HEIGHT, etc.
    if [[ -n "${VHS_WIDTH:-}" ]] || [[ -n "${VHS_HEIGHT:-}" ]] || [[ -n "${VHS_THEME:-}" ]]; then
        return 0
    fi

    # Check if parent process is VHS
    if pgrep -P $$ | xargs -I {} ps -p {} -o comm= 2>/dev/null | grep -q "vhs"; then
        return 0
    fi

    return 1
}

#
# Check if VHS auto-recording is enabled
#
# Respects VHS_AUTO_RECORD environment variable.
# Default: enabled (true)
#
# Returns:
#   0 - Auto-recording enabled
#   1 - Auto-recording disabled
#
is_vhs_auto_record_enabled() {
    # Check if explicitly disabled
    if [[ "${VHS_AUTO_RECORD:-true}" == "false" ]]; then
        return 1
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════════
# VHS Tape File Generation
# ═══════════════════════════════════════════════════════════════

#
# Generate VHS tape file for recording a script
#
# Creates a .tape file that VHS will execute to record the script.
#
# Args:
#   $1 - Recording name (e.g., "start", "daily-updates")
#   $2 - Script path to record (e.g., "./start.sh")
#   $3+ - Script arguments (optional)
#
# Outputs:
#   Tape file path to stdout
#
# Returns:
#   0 - Tape file generated successfully
#   1 - Failed to generate tape file
#
generate_vhs_tape() {
    local recording_name="$1"
    local script_path="$2"
    shift 2
    local script_args=("$@")

    # Generate timestamp for unique filenames
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)

    # Determine output paths
    local repo_root="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
    local output_dir="${repo_root}/logs/video"
    local output_file="${output_dir}/${timestamp}.gif"
    local tape_file="/tmp/vhs-${recording_name}-${timestamp}.tape"

    # Create output directory if needed
    mkdir -p "$output_dir" 2>/dev/null || {
        # Silently fail if can't create directory
        return 1
    }

    # Build command string with arguments
    local cmd="$script_path"
    for arg in "${script_args[@]}"; do
        # Quote arguments with spaces
        if [[ "$arg" =~ [[:space:]] ]]; then
            cmd="$cmd \"$arg\""
        else
            cmd="$cmd $arg"
        fi
    done

    # Generate VHS tape file
    cat > "$tape_file" <<EOF
# VHS Auto-Recording Tape File
# Generated: ${timestamp}
# Recording: ${recording_name}
# Script: ${script_path}

# Output Configuration
Output "${output_file}"
Set Shell "bash"
Set FontSize 14
Set Width 1400
Set Height 900
Set Theme "Catppuccin Mocha"
Set TypingSpeed 50ms

# Set marker environment variable so script knows it's under VHS
# Note: We set VHS_RECORDING in the command itself for reliable detection
# Execute the script with VHS_RECORDING environment variable
Type "VHS_RECORDING=true VHS_OUTPUT='${output_file}' ${cmd}"
Sleep 500ms
Enter

# Wait for script to complete
# Adjust timing based on expected script duration
# start.sh: ~3-5 minutes typical
# daily-updates.sh: ~2-4 minutes typical
Sleep 300s

# Final pause to capture completion message
Sleep 3s
EOF

    if [[ ! -f "$tape_file" ]]; then
        return 1
    fi

    # Output tape file path for caller
    echo "$tape_file"
    return 0
}

# ═══════════════════════════════════════════════════════════════
# Main Auto-Recording Entry Point
# ═══════════════════════════════════════════════════════════════

#
# Maybe start VHS recording (main entry point)
#
# This function should be called at the very start of scripts that want
# automatic VHS recording support.
#
# Behavior:
#   - If already under VHS: Return immediately (script continues)
#   - If VHS not available: Return immediately (script continues)
#   - If VHS available and enabled: Generate tape, exec into VHS (NO RETURN)
#
# Args:
#   $1 - Recording name (e.g., "start", "daily-updates")
#   $2 - Script path ($0 from caller)
#   $3+ - Script arguments ($@ from caller)
#
# Returns:
#   0 - Not recording (continue normally)
#   NEVER RETURNS - If exec into VHS succeeds
#
maybe_start_vhs_recording() {
    local recording_name="$1"
    local script_path="$2"
    shift 2
    local script_args=("$@")

    # Check 1: Already under VHS?
    if is_under_vhs; then
        # We're already recording - continue normally
        return 0
    fi

    # Check 2: VHS auto-recording enabled?
    if ! is_vhs_auto_record_enabled; then
        # User disabled auto-recording
        return 0
    fi

    # Check 3: VHS available?
    if ! check_vhs_available; then
        # VHS not installed - continue normally (graceful degradation)
        return 0
    fi

    # All checks passed - start VHS recording
    local tape_file
    tape_file=$(generate_vhs_tape "$recording_name" "$script_path" "${script_args[@]}")

    if [[ $? -ne 0 ]] || [[ ! -f "$tape_file" ]]; then
        # Failed to generate tape file - continue without recording
        return 0
    fi

    # Print notification (will be visible in terminal, not in recording)
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "VHS Auto-Recording Enabled"
    echo "═══════════════════════════════════════════════════════════"
    echo "Recording: ${recording_name}"
    echo "Output: logs/video/$(date +%Y%m%d-%H%M%S).gif"
    echo ""
    echo "To disable: export VHS_AUTO_RECORD=false"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    sleep 2

    # CRITICAL: exec replaces current process - NO RETURN
    # The script will restart inside VHS session
    exec vhs "$tape_file"

    # If exec fails (VHS error), continue without recording
    return 0
}

# Export functions for use by other scripts
export -f check_vhs_available
export -f is_under_vhs
export -f is_vhs_auto_record_enabled
export -f generate_vhs_tape
export -f maybe_start_vhs_recording
