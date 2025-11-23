#!/usr/bin/env bash
#
# Module: Feh - Install Binary
# Purpose: Install feh binary to system
#
set -euo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"

# 2. Load Common Utils
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# 3. Cleanup temp build files after successful install
cleanup_temp_files() {
    if [ "${INSTALL_SUCCESS:-0}" -eq 1 ]; then
        log "INFO" "Cleaning up temporary build directory..."
        rm -rf "$FEH_BUILD_DIR" 2>/dev/null || true
        log "SUCCESS" "Build directory cleaned up: $FEH_BUILD_DIR"
    fi
}
trap cleanup_temp_files EXIT

# 4. Main Logic
main() {
    # Environment Check
    run_environment_checks || exit 1

    # TUI Integration
    local task_id="install-feh-binary"
    register_task "$task_id" "Installing feh binary"
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

    log "INFO" "Installing feh to $FEH_INSTALL_PREFIX"
    log "INFO" "Install prefix: $FEH_INSTALL_PREFIX"
    log "INFO" "Binary location: $FEH_INSTALL_PREFIX/bin/feh"

    # Install using make (requires sudo for /usr/local)
    if sudo make PREFIX="$FEH_INSTALL_PREFIX" install; then
        log "SUCCESS" "Feh installed successfully"

        # Verify installation
        if command -v feh >/dev/null 2>&1; then
            local installed_version
            installed_version=$(get_feh_version)
            log "SUCCESS" "Installed feh version: $installed_version"

            # Mark for cleanup
            export INSTALL_SUCCESS=1

            complete_task "$task_id"
            exit 0
        else
            log "ERROR" "Feh binary not found in PATH after installation"
            fail_task "$task_id"
            exit 1
        fi
    else
        log "ERROR" "Feh installation failed"
        fail_task "$task_id"
        exit 1
    fi
}

main "$@"
