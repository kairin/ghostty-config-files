#!/usr/bin/env bash
# lib/updates/apt_updates.sh - APT package updates for daily-updates.sh
# Contains: update_github_cli, update_system_packages

set -uo pipefail

[ -z "${APT_UPDATES_SH_LOADED:-}" ] || return 0
APT_UPDATES_SH_LOADED=1

# Check if sudo can run apt commands without password
can_sudo_apt_without_password() {
    sudo -n /usr/bin/apt update --help >/dev/null 2>&1
}

# update_github_cli - Update GitHub CLI via apt
update_github_cli() {
    log_section "1. Updating GitHub CLI (gh)"

    if [[ "$SKIP_APT" == true ]]; then
        log_skip "Skipping GitHub CLI (--skip-apt enabled)"
        track_update_result "GitHub CLI" "skip"
        return 0
    fi

    if ! software_exists "gh"; then
        log_skip "GitHub CLI not installed"
        track_update_result "GitHub CLI" "skip"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would update GitHub CLI"
        return 0
    fi

    local current_version
    current_version=$(gh --version 2>/dev/null | head -1 || echo "unknown")
    log_info "Current gh version: $current_version"

    if ! can_sudo_apt_without_password; then
        log_warning "Cannot run apt without password - skipping GitHub CLI"
        track_update_result "GitHub CLI" "skip"
        return 0
    fi

    if sudo -n apt update 2>&1 | tee -a "$LOG_FILE"; then
        log_success "apt update completed"
    else
        log_error "apt update failed"
        track_update_result "GitHub CLI" "fail"
        return 1
    fi

    if sudo -n apt upgrade -y gh 2>&1 | tee -a "$LOG_FILE"; then
        local new_version
        new_version=$(gh --version 2>/dev/null | head -1 || echo "unknown")
        log_success "GitHub CLI updated"
        log_info "New gh version: $new_version"
        track_update_result "GitHub CLI" "success"
    else
        log_error "GitHub CLI update failed"
        track_update_result "GitHub CLI" "fail"
        return 1
    fi
}

# update_system_packages - Update system packages via apt
update_system_packages() {
    log_section "2. Updating System Packages"

    if [[ "$SKIP_APT" == true ]]; then
        log_skip "Skipping system packages (--skip-apt enabled)"
        track_update_result "System Packages" "skip"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would update system packages"
        return 0
    fi

    if ! can_sudo_apt_without_password; then
        log_warning "Cannot run apt without password - skipping system packages"
        track_update_result "System Packages" "skip"
        return 0
    fi

    log_info "Running full system update..."

    if sudo -n apt update 2>&1 | tee -a "$LOG_FILE"; then
        log_success "apt update completed"
    else
        log_error "apt update failed"
        track_update_result "System Packages" "fail"
        return 1
    fi

    local upgradable
    upgradable=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo "0")
    log_info "Packages to upgrade: $upgradable"

    if [[ "$upgradable" == "0" ]] && [[ "$FORCE_UPDATE" != true ]]; then
        log_info "System packages already up to date"
        track_update_result "System Packages" "latest"
        return 0
    fi

    local upgrade_flags="-y"
    if [[ "$ONLY_SECURITY" == true ]]; then
        upgrade_flags="-y --only-upgrade"
        log_info "Applying security updates only"
    fi

    # shellcheck disable=SC2086
    if sudo -n apt upgrade $upgrade_flags 2>&1 | tee -a "$LOG_FILE"; then
        log_success "System packages upgraded"
        track_update_result "System Packages" "success"
    else
        log_error "System package upgrade failed"
        track_update_result "System Packages" "fail"
        return 1
    fi

    log_info "Cleaning up unused packages..."
    sudo -n apt autoremove -y 2>&1 | tee -a "$LOG_FILE" || log_warning "Cleanup had issues but continuing"
}

export -f can_sudo_apt_without_password update_github_cli update_system_packages
