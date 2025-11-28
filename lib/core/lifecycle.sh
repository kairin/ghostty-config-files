#!/usr/bin/env bash
#
# lib/core/lifecycle.sh - Unified install/upgrade lifecycle management
#
# Purpose: Bridge between installation and update paths
#   - Ensures components are both installed AND up-to-date
#   - Single entry point for "make sure X is ready to use"
#   - Constitutional compliance: enhances existing scripts, doesn't create wrappers
#
# Usage:
#   lifecycle_ensure "claude" verify_claude_installed install_claude upgrade_claude
#
# Return codes:
#   0 = Action taken (installed or upgraded)
#   1 = Error occurred
#   2 = Already current (no action needed)
#

set -euo pipefail

# Source guard - prevent redundant loading
[ -z "${LIFECYCLE_SH_LOADED:-}" ] || return 0
LIFECYCLE_SH_LOADED=1

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/logging.sh"
source "${SCRIPT_DIR}/utils.sh"
source "${SCRIPT_DIR}/version-intelligence.sh"

# ============================================================================
# COMPONENT REGISTRY
# ============================================================================
# Maps component names to their version check commands and upgrade commands
# Format: "check_cmd|upgrade_cmd|package_name"

declare -gA LIFECYCLE_REGISTRY=(
    # npm packages (global)
    ["claude"]="npm list -g @anthropic-ai/claude-code|npm update -g @anthropic-ai/claude-code|@anthropic-ai/claude-code"
    ["gemini"]="npm list -g @google/gemini-cli|npm update -g @google/gemini-cli|@google/gemini-cli"
    ["copilot"]="npm list -g @github/copilot|npm update -g @github/copilot|@github/copilot"
    ["npm"]="npm --version|npm install -g npm@latest|npm"

    # curl/web tools
    ["fnm"]="fnm --version|curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell|fnm"
    ["node"]="node --version|fnm install --latest && fnm use --install-if-missing latest|node"
    ["uv"]="uv --version|curl -LsSf https://astral.sh/uv/install.sh | sh|uv"
    ["ohmyzsh"]="test -d ~/.oh-my-zsh|cd ~/.oh-my-zsh && git pull|oh-my-zsh"

    # go-built tools
    ["gum"]="gum --version|go install github.com/charmbracelet/gum@latest|gum"

    # apt packages
    ["glow"]="glow --version|sudo apt-get update && sudo apt-get install -y glow|glow"
    ["vhs"]="vhs --version|sudo apt-get update && sudo apt-get install -y vhs|vhs"
    ["fastfetch"]="fastfetch --version|sudo apt-get update && sudo apt-get install -y fastfetch|fastfetch"
)

# ============================================================================
# CORE LIFECYCLE FUNCTIONS
# ============================================================================

#
# Main lifecycle function: ensure component is installed AND up-to-date
#
# Args:
#   $1 - Component name (key in LIFECYCLE_REGISTRY or custom)
#   $2 - Verify function (optional, uses registry if not provided)
#   $3 - Install function (optional, uses registry if not provided)
#   $4 - Upgrade function (optional, uses registry if not provided)
#
# Returns:
#   0 = Action taken (installed or upgraded)
#   1 = Error occurred
#   2 = Already current (no action needed)
#
lifecycle_ensure() {
    local component="$1"
    local verify_fn="${2:-}"
    local install_fn="${3:-}"
    local upgrade_fn="${4:-}"

    local timestamp
    timestamp=$(date "+%H:%M:%S")

    log "INFO" "[$timestamp] Checking $component..."

    # Use custom functions if provided, otherwise use registry
    local is_installed=false

    if [ -n "$verify_fn" ] && declare -f "$verify_fn" &>/dev/null; then
        # Custom verify function provided
        if $verify_fn 2>/dev/null; then
            is_installed=true
        fi
    elif [ -n "${LIFECYCLE_REGISTRY[$component]:-}" ]; then
        # Use registry check command
        local check_cmd
        check_cmd=$(echo "${LIFECYCLE_REGISTRY[$component]}" | cut -d'|' -f1)
        if eval "$check_cmd" &>/dev/null; then
            is_installed=true
        fi
    else
        log "WARNING" "[$timestamp] No verification method for $component"
        return 1
    fi

    # Not installed → install
    if [ "$is_installed" = false ]; then
        log "INFO" "[$timestamp] → Installing $component..."

        if [ -n "$install_fn" ] && declare -f "$install_fn" &>/dev/null; then
            if $install_fn; then
                log "SUCCESS" "[$timestamp] ✓ $component installed"
                return 0
            else
                log "ERROR" "[$timestamp] ✗ $component installation failed"
                return 1
            fi
        else
            log "WARNING" "[$timestamp] No installation method for $component"
            return 1
        fi
    fi

    # Installed → check for upgrade
    if lifecycle_is_outdated "$component"; then
        log "INFO" "[$timestamp] → Upgrading $component..."

        if [ -n "$upgrade_fn" ] && declare -f "$upgrade_fn" &>/dev/null; then
            if $upgrade_fn; then
                log "SUCCESS" "[$timestamp] ✓ $component upgraded"
                return 0
            fi
        elif [ -n "${LIFECYCLE_REGISTRY[$component]:-}" ]; then
            local upgrade_cmd
            upgrade_cmd=$(echo "${LIFECYCLE_REGISTRY[$component]}" | cut -d'|' -f2)
            if eval "$upgrade_cmd" &>/dev/null; then
                log "SUCCESS" "[$timestamp] ✓ $component upgraded"
                return 0
            fi
        fi

        log "WARNING" "[$timestamp] ⚠ $component upgrade had issues"
        return 1
    fi

    log "INFO" "[$timestamp] ↷ $component already current"
    return 2  # Already current
}

