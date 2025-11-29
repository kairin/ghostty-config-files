#!/usr/bin/env bash
#
# Module: Gum - Check Existing Installation
# Purpose: Check for existing gum and report status (ALWAYS proceeds to reinstall)
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
    local task_id="gum-check"
    register_task "$task_id" "Checking existing gum installation"
    start_task "$task_id"

    # Check for existing gum
    log "INFO" "Checking for existing gum installation..."

    if command -v gum >/dev/null 2>&1; then
        local version
        version=$(get_gum_version)
        local method
        method=$(get_gum_install_method)

        log "INFO" "Found gum: $version (via $method)"
        log "WARNING" "Will reinstall latest version (constitutional requirement)"
    else
        log "INFO" "No existing gum installation found"
    fi

    complete_task "$task_id" 0
    exit 0
}

main "$@"
