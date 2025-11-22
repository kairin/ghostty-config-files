#!/usr/bin/env bash
#
# Module: Feh - Clone Repository
# Purpose: Clone feh repository using gh CLI
#
set -euo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"

# 2. Load Common Utils
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# 3. Temp file cleanup on exit
cleanup_temp_files() {
    # Cleanup is handled by install script after successful build
    :
}
trap cleanup_temp_files EXIT ERR INT TERM

# 4. Main Logic
main() {
    # Environment Check
    run_environment_checks || exit 1

    # TUI Integration
    local task_id="clone-feh"
    register_task "$task_id" "Cloning feh repository"
    start_task "$task_id"

    log "INFO" "Cloning feh repository to $FEH_BUILD_DIR..."
    echo "  Repository: $FEH_REPO"
    echo "  Build directory: $FEH_BUILD_DIR"
    echo ""

    # Remove existing build directory if present
    if [ -d "$FEH_BUILD_DIR" ]; then
        log "INFO" "Removing existing build directory..."
        rm -rf "$FEH_BUILD_DIR"
    fi

    # Clone using gh CLI to /tmp (following ghostty pattern)
    if gh repo clone derf/feh "$FEH_BUILD_DIR" -- --depth 1; then
        log "SUCCESS" "Feh repository cloned successfully"
        complete_task "$task_id"
        exit 0
    else
        log "ERROR" "Failed to clone feh repository"
        fail_task "$task_id"
        exit 1
    fi
}

main "$@"
