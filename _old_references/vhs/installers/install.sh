#!/usr/bin/env bash
#
# VHS Terminal Recorder Installation Manager
# Purpose: Orchestrates VHS installation (Charm Bracelet terminal recorder)
# Dependencies: ffmpeg, ttyd, apt with Charm repository
# Exit Codes: 0=success, 1=failure
#
# Architecture: Data-driven with modular TUI integration via manager-runner.sh
#

set -eo pipefail

# Get script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STEPS_DIR="${SCRIPT_DIR}/steps"

# Source common functions and modular TUI wrapper
source "${STEPS_DIR}/common.sh"
source "${REPO_ROOT}/lib/installers/common/manager-runner.sh"

# Main installation orchestrator
main() {
    # Define installation steps as data (not loops)
    # Format: "script.sh|Display Name|Estimated Duration (seconds)"
    declare -a INSTALL_STEPS=(
        "00-check-dependencies.sh|Check Dependencies|5"
        "01-install-ffmpeg.sh|Install ffmpeg|30"
        "02-install-ttyd.sh|Install ttyd|15"
        "03-install-vhs.sh|Install VHS|25"
        "04-verify-installation.sh|Verify Installation|10"
    )

    # One function call runs everything with full TUI integration
    run_install_steps "VHS Terminal Recorder" "$STEPS_DIR" "${INSTALL_STEPS[@]}"
}

# Execute main function
main "$@"
