#!/bin/bash
#
# Daily System Updates Script
# Automatically updates system packages, dev tools, and AI assistants
# Logs all output for troubleshooting
#
# Author: Auto-generated for ghostty-config-files
# Last Modified: 2025-11-12

set -euo pipefail

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

# ============================================================================
# Update Functions
# ============================================================================

update_github_cli() {
    log_section "1. Updating GitHub CLI (gh)"

    log_info "Current gh version: $(gh --version | head -1)"

    if sudo -n apt update 2>&1 | tee -a "$LOG_FILE"; then
        log_success "apt update completed"
    else
        log_error "apt update failed (may require password for manual run)"
        return 1
    fi

    if sudo -n apt upgrade -y gh 2>&1 | tee -a "$LOG_FILE"; then
        log_success "GitHub CLI updated"
        log_info "New gh version: $(gh --version | head -1)"
    else
        log_error "GitHub CLI update failed"
        return 1
    fi
}

update_system_packages() {
    log_section "2. Updating System Packages"

    log_info "Running full system update..."

    if sudo -n apt update 2>&1 | tee -a "$LOG_FILE"; then
        log_success "apt update completed"
    else
        log_error "apt update failed (may require password for manual run)"
        return 1
    fi

    # Count upgradable packages
    local upgradable=$(apt list --upgradable 2>/dev/null | grep -c upgradable || true)
    log_info "Packages to upgrade: $upgradable"

    if sudo -n apt upgrade -y 2>&1 | tee -a "$LOG_FILE"; then
        log_success "System packages upgraded"
    else
        log_error "System package upgrade failed"
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

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Updating Oh My Zsh..."

        # Oh My Zsh update (disable auto-update prompts)
        ZSH="$HOME/.oh-my-zsh" DISABLE_UPDATE_PROMPT=true \
            bash "$HOME/.oh-my-zsh/tools/upgrade.sh" 2>&1 | tee -a "$LOG_FILE" || {
            log_warning "Oh My Zsh update may have been skipped (already up to date)"
        }

        log_success "Oh My Zsh update completed"
    else
        log_warning "Oh My Zsh not found at $HOME/.oh-my-zsh"
    fi
}

update_npm_packages() {
    log_section "4. Updating npm and Global Packages"

    if command -v npm &>/dev/null; then
        log_info "Current npm version: $(npm --version)"
        log_info "Current Node.js version: $(node --version)"

        # Update npm itself
        log_info "Updating npm..."
        if npm install -g npm@latest 2>&1 | tee -a "$LOG_FILE"; then
            log_success "npm updated to $(npm --version)"
        else
            log_error "npm update failed"
            return 1
        fi

        # List globally installed packages
        log_info "Globally installed packages:"
        npm list -g --depth=0 2>&1 | tee -a "$LOG_FILE"

        # Update all global packages
        log_info "Updating all global npm packages..."
        if npm update -g 2>&1 | tee -a "$LOG_FILE"; then
            log_success "Global npm packages updated"
        else
            log_error "Global npm package update failed"
            return 1
        fi

        # Check for outdated packages
        log_info "Checking for outdated global packages..."
        npm outdated -g 2>&1 | tee -a "$LOG_FILE" || log_info "All global packages are up to date"

    else
        log_warning "npm not found - skipping npm updates"
    fi
}

update_claude_cli() {
    log_section "5. Updating Claude CLI"

    if command -v claude &>/dev/null; then
        log_info "Current Claude CLI version: $(claude --version 2>&1 || echo 'unknown')"

        log_info "Updating Claude CLI..."
        if npm update -g @anthropic-ai/claude-code 2>&1 | tee -a "$LOG_FILE"; then
            log_success "Claude CLI updated"
            log_info "New version: $(claude --version 2>&1 || echo 'unknown')"
        else
            log_error "Claude CLI update failed"
            return 1
        fi
    else
        log_warning "Claude CLI not found - skipping update"
        log_info "To install: npm install -g @anthropic-ai/claude-code"
    fi
}

update_gemini_cli() {
    log_section "6. Updating Gemini CLI"

    if command -v gemini &>/dev/null || command -v gemini-cli &>/dev/null; then
        local gemini_cmd=$(command -v gemini || command -v gemini-cli)
        log_info "Found Gemini CLI at: $gemini_cmd"

        # Get current version
        local current_version=$(npm list -g @google/gemini-cli --depth=0 2>/dev/null | grep @google/gemini-cli | sed 's/.*@//' || echo 'unknown')
        log_info "Current Gemini CLI version: $current_version"

        # Update Gemini CLI
        log_info "Updating Gemini CLI via npm..."
        if npm update -g @google/gemini-cli 2>&1 | tee -a "$LOG_FILE"; then
            log_success "Gemini CLI updated"
            local new_version=$(npm list -g @google/gemini-cli --depth=0 2>/dev/null | grep @google/gemini-cli | sed 's/.*@//' || echo 'unknown')
            log_info "New version: $new_version"
        else
            log_error "Gemini CLI update failed"
            return 1
        fi
    else
        log_warning "Gemini CLI not found - skipping update"
        log_info "To install: npm install -g @google/gemini-cli"
    fi
}

