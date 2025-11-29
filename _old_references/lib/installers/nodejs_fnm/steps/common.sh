#!/usr/bin/env bash
#
# Module: Node.js fnm Common
# Purpose: Shared variables and functions for Node.js fnm tasks
#
# Context7 Best Practices (2025):
# - fnm significantly faster than nvm (performance measured and logged)
# - Node.js latest v25.2.0+ (NOT LTS - constitutional policy)
# - XDG-compliant installation (~/.local/share/fnm)
# - Auto-switching on directory change (.node-version/.nvmrc detection)
#
set -euo pipefail

# Source core libraries if not already sourced
if [ -z "${REPO_ROOT:-}" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../../init.sh"
fi

# Installation constants
export FNM_INSTALL_URL="https://fnm.vercel.app/install"
export FNM_DIR="${HOME}/.local/share/fnm"
export FNM_BINARY="${FNM_DIR}/fnm"
export NODE_LATEST_VERSION="latest"  # Constitutional: LATEST, not LTS

# Conflicting version managers (constitutional prohibition)
export NODEJS_CONFLICTING_MANAGERS=(
    "nvm"
    "n"
    "asdf"
    "nodenv"
)

# Verification functions
verify_fnm_not_installed() {
    [ ! -f "$FNM_BINARY" ]
}

verify_fnm_binary() {
    [ -f "$FNM_BINARY" ] && [ -x "$FNM_BINARY" ]
}

verify_fnm_version() {
    command_exists "fnm" && fnm --version &>/dev/null
}

verify_nodejs_installed() {
    command_exists "node" && node --version &>/dev/null
}

verify_nodejs_fnm() {
    verify_fnm_binary && verify_fnm_version && verify_nodejs_installed
}

# Export verification functions
export -f verify_fnm_not_installed
export -f verify_fnm_binary
export -f verify_fnm_version
export -f verify_nodejs_installed
export -f verify_nodejs_fnm
