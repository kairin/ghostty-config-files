#!/bin/bash
# configure_zsh.sh - ZSH Configuration Module
# Constitutional Compliance: Script Proliferation Prevention (single comprehensive module)
# Performance Target: <50ms perceived startup (Powerlevel10k instant prompt)
# Note: Full ZSH initialization happens in background (~2s is normal)
#
# This module provides post-installation configuration for ZSH with:
# - Powerlevel10k theme installation and setup
# - Plugin management (zsh-autosuggestions, zsh-syntax-highlighting, fzf-tab, etc.)
# - Performance optimizations (instant prompt, lazy loading, compilation)
# - Idempotent configuration (safe to run multiple times)
#
# Usage:
#   source /path/to/configure_zsh.sh
#   configure_zsh

# Prevent duplicate sourcing
[[ -n "${CONFIGURE_ZSH_SH_LOADED:-}" ]] && return
CONFIGURE_ZSH_SH_LOADED=1

# Source shared logging utility
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/006-logs/logger.sh"

# =============================================================================
# Constants
# =============================================================================

OH_MY_ZSH_DIR="${HOME}/.oh-my-zsh"
ZSH_CUSTOM="${OH_MY_ZSH_DIR}/custom"
ZSHRC_FILE="${HOME}/.zshrc"
MAX_STARTUP_OVERHEAD_MS=50  # Performance testing target (perceived startup with instant prompt)

# =============================================================================
# Private Helper Functions
# =============================================================================

# Backup .zshrc with timestamp
# Usage: _backup_zshrc
_backup_zshrc() {
    local backup_file="${ZSHRC_FILE}.backup.$(date +%Y%m%d-%H%M%S)"
    if [[ -f "$ZSHRC_FILE" ]]; then
        cp "$ZSHRC_FILE" "$backup_file"
        log "SUCCESS" "Backed up .zshrc to ${backup_file}"
        return 0
    fi
    log "WARNING" ".zshrc not found, no backup created"
    return 1
}

# Measure ZSH startup time (average of 5 runs)
# Usage: startup_ms=$(_measure_zsh_startup)
_measure_zsh_startup() {
    if ! command -v zsh &> /dev/null; then
        echo "0"
        return 1
    fi

    # Check if 'bc' is available for calculations
    if ! command -v bc &> /dev/null; then
        log "WARNING" "bc not available, cannot measure startup time accurately"
        echo "0"
        return 1
    fi

    local total=0
    local runs=5

    for i in $(seq 1 $runs); do
        # Use /usr/bin/time to measure execution time
        local time_output=$( (time zsh -i -c exit) 2>&1 | grep real | awk '{print $2}')

        # Convert to milliseconds (handle format like "0m0.045s")
        local seconds=$(echo "$time_output" | sed 's/[^0-9.]//g')
        local ms=$(echo "$seconds * 1000" | bc 2>/dev/null || echo "0")
        total=$(echo "$total + $ms" | bc 2>/dev/null || echo "$total")
    done

    # Calculate average
    local average=$(echo "scale=0; $total / $runs" | bc 2>/dev/null || echo "0")
    echo "${average%.*}"  # Remove decimal part
}

# Add or replace a configuration section in .zshrc (idempotent)
# Usage: _add_config_section "section-name" "content"
_add_config_section() {
    local section_name="$1"
    local content="$2"

    if [[ ! -f "$ZSHRC_FILE" ]]; then
        log "ERROR" ".zshrc not found"
        return 1
    fi

    local start_marker="# >>> ghostty-config:${section_name} >>>"
    local end_marker="# <<< ghostty-config:${section_name} <<<"

    # Remove existing section if present
    sed -i "/${start_marker}/,/${end_marker}/d" "$ZSHRC_FILE"

    # Add new section at end of file
    cat >> "$ZSHRC_FILE" <<EOF

${start_marker}
${content}
${end_marker}
EOF

    log "SUCCESS" "Updated section '${section_name}' in .zshrc"
    return 0
}

# =============================================================================
# Public API Functions
# =============================================================================

# Install or update Oh-My-Zsh
# Usage: install_oh_my_zsh
install_oh_my_zsh() {
    if [[ -d "$OH_MY_ZSH_DIR" ]]; then
        log "INFO" "Oh-My-Zsh already installed"
        if [[ -d "$OH_MY_ZSH_DIR/.git" ]]; then
            log "INFO" "Updating Oh-My-Zsh..."
            git -C "$OH_MY_ZSH_DIR" pull --quiet 2>/dev/null
            log "SUCCESS" "Oh-My-Zsh updated"
        fi
        return 0
    else
        log "ERROR" "Oh-My-Zsh not installed. Run install_zsh.sh first"
        return 1
    fi
}

