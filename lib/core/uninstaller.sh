#!/usr/bin/env bash
#
# lib/core/uninstaller.sh - Modular Uninstallation System
#
# Purpose: Safely remove existing tool installations before reinstalling
# Handles: apt, snap, npm, binary installations, source builds
#
# Constitutional Compliance: Clean removal before installation
#

set -euo pipefail

# Source guard
[ -z "${UNINSTALLER_SH_LOADED:-}" ] || return 0
UNINSTALLER_SH_LOADED=1

#
# Detect installation method for a tool
#
# Args:
#   $1 - Tool/binary name
#
# Returns:
#   Installation method: "apt", "snap", "npm", "binary", "source", "unknown"
#
detect_installation_method() {
    local tool_name="$1"

    # Check if tool exists
    if ! command -v "$tool_name" >/dev/null 2>&1; then
        echo "not_installed"
        return 0
    fi

    local tool_path
    tool_path=$(command -v "$tool_name")

    # Determine installation method by path
    case "$tool_path" in
        /usr/bin/*)
            # Check if installed via apt
            if dpkg -S "$tool_path" >/dev/null 2>&1; then
                echo "apt"
            else
                echo "binary"
            fi
            ;;
        /snap/bin/*)
            echo "snap"
            ;;
        */node_modules/* | */.npm-global/*)
            echo "npm"
            ;;
        "$HOME/.local/bin/"* | "$HOME/bin/"*)
            echo "binary"
            ;;
        /usr/local/bin/*)
            echo "source"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

#
# Uninstall a tool completely based on detected method
#
# Args:
#   $1 - Tool/binary name
#   $2 - Package name (optional, defaults to tool name)
#   $3 - Verbose mode (true/false, default false)
#
# Returns:
#   0 = success, 1 = failure
#
uninstall_tool() {
    local tool_name="$1"
    local package_name="${2:-$tool_name}"
    local verbose="${3:-false}"

    local install_method
    install_method=$(detect_installation_method "$tool_name")

    if [ "$install_method" = "not_installed" ]; then
        [ "$verbose" = true ] && log "INFO" "$tool_name not installed, skipping uninstall"
        return 0
    fi

    log "INFO" "Uninstalling $tool_name (method: $install_method)..."

    case "$install_method" in
        apt)
            if [ "$verbose" = true ]; then
                sudo apt-get remove -y "$package_name" 2>&1 | tee -a "$(get_log_file)"
            else
                sudo apt-get remove -y "$package_name" >/dev/null 2>&1
            fi
            log "SUCCESS" "✓ Removed $tool_name via apt"
            ;;

        snap)
            if [ "$verbose" = true ]; then
                sudo snap remove "$package_name" 2>&1 | tee -a "$(get_log_file)"
            else
                sudo snap remove "$package_name" >/dev/null 2>&1
            fi
            log "SUCCESS" "✓ Removed $tool_name via snap"
            ;;

        npm)
            if [ "$verbose" = true ]; then
                npm uninstall -g "$package_name" 2>&1 | tee -a "$(get_log_file)"
            else
                npm uninstall -g "$package_name" >/dev/null 2>&1
            fi
            log "SUCCESS" "✓ Removed $tool_name via npm"
            ;;

        binary)
            local tool_path
            tool_path=$(command -v "$tool_name")
            rm -f "$tool_path"
            log "SUCCESS" "✓ Removed $tool_name binary from $tool_path"
            ;;

        source)
            local tool_path
            tool_path=$(command -v "$tool_name")
            sudo rm -f "$tool_path"
            log "SUCCESS" "✓ Removed $tool_name (source build) from $tool_path"
            ;;

        unknown)
            log "WARNING" "Cannot determine installation method for $tool_name, skipping"
            return 1
            ;;
    esac

    return 0
}

#
# Uninstall tool with all known variants
#
# Args:
#   $1 - Tool name
#   $2 - Verbose mode (true/false)
#
# Handles:
#   - Multiple installation locations
#   - Different package names
#   - Snap + apt conflicts
#
uninstall_tool_complete() {
    local tool_name="$1"
    local verbose="${2:-false}"

    log "INFO" "Complete uninstall of $tool_name (checking all sources)..."

    # Check all possible installation methods
    local removed_any=false

    # 1. Check snap
    if snap list "$tool_name" >/dev/null 2>&1; then
        log "INFO" "  Removing $tool_name snap..."
        sudo snap remove "$tool_name" >/dev/null 2>&1 || true
        removed_any=true
    fi

    # 2. Check apt/dpkg
    if dpkg -l | grep -q "^ii.*$tool_name"; then
        log "INFO" "  Removing $tool_name apt package..."
        sudo apt-get remove -y "$tool_name" >/dev/null 2>&1 || true
        removed_any=true
    fi

    # 3. Check npm global
    if npm list -g "$tool_name" >/dev/null 2>&1; then
        log "INFO" "  Removing $tool_name npm package..."
        npm uninstall -g "$tool_name" >/dev/null 2>&1 || true
        removed_any=true
    fi

    # 4. Check common binary locations
    for bin_path in \
        "$HOME/.local/bin/$tool_name" \
        "$HOME/bin/$tool_name" \
        "/usr/local/bin/$tool_name" \
        "/opt/$tool_name/$tool_name"; do

        if [ -f "$bin_path" ]; then
            log "INFO" "  Removing binary: $bin_path"
            if [[ "$bin_path" == /usr/* ]] || [[ "$bin_path" == /opt/* ]]; then
                sudo rm -f "$bin_path" || true
            else
                rm -f "$bin_path" || true
            fi
            removed_any=true
        fi
    done

    if [ "$removed_any" = true ]; then
        log "SUCCESS" "✓ Complete uninstall of $tool_name finished"
    else
        log "INFO" "$tool_name was not installed"
    fi

    return 0
}

# Export functions
export -f detect_installation_method
export -f uninstall_tool
export -f uninstall_tool_complete
