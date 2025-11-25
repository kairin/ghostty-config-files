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
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${SCRIPT_DIR}/../core/logging.sh"
source "${SCRIPT_DIR}/../core/utils.sh"

# Source audit modules
source "${REPO_ROOT}/lib/audit/detectors.sh"
source "${REPO_ROOT}/lib/audit/report.sh"

#
# Detect Snap package status for audit table
#
# Args:
#   $1 - Display name (e.g., "Ghostty Terminal")
#   $2 - Snap package name (e.g., "ghostty")
#   $3 - Minimum required version (typically "latest" or specific version)
#
# Returns:
#   Pipe-delimited string: "Name|Version|Path|Method|MinReq|AptAvail|SnapLatest|Status"
#
detect_snap_package_status() {
    local display_name="$1"
    local snap_package="$2"
    local min_required="${3:-latest}"

    local installed_version="not installed"
    local install_path="N/A"
    local install_method="missing"
    local snap_latest="N/A"
    local status="INSTALL"

    # Check if snap is installed
    if ! command_exists "snap"; then
        # Snap not available on system
        echo "${display_name}|${installed_version}|${install_path}|${install_method}|${min_required}|N/A|${snap_latest}|${status}"
        return 0
    fi

    # Check if package is installed
    if snap list "$snap_package" >/dev/null 2>&1; then
        # Get installed version
        installed_version=$(snap list "$snap_package" 2>/dev/null | awk 'NR==2 {print $2}' || echo "unknown")
        install_path="/snap/bin/$snap_package"
        install_method="snap"

        # Determine status
        if [ "$installed_version" != "unknown" ]; then
            status="OK"
        fi
    fi

    # Try to get latest version from snap store
    if snap info "$snap_package" >/dev/null 2>&1; then
        snap_latest=$(snap info "$snap_package" 2>/dev/null | grep -oP 'latest/stable:\s+\K[\d.]+' | head -1 || echo "N/A")
    fi

    # Format: Name|Version|Path|Method|MinReq|AptAvail|SnapLatest|Status
    echo "${display_name}|${installed_version}|${install_path}|${install_method}|${min_required}|N/A|${snap_latest}|${status}"
}