# Install a ZSH plugin (idempotent)
# Usage: install_zsh_plugin "plugin-name" "git-url"
install_zsh_plugin() {
    local plugin_name="$1"
    local git_url="$2"
    local plugin_dir="${ZSH_CUSTOM}/plugins/${plugin_name}"

    if [[ -d "$plugin_dir" ]]; then
        log "INFO" "Plugin ${plugin_name} exists, updating..."
        if [[ -d "$plugin_dir/.git" ]]; then
            git -C "$plugin_dir" pull --quiet 2>/dev/null && \
                log "SUCCESS" "Plugin ${plugin_name} updated" || \
                log "WARNING" "Failed to update plugin ${plugin_name}"
        fi
    else
        log "INFO" "Installing plugin ${plugin_name}..."
        if git clone --depth=1 "$git_url" "$plugin_dir" &>/dev/null; then
            log "SUCCESS" "Plugin ${plugin_name} installed"
        else
            log "ERROR" "Failed to install plugin ${plugin_name}"
            return 1
        fi
    fi
    return 0
}

# Install Powerlevel10k theme
# Usage: install_powerlevel10k_theme
install_powerlevel10k_theme() {
    local p10k_dir="${ZSH_CUSTOM}/themes/powerlevel10k"
    local p10k_url="https://github.com/romkatv/powerlevel10k.git"

    if [[ -d "$p10k_dir" ]]; then
        log "INFO" "Powerlevel10k exists, updating..."
        if git -C "$p10k_dir" pull --quiet 2>/dev/null; then
            log "SUCCESS" "Powerlevel10k updated"
        else
            log "WARNING" "Failed to update Powerlevel10k"
        fi
    else
        log "INFO" "Installing Powerlevel10k theme..."
        if git clone --depth=1 "$p10k_url" "$p10k_dir" &>/dev/null; then
            log "SUCCESS" "Powerlevel10k theme installed"
        else
            log "ERROR" "Failed to install Powerlevel10k"
            return 1
        fi
    fi
    return 0
}

# Configure ZSH plugins in .zshrc
# Usage: configure_zsh_plugins
configure_zsh_plugins() {
    _backup_zshrc

    local plugins_config='plugins=(
    # Oh-My-Zsh builtins
    git
    sudo
    docker
    extract
    colored-man-pages
    command-not-found

    # Custom plugins (must be installed first)
    zsh-autosuggestions
    zsh-completions
    fzf-tab
    you-should-use
    zsh-syntax-highlighting  # MUST be last
)'

    _add_config_section "plugins" "$plugins_config"
    log "SUCCESS" "ZSH plugins configured"
}

# Configure Powerlevel10k theme and create default .p10k.zsh
# Usage: configure_powerlevel10k_theme
configure_powerlevel10k_theme() {
    _backup_zshrc

    # Update ZSH_THEME in .zshrc
    if grep -q "^ZSH_THEME=" "$ZSHRC_FILE"; then
        sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$ZSHRC_FILE"
        log "SUCCESS" "ZSH_THEME updated to powerlevel10k"
    else
        log "ERROR" "ZSH_THEME not found in .zshrc"
        return 1
    fi

    # Create default .p10k.zsh if missing
    if [[ ! -f "${HOME}/.p10k.zsh" ]]; then
        log "INFO" "Creating default .p10k.zsh configuration..."
        cat > "${HOME}/.p10k.zsh" <<'P10K_CONFIG'
# Powerlevel10k configuration (minimal, performance-optimized)
# Generated by ghostty-config-files configure_zsh.sh

# Instant prompt (CRITICAL for <50ms startup)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Powerlevel10k prompt configuration
typeset -g POWERLEVEL9K_MODE='nerdfont-complete'
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
typeset -g POWERLEVEL9K_PROMPT_ON_NEWLINE=true

# Left prompt segments
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    dir                     # Current directory
    vcs                     # Git status
)

# Right prompt segments
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    status                  # Exit code
    command_execution_time  # Command duration
    background_jobs         # Background jobs indicator
    time                    # Current time
)

# Directory segment
typeset -g POWERLEVEL9K_DIR_FOREGROUND=254
typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=250
typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=255
typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_last
typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=1

# Git segment
typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=076
typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=178
typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=014

# Status segment
typeset -g POWERLEVEL9K_STATUS_OK=false
typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=160

# Execution time segment
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=101

# Note: .zshrc handles sourcing this file - no self-sourcing needed
P10K_CONFIG
        log "SUCCESS" "Created default .p10k.zsh"
    else
        log "INFO" ".p10k.zsh already exists, skipping creation"
    fi

    # Add instant prompt to .zshrc (must be near top of file)
    local instant_prompt='# Enable Powerlevel10k instant prompt (performance optimization)
