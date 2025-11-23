#!/bin/bash
#
# Daily System Updates Script
# Automatically updates system packages, dev tools, and AI assistants
# Logs all output for troubleshooting
#
# Author: Auto-generated for ghostty-config-files
# Last Modified: 2025-11-23
# Version: 3.0 - Migrated to Snap-only Ghostty installation (removed Zig)

set -uo pipefail  # Removed -e to allow graceful error handling

# ============================================================================
# VHS Auto-Recording Setup (if available)
# ============================================================================
# Enable automatic VHS recording for demo creation
# If VHS available and enabled: execs into VHS (NO RETURN)
# If VHS not available or disabled: continues normally (graceful degradation)

# Discover repository root (needed for vhs-auto-record.sh)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [[ -f "${REPO_ROOT}/lib/ui/vhs-auto-record.sh" ]]; then
    source "${REPO_ROOT}/lib/ui/vhs-auto-record.sh"
    maybe_start_vhs_recording "daily-updates" "$0" "$@"
fi

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_NAME="Daily Updates"
LOG_DIR="/tmp/daily-updates-logs"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
LOG_FILE="${LOG_DIR}/update-${TIMESTAMP}.log"
ERROR_LOG="${LOG_DIR}/errors-${TIMESTAMP}.log"
SUMMARY_FILE="${LOG_DIR}/last-update-summary.txt"
LATEST_LOG_LINK="${LOG_DIR}/latest.log"

# Create log directory
mkdir -p "$LOG_DIR"

# Tracking arrays for updates
declare -a SUCCESSFUL_UPDATES=()
declare -a FAILED_UPDATES=()
declare -a SKIPPED_UPDATES=()
declare -a ALREADY_LATEST=()

# Command-line flags
DRY_RUN=false
SKIP_APT=false
SKIP_NODE=false
SKIP_NPM=false
ONLY_SECURITY=false
FORCE_UPDATE=false

# ============================================================================
# Logging Functions
# ============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_info() {
    log "INFO" "$@"
}

log_success() {
    log "SUCCESS" "✅ $@"
}

log_error() {
    log "ERROR" "❌ $@"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [ERROR] $@" >> "$ERROR_LOG"
}

log_warning() {
    log "WARNING" "⚠️  $@"
}

log_skip() {
    log "SKIP" "⏭️  $@"
}

log_section() {
    local section="$1"
    echo "" | tee -a "$LOG_FILE"
    echo "============================================================================" | tee -a "$LOG_FILE"
    echo "  $section" | tee -a "$LOG_FILE"
    echo "============================================================================" | tee -a "$LOG_FILE"
}

# ============================================================================
# Helper Functions
# ============================================================================

can_sudo_apt_without_password() {
    # Check if sudo can run apt commands without password prompt
    # Test with apt-cache which is safe and doesn't modify system
    sudo -n /usr/bin/apt update --help >/dev/null 2>&1
    return $?
}

# Check if software exists before attempting update
software_exists() {
    local software="$1"
    command -v "$software" &>/dev/null
}

# Generic wrapper for updating software with existence check
update_if_exists() {
    local name="$1"
    local check_command="$2"
    local update_function="$3"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would check/update: $name"
        return 0
    fi

    if eval "$check_command" &>/dev/null; then
        log_info "$name found, proceeding with update..."
        if eval "$update_function"; then
            SUCCESSFUL_UPDATES+=("$name")
            return 0
        else
            FAILED_UPDATES+=("$name")
            return 1
        fi
    else
        log_skip "$name not installed, skipping"
        SKIPPED_UPDATES+=("$name")
        return 0
    fi
}

# Version comparison helper
version_compare() {
    local current="$1"
    local latest="$2"

    if [[ "$current" == "$latest" ]]; then
        return 0  # Same version
    else
        return 1  # Different version
    fi
}

# Track update result
track_update_result() {
    local name="$1"
    local result="$2"  # success, fail, skip, latest

    case "$result" in
        success)
            SUCCESSFUL_UPDATES+=("$name")
            ;;
        fail)
            FAILED_UPDATES+=("$name")
            ;;
        skip)
            SKIPPED_UPDATES+=("$name")
            ;;
        latest)
            ALREADY_LATEST+=("$name")
            ;;
    esac
}

