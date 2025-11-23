#!/usr/bin/env bash
#
# Feh Installation Manager
# Purpose: Orchestrates 5-step feh image viewer installation process
# Dependencies: build-essential, libimlib2-dev, libcurl4-openssl-dev
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
        "00-check-prerequisites.sh|Check Prerequisites|10"
        "01-uninstall-apt-version.sh|Uninstall APT Version|5"
        "02-clone-feh.sh|Clone Feh Repository|15"
        "03-build-feh.sh|Build Feh|90"
        "04-install-binary.sh|Install Feh Binary|10"
        "05-verify-installation.sh|Verify Installation|5"
    )

    # One function call runs everything with full TUI integration
    run_install_steps "Feh Image Viewer" "$STEPS_DIR" "${INSTALL_STEPS[@]}"
}

# Execute main function
main "$@"
