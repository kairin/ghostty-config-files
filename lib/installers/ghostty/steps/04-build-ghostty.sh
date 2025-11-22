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
    echo "  Build directory: $GHOSTTY_BUILD_DIR"
    echo "  Build type: ReleaseFast"
    echo "  This will take 5-10 minutes (compiling C/C++/Zig code)..."
    echo "  You will see periodic progress updates below:"
    echo ""

    # Use streaming to show build progress (Zig shows compilation stages)
    # Force use of our bootstrap Zig
    local zig_bin="$ZIG_INSTALL_DIR/zig"
    if [ ! -x "$zig_bin" ]; then
        # Fallback to PATH if not found (though it should be there)
        zig_bin="zig"
    fi

    if run_command_streaming "$task_id" "$zig_bin" build -Doptimize=ReleaseFast; then
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
