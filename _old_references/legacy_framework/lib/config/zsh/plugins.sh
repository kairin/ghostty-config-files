#!/usr/bin/env bash
#
# lib/config/zsh/plugins.sh - ZSH plugin management
#
# Purpose: Install and configure Oh My ZSH plugins
# Dependencies: git
# Constitutional: Principle V - Modular Architecture (<300 lines)
#
# Functions:
#   - install_zsh_plugin(): Install single plugin from Git
#   - configure_zsh_plugins(): Install and configure all essential plugins
#   - update_plugin(): Update existing plugin
#   - get_plugin_status(): Check plugin installation status
#

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_LIB_CONFIG_ZSH_PLUGINS_SH:-}" ]] && return 0
readonly _LIB_CONFIG_ZSH_PLUGINS_SH=1

# Module constants
readonly ZSH_CUSTOM="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}"
readonly PLUGIN_DIR="${ZSH_CUSTOM}/plugins"

# Plugin repositories
readonly PLUGIN_REPOS=(
    "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions"
    "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting"
    "you-should-use|https://github.com/MichaelAquilina/zsh-you-should-use"
)

# ============================================================================
# PLUGIN INSTALLATION
# ============================================================================

# Function: install_zsh_plugin
# Purpose: Install ZSH plugin from Git repository
# Args:
#   $1 - Plugin name (e.g., "zsh-autosuggestions")
#   $2 - Repository URL
# Returns:
#   0 = success (installed or already exists), 1 = failure
install_zsh_plugin() {
    local plugin_name="$1"
    local repo_url="$2"
    local plugin_path="${PLUGIN_DIR}/${plugin_name}"

    # Check if already installed
    if [[ -d "$plugin_path" ]]; then
        echo "PASS: Plugin already installed: $plugin_name"
        return 0
    fi

    echo "Installing ZSH plugin: $plugin_name..."

    # Create plugins directory
    mkdir -p "$PLUGIN_DIR"

    # Clone plugin repository (shallow clone for speed)
    if git clone --depth 1 "$repo_url" "$plugin_path" 2>&1 | grep -v "^Cloning"; then
        echo "PASS: Plugin installed: $plugin_name"
        return 0
    else
        echo "FAIL: Failed to install plugin: $plugin_name" >&2
        return 1
    fi
}

# Function: update_plugin
# Purpose: Update existing ZSH plugin to latest version
# Args:
#   $1 - Plugin name
# Returns:
#   0 = success, 1 = failure
update_plugin() {
    local plugin_name="$1"
    local plugin_path="${PLUGIN_DIR}/${plugin_name}"

    if [[ ! -d "$plugin_path" ]]; then
        echo "WARN: Plugin not installed: $plugin_name"
        return 0
    fi

    echo "Updating plugin: $plugin_name..."

    if (cd "$plugin_path" && git pull origin master 2>&1 | grep -E "^(Already up to date|Updating|Fast-forward)"); then
        echo "PASS: Plugin updated: $plugin_name"
        return 0
    else
        echo "WARN: Plugin update may have failed: $plugin_name"
        return 0
    fi
}

# Function: get_plugin_status
# Purpose: Check installation status of a plugin
# Args:
#   $1 - Plugin name
# Returns:
#   Status string: "installed", "not_installed", "error"
get_plugin_status() {
    local plugin_name="$1"
    local plugin_path="${PLUGIN_DIR}/${plugin_name}"

    if [[ -d "$plugin_path" ]]; then
        if [[ -d "${plugin_path}/.git" ]]; then
            echo "installed"
        else
            echo "error"
        fi
    else
        echo "not_installed"
    fi
}

# ============================================================================
# BULK PLUGIN OPERATIONS
# ============================================================================

# Function: configure_zsh_plugins
# Purpose: Install and configure all essential ZSH plugins
# Args: None
# Returns:
#   0 = all plugins installed, 1 = some failures
install_essential_plugins() {
    local failures=0
    local installed=0
    local plugin_entry plugin_name plugin_repo

    echo "Installing essential ZSH plugins..."
    echo

    for plugin_entry in "${PLUGIN_REPOS[@]}"; do
        plugin_name="${plugin_entry%%|*}"
        plugin_repo="${plugin_entry##*|}"

        if install_zsh_plugin "$plugin_name" "$plugin_repo"; then
            ((installed++))
        else
            ((failures++))
        fi
    done

    echo
    echo "Plugin installation summary: $installed installed, $failures failed"

    [[ $failures -eq 0 ]]
}

