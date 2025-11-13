#!/bin/bash
# Module: install_spec_kit.sh
# Purpose: Install and manage spec-kit (Specification Development Toolkit)
# Dependencies: uv (Fast Python Package Installer)
# Modules Required: common.sh, install_uv.sh
# Exit Codes: 0=success, 1=general failure, 2=uv dependency missing, 3=spec-kit installation failed
# Constitutional Compliance: Spec-Kit development workflow requirement

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
# shellcheck source=scripts/install_uv.sh
source "${MODULE_DIR}/install_uv.sh"

# ============================================================
# CLEANUP HANDLER
# ============================================================

# Cleanup function (called on EXIT)
cleanup() {
    local exit_code=$?

    # Only perform cleanup if needed
    if [ -n "${CLEANUP_NEEDED:-}" ]; then
        log_info "Cleaning up..."

        # Remove temporary spec-kit artifacts if present
        if [ -n "${SPECKIT_INSTALL_TEMP:-}" ] && [ -d "$SPECKIT_INSTALL_TEMP" ]; then
            rm -rf "$SPECKIT_INSTALL_TEMP" 2>/dev/null || true
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
: "${SPECKIT_PACKAGE:=specify-cli}"  # NPM package name
: "${SPECKIT_COMMAND:=specify}"      # Primary command
: "${SPECKIT_SLASH_COMMANDS_DIR:=${HOME}/Apps/ghostty-config-files/.claude/commands}"  # Slash commands location

# UV tools installation location (for verification)
: "${SPECKIT_UV_TOOLS_BIN:=${HOME}/.local/share/uv/tools/specify-cli/bin/${SPECKIT_COMMAND}}"

# ============================================================
# PUBLIC FUNCTIONS (Module API)
# ============================================================

# Function: install_spec_kit
# Purpose: Install spec-kit using uv tool install
# Args: None (uses SPECKIT_PACKAGE environment variable)
# Returns: 0 on success, 2 if uv missing, 3 on installation failure
# Side Effects: Installs spec-kit globally via uv, configures slash commands
install_spec_kit() {
    log_info "Installing spec-kit ($SPECKIT_PACKAGE)..."

    # Ensure uv is available
    if ! command -v uv >/dev/null 2>&1; then
        log_error "uv not found, installing uv first..."
        if ! install_uv_full; then
            log_error "Failed to install uv dependency"
            return 2
        fi
    fi

    # Check if spec-kit is already installed
    # Priority 1: Check UV tools directory (most common location)
    if [[ -x "$SPECKIT_UV_TOOLS_BIN" ]]; then
        log_info "$SPECKIT_COMMAND already installed at $SPECKIT_UV_TOOLS_BIN"
        _check_spec_kit_update
        return 0
    # Priority 2: Check PATH (if user added to PATH manually)
    elif command -v "$SPECKIT_COMMAND" >/dev/null 2>&1; then
        log_info "$SPECKIT_COMMAND already installed (in PATH)"
        _check_spec_kit_update
        return 0
    fi

    log_info "Installing $SPECKIT_PACKAGE via uv tool install..."

    # Install spec-kit using uv
    if install_uv_tool "$SPECKIT_PACKAGE"; then
        log_info "$SPECKIT_PACKAGE installed successfully"

        # Verify installation (check UV tools location directly)
        if [[ -x "$SPECKIT_UV_TOOLS_BIN" ]]; then
            local version
            version=$("$SPECKIT_UV_TOOLS_BIN" --version 2>/dev/null || echo "unknown")
            log_info "✅ spec-kit installed successfully: $version"
            log_info "📍 Location: $SPECKIT_UV_TOOLS_BIN"
            log_info "💡 Will be available as 'specify' after shell restart"
        elif command -v "$SPECKIT_COMMAND" >/dev/null 2>&1; then
            local version
            version=$("$SPECKIT_COMMAND" --version 2>/dev/null || echo "unknown")
            log_info "✅ spec-kit installed successfully: $version (in current PATH)"
        else
            log_error "❌ spec-kit installation verification failed"
            log_info "Expected location: $SPECKIT_UV_TOOLS_BIN"
            log_info "Run 'uv tool list' to check installation status"
            return 3
        fi

        # Configure slash commands
        _configure_spec_kit_slash_commands

        return 0
    else
        log_error "Failed to install $SPECKIT_PACKAGE"
        return 3
    fi
}

# Function: update_spec_kit
# Purpose: Update spec-kit to the latest version
# Args: None
# Returns: 0 on success, 1 on failure (non-critical)
# Side Effects: Updates global spec-kit installation
update_spec_kit() {
    log_info "Updating spec-kit ($SPECKIT_PACKAGE)..."

    if ! command -v uv >/dev/null 2>&1; then
        log_warn "uv not found, skipping spec-kit update"
        return 1
    fi

    # Check if spec-kit is installed
    if ! command -v "$SPECKIT_COMMAND" >/dev/null 2>&1; then
        log_warn "spec-kit not installed, skipping update"
        return 1
    fi

    # Get current version
    local current_version
    current_version=$("$SPECKIT_COMMAND" --version 2>/dev/null | awk '{print $NF}' || echo "unknown")
    log_info "Current spec-kit version: $current_version"

    # Update using uv tool upgrade
    if update_uv_tool "$SPECKIT_PACKAGE"; then
        local new_version
        new_version=$("$SPECKIT_COMMAND" --version 2>/dev/null | awk '{print $NF}' || echo "unknown")

        if [[ "$new_version" != "$current_version" ]]; then
            log_info "spec-kit updated from $current_version to $new_version"
        else
            log_info "spec-kit already at latest version ($current_version)"
        fi

        # Update slash commands if needed
        _configure_spec_kit_slash_commands

        return 0
    else
        log_warn "spec-kit update failed, continuing with existing version"
        return 1
    fi
}

# Function: verify_spec_kit_slash_commands
# Purpose: Verify that spec-kit slash commands are properly configured
# Args: None
# Returns: 0 if all commands exist, 1 if any are missing
# Side Effects: Prints verification results
verify_spec_kit_slash_commands() {
    log_info "Verifying spec-kit slash commands..."

    # List of expected slash commands
    local commands=(
        "speckit.constitution"
        "speckit.specify"
        "speckit.clarify"
        "speckit.plan"
        "speckit.tasks"
        "speckit.implement"
        "speckit.analyze"
    )

    local missing_count=0
    for cmd in "${commands[@]}"; do
        local cmd_file="${SPECKIT_SLASH_COMMANDS_DIR}/${cmd}.md"
        if [[ -f "$cmd_file" ]]; then
            log_info "/$cmd - found"
        else
            log_warn "/$cmd - MISSING: $cmd_file"
            ((missing_count++)) || true
        fi
    done

    if [[ $missing_count -eq 0 ]]; then
        log_info "All spec-kit slash commands configured correctly"
        return 0
    else
        log_warn "$missing_count spec-kit slash commands are missing"
        return 1
    fi
}

# Function: install_spec_kit_full
# Purpose: Complete spec-kit setup (installation + verification)
# Args: None
# Returns: 0 on success, non-zero on failure
# Side Effects: Installs spec-kit, configures slash commands
install_spec_kit_full() {
    log_info "Starting complete spec-kit installation..."

    # Step 1: Ensure uv is installed
    if ! command -v uv >/dev/null 2>&1; then
        log_info "uv not found, installing uv first..."
        if ! install_uv_full; then
            log_error "Failed to install uv dependency"
            return 2
        fi
    fi

    # Step 2: Install spec-kit
    if ! install_spec_kit; then
        log_error "spec-kit installation failed"
        return 3
    fi

    # Step 3: Verify slash commands
    if verify_spec_kit_slash_commands; then
        log_info "spec-kit installation and configuration complete"
    else
        log_warn "spec-kit installed but some slash commands may be missing"
        log_info "Run 'specify init' in your project to configure slash commands"
    fi

    return 0
}

# ============================================================
# PRIVATE FUNCTIONS (Internal helpers)
# ============================================================

# Function: _check_spec_kit_update
# Purpose: Check if spec-kit update is available
# Args: None
# Returns: 0 always (informational only)
_check_spec_kit_update() {
    log_info "Checking for spec-kit updates..."

    local current_version
    current_version=$("$SPECKIT_COMMAND" --version 2>/dev/null | awk '{print $NF}' || echo "unknown")

    log_info "Current spec-kit version: $current_version"
    log_info "To update spec-kit, run: uv tool upgrade $SPECKIT_PACKAGE"

    return 0
}

# Function: _configure_spec_kit_slash_commands
# Purpose: Ensure spec-kit slash commands are properly configured
# Args: None
# Returns: 0 on success, 1 on failure
_configure_spec_kit_slash_commands() {
    log_info "Configuring spec-kit slash commands..."

    # Check if slash commands directory exists
    if [[ ! -d "$SPECKIT_SLASH_COMMANDS_DIR" ]]; then
        log_info "Slash commands directory not found: $SPECKIT_SLASH_COMMANDS_DIR"
        log_info "Run 'specify init' in your project to create slash commands"
        return 1
    fi

    # Verify slash commands exist
    if verify_spec_kit_slash_commands; then
        log_info "Slash commands configured correctly"
        return 0
    else
        log_warn "Some slash commands are missing"
        log_info "Run 'specify init' to regenerate missing commands"
        return 1
    fi
}

# ============================================================
# MAIN EXECUTION (Skipped when sourced)
# ============================================================

if [[ "${SOURCED_FOR_TESTING}" -eq 0 ]]; then
    # Execute when run directly, not when sourced
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 [install|update|verify]" >&2
        echo "Example: $0 install" >&2
        echo "Example: $0 update" >&2
        echo "Example: $0 verify" >&2
        echo "Installs and manages spec-kit and its slash commands" >&2
        echo "" >&2
        echo "Constitutional Compliance: Spec-Kit development workflow" >&2
        exit 1
    fi

    case "$1" in
        install)
            install_spec_kit_full
            exit $?
            ;;
        update)
            update_spec_kit
            exit $?
            ;;
        verify)
            verify_spec_kit_slash_commands
            exit $?
            ;;
        *)
            echo "ERROR: Unknown command: $1" >&2
            exit 1
            ;;
    esac
fi
