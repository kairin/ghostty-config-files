#!/usr/bin/env bash
#
# Glow Markdown Viewer Installation Manager
# Purpose: Orchestrates glow installation (Charm Bracelet markdown renderer)
# Dependencies: apt with Charm repository
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
        "00-check-existing.sh|Check Existing Installation|3"
        "01-install-apt.sh|Install via APT|25"
        "02-verify-installation.sh|Verify Installation|5"
    )

    # One function call runs everything with full TUI integration
    run_install_steps "Glow Markdown Viewer" "$STEPS_DIR" "${INSTALL_STEPS[@]}"
}

# Execute main function
main "$@"
