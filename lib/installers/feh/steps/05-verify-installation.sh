#!/usr/bin/env bash
#
# Module: Feh - Verify Installation
# Purpose: Verify feh installation and check configurations
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
    local task_id="verify-feh-installation"
    register_task "$task_id" "Verifying feh installation"
    start_task "$task_id"

    log "INFO" "Verifying feh installation..."

    local all_checks_passed=0

    # Check 1: Binary installation
    log "INFO" "Check 1: Binary Installation"
    if command -v feh >/dev/null 2>&1; then
        local installed_version
        installed_version=$(get_feh_version)
        log "SUCCESS" "feh binary found"
        log "SUCCESS" "Version: $installed_version"
        log "SUCCESS" "Location: $(command -v feh)"
    else
        log "ERROR" "feh binary not found in PATH"
        all_checks_passed=1
    fi

    # Check 2: Configuration preservation
    log "INFO" "Check 2: Configuration Preservation"
    if [ -f "$HOME/.local/share/applications/feh.desktop" ]; then
        log "SUCCESS" "Desktop file preserved: $HOME/.local/share/applications/feh.desktop"
    else
        log "WARNING" "Desktop file not found (will need to be recreated)"
    fi

    # Note: feh doesn't use ~/.config/feh/themes by default, this is custom user config
    if [ -d "$HOME/.config/feh" ]; then
        log "SUCCESS" "Custom feh config directory preserved: $HOME/.config/feh/"
        if [ -f "$HOME/.config/feh/themes" ]; then
            log "SUCCESS" "Themes file preserved: $HOME/.config/feh/themes"
        fi
    fi

    # Check 3: Compile-time features
    log "INFO" "Check 3: Compile-time Features"
    if feh --version 2>&1 | grep -q "Compile-time switches:"; then
        log "SUCCESS" "Compile-time switches:"
        feh --version 2>&1 | grep "Compile-time switches:" | sed 's/^/    /' | while read -r line; do
            log "INFO" "$line"
        done

        # Verify key features enabled
        if feh --version 2>&1 | grep -q "curl"; then
            log "SUCCESS" "curl support enabled (HTTPS image loading)"
        fi
        if feh --version 2>&1 | grep -q "exif"; then
            log "SUCCESS" "EXIF support enabled"
        fi
        if feh --version 2>&1 | grep -q "xinerama"; then
            log "SUCCESS" "Xinerama support enabled (multimonitor)"
        fi
    fi

    # Check 4: Basic functionality test
    log "INFO" "Check 4: Basic Functionality"
    if timeout 2s feh --version >/dev/null 2>&1; then
        log "SUCCESS" "Feh launches successfully"
    else
        log "ERROR" "Feh failed to launch"
        all_checks_passed=1
    fi

    if [ $all_checks_passed -eq 0 ]; then
        log "SUCCESS" "All verification checks passed"
        complete_task "$task_id"
        exit 0
    else
        log "ERROR" "Some verification checks failed"
        fail_task "$task_id"
        exit 1
    fi
}

main "$@"
