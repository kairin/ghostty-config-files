#!/usr/bin/env bash
#
# Module: Ghostty - Download .deb Package
# Purpose: Download official Ghostty .deb package from GitHub
#
set -eo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"

# 2. Load Common Utils
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# 3. Main Logic
main() {
    # Environment Check
    run_environment_checks || exit 1

    # TUI Integration
    local task_id="ghostty-download"
    register_task "$task_id" "Downloading Ghostty .deb package"
    start_task "$task_id"

    # Check if already downloaded
    if [ -f "$GHOSTTY_DEB_FILE" ]; then
        log "INFO" "Package already downloaded: $GHOSTTY_DEB_FILE"
        complete_task "$task_id"
        exit 0
    fi

    # Check for updates
    local latest_version
    latest_version=$(get_latest_ghostty_version)
    if [ "$latest_version" != "unknown" ] && [ "$latest_version" != "$GHOSTTY_VERSION" ]; then
        log "WARNING" "Newer version available: $latest_version (installing $GHOSTTY_VERSION)"
        log "WARNING" "Update GHOSTTY_VERSION in common.sh to get v$latest_version"
    fi

    log "INFO" "Downloading Ghostty v${GHOSTTY_VERSION} for Ubuntu ${GHOSTTY_UBUNTU_VERSION}..."
    log "INFO" "Filename: $GHOSTTY_DEB_FILENAME"
    log "INFO" "URL: $GHOSTTY_DEB_URL"

    # Download with wget -c (resume support)
    if wget -c -O "$GHOSTTY_DEB_FILE" "$GHOSTTY_DEB_URL" 2>&1 | tee >(cat >&2); then
        log "SUCCESS" "Downloaded: $GHOSTTY_DEB_FILE"

        # Verify file exists and has content
        if [ -f "$GHOSTTY_DEB_FILE" ] && [ -s "$GHOSTTY_DEB_FILE" ]; then
            local file_size
            file_size=$(du -h "$GHOSTTY_DEB_FILE" | awk '{print $1}')
            log "INFO" "Package size: $file_size"
            complete_task "$task_id"
            exit 0
        else
            log "ERROR" "Downloaded file is empty or missing"
            fail_task "$task_id" "empty download"
            exit 1
        fi
    else
        log "ERROR" "Failed to download Ghostty package"
        fail_task "$task_id" "download failed"
        exit 1
    fi
}

main "$@"
