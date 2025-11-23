#!/usr/bin/env bash
#
# fastfetch Installation Manager
# Purpose: Orchestrates fastfetch installation (system information tool)
# Dependencies: apt or curl for binary download
# Exit Codes: 0=success, 1=failure
#
# Architecture: Data-driven with modular TUI integration via manager-runner.sh
# CRITICAL: fastfetch is installed BEFORE gum (Priority -1) for system audit display
#

set -euo pipefail

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
        "00-check-existing.sh|Check Existing Installation|3"
        "01-install-latest.sh|Install Latest fastfetch|20"
        "02-verify-installation.sh|Verify Installation|3"
    )

    # One function call runs everything with full TUI integration
    run_install_steps "fastfetch System Info Tool" "$STEPS_DIR" "${INSTALL_STEPS[@]}"
}

# Execute main function
main "$@"
