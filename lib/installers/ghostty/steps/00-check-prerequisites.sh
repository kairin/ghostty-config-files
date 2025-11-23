#!/usr/bin/env bash
#
# Module: Ghostty - Check Prerequisites
# Purpose: Verify wget and apt are available for .deb installation
#
set -eo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"

# 2. Load Common Utils
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# 3. Main Logic
main() {
    # Environment Check
    run_environment_checks || exit 1

    # TUI Integration
    local task_id="ghostty-prereqs"
    register_task "$task_id" "Checking Ghostty prerequisites"
    start_task "$task_id"

    # Check if wget is available
    if ! command -v wget &>/dev/null; then
        log "ERROR" "wget not found - required for downloading .deb package"
        fail_task "$task_id" "wget not available"
        exit 1
    fi

    # Check if apt is available
    if ! command -v apt &>/dev/null; then
        log "ERROR" "apt not found - required for installing .deb package"
        fail_task "$task_id" "apt not available"
        exit 1
    fi

    log "SUCCESS" "All prerequisites available (wget, apt)"
    complete_task "$task_id"
    exit 0
}

main "$@"
