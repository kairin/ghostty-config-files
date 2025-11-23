#!/usr/bin/env bash
#
# ZSH Installation Manager
# Purpose: Orchestrates 6-step ZSH + Oh My ZSH configuration process
# Dependencies: zsh, git, curl
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
        "01-install-oh-my-zsh.sh|Install Oh My ZSH|15"
        "02-install-plugins.sh|Install ZSH Plugins|20"
        "03-configure-zshrc.sh|Configure .zshrc|10"
        "04-install-security-check.sh|Install Security Check|5"
        "05-verify-installation.sh|Verify Installation|5"
    )

    # One function call runs everything with full TUI integration
    run_install_steps "ZSH Shell" "$STEPS_DIR" "${INSTALL_STEPS[@]}"
}

# Execute main function
main "$@"