#
# Check if component is outdated
#
# Args:
#   $1 - Component name
#
# Returns:
#   0 = Outdated (needs upgrade)
#   1 = Current (no upgrade needed)
#
lifecycle_is_outdated() {
    local component="$1"

    # Different strategies based on component type
    case "$component" in
        # npm packages - check npm outdated
        claude|gemini|copilot|npm)
            local pkg_name
            pkg_name=$(echo "${LIFECYCLE_REGISTRY[$component]:-}" | cut -d'|' -f3)
            if [ -n "$pkg_name" ]; then
                # npm outdated returns 1 if packages are outdated
                if npm outdated -g "$pkg_name" 2>/dev/null | grep -q "$pkg_name"; then
                    return 0  # Outdated
                fi
            fi
            return 1  # Current
            ;;

        # fnm/node - check if newer version available
        fnm|node)
            # For now, assume always current unless explicitly checked
            # Future: could check against latest release
            return 1
            ;;

        # curl tools - hard to check, assume current
        uv|ohmyzsh)
            return 1
            ;;

        # go tools - could check GitHub releases
        gum)
            # For now, assume current
            return 1
            ;;

        # apt packages - check apt policy
        glow|vhs|fastfetch)
            local pkg_name
            pkg_name=$(echo "${LIFECYCLE_REGISTRY[$component]:-}" | cut -d'|' -f3)
            if [ -n "$pkg_name" ]; then
                # Check if installed version < candidate version
                local installed candidate
                installed=$(apt-cache policy "$pkg_name" 2>/dev/null | grep 'Installed:' | awk '{print $2}')
                candidate=$(apt-cache policy "$pkg_name" 2>/dev/null | grep 'Candidate:' | awk '{print $2}')

                if [ -n "$installed" ] && [ -n "$candidate" ] && [ "$installed" != "$candidate" ]; then
                    return 0  # Outdated
                fi
            fi
            return 1  # Current
            ;;

        *)
            # Unknown component - assume current
            return 1
            ;;
    esac
}

#
# Get component status summary
#
# Args:
#   $1 - Component name
#
# Returns:
#   JSON status object
#
lifecycle_status() {
    local component="$1"

    local is_installed="false"
    local is_outdated="false"
    local current_version="N/A"

    # Check installation
    if [ -n "${LIFECYCLE_REGISTRY[$component]:-}" ]; then
        local check_cmd
        check_cmd=$(echo "${LIFECYCLE_REGISTRY[$component]}" | cut -d'|' -f1)
        if eval "$check_cmd" &>/dev/null; then
            is_installed="true"
            current_version=$(eval "$check_cmd" 2>/dev/null | grep -oP 'v?\d+\.\d+(\.\d+)?' | head -1 || echo "installed")
        fi
    fi

    # Check if outdated
    if [ "$is_installed" = "true" ] && lifecycle_is_outdated "$component"; then
        is_outdated="true"
    fi

    cat <<EOF
{
  "component": "$component",
  "installed": $is_installed,
  "outdated": $is_outdated,
  "version": "$current_version"
}
EOF
}

#
# Batch lifecycle ensure for multiple components
#
# Args:
#   $@ - List of component names
#
# Returns:
#   Number of components that needed action
#
lifecycle_ensure_all() {
    local components=("$@")
    local actions_taken=0

    for component in "${components[@]}"; do
        lifecycle_ensure "$component"
        local result=$?

        if [ $result -eq 0 ]; then
            ((actions_taken++))
        fi
    done

    echo "$actions_taken"
}

# ============================================================================
# EXPORTS
# ============================================================================

export -f lifecycle_ensure
export -f lifecycle_is_outdated
export -f lifecycle_status
export -f lifecycle_ensure_all