#
# Display pre-installation system audit table (enhanced with version analysis)
#
# Shows current state of all apps that will be installed
# Zero sudo requirements (read-only)
#
task_pre_installation_audit() {
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Pre-Installation System Audit (Enhanced)"
    log "INFO" "════════════════════════════════════════"
    echo ""

    # Display system information using fastfetch (if available)
    if command_exists "fastfetch"; then
        log "INFO" "System Information:"
        echo ""

        # Use Python script to format fastfetch output into a table
        # Note: We use REPO_ROOT/lib/tasks because SCRIPT_DIR might be overridden by start.sh
        local table_script="${REPO_ROOT}/lib/tasks/fastfetch_table.py"
        if [ -f "$table_script" ]; then
            if command_exists "gum"; then
                "$table_script" | gum table --border rounded --border.foreground 6 --widths 15,20,45 --height 0 --print --separator "|"
            else
                "$table_script"
            fi
        else
            # Fallback: Run fastfetch with minimal output (key system info only)
            if command_exists "gum"; then
                # Beautiful bordered output with gum
                fastfetch --pipe --logo none --structure Title:Separator:OS:Host:Kernel:Uptime:Packages:Shell:CPU:GPU:Memory:Disk:PhysicalDisk --physicaldisk-temp true 2>/dev/null | \
                    gum style --border rounded --border-foreground 6 --padding "0 1" --width 80 || \
                    fastfetch --logo none --structure Title:Separator:OS:Host:Kernel:Uptime:Packages:Shell:CPU:GPU:Memory:Disk:PhysicalDisk --physicaldisk-temp true 2>/dev/null
            else
                # Plain output without gum
                fastfetch --logo none --structure Title:Separator:OS:Host:Kernel:Uptime:Packages:Shell:CPU:GPU:Memory:Disk:PhysicalDisk --physicaldisk-temp true 2>/dev/null
            fi
        fi
        echo ""
    fi

    log "INFO" "Scanning current system state..."
    echo ""

    # Initialize version cache
    init_version_cache

    # Collect app statuses with enhanced version tracking
    local -a audit_data

    # Note: Enhanced format includes APT and source versions
    # Format: name|current|path|method|min_required|apt_avail|source_latest|status

    # fastfetch System Info Tool
    audit_data+=("$(detect_app_status_enhanced "fastfetch" "fastfetch" "fastfetch --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+'" "2.0.0" "fastfetch" "fastfetch")")

    # Go Programming Language
    audit_data+=("$(detect_app_status_enhanced "Go Language" "go" "go version 2>&1 | grep -oP 'go\K[\d.]+'" "latest" "none" "go")")

    # Gum TUI Framework (built from source)
    audit_data+=("$(detect_app_status_enhanced "Gum TUI" "gum" "gum --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo 'built-from-source'" "latest" "gum" "gum")")

    # Ghostty Terminal (.deb package)
    audit_data+=("$(detect_app_status_enhanced "Ghostty Terminal" "ghostty" "ghostty --version 2>&1 | head -n1 | awk '{print \$2}'" "latest" "ghostty" "ghostty")")

    # ZSH
    audit_data+=("$(detect_app_status_enhanced "ZSH Shell" "zsh" "zsh --version 2>&1 | head -n1 | grep -oP '\d+\.\d+'" "5.9" "zsh" "none")")

    # Oh My ZSH (check directory instead) - enhanced format manually
    audit_data+=("$(detect_omz_status)")

    # Python UV
    audit_data+=("$(detect_app_status_enhanced "Python UV" "uv" "uv --version 2>&1 | grep -oP '\d+\.\d+\.\d+'" "latest" "none" "uv")")

    # fnm (Fast Node Manager)
    audit_data+=("$(detect_app_status_enhanced "fnm" "fnm" "fnm --version 2>&1 | grep -oP '\d+\.\d+\.\d+'" "latest" "none" "fnm")")

    # Node.js
    audit_data+=("$(detect_app_status_enhanced "Node.js" "node" "node --version 2>&1 | grep -oP '\d+\.\d+\.\d+'" "latest" "nodejs" "node")")

    # npm
    # Use detect_npm_package_status to get latest version from registry
    audit_data+=("$(detect_npm_package_status "npm" "npm" "npm" "latest")")

    # Claude CLI (npm global package: @anthropic-ai/claude-code)
    audit_data+=("$(detect_npm_package_status "Claude CLI" "@anthropic-ai/claude-code" "claude" "latest")")

    # Gemini CLI (npm global package: @google/gemini-cli)
    audit_data+=("$(detect_npm_package_status "Gemini CLI" "@google/gemini-cli" "gemini" "latest")")

    # GitHub Copilot CLI (npm global package: @github/copilot)
    # Command is 'copilot' NOT 'github-copilot-cli'
    audit_data+=("$(detect_npm_package_status "Copilot CLI" "@github/copilot" "copilot" "latest")")

    # Feh Image Viewer
    audit_data+=("$(detect_app_status_enhanced "Feh Viewer" "feh" "feh --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+'" "3.11.0" "feh" "feh")")

    # Glow Markdown Viewer
    audit_data+=("$(detect_app_status_enhanced "Glow Markdown" "glow" "glow --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+'" "2.0.0" "glow" "glow")")

    # VHS Terminal Recorder
    audit_data+=("$(detect_app_status_enhanced "VHS Recorder" "vhs" "vhs --version 2>&1 | grep -oP '\d+\.\d+\.\d+'" "0.7.0" "vhs" "vhs")")

    # asciinema Terminal Recorder
    audit_data+=("$(detect_app_status_enhanced "asciinema" "asciinema" "asciinema --version 2>&1 | grep -oP '\d+\.\d+'" "2.0" "asciinema" "asciinema")")

    # script command (util-linux - always available on Linux)
    audit_data+=("$(detect_app_status_enhanced "script (util-linux)" "script" "script --version 2>&1 | grep -oP 'util-linux \K[\d.]+'" "2.0" "util-linux" "none")")

    # ffmpeg (VHS dependency - no GitHub releases support)
    audit_data+=("$(detect_app_status_enhanced "ffmpeg" "ffmpeg" "ffmpeg -version 2>&1 | head -n1 | grep -oP 'version \K[\d.]+'" "4.0" "ffmpeg" "none")")

    # ttyd (VHS dependency)
    audit_data+=("$(detect_app_status_enhanced "ttyd" "ttyd" "ttyd --version 2>&1 | grep -oP '\d+\.\d+\.\d+'" "1.7.0" "ttyd" "ttyd")")

    # Nautilus Context Menu (check script) - enhanced format manually
    if [ -f "$HOME/.local/share/nautilus/scripts/Open in Ghostty" ]; then
        audit_data+=("Context Menu|installed|~/.local/share/nautilus/scripts|source|latest|N/A|N/A|OK")
    else
        audit_data+=("Context Menu|not installed|N/A|missing|latest|N/A|N/A|INSTALL")
    fi

    # Summary statistics (displayed first, then grouped table)
    local total_apps="${#audit_data[@]}"
    local installed_count=0
    local upgrade_count=0
    local install_count=0

    for data in "${audit_data[@]}"; do
        IFS='|' read -r _ _ _ _ _ _ _ action <<< "$data"
        case "$action" in
            "OK") ((installed_count++)) ;;
            "UPGRADE") ((upgrade_count++)) ;;
            "INSTALL") ((install_count++)) ;;
        esac
    done

    log "INFO" "════════════════════════════════════════"
    log "INFO" "System Audit Summary"
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Total apps/tools: $total_apps"
    log "SUCCESS" "Already installed (OK): $installed_count"
    log "WARNING" "Will upgrade: $upgrade_count"
    log "INFO" "Will install: $install_count"
    echo ""

    # Display tools grouped by installation strategy (CONSOLIDATED TABLE - only one shown)
    display_installation_strategy_groups "${audit_data[@]}"

    # Generate markdown report and save to logs (detailed analysis saved to file)
    generate_markdown_report "${audit_data[@]}"

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

#
# Post-Installation Verification (Same audit as pre-install, but without confirmation)
#
# Purpose: Show final system state after installation completes
# Compare with pre-installation state to verify all tasks completed successfully
#
# Returns:
#   0 - Always succeeds (verification only, no confirmation needed)
#
task_post_installation_verification() {
    log "INFO" "Scanning final system state..."
    echo ""

    # Initialize version cache
    init_version_cache

    # Build audit data (same as pre-installation)
    local -a audit_data

    # Go Programming Language
    audit_data+=("$(detect_app_status_enhanced "Go Language" "go" "go version 2>&1 | grep -oP 'go\K[\d.]+'" "latest" "none" "go")")

    # Gum TUI Framework
    audit_data+=("$(detect_app_status_enhanced "Gum TUI" "gum" "gum --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo 'built-from-source'" "latest" "gum" "gum")")

    # Ghostty Terminal (.deb package)
    audit_data+=("$(detect_app_status_enhanced "Ghostty Terminal" "ghostty" "ghostty --version 2>&1 | head -n1 | awk '{print \$2}'" "latest" "ghostty" "ghostty")")

    # ZSH Shell
    audit_data+=("$(detect_app_status_enhanced "ZSH Shell" "zsh" "zsh --version 2>&1 | grep -oP '\d+\.\d+'" "5.9" "zsh" "none")")

    # Oh My ZSH
    audit_data+=("$(detect_omz_status)")

    # Python UV
    audit_data+=("$(detect_app_status_enhanced "Python UV" "uv" "uv --version 2>&1 | grep -oP '\d+\.\d+\.\d+'" "latest" "none" "uv")")

    # fnm (Fast Node Manager)
    audit_data+=("$(detect_app_status_enhanced "fnm" "fnm" "fnm --version 2>&1 | grep -oP '\d+\.\d+\.\d+'" "latest" "none" "fnm")")

    # Node.js
    audit_data+=("$(detect_app_status_enhanced "Node.js" "node" "node --version 2>&1 | grep -oP '\d+\.\d+\.\d+'" "latest" "nodejs" "node")")

    # npm
    audit_data+=("$(detect_npm_package_status "npm" "npm" "npm" "latest")")

    # Claude CLI (npm global package: @anthropic-ai/claude-code)
    audit_data+=("$(detect_npm_package_status "Claude CLI" "@anthropic-ai/claude-code" "claude" "latest")")

    # Gemini CLI (npm global package: @google/gemini-cli)
    audit_data+=("$(detect_npm_package_status "Gemini CLI" "@google/gemini-cli" "gemini" "latest")")

    # GitHub Copilot CLI (npm global package: @github/copilot)
    # Command is 'copilot' NOT 'github-copilot-cli'
    audit_data+=("$(detect_npm_package_status "Copilot CLI" "@github/copilot" "copilot" "latest")")

    # Feh Image Viewer
    audit_data+=("$(detect_app_status_enhanced "Feh Viewer" "feh" "feh --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+'" "3.11.0" "feh" "feh")")

    # Glow Markdown Viewer
    audit_data+=("$(detect_app_status_enhanced "Glow Markdown" "glow" "glow --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+'" "2.0.0" "glow" "glow")")

    # VHS Terminal Recorder
    audit_data+=("$(detect_app_status_enhanced "VHS Recorder" "vhs" "vhs --version 2>&1 | grep -oP '\d+\.\d+\.\d+'" "0.7.0" "vhs" "vhs")")

    # ffmpeg (VHS dependency - no GitHub releases support)
    audit_data+=("$(detect_app_status_enhanced "ffmpeg" "ffmpeg" "ffmpeg -version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+'" "4.0" "ffmpeg" "none")")

    # ttyd (VHS dependency)
    audit_data+=("$(detect_app_status_enhanced "ttyd" "ttyd" "ttyd --version 2>&1 | grep -oP '\d+\.\d+\.\d+'" "1.7.0" "ttyd" "ttyd")")

    # Context Menu Integration
    audit_data+=("$(detect_app_status_enhanced "Context Menu" "nautilus-scripts" "[ -d ~/.local/share/nautilus/scripts ] && echo 'installed' || echo 'not installed'" "latest" "none" "none")")

    # Display final system state table
    log "INFO" "Final System State:"
    echo ""

    if command_exists "gum"; then
        # Beautiful table with gum
        {
            echo "App/Tool|Current Version|Path|Method|Min Required|Status"
            for data in "${audit_data[@]}"; do
                echo "$data"
            done
        } | gum table --border rounded --separator "|" --widths 18,19,62,13,14,9 || {
            # Fallback to text table if gum fails
            printf "%-18s | %-19s | %-62s | %-13s | %-14s | %-9s\n" "App/Tool" "Current Version" "Path" "Method" "Min Required" "Status"
            echo "─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
            for data in "${audit_data[@]}"; do
                IFS='|' read -r name version path method min_req apt_ver src_ver status <<< "$data"
                printf "%-18s | %-19s | %-62s | %-13s | %-14s | %-9s\n" "$name" "$version" "$path" "$method" "$min_req" "$status"
            done
        }
    else
        # Text-only table if gum not available
        printf "%-18s | %-19s | %-62s | %-13s | %-14s | %-9s\n" "App/Tool" "Current Version" "Path" "Method" "Min Required" "Status"
        echo "─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
        for data in "${audit_data[@]}"; do
            IFS='|' read -r name version path method min_req apt_ver src_ver status <<< "$data"
            printf "%-18s | %-19s | %-62s | %-13s | %-14s | %-9s\n" "$name" "$version" "$path" "$method" "$min_req" "$status"
        done
    fi

    echo ""

    # Summary statistics
    local total_apps="${#audit_data[@]}"
    local installed_count=0
    local upgrade_count=0
    local install_count=0

    for data in "${audit_data[@]}"; do
        IFS='|' read -r _ _ _ _ _ _ _ status <<< "$data"
        case "$status" in
            "OK") ((installed_count++)) ;;
            "UPGRADE") ((upgrade_count++)) ;;
            "INSTALL") ((install_count++)) ;;
        esac
    done

    log "INFO" "════════════════════════════════════════"
    log "INFO" "Verification Summary"
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Total apps/tools: $total_apps"
    log "SUCCESS" "Successfully installed: $installed_count"
    [ "$install_count" -gt 0 ] && log "WARNING" "Still missing: $install_count"
    [ "$upgrade_count" -gt 0 ] && log "WARNING" "Need upgrades: $upgrade_count"
    echo ""

    # Display version analysis
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Final Version Analysis"
    log "INFO" "════════════════════════════════════════"
    echo ""

    display_version_analysis "${audit_data[@]}"

    # Generate final markdown report
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local markdown_file="${REPO_ROOT}/logs/installation/post-install-verification-${timestamp}.md"

    # Ensure logs directory exists
    mkdir -p "${REPO_ROOT}/logs/installation"

    # Generate markdown content
    # Always return success (verification only)
    return 0
}

# Export functions
export -f task_pre_installation_audit
export -f task_post_installation_verification
export -f detect_snap_package_status
