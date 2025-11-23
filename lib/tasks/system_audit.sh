#!/usr/bin/env bash
#
# lib/tasks/system_audit.sh - Pre-installation system state audit
#
# Purpose: Display current system state before installation starts
# Shows: Installed apps, versions, paths, installation methods, upgrade recommendations
#
# Constitutional Compliance:
# - Principle V: Modular Architecture
# - User Stories: US1 (Fresh Installation visibility)
# - Zero sudo requirements (read-only audit)
#
# Output: Beautiful gum table showing:
# - App/Tool name
# - Current version (if installed)
# - Installation path
# - Installation method (apt/source/binary/npm/missing)
# - Latest available version
# - Recommended action (OK/UPGRADE/INSTALL)
#

set -euo pipefail

# Source required utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../core/logging.sh"
source "${SCRIPT_DIR}/../core/utils.sh"

#
# Detect app installation status
#
# Args:
#   $1 - App name (for display)
#   $2 - Command to check
#   $3 - Version extraction command
#   $4 - Expected version (from installer)
#
# Returns:
#   JSON: {"name":"gum","version":"0.14.5","path":"/usr/bin/gum","method":"apt","status":"ok"}
#
detect_app_status() {
    local app_name="$1"
    local command_name="$2"
    local version_cmd="$3"
    local expected_version="${4:-unknown}"

    local current_version="not installed"
    local install_path="N/A"
    local install_method="missing"
    local status="INSTALL"

    # Check if command exists
    if command_exists "$command_name"; then
        install_path=$(command -v "$command_name")

        # Extract version
        if [ -n "$version_cmd" ]; then
            current_version=$(eval "$version_cmd" 2>/dev/null || echo "unknown")
        fi

        # Detect installation method
        case "$install_path" in
            /usr/bin/*)
                # Check if apt-managed
                if dpkg -l "$command_name" 2>/dev/null | grep -q "^ii"; then
                    install_method="apt"
                else
                    install_method="binary"
                fi
                ;;
            /usr/local/bin/*)
                install_method="source"
                ;;
            "$HOME/.local/bin/"*)
                install_method="user-binary"
                ;;
            */node_modules/.bin/*)
                install_method="npm"
                ;;
            "$HOME/.cargo/bin/"*)
                install_method="cargo"
                ;;
            *)
                install_method="other"
                ;;
        esac

        # Determine status (OK or UPGRADE)
        if [ "$expected_version" != "unknown" ] && [ "$current_version" != "unknown" ]; then
            # Simple version comparison (assumes semantic versioning)
            if version_compare "$current_version" "$expected_version"; then
                status="OK"
            else
                status="UPGRADE"
            fi
        else
            status="OK"
        fi
    fi

    # Return as pipe-delimited (easier for gum table)
    echo "${app_name}|${current_version}|${install_path}|${install_method}|${expected_version}|${status}"
}

#
# Simple version comparison
#
# Args:
#   $1 - Current version
#   $2 - Expected version
#
# Returns:
#   0 if current >= expected, 1 otherwise
#
version_compare() {
    local current="$1"
    local expected="$2"

    # Remove 'v' prefix if present
    current="${current#v}"
    expected="${expected#v}"

    # Extract major.minor.patch
    local current_major current_minor current_patch
    current_major=$(echo "$current" | cut -d. -f1 | grep -oP '\d+' || echo "0")
    current_minor=$(echo "$current" | cut -d. -f2 | grep -oP '\d+' || echo "0")
    current_patch=$(echo "$current" | cut -d. -f3 | grep -oP '\d+' || echo "0")

    local expected_major expected_minor expected_patch
    expected_major=$(echo "$expected" | cut -d. -f1 | grep -oP '\d+' || echo "0")
    expected_minor=$(echo "$expected" | cut -d. -f2 | grep -oP '\d+' || echo "0")
    expected_patch=$(echo "$expected" | cut -d. -f3 | grep -oP '\d+' || echo "0")

    # Compare major.minor.patch
    if [ "$current_major" -gt "$expected_major" ]; then
        return 0
    elif [ "$current_major" -eq "$expected_major" ]; then
        if [ "$current_minor" -gt "$expected_minor" ]; then
            return 0
        elif [ "$current_minor" -eq "$expected_minor" ]; then
            if [ "$current_patch" -ge "$expected_patch" ]; then
                return 0
            fi
        fi
    fi

    return 1
}

#
# Display pre-installation system audit table
#
# Shows current state of all apps that will be installed
# Zero sudo requirements (read-only)
#
task_pre_installation_audit() {
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Pre-Installation System Audit"
    log "INFO" "════════════════════════════════════════"
    echo ""

    log "INFO" "Scanning current system state..."
    echo ""

    # Collect app statuses
    local -a audit_data

    # Gum TUI Framework
    audit_data+=("$(detect_app_status "Gum TUI" "gum" "gum --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+'" "0.14.5")")

    # Zig Compiler (Ghostty dependency)
    audit_data+=("$(detect_app_status "Zig Compiler" "zig" "zig version 2>&1 | grep -oP '\d+\.\d+\.\d+'" "0.13.0")")

    # Ghostty Terminal
    audit_data+=("$(detect_app_status "Ghostty Terminal" "ghostty" "ghostty --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+'" "1.1.4")")

    # ZSH
    audit_data+=("$(detect_app_status "ZSH Shell" "zsh" "zsh --version 2>&1 | head -n1 | grep -oP '\d+\.\d+'" "5.9")")

    # Oh My ZSH (check directory instead)
    if [ -d "$HOME/.oh-my-zsh" ]; then
        audit_data+=("Oh My ZSH|installed|$HOME/.oh-my-zsh|source|latest|OK")
    else
        audit_data+=("Oh My ZSH|not installed|N/A|missing|latest|INSTALL")
    fi

    # Python UV
    audit_data+=("$(detect_app_status "Python UV" "uv" "uv --version 2>&1 | grep -oP '\d+\.\d+\.\d+'" "0.5.0")")

    # fnm (Fast Node Manager)
    audit_data+=("$(detect_app_status "fnm" "fnm" "fnm --version 2>&1 | grep -oP '\d+\.\d+\.\d+'" "1.38.0")")

    # Node.js
    audit_data+=("$(detect_app_status "Node.js" "node" "node --version 2>&1 | grep -oP '\d+\.\d+\.\d+'" "25.2.0")")

    # npm
    audit_data+=("$(detect_app_status "npm" "npm" "npm --version 2>&1" "11.0.0")")

    # Claude CLI
    audit_data+=("$(detect_app_status "Claude CLI" "claude" "claude --version 2>&1 | head -n1" "latest")")

    # Gemini CLI
    audit_data+=("$(detect_app_status "Gemini CLI" "gemini" "gemini --version 2>&1 | head -n1" "latest")")

    # GitHub Copilot CLI
    audit_data+=("$(detect_app_status "Copilot CLI" "gh-copilot" "gh copilot --version 2>&1" "latest")")

    # Feh Image Viewer
    audit_data+=("$(detect_app_status "Feh Viewer" "feh" "feh --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+'" "3.11.0")")

    # Nautilus Context Menu (check script)
    if [ -f "$HOME/.local/share/nautilus/scripts/Open in Ghostty" ]; then
        audit_data+=("Context Menu|installed|~/.local/share/nautilus/scripts|source|latest|OK")
    else
        audit_data+=("Context Menu|not installed|N/A|missing|latest|INSTALL")
    fi

    # Display table using gum (if available) or fallback to plain text
    if command_exists "gum"; then
        log "INFO" "Current System State:"
        echo ""

        # Create table header
        local table_header="App/Tool|Current Version|Path|Method|Latest Version|Action"

        # Combine header + data
        {
            echo "$table_header"
            printf '%s\n' "${audit_data[@]}"
        } | gum table --separator "|" \
            --border rounded \
            --border.foreground "6" \
            --height 0 \
            --print

    else
        # Fallback: plain text table
        log "INFO" "Current System State (install gum for better formatting):"
        echo ""
        printf "%-20s %-20s %-35s %-15s %-18s %-10s\n" \
            "App/Tool" "Current Version" "Path" "Method" "Latest Version" "Action"
        printf "%-20s %-20s %-35s %-15s %-18s %-10s\n" \
            "--------------------" "--------------------" "-----------------------------------" "---------------" "------------------" "----------"

        for data in "${audit_data[@]}"; do
            IFS='|' read -r name version path method latest action <<< "$data"
            printf "%-20s %-20s %-35s %-15s %-18s %-10s\n" \
                "$name" "$version" "$path" "$method" "$latest" "$action"
        done
    fi

    echo ""

    # Summary statistics
    local total_apps="${#audit_data[@]}"
    local installed_count=0
    local upgrade_count=0
    local install_count=0

    for data in "${audit_data[@]}"; do
        IFS='|' read -r _ _ _ _ _ action <<< "$data"
        case "$action" in
            "OK") ((installed_count++)) ;;
            "UPGRADE") ((upgrade_count++)) ;;
            "INSTALL") ((install_count++)) ;;
        esac
    done

    log "INFO" "════════════════════════════════════════"
    log "INFO" "Summary"
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Total apps/tools: $total_apps"
    log "SUCCESS" "Already installed (OK): $installed_count"
    log "WARNING" "Will upgrade: $upgrade_count"
    log "INFO" "Will install: $install_count"
    echo ""

    # Installation method breakdown
    log "INFO" "Installation Methods Detected:"
    local method_apt=0 method_source=0 method_binary=0 method_npm=0 method_missing=0

    for data in "${audit_data[@]}"; do
        IFS='|' read -r _ _ _ method _ _ <<< "$data"
        case "$method" in
            "apt") ((method_apt++)) ;;
            "source") ((method_source++)) ;;
            "binary"|"user-binary") ((method_binary++)) ;;
            "npm") ((method_npm++)) ;;
            "missing") ((method_missing++)) ;;
        esac
    done

    [ "$method_apt" -gt 0 ] && log "INFO" "  - APT packages: $method_apt"
    [ "$method_source" -gt 0 ] && log "INFO" "  - Built from source: $method_source"
    [ "$method_binary" -gt 0 ] && log "INFO" "  - Binary installations: $method_binary"
    [ "$method_npm" -gt 0 ] && log "INFO" "  - NPM global packages: $method_npm"
    [ "$method_missing" -gt 0 ] && log "INFO" "  - Not installed: $method_missing"
    echo ""

    log "INFO" "════════════════════════════════════════"
    echo ""

    # Ask user to confirm before proceeding
    if command_exists "gum"; then
        log "INFO" "Ready to proceed with installation?"
        echo ""
        if gum confirm "Continue with installation?"; then
            log "SUCCESS" "User confirmed - proceeding with installation"
            return 0
        else
            log "WARNING" "User cancelled installation"
            return 1
        fi
    else
        # Fallback: simple read
        echo -n "Continue with installation? [Y/n] "
        read -r response
        if [[ "$response" =~ ^[Nn] ]]; then
            log "WARNING" "User cancelled installation"
            return 1
        fi
        log "SUCCESS" "User confirmed - proceeding with installation"
        return 0
    fi
}

# Export functions
export -f detect_app_status
export -f version_compare
export -f task_pre_installation_audit
