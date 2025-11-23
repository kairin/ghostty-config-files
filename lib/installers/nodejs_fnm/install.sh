#!/usr/bin/env bash
#
# Node.js FNM Installation Manager
# Purpose: Orchestrates 5-step Fast Node Manager (fnm) installation process
# Dependencies: curl or wget, bash
# Exit Codes: 0=success, 1=failure
#
# Architecture: Data-driven with modular TUI integration via manager-runner.sh

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
        "00-check-prerequisites.sh|Check Prerequisites|5"
        "01-install-fnm.sh|Install Fast Node Manager|15"
        "02-install-nodejs.sh|Install Node.js Latest|30"
        "03-configure-shell.sh|Configure Shell Integration|10"
        "04-verify-installation.sh|Verify Installation|5"
    )

    # One function call runs everything with full TUI integration
    run_install_steps "Node.js FNM" "$STEPS_DIR" "${INSTALL_STEPS[@]}"
}

# Execute main function
main "$@"