# ============================================================================
# Update Functions
# ============================================================================

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

    local current_version=$(gh --version 2>/dev/null | head -1 || echo "unknown")
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
        local new_version=$(gh --version 2>/dev/null | head -1 || echo "unknown")
        log_success "GitHub CLI updated"
        log_info "New gh version: $new_version"
        track_update_result "GitHub CLI" "success"
    else
        log_error "GitHub CLI update failed"
        track_update_result "GitHub CLI" "fail"
        return 1
    fi
}

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

    # Count upgradable packages
    local upgradable=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo "0")
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

    if sudo -n apt upgrade $upgrade_flags 2>&1 | tee -a "$LOG_FILE"; then
        log_success "System packages upgraded"
        track_update_result "System Packages" "success"
    else
        log_error "System package upgrade failed"
        track_update_result "System Packages" "fail"
        return 1
    fi

    # Auto-remove unused packages
    log_info "Cleaning up unused packages..."
    if sudo -n apt autoremove -y 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Cleanup completed"
    else
        log_warning "Cleanup had issues but continuing"
    fi
}

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

    # Oh My Zsh update (disable auto-update prompts)
    if ZSH="$HOME/.oh-my-zsh" DISABLE_UPDATE_PROMPT=true \
        bash "$HOME/.oh-my-zsh/tools/upgrade.sh" 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Oh My Zsh updated"
        track_update_result "Oh My Zsh" "success"
    else
        # Check if it failed because already up to date
        if grep -q "already up to date" "$LOG_FILE" 2>/dev/null; then
            log_info "Oh My Zsh already up to date"
            track_update_result "Oh My Zsh" "latest"
        else
            log_warning "Oh My Zsh update had issues, but continuing"
            track_update_result "Oh My Zsh" "fail"
        fi
    fi
}

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

    local current_fnm_version=$(fnm --version 2>/dev/null || echo "unknown")
    local current_node_version=$(node --version 2>/dev/null || echo 'not set')
    log_info "Current fnm version: $current_fnm_version"
    log_info "Current Node.js version: $current_node_version"

    # Update fnm itself (re-run installer)
    log_info "Updating fnm to latest version..."
    if curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell 2>&1 | tee -a "$LOG_FILE"; then
        local new_fnm_version=$(fnm --version 2>/dev/null || echo "unknown")
        log_success "fnm updated successfully"
        log_info "New fnm version: $new_fnm_version"
    else
        log_error "fnm update failed"
        track_update_result "fnm & Node.js" "fail"
        return 1
    fi

    # CONSTITUTIONAL REQUIREMENT: Use --latest (not --lts)
    # Per CLAUDE.md: "Global Policy: Always use the latest Node.js version (not LTS)"
    log_info "Checking for Node.js latest version updates..."

    if fnm install --latest 2>&1 | tee -a "$LOG_FILE"; then
        local new_node_version=$(node --version 2>/dev/null || echo 'unknown')

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

    # List installed Node.js versions
    log_info "Installed Node.js versions:"
    fnm list 2>&1 | tee -a "$LOG_FILE"
}

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

    local current_npm_version=$(npm --version 2>/dev/null || echo "unknown")
    local current_node_version=$(node --version 2>/dev/null || echo "unknown")
    log_info "Current npm version: $current_npm_version"
    log_info "Current Node.js version: $current_node_version"

    # Update npm itself
    log_info "Updating npm..."
    if npm install -g npm@latest 2>&1 | tee -a "$LOG_FILE"; then
        local new_npm_version=$(npm --version 2>/dev/null || echo "unknown")

        if [[ "$current_npm_version" == "$new_npm_version" ]] && [[ "$FORCE_UPDATE" != true ]]; then
            log_info "npm already at latest version ($new_npm_version)"
        else
            log_success "npm updated to $new_npm_version"
        fi
    else
        log_error "npm update failed"
        track_update_result "npm & Global Packages" "fail"
        return 1
    fi

    # List globally installed packages
    log_info "Globally installed packages:"
    npm list -g --depth=0 2>&1 | tee -a "$LOG_FILE"

    # Check for outdated packages first
    log_info "Checking for outdated global packages..."
    local outdated_count=$(npm outdated -g 2>/dev/null | tail -n +2 | wc -l || echo "0")

    if [[ "$outdated_count" == "0" ]] && [[ "$FORCE_UPDATE" != true ]]; then
        log_info "All global packages are up to date"
        track_update_result "npm & Global Packages" "latest"
        return 0
    fi

    # Update all global packages
    log_info "Updating all global npm packages ($outdated_count outdated)..."
    if npm update -g 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Global npm packages updated"
        track_update_result "npm & Global Packages" "success"
    else
        log_error "Global npm package update failed"
        track_update_result "npm & Global Packages" "fail"
        return 1
    fi

    # Final check for any remaining outdated packages
    npm outdated -g 2>&1 | tee -a "$LOG_FILE" || log_info "All global packages are now up to date"
}

