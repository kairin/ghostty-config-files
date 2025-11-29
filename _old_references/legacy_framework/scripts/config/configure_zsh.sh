#!/bin/bash
# ZSH Configuration Script (Orchestrator)
# Purpose: Configure ZSH with Oh My ZSH, plugins, and <50ms startup optimization
# Refactored: 2025-11-25 - Modularized to <300 lines (was 803 lines)
# Modules: lib/config/zsh/{plugins,theme,aliases,functions}.sh

set -euo pipefail

# Prevent multiple sourcing
[[ -n "${CONFIGURE_ZSH_ORCHESTRATOR_LOADED:-}" ]] && return 0
readonly CONFIGURE_ZSH_ORCHESTRATOR_LOADED=1

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

readonly OH_MY_ZSH_DIR="${HOME}/.oh-my-zsh"
readonly ZSHRC_FILE="${HOME}/.zshrc"
readonly MAX_STARTUP_OVERHEAD_MS=50

# ============================================================================
# Source Modular ZSH Configuration Libraries
# ============================================================================

source_zsh_modules() {
    local lib_dir="${REPO_ROOT}/lib/config/zsh"

    for module in plugins theme aliases functions; do
        if [[ -f "${lib_dir}/${module}.sh" ]]; then
            source "${lib_dir}/${module}.sh"
        else
            echo "WARN: Module not found: ${module}.sh" >&2
        fi
    done
}

# ============================================================================
# Core ZSH Installation
# ============================================================================

install_zsh() {
    if ! command -v zsh &>/dev/null; then
        echo "Installing ZSH..."
        sudo apt update && sudo apt install -y zsh
        echo "ZSH installed"
    else
        echo "ZSH already installed"
    fi
}

install_oh_my_zsh() {
    if [[ -d "$OH_MY_ZSH_DIR" ]]; then
        echo "Oh My ZSH already installed"
        # Update to latest
        (cd "$OH_MY_ZSH_DIR" && git pull origin master 2>&1 | head -1) || true
        return 0
    fi

    echo "Installing Oh My ZSH..."

    # Backup existing .zshrc
    [[ -f "$ZSHRC_FILE" ]] && cp "$ZSHRC_FILE" "${ZSHRC_FILE}.backup-$(date +%Y%m%d-%H%M%S)"

    # Install Oh My ZSH (unattended)
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    if [[ -d "$OH_MY_ZSH_DIR" ]]; then
        echo "Oh My ZSH installed successfully"
        return 0
    else
        echo "Oh My ZSH installation failed" >&2
        return 1
    fi
}

# ============================================================================
# Performance Measurement
# ============================================================================

measure_zsh_startup() {
    local start_ns end_ns duration_ms
    start_ns=$(date +%s%N)
    zsh -i -c exit >/dev/null 2>&1 || true
    end_ns=$(date +%s%N)
    duration_ms=$(( (end_ns - start_ns) / 1000000 ))
    echo "$duration_ms"
}

verify_startup_performance() {
    echo "Measuring ZSH startup time..."
    local startup_ms
    startup_ms=$(measure_zsh_startup)
    echo "ZSH startup time: ${startup_ms}ms"

    if [[ $startup_ms -le $MAX_STARTUP_OVERHEAD_MS ]]; then
        echo "PASS: Performance target MET (<=${MAX_STARTUP_OVERHEAD_MS}ms)"
        return 0
    else
        echo "WARN: Performance target EXCEEDED (>${MAX_STARTUP_OVERHEAD_MS}ms)"
        return 0
    fi
}

# ============================================================================
# Set Default Shell
# ============================================================================

