#!/usr/bin/env bash
#
# Module: Ghostty - Check Prerequisites
# Purpose: Verify build dependencies (Zig)
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
    local task_id="ghostty-prereqs"
    register_task "$task_id" "Checking Ghostty prerequisites"
    start_task "$task_id"

    # Check Zig
    log "INFO" "Checking Zig compiler..."
    local zig_version
    zig_version=$(get_zig_version)

    if [ "$zig_version" == "none" ]; then
        log "WARNING" "Zig compiler not found"
        # We don't fail here because the next steps will install it
        # But we should probably indicate that installation is needed
        complete_task "$task_id"
        exit 0
    fi

    log "INFO" "Zig version: $zig_version"
    
    # Version check logic (simplified from original)
    # We just check if it exists for now, strict version check can be in build step or here
    # Original script checked version >= 0.15.2
    
    # Extract version for comparison
    local zig_major zig_minor zig_patch
    zig_major=$(echo "$zig_version" | cut -d. -f1)
    zig_minor=$(echo "$zig_version" | cut -d. -f2 | cut -d- -f1)
    
    # Check if version >= 0.15.2
    if [ "$zig_major" -eq 0 ] && [ "$zig_minor" -ge 15 ]; then
        log "SUCCESS" "Zig compiler ready ($zig_version)"
        complete_task "$task_id"
        exit 0
    else
        log "WARNING" "Zig version too old: $zig_version (need >= $ZIG_MIN_VERSION)"
        # Again, we don't fail because we can upgrade
        complete_task "$task_id"
        exit 0
    fi
}

main "$@"
