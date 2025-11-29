#!/usr/bin/env bash
# lib/updates/ghostty/install.sh - Ghostty installation operations
# Extracted from lib/updates/ghostty-specific.sh for modularity

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_GHOSTTY_INSTALL_SOURCED:-}" ]] && return 0
readonly _GHOSTTY_INSTALL_SOURCED=1

#######################################
# Kill running Ghostty processes holding the binary
# Returns:
#   0 always (best effort)
#######################################
kill_ghostty_processes() {
    echo ""
    echo "-> Checking for running Ghostty processes holding /usr/bin/ghostty..."

    local ghostty_pids
    ghostty_pids=$(sudo lsof -t /usr/bin/ghostty 2>/dev/null || true)

    if [[ -n "$ghostty_pids" ]]; then
        local pid_list
        pid_list=$(echo "$ghostty_pids" | tr '\n' ' ')
        echo ""
        echo "-> Found Ghostty process(es) (PIDs: $pid_list) holding /usr/bin/ghostty. Terminating..."
        for pid in $ghostty_pids; do
            sudo kill -9 "$pid" 2>/dev/null || true
        done
        sleep 1
    else
        echo ""
        echo "-> No Ghostty process found holding /usr/bin/ghostty."
    fi
}

#######################################
# Install Ghostty from build output
# Arguments:
#   $1 - Build output directory (optional, defaults to /tmp/ghostty)
# Returns:
#   0 on success, 1 on failure
#######################################
install_ghostty() {
    local build_dir="${1:-/tmp/ghostty}"

    echo ""
    echo "-> Installing Ghostty..."

    if [[ ! -d "$build_dir/usr" ]]; then
        echo "Error: Build output not found at $build_dir/usr"
        return 1
    fi

    if ! sudo cp -r "$build_dir/usr/"* /usr/; then
        echo "Error: Ghostty installation failed."
        return 1
    fi

    echo "Ghostty installation completed successfully"
    return 0
}

#######################################
# Verify Ghostty installation
# Returns:
#   0 if verified, 1 otherwise
#######################################
verify_ghostty_installation() {
    if ! command -v ghostty &>/dev/null; then
        echo "Error: Ghostty binary not found in PATH after installation"
        return 1
    fi

    local version
    version=$(ghostty --version 2>/dev/null | head -n1 || echo "unknown")
    echo "Ghostty installed successfully: $version"
    return 0
}

#######################################
# Update desktop database after installation
# Returns:
#   0 on success
#######################################
update_desktop_database() {
    echo "-> Updating desktop database..."

    if command -v update-desktop-database &>/dev/null; then
        sudo update-desktop-database /usr/share/applications 2>/dev/null || true
    fi

    if command -v gtk-update-icon-cache &>/dev/null; then
        sudo gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
    fi

    echo "Desktop database updated"
    return 0
}

#######################################
# Backup Ghostty configuration files
# Arguments:
#   $1 - Source directory
#   $2 - Backup directory (optional, defaults to /tmp/ghostty-config-backup-TIMESTAMP)
# Returns:
#   0 on success, 1 on failure
#######################################
backup_ghostty_config() {
    local source_dir="${1:-.}"
    local backup_dir="${2:-/tmp/ghostty-config-backup-$(date +%s)}"

    mkdir -p "$backup_dir"
    echo "-> Backing up current config to $backup_dir"

    cp "$source_dir/config" "$backup_dir/" 2>/dev/null || true
    cp "$source_dir/theme.conf" "$backup_dir/" 2>/dev/null || true

    if [[ ! -f "$backup_dir/config" ]] && [[ ! -f "$backup_dir/theme.conf" ]]; then
        echo "Warning: Some config files may not exist"
        return 1
    fi

    echo "$backup_dir"
    return 0
}

#######################################
# Restore Ghostty configuration from backup
# Arguments:
#   $1 - Backup directory
#   $2 - Target directory (optional, defaults to current directory)
# Returns:
#   0 on success, 1 on failure
#######################################
restore_ghostty_config() {
    local backup_dir="$1"
    local target_dir="${2:-.}"

    if [[ ! -d "$backup_dir" ]]; then
        echo "ERROR: Backup directory does not exist: $backup_dir"
        return 1
    fi

    cp "$backup_dir/config" "$target_dir/config" 2>/dev/null && echo "-> Restored config file"
    cp "$backup_dir/theme.conf" "$target_dir/theme.conf" 2>/dev/null && echo "-> Restored theme.conf file"

    return 0
}

#######################################
# Test Ghostty configuration for errors
# Arguments:
#   $1 - Config test error log file (optional)
# Returns:
#   0 if config is valid, 1 if errors found
#######################################
test_ghostty_config() {
    local error_log="${1:-config_test_errors.log}"

    echo "-> Testing Ghostty configuration for errors..."
    if ghostty +show-config >/dev/null 2>"$error_log"; then
        echo "Configuration test passed"
        rm -f "$error_log"
        return 0
    else
        echo "Configuration test failed"
        cat "$error_log"
        return 1
    fi
}

#######################################
# Attempt automatic configuration cleanup
# Arguments:
#   $1 - Backup directory for restoration on failure
# Returns:
#   0 on success, 1 on failure
#######################################
attempt_config_fix() {
    local backup_dir="${1:-}"

    if [[ -x "scripts/fix_config.sh" ]]; then
        echo "-> Running automatic configuration cleanup..."
        if scripts/fix_config.sh; then
            echo "-> Automatic cleanup completed, re-testing configuration..."
            if ghostty +show-config >/dev/null 2>&1; then
                echo "Configuration fixed automatically"
                rm -f config_test_errors.log
                return 0
            fi
        fi
    fi

    echo "Automatic cleanup failed or not available"
    if [[ -n "$backup_dir" ]] && [[ -d "$backup_dir" ]]; then
        echo "-> Restoring backup..."
        restore_ghostty_config "$backup_dir"
    fi

    return 1
}

# Export functions
export -f kill_ghostty_processes install_ghostty
export -f verify_ghostty_installation update_desktop_database
export -f backup_ghostty_config restore_ghostty_config
export -f test_ghostty_config attempt_config_fix
