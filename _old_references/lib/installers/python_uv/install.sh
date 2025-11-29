#!/usr/bin/env bash
#
# Python UV Installation Manager
# Purpose: Orchestrates 5-step Python UV package manager installation
# Dependencies: curl or wget
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
        "01-install-uv.sh|Install Python UV|20"
        "02-configure-shell.sh|Configure Shell Integration|10"
        "03-add-constitutional-warning.sh|Add Constitutional Warning|5"
        "04-verify-installation.sh|Verify Installation|5"
    )

    # One function call runs everything with full TUI integration
    run_install_steps "Python UV" "$STEPS_DIR" "${INSTALL_STEPS[@]}"
}

# Execute main function
main "$@"