update_copilot_cli() {
    log_section "7. Updating Copilot CLI"

    # Check if @github/copilot is installed via npm
    if npm list -g @github/copilot &>/dev/null; then
        log_info "Found GitHub Copilot CLI installed"

        # Get current version
        local current_version=$(npm list -g @github/copilot --depth=0 2>/dev/null | grep @github/copilot | sed 's/.*@//' || echo 'unknown')
        log_info "Current Copilot version: $current_version"

        log_info "Updating GitHub Copilot CLI..."
        if npm update -g @github/copilot 2>&1 | tee -a "$LOG_FILE"; then
            log_success "Copilot CLI updated"
            local new_version=$(npm list -g @github/copilot --depth=0 2>/dev/null | grep @github/copilot | sed 's/.*@//' || echo 'unknown')
            log_info "New version: $new_version"
        else
            log_error "Copilot CLI update failed"
            return 1
        fi
    else
        log_warning "GitHub Copilot CLI not found"
        log_info "To install: npm install -g @github/copilot"
        log_info "Note: gh copilot extension was deprecated in Sept 2025"
    fi
}

# ============================================================================
# Summary Generation
# ============================================================================

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

Updates Completed:
EOF

    # Check each component
    if grep -q "✅.*GitHub CLI" "$LOG_FILE"; then
        echo "✅ GitHub CLI (gh) - Updated" >> "$SUMMARY_FILE"
    else
        echo "❌ GitHub CLI (gh) - Failed or Skipped" >> "$SUMMARY_FILE"
    fi

    if grep -q "✅.*System packages" "$LOG_FILE"; then
        echo "✅ System Packages - Updated" >> "$SUMMARY_FILE"
    else
        echo "❌ System Packages - Failed or Skipped" >> "$SUMMARY_FILE"
    fi

    if grep -q "✅.*Oh My Zsh" "$LOG_FILE"; then
        echo "✅ Oh My Zsh - Updated" >> "$SUMMARY_FILE"
    else
        echo "⚠️  Oh My Zsh - Failed or Skipped" >> "$SUMMARY_FILE"
    fi

    if grep -q "✅.*npm packages" "$LOG_FILE"; then
        echo "✅ npm & Global Packages - Updated" >> "$SUMMARY_FILE"
    else
        echo "❌ npm & Global Packages - Failed or Skipped" >> "$SUMMARY_FILE"
    fi

    if grep -q "✅.*Claude CLI" "$LOG_FILE"; then
        echo "✅ Claude CLI - Updated" >> "$SUMMARY_FILE"
    else
        echo "⚠️  Claude CLI - Failed or Skipped" >> "$SUMMARY_FILE"
    fi

    if grep -q "✅.*Gemini CLI" "$LOG_FILE"; then
        echo "✅ Gemini CLI - Updated" >> "$SUMMARY_FILE"
    else
        echo "⚠️  Gemini CLI - Failed or Skipped" >> "$SUMMARY_FILE"
    fi

    if grep -q "✅.*Copilot CLI" "$LOG_FILE"; then
        echo "✅ Copilot CLI - Updated" >> "$SUMMARY_FILE"
    else
        echo "⚠️  Copilot CLI - Failed or Skipped" >> "$SUMMARY_FILE"
    fi

    echo "" >> "$SUMMARY_FILE"
    echo "==============================================================================" >> "$SUMMARY_FILE"

    # Display summary
    cat "$SUMMARY_FILE" | tee -a "$LOG_FILE"

    # Create symlink to latest log
    ln -sf "$LOG_FILE" "$LATEST_LOG_LINK"

    log_info "View full log: cat $LOG_FILE"
    log_info "View latest: cat $LATEST_LOG_LINK"
    log_info "View summary: cat $SUMMARY_FILE"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    local start_time=$(date +"%Y-%m-%d %H:%M:%S")

    log_section "Daily System Updates - $start_time"
    log_info "Log file: $LOG_FILE"
    log_info "Error log: $ERROR_LOG"

    # Track overall success
    local overall_success=true

    # Run updates (continue on error for each section)
    update_github_cli || overall_success=false
    update_system_packages || overall_success=false
    update_oh_my_zsh || overall_success=false
    update_npm_packages || overall_success=false
    update_claude_cli || overall_success=false
    update_gemini_cli || overall_success=false
    update_copilot_cli || overall_success=false

    # Generate summary
    generate_summary

    if [[ "$overall_success" == true ]]; then
        log_success "All updates completed successfully!"
        exit 0
    else
        log_warning "Some updates had issues. Check logs for details."
        exit 1
    fi
}

# Run main function
main "$@"
