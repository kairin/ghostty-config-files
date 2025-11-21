#!/usr/bin/env bash
#
# Module: Ghostty - Download Zig
# Purpose: Download Zig compiler tarball
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
    local task_id="download-zig"
    register_task "$task_id" "Downloading Zig compiler"
    start_task "$task_id"

    # Check if already installed and up to date
    local zig_version
    zig_version=$(get_zig_version)
    
    # Simple check: if we have a version and it looks recent enough (basic check)
    # Ideally we reuse the logic from prereqs, but for now let's assume if prereqs said "ready", we might skip?
    # But prereqs script didn't exit with specific code for "skip". 
    # Let's just check if the tarball exists or if we really need to download.
    
    # Actually, let's check if we need to upgrade.
    local need_download=true
    if [ "$zig_version" != "none" ]; then
         # Check version (simplified)
         if [[ "$zig_version" == *"$ZIG_MIN_VERSION"* ]] || [[ "$zig_version" > "$ZIG_MIN_VERSION" ]]; then
             log "INFO" "Zig $zig_version already installed"
             need_download=false
         fi
    fi

    if [ "$need_download" = false ]; then
        log "INFO" "Skipping download (Zig already up to date)"
        complete_task "$task_id"
        exit 0
    fi

    local zig_tarball="/tmp/zig-${ZIG_MIN_VERSION}.tar.xz"
    
    if [ -f "$zig_tarball" ]; then
        log "INFO" "Tarball already exists at $zig_tarball"
        complete_task "$task_id"
        exit 0
    fi

    log "INFO" "Downloading Zig ${ZIG_MIN_VERSION}..."
    if run_command_collapsible "$task_id" curl -fsSL "$ZIG_DOWNLOAD_URL" -o "$zig_tarball"; then
        log "SUCCESS" "Downloaded Zig to $zig_tarball"
        complete_task "$task_id"
        exit 0
    else
        log "ERROR" "Failed to download Zig"
        fail_task "$task_id"
        exit 1
    fi
}

main "$@"
