#!/usr/bin/env bash
#
# Ghostty Installation Manager
# Purpose: Orchestrates 9-step Ghostty terminal emulator installation process
# Dependencies: Zig 0.14.0+, Git, build-essential
# Exit Codes: 0=success, 1=failure

set -euo pipefail

# Get script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STEPS_DIR="${SCRIPT_DIR}/steps"

# Source common functions
source "${STEPS_DIR}/common.sh"

# Source core logging if available
if [ -f "${REPO_ROOT}/lib/core/logging.sh" ]; then
    source "${REPO_ROOT}/lib/core/logging.sh"
else
    # Fallback logging functions
    log() {
        local level="$1"
        shift
        echo "[${level}] $*" >&2
    }
fi

# Main installation orchestrator
main() {
    log "INFO" "Starting Ghostty installation (9 steps)..."

    local steps=(
        "00-check-prerequisites.sh"
        "01-download-zig.sh"
        "02-extract-zig.sh"
        "03-clone-ghostty.sh"
        "04-build-ghostty.sh"
        "05-install-binary.sh"
        "06-configure-ghostty.sh"
        "07-create-desktop-entry.sh"
        "08-verify-installation.sh"
    )

    local step_num=1
    local total_steps=${#steps[@]}

    for step in "${steps[@]}"; do
        local step_name="${step%.sh}"
        log "INFO" "Step ${step_num}/${total_steps}: ${step_name}"

        if ! "${STEPS_DIR}/${step}"; then
            log "ERROR" "Ghostty installation failed at step ${step_num}/${total_steps}: ${step_name}"
            log "ERROR" "Check logs for details: /tmp/ghostty-start-logs/"
            return 1
        fi

        ((step_num++))
    done

    log "SUCCESS" "Ghostty installation complete (${total_steps}/${total_steps} steps)"
    return 0
}

# Execute main function
main "$@"
