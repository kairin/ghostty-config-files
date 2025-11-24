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
# Generate markdown report of system state (enhanced with version analysis)
#
# Args:
#   $@ - Array of enhanced audit data (pipe-delimited strings with 8 fields)
#
# Output:
#   Markdown file saved to logs/installation/system-state-YYYYMMDD-HHMMSS.md
#
generate_markdown_report() {
    local -a audit_data=("$@")
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local markdown_file="${REPO_ROOT}/logs/installation/system-state-${timestamp}.md"

    # Ensure logs directory exists
    mkdir -p "${REPO_ROOT}/logs/installation"

    # Generate markdown content
    cat > "$markdown_file" <<EOF
# System State Audit
**Generated:** $(date '+%Y-%m-%d %H:%M:%S')

## Installation Status

| App/Tool | Current Version | Path | Method | Min Required | Action |
|----------|----------------|------|--------|--------------|--------|
EOF

    # Add table data (basic status - first 6 fields)
    for data in "${audit_data[@]}"; do
        IFS='|' read -r name current path method min_req apt_ver src_ver status <<< "$data"
        echo "| $name | $current | $path | $method | $min_req | $status |" >> "$markdown_file"
    done

    # Add version analysis section
    cat >> "$markdown_file" <<EOF

## Version Analysis & Recommendations

| App/Tool | Min Required | APT Available | Installed | Source Latest | Recommendation |
|----------|--------------|---------------|-----------|---------------|----------------|
EOF

    # Add version analysis rows
    for data in "${audit_data[@]}"; do
        IFS='|' read -r app_name current_ver path method min_required apt_avail source_latest status <<< "$data"

        # Generate recommendation
        local recommendation
        recommendation=$(generate_recommendation "$app_name" "$min_required" "$apt_avail" "$current_ver" "$source_latest" "$method")

        # Add version check mark
        local installed_mark="✗"
        if [ "$current_ver" != "not installed" ] && [ "$current_ver" != "unknown" ]; then
            if [ "$min_required" = "unknown" ] || [ "$min_required" = "latest" ] || version_compare "$current_ver" "$min_required"; then
                installed_mark="✓"
            else
                installed_mark="⚠"
            fi
        fi

        echo "| $app_name | $min_required | $apt_avail | $current_ver $installed_mark | $source_latest | $recommendation |" >> "$markdown_file"
    done

    # Add legend
    cat >> "$markdown_file" <<EOF

**Legend:**
- ✓ = Meets minimum requirement
- ⚠ = Below minimum (CRITICAL)
- ✗ = Not installed
- ? = Built from source (version unknown)
- ↑ = Newer version available

EOF

    # Add summary section
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

    cat >> "$markdown_file" <<EOF

## Summary Statistics

- **Total apps/tools:** $total_apps
- **Already installed (OK):** $installed_count
- **Will upgrade:** $upgrade_count
- **Will install:** $install_count

## Installation Methods

EOF

    # Installation method breakdown
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

    [ "$method_apt" -gt 0 ] && echo "- **APT packages:** $method_apt" >> "$markdown_file"
    [ "$method_source" -gt 0 ] && echo "- **Built from source:** $method_source" >> "$markdown_file"
    [ "$method_binary" -gt 0 ] && echo "- **Binary installations:** $method_binary" >> "$markdown_file"
    [ "$method_npm" -gt 0 ] && echo "- **NPM global packages:** $method_npm" >> "$markdown_file"
    [ "$method_missing" -gt 0 ] && echo "- **Not installed:** $method_missing" >> "$markdown_file"

    # Add Charm Bracelet ecosystem note
    cat >> "$markdown_file" <<'EOF'

## Charm Bracelet TUI Ecosystem

This project uses the following Charm Bracelet tools:

### CLI Tools (Directly Usable in Bash)
- **gum** - Complete TUI framework wrapping bubbletea, bubbles, and lipgloss
- **glow** - Markdown viewer for beautiful documentation display
- **vhs** - Terminal recorder for creating demo GIFs and videos

### Dependencies (VHS)
- **ffmpeg** - Multimedia framework for video encoding
- **ttyd** - Terminal over HTTP for VHS recording

### NOT Installed (Go Libraries - Not Bash Compatible)
The following are Go libraries that are **already wrapped** by the CLI tools above:
- `bubbletea` - TUI framework (wrapped by gum)
- `bubbles` - TUI components (wrapped by gum)
- `lipgloss` - Styling library (wrapped by gum)
- `glamour` - Markdown rendering (wrapped by glow)
- `huh` - Forms library (equivalent functionality in gum)
- `ultraviolet` - Low-level primitives (internal use only)
- `colorprofile` - Color handling (internal library)

Installing these Go libraries separately would provide **zero additional functionality**
for bash scripts. The gum and glow CLI tools already expose all their features.

---

*This report is automatically generated during each installation/update run.*
*View with: `glow logs/installation/system-state-*.md`*
EOF

    log "INFO" "Markdown report saved: $markdown_file"
    log "INFO" "View detailed report: glow $markdown_file"
}

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

        # Run fastfetch with minimal output (key system info only)
        if command_exists "gum"; then
            # Beautiful bordered output with gum
            fastfetch --pipe --logo none --structure Title:Separator:OS:Host:Kernel:Uptime:Packages:Shell:CPU:GPU:Memory:Disk 2>/dev/null | \
                gum style --border rounded --border-foreground 6 --padding "0 1" --width 80 || \
                fastfetch --logo none --structure Title:Separator:OS:Host:Kernel:Uptime:Packages:Shell:CPU:GPU:Memory:Disk 2>/dev/null
        else
            # Plain output without gum
            fastfetch --logo none --structure Title:Separator:OS:Host:Kernel:Uptime:Packages:Shell:CPU:GPU:Memory:Disk 2>/dev/null
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

    # Gum TUI Framework (built from source)
    audit_data+=("$(detect_app_status_enhanced "Gum TUI" "gum" "gum --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo 'built-from-source'" "0.14.5" "gum" "gum")")

    # Ghostty Terminal (.deb package)
    audit_data+=("$(detect_app_status_enhanced "Ghostty Terminal" "ghostty" "ghostty --version 2>&1 | head -n1 | awk '{print \$2}'" "1.2.3" "ghostty" "ghostty")")

    # ZSH
    audit_data+=("$(detect_app_status_enhanced "ZSH Shell" "zsh" "zsh --version 2>&1 | head -n1 | grep -oP '\d+\.\d+'" "5.9" "zsh" "none")")

    # Oh My ZSH (check directory instead) - enhanced format manually
    if [ -d "$HOME/.oh-my-zsh" ]; then
        audit_data+=("Oh My ZSH|installed|$HOME/.oh-my-zsh|source|latest|N/A|N/A|OK")
    else
        audit_data+=("Oh My ZSH|not installed|N/A|missing|latest|N/A|N/A|INSTALL")
    fi

    # Python UV
    audit_data+=("$(detect_app_status_enhanced "Python UV" "uv" "uv --version 2>&1 | grep -oP '\d+\.\d+\.\d+'" "0.5.0" "none" "uv")")

    # fnm (Fast Node Manager)
    audit_data+=("$(detect_app_status_enhanced "fnm" "fnm" "fnm --version 2>&1 | grep -oP '\d+\.\d+\.\d+'" "1.38.0" "none" "fnm")")

    # Node.js
    audit_data+=("$(detect_app_status_enhanced "Node.js" "node" "node --version 2>&1 | grep -oP '\d+\.\d+\.\d+'" "25.2.0" "nodejs" "node")")

    # npm
    audit_data+=("$(detect_app_status_enhanced "npm" "npm" "npm --version 2>&1" "11.0.0" "npm" "none")")

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

    # Display basic table using gum (if available) or fallback to plain text
    if command_exists "gum"; then
        log "INFO" "Current System State:"
        echo ""

        # Create table header with clearer labels
        local table_header="App/Tool|Current Version|Path|Install Source|Min Version|Status"

        # Combine header + data (extract first 6 fields only)
        {
            echo "$table_header"
            for data in "${audit_data[@]}"; do
                IFS='|' read -r name current path method min_req apt_ver src_ver status <<< "$data"
                echo "${name}|${current}|${path}|${method}|${min_req}|${status}"
            done
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
            "App/Tool" "Current Version" "Path" "Install Source" "Min Version" "Status"
        printf "%-20s %-20s %-35s %-15s %-18s %-10s\n" \
            "--------------------" "--------------------" "-----------------------------------" "---------------" "------------------" "----------"

        for data in "${audit_data[@]}"; do
            IFS='|' read -r name version path method min_req apt_ver src_ver action <<< "$data"
            printf "%-20s %-20s %-35s %-15s %-18s %-10s\n" \
                "$name" "$version" "$path" "$method" "$min_req" "$action"
        done
    fi

    echo ""

    # Summary statistics
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
        IFS='|' read -r _ _ _ method _ _ _ _ <<< "$data"
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

    # Display tools grouped by installation strategy
    display_installation_strategy_groups "${audit_data[@]}"

    # Display enhanced version analysis
    display_version_analysis "${audit_data[@]}"

    # Generate markdown report and save to logs
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
# GitHub Repository Mapping for Source Version Detection
#
# Maps app names to their GitHub repositories for version checking
#
declare -gA SOURCE_REPOS=(
    ["fastfetch"]="fastfetch-cli/fastfetch"
    ["gum"]="charmbracelet/gum"
    ["glow"]="charmbracelet/glow"
    ["vhs"]="charmbracelet/vhs"
    ["feh"]="derf/feh"
    # Note: ghostty uses custom release system, not GitHub releases API
    # ["ghostty"]="ghostty-org/ghostty"
    ["zig"]="ziglang/zig"
    ["node"]="nodejs/node"
    ["fnm"]="Schniz/fnm"
    ["uv"]="astral-sh/uv"
    ["ttyd"]="tsl0922/ttyd"
    # Note: FFmpeg doesn't use GitHub releases, uses tags instead
    # ["ffmpeg"]="FFmpeg/FFmpeg"
)

#
# Cache directory for version checks (5 minute TTL)
#
readonly VERSION_CACHE_DIR="${HOME}/.cache/ghostty-system-audit"
readonly VERSION_CACHE_TTL=300  # 5 minutes

#
# Initialize version cache directory
#
init_version_cache() {
    mkdir -p "$VERSION_CACHE_DIR"
}

#
# Get cached version or return empty if expired
#
# Args:
#   $1 - Cache key (e.g., "apt-gum" or "github-charmbracelet-gum")
#
# Returns:
#   Cached version string or empty if not found/expired
#
get_cached_version() {
    local cache_key="$1"
    local cache_file="${VERSION_CACHE_DIR}/${cache_key}"

    if [ -f "$cache_file" ]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
        if [ "$cache_age" -lt "$VERSION_CACHE_TTL" ]; then
            cat "$cache_file"
            return 0
        fi
    fi

    return 1
}

#
# Set cached version
#
# Args:
#   $1 - Cache key
#   $2 - Version string
#
set_cached_version() {
    local cache_key="$1"
    local version="$2"
    local cache_file="${VERSION_CACHE_DIR}/${cache_key}"

    echo "$version" > "$cache_file"
}

#
# Detect APT available version for a package
#
# Args:
#   $1 - Package name
#
# Returns:
#   Version string or "N/A" if not available in apt
#
detect_apt_version() {
    local package_name="$1"
    local cache_key="apt-${package_name}"

    # Check cache first
    local cached_version
    if cached_version=$(get_cached_version "$cache_key"); then
        echo "$cached_version"
        return 0
    fi

    # Query apt-cache with timeout
    local apt_version="N/A"
    if timeout 5s apt-cache policy "$package_name" >/dev/null 2>&1; then
        apt_version=$(apt-cache policy "$package_name" 2>/dev/null | \
            grep "Candidate:" | \
            awk '{print $2}' | \
            grep -oP '^[\d.]+' || echo "N/A")
    fi

    # Cache the result
    set_cached_version "$cache_key" "$apt_version"
    echo "$apt_version"
}

#
# Detect latest source version from GitHub releases
#
# Args:
#   $1 - App name (key in SOURCE_REPOS array)
#
# Returns:
#   Version string or "N/A" if not available/API failure
#
detect_source_version() {
    local app_name="$1"
    local repo="${SOURCE_REPOS[$app_name]:-}"

    if [ -z "$repo" ]; then
        echo "N/A"
        return 1
    fi

    local cache_key="github-${repo//\//-}"

    # Check cache first
    local cached_version
    if cached_version=$(get_cached_version "$cache_key"); then
        echo "$cached_version"
        return 0
    fi

    # Query GitHub API with timeout and error handling
    local source_version="N/A"

    # Check if gh CLI is available
    if ! command_exists "gh"; then
        set_cached_version "$cache_key" "$source_version"
        echo "$source_version"
        return 1
    fi

    # Use gh CLI to query latest release (with 5s timeout)
    # Handle errors gracefully (some repos don't use GitHub releases)
    local api_response
    if api_response=$(timeout 5s gh api "repos/${repo}/releases/latest" 2>&1); then
        # Check if response is valid JSON with tag_name
        if echo "$api_response" | grep -q '"tag_name"'; then
            source_version=$(echo "$api_response" | grep -oP '"tag_name":\s*"\K[^"]+' || echo "N/A")
            # Remove 'v' prefix if present
            source_version="${source_version#v}"
            # Extract semantic version (handle cases like "v1.0.0-beta")
            source_version=$(echo "$source_version" | grep -oP '^\d+\.\d+(\.\d+)?' || echo "N/A")
        fi
    fi

    # Cache the result
    set_cached_version "$cache_key" "$source_version"
    echo "$source_version"
}

#
# Detect npm package version (both installed and latest available)
#
# Args:
#   $1 - Package name on npm (e.g., "@anthropic-ai/claude-code")
#   $2 - Command name to check for installed version (e.g., "claude")
#
# Returns:
#   "installed_version|latest_version" or "not installed|latest_version"
#
detect_npm_version() {
    local package_name="$1"
    local command_name="$2"
    local cache_key="npm-${package_name//\//-}"

    local installed_version="not installed"
    local latest_version="N/A"

    # Detect installed version by checking the command
    if command -v "$command_name" >/dev/null 2>&1; then
        # Try to get version from command --version
        installed_version=$("$command_name" --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")

        # If command --version doesn't work, try npm list to get the installed package version
        if [ "$installed_version" = "unknown" ]; then
            installed_version=$(npm list -g "$package_name" --depth=0 2>/dev/null | \
                grep "$package_name" | \
                grep -oP '\d+\.\d+\.\d+' || echo "unknown")
        fi
    fi

    # Check cache for latest version
    local cached_latest
    if cached_latest=$(get_cached_version "$cache_key"); then
        latest_version="$cached_latest"
    else
        # Query npm registry for latest version (with timeout)
        if command -v npm >/dev/null 2>&1; then
            local npm_response
            if npm_response=$(timeout 5s npm view "$package_name" version 2>&1); then
                latest_version=$(echo "$npm_response" | grep -oP '^\d+\.\d+\.\d+' || echo "N/A")
                set_cached_version "$cache_key" "$latest_version"
            fi
        fi
    fi

    echo "${installed_version}|${latest_version}"
}

#
# Detect npm package status for audit table
#
# Args:
#   $1 - Display name (e.g., "Claude CLI")
#   $2 - npm package name (e.g., "@anthropic-ai/claude-code")
#   $3 - Command name (e.g., "claude")
#   $4 - Minimum required version (typically "latest" for npm packages)
#
# Returns:
#   Pipe-delimited string: "Name|Version|Path|Method|MinReq|AptAvail|SourceLatest|Status"
#
detect_npm_package_status() {
    local display_name="$1"
    local npm_package="$2"
    local command_name="$3"
    local min_required="${4:-latest}"

    # Get npm version info (installed|latest)
    local npm_info
    npm_info=$(detect_npm_version "$npm_package" "$command_name")

    local installed_version="${npm_info%%|*}"
    local latest_version="${npm_info##*|}"

    # Determine installation path
    local install_path="N/A"
    if command -v "$command_name" >/dev/null 2>&1; then
        install_path=$(command -v "$command_name")
    fi

    # Determine installation method
    local install_method="missing"
    if [ "$installed_version" != "not installed" ]; then
        install_method="npm"
    fi

    # Determine status
    local status="INSTALL"
    if [ "$installed_version" != "not installed" ] && [ "$installed_version" != "unknown" ]; then
        # Check if meets minimum (if specified)
        if [ "$min_required" = "latest" ]; then
            status="OK"
        elif version_compare "$installed_version" "$min_required"; then
            status="OK"
        else
            status="UPGRADE"
        fi
    fi

    # Format: Name|Version|Path|Method|MinReq|AptAvail|SourceLatest|Status
    echo "${display_name}|${installed_version}|${install_path}|${install_method}|${min_required}|N/A|${latest_version}|${status}"
}

#
# Generate recommendation based on version comparison
#
# Args:
#   $1 - App name
#   $2 - Minimum required version
#   $3 - APT available version
#   $4 - Installed version
#   $5 - Source latest version
#   $6 - Current installation method
#
# Returns:
#   Recommendation string with color codes
#
generate_recommendation() {
    local app_name="$1"
    local min_required="$2"
    local apt_avail="$3"
    local installed="$4"
    local source_latest="$5"
    local install_method="$6"

    # Handle "not installed" case
    if [ "$installed" = "not installed" ] || [ "$installed" = "unknown" ] || [ "$installed" = "built-from-source" ]; then
        # Check if this is an npm package (method="npm")
        if [ "$install_method" = "npm" ]; then
            echo "INSTALL via npm"
            return 0
        # Check if APT has a good version available
        elif [ "$apt_avail" != "N/A" ] && [ "$apt_avail" != "unknown" ]; then
            echo "INSTALL (APT available)"
            return 0
        # Default to build from source
        else
            echo "INSTALL (build from source)"
            return 0
        fi
    fi

    # Remove version prefixes for comparison
    min_required="${min_required#v}"
    apt_avail="${apt_avail#v}"
    installed="${installed#v}"
    source_latest="${source_latest#v}"

    # Check if installed meets minimum requirement
    local meets_minimum=false
    if [ "$min_required" != "unknown" ] && [ "$min_required" != "latest" ]; then
        if version_compare "$installed" "$min_required"; then
            meets_minimum=true
        fi
    else
        meets_minimum=true  # No specific requirement
    fi

    # Critical: Below minimum
    if [ "$meets_minimum" = false ]; then
        echo "⚠ CRITICAL (below minimum $min_required)"
        return 0
    fi

    # Compare versions to generate smart recommendation
    local apt_viable=false
    local source_advantage=false
    local at_latest=false

    # Is APT version viable (meets minimum)?
    if [ "$apt_avail" != "N/A" ] && [ "$apt_avail" != "unknown" ]; then
        if [ "$min_required" = "unknown" ] || [ "$min_required" = "latest" ] || version_compare "$apt_avail" "$min_required"; then
            apt_viable=true
        fi
    fi

    # Does source have newer version than APT?
    if [ "$source_latest" != "N/A" ] && [ "$apt_avail" != "N/A" ]; then
        if version_compare "$source_latest" "$apt_avail"; then
            source_advantage=true
        fi
    fi

    # Is installed version at latest?
    if [ "$source_latest" != "N/A" ]; then
        if [ "$installed" = "$source_latest" ]; then
            at_latest=true
        fi
    elif [ "$apt_avail" != "N/A" ]; then
        if [ "$installed" = "$apt_avail" ]; then
            at_latest=true
        fi
    fi

    # Generate recommendation
    if [ "$at_latest" = true ]; then
        if [ "$install_method" = "source" ]; then
            echo "✓ OK (built from source)"
        else
            echo "✓ OK (APT latest)"
        fi
    elif [ "$source_advantage" = true ]; then
        local delta="$source_latest"
        echo "↑ UPGRADE (source → $delta)"
    elif [ "$apt_viable" = true ] && [ "$install_method" != "apt" ]; then
        echo "✓ OK (can use APT $apt_avail)"
    else
        echo "✓ OK (meets minimum)"
    fi
}

#
# Detect app status with enhanced version tracking
#
# This extends the original detect_app_status to include APT and source versions
#
# Args:
#   $1 - App name (for display)
#   $2 - Command to check
#   $3 - Version extraction command
#   $4 - Expected version (from installer)
#   $5 - APT package name (optional, defaults to command name)
#   $6 - Source repo key (optional, defaults to lowercase app name)
#
# Returns:
#   Pipe-delimited: name|current|path|method|min_required|apt_avail|source_latest|status
#
detect_app_status_enhanced() {
    local app_name="$1"
    local command_name="$2"
    local version_cmd="$3"
    local expected_version="${4:-unknown}"
    local apt_package="${5:-$command_name}"
    local source_key="${6:-${app_name,,}}"  # Lowercase app name

    # Get basic status (original function)
    local basic_status
    basic_status=$(detect_app_status "$app_name" "$command_name" "$version_cmd" "$expected_version")

    # Parse basic status
    IFS='|' read -r name current_ver path method expected status <<< "$basic_status"

    # Detect APT available version
    local apt_avail="N/A"
    if [ "$apt_package" != "none" ]; then
        apt_avail=$(detect_apt_version "$apt_package")
    fi

    # Detect source latest version
    local source_latest="N/A"
    if [ "$source_key" != "none" ] && [ -n "${SOURCE_REPOS[$source_key]:-}" ]; then
        source_latest=$(detect_source_version "$source_key")
    fi

    # Return enhanced format: name|current|path|method|min_required|apt_avail|source_latest|status
    echo "${name}|${current_ver}|${path}|${method}|${expected}|${apt_avail}|${source_latest}|${status}"
}

#
# Display installation strategy groups
#
# Groups tools by their optimal installation method:
# 1. npm/fnm (Node.js ecosystem)
# 2. APT (good enough versions available)
# 3. Source (best versions require building from source)
# 4. Shows current system version clearly
#
# Args:
#   $@ - Array of enhanced audit data (pipe-delimited strings with 8 fields)
#
display_installation_strategy_groups() {
    local -a audit_data=("$@")

    log "INFO" "════════════════════════════════════════"
    log "INFO" "Installation Strategy by Tool Category"
    log "INFO" "════════════════════════════════════════"
    echo ""

    # Group tools by installation strategy
    local -a npm_tools=()
    local -a curl_installer_tools=()
    local -a apt_tools=()
    local -a source_tools=()
    local -a other_tools=()

    # Categorize each tool
    for data in "${audit_data[@]}"; do
        IFS='|' read -r app_name current_ver path method min_required apt_avail source_latest status <<< "$data"

        # Determine optimal installation strategy
        local strategy=""
        local reason=""

        # Check if it's a Snap package first
        if [ "$method" = "snap" ]; then
            reason="Snap: ${source_latest:-latest} (Universal Linux package)"
            other_tools+=("${app_name}|${current_ver}|N/A|${source_latest}|${reason}")
        # Check if it's a curl-based installer
        elif [ "$app_name" = "fnm" ]; then
            reason="fnm.vercel.app::curl -fsSL fnm.vercel.app/install"
            curl_installer_tools+=("${app_name}|${current_ver}|${reason}")
        elif [ "$app_name" = "Python UV" ]; then
            reason="astral.sh/uv::curl -LsSf astral.sh/uv/install.sh"
            curl_installer_tools+=("${app_name}|${current_ver}|${reason}")
        elif [ "$app_name" = "Oh My ZSH" ]; then
            reason="ohmyz.sh::sh -c \$(curl -fsSL ohmyz.sh/install)"
            curl_installer_tools+=("${app_name}|${current_ver}|${reason}")
        # Check if it's npm/fnm managed
        elif [ "$method" = "npm" ] || [ "$app_name" = "Node.js" ] || [ "$app_name" = "npm" ]; then
            if [ "$app_name" = "Node.js" ]; then
                reason="Managed by fnm"
            elif [ "$app_name" = "npm" ]; then
                reason="Installed with Node.js via fnm"
            else
                reason="Global npm package"
            fi
            npm_tools+=("${app_name}|${current_ver}|${apt_avail}|${source_latest}|${reason}")
        # Check if APT version is sufficient
        elif [ "$apt_avail" != "N/A" ] && [ "$apt_avail" != "unknown" ]; then
            # Compare APT vs Source to determine best strategy
            if [ "$source_latest" != "N/A" ] && [ "$source_latest" != "unknown" ]; then
                # If source is significantly newer, recommend source
                local apt_major=$(echo "$apt_avail" | cut -d. -f1 2>/dev/null || echo "0")
                local src_major=$(echo "$source_latest" | cut -d. -f1 2>/dev/null || echo "0")

                if [ "$src_major" != "$apt_major" ] && [ "$src_major" -gt "$apt_major" ] 2>/dev/null; then
                    reason="Source: $source_latest (APT: $apt_avail - major version upgrade)"
                    source_tools+=("${app_name}|${current_ver}|${apt_avail}|${source_latest}|${reason}")
                else
                    reason="APT: $apt_avail sufficient (Source: $source_latest)"
                    apt_tools+=("${app_name}|${current_ver}|${apt_avail}|${source_latest}|${reason}")
                fi
            else
                reason="APT: $apt_avail (recommended)"
                apt_tools+=("${app_name}|${current_ver}|${apt_avail}|${source_latest}|${reason}")
            fi
        # Must build from source
        elif [ "$source_latest" != "N/A" ] && [ "$source_latest" != "unknown" ]; then
            reason="Source: $source_latest (APT not available)"
            source_tools+=("${app_name}|${current_ver}|${apt_avail}|${source_latest}|${reason}")
        else
            # Other/custom installation
            reason="Custom installation"
            other_tools+=("${app_name}|${current_ver}|${apt_avail}|${source_latest}|${reason}")
        fi
    done

    # Display Group 1: Official curl Installers
    if [ ${#curl_installer_tools[@]} -gt 0 ]; then
        log "INFO" "🌐 Group 1: Official curl-Based Installers"
        log "INFO" "Tools installed via official curl installation scripts"
        echo ""

        if command_exists "gum"; then
            {
                echo "Tool|Current Ver|Official Source|Installation Command"
                for row in "${curl_installer_tools[@]}"; do
                    IFS='|' read -r name ver reason <<< "$row"
                    # Split on :: delimiter
                    source="${reason%%::*}"
                    cmd="${reason#*::}"
                    echo "${name}|${ver}|${source}|${cmd}"
                done
            } | gum table --separator "|" --border rounded --border.foreground "5" --height 0 --print
        else
            printf "%-15s | %-15s | %-15s | %-15s | %-80s\n" \
                "Tool" "Current Ver" "APT Available" "Source Latest" "Official Installation Command"
            echo "────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
            for row in "${curl_installer_tools[@]}"; do
                IFS='|' read -r name ver apt src reason <<< "$row"
                printf "%-15s | %-15s | %-15s | %-15s | %-80s\n" \
                    "$name" "$ver" "$apt" "$src" "$reason"
            done
        fi
        echo ""
    fi

    # Display Group 2: Node.js Ecosystem (npm/fnm)
    if [ ${#npm_tools[@]} -gt 0 ]; then
        log "INFO" "📦 Group 2: Node.js Ecosystem (npm/fnm)"
        log "INFO" "Tools managed by Node.js package manager or fnm"
        echo ""

        if command_exists "gum"; then
            {
                echo "Tool|Current Version|APT Available|Source Latest|Installation Strategy"
                printf '%s\n' "${npm_tools[@]}"
            } | gum table --separator "|" --border rounded --border.foreground "4" --height 0 --print
        else
            printf "%-20s | %-20s | %-15s | %-15s | %-50s\n" \
                "Tool" "Current Version" "APT Available" "Source Latest" "Installation Strategy"
            echo "────────────────────────────────────────────────────────────────────────────────────────────────────────"
            for row in "${npm_tools[@]}"; do
                IFS='|' read -r name ver apt src reason <<< "$row"
                printf "%-20s | %-20s | %-15s | %-15s | %-50s\n" \
                    "$name" "$ver" "$apt" "$src" "$reason"
            done
        fi
        echo ""
    fi

    # Display Group 3: APT Packages (good enough versions)
    if [ ${#apt_tools[@]} -gt 0 ]; then
        log "INFO" "📦 Group 3: APT Packages (Recommended)"
        log "INFO" "Tools with good enough versions available via APT"
        echo ""

        if command_exists "gum"; then
            {
                echo "Tool|Current Version|APT Available|Source Latest|Installation Strategy"
                printf '%s\n' "${apt_tools[@]}"
            } | gum table --separator "|" --border rounded --border.foreground "2" --height 0 --print
        else
            printf "%-20s | %-20s | %-15s | %-15s | %-50s\n" \
                "Tool" "Current Version" "APT Available" "Source Latest" "Installation Strategy"
            echo "────────────────────────────────────────────────────────────────────────────────────────────────────────"
            for row in "${apt_tools[@]}"; do
                IFS='|' read -r name ver apt src reason <<< "$row"
                printf "%-20s | %-20s | %-15s | %-15s | %-50s\n" \
                    "$name" "$ver" "$apt" "$src" "$reason"
            done
        fi
        echo ""
    fi

    # Display Group 4: Build from Source (best versions)
    if [ ${#source_tools[@]} -gt 0 ]; then
        log "INFO" "🔨 Group 4: Build from Source (Best Versions)"
        log "INFO" "Tools requiring source build for optimal versions"
        echo ""

        if command_exists "gum"; then
            {
                echo "Tool|Current Version|APT Available|Source Latest|Installation Strategy"
                printf '%s\n' "${source_tools[@]}"
            } | gum table --separator "|" --border rounded --border.foreground "3" --height 0 --print
        else
            printf "%-20s | %-20s | %-15s | %-15s | %-50s\n" \
                "Tool" "Current Version" "APT Available" "Source Latest" "Installation Strategy"
            echo "────────────────────────────────────────────────────────────────────────────────────────────────────────"
            for row in "${source_tools[@]}"; do
                IFS='|' read -r name ver apt src reason <<< "$row"
                printf "%-20s | %-20s | %-15s | %-15s | %-50s\n" \
                    "$name" "$ver" "$apt" "$src" "$reason"
            done
        fi
        echo ""
    fi

    # Display Group 5: Snap Packages & Custom Installations
    if [ ${#other_tools[@]} -gt 0 ]; then
        log "INFO" "⚙️  Group 5: Snap Packages & Custom Installations"
        log "INFO" "Tools installed via Snap or specialized methods"
        echo ""

        if command_exists "gum"; then
            {
                echo "Tool|Current Version|APT Available|Source Latest|Installation Strategy"
                printf '%s\n' "${other_tools[@]}"
            } | gum table --separator "|" --border rounded --border.foreground "5" --height 0 --print
        else
            printf "%-20s | %-20s | %-15s | %-15s | %-50s\n" \
                "Tool" "Current Version" "APT Available" "Source Latest" "Installation Strategy"
            echo "────────────────────────────────────────────────────────────────────────────────────────────────────────"
            for row in "${other_tools[@]}"; do
                IFS='|' read -r name ver apt src reason <<< "$row"
                printf "%-20s | %-20s | %-15s | %-15s | %-50s\n" \
                    "$name" "$ver" "$apt" "$src" "$reason"
            done
        fi
        echo ""
    fi

    log "INFO" "════════════════════════════════════════"
    echo ""
}

#
# Display version analysis table
#
# Args:
#   $@ - Array of enhanced audit data (pipe-delimited strings with 8 fields)
#
display_version_analysis() {
    local -a audit_data=("$@")

    log "INFO" "════════════════════════════════════════"
    log "INFO" "Version Analysis & Recommendations"
    log "INFO" "════════════════════════════════════════"
    echo ""

    log "INFO" "Analyzing version deltas and upgrade opportunities..."
    echo ""

    # Build analysis table
    local -a analysis_rows=()

    for data in "${audit_data[@]}"; do
        IFS='|' read -r app_name current_ver path method min_required apt_avail source_latest status <<< "$data"

        # Generate recommendation
        local recommendation
        recommendation=$(generate_recommendation "$app_name" "$min_required" "$apt_avail" "$current_ver" "$source_latest" "$method")

        # Add version check marks
        local installed_mark="✗"
        if [ "$current_ver" != "not installed" ] && [ "$current_ver" != "unknown" ] && [ "$current_ver" != "built-from-source" ]; then
            if [ "$min_required" = "unknown" ] || [ "$min_required" = "latest" ] || version_compare "$current_ver" "$min_required"; then
                installed_mark="✓"
            else
                installed_mark="⚠"
            fi
        elif [ "$current_ver" = "built-from-source" ]; then
            # Special case: built from source but no version number
            installed_mark="?"
        fi

        # Format row
        local row="${app_name}|${min_required}|${apt_avail}|${current_ver} ${installed_mark}|${source_latest}|${recommendation}"
        analysis_rows+=("$row")
    done

    # Display with gum table if available
    if command_exists "gum"; then
        local table_header="App/Tool|Min Required|APT Available|Installed|Source Latest|Recommendation"

        {
            echo "$table_header"
            printf '%s\n' "${analysis_rows[@]}"
        } | gum table --separator "|" \
            --border rounded \
            --border.foreground "6" \
            --height 0 \
            --print
    else
        # Fallback: plain text table
        printf "%-20s %-15s %-15s %-20s %-15s %-40s\n" \
            "App/Tool" "Min Required" "APT Available" "Installed" "Source Latest" "Recommendation"
        printf "%-20s %-15s %-15s %-20s %-15s %-40s\n" \
            "--------------------" "---------------" "---------------" "--------------------" "---------------" "----------------------------------------"

        for row in "${analysis_rows[@]}"; do
            IFS='|' read -r app min_req apt_ver inst_ver src_ver recommend <<< "$row"
            printf "%-20s %-15s %-15s %-20s %-15s %-40s\n" \
                "$app" "$min_req" "$apt_ver" "$inst_ver" "$src_ver" "$recommend"
        done
    fi

    echo ""

    # Legend
    log "INFO" "Legend:"
    log "INFO" "  ✓ = Meets minimum requirement"
    log "INFO" "  ⚠ = Below minimum (CRITICAL)"
    log "INFO" "  ✗ = Not installed"
    log "INFO" "  ? = Built from source (version unknown)"
    log "INFO" "  ↑ = Newer version available"
    echo ""

    # Summary insights
    local upgrade_opportunities=0
    local critical_count=0
    local optimal_count=0

    for row in "${analysis_rows[@]}"; do
        IFS='|' read -r _ _ _ _ _ recommend <<< "$row"
        case "$recommend" in
            *"CRITICAL"*) ((critical_count++)) ;;
            *"UPGRADE"*) ((upgrade_opportunities++)) ;;
            *"OK"*) ((optimal_count++)) ;;
        esac
    done

    log "INFO" "════════════════════════════════════════"
    log "INFO" "Version Analysis Summary"
    log "INFO" "════════════════════════════════════════"
    [ "$critical_count" -gt 0 ] && log "ERROR" "⚠ CRITICAL upgrades needed: $critical_count"
    [ "$upgrade_opportunities" -gt 0 ] && log "WARNING" "↑ Upgrade opportunities: $upgrade_opportunities"
    [ "$optimal_count" -gt 0 ] && log "SUCCESS" "✓ Optimal installations: $optimal_count"
    echo ""
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

    # Gum TUI Framework
    audit_data+=("$(detect_app_status_enhanced "Gum TUI" "gum" "gum --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo 'built-from-source'" "0.14.5" "gum" "gum")")

    # Ghostty Terminal (.deb package)
    audit_data+=("$(detect_app_status_enhanced "Ghostty Terminal" "ghostty" "ghostty --version 2>&1 | head -n1 | awk '{print \$2}'" "1.2.3" "ghostty" "ghostty")")

    # ZSH Shell
    audit_data+=("$(detect_app_status_enhanced "ZSH Shell" "zsh" "zsh --version 2>&1 | grep -oP '\d+\.\d+'" "5.9" "zsh" "none")")

    # Oh My ZSH
    audit_data+=("$(detect_app_status_enhanced "Oh My ZSH" "oh-my-zsh" "[ -d ~/.oh-my-zsh ] && echo 'installed' || echo 'not installed'" "latest" "none" "none")")

    # Python UV
    audit_data+=("$(detect_app_status_enhanced "Python UV" "uv" "uv --version 2>&1 | grep -oP '\d+\.\d+\.\d+'" "0.5.0" "none" "uv")")

    # fnm (Fast Node Manager)
    audit_data+=("$(detect_app_status_enhanced "fnm" "fnm" "fnm --version 2>&1 | grep -oP '\d+\.\d+\.\d+'" "1.38.0" "none" "fnm")")

    # Node.js
    audit_data+=("$(detect_app_status_enhanced "Node.js" "node" "node --version 2>&1 | grep -oP '\d+\.\d+\.\d+'" "25.2.0" "nodejs" "node")")

    # npm
    audit_data+=("$(detect_app_status_enhanced "npm" "npm" "npm --version 2>&1" "11.0.0" "npm" "none")")

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
    cat > "$markdown_file" <<EOF
# Post-Installation Verification Report
**Generated:** $(date '+%Y-%m-%d %H:%M:%S')

## Final System State

| App/Tool | Current Version | Path | Method | Min Required | Status |
|----------|----------------|------|--------|--------------|--------|
EOF

    # Add table data
    for data in "${audit_data[@]}"; do
        IFS='|' read -r name current path method min_req apt_ver src_ver status <<< "$data"
        echo "| $name | $current | $path | $method | $min_req | $status |" >> "$markdown_file"
    done

    # Add version analysis section
    cat >> "$markdown_file" <<EOF

## Version Analysis & Recommendations

| App/Tool | Min Required | APT Available | Installed | Source Latest | Recommendation |
|----------|--------------|---------------|-----------|---------------|----------------|
EOF

    # Add version analysis rows
    for data in "${audit_data[@]}"; do
        IFS='|' read -r app_name current_ver path method min_required apt_avail source_latest status <<< "$data"

        # Generate recommendation
        local recommendation
        recommendation=$(generate_recommendation "$app_name" "$min_required" "$apt_avail" "$current_ver" "$source_latest" "$method")

        # Add version check mark
        local installed_mark="✗"
        if [ "$current_ver" != "not installed" ] && [ "$current_ver" != "unknown" ]; then
            if [ "$min_required" = "unknown" ] || [ "$min_required" = "latest" ] || version_compare "$current_ver" "$min_required"; then
                installed_mark="✓"
            else
                installed_mark="⚠"
            fi
        fi

        echo "| $app_name | $min_required | $apt_avail | $current_ver $installed_mark | $source_latest | $recommendation |" >> "$markdown_file"
    done

    # Add summary
    cat >> "$markdown_file" <<EOF

## Verification Summary

- **Total apps/tools:** $total_apps
- **Successfully installed:** $installed_count
- **Still missing:** $install_count
- **Need upgrades:** $upgrade_count

---

*This verification report confirms the final state after installation completed.*
*Compare with pre-installation report to see what changed.*

EOF

    log "INFO" "Post-installation verification report saved: $markdown_file"
    log "INFO" "View detailed report: glow $markdown_file"
    echo ""

    # Always return success (verification only)
    return 0
}

# Export functions
export -f detect_app_status
export -f version_compare
export -f generate_markdown_report
export -f task_pre_installation_audit
export -f task_post_installation_verification
export -f init_version_cache
export -f get_cached_version
export -f set_cached_version
export -f detect_apt_version
export -f detect_source_version
export -f generate_recommendation
export -f detect_app_status_enhanced
export -f detect_snap_package_status
export -f detect_npm_package_status
export -f display_installation_strategy_groups
export -f display_version_analysis
