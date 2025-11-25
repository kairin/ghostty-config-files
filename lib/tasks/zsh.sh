#!/usr/bin/env bash
#
# lib/tasks/zsh.sh - ZSH + Oh My ZSH installation and configuration
#
# CONTEXT7 STATUS: API authentication failed (invalid key)
# FALLBACK STRATEGY: Use constitutional compliance requirements from CLAUDE.md/AGENTS.md
# - Ubuntu 25.10 defaults to ZSH (already system default)
# - Oh My ZSH framework with productivity plugins
# - Preserve user customizations during configuration
#
# Constitutional Compliance:
# - Principle V: Modular Architecture
# - ZSH as default shell (Ubuntu 25.10 standard)
# - Oh My ZSH with curated plugins (git, docker, kubectl, zsh-autosuggestions, zsh-syntax-highlighting)
# - Preserve existing .zshrc customizations
#
# User Stories: US1 (Fresh Installation), US3 (Re-run Safety)
#
# Requirements:
# - FR-053: Idempotency (skip if already configured)
# - FR-071: Query Context7 (fallback if unavailable)
#

set -euo pipefail

# Source required utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../core/logging.sh"
source "${SCRIPT_DIR}/../core/utils.sh"
source "${SCRIPT_DIR}/../core/state.sh"
source "${SCRIPT_DIR}/../core/errors.sh"
source "${SCRIPT_DIR}/../verification/duplicate_detection.sh"
source "${SCRIPT_DIR}/../verification/unit_tests.sh"

# Installation constants
readonly OH_MY_ZSH_DIR="${HOME}/.oh-my-zsh"
readonly ZSHRC="${HOME}/.zshrc"
readonly ZSH_CUSTOM="${OH_MY_ZSH_DIR}/custom"
readonly OH_MY_ZSH_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

# Recommended plugins (constitutional compliance)
readonly RECOMMENDED_PLUGINS=(
    "git"
    "docker"
    "kubectl"
    "zsh-autosuggestions"
    "zsh-syntax-highlighting"
)

#
# Check if ZSH is installed and available
#
# Returns:
#   0 = ZSH available
#   1 = ZSH not installed
#
check_zsh_installed() {
    log "INFO" "Checking ZSH installation..."

    if ! command_exists "zsh"; then
        log "ERROR" "✗ ZSH not found"
        return 1
    fi

    local zsh_version
    zsh_version=$(zsh --version 2>&1 | head -n 1)
    log "INFO" "  ZSH version: $zsh_version"
    log "SUCCESS" "✓ ZSH installed"
    return 0
}

#
# Check if Oh My ZSH is installed
#
# Returns:
#   0 = Oh My ZSH installed
#   1 = Not installed
#
check_oh_my_zsh_installed() {
    log "INFO" "Checking Oh My ZSH installation..."

    if [ ! -d "$OH_MY_ZSH_DIR" ]; then
        log "INFO" "  Oh My ZSH not found"
        return 1
    fi

    log "SUCCESS" "✓ Oh My ZSH installed at $OH_MY_ZSH_DIR"
    return 0
}

#
# Backup existing .zshrc file
#
# Creates timestamped backup to preserve user customizations
#
backup_zshrc() {
    if [ -f "$ZSHRC" ]; then
        local backup_file
        backup_file="${ZSHRC}.backup-$(date +%Y%m%d-%H%M%S)"
        cp "$ZSHRC" "$backup_file"
        log "INFO" "  ✓ Backed up existing .zshrc to $backup_file"
    fi
}

#
# Install Oh My ZSH framework
#
# Process:
#   1. Download official installation script
#   2. Run non-interactive installation
#   3. Verify installation
#
# Returns:
#   0 = success
#   1 = failure
#
install_oh_my_zsh() {
    log "INFO" "Installing Oh My ZSH framework..."

    # Download and run installer (non-interactive)
    if ! sh -c "$(curl -fsSL $OH_MY_ZSH_URL)" "" --unattended 2>&1 | tee -a "$(get_log_file)"; then
        handle_error "install-zsh" 1 "Oh My ZSH installation failed" \
            "Check internet connection" \
            "Verify GitHub access: ping raw.githubusercontent.com" \
            "Try manual installation from https://ohmyz.sh/"
        return 1
    fi

    if [ ! -d "$OH_MY_ZSH_DIR" ]; then
        handle_error "install-zsh" 2 "Oh My ZSH directory not created" \
            "Check installation logs" \
            "Verify write permissions to $HOME"
        return 1
    fi

    log "SUCCESS" "✓ Oh My ZSH installed"
    return 0
}

