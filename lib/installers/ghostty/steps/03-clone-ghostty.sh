#!/usr/bin/env bash
#
# Module: Ghostty - Clone Repository
# Purpose: Clone Ghostty repository for building
#
set -euo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"

# 2. Load Common Utils
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# 3. Temp file cleanup on exit
cleanup_temp_files() {
    # Cleanup is handled by install-binary.sh after successful build
    # Individual step scripts don't clean their outputs (needed by next steps)
    :
}
trap cleanup_temp_files EXIT ERR INT TERM

# 4. Main Logic
main() {
    # Environment Check
    run_environment_checks || exit 1

    # TUI Integration
    local task_id="clone-ghostty"
    register_task "$task_id" "Cloning Ghostty repository"
    start_task "$task_id"

    # Check if already installed (optional, but usually we want to update if running this)
    # But for modularity, maybe we assume if this script is run, we want to clone.
    
    if [ -d "$GHOSTTY_BUILD_DIR" ]; then
        log "INFO" "Build directory exists, cleaning..."
        rm -rf "$GHOSTTY_BUILD_DIR"
    fi

    log "INFO" "Cloning Ghostty repository..."
    echo "  Repository: $GHOSTTY_REPO"
    echo "  Destination: $GHOSTTY_BUILD_DIR"
    echo "  This may take 1-2 minutes depending on your connection..."
    echo ""

    # Use streaming to show git clone progress
    if run_command_streaming "$task_id" git clone --progress --depth 1 "$GHOSTTY_REPO" "$GHOSTTY_BUILD_DIR"; then
        log "SUCCESS" "Repository cloned to $GHOSTTY_BUILD_DIR"
        complete_task "$task_id"
        exit 0
    else
        log "ERROR" "Failed to clone Ghostty repository"
        fail_task "$task_id"
        exit 1
    fi
}

main "$@"
