#!/bin/bash
# Module: install_node.sh
# Purpose: Install and manage Node.js via NVM (Node Version Manager)
# Dependencies: curl, bash
# Modules Required: common.sh
# Exit Codes: 0=success, 1=general failure, 2=NVM installation failed, 3=Node installation failed

set -euo pipefail

# Module-level guard: Allow sourcing for testing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    SOURCED_FOR_TESTING=1
else
    SOURCED_FOR_TESTING=0
fi

# Source required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"

# ============================================================
# CLEANUP HANDLER
# ============================================================

# Cleanup function (called on EXIT)
cleanup() {
    local exit_code=$?

    # Only perform cleanup if needed
    if [ -n "${CLEANUP_NEEDED:-}" ]; then
        log_info "🧹 Cleaning up..."

        # Remove temporary NVM installation artifacts if present
        if [ -n "${NVM_INSTALL_TEMP:-}" ] && [ -d "$NVM_INSTALL_TEMP" ]; then
            rm -rf "$NVM_INSTALL_TEMP" 2>/dev/null || true
        fi
    fi

    # Exit with original code
    exit $exit_code
}

# Set trap for cleanup on exit (only if not sourced for testing)
if [[ "${SOURCED_FOR_TESTING}" -eq 0 ]]; then
    trap cleanup EXIT
fi

# ============================================================
# MODULE CONFIGURATION
# ============================================================

# Default versions (can be overridden by environment variables)
: "${NVM_VERSION:=v0.40.1}"
: "${NODE_VERSION:=24.6.0}"
: "${NVM_DIR:=${HOME}/.nvm}"

# ============================================================
# PUBLIC FUNCTIONS (Module API)
# ============================================================

# Function: install_nvm
# Purpose: Install or update NVM (Node Version Manager)
# Args: None (uses NVM_VERSION and NVM_DIR environment variables)
# Returns: 0 on success, 2 on failure
# Side Effects: Creates ~/.nvm directory, modifies shell RC files
install_nvm() {
    log_info "📦 Installing/updating NVM..."

    # Check if NVM directory exists
    if [ ! -d "$NVM_DIR" ]; then
        log_info "📥 Installing NVM $NVM_VERSION..."

        # Temporarily unset NVM_DIR to let installer create it
        # (NVM installer fails if NVM_DIR is set but directory doesn't exist)
        local saved_nvm_dir="$NVM_DIR"
        unset NVM_DIR

        if curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash >/dev/null 2>&1; then
            # Restore NVM_DIR after installation
            NVM_DIR="$saved_nvm_dir"
            log_info "✅ NVM installed to $NVM_DIR"
        else
            # Restore NVM_DIR even on failure
            NVM_DIR="$saved_nvm_dir"
            log_error "❌ Failed to install NVM"
            return 2
        fi
    else
        log_info "✅ NVM already present at $NVM_DIR"

        # Check if NVM update is available
        _check_nvm_update
    fi

    return 0
}

# Function: install_node
# Purpose: Install Node.js using NVM
# Args: $1=node_version (optional, defaults to NODE_VERSION env var)
# Returns: 0 on success, 3 on failure
# Side Effects: Installs Node.js, sets default version in NVM
install_node() {
    local node_version="${1:-$NODE_VERSION}"

    log_info "📦 Installing Node.js $node_version via NVM..."

    # Source NVM to make it available
    if ! _load_nvm; then
        log_error "❌ Failed to load NVM"
        return 3
    fi

    # Check if Node.js is already installed
    if command -v node >/dev/null 2>&1; then
        local current_version
        current_version=$(node --version | sed 's/v//')

        if [[ "$current_version" == "$node_version" ]]; then
            log_info "✅ Node.js $node_version already installed"
            return 0
        else
            log_info "Current Node.js version: $current_version, target: $node_version"
        fi
    fi

    # Install Node.js
    log_info "📥 Installing Node.js $node_version..."
    if nvm install "$node_version" >/dev/null 2>&1 && \
       nvm use "$node_version" >/dev/null 2>&1 && \
       nvm alias default "$node_version" >/dev/null 2>&1; then
        log_info "✅ Node.js $node_version installed and set as default"
    else
        log_error "❌ Failed to install Node.js $node_version"
        return 3
    fi

    return 0
}

