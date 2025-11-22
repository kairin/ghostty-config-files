#!/usr/bin/env bash
#
# Module: Feh - Build
# Purpose: Build feh from source using make
#
set -euo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"

# 2. Load Common Utils
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# 3. Temp file cleanup on exit
cleanup_temp_files() {
    # Cleanup is handled by install-binary.sh after successful build
    :
}
trap cleanup_temp_files EXIT ERR INT TERM

# 4. Main Logic
main() {
    # Environment Check
    run_environment_checks || exit 1

    # TUI Integration
    local task_id="build-feh"
    register_task "$task_id" "Building feh (2-5 minutes)"
    start_task "$task_id"

    if [ ! -d "$FEH_BUILD_DIR" ]; then
        log "ERROR" "Build directory not found: $FEH_BUILD_DIR"
        fail_task "$task_id"
        exit 1
    fi

    builtin cd "$FEH_BUILD_DIR" || {
        log "ERROR" "Cannot access build directory"
        fail_task "$task_id"
        exit 1
    }

    log "INFO" "Building feh..."
    echo "  Build directory: $FEH_BUILD_DIR"
    echo "  Build flags: curl=1 exif=1 inotify=1 xinerama=1"
    echo "  This will take 2-5 minutes..."
    echo ""

    # Build with recommended flags (following feh README)
    if run_command_streaming "$task_id" make curl=1 exif=1 inotify=1 xinerama=1; then
        log "SUCCESS" "Build completed"
        complete_task "$task_id"
        exit 0
    else
        log "ERROR" "Feh build failed"
        fail_task "$task_id"
        exit 1
    fi
}

main "$@"
