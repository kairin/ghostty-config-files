#!/usr/bin/env bash
#
# Module: VHS - Check Dependencies
# Purpose: Verify ffmpeg and ttyd are available
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
    local task_id="vhs-deps-check"
    register_task "$task_id" "Checking VHS dependencies"
    start_task "$task_id"

    log "INFO" "Checking VHS dependencies..."

    local missing_deps=()

    # Check ffmpeg
    if command_exists "ffmpeg"; then
        local ffmpeg_version
        if ffmpeg_version=$(ffmpeg -version 2>&1 | head -n 1 | grep -oP 'version \K[\d.]+'); then
            log "SUCCESS" "  ✓ ffmpeg installed: $ffmpeg_version"
        else
            log "SUCCESS" "  ✓ ffmpeg installed (version unknown)"
        fi
    else
        log "WARNING" "  ✗ ffmpeg not installed (will install)"
        missing_deps+=("ffmpeg")
    fi

    # Check ttyd
    if command_exists "ttyd"; then
        local ttyd_version
        if ttyd_version=$(ttyd --version 2>&1 | grep -oP '\d+\.\d+\.\d+'); then
            log "SUCCESS" "  ✓ ttyd installed: $ttyd_version"
        else
            log "SUCCESS" "  ✓ ttyd installed (version unknown)"
        fi
    else
        log "WARNING" "  ✗ ttyd not installed (will install)"
        missing_deps+=("ttyd")
    fi

    # Check VHS
    if command_exists "vhs"; then
        local vhs_version
        if vhs_version=$(vhs --version 2>&1 | grep -oP '\d+\.\d+\.\d+'); then
            log "INFO" "  ℹ VHS already installed: $vhs_version (will reinstall latest)"
        else
            log "INFO" "  ℹ VHS installed (version unknown)"
        fi
    else
        log "INFO" "  ℹ VHS not installed"
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log "INFO" "Missing dependencies: ${missing_deps[*]}"
    else
        log "SUCCESS" "All dependencies present"
    fi

    complete_task "$task_id" 0
    exit 0
}

main "$@"
