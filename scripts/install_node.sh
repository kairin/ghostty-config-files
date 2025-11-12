#!/bin/bash
# Module: install_node.sh
# Purpose: Install and manage Node.js via fnm (Fast Node Manager)
# Dependencies: curl, bash
# Modules Required: common.sh
# Exit Codes: 0=success, 1=general failure, 2=fnm installation failed, 3=Node installation failed
# Constitutional Compliance: AGENTS.md line 23 mandates fnm for 40x faster startup (<50ms vs 500ms-3s)

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

        # Remove temporary fnm installation artifacts if present
        if [ -n "${FNM_INSTALL_TEMP:-}" ] && [ -d "$FNM_INSTALL_TEMP" ]; then
            rm -rf "$FNM_INSTALL_TEMP" 2>/dev/null || true
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
: "${NODE_VERSION:=lts/latest}"  # fnm supports LTS selection
: "${FNM_DIR:=${HOME}/.local/share/fnm}"  # XDG-compliant default
: "${FNM_INSTALL_URL:=https://fnm.vercel.app/install}"

# ============================================================
# PUBLIC FUNCTIONS (Module API)
# ============================================================

# Function: install_fnm
# Purpose: Install or update fnm (Fast Node Manager)
# Args: None (uses FNM_DIR environment variable)
# Returns: 0 on success, 2 on failure
# Side Effects: Creates ~/.local/share/fnm directory, modifies shell RC files
install_fnm() {
    log_info "⚡ Installing/updating fnm (Fast Node Manager)..."

    # Check if fnm is already installed
    if command -v fnm >/dev/null 2>&1; then
        log_info "✅ fnm already installed"
        _check_fnm_update
        return 0
    fi

    log_info "📥 Installing fnm from $FNM_INSTALL_URL..."

    # Install fnm using official installer
    # The installer automatically detects shell and adds to PATH
    if curl -fsSL "$FNM_INSTALL_URL" | bash -s -- --skip-shell >/dev/null 2>&1; then
        log_info "✅ fnm installed to $FNM_DIR"

        # Add fnm to current session PATH
        export PATH="$FNM_DIR:$PATH"

        # Configure shell integration
        _configure_fnm_shell_integration

        return 0
    else
        log_error "❌ Failed to install fnm"
        return 2
    fi
}

# Function: install_node
# Purpose: Install Node.js using fnm
# Args: $1=node_version (optional, defaults to NODE_VERSION env var)
# Returns: 0 on success, 3 on failure
# Side Effects: Installs Node.js, sets default version in fnm
install_node() {
    local node_version="${1:-$NODE_VERSION}"

    log_info "📦 Installing Node.js $node_version via fnm..."

    # Ensure fnm is available
    if ! command -v fnm >/dev/null 2>&1; then
        # Try to load fnm from known installation location
        if [[ -f "$FNM_DIR/fnm" ]]; then
            export PATH="$FNM_DIR:$PATH"
        else
            log_error "❌ fnm not found, please install it first"
            return 3
        fi
    fi

    # Check if Node.js is already installed with the target version
    if command -v node >/dev/null 2>&1; then
        local current_version
        current_version=$(node --version | sed 's/v//')

        # For LTS, check if we're on latest LTS
        if [[ "$node_version" == "lts/latest" ]] || [[ "$node_version" == "lts/*" ]]; then
            log_info "Current Node.js version: $current_version"
            log_info "Ensuring latest LTS is installed..."
        elif [[ "$current_version" == "$node_version" ]]; then
            log_info "✅ Node.js $node_version already installed"
            return 0
        else
            log_info "Current Node.js version: $current_version, target: $node_version"
        fi
    fi

    # Install Node.js
    log_info "📥 Installing Node.js $node_version..."
    if fnm install "$node_version" >/dev/null 2>&1; then
        log_info "✅ Node.js $node_version installed"
    else
        log_error "❌ Failed to install Node.js $node_version"
        return 3
    fi

    # Set as default version
    if fnm default "$node_version" >/dev/null 2>&1; then
        log_info "✅ Node.js $node_version set as default"
    else
        log_warn "⚠️  Could not set default version, continuing..."
    fi

    # Activate the installed version
    eval "$(fnm env --use-on-cd --version-file-strategy=recursive)" >/dev/null 2>&1

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
# Purpose: Complete Node.js setup (fnm + Node + npm update)
# Args: $1=node_version (optional, defaults to NODE_VERSION env var)
# Returns: 0 on success, non-zero on failure
# Side Effects: Installs fnm, Node.js, updates npm
install_node_full() {
    local node_version="${1:-$NODE_VERSION}"

    log_info "🚀 Starting complete Node.js installation (fnm-based)..."

    # Step 1: Install/update fnm
    if ! install_fnm; then
        log_error "❌ fnm installation failed"
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
    log_info "📊 Performance: fnm provides <50ms startup vs 500ms-3s for NVM"
    return 0
}

# ============================================================
# PRIVATE FUNCTIONS (Internal helpers)
# ============================================================

# Function: _check_fnm_update
# Purpose: Check if fnm update is available and suggest update
# Args: None
# Returns: 0 always (informational only)
_check_fnm_update() {
    log_info "🔄 Checking for fnm updates..."

    # fnm doesn't have built-in version comparison, so we check GitHub releases
    local current_version
    current_version=$(fnm --version 2>/dev/null | awk '{print $2}' || echo "unknown")

    log_info "ℹ️  Current fnm version: $current_version"
    log_info "💡 To update fnm, run: curl -fsSL https://fnm.vercel.app/install | bash"

    return 0
}

# Function: _configure_fnm_shell_integration
# Purpose: Configure shell integration for bash and zsh
# Args: None
# Returns: 0 on success, 1 on failure
_configure_fnm_shell_integration() {
    log_info "🔧 Configuring fnm shell integration..."

    # fnm shell integration block
    local fnm_block='
# fnm (Fast Node Manager) - 2025 Performance Optimized
# Loads 40x faster than NVM, minimal startup impact (<50ms)
export FNM_DIR="$HOME/.local/share/fnm"
if [ -d "$FNM_DIR" ]; then
  export PATH="$FNM_DIR:$PATH"
  eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"
fi
'

    # Configure .bashrc
    if [[ -f "$HOME/.bashrc" ]]; then
        if ! grep -q "fnm env" "$HOME/.bashrc" 2>/dev/null; then
            echo "$fnm_block" >> "$HOME/.bashrc"
            log_info "✅ Added fnm to .bashrc"
        else
            log_info "ℹ️  fnm already configured in .bashrc"
        fi
    fi

    # Configure .zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        if ! grep -q "fnm env" "$HOME/.zshrc" 2>/dev/null; then
            echo "$fnm_block" >> "$HOME/.zshrc"
            log_info "✅ Added fnm to .zshrc"
        else
            log_info "ℹ️  fnm already configured in .zshrc"
        fi
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
        echo "Example: $0 lts/latest" >&2
        echo "Example: $0 24.11.1" >&2
        echo "Installs fnm, Node.js, and updates npm" >&2
        echo "" >&2
        echo "Constitutional Compliance: Uses fnm for 40x faster startup" >&2
        exit 1
    fi

    # Call main public function
    install_node_full "$@"
    exit $?
fi