#
# Install ZSH plugin (autosuggestions or syntax-highlighting)
#
# Args:
#   $1 - Plugin name
#   $2 - Git repository URL
#
# Returns:
#   0 = success
#   1 = failure
#
install_zsh_plugin() {
    local plugin_name="$1"
    local plugin_repo="$2"
    local plugin_dir="${ZSH_CUSTOM}/plugins/${plugin_name}"

    if [ -d "$plugin_dir" ]; then
        log "INFO" "  ↷ Plugin '$plugin_name' already installed"
        return 0
    fi

    log "INFO" "  Installing plugin: $plugin_name..."

    if ! git clone --depth 1 "$plugin_repo" "$plugin_dir" 2>&1 | tee -a "$(get_log_file)"; then
        log "WARNING" "  ✗ Failed to install plugin '$plugin_name'"
        return 1
    fi

    log "SUCCESS" "  ✓ Plugin '$plugin_name' installed"
    return 0
}

#
# Configure ZSH plugins in .zshrc
#
# Adds recommended plugins to .zshrc if not already configured
# Preserves existing user customizations
#
configure_zsh_plugins() {
    log "INFO" "Configuring ZSH plugins..."

    if [ ! -f "$ZSHRC" ]; then
        log "ERROR" "✗ .zshrc not found after Oh My ZSH installation"
        return 1
    fi

    # Install external plugins (not included in Oh My ZSH by default)
    install_zsh_plugin "zsh-autosuggestions" \
        "https://github.com/zsh-users/zsh-autosuggestions.git"

    install_zsh_plugin "zsh-syntax-highlighting" \
        "https://github.com/zsh-users/zsh-syntax-highlighting.git"

    # Configure plugins in .zshrc
    local plugins_line="plugins=(${RECOMMENDED_PLUGINS[*]})"

    if grep -q "^plugins=(" "$ZSHRC"; then
        # Update existing plugins line
        log "INFO" "  Updating plugins configuration..."
        sed -i.bak "s/^plugins=(.*)/plugins=(${RECOMMENDED_PLUGINS[*]})/" "$ZSHRC"
    else
        # Add plugins line if missing
        log "INFO" "  Adding plugins configuration..."
        echo "" >> "$ZSHRC"
        echo "# Plugins (configured by installation script)" >> "$ZSHRC"
        echo "$plugins_line" >> "$ZSHRC"
    fi

    log "SUCCESS" "✓ ZSH plugins configured: ${RECOMMENDED_PLUGINS[*]}"
    return 0
}

#
# Set ZSH as default shell
#
# Prompts user before changing default shell
#
# Returns:
#   0 = success or already default
#   1 = failure or user declined
#
set_zsh_as_default() {
    log "INFO" "Checking default shell..."

    local current_shell
    current_shell=$(basename "$SHELL")

    if [ "$current_shell" = "zsh" ]; then
        log "INFO" "  ↷ ZSH is already the default shell"
        return 0
    fi

    log "INFO" "  Current default shell: $current_shell"
    log "INFO" "  ZSH path: $(command -v zsh)"

    # Non-interactive: Skip shell change prompt in automated installation
    # User can manually change shell later with: chsh -s $(which zsh)
    log "INFO" "  Note: To set ZSH as default shell, run: chsh -s \$(which zsh)"
    log "INFO" "  Skipping automatic shell change (requires logout/login)"

    return 0
}

