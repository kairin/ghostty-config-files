#!/usr/bin/env bash
#
# lib/verification/checks/post_install_checks.sh - Post-installation validation checks
#
# Purpose: Validate complete system after installation
# Dependencies: None (standalone module)
# Constitutional: Principle V - Modular Architecture (<300 lines)
#
# Functions:
#   - check_gum_installed(): Verify gum installation
#   - check_ghostty_installed(): Verify Ghostty installation
#   - check_zsh_configured(): Verify ZSH configuration
#   - check_fnm_installed(): Verify fnm installation
#   - check_nodejs_version(): Verify Node.js version
#   - post_installation_health_check(): Run all post-install checks
#

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_LIB_VERIFICATION_CHECKS_POST_INSTALL_SH:-}" ]] && return 0
readonly _LIB_VERIFICATION_CHECKS_POST_INSTALL_SH=1

# Module constants
readonly NODE_MIN_MAJOR_VERSION=25

# ============================================================================
# COMPONENT CHECKS
# ============================================================================

# Function: check_gum_installed
# Purpose: Verify gum (Charm tool) is installed
# Args: None
# Returns:
#   0 = installed, 1 = not installed
check_gum_installed() {
    echo "Checking gum installation..."

    if command -v gum &>/dev/null; then
        local start_ns end_ns duration_ms
        start_ns=$(date +%s%N)
        gum --version &>/dev/null
        end_ns=$(date +%s%N)
        duration_ms=$(( (end_ns - start_ns) / 1000000 ))

        echo "PASS: gum: Installed (startup: ${duration_ms}ms)"
        return 0
    else
        echo "FAIL: gum: Not installed"
        return 1
    fi
}

# Function: check_ghostty_installed
# Purpose: Verify Ghostty terminal is installed
# Args: None
# Returns:
#   0 = installed, 1 = not installed
check_ghostty_installed() {
    echo "Checking Ghostty installation..."

    if command -v ghostty &>/dev/null; then
        local ghostty_path ghostty_version
        ghostty_path=$(command -v ghostty)
        ghostty_version=$(ghostty --version 2>&1 | head -n 1)
        echo "PASS: Ghostty: Installed at $ghostty_path ($ghostty_version)"
        return 0
    else
        echo "FAIL: Ghostty: Not found in PATH"
        return 1
    fi
}

