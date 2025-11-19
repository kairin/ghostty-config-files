#!/usr/bin/env bash
#
# Module: Ghostty - Extract Zig
# Purpose: Extract Zig compiler and setup symlinks
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
    local task_id="extract-zig"
    register_task "$task_id" "Extracting Zig compiler"
    start_task "$task_id"

    local zig_tarball="/tmp/zig-${ZIG_MIN_VERSION}.tar.xz"
    
    # Check if we need to extract (if zig is already good, skip)
    local zig_version
    zig_version=$(get_zig_version)
    if [[ "$zig_version" == *"$ZIG_MIN_VERSION"* ]] || [[ "$zig_version" > "$ZIG_MIN_VERSION" ]]; then
         log "INFO" "Zig already installed and up to date"
         complete_task "$task_id"
         exit 0
    fi

    if [ ! -f "$zig_tarball" ]; then
        log "ERROR" "Zig tarball not found at $zig_tarball"
        fail_task "$task_id"
        exit 1
    fi

    mkdir -p "$HOME/Apps"
    cd "$HOME/Apps"

    log "INFO" "Extracting Zig..."
    if ! run_command_collapsible "$task_id" tar xf "$zig_tarball"; then
        log "ERROR" "Failed to extract Zig"
        fail_task "$task_id"
        exit 1
    fi

    # Backup old zig
    if [ -e "zig" ]; then
        log "INFO" "Backing up old Zig installation..."
        if [ -d "zig" ] && [ ! -L "zig" ]; then
             mv zig "zig-old-backup-$(date +%Y%m%d-%H%M%S)"
        elif [ -L "zig" ]; then
             rm -f zig
        else
             rm -f zig
        fi
    fi

    # Create symlink
    ln -s "zig-x86_64-linux-$ZIG_MIN_VERSION" zig
    
    # Verify
    if [ -L "zig" ]; then
        log "SUCCESS" "Zig extracted and linked"
        complete_task "$task_id"
        exit 0
    else
        log "ERROR" "Failed to create symlink"
        fail_task "$task_id"
        exit 1
    fi
}

main "$@"
