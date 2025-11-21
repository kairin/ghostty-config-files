#!/usr/bin/env bash
#
# Context Menu Installation Manager
# Purpose: Orchestrates 3-step Nautilus context menu integration for Ghostty
# Dependencies: nautilus (GNOME file manager)
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
    log "INFO" "Starting Context Menu integration (3 steps)..."

    local steps=(
        "00-check-prerequisites.sh"
        "01-install-context-menu.sh"
        "02-verify-installation.sh"
    )

    local step_num=1
    local total_steps=${#steps[@]}

    for step in "${steps[@]}"; do
        local step_name="${step%.sh}"
        log "INFO" "Step ${step_num}/${total_steps}: ${step_name}"

        if ! "${STEPS_DIR}/${step}"; then
            log "ERROR" "Context Menu integration failed at step ${step_num}/${total_steps}: ${step_name}"
            log "ERROR" "Check logs for details: /tmp/ghostty-start-logs/"
            return 1
        fi

        ((step_num++))
    done

    log "SUCCESS" "Context Menu integration complete (${total_steps}/${total_steps} steps)"
    return 0
}

# Execute main function
main "$@"
