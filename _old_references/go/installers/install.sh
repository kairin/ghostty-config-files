#!/usr/bin/env bash
#
# Go Programming Language Installation Manager
# Purpose: Orchestrates Go installation
# Dependencies: curl, tar
# Exit Codes: 0=success, 1=failure
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
    # Define installation steps as data
    declare -a INSTALL_STEPS=(
        "01-install-go.sh|Install Latest Go|60"
        "02-verify-go.sh|Verify Go Installation|5"
    )

    # One function call runs everything with full TUI integration
    run_install_steps "Go Programming Language" "$STEPS_DIR" "${INSTALL_STEPS[@]}"
}

# Execute main function
main "$@"
