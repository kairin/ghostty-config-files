#!/usr/bin/env bash
# lib/updates/source_updates.sh - Source-based tool updates for daily-updates.sh
# Contains: update_oh_my_zsh, update_uv, update_spec_kit, update_all_uv_tools

set -uo pipefail

[ -z "${SOURCE_UPDATES_SH_LOADED:-}" ] || return 0
SOURCE_UPDATES_SH_LOADED=1

# update_oh_my_zsh - Update Oh My Zsh framework
update_oh_my_zsh() {
    log_section "3. Updating Oh My Zsh"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would update Oh My Zsh"
        return 0
    fi

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_skip "Oh My Zsh not installed at $HOME/.oh-my-zsh"
        track_update_result "Oh My Zsh" "skip"
        return 0
    fi

    log_info "Updating Oh My Zsh..."

    if ZSH="$HOME/.oh-my-zsh" DISABLE_UPDATE_PROMPT=true \
        bash "$HOME/.oh-my-zsh/tools/upgrade.sh" 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Oh My Zsh updated"
        track_update_result "Oh My Zsh" "success"
    else
        if grep -q "already up to date" "$LOG_FILE" 2>/dev/null; then
            log_info "Oh My Zsh already up to date"
            track_update_result "Oh My Zsh" "latest"
        else
            log_warning "Oh My Zsh update had issues, but continuing"
            track_update_result "Oh My Zsh" "fail"
        fi
    fi
}

# update_uv - Update uv (Fast Python Package Installer)
update_uv() {
    log_section "9. Updating uv (Fast Python Package Installer)"

    if ! software_exists "uv"; then
        log_skip "uv not installed"
        log_info "To install: curl -LsSf https://astral.sh/uv/install.sh | sh"
        track_update_result "uv" "skip"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would update uv"
        return 0
    fi

    local current_version
    current_version=$(uv --version 2>&1 || echo 'unknown')
    log_info "Current uv version: $current_version"

    log_info "Updating uv via self-update..."
    if uv self update 2>&1 | tee -a "$LOG_FILE"; then
        local new_version
        new_version=$(uv --version 2>&1 || echo 'unknown')

        if [[ "$current_version" == "$new_version" ]] && [[ "$FORCE_UPDATE" != true ]]; then
            log_info "uv already at latest version"
            track_update_result "uv" "latest"
        else
            log_success "uv updated"
            log_info "New version: $new_version"
            track_update_result "uv" "success"
        fi
    else
        log_error "uv update failed"
        track_update_result "uv" "fail"
        return 1
    fi
}

# update_spec_kit - Update spec-kit (Specification Development Toolkit)
update_spec_kit() {
    log_section "10. Updating spec-kit (Specification Development Toolkit)"

    if ! software_exists "uv"; then
        log_skip "uv not installed - cannot update spec-kit"
        log_info "Install uv first: curl -LsSf https://astral.sh/uv/install.sh | sh"
        track_update_result "spec-kit" "skip"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would check/update spec-kit"
        return 0
    fi

    if ! uv tool list 2>/dev/null | grep -q "^specify-cli"; then
        log_skip "spec-kit not installed via uv"
        log_info "To install: uv tool install specify-cli"
        track_update_result "spec-kit" "skip"
        return 0
    fi

    log_info "Found spec-kit installed"

    local current_version
    current_version=$(specify --version 2>/dev/null | awk '{print $NF}' || echo 'unknown')
    log_info "Current spec-kit version: $current_version"

    log_info "Updating spec-kit via uv tool upgrade..."
    if uv tool upgrade specify-cli 2>&1 | tee -a "$LOG_FILE"; then
        local new_version
        new_version=$(specify --version 2>/dev/null | awk '{print $NF}' || echo 'unknown')

        if [[ "$current_version" == "$new_version" ]] && [[ "$FORCE_UPDATE" != true ]]; then
            log_info "spec-kit already at latest version"
            track_update_result "spec-kit" "latest"
        else
            log_success "spec-kit updated"
            log_info "New version: $new_version"
            track_update_result "spec-kit" "success"
        fi
    else
        log_error "spec-kit update failed"
        track_update_result "spec-kit" "fail"
        return 1
    fi
}

# update_all_uv_tools - Update all uv-installed tools
update_all_uv_tools() {
    log_section "11. Updating All uv Tools"

    if ! software_exists "uv"; then
        log_skip "uv not installed - cannot update uv tools"
        track_update_result "Additional uv Tools" "skip"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would check/update all uv tools"
        return 0
    fi

    log_info "Checking for uv tools to update..."

    local tools
    tools=$(uv tool list 2>/dev/null | awk '/^[a-zA-Z]/ {print $1}' || echo "")

    if [[ -z "$tools" ]]; then
        log_info "No additional uv tools installed"
        track_update_result "Additional uv Tools" "skip"
        return 0
    fi

    log_info "Found uv tools:"
    echo "$tools" | tee -a "$LOG_FILE"

    local update_count=0
    local fail_count=0
    while IFS= read -r tool; do
        if [[ -n "$tool" ]] && [[ "$tool" != "specify-cli" ]]; then
            log_info "Updating $tool..."
            if uv tool upgrade "$tool" 2>&1 | tee -a "$LOG_FILE"; then
                log_success "$tool updated"
                ((update_count++)) || true
            else
                log_warning "$tool update failed, continuing..."
                ((fail_count++)) || true
            fi
        fi
    done <<< "$tools"

    if [[ $update_count -gt 0 ]]; then
        log_success "Updated $update_count additional uv tools"
        track_update_result "Additional uv Tools" "success"
    elif [[ $fail_count -gt 0 ]]; then
        log_warning "Failed to update $fail_count uv tools"
        track_update_result "Additional uv Tools" "fail"
    else
        log_info "No additional uv tools needed updating"
        track_update_result "Additional uv Tools" "latest"
    fi
}

export -f update_oh_my_zsh update_uv update_spec_kit update_all_uv_tools
