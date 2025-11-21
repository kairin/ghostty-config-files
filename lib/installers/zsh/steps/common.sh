#!/usr/bin/env bash
#
# Module: ZSH Common
# Purpose: Shared variables and functions for ZSH tasks
#
# Context7 Best Practices (2025):
# - Oh My ZSH is the de-facto standard ZSH framework
# - Recommended plugins: git, docker, kubectl, zsh-autosuggestions, zsh-syntax-highlighting
# - XDG Base Directory compliance for configuration
# - Preserve user customizations during updates
#
set -euo pipefail

# Source core libraries if not already sourced
if [ -z "${REPO_ROOT:-}" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../../init.sh"
fi

# Installation constants
export OH_MY_ZSH_DIR="${HOME}/.oh-my-zsh"
export ZSHRC="${HOME}/.zshrc"
export ZSH_CUSTOM="${OH_MY_ZSH_DIR}/custom"
export OH_MY_ZSH_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

# Recommended plugins (constitutional compliance)
export RECOMMENDED_PLUGINS=(
    "git"
    "docker"
    "kubectl"
    "zsh-autosuggestions"
    "zsh-syntax-highlighting"
)

# Plugin repositories
export PLUGIN_AUTOSUGGESTIONS_REPO="https://github.com/zsh-users/zsh-autosuggestions.git"
export PLUGIN_SYNTAX_HIGHLIGHTING_REPO="https://github.com/zsh-users/zsh-syntax-highlighting.git"

# Verification functions
verify_zsh_installed() {
    command_exists "zsh"
}

verify_oh_my_zsh_installed() {
    [ -d "$OH_MY_ZSH_DIR" ]
}

verify_zshrc_exists() {
    [ -f "$ZSHRC" ]
}

verify_plugin_installed() {
    local plugin_name="$1"
    [ -d "${ZSH_CUSTOM}/plugins/${plugin_name}" ]
}

verify_zsh_configured() {
    verify_zsh_installed && \
    verify_oh_my_zsh_installed && \
    verify_zshrc_exists
}

# Export verification functions
export -f verify_zsh_installed
export -f verify_oh_my_zsh_installed
export -f verify_zshrc_exists
export -f verify_plugin_installed
export -f verify_zsh_configured
