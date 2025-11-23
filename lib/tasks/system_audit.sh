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

    log "INFO" "Scanning current system state..."
    echo ""

    # Initialize version cache
    init_version_cache

    # Collect app statuses with enhanced version tracking
    local -a audit_data

    # Note: Enhanced format includes APT and source versions
    # Format: name|current|path|method|min_required|apt_avail|source_latest|status

    # Gum TUI Framework (built from source)
    audit_data+=("$(detect_app_status_enhanced "Gum TUI" "gum" "gum --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo 'built-from-source'" "0.14.5" "gum" "gum")")

    # Zig Compiler (Ghostty dependency)
    audit_data+=("$(detect_app_status_enhanced "Zig Compiler" "zig" "zig version 2>&1 | grep -oP '\d+\.\d+\.\d+'" "0.13.0" "zig" "zig")")

    # Ghostty Terminal (no GitHub releases support)
    audit_data+=("$(detect_app_status_enhanced "Ghostty Terminal" "ghostty" "ghostty --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+'" "1.1.4" "none" "none")")

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
    audit_data+=("Claude CLI|$(command -v claude >/dev/null 2>&1 && claude --version 2>&1 | head -n1 || echo 'not installed')|$(command -v claude 2>/dev/null || echo 'N/A')|$(command -v claude >/dev/null 2>&1 && echo 'npm' || echo 'missing')|latest|N/A|npm install -g @anthropic-ai/claude-code|$(command -v claude >/dev/null 2>&1 && echo 'OK' || echo 'INSTALL')")

    # Gemini CLI (npm global package: @google/gemini-cli)
    audit_data+=("Gemini CLI|$(command -v gemini >/dev/null 2>&1 && gemini --version 2>&1 | head -n1 || echo 'not installed')|$(command -v gemini 2>/dev/null || echo 'N/A')|$(command -v gemini >/dev/null 2>&1 && echo 'npm' || echo 'missing')|latest|N/A|npm install -g @google/gemini-cli|$(command -v gemini >/dev/null 2>&1 && echo 'OK' || echo 'INSTALL')")

    # GitHub Copilot CLI (npm global package: @github/copilot)
    # Command is 'copilot' NOT 'github-copilot-cli'
    audit_data+=("Copilot CLI|$(command -v copilot >/dev/null 2>&1 && copilot --version 2>&1 | head -n1 || echo 'not installed')|$(command -v copilot 2>/dev/null || echo 'N/A')|$(command -v copilot >/dev/null 2>&1 && echo 'npm' || echo 'missing')|latest|N/A|npm install -g @github/copilot|$(command -v copilot >/dev/null 2>&1 && echo 'OK' || echo 'INSTALL')")

    # Feh Image Viewer
    audit_data+=("$(detect_app_status_enhanced "Feh Viewer" "feh" "feh --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+'" "3.11.0" "feh" "feh")")

    # Glow Markdown Viewer
    audit_data+=("$(detect_app_status_enhanced "Glow Markdown" "glow" "glow --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+'" "2.0.0" "glow" "glow")")

    # VHS Terminal Recorder
    audit_data+=("$(detect_app_status_enhanced "VHS Recorder" "vhs" "vhs --version 2>&1 | grep -oP '\d+\.\d+\.\d+'" "0.7.0" "vhs" "vhs")")

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

        # Create table header (simplified for basic view - only first 6 fields)
        local table_header="App/Tool|Current Version|Path|Method|Min Required|Action"

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
            "App/Tool" "Current Version" "Path" "Method" "Min Required" "Action"
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
        # Check if source_latest contains npm install command
        if [[ "$source_latest" == "npm install"* ]]; then
            echo "INSTALL via npm: $source_latest"
            return 0
        elif [ "$apt_avail" != "N/A" ] && [ "$apt_avail" != "unknown" ]; then
            echo "INSTALL (APT available)"
            return 0
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

# Export functions
export -f detect_app_status
export -f version_compare
export -f generate_markdown_report
export -f task_pre_installation_audit
export -f init_version_cache
export -f get_cached_version
export -f set_cached_version
export -f detect_apt_version
export -f detect_source_version
export -f generate_recommendation
export -f detect_app_status_enhanced
export -f display_version_analysis
