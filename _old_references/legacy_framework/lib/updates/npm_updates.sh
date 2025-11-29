#!/usr/bin/env bash
# lib/updates/npm_updates.sh - npm and Node.js updates for daily-updates.sh
# Contains: update_fnm, update_npm_packages, update_claude_cli, update_gemini_cli, update_copilot_cli

set -uo pipefail

[ -z "${NPM_UPDATES_SH_LOADED:-}" ] || return 0
NPM_UPDATES_SH_LOADED=1

# update_fnm - Update fnm and Node.js
update_fnm() {
    log_section "4. Updating fnm (Fast Node Manager) & Node.js"

    if [[ "$SKIP_NODE" == true ]]; then
        log_skip "Skipping fnm/Node.js (--skip-node enabled)"
        track_update_result "fnm & Node.js" "skip"
        return 0
    fi

    if ! software_exists "fnm"; then
        log_skip "fnm not installed"
        track_update_result "fnm & Node.js" "skip"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would update fnm and Node.js"
        return 0
    fi

    local current_fnm_version current_node_version
    current_fnm_version=$(fnm --version 2>/dev/null || echo "unknown")
    current_node_version=$(node --version 2>/dev/null || echo 'not set')
    log_info "Current fnm version: $current_fnm_version"
    log_info "Current Node.js version: $current_node_version"

    log_info "Updating fnm to latest version..."
    if curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell 2>&1 | tee -a "$LOG_FILE"; then
        local new_fnm_version
        new_fnm_version=$(fnm --version 2>/dev/null || echo "unknown")
        log_success "fnm updated successfully"
        log_info "New fnm version: $new_fnm_version"
    else
        log_error "fnm update failed"
        track_update_result "fnm & Node.js" "fail"
        return 1
    fi

    # CONSTITUTIONAL: Use --latest (not --lts)
    log_info "Checking for Node.js latest version updates..."

    if fnm install --latest 2>&1 | tee -a "$LOG_FILE"; then
        local new_node_version
        new_node_version=$(node --version 2>/dev/null || echo 'unknown')

        if [[ "$current_node_version" == "$new_node_version" ]] && [[ "$FORCE_UPDATE" != true ]]; then
            log_info "Node.js already at latest version ($new_node_version)"
            track_update_result "fnm & Node.js" "latest"
        else
            log_success "Node.js latest version checked/updated"
            log_info "New Node.js version: $new_node_version"
            track_update_result "fnm & Node.js" "success"
        fi
    else
        log_warning "Node.js latest version check had issues"
        track_update_result "fnm & Node.js" "fail"
        return 1
    fi

    log_info "Installed Node.js versions:"
    fnm list 2>&1 | tee -a "$LOG_FILE"
}

# update_npm_packages - Update npm and global packages
update_npm_packages() {
    log_section "5. Updating npm and Global Packages"

    if [[ "$SKIP_NPM" == true ]]; then
        log_skip "Skipping npm packages (--skip-npm enabled)"
        track_update_result "npm & Global Packages" "skip"
        return 0
    fi

    if ! software_exists "npm"; then
        log_skip "npm not installed"
        track_update_result "npm & Global Packages" "skip"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would update npm and global packages"
        return 0
    fi

    local current_npm_version
    current_npm_version=$(npm --version 2>/dev/null || echo "unknown")
    log_info "Current npm version: $current_npm_version"

    log_info "Updating npm..."
    if npm install -g npm@latest 2>&1 | tee -a "$LOG_FILE"; then
        local new_npm_version
        new_npm_version=$(npm --version 2>/dev/null || echo "unknown")
        [[ "$current_npm_version" != "$new_npm_version" ]] && log_success "npm updated to $new_npm_version"
    else
        log_error "npm update failed"
        track_update_result "npm & Global Packages" "fail"
        return 1
    fi

    log_info "Globally installed packages:"
    npm list -g --depth=0 2>&1 | tee -a "$LOG_FILE"

    log_info "Checking for outdated global packages..."
    local outdated_count
    outdated_count=$(npm outdated -g 2>/dev/null | tail -n +2 | wc -l || echo "0")

    if [[ "$outdated_count" == "0" ]] && [[ "$FORCE_UPDATE" != true ]]; then
        log_info "All global packages are up to date"
        track_update_result "npm & Global Packages" "latest"
        return 0
    fi

    log_info "Updating all global npm packages ($outdated_count outdated)..."
    if npm update -g 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Global npm packages updated"
        track_update_result "npm & Global Packages" "success"
    else
        log_error "Global npm package update failed"
        track_update_result "npm & Global Packages" "fail"
        return 1
    fi
}

