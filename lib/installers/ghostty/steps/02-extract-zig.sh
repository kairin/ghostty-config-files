#!/usr/bin/env bash
#
# Module: Ghostty - Extract Zig
# Purpose: Extract Zig compiler and setup symlinks
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
    local task_id="extract-zig"
    register_task "$task_id" "Extracting Zig compiler"
    start_task "$task_id"

    local zig_tarball="/tmp/zig-${ZIG_MIN_VERSION}.tar.xz"
    
    # Check if we need to extract (if zig is already good, skip)
    # For temp bootstrap, we always check if the specific binary exists
    if [ -x "$ZIG_INSTALL_DIR/zig" ]; then
         local installed_ver
         installed_ver=$("$ZIG_INSTALL_DIR/zig" version 2>/dev/null || echo "none")
         if [[ "$installed_ver" == *"$ZIG_MIN_VERSION"* ]] || [[ "$installed_ver" > "$ZIG_MIN_VERSION" ]]; then
             log "INFO" "Zig bootstrap already ready at $ZIG_INSTALL_DIR"
             complete_task "$task_id"
             exit 0
         fi
    fi

    if [ ! -f "$zig_tarball" ]; then
        log "ERROR" "Zig tarball not found at $zig_tarball"
        fail_task "$task_id"
        exit 1
    fi

    mkdir -p "$ZIG_INSTALL_DIR"
    
    log "INFO" "Extracting Zig to $ZIG_INSTALL_DIR..."
    echo "  Archive: $zig_tarball"
    echo "  Destination: $ZIG_INSTALL_DIR"
    echo ""

    # Extract stripping the first component (zig-linux-x86_64-...)
    if run_command_streaming "$task_id" tar xvf "$zig_tarball" -C "$ZIG_INSTALL_DIR" --strip-components=1; then
        log "SUCCESS" "Zig extracted"
        
        # Verify
        if [ -x "$ZIG_INSTALL_DIR/zig" ]; then
            log "SUCCESS" "Zig binary ready"
            complete_task "$task_id"
            exit 0
        else
            log "ERROR" "Zig binary not found after extraction"
            fail_task "$task_id"
            exit 1
        fi
    else
        log "ERROR" "Failed to extract Zig"
        fail_task "$task_id"
        exit 1
    fi
}

main "$@"
