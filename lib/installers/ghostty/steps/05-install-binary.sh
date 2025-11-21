#!/usr/bin/env bash
#
# Module: Ghostty - Install Binary
# Purpose: Install Ghostty binary and shared files
#
set -euo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../init.sh"

# 2. Load Common Utils
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# 3. Main Logic
main() {
    # Environment Check
    run_environment_checks || exit 1

    # TUI Integration
    local task_id="install-ghostty-bin"
    register_task "$task_id" "Installing Ghostty binary"
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

    log "INFO" "Installing to $GHOSTTY_INSTALL_DIR..."
    
    mkdir -p "$GHOSTTY_INSTALL_DIR/bin"
    mkdir -p "$GHOSTTY_INSTALL_DIR/share"

    # Copy binary
    if [ -f "zig-out/bin/ghostty" ]; then
        cp "zig-out/bin/ghostty" "$GHOSTTY_INSTALL_DIR/bin/"
        chmod +x "$GHOSTTY_INSTALL_DIR/bin/ghostty"
        log "SUCCESS" "Binary installed"
    else
        log "ERROR" "Build output not found: zig-out/bin/ghostty"
        fail_task "$task_id"
        exit 1
    fi

    # Copy shared files
    if [ -d "zig-out/share" ]; then
        cp -r zig-out/share/* "$GHOSTTY_INSTALL_DIR/share/" 2>/dev/null || true
        log "INFO" "Shared files installed"
    fi

    complete_task "$task_id"
    exit 0
}

main "$@"
