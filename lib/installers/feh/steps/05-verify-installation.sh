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
    echo ""

    local all_checks_passed=0

    # Check 1: Binary installation
    echo "Check 1: Binary Installation"
    if command -v feh >/dev/null 2>&1; then
        local installed_version
        installed_version=$(get_feh_version)
        echo "  ✓ feh binary found"
        echo "  ✓ Version: $installed_version"
        echo "  ✓ Location: $(command -v feh)"
    else
        echo "  ✗ feh binary not found in PATH"
        all_checks_passed=1
    fi
    echo ""

    # Check 2: Configuration preservation
    echo "Check 2: Configuration Preservation"
    if [ -f "$HOME/.local/share/applications/feh.desktop" ]; then
        echo "  ✓ Desktop file preserved: $HOME/.local/share/applications/feh.desktop"
    else
        echo "  ⚠ Desktop file not found (will need to be recreated)"
    fi

    # Note: feh doesn't use ~/.config/feh/themes by default, this is custom user config
    if [ -d "$HOME/.config/feh" ]; then
        echo "  ✓ Custom feh config directory preserved: $HOME/.config/feh/"
        if [ -f "$HOME/.config/feh/themes" ]; then
            echo "  ✓ Themes file preserved: $HOME/.config/feh/themes"
        fi
    fi
    echo ""

    # Check 3: Compile-time features
    echo "Check 3: Compile-time Features"
    if feh --version 2>&1 | grep -q "Compile-time switches:"; then
        echo "  ✓ Compile-time switches:"
        feh --version 2>&1 | grep "Compile-time switches:" | sed 's/^/    /'

        # Verify key features enabled
        if feh --version 2>&1 | grep -q "curl"; then
            echo "  ✓ curl support enabled (HTTPS image loading)"
        fi
        if feh --version 2>&1 | grep -q "exif"; then
            echo "  ✓ EXIF support enabled"
        fi
        if feh --version 2>&1 | grep -q "xinerama"; then
            echo "  ✓ Xinerama support enabled (multimonitor)"
        fi
    fi
    echo ""

    # Check 4: Basic functionality test
    echo "Check 4: Basic Functionality"
    if timeout 2s feh --version >/dev/null 2>&1; then
        echo "  ✓ Feh launches successfully"
    else
        echo "  ✗ Feh failed to launch"
        all_checks_passed=1
    fi
    echo ""

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