# Function: update_all_plugins
# Purpose: Update all installed plugins to latest versions
# Args: None
# Returns:
#   0 = success, 1 = some failures
update_all_plugins() {
    local failures=0
    local updated=0
    local plugin_entry plugin_name

    echo "Updating all ZSH plugins..."
    echo

    for plugin_entry in "${PLUGIN_REPOS[@]}"; do
        plugin_name="${plugin_entry%%|*}"

        if update_plugin "$plugin_name"; then
            ((updated++))
        else
            ((failures++))
        fi
    done

    echo
    echo "Plugin update summary: $updated updated, $failures failed"

    [[ $failures -eq 0 ]]
}

# Function: get_all_plugin_status
# Purpose: Get installation status of all plugins
# Args: None
# Returns:
#   JSON-formatted status (stdout)
get_all_plugin_status() {
    local plugin_entry plugin_name status
    local json_output="{"
    local first=true

    for plugin_entry in "${PLUGIN_REPOS[@]}"; do
        plugin_name="${plugin_entry%%|*}"
        status=$(get_plugin_status "$plugin_name")

        [[ "$first" == "false" ]] && json_output+=","
        first=false

        json_output+="\"$plugin_name\":\"$status\""
    done

    json_output+="}"
    echo "$json_output"
}

# ============================================================================
# ZSHRC PLUGIN CONFIGURATION
# ============================================================================

# Function: get_plugins_string
# Purpose: Generate plugins string for .zshrc
# Args: None
# Returns:
#   Plugins configuration line (stdout)
get_plugins_string() {
    # Built-in plugins + custom plugins
    # Note: zsh-syntax-highlighting MUST be last for performance
    local built_in="git npm node docker docker-compose sudo history extract z"
    local custom="you-should-use zsh-autosuggestions zsh-syntax-highlighting"

    echo "plugins=($built_in $custom)"
}

# Function: update_zshrc_plugins
# Purpose: Update plugins line in .zshrc
# Args:
#   $1 - Path to .zshrc (default: ~/.zshrc)
# Returns:
#   0 = success, 1 = failure
update_zshrc_plugins() {
    local zshrc="${1:-${HOME}/.zshrc}"
    local plugins_string

    if [[ ! -f "$zshrc" ]]; then
        echo "FAIL: .zshrc not found: $zshrc" >&2
        return 1
    fi

    plugins_string=$(get_plugins_string)

    # Backup .zshrc
    cp "$zshrc" "${zshrc}.backup-$(date +%Y%m%d-%H%M%S)"

    # Update or add plugins line
    if grep -q "^plugins=" "$zshrc"; then
        sed -i "s/^plugins=.*/$plugins_string/" "$zshrc"
        echo "PASS: Updated plugins in $zshrc"
    else
        echo "" >> "$zshrc"
        echo "$plugins_string" >> "$zshrc"
        echo "PASS: Added plugins to $zshrc"
    fi

    return 0
}

# ============================================================================
# PLUGIN VERIFICATION
# ============================================================================

# Function: verify_plugins_installed
# Purpose: Verify all essential plugins are installed
# Args: None
# Returns:
#   0 = all installed, 1 = some missing
verify_plugins_installed() {
    local missing=0
    local plugin_entry plugin_name status

    echo "Verifying plugin installation..."

    for plugin_entry in "${PLUGIN_REPOS[@]}"; do
        plugin_name="${plugin_entry%%|*}"
        status=$(get_plugin_status "$plugin_name")

        if [[ "$status" == "installed" ]]; then
            echo "  PASS: $plugin_name"
        else
            echo "  FAIL: $plugin_name ($status)" >&2
            ((missing++))
        fi
    done

    if [[ $missing -eq 0 ]]; then
        echo "PASS: All essential plugins installed"
        return 0
    else
        echo "FAIL: $missing plugin(s) missing" >&2
        return 1
    fi
}
