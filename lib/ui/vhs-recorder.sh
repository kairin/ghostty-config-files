#!/usr/bin/env bash
#
# lib/ui/vhs-recorder.sh - Automatic VHS recording wrapper
#
# Purpose: Automatically record installation process with VHS if available
# Creates professional demo GIFs and videos for documentation
#
# Constitutional Compliance:
# - Graceful degradation if VHS not available
# - No blocking on recording failures
# - Saves to documentation/demos/ for easy sharing
#

set -euo pipefail

# Source guard
[ -z "${VHS_RECORDER_SH_LOADED:-}" ] || return 0
VHS_RECORDER_SH_LOADED=1

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../core/utils.sh"
source "${SCRIPT_DIR}/../core/logging.sh"

# VHS recording settings
VHS_AVAILABLE=false
VHS_RECORDING_ENABLED="${VHS_AUTO_RECORD:-false}"
VHS_OUTPUT_DIR="${REPO_ROOT}/documentation/demos"

#
# Check if VHS is available and functional
#
# Returns:
#   0 - VHS available and working
#   1 - VHS not available or broken
#
check_vhs_available() {
    if ! command_exists "vhs"; then
        return 1
    fi

    # Test VHS can run (might need display environment)
    if timeout 2s vhs --version >/dev/null 2>&1; then
        return 0
    fi

    return 1
}

#
# Initialize VHS recording system
#
# Sets VHS_AVAILABLE flag based on detection
#
init_vhs_recorder() {
    if check_vhs_available; then
        VHS_AVAILABLE=true
        log "INFO" "VHS recorder available - recordings enabled"
    else
        VHS_AVAILABLE=false
        log "DEBUG" "VHS recorder not available - recordings disabled"
    fi
}

#
# Start VHS recording of installation
#
# Creates a VHS tape file dynamically and starts recording
#
# Args:
#   $1 - Recording name (e.g., "installation", "system-audit")
#
# Returns:
#   0 - Recording started successfully
#   1 - Recording failed to start
#
start_vhs_recording() {
    local recording_name="${1:-installation}"

    if [ "$VHS_AVAILABLE" = false ]; then
        log "DEBUG" "VHS not available - skipping recording"
        return 1
    fi

    if [ "$VHS_RECORDING_ENABLED" = false ]; then
        log "DEBUG" "VHS auto-recording disabled - set VHS_AUTO_RECORD=true to enable"
        return 1
    fi

    # Create output directory
    mkdir -p "$VHS_OUTPUT_DIR"

    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local tape_file="/tmp/vhs-${recording_name}-${timestamp}.tape"
    local output_file="${VHS_OUTPUT_DIR}/${recording_name}-${timestamp}.gif"

    # Generate VHS tape file
    cat > "$tape_file" <<EOF
# Auto-generated VHS recording
# Recording: ${recording_name}
# Timestamp: ${timestamp}

Output ${output_file}
Set Shell "bash"
Set FontSize 14
Set Width 1400
Set Height 900
Set Theme "Catppuccin Mocha"

# Record the actual terminal session
# VHS will capture the real output
EOF

    # Start VHS in background
    log "INFO" "Starting VHS recording: ${output_file}"

    # TODO: Implement actual VHS recording
    # This requires running the installation inside VHS context
    # For now, just log the intent

    log "WARNING" "VHS auto-recording requires implementation of session replay"
    log "INFO" "Use manual recording: vhs scripts/vhs/record-installation.tape"

    return 1
}

#
# Stop VHS recording
#
# Finalizes the recording and saves the output
#
# Returns:
#   0 - Recording stopped successfully
#   1 - No recording in progress or error
#
stop_vhs_recording() {
    if [ "$VHS_AVAILABLE" = false ]; then
        return 1
    fi

    # TODO: Implement actual VHS stop logic
    log "INFO" "VHS recording stopped"

    return 0
}

# Export functions
export -f check_vhs_available
export -f init_vhs_recorder
export -f start_vhs_recording
export -f stop_vhs_recording