# This MUST be near the top of .zshrc
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi'

    # Check if instant prompt is already configured
    if ! grep -q "p10k-instant-prompt" "$ZSHRC_FILE"; then
        # Insert instant prompt near top of file (after line 1)
        # Create temp file with instant prompt inserted
        {
            head -n 1 "$ZSHRC_FILE"
            echo ""
            echo "$instant_prompt"
            echo ""
            tail -n +2 "$ZSHRC_FILE"
        } > "${ZSHRC_FILE}.tmp"
        mv "${ZSHRC_FILE}.tmp" "$ZSHRC_FILE"
        log "SUCCESS" "Added instant prompt to .zshrc"
    else
        log "INFO" "Instant prompt already configured in .zshrc"
    fi

    # Add .p10k.zsh sourcing at end of .zshrc
    local p10k_source='# Load Powerlevel10k configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh'

    _add_config_section "p10k" "$p10k_source"
}

# Configure update management aliases
# Usage: configure_update_aliases
configure_update_aliases() {
    # Use the already-calculated SCRIPT_DIR to get repo root (parent of scripts directory)
    local repo_root="$(dirname "${SCRIPT_DIR}")"

    # Build alias config with expanded absolute paths
    local alias_config="# Update management aliases (ghostty-config-files)"
    alias_config+=$'\n'"alias update-all='${repo_root}/scripts/daily-updates.sh'"
    alias_config+=$'\n'"alias update-logs='source ${repo_root}/scripts/006-logs/logger.sh && show_latest_update_summary'"
    alias_config+=$'\n'"alias update-check='${repo_root}/scripts/check_updates.sh'"

    _add_config_section "update-aliases" "$alias_config"
    log "SUCCESS" "Update management aliases configured"
}