# Function: check_zsh_configured
# Purpose: Verify ZSH is properly configured
# Args: None
# Returns:
#   0 = configured, 1 = not configured
check_zsh_configured() {
    echo "Checking ZSH configuration..."

    if command -v zsh &>/dev/null && [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo "PASS: ZSH: Installed with Oh My ZSH"
        return 0
    else
        echo "FAIL: ZSH: Not properly configured"
        return 1
    fi
}

# Function: check_uv_installed
# Purpose: Verify uv Python package manager is installed
# Args: None
# Returns:
#   0 = installed, 1 = not installed
check_uv_installed() {
    echo "Checking uv (Python package manager)..."

    if command -v uv &>/dev/null; then
        local uv_version
        uv_version=$(uv --version 2>&1 | head -n 1)
        echo "PASS: uv: Installed ($uv_version)"
        return 0
    else
        echo "FAIL: uv: Not installed"
        return 1
    fi
}

# Function: check_fnm_installed
# Purpose: Verify fnm (Fast Node Manager) is installed
# Args: None
# Returns:
#   0 = installed, 1 = not installed
check_fnm_installed() {
    echo "Checking fnm (Node.js manager)..."

    if command -v fnm &>/dev/null; then
        local start_ns end_ns duration_ms
        start_ns=$(date +%s%N)
        fnm env &>/dev/null
        end_ns=$(date +%s%N)
        duration_ms=$(( (end_ns - start_ns) / 1000000 ))

        echo "PASS: fnm: Installed (startup: ${duration_ms}ms)"
        return 0
    else
        echo "FAIL: fnm: Not installed"
        return 1
    fi
}

# Function: check_nodejs_version
# Purpose: Verify Node.js version meets requirements
# Args: None
# Returns:
#   0 = meets requirements, 1 = too old or not installed
check_nodejs_version() {
    echo "Checking Node.js version..."

    if command -v node &>/dev/null; then
        local node_version node_major
        node_version=$(node --version 2>&1 | head -n 1)
        node_major=$(echo "$node_version" | sed 's/v\([0-9]*\).*/\1/')

        if [[ "$node_major" -ge "$NODE_MIN_MAJOR_VERSION" ]]; then
            echo "PASS: Node.js: Latest version installed ($node_version >= v${NODE_MIN_MAJOR_VERSION})"
            return 0
        else
            echo "FAIL: Node.js: Old version ($node_version < v${NODE_MIN_MAJOR_VERSION})"
            echo "  Constitutional requirement: Latest Node.js (v${NODE_MIN_MAJOR_VERSION}+), NOT LTS"
            return 1
        fi
    else
        echo "FAIL: Node.js: Not installed"
        return 1
    fi
}

# ============================================================================
# OPTIONAL COMPONENT CHECKS
# ============================================================================

# Function: check_ai_tools
# Purpose: Check AI tool installations (optional)
# Args: None
# Returns:
#   Number of AI tools installed (stdout)
check_ai_tools() {
    echo "Checking AI tools..."

    local ai_tool_count=0

    if command -v claude &>/dev/null; then
        echo "  PASS: Claude CLI"
        ((ai_tool_count++))
    else
        echo "  WARN: Claude CLI not installed"
    fi

    if command -v gemini &>/dev/null; then
        echo "  PASS: Gemini CLI"
        ((ai_tool_count++))
    else
        echo "  WARN: Gemini CLI not installed"
    fi

    if [[ "$ai_tool_count" -gt 0 ]]; then
        echo "PASS: AI Tools: ${ai_tool_count}/2 installed"
    else
        echo "WARN: AI Tools: None installed (optional)"
    fi

    echo "$ai_tool_count"
}

# Function: check_context_menu
# Purpose: Check Nautilus context menu integration (optional)
# Args: None
# Returns:
#   0 = configured, 1 = not configured
check_context_menu() {
    echo "Checking Nautilus context menu integration..."

    local nautilus_script_dir="$HOME/.local/share/nautilus/scripts"

    if [[ -d "$nautilus_script_dir" ]] && [[ -x "$nautilus_script_dir/Open in Ghostty" ]]; then
        echo "PASS: Context Menu: Integrated with Nautilus"
        return 0
    else
        echo "WARN: Context Menu: Not configured (optional)"
        return 1
    fi
}

# ============================================================================
# COMPREHENSIVE POST-INSTALL CHECK
# ============================================================================

# Function: post_installation_health_check
# Purpose: Run all post-installation validation checks
# Args: None
# Returns:
#   0 = all critical checks passed, 1 = critical failures
post_installation_health_check() {
    echo "Running post-installation health checks..."
    echo

    local failures=0

    # Check gum
    if ! check_gum_installed; then
        ((failures++))
    fi
    echo

    # Check Ghostty
    if ! check_ghostty_installed; then
        ((failures++))
    fi
    echo

    # Check ZSH
    if ! check_zsh_configured; then
        ((failures++))
    fi
    echo

    # Check uv
    if ! check_uv_installed; then
        ((failures++))
    fi
    echo

    # Check fnm
    if ! check_fnm_installed; then
        ((failures++))
    fi
    echo

    # Check Node.js version
    if ! check_nodejs_version; then
        ((failures++))
    fi
    echo

    # Check AI tools (optional)
    check_ai_tools >/dev/null
    echo

    # Check context menu (optional)
    check_context_menu || true
    echo

    # Summary
    if [[ "$failures" -eq 0 ]]; then
        echo "========================================"
        echo "PASS: POST-INSTALLATION CHECK: ALL PASSED"
        echo "  System ready for production use"
        echo "========================================"
        return 0
    else
        echo "========================================"
        echo "FAIL: POST-INSTALLATION CHECK: ${failures} FAILURE(S)"
        echo "  Review errors above and re-run installation"
        echo "========================================"
        return 1
    fi
}
