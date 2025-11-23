#!/usr/bin/env bash
#
# Module: VHS - Install ffmpeg
# Purpose: Install ffmpeg multimedia framework (VHS dependency)
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
    local task_id="vhs-ffmpeg"
    register_task "$task_id" "Installing ffmpeg"
    start_task "$task_id"

    # Check if already installed
    if command_exists "ffmpeg"; then
        log "INFO" "ffmpeg already installed, checking version..."
        local version
        if version=$(ffmpeg -version 2>&1 | head -n 1 | grep -oP 'version \K[\d.]+'); then
            log "SUCCESS" "  ✓ ffmpeg $version installed"
            complete_task "$task_id" 0
            exit 0
        fi
    fi

    log "INFO" "Installing ffmpeg..."
    echo "  ⠋ Updating package lists..."

    if ! sudo apt-get update 2>&1 | tee -a "$(get_log_file)" | grep -E "Reading package lists|Building dependency tree|Get:"; then
        log "WARNING" "apt update completed with warnings (non-critical)"
    fi

    echo "  ⠋ Installing ffmpeg package..."
    if sudo apt-get install -y ffmpeg 2>&1 | tee -a "$(get_log_file)" | grep -E "Unpacking|Setting up|Processing"; then
        log "SUCCESS" "✓ Installed ffmpeg via APT"

        # Verify installation
        if version=$(ffmpeg -version 2>&1 | head -n 1 | grep -oP 'version \K[\d.]+'); then
            log "SUCCESS" "  ✓ Version: $version"
        fi

        complete_task "$task_id" 0
        exit 0
    else
        log "ERROR" "Failed to install ffmpeg"
        complete_task "$task_id" 1
        exit 1
    fi
}

main "$@"
