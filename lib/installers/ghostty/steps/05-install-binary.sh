#!/usr/bin/env bash
#
# Module: Ghostty - Install Binary
# Purpose: Install Ghostty binary and shared files
#
set -euo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"

# 2. Load Common Utils
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# 3. Temp file cleanup on exit
cleanup_build_artifacts() {
    # This is the FINAL step - clean ALL temp build artifacts after successful install
    local exit_code=$?

    if [ $exit_code -eq 0 ] || [ $exit_code -eq 2 ]; then
        # Success or skip (already installed) - safe to clean up
        log "INFO" "Cleaning up build artifacts..."

        # Clean Ghostty build directory
        if [ -d "${GHOSTTY_BUILD_DIR:-/tmp/ghostty-build}" ]; then
            log "INFO" "Removing Ghostty build directory: $GHOSTTY_BUILD_DIR"
            rm -rf "$GHOSTTY_BUILD_DIR" 2>/dev/null || true
        fi

        # Clean Zig tarball
        if [ -f "/tmp/zig-${ZIG_MIN_VERSION}.tar.xz" ]; then
            log "INFO" "Removing Zig tarball: /tmp/zig-${ZIG_MIN_VERSION}.tar.xz"
            rm -f "/tmp/zig-${ZIG_MIN_VERSION}.tar.xz" 2>/dev/null || true
        fi

        # Clean Zig source directory from ~/Apps
        if [ -d "$HOME/Apps/zig-x86_64-linux-${ZIG_MIN_VERSION}" ]; then
            log "INFO" "Removing Zig source directory: $HOME/Apps/zig-x86_64-linux-${ZIG_MIN_VERSION}"
            rm -rf "$HOME/Apps/zig-x86_64-linux-${ZIG_MIN_VERSION}" 2>/dev/null || true
        fi

        # Clean Zig symlink from ~/Apps
        if [ -L "$HOME/Apps/zig" ]; then
            log "INFO" "Removing Zig symlink: $HOME/Apps/zig"
            rm -f "$HOME/Apps/zig" 2>/dev/null || true
        fi

        log "SUCCESS" "Build artifacts cleaned up"
    else
        # Failure - keep artifacts for debugging
        log "WARN" "Build failed, keeping artifacts for debugging:"
        log "WARN" "  - Ghostty source: ${GHOSTTY_BUILD_DIR:-/tmp/ghostty-build}"
        log "WARN" "  - Zig tarball: /tmp/zig-${ZIG_MIN_VERSION}.tar.xz"
        log "WARN" "  - Zig source: $HOME/Apps/zig-x86_64-linux-${ZIG_MIN_VERSION}"
    fi
}
# Cleanup is handled by start.sh at the very end
# trap cleanup_build_artifacts EXIT

# 4. Main Logic
main() {
    # Environment Check
    run_environment_checks || exit 1

    # TUI Integration
    local task_id="install-ghostty-bin"
    register_task "$task_id" "Installing Ghostty binary"
    start_task "$task_id"
    
    # Cleanup conflicting installations
    log "INFO" "Checking for conflicting installations..."
    
    # Check for snap
    if snap list ghostty >/dev/null 2>&1; then
        log "INFO" "Removing Ghostty snap..."
        sudo snap remove ghostty 2>&1 | tee -a "$(get_log_file)" || true
    fi
    
    # Check for apt/deb
    if dpkg -l ghostty >/dev/null 2>&1; then
        log "INFO" "Removing Ghostty apt package..."
        sudo apt-get remove -y ghostty 2>&1 | tee -a "$(get_log_file)" || true
    fi
    
    # Check for manual install in /usr/local/bin
    if [ -f "/usr/local/bin/ghostty" ]; then
        log "INFO" "Removing manual installation from /usr/local/bin..."
        sudo rm -f "/usr/local/bin/ghostty"
    fi

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