# Function: update_npm
# Purpose: Update npm to latest version
# Args: None
# Returns: 0 on success, 1 on failure (non-critical)
# Side Effects: Updates global npm installation
update_npm() {
    log_info "🔄 Updating npm to latest version..."

    if ! command -v npm >/dev/null 2>&1; then
        log_warn "⚠️  npm not found, skipping update"
        return 1
    fi

    if npm install -g npm@latest >/dev/null 2>&1; then
        local npm_version
        npm_version=$(npm --version)
        log_info "✅ npm updated to $npm_version"
        return 0
    else
        log_warn "⚠️  npm update failed, continuing with existing version"
        return 1
    fi
}

# Function: install_node_full
# Purpose: Complete Node.js setup (NVM + Node + npm update)
# Args: $1=node_version (optional, defaults to NODE_VERSION env var)
# Returns: 0 on success, non-zero on failure
# Side Effects: Installs NVM, Node.js, updates npm
install_node_full() {
    local node_version="${1:-$NODE_VERSION}"

    log_info "🚀 Starting complete Node.js installation..."

    # Step 1: Install/update NVM
    if ! install_nvm; then
        log_error "❌ NVM installation failed"
        return 2
    fi

    # Step 2: Install Node.js
    if ! install_node "$node_version"; then
        log_error "❌ Node.js installation failed"
        return 3
    fi

    # Step 3: Update npm (non-critical)
    update_npm || log_warn "⚠️  npm update skipped, but continuing..."

    log_info "✅ Node.js installation complete!"
    return 0
}

# ============================================================
# PRIVATE FUNCTIONS (Internal helpers)
# ============================================================

# Function: _check_nvm_update
# Purpose: Check if NVM update is available and update if needed
# Args: None
# Returns: 0 on success, 1 on update failure (non-critical)
_check_nvm_update() {
    log_info "🔄 Checking for NVM updates..."

    # Load NVM to check version
    _load_nvm || return 1

    local current_nvm_version
    current_nvm_version=$(nvm --version 2>/dev/null || echo "unknown")
    local target_version
    target_version=$(echo "$NVM_VERSION" | sed 's/v//')

    if [[ "$current_nvm_version" != "$target_version" ]]; then
        log_info "🆕 NVM update available ($current_nvm_version → $target_version)"
        log_info "Updating NVM..."

        if curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash >/dev/null 2>&1; then
            log_info "✅ NVM updated to $NVM_VERSION"
            return 0
        else
            log_warn "⚠️  NVM update failed, continuing with existing version"
            return 1
        fi
    else
        log_info "✅ NVM is up to date ($current_nvm_version)"
        return 0
    fi
}

# Function: _load_nvm
# Purpose: Source NVM script to make nvm command available
# Args: None
# Returns: 0 on success, 1 on failure
_load_nvm() {
    # Set NVM_DIR for sourcing
    export NVM_DIR="${NVM_DIR}"

    # Source NVM script if it exists
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        # shellcheck source=/dev/null
        \. "$NVM_DIR/nvm.sh" >/dev/null 2>&1
    else
        log_error "❌ NVM script not found at $NVM_DIR/nvm.sh"
        return 1
    fi

    # Source bash completion if available
    [[ -s "$NVM_DIR/bash_completion" ]] && \. "$NVM_DIR/bash_completion" >/dev/null 2>&1

    # Verify NVM is working
    if ! command -v nvm >/dev/null 2>&1 && ! type nvm >/dev/null 2>&1; then
        log_warn "⚠️  NVM not available after sourcing"
        return 1
    fi

    return 0
}

# ============================================================
# MAIN EXECUTION (Skipped when sourced)
# ============================================================

if [[ "${SOURCED_FOR_TESTING}" -eq 0 ]]; then
    # Execute when run directly, not when sourced
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 [node_version]" >&2
        echo "Example: $0 24.6.0" >&2
        echo "Installs NVM, Node.js, and updates npm" >&2
        exit 1
    fi

    # Call main public function
    install_node_full "$@"
    exit $?
fi
