#!/bin/bash
# Module: install_uv.sh
# Purpose: Install and manage uv (Fast Python Package Installer)
# Dependencies: curl, bash
# Modules Required: common.sh
# Exit Codes: 0=success, 1=general failure, 2=uv installation failed, 3=tool installation failed
# Constitutional Compliance: Modern web development stack requirement (Feature 001)

set -euo pipefail

# Module-level guard: Allow sourcing for testing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    SOURCED_FOR_TESTING=1
else
    SOURCED_FOR_TESTING=0
fi

# Source required modules
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${MODULE_DIR}/common.sh"

# ============================================================
# CLEANUP HANDLER
# ============================================================

# Cleanup function (called on EXIT)
cleanup() {
    local exit_code=$?

    # Only perform cleanup if needed
    if [ -n "${CLEANUP_NEEDED:-}" ]; then
        log_info "Cleaning up..."

        # Remove temporary uv installation artifacts if present
        if [ -n "${UV_INSTALL_TEMP:-}" ] && [ -d "$UV_INSTALL_TEMP" ]; then
            rm -rf "$UV_INSTALL_TEMP" 2>/dev/null || true
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

# Default configuration (can be overridden by environment variables)
: "${UV_INSTALL_DIR:=${HOME}/.local/bin}"  # XDG-compliant default
: "${UV_INSTALL_URL:=https://astral.sh/uv/install.sh}"
: "${UV_TOOL_DIR:=${HOME}/.local/share/uv/tools}"  # XDG-compliant tool storage

# ============================================================
# PUBLIC FUNCTIONS (Module API)
# ============================================================

# Function: install_uv
# Purpose: Install or update uv (Fast Python Package Installer)
# Args: None (uses UV_INSTALL_DIR environment variable)
# Returns: 0 on success, 2 on failure
# Side Effects: Creates ~/.local/bin directory, modifies PATH if needed
install_uv() {
    log_info "Installing/updating uv (Fast Python Package Installer)..."

    # Check if uv is already installed
    if command -v uv >/dev/null 2>&1; then
        log_info "uv already installed"
        _check_uv_update
        return 0
    fi

    log_info "Installing uv from $UV_INSTALL_URL..."

    # Create installation directory if it doesn't exist
    mkdir -p "$UV_INSTALL_DIR"

    # Install uv using official installer
    # The installer automatically detects the system and installs the appropriate binary
    if curl -LsSf "$UV_INSTALL_URL" | sh >/dev/null 2>&1; then
        log_info "uv installed to $UV_INSTALL_DIR"

        # Add uv to current session PATH if not already there
        if [[ ":$PATH:" != *":$UV_INSTALL_DIR:"* ]]; then
            export PATH="$UV_INSTALL_DIR:$PATH"
        fi

        # Configure shell integration
        _configure_uv_shell_integration

        return 0
    else
        log_error "Failed to install uv"
        return 2
    fi
}

# Function: update_uv
# Purpose: Update uv to the latest version using uv self-update
# Args: None
# Returns: 0 on success, 1 on failure (non-critical)
# Side Effects: Updates global uv installation
update_uv() {
    log_info "Updating uv to latest version..."

    if ! command -v uv >/dev/null 2>&1; then
        log_warn "uv not found, skipping update"
        return 1
    fi

    # Get current version
    local current_version
    current_version=$(uv --version 2>/dev/null | awk '{print $2}' || echo "unknown")
    log_info "Current uv version: $current_version"

    # Update using uv self update
    if uv self update >/dev/null 2>&1; then
        local new_version
        new_version=$(uv --version 2>/dev/null | awk '{print $2}' || echo "unknown")

        if [[ "$new_version" != "$current_version" ]]; then
            log_info "uv updated from $current_version to $new_version"
        else
            log_info "uv already at latest version ($current_version)"
        fi
        return 0
    else
        log_warn "uv update failed, continuing with existing version"
        return 1
    fi
}

# Function: install_uv_tool
# Purpose: Install a tool using uv tool install
# Args: $1=tool_name (e.g., "specify-cli", "@anthropic-ai/claude-code")
# Returns: 0 on success, 3 on failure
# Side Effects: Installs tool globally via uv
install_uv_tool() {
    local tool_name="${1:-}"

    if [[ -z "$tool_name" ]]; then
        log_error "Tool name required for installation"
        return 3
    fi

    log_info "Installing $tool_name via uv tool install..."

    # Ensure uv is available
    if ! command -v uv >/dev/null 2>&1; then
        log_error "uv not found, please install it first"
        return 3
    fi

    # Check if tool is already installed
    if uv tool list 2>/dev/null | grep -q "^${tool_name}"; then
        log_info "$tool_name already installed"
        return 0
    fi

    # Install the tool
    if uv tool install "$tool_name" >/dev/null 2>&1; then
        log_info "$tool_name installed successfully"
        return 0
    else
        log_error "Failed to install $tool_name"
        return 3
    fi
}

# Function: update_uv_tool
# Purpose: Update a specific tool installed via uv
# Args: $1=tool_name (e.g., "specify-cli")
# Returns: 0 on success, 1 on failure (non-critical)
# Side Effects: Updates the specified tool
update_uv_tool() {
    local tool_name="${1:-}"

    if [[ -z "$tool_name" ]]; then
        log_error "Tool name required for update"
        return 1
    fi

    log_info "Updating $tool_name via uv tool upgrade..."

    if ! command -v uv >/dev/null 2>&1; then
        log_warn "uv not found, skipping tool update"
        return 1
    fi

    # Check if tool is installed
    if ! uv tool list 2>/dev/null | grep -q "^${tool_name}"; then
        log_warn "$tool_name not installed via uv, skipping update"
        return 1
    fi

    # Update the tool
    if uv tool upgrade "$tool_name" >/dev/null 2>&1; then
        log_info "$tool_name updated successfully"
        return 0
    else
        log_warn "$tool_name update failed, continuing with existing version"
        return 1
    fi
}

# Function: update_all_uv_tools
# Purpose: Update all tools installed via uv
# Args: None
# Returns: 0 on success, 1 on failure (non-critical)
# Side Effects: Updates all globally installed uv tools
update_all_uv_tools() {
    log_info "Updating all uv tools..."

    if ! command -v uv >/dev/null 2>&1; then
        log_warn "uv not found, skipping tool updates"
        return 1
    fi

    # Get list of installed tools
    local tools
    tools=$(uv tool list 2>/dev/null | awk '{print $1}' || echo "")

    if [[ -z "$tools" ]]; then
        log_info "No uv tools installed"
        return 0
    fi

    # Update each tool
    local update_count=0
    while IFS= read -r tool; do
        if [[ -n "$tool" ]]; then
            if update_uv_tool "$tool"; then
                ((update_count++)) || true
            fi
        fi
    done <<< "$tools"

    log_info "Updated $update_count uv tools"
    return 0
}

# Function: install_uv_full
# Purpose: Complete uv setup (uv installation + verification)
# Args: None
# Returns: 0 on success, non-zero on failure
# Side Effects: Installs uv, configures PATH
install_uv_full() {
    log_info "Starting complete uv installation..."

    # Step 1: Install/update uv
    if ! install_uv; then
        log_error "uv installation failed"
        return 2
    fi

    # Step 2: Verify installation
    if command -v uv >/dev/null 2>&1; then
        local version
        version=$(uv --version 2>/dev/null || echo "unknown")
        log_info "uv installation complete: $version"
        log_info "Performance: uv provides significantly faster package operations than pip"
    else
        log_error "uv installation verification failed"
        return 2
    fi

    return 0
}

# ============================================================
# PRIVATE FUNCTIONS (Internal helpers)
# ============================================================

# Function: _check_uv_update
# Purpose: Check if uv update is available
# Args: None
# Returns: 0 always (informational only)
_check_uv_update() {
    log_info "Checking for uv updates..."

    local current_version
    current_version=$(uv --version 2>/dev/null | awk '{print $2}' || echo "unknown")

    log_info "Current uv version: $current_version"
    log_info "To update uv, run: uv self update"

    return 0
}

# Function: _configure_uv_shell_integration
# Purpose: Configure shell integration for bash and zsh
# Args: None
# Returns: 0 on success, 1 on failure
_configure_uv_shell_integration() {
    log_info "Configuring uv shell integration..."

    # uv shell integration block
    local uv_block='
# uv (Fast Python Package Installer) - 2025 Performance Optimized
# Significantly faster than pip for package operations
export UV_INSTALL_DIR="$HOME/.local/bin"
if [ -d "$UV_INSTALL_DIR" ]; then
  export PATH="$UV_INSTALL_DIR:$PATH"
fi
'

    # Configure .bashrc
    if [[ -f "$HOME/.bashrc" ]]; then
        if ! grep -q "UV_INSTALL_DIR" "$HOME/.bashrc" 2>/dev/null; then
            echo "$uv_block" >> "$HOME/.bashrc"
            log_info "Added uv to .bashrc"
        else
            log_info "uv already configured in .bashrc"
        fi
    fi

    # Configure .zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        if ! grep -q "UV_INSTALL_DIR" "$HOME/.zshrc" 2>/dev/null; then
            echo "$uv_block" >> "$HOME/.zshrc"
            log_info "Added uv to .zshrc"
        else
            log_info "uv already configured in .zshrc"
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
        echo "Usage: $0 [install|update|install-tool TOOL_NAME|update-tool TOOL_NAME]" >&2
        echo "Example: $0 install" >&2
        echo "Example: $0 update" >&2
        echo "Example: $0 install-tool specify-cli" >&2
        echo "Example: $0 update-tool specify-cli" >&2
        echo "Installs and manages uv and uv-based tools" >&2
        echo "" >&2
        echo "Constitutional Compliance: Modern web development stack requirement" >&2
        exit 1
    fi

    case "$1" in
        install)
            install_uv_full
            exit $?
            ;;
        update)
            update_uv
            exit $?
            ;;
        install-tool)
            if [[ $# -lt 2 ]]; then
                echo "ERROR: Tool name required" >&2
                exit 1
            fi
            install_uv_tool "$2"
            exit $?
            ;;
        update-tool)
            if [[ $# -lt 2 ]]; then
                echo "ERROR: Tool name required" >&2
                exit 1
            fi
            update_uv_tool "$2"
            exit $?
            ;;
        *)
            echo "ERROR: Unknown command: $1" >&2
            exit 1
            ;;
    esac
fi
