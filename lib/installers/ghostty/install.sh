#!/usr/bin/env bash
#
# Ghostty Installation Manager (Snap-Only Version)
# Purpose: Orchestrates Ghostty terminal emulator installation via Snap
# Dependencies: snapd
# Exit Codes: 0=success, 1=failure
#
# Architecture: Data-driven with modular TUI integration via manager-runner.sh

set -euo pipefail

# Get script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STEPS_DIR="${SCRIPT_DIR}/steps"

# Source common functions and modular TUI wrapper
source "${STEPS_DIR}/common.sh"
source "${REPO_ROOT}/lib/installers/common/manager-runner.sh"

# Main installation orchestrator
main() {
    # Define installation steps as data (Snap-only workflow)
    # Format: "script.sh|Display Name|Estimated Duration (seconds)"
    declare -a INSTALL_STEPS=(
        "00-check-prerequisites.sh|Check Prerequisites|5"
        "01-cleanup-manual-installation.sh|Cleanup Manual Installations|10"
        "02-install-snap.sh|Install from Snap|30"
        "03-configure-ghostty.sh|Configure Ghostty|5"
        "04-verify-installation.sh|Verify Installation|5"
    )

    # One function call runs everything with full TUI integration
    run_install_steps "Ghostty Terminal (Snap)" "$STEPS_DIR" "${INSTALL_STEPS[@]}"
}

# Execute main function
main "$@"
