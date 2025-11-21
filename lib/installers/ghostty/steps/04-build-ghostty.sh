#!/usr/bin/env bash
#
# Module: Ghostty - Build
# Purpose: Build Ghostty from source using Zig
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
    local task_id="build-ghostty"
    register_task "$task_id" "Building Ghostty (this may take 5-10 minutes)"
    start_task "$task_id"

    if [ ! -d "$GHOSTTY_BUILD_DIR" ]; then
        log "ERROR" "Build directory not found: $GHOSTTY_BUILD_DIR"
        fail_task "$task_id"
        exit 1
    fi

    cd "$GHOSTTY_BUILD_DIR" || {
        log "ERROR" "Cannot access build directory"
        fail_task "$task_id"
        exit 1
    }

    log "INFO" "Building Ghostty..."
    # We use collapsible output because build output is verbose
    if run_command_collapsible "$task_id" zig build -Doptimize=ReleaseFast; then
        log "SUCCESS" "Build completed"
        complete_task "$task_id"
        exit 0
    else
        log "ERROR" "Ghostty build failed"
        fail_task "$task_id"
        exit 1
    fi
}

main "$@"