update_claude_cli() {
    log_section "6. Updating Claude CLI"

    if [[ "$SKIP_NPM" == true ]]; then
        log_skip "Skipping Claude CLI (--skip-npm enabled)"
        track_update_result "Claude CLI" "skip"
        return 0
    fi

    if ! software_exists "claude"; then
        log_skip "Claude CLI not installed"
        log_info "To install: npm install -g @anthropic-ai/claude-code"
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

    local current_version=$(claude --version 2>&1 | head -1 || echo 'unknown')
    log_info "Current Claude CLI version: $current_version"

    log_info "Updating Claude CLI..."
    if npm update -g @anthropic-ai/claude-code 2>&1 | tee -a "$LOG_FILE"; then
        local new_version=$(claude --version 2>&1 | head -1 || echo 'unknown')

        if [[ "$current_version" == "$new_version" ]] && [[ "$FORCE_UPDATE" != true ]]; then
            log_info "Claude CLI already at latest version"
            track_update_result "Claude CLI" "latest"
        else
            log_success "Claude CLI updated"
            log_info "New version: $new_version"
            track_update_result "Claude CLI" "success"
        fi
    else
        log_error "Claude CLI update failed"
        track_update_result "Claude CLI" "fail"
        return 1
    fi
}

update_gemini_cli() {
    log_section "7. Updating Gemini CLI"

    if [[ "$SKIP_NPM" == true ]]; then
        log_skip "Skipping Gemini CLI (--skip-npm enabled)"
        track_update_result "Gemini CLI" "skip"
        return 0
    fi

    if ! software_exists "gemini" && ! software_exists "gemini-cli"; then
        log_skip "Gemini CLI not installed"
        log_info "To install: npm install -g @google/gemini-cli"
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

    local gemini_cmd=$(command -v gemini || command -v gemini-cli)
    log_info "Found Gemini CLI at: $gemini_cmd"

    # Get current version
    local current_version=$(npm list -g @google/gemini-cli --depth=0 2>/dev/null | grep @google/gemini-cli | sed 's/.*@//' || echo 'unknown')
    log_info "Current Gemini CLI version: $current_version"

    # Update Gemini CLI
    log_info "Updating Gemini CLI via npm..."
    if npm update -g @google/gemini-cli 2>&1 | tee -a "$LOG_FILE"; then
        local new_version=$(npm list -g @google/gemini-cli --depth=0 2>/dev/null | grep @google/gemini-cli | sed 's/.*@//' || echo 'unknown')

        if [[ "$current_version" == "$new_version" ]] && [[ "$FORCE_UPDATE" != true ]]; then
            log_info "Gemini CLI already at latest version"
            track_update_result "Gemini CLI" "latest"
        else
            log_success "Gemini CLI updated"
            log_info "New version: $new_version"
            track_update_result "Gemini CLI" "success"
        fi
    else
        log_error "Gemini CLI update failed"
        track_update_result "Gemini CLI" "fail"
        return 1
    fi
}

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

    # Check if Copilot is installed (either as npm package or gh extension)
    local copilot_npm_installed=false
    local copilot_gh_installed=false

    # Check npm installation
    if npm list -g @github/copilot &>/dev/null; then
        copilot_npm_installed=true
    fi

    # Check gh extension installation
    if software_exists "gh" && gh extension list 2>/dev/null | grep -q "github/gh-copilot"; then
        copilot_gh_installed=true
    fi

    if [[ "$copilot_npm_installed" == false ]] && [[ "$copilot_gh_installed" == false ]]; then
        log_skip "GitHub Copilot CLI not installed"
        log_info "To install (npm): npm install -g @github/copilot"
        log_info "To install (gh): gh extension install github/gh-copilot"
        log_info "Note: gh extension method was deprecated in Sept 2024"
        track_update_result "Copilot CLI" "skip"
        return 0
    fi

    if [[ "$copilot_npm_installed" == true ]]; then
        log_info "Found GitHub Copilot CLI installed via npm"
    else
        log_info "Found GitHub Copilot CLI installed as gh extension"
    fi

    # Handle updates based on installation method
    if [[ "$copilot_npm_installed" == true ]]; then
        # Get current version
        local current_version=$(npm list -g @github/copilot --depth=0 2>/dev/null | grep @github/copilot | sed 's/.*@//' || echo 'unknown')
        log_info "Current Copilot version: $current_version"

        log_info "Updating GitHub Copilot CLI via npm..."
        if npm update -g @github/copilot 2>&1 | tee -a "$LOG_FILE"; then
            local new_version=$(npm list -g @github/copilot --depth=0 2>/dev/null | grep @github/copilot | sed 's/.*@//' || echo 'unknown')

            if [[ "$current_version" == "$new_version" ]] && [[ "$FORCE_UPDATE" != true ]]; then
                log_info "Copilot CLI already at latest version"
                track_update_result "Copilot CLI" "latest"
            else
                log_success "Copilot CLI updated"
                log_info "New version: $new_version"
                track_update_result "Copilot CLI" "success"
            fi
        else
            log_error "Copilot CLI update failed"
            track_update_result "Copilot CLI" "fail"
            return 1
        fi
    elif [[ "$copilot_gh_installed" == true ]]; then
        log_info "Checking for Copilot gh extension updates..."
        if gh extension upgrade github/gh-copilot 2>&1 | tee -a "$LOG_FILE"; then
            log_success "Copilot CLI extension update check completed"
            track_update_result "Copilot CLI" "latest"
        else
            log_warning "Copilot CLI extension update check completed with warnings"
            track_update_result "Copilot CLI" "latest"
        fi
    fi
}

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

    local current_version=$(uv --version 2>&1 || echo 'unknown')
    log_info "Current uv version: $current_version"

    log_info "Updating uv via self-update..."
    if uv self update 2>&1 | tee -a "$LOG_FILE"; then
        local new_version=$(uv --version 2>&1 || echo 'unknown')

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

    # Check if spec-kit is installed
    if ! uv tool list 2>/dev/null | grep -q "^specify-cli"; then
        log_skip "spec-kit not installed via uv"
        log_info "To install: uv tool install specify-cli"
        track_update_result "spec-kit" "skip"
        return 0
    fi

    log_info "Found spec-kit installed"

    # Get current version
    local current_version=$(specify --version 2>/dev/null | awk '{print $NF}' || echo 'unknown')
    log_info "Current spec-kit version: $current_version"

    log_info "Updating spec-kit via uv tool upgrade..."
    if uv tool upgrade specify-cli 2>&1 | tee -a "$LOG_FILE"; then
        local new_version=$(specify --version 2>/dev/null | awk '{print $NF}' || echo 'unknown')

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

    # Get list of installed tools (skip lines starting with '-' which are executables)
    local tools=$(uv tool list 2>/dev/null | awk '/^[a-zA-Z]/ {print $1}' || echo "")

    if [[ -z "$tools" ]]; then
        log_info "No additional uv tools installed"
        track_update_result "Additional uv Tools" "skip"
        return 0
    fi

    log_info "Found uv tools:"
    echo "$tools" | tee -a "$LOG_FILE"

    # Update each tool (skip spec-kit as it's already updated)
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

    # Check if Ghostty is installed via Snap
    if ! snap list ghostty &>/dev/null; then
        log_skip "Ghostty not installed via Snap"
        track_update_result "Ghostty Terminal" "skip"
        return 0
    fi

    # Get current Ghostty version from Snap
    local current_version
    current_version=$(snap list ghostty 2>/dev/null | awk 'NR==2 {print $2}' || echo "unknown")
    log_info "Current Ghostty version (Snap): $current_version"

    # Get latest available version from Snap store
    local latest_version
    latest_version=$(snap info ghostty 2>/dev/null | grep "^latest/stable:" | awk '{print $2}' || echo "unknown")
    log_info "Latest Ghostty version (Snap): $latest_version"

    # Compare versions
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

    log_info "Ghostty update available: $current_version → $latest_version"
    log_info "Updating Ghostty via Snap..."

    # Update Ghostty using snap refresh
    if sudo snap refresh ghostty 2>&1 | tee -a "$LOG_FILE"; then
        local new_version
        new_version=$(snap list ghostty 2>/dev/null | awk 'NR==2 {print $2}' || echo "unknown")
        log_success "Ghostty updated successfully: $current_version → $new_version"
        track_update_result "Ghostty Terminal" "success"
        return 0
    else
        log_error "Failed to update Ghostty via Snap"
        track_update_result "Ghostty Terminal" "fail"
        return 1
    fi
}

