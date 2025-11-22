#!/usr/bin/env bash
#
# Module: Feh - Prerequisites
# Purpose: Check and install build dependencies
#
set -euo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"

# 2. Load Common Utils
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# 3. Main Logic
main() {
    # Environment Check
    run_environment_checks || exit 1

    # TUI Integration
    local task_id="check-feh-prerequisites"
    register_task "$task_id" "Checking feh build prerequisites"
    start_task "$task_id"

    log "INFO" "Checking feh build prerequisites..."
    echo ""

    # Required build dependencies
    local required_packages=(
        "build-essential"
        "libimlib2-dev"
        "libcurl4-openssl-dev"
        "libpng-dev"
        "libx11-dev"
        "libxt-dev"
        "libxinerama-dev"
        "libexif-dev"
        "git"
    )

    local missing_packages=()

    # Check for missing packages
    for package in "${required_packages[@]}"; do
        if ! dpkg -l | grep -qw "^ii.*${package}"; then
            missing_packages+=("$package")
        fi
    done

    if [ ${#missing_packages[@]} -eq 0 ]; then
        log "SUCCESS" "All build dependencies already installed"
        complete_task "$task_id"
        exit 0
    fi

    log "INFO" "Installing missing build dependencies: ${missing_packages[*]}"
    echo ""

    # Update package list
    if ! sudo apt update; then
        log "ERROR" "Failed to update package list"
        fail_task "$task_id"
        exit 1
    fi

    # Install missing packages
    if sudo apt install -y "${missing_packages[@]}"; then
        log "SUCCESS" "Build dependencies installed successfully"
        complete_task "$task_id"
        exit 0
    else
        log "ERROR" "Failed to install build dependencies"
        fail_task "$task_id"
        exit 1
    fi
}

main "$@"