# update_claude_cli - Update Claude CLI
update_claude_cli() {
    log_section "6. Updating Claude CLI"

    if [[ "$SKIP_NPM" == true ]]; then
        log_skip "Skipping Claude CLI (--skip-npm enabled)"
        track_update_result "Claude CLI" "skip"
        return 0
    fi

    if ! software_exists "claude"; then
        log_skip "Claude CLI not installed"
        track_update_result "Claude CLI" "skip"
        return 0
    fi

    if ! software_exists "npm"; then
        log_skip "npm not installed, cannot update Claude CLI"
        track_update_result "Claude CLI" "skip"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would update Claude CLI"
        return 0
    fi

    local current_version
    current_version=$(claude --version 2>&1 | head -1 || echo 'unknown')
    log_info "Current Claude CLI version: $current_version"

    log_info "Updating Claude CLI..."
    if npm update -g @anthropic-ai/claude-code 2>&1 | tee -a "$LOG_FILE"; then
        local new_version
        new_version=$(claude --version 2>&1 | head -1 || echo 'unknown')
        if [[ "$current_version" == "$new_version" ]] && [[ "$FORCE_UPDATE" != true ]]; then
            log_info "Claude CLI already at latest version"
            track_update_result "Claude CLI" "latest"
        else
            log_success "Claude CLI updated to $new_version"
            track_update_result "Claude CLI" "success"
        fi
    else
        log_error "Claude CLI update failed"
        track_update_result "Claude CLI" "fail"
        return 1
    fi
}

# update_gemini_cli - Update Gemini CLI
update_gemini_cli() {
    log_section "7. Updating Gemini CLI"

    if [[ "$SKIP_NPM" == true ]]; then
        log_skip "Skipping Gemini CLI (--skip-npm enabled)"
        track_update_result "Gemini CLI" "skip"
        return 0
    fi

    if ! software_exists "gemini" && ! software_exists "gemini-cli"; then
        log_skip "Gemini CLI not installed"
        track_update_result "Gemini CLI" "skip"
        return 0
    fi

    if ! software_exists "npm"; then
        log_skip "npm not installed, cannot update Gemini CLI"
        track_update_result "Gemini CLI" "skip"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would update Gemini CLI"
        return 0
    fi

    local current_version
    current_version=$(npm list -g @google/gemini-cli --depth=0 2>/dev/null | grep @google/gemini-cli | sed 's/.*@//' || echo 'unknown')
    log_info "Current Gemini CLI version: $current_version"

    log_info "Updating Gemini CLI via npm..."
    if npm update -g @google/gemini-cli 2>&1 | tee -a "$LOG_FILE"; then
        local new_version
        new_version=$(npm list -g @google/gemini-cli --depth=0 2>/dev/null | grep @google/gemini-cli | sed 's/.*@//' || echo 'unknown')
        if [[ "$current_version" == "$new_version" ]] && [[ "$FORCE_UPDATE" != true ]]; then
            log_info "Gemini CLI already at latest version"
            track_update_result "Gemini CLI" "latest"
        else
            log_success "Gemini CLI updated to $new_version"
            track_update_result "Gemini CLI" "success"
        fi
    else
        log_error "Gemini CLI update failed"
        track_update_result "Gemini CLI" "fail"
        return 1
    fi
}

# update_copilot_cli - Update Copilot CLI
update_copilot_cli() {
    log_section "8. Updating Copilot CLI"

    if [[ "$SKIP_NPM" == true ]]; then
        log_skip "Skipping Copilot CLI (--skip-npm enabled)"
        track_update_result "Copilot CLI" "skip"
        return 0
    fi

    if ! software_exists "npm"; then
        log_skip "npm not installed, cannot check Copilot CLI"
        track_update_result "Copilot CLI" "skip"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would check/update Copilot CLI"
        return 0
    fi

    local copilot_npm_installed=false copilot_gh_installed=false

    npm list -g @github/copilot &>/dev/null && copilot_npm_installed=true
    software_exists "gh" && gh extension list 2>/dev/null | grep -q "github/gh-copilot" && copilot_gh_installed=true

    if [[ "$copilot_npm_installed" == false ]] && [[ "$copilot_gh_installed" == false ]]; then
        log_skip "GitHub Copilot CLI not installed"
        track_update_result "Copilot CLI" "skip"
        return 0
    fi

    if [[ "$copilot_npm_installed" == true ]]; then
        local current_version
        current_version=$(npm list -g @github/copilot --depth=0 2>/dev/null | grep @github/copilot | sed 's/.*@//' || echo 'unknown')
        log_info "Updating GitHub Copilot CLI via npm..."
        if npm update -g @github/copilot 2>&1 | tee -a "$LOG_FILE"; then
            local new_version
            new_version=$(npm list -g @github/copilot --depth=0 2>/dev/null | grep @github/copilot | sed 's/.*@//' || echo 'unknown')
            [[ "$current_version" == "$new_version" ]] && track_update_result "Copilot CLI" "latest" || track_update_result "Copilot CLI" "success"
        else
            track_update_result "Copilot CLI" "fail"
            return 1
        fi
    elif [[ "$copilot_gh_installed" == true ]]; then
        gh extension upgrade github/gh-copilot 2>&1 | tee -a "$LOG_FILE" || true
        track_update_result "Copilot CLI" "latest"
    fi
}

export -f update_fnm update_npm_packages update_claude_cli update_gemini_cli update_copilot_cli