# ============================================================================
# Summary Generation
# ============================================================================

print_update_summary() {
    echo ""
    echo "======================================"
    echo "Update Summary"
    echo "======================================"
    echo "✅ Successful: ${#SUCCESSFUL_UPDATES[@]}"
    echo "🔄 Already Latest: ${#ALREADY_LATEST[@]}"
    echo "⏭️  Skipped: ${#SKIPPED_UPDATES[@]}"
    echo "❌ Failed: ${#FAILED_UPDATES[@]}"
    echo ""

    if [[ ${#SUCCESSFUL_UPDATES[@]} -gt 0 ]]; then
        echo "Successful updates:"
        printf '  ✅ %s\n' "${SUCCESSFUL_UPDATES[@]}"
        echo ""
    fi

    if [[ ${#ALREADY_LATEST[@]} -gt 0 ]]; then
        echo "Already at latest version:"
        printf '  🔄 %s\n' "${ALREADY_LATEST[@]}"
        echo ""
    fi

    if [[ ${#SKIPPED_UPDATES[@]} -gt 0 ]]; then
        echo "Skipped (not installed):"
        printf '  ⏭️  %s\n' "${SKIPPED_UPDATES[@]}"
        echo ""
    fi

    if [[ ${#FAILED_UPDATES[@]} -gt 0 ]]; then
        echo "Failed updates:"
        printf '  ❌ %s\n' "${FAILED_UPDATES[@]}"
        echo ""
    fi
}

generate_summary() {
    log_section "Update Summary"

    local end_time=$(date +"%Y-%m-%d %H:%M:%S")
    local duration=$SECONDS

    cat > "$SUMMARY_FILE" <<EOF
=============================================================================
Daily Update Summary - $end_time
=============================================================================
Duration: ${duration}s

Log Files:
- Full log: $LOG_FILE
- Error log: $ERROR_LOG
- Latest: $LATEST_LOG_LINK

Update Statistics:
- ✅ Successful: ${#SUCCESSFUL_UPDATES[@]}
- 🔄 Already Latest: ${#ALREADY_LATEST[@]}
- ⏭️  Skipped: ${#SKIPPED_UPDATES[@]}
- ❌ Failed: ${#FAILED_UPDATES[@]}

EOF

    # Add successful updates
    if [[ ${#SUCCESSFUL_UPDATES[@]} -gt 0 ]]; then
        echo "Successful Updates:" >> "$SUMMARY_FILE"
        printf '  ✅ %s\n' "${SUCCESSFUL_UPDATES[@]}" >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"
    fi

    # Add already latest
    if [[ ${#ALREADY_LATEST[@]} -gt 0 ]]; then
        echo "Already at Latest Version:" >> "$SUMMARY_FILE"
        printf '  🔄 %s\n' "${ALREADY_LATEST[@]}" >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"
    fi

    # Add skipped updates
    if [[ ${#SKIPPED_UPDATES[@]} -gt 0 ]]; then
        echo "Skipped (Not Installed):" >> "$SUMMARY_FILE"
        printf '  ⏭️  %s\n' "${SKIPPED_UPDATES[@]}" >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"
    fi

    # Add failed updates
    if [[ ${#FAILED_UPDATES[@]} -gt 0 ]]; then
        echo "Failed Updates:" >> "$SUMMARY_FILE"
        printf '  ❌ %s\n' "${FAILED_UPDATES[@]}" >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"
    fi

    echo "==============================================================================" >> "$SUMMARY_FILE"

    # Display summary to console and log
    print_update_summary | tee -a "$LOG_FILE"

    # Display summary file
    cat "$SUMMARY_FILE" | tee -a "$LOG_FILE"

    # Create symlink to latest log
    ln -sf "$LOG_FILE" "$LATEST_LOG_LINK"

    log_info "View full log: cat $LOG_FILE"
    log_info "View latest: cat $LATEST_LOG_LINK"
    log_info "View summary: cat $SUMMARY_FILE"
}

# ============================================================================
# Argument Parsing
# ============================================================================

show_help() {
    cat << EOF
Daily System Updates Script - Enhanced Version 2.1

Usage: $(basename "$0") [OPTIONS]

FEATURES:
  - Automatic version detection for all installed tools
  - Modular uninstall → reinstall workflow for major updates
  - Graceful error handling (continues on failure)
  - Comprehensive logging and summary reports

OPTIONS:
  --dry-run           Show what would be updated without actually updating
  --skip-apt          Skip apt-based updates (GitHub CLI, system packages)
  --skip-node         Skip Node.js/fnm updates
  --skip-npm          Skip npm and npm-based packages
  --only-security     Only apply security updates for apt packages
  --force             Force updates even if already at latest version
  -h, --help          Show this help message

COMPONENTS UPDATED:
  1. GitHub CLI (gh) - via apt
  2. System packages - via apt with autoremove
  3. Oh My Zsh - native updater
  4. fnm & Node.js - latest version (constitutional requirement)
  5. npm & global packages - bulk update
  6. Claude CLI - via npm
  7. Gemini CLI - via npm
  8. Copilot CLI - via npm or gh extension
  9. uv (Python package manager) - self-update
  10. spec-kit - via uv tool upgrade
  11. Additional uv tools - bulk upgrade
  12. Zig Compiler - modular uninstall/reinstall (NEW)
  13. Ghostty Terminal - modular uninstall/reinstall (NEW)

EXAMPLES:
  $(basename "$0")                  # Normal run - update everything
  $(basename "$0") --dry-run        # Preview what would be updated
  $(basename "$0") --skip-node      # Skip Node.js updates
  $(basename "$0") --force          # Force all updates

EXIT CODES:
  0 - At least one update succeeded
  1 - All updates failed or were skipped

LOG LOCATIONS:
  Full log: $LOG_DIR/update-TIMESTAMP.log
  Errors:   $LOG_DIR/errors-TIMESTAMP.log
  Summary:  $LOG_DIR/last-update-summary.txt
  Latest:   $LOG_DIR/latest.log (symlink)

NOTES:
  - Ghostty/Zig updates use modular uninstall → reinstall workflow
  - Configuration files are preserved during reinstallation
  - All changes are logged to $LOG_DIR for troubleshooting

EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                log_info "DRY RUN mode enabled - no actual updates will be performed"
                shift
                ;;
            --skip-apt)
                SKIP_APT=true
                log_info "Skipping apt-based updates"
                shift
                ;;
            --skip-node)
                SKIP_NODE=true
                log_info "Skipping Node.js/fnm updates"
                shift
                ;;
            --skip-npm)
                SKIP_NPM=true
                log_info "Skipping npm-based updates"
                shift
                ;;
            --only-security)
                ONLY_SECURITY=true
                log_info "Only applying security updates for apt packages"
                shift
                ;;
            --force)
                FORCE_UPDATE=true
                log_info "Force update mode enabled"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    local start_time=$(date +"%Y-%m-%d %H:%M:%S")

    # Parse command-line arguments
    parse_arguments "$@"

    log_section "Daily System Updates - $start_time"
    log_info "Log file: $LOG_FILE"
    log_info "Error log: $ERROR_LOG"

    if [[ "$DRY_RUN" == true ]]; then
        log_warning "DRY RUN MODE - No actual changes will be made"
    fi

    # Run updates (continue on error for each section - graceful degradation)
    # Each function handles its own errors and tracks results
    update_github_cli || true
    update_system_packages || true
    update_oh_my_zsh || true
    update_fnm || true
    update_npm_packages || true
    update_claude_cli || true
    update_gemini_cli || true
    update_copilot_cli || true
    update_uv || true
    update_spec_kit || true
    update_all_uv_tools || true
    update_ghostty || true

    # Generate summary
    generate_summary

    # Determine exit code based on results
    # Exit 0 if at least one update succeeded or is already latest
    # Exit 1 only if ALL updates failed or were skipped
    local total_good=$((${#SUCCESSFUL_UPDATES[@]} + ${#ALREADY_LATEST[@]}))
    local total_bad=$((${#FAILED_UPDATES[@]}))

    if [[ $total_good -gt 0 ]]; then
        log_success "Update run completed with $total_good successful/latest components"
        exit 0
    elif [[ $total_bad -gt 0 ]]; then
        log_error "All updates failed. Check logs for details."
        exit 1
    else
        log_info "No updates were needed or all components were skipped"
        exit 0
    fi
}

# Run main function
main "$@"
