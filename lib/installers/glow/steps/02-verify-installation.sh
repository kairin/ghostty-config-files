#!/usr/bin/env bash
#
# Module: Glow - Verify Installation
# Purpose: Verify glow is installed and functional
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
    local task_id="glow-verify"
    register_task "$task_id" "Verifying glow installation"
    start_task "$task_id"

    log "INFO" "Verifying glow installation..."

    # Check 1: Command exists
    if ! command_exists "glow"; then
        log "ERROR" "  ✗ glow command not found"
        complete_task "$task_id" 1
        exit 1
    fi

    local glow_path
    glow_path=$(command -v glow)
    log "SUCCESS" "  ✓ glow found: $glow_path"

    # Check 2: Version check
    local version
    if version=$(glow --version 2>&1 | head -n 1 | grep -oP '\d+\.\d+\.\d+'); then
        log "SUCCESS" "  ✓ Version: $version"

        # Compare with minimum version (2.0.0)
        local version_major
        version_major=$(echo "$version" | cut -d. -f1)

        if [ "$version_major" -ge 2 ]; then
            log "SUCCESS" "  ✓ Version meets minimum requirement ($GLOW_MIN_VERSION)"
        else
            log "WARNING" "  ⚠ Version $version < $GLOW_MIN_VERSION (consider upgrading)"
        fi
    else
        log "WARNING" "  ⚠ Could not determine version (non-critical)"
    fi

    # Check 3: Test basic functionality
    log "INFO" "Testing basic functionality..."
    local test_md
    test_md=$(mktemp --suffix=.md)
    cat > "$test_md" <<'EOF'
# Test Markdown

This is a **test** to verify glow works correctly.

- Item 1
- Item 2
- Item 3
EOF

    if glow "$test_md" >/dev/null 2>&1; then
        log "SUCCESS" "  ✓ glow can render markdown"
    else
        log "ERROR" "  ✗ glow failed to render test markdown"
        rm -f "$test_md"
        complete_task "$task_id" 1
        exit 1
    fi

    rm -f "$test_md"

    log "SUCCESS" "✓ glow installation verified"
    complete_task "$task_id" 0
    exit 0
}

main "$@"