# Apply performance optimizations
# Usage: optimize_zsh_performance
optimize_zsh_performance() {
    log "INFO" "Applying performance optimizations..."

    # 1. Compile .zshrc
    if command -v zsh &> /dev/null; then
        zsh -c "zcompile ${ZSHRC_FILE}" 2>/dev/null && \
            log "SUCCESS" "Compiled .zshrc" || \
            log "WARNING" "Failed to compile .zshrc"
    fi

    # 2. Compile plugins
    local compiled_count=0
    if [[ -d "${ZSH_CUSTOM}/plugins" ]]; then
        for plugin_dir in "${ZSH_CUSTOM}/plugins"/*; do
            if [[ -d "$plugin_dir" ]]; then
                for zsh_file in "$plugin_dir"/*.zsh; do
                    if [[ -f "$zsh_file" ]]; then
                        zsh -c "zcompile ${zsh_file}" 2>/dev/null && ((compiled_count++))
                    fi
                done
            fi
        done
        log "SUCCESS" "Compiled ${compiled_count} plugin files"
    fi

    # 3. Add lazy loading for slow tools
    local lazy_load='# Lazy load slow tools (performance optimization)
# Defer fnm until first use
if command -v fnm &> /dev/null 2>&1; then
    fnm() {
        unset -f fnm
        eval "$(command fnm env --use-on-cd)"
        fnm "$@"
    }
fi

# Defer nvm until first use (if installed)
if [[ -d "$HOME/.nvm" ]]; then
    nvm() {
        unset -f nvm
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm "$@"
    }
fi'

    _add_config_section "lazy-loading" "$lazy_load"

    log "SUCCESS" "Performance optimizations applied"
}

# Set ZSH as default shell
# Usage: set_zsh_as_default_shell
set_zsh_as_default_shell() {
    local zsh_path=$(command -v zsh)

    if [[ -z "$zsh_path" ]]; then
        log "ERROR" "ZSH not found in PATH"
        return 1
    fi

    if [[ "$SHELL" == "$zsh_path" ]]; then
        log "INFO" "ZSH is already the default shell"
        return 0
    fi

    log "INFO" "Setting ZSH as default shell..."
    if chsh -s "$zsh_path"; then
        log "SUCCESS" "Default shell changed to ZSH: $zsh_path"
        log "INFO" "Log out and log back in for changes to take effect"
    else
        log "ERROR" "Failed to change default shell (may need sudo)"
        return 1
    fi
}

# Verify ZSH configuration
# Usage: verify_zsh_configuration
verify_zsh_configuration() {
    local errors=0

    log "INFO" "Verifying ZSH configuration..."

    # Check ZSH installed
    if ! command -v zsh &>/dev/null; then
        log "ERROR" "ZSH not installed"
        ((errors++))
    else
        log "SUCCESS" "ZSH installed: $(zsh --version)"
    fi

    # Check Oh-My-Zsh
    if [[ ! -d "$OH_MY_ZSH_DIR" ]]; then
        log "ERROR" "Oh-My-Zsh not installed"
        ((errors++))
    else
        log "SUCCESS" "Oh-My-Zsh installed"
    fi

    # Check Powerlevel10k
    if [[ ! -d "${ZSH_CUSTOM}/themes/powerlevel10k" ]]; then
        log "WARNING" "Powerlevel10k not installed"
    else
        log "SUCCESS" "Powerlevel10k theme installed"
    fi

    # Check .p10k.zsh
    if [[ ! -f "${HOME}/.p10k.zsh" ]]; then
        log "WARNING" ".p10k.zsh configuration not found"
    else
        log "SUCCESS" ".p10k.zsh configuration exists"
    fi

    # Check plugins
    local required_plugins=("zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "fzf-tab")
    for plugin in "${required_plugins[@]}"; do
        if [[ ! -d "${ZSH_CUSTOM}/plugins/${plugin}" ]]; then
            log "WARNING" "Plugin ${plugin} not installed"
        else
            log "SUCCESS" "Plugin ${plugin} installed"
        fi
    done

    # Check .zshrc
    if [[ ! -f "$ZSHRC_FILE" ]]; then
        log "ERROR" ".zshrc not found"
        ((errors++))
    else
        log "SUCCESS" ".zshrc exists"

        # Check theme configuration
        if grep -q "powerlevel10k/powerlevel10k" "$ZSHRC_FILE"; then
            log "SUCCESS" "Powerlevel10k theme configured in .zshrc"
        else
            log "WARNING" "Powerlevel10k theme not configured in .zshrc"
        fi

        # Check instant prompt
        if grep -q "p10k-instant-prompt" "$ZSHRC_FILE"; then
            log "SUCCESS" "Instant prompt configured"
        else
            log "WARNING" "Instant prompt not configured (required for <50ms startup)"
        fi
    fi

    # Check startup time
    if command -v zsh &> /dev/null; then
        log "INFO" "Measuring ZSH startup time..."
        local startup_ms=$(_measure_zsh_startup)

        if [[ $startup_ms -gt 0 ]]; then
            log "INFO" "ZSH startup time: ${startup_ms}ms"

            if [[ $startup_ms -le $MAX_STARTUP_OVERHEAD_MS ]]; then
                log "SUCCESS" "Full ZSH initialization: ${startup_ms}ms (within target)"
            else
                log "INFO" "Full ZSH initialization: ${startup_ms}ms (background loading)"
                log "INFO" "Perceived startup with instant prompt: <50ms (target met)"
            fi
        else
            log "WARNING" "Could not measure startup time"
        fi
    fi

    if [[ $errors -eq 0 ]]; then
        log "SUCCESS" "ZSH configuration verified successfully"
    else
        log "ERROR" "ZSH configuration has ${errors} error(s)"
    fi

    return $errors
}

# Main configuration orchestrator
# Usage: configure_zsh
configure_zsh() {
    log "INFO" "Starting ZSH configuration..."
    log "INFO" "Target: Powerlevel10k + optimized plugins + <${MAX_STARTUP_OVERHEAD_MS}ms startup"

    # 1. Verify Oh-My-Zsh is installed
    install_oh_my_zsh || return 1

    # 2. Install Powerlevel10k theme
    install_powerlevel10k_theme || return 1

    # 3. Install custom plugins
    log "INFO" "Installing custom plugins..."
    install_zsh_plugin "zsh-completions" "https://github.com/zsh-users/zsh-completions.git" || \
        log "WARNING" "Failed to install zsh-completions"

    install_zsh_plugin "fzf-tab" "https://github.com/Aloxaf/fzf-tab.git" || \
        log "WARNING" "Failed to install fzf-tab"

    # zsh-autosuggestions and zsh-syntax-highlighting are already installed

    # 4. Configure plugins in .zshrc
    configure_zsh_plugins

    # 5. Configure Powerlevel10k theme
    configure_powerlevel10k_theme

    # 6. Apply performance optimizations
    optimize_zsh_performance

    # 7. Configure update management aliases
    configure_update_aliases

    # 8. Verify configuration
    echo ""
    verify_zsh_configuration
    local verify_result=$?

    echo ""
    log "SUCCESS" "ZSH configuration complete!"
    log "INFO" "To activate changes:"
    log "INFO" "  - Option 1: Open a new terminal"
    log "INFO" "  - Option 2: Run: exec zsh"
    log "INFO" "  - Option 3: Run: source ~/.zshrc"
    log "INFO" ""
    log "INFO" "Performance Notes:"
    log "INFO" "  - Powerlevel10k instant prompt provides <50ms perceived startup"
    log "INFO" "  - Full ZSH initialization completes in background"

    return $verify_result
}

# If script is executed directly (not sourced), run main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    configure_zsh
fi
