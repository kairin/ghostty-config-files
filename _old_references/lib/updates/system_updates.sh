#!/usr/bin/env bash
# lib/updates/system_updates.sh - System application updates for daily-updates.sh
# Contains: update_ghostty

set -uo pipefail

[ -z "${SYSTEM_UPDATES_SH_LOADED:-}" ] || return 0
SYSTEM_UPDATES_SH_LOADED=1

# update_ghostty - Update Ghostty Terminal via Snap
update_ghostty() {
    log_section "12. Updating Ghostty Terminal (Snap)"

    if ! software_exists "snap"; then
        log_skip "Snap not installed"
        track_update_result "Ghostty Terminal" "skip"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would check/update Ghostty via Snap"
        return 0
    fi

    if ! snap list ghostty &>/dev/null; then
        log_skip "Ghostty not installed via Snap"
        track_update_result "Ghostty Terminal" "skip"
        return 0
    fi

    local current_version
    current_version=$(snap list ghostty 2>/dev/null | awk 'NR==2 {print $2}' || echo "unknown")
    log_info "Current Ghostty version (Snap): $current_version"

    local latest_version
    latest_version=$(snap info ghostty 2>/dev/null | grep "^latest/stable:" | awk '{print $2}' || echo "unknown")
    log_info "Latest Ghostty version (Snap): $latest_version"

    if [[ "$current_version" == "$latest_version" ]] && [[ "$FORCE_UPDATE" != true ]]; then
        log_info "Ghostty already at latest version"
        track_update_result "Ghostty Terminal" "latest"
        return 0
    fi

    if [[ "$latest_version" == "unknown" ]]; then
        log_warning "Could not fetch latest Ghostty version from Snap store"
        track_update_result "Ghostty Terminal" "fail"
        return 1
    fi

    log_info "Ghostty update available: $current_version -> $latest_version"
    log_info "Updating Ghostty via Snap..."

    if sudo snap refresh ghostty 2>&1 | tee -a "$LOG_FILE"; then
        local new_version
        new_version=$(snap list ghostty 2>/dev/null | awk 'NR==2 {print $2}' || echo "unknown")
        log_success "Ghostty updated successfully: $current_version -> $new_version"
        track_update_result "Ghostty Terminal" "success"
        return 0
    else
        log_error "Failed to update Ghostty via Snap"
        track_update_result "Ghostty Terminal" "fail"
        return 1
    fi
}

export -f update_ghostty
