#!/usr/bin/env bash
#
# Module: Gum - Verify Installation
# Purpose: Verify gum installation and performance
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
    local task_id="gum-verify"
    register_task "$task_id" "Verifying gum installation"
    start_task "$task_id"

    log "INFO" "Verifying gum installation..."

    # Check 1: Command exists
    if ! command -v gum >/dev/null 2>&1; then
        log "ERROR" "✗ gum command not found"
        complete_task "$task_id" 1
        exit 1
    fi

    local gum_path
    gum_path=$(command -v gum)
    log "INFO" "  gum path: $gum_path"

    # Check 2: Version check
    local version
    version=$(get_gum_version)
    log "INFO" "  gum version: $version"

    # Check 3: Functionality test
    if ! is_gum_functional; then
        log "ERROR" "✗ gum functionality test failed"
        complete_task "$task_id" 1
        exit 1
    fi

    # Check 4: Performance measurement
    local start_ns end_ns duration_ns duration_ms
    start_ns=$(date +%s%N)
    gum --version >/dev/null 2>&1 || true
    end_ns=$(date +%s%N)
    duration_ns=$((end_ns - start_ns))
    duration_ms=$((duration_ns / 1000000))

    log "INFO" "  gum startup: ${duration_ms}ms"

    log "SUCCESS" "✓ gum installed and functional"

    complete_task "$task_id" 0
    exit 0
}

main "$@"