set_zsh_as_default() {
    local current_shell zsh_path
    current_shell=$(getent passwd "$USER" | cut -d: -f7)
    zsh_path=$(which zsh)

    if [[ "$current_shell" == "$zsh_path" ]]; then
        echo "ZSH is already the default shell"
        return 0
    fi

    echo "Setting ZSH as default shell..."
    if sudo usermod -s "$zsh_path" "$USER" 2>/dev/null; then
        echo "ZSH set as default shell (restart terminal to take effect)"
        return 0
    else
        echo "WARN: Could not set ZSH as default. Run: chsh -s $zsh_path"
        return 1
    fi
}

# ============================================================================
# Verification
# ============================================================================

verify_configuration() {
    echo ""
    echo "=== ZSH Configuration Verification ==="
    local checks_passed=0

    # Check ZSH
    if command -v zsh &>/dev/null; then
        echo "PASS: ZSH installed"
        ((checks_passed++))
    else
        echo "FAIL: ZSH not installed"
    fi

    # Check Oh My ZSH
    if [[ -d "$OH_MY_ZSH_DIR" ]]; then
        echo "PASS: Oh My ZSH installed"
        ((checks_passed++))
    else
        echo "FAIL: Oh My ZSH not installed"
    fi

    # Check .zshrc
    if [[ -f "$ZSHRC_FILE" ]] && grep -q "oh-my-zsh" "$ZSHRC_FILE"; then
        echo "PASS: .zshrc configured"
        ((checks_passed++))
    else
        echo "FAIL: .zshrc not configured"
    fi

    # Check plugins (using module if available)
    if declare -f verify_plugins_installed &>/dev/null; then
        verify_plugins_installed && ((checks_passed++))
    fi

    # Check theme (using module if available)
    if declare -f verify_theme_installed &>/dev/null; then
        verify_theme_installed && ((checks_passed++))
    fi

    echo ""
    echo "Verification complete: $checks_passed checks passed"
    return 0
}

# ============================================================================
# Main Configuration Flow
# ============================================================================

configure_zsh() {
    echo "=== ZSH Configuration ==="
    echo ""

    # Source modular libraries
    source_zsh_modules

    # Step 1: Install ZSH
    install_zsh

    # Step 2: Install Oh My ZSH
    install_oh_my_zsh || return 1

    # Step 3: Configure plugins (using module)
    if declare -f install_essential_plugins &>/dev/null; then
        echo ""
        echo "=== Installing Plugins ==="
        install_essential_plugins
        update_zshrc_plugins "$ZSHRC_FILE" 2>/dev/null || true
    fi

    # Step 4: Configure theme (using module)
    if declare -f install_powerlevel10k &>/dev/null; then
        echo ""
        echo "=== Installing Powerlevel10k Theme ==="
        install_powerlevel10k
        configure_powerlevel10k "$ZSHRC_FILE" 2>/dev/null || true
        setup_instant_prompt "$ZSHRC_FILE" 2>/dev/null || true
    fi

    # Step 5: Configure aliases (using module)
    if declare -f configure_modern_tool_aliases &>/dev/null; then
        echo ""
        echo "=== Configuring Aliases ==="
        configure_modern_tool_aliases "$ZSHRC_FILE"
        configure_fzf_integration "$ZSHRC_FILE" 2>/dev/null || true
        configure_zoxide_integration "$ZSHRC_FILE" 2>/dev/null || true
    fi

    # Step 6: Configure functions (using module)
    if declare -f configure_all_zsh_functions &>/dev/null; then
        echo ""
        echo "=== Configuring Functions ==="
        configure_all_zsh_functions "$ZSHRC_FILE"
    fi

    # Step 7: Set default shell
    echo ""
    echo "=== Setting Default Shell ==="
    set_zsh_as_default

    # Step 8: Verify performance
    echo ""
    echo "=== Performance Verification ==="
    verify_startup_performance

    # Step 9: Final verification
    verify_configuration

    echo ""
    echo "ZSH configuration complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Restart terminal: exec zsh"
    echo "  2. Customize theme: p10k configure"
    echo ""

    return 0
}

# ============================================================================
# Main Execution
# ============================================================================

# Only run if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    configure_zsh
    exit $?
fi
