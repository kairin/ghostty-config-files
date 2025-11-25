#!/usr/bin/env bash
# lib/updates/ghostty-specific.sh - Ghostty-specific update operations
# Extracted from scripts/updates/update_ghostty.sh for modularity

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_GHOSTTY_SPECIFIC_SOURCED:-}" ]] && return 0
readonly _GHOSTTY_SPECIFIC_SOURCED=1

#######################################
# Get Ghostty version from installed binary
# Outputs:
#   Version string or empty if not installed
# Returns:
#   0 always
#######################################
get_ghostty_version() {
    if command -v ghostty &> /dev/null; then
        local version_output
        version_output=$(ghostty --version 2>/dev/null | head -n 1 | awk '{print $NF}')
        if [[ -n "$version_output" ]]; then
            echo "$version_output"
        else
            echo ""
        fi
    else
        echo ""
    fi
}

#######################################
# Get step status message with emoji
# Arguments:
#   $1 - Step name
#   $2 - Status (start|progress|success|warning|error)
# Outputs:
#   Formatted status message
#######################################
get_step_status() {
    local step="$1"
    local status="$2"
    case "$status" in
        "start") echo "Starting: $step" ;;
        "progress") echo "In progress: $step" ;;
        "success") echo "Completed: $step" ;;
        "warning") echo "Warning in: $step" ;;
        "error") echo "Failed: $step" ;;
        *) echo "$step: $status" ;;
    esac
}

#######################################
# Get process details for logging
# Arguments:
#   $1 - Process name
#   $2 - Detail message
# Outputs:
#   Formatted process detail
#######################################
get_process_details() {
    local process="$1"
    local detail="$2"
    echo "   - $process: $detail"
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

#######################################
# Verify critical build tools are installed
# Arguments:
#   None
# Outputs:
#   Status messages for each tool
# Returns:
#   0 if all tools present, 1 if any missing
#######################################
verify_critical_build_tools() {
    local missing_critical=()
    local critical_tools=("zig" "pkg-config" "msgfmt" "gcc" "g++")

    echo ""
    echo "=================================="
    echo "     Pre-build System Verification"
    echo "=================================="
    echo "Final system check before building Ghostty..."

    for tool in "${critical_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_critical+=("$tool")
        fi
    done

    if [[ ${#missing_critical[@]} -ne 0 ]]; then
        echo "Critical build tools are missing: ${missing_critical[*]}"
        return 1
    fi

    echo "All critical build tools are available"
    return 0
}

#######################################
# Print manual installation instructions
# Outputs:
#   Instructions for installing missing dependencies
#######################################
print_dependency_instructions() {
    cat <<'EOF'

MANUAL INSTALLATION REQUIRED:
Please run the following commands manually to install missing dependencies:

# Update package lists
sudo apt update

# Install essential build tools and dependencies
sudo apt install -y \
  build-essential \
  pkg-config \
  gettext \
  libxml2-utils \
  pandoc \
  libgtk-4-dev \
  libadwaita-1-dev \
  blueprint-compiler \
  libgtk4-layer-shell-dev \
  libfreetype-dev \
  libharfbuzz-dev \
  libfontconfig-dev \
  libpng-dev \
  libbz2-dev \
  zlib1g-dev \
  libglib2.0-dev \
  libgio-2.0-dev \
  libpango1.0-dev \
  libgdk-pixbuf-2.0-dev \
  libcairo2-dev \
  libvulkan-dev \
  libgraphene-1.0-dev \
  libx11-dev \
  libwayland-dev \
  libonig-dev \
  libxml2-dev

# Verify tools are available
pkg-config --modversion gtk4
pkg-config --modversion libadwaita-1

After installing dependencies, re-run this script.
EOF
}

#######################################
# Verify GTK4 and libadwaita via pkg-config
# Returns:
#   0 if both are available, 1 otherwise
#######################################
verify_gtk4_libadwaita() {
    if pkg-config --exists gtk4 && pkg-config --exists libadwaita-1; then
        local gtk4_version adwaita_version
        gtk4_version=$(pkg-config --modversion gtk4 2>/dev/null || echo "unknown")
        adwaita_version=$(pkg-config --modversion libadwaita-1 2>/dev/null || echo "unknown")
        echo "GTK4 version: $gtk4_version"
        echo "libadwaita version: $adwaita_version"
        return 0
    fi

    echo "GTK4 or libadwaita not properly installed or configured"
    echo "This may cause build failures. Please ensure the development packages are installed."
    return 1
}

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
# Build Ghostty from source
# Arguments:
#   $1 - Source directory (optional, defaults to ~/Apps/ghostty)
# Returns:
#   0 on success, 1 on failure
#######################################
build_ghostty() {
    local source_dir="${1:-$HOME/Apps/ghostty}"

    echo ""
    echo "-> Building Ghostty..."

    cd "$source_dir" || {
        echo "Error: Ghostty application directory not found at $source_dir"
        return 1
    }

    if ! DESTDIR=/tmp/ghostty zig build --prefix /usr -Doptimize=ReleaseFast -Dcpu=baseline; then
        echo "Error: Ghostty build failed."
        return 1
    fi

    echo "Ghostty build completed successfully"
    return 0
}

#######################################
# Install Ghostty from build output
# Returns:
#   0 on success, 1 on failure
#######################################
install_ghostty() {
    echo ""
    echo "-> Installing Ghostty..."

    if ! sudo cp -r /tmp/ghostty/usr/* /usr/; then
        echo "Error: Ghostty installation failed."
        return 1
    fi

    echo "Ghostty installation completed successfully"
    return 0
}

#######################################
# Print Ghostty update summary
# Arguments:
#   $1 - Old version
#   $2 - New version
#   $3 - Config updated flag (true/false)
#   $4 - App updated flag (true/false)
#######################################
print_update_summary() {
    local old_version="$1"
    local new_version="$2"
    local config_updated="$3"
    local app_updated="$4"

    echo "======================================="
    echo "         Ghostty Update Summary"
    echo "======================================="

    if [[ "$config_updated" == "true" ]]; then
        echo "Ghostty config: Updated"
    else
        echo "Ghostty config: Already up to date"
    fi

    if [[ "$app_updated" == "true" ]]; then
        echo "Ghostty app: Updated to version $new_version"
    elif [[ -n "$new_version" ]]; then
        echo "Ghostty app: Already at version $new_version"
    else
        echo "Ghostty app: Not found or not updated"
    fi

    if [[ -z "$old_version" ]] && [[ -z "$new_version" ]]; then
        echo "Overall Status: Failed (Ghostty not found)"
    elif [[ "$config_updated" == "true" ]] || [[ "$app_updated" == "true" ]]; then
        echo "Overall Status: Success (Updates applied)"
    else
        echo "Overall Status: Already up to date"
    fi
    echo "======================================="
}

# Export functions for use by main script
export -f get_ghostty_version get_step_status get_process_details
export -f backup_ghostty_config restore_ghostty_config
export -f test_ghostty_config attempt_config_fix
export -f verify_critical_build_tools print_dependency_instructions
export -f verify_gtk4_libadwaita kill_ghostty_processes
export -f build_ghostty install_ghostty print_update_summary