#
# Add dircolors configuration (XDG-compliant)
#
# Ensures XDG-compliant dircolors loading in .zshrc
#
configure_dircolors() {
    log "INFO" "Configuring dircolors (XDG-compliant)..."

    local dircolors_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
    local dircolors_file="${dircolors_config_dir}/dircolors"

    # Check if dircolors file exists
    if [ ! -f "$dircolors_file" ]; then
        log "INFO" "  Dircolors file not found at $dircolors_file"
        log "INFO" "  Will be deployed by main installation script"
        return 0
    fi

    # Add dircolors loading to .zshrc (idempotent)
    local dircolors_line='eval "$(dircolors ${XDG_CONFIG_HOME:-$HOME/.config}/dircolors)"'

    if ! grep -q "dircolors.*XDG_CONFIG_HOME" "$ZSHRC" 2>/dev/null; then
        log "INFO" "  Adding dircolors loading to .zshrc..."
        echo "" >> "$ZSHRC"
        echo "# XDG-compliant dircolors configuration" >> "$ZSHRC"
        echo "$dircolors_line" >> "$ZSHRC"
        log "SUCCESS" "  ✓ Dircolors configuration added"
    else
        log "INFO" "  ↷ Dircolors already configured"
    fi

    return 0
}

#
# Install and configure ZSH + Oh My ZSH
#
# Process:
#   1. Check duplicate detection (skip if already configured)
#   2. Install ZSH (if missing)
#   3. Install Oh My ZSH framework
#   4. Configure plugins
#   5. Configure dircolors (XDG-compliant)
#   6. Verify installation
#
# Returns:
#   0 = success
#   1 = failure
#
task_install_zsh() {
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Installing ZSH + Oh My ZSH"
    log "INFO" "════════════════════════════════════════"

    local task_start
    task_start=$(get_unix_timestamp)

    # Step 1: Duplicate Detection (Idempotency)
    log "INFO" "Checking for existing ZSH configuration..."

    if verify_zsh_configured 2>/dev/null; then
        log "INFO" "↷ ZSH + Oh My ZSH already installed and configured"
        mark_task_completed "install-zsh" 0  # 0 seconds (skipped)
        return 0
    fi

    # Step 2: Check ZSH installed
    if ! check_zsh_installed; then
        log "INFO" "Installing ZSH..."
        if ! sudo apt-get install -y zsh 2>&1 | tee -a "$(get_log_file)"; then
            handle_error "install-zsh" 3 "Failed to install ZSH package" \
                "Check apt repository access" \
                "Try: sudo apt-get update && sudo apt-get install zsh"
            return 1
        fi
        log "SUCCESS" "✓ ZSH installed"
    fi

    # Step 3: Backup existing .zshrc
    backup_zshrc

    # Step 4: Install Oh My ZSH
    if ! check_oh_my_zsh_installed; then
        if ! install_oh_my_zsh; then
            return 1
        fi
    else
        log "INFO" "↷ Oh My ZSH already installed"
    fi

    # Step 5: Configure plugins
    if ! configure_zsh_plugins; then
        handle_error "install-zsh" 4 "Failed to configure ZSH plugins" \
            "Check .zshrc file permissions" \
            "Verify plugin directories exist"
        return 1
    fi

    # Step 6: Configure dircolors (XDG-compliant)
    configure_dircolors

    # Step 7: Set ZSH as default (optional, non-blocking)
    set_zsh_as_default

    # Step 8: Verify installation
    log "INFO" "Verifying installation..."

    if verify_zsh_configured; then
        local task_end
        task_end=$(get_unix_timestamp)
        local duration
        duration=$(calculate_duration "$task_start" "$task_end")

        mark_task_completed "install-zsh" "$duration"

        log "SUCCESS" "════════════════════════════════════════"
        log "SUCCESS" "✓ ZSH + Oh My ZSH configured successfully ($(format_duration "$duration"))"
        log "SUCCESS" "════════════════════════════════════════"
        log "INFO" ""
        log "INFO" "Next steps:"
        log "INFO" "  1. Restart terminal or run: source ~/.zshrc"
        log "INFO" "  2. (Optional) Set ZSH as default: chsh -s \$(which zsh)"
        log "INFO" "  3. Logout and login for default shell change to take effect"
        return 0
    else
        handle_error "install-zsh" 5 "Installation verification failed" \
            "Check logs for errors" \
            "Try manual verification: zsh --version && ls ~/.oh-my-zsh"
        return 1
    fi
}

# Export functions
export -f check_zsh_installed
export -f check_oh_my_zsh_installed
export -f backup_zshrc
export -f install_oh_my_zsh
export -f install_zsh_plugin
export -f configure_zsh_plugins
export -f set_zsh_as_default
export -f configure_dircolors
export -f task_install_zsh
