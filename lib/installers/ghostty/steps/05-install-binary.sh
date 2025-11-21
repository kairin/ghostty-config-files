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

    # Check if already installed and up-to-date
    local ghostty_bin="$GHOSTTY_INSTALL_DIR/bin/ghostty"
    if [ -x "$ghostty_bin" ]; then
        log "INFO" "Ghostty already installed, checking version..."
        local installed_version
        if installed_version=$("$ghostty_bin" --version 2>&1 | grep -oP '\d+\.\d+\.\d+' | head -1); then
            log "INFO" "Currently installed: v$installed_version"

            # Check for updates
            local latest_version
            if latest_version=$(curl -sf --max-time 5 https://api.github.com/repos/ghostty-org/ghostty/releases/latest 2>/dev/null | grep -oP '"tag_name":\s*"v?\K[0-9.]+'); then
                if [ -n "$latest_version" ]; then
                    if version_equal "$latest_version" "$installed_version"; then
                        log "SUCCESS" "Ghostty already up-to-date (v$installed_version)"
                        complete_task "$task_id"
                        exit 2  # Exit code 2 = skip (already current)
                    else
                        log "INFO" "Update available: v$latest_version, proceeding with installation..."
                    fi
                fi
            else
                log "INFO" "Could not check for updates, proceeding with installation..."
            fi
        fi
    fi

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
