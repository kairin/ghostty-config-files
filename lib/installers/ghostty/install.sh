#!/usr/bin/env bash
#
# Ghostty Installation Manager
# Purpose: Orchestrates 9-step Ghostty terminal emulator installation process
# Dependencies: Zig 0.14.0+, Git, build-essential
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
    # Define installation steps as data (not loops)
    # Format: "script.sh|Display Name|Estimated Duration (seconds)"
    declare -a INSTALL_STEPS=(
        "00-check-prerequisites.sh|Check Prerequisites|5"
        "01-download-zig.sh|Download Zig Compiler|30"
        "02-extract-zig.sh|Extract Zig Tarball|10"
        "03-clone-ghostty.sh|Clone Ghostty Repository|20"
        "04-build-ghostty.sh|Build Ghostty|90"
        "05-install-binary.sh|Install Ghostty Binary|10"
        "06-configure-ghostty.sh|Configure Ghostty|10"
        "07-create-desktop-entry.sh|Create Desktop Entry|5"
        "08-verify-installation.sh|Verify Installation|5"
    )

    # One function call runs everything with full TUI integration
    run_install_steps "Ghostty Terminal" "$STEPS_DIR" "${INSTALL_STEPS[@]}"
}

# Execute main function
main "$@"
