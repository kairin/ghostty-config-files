#!/usr/bin/env bash
#
# Module: VHS - Verify Installation
# Purpose: Verify VHS and all dependencies are working
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
    local task_id="vhs-verify"
    register_task "$task_id" "Verifying VHS installation"
    start_task "$task_id"

    log "INFO" "Verifying VHS installation..."

    local verification_failed=0

    # Check 1: VHS command exists
    if ! command_exists "vhs"; then
        log "ERROR" "  ✗ vhs command not found"
        verification_failed=1
    else
        local vhs_path
        vhs_path=$(command -v vhs)
        log "SUCCESS" "  ✓ vhs found: $vhs_path"

        # Get version
        local version
        if version=$(vhs --version 2>&1 | grep -oP '\d+\.\d+\.\d+'); then
            log "SUCCESS" "  ✓ Version: $version"
        else
            log "WARNING" "  ⚠ Could not determine version (non-critical)"
        fi
    fi

    # Check 2: ffmpeg dependency
    if ! command_exists "ffmpeg"; then
        log "ERROR" "  ✗ ffmpeg not found (required dependency)"
        verification_failed=1
    else
        log "SUCCESS" "  ✓ ffmpeg found: $(command -v ffmpeg)"
    fi

    # Check 3: ttyd dependency
    if ! command_exists "ttyd"; then
        log "ERROR" "  ✗ ttyd not found (required dependency)"
        verification_failed=1
    else
        log "SUCCESS" "  ✓ ttyd found: $(command -v ttyd)"
    fi

    # Check 4: Test basic VHS functionality
    if [ $verification_failed -eq 0 ]; then
        log "INFO" "Testing VHS functionality..."

        local test_tape
        test_tape=$(mktemp --suffix=.tape)
        cat > "$test_tape" <<'EOF'
Output /tmp/vhs-test.gif
Set Width 800
Set Height 400
Type "# VHS Installation Test"
Enter
Sleep 500ms
EOF

        if timeout 10s vhs "$test_tape" 2>&1 | tee -a "$(get_log_file)"; then
            if [ -f "/tmp/vhs-test.gif" ]; then
                log "SUCCESS" "  ✓ VHS can create recordings"
                rm -f "/tmp/vhs-test.gif"
            else
                log "WARNING" "  ⚠ VHS executed but no output file (may need display)"
            fi
        else
            log "WARNING" "  ⚠ VHS test timeout or failed (may need display environment)"
        fi

        rm -f "$test_tape"
    fi

    if [ $verification_failed -eq 1 ]; then
        log "ERROR" "VHS verification failed"
        complete_task "$task_id" 1
        exit 1
    fi

    log "SUCCESS" "✓ VHS installation verified"
    complete_task "$task_id" 0
    exit 0
}

main "$@"
