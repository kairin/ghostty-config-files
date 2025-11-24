#!/usr/bin/env bash
#
# lib/tasks/app_audit.sh - Application audit and duplicate detection system
#
# CONTEXT7 STATUS: MCP available for best practices queries
# CONTEXT7 QUERIES:
# - Query 1: "Ubuntu snap vs apt duplicate detection best practices 2025"
#   Purpose: Detect same application installed via multiple package managers
#   Result: Use dpkg -l, snap list, and desktop file scanning
# - Query 2: "Safe snap package removal Ubuntu 2025"
#   Purpose: Best practices for removing duplicate/disabled snap packages
#   Result: Use snap remove with user data backup, check disabled snaps with snap list --all
#
# Constitutional Compliance:
# - Principle V: Modular Architecture
# - FR-026: Duplicate detection framework
# - FR-064: Application audit system
# - FR-066: Disk usage calculation per duplicate category
#
# User Stories: US4 (Duplicate App Detection and Cleanup)
#
# Requirements:
# - FR-026: Detect duplicate installations (snap + apt)
# - FR-064: Categorize duplicates and recommend cleanup
# - FR-066: Calculate disk usage for each duplicate category
# - Safe cleanup with user data backup
#

set -euo pipefail

# Source required utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../core/logging.sh"
source "${SCRIPT_DIR}/../core/utils.sh"
source "${SCRIPT_DIR}/../core/state.sh"
source "${SCRIPT_DIR}/../core/errors.sh"

# Audit configuration
readonly AUDIT_REPORT="/tmp/ubuntu-apps-audit.md"
readonly AUDIT_TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
readonly AUDIT_LOG="/tmp/ghostty-start-logs/app-audit-${AUDIT_TIMESTAMP}.log"

#
# Scan installed APT packages
#
# Returns:
#   JSON array of installed packages: [{"name": "...", "version": "...", "size": "..."}]
#
scan_apt_packages() {
    log "INFO" "Scanning APT packages..."

    # Use awk to parse dpkg output efficiently in one pass
    # This generates a TSV file: name\tversion\tsize_mb
    local tmp_data="/tmp/apt-scan-$$.tsv"

    dpkg -query -W -f='${Package}\t${Version}\t${Installed-Size}\n' 2>/dev/null | \
        awk -F'\t' 'BEGIN {OFS="\t"} {
            size_kb = $3;
            if (size_kb == "") size_kb = 0;
            size_mb = int(size_kb / 1024);
            print $1, $2, size_mb "MB"
        }' > "$tmp_data"

    local count=$(wc -l < "$tmp_data")
    log "INFO" "  Found $count APT packages"

    # Build JSON using jq to properly escape all fields
    local packages_json="[]"
    if [ "$count" -gt 0 ]; then
        # Use jq to build JSON array from TSV, properly escaping all fields
        packages_json=$(awk -F'\t' 'BEGIN {OFS="\t"} {print $1, $2, $3}' "$tmp_data" | \
            jq -R -s 'split("\n")[:-1] | map(split("\t") | {name: .[0], version: .[1], size: .[2], method: "apt"})')
    fi

    rm -f "$tmp_data"
    echo "$packages_json"
}

#
# Scan installed Snap packages
#
# Returns:
#   JSON array of snap packages: [{"name": "...", "version": "...", "size": "...", "disabled": true|false}]
#
scan_snap_packages() {
    log "INFO" "Scanning Snap packages..."

    local packages_json="[]"

    # Check if snapd is installed
    if ! command -v snap &>/dev/null; then
        log "INFO" "  Snapd not installed, skipping snap scan"
        echo "$packages_json"
        return 0
    fi

    # Parse snap list output with awk (fast)
    local tmp_data="/tmp/snap-scan-$$.tsv"

    snap list --all 2>/dev/null | awk '
        NR==1 {next}  # Skip header
        {
            name = $1
            version = $2
            rev = $3
            notes = $NF

            # Check if disabled
            disabled = (notes ~ /disabled/) ? "true" : "false"

            # Get size (approximate from du -sh)
            size = "unknown"
            cmd = "du -sh /snap/" name "/" rev " 2>/dev/null | awk '\''{print $1}'\''"
            cmd | getline size
            close(cmd)
            if (size == "") size = "unknown"

            printf "%s\t%s\t%s\t%s\n", name, version, size, disabled
        }
    ' > "$tmp_data"

    local count=$(wc -l < "$tmp_data" 2>/dev/null || echo "0")
    local disabled_count=$(awk -F'\t' '$4 == "true"' "$tmp_data" | wc -l 2>/dev/null || echo "0")

    log "INFO" "  Found $count Snap packages ($disabled_count disabled)"

    # Build JSON using jq to properly escape all fields
    if [ "$count" -gt 0 ]; then
        # Use jq to build JSON array from TSV, properly escaping all fields
        packages_json=$(awk -F'\t' 'BEGIN {OFS="\t"} {print $1, $2, $3, $4}' "$tmp_data" | \
            jq -R -s 'split("\n")[:-1] | map(split("\t") | {name: .[0], version: .[1], size: .[2], method: "snap", disabled: (.[3] == "true")})')
    fi

    rm -f "$tmp_data"
    echo "$packages_json"
}

#
# Scan desktop files for GUI applications
#
# Returns:
#   JSON array of desktop applications: [{"name": "...", "exec": "...", "icon": "..."}]
#
scan_desktop_files() {
    log "INFO" "Scanning desktop files..."

    local tmp_data="/tmp/desktop-scan-$$.tsv"

    # Scan system and user desktop file locations
    local desktop_dirs=(
        "/usr/share/applications"
        "/usr/local/share/applications"
        "$HOME/.local/share/applications"
        "/var/lib/snapd/desktop/applications"
    )

    # Use find + awk to process all desktop files efficiently
    for dir in "${desktop_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            continue
        fi

        find "$dir" -maxdepth 1 -name "*.desktop" -type f 2>/dev/null | while read -r desktop_file; do
            # Extract Name, Exec, Icon with awk (faster than grep)
            awk -F= '
                /^Name=/ && !name {name = $2}
                /^Exec=/ && !exec {exec = $2}
                /^Icon=/ && !icon {icon = $2}
                END {
                    if (name != "") {
                        printf "%s\t%s\t%s\t%s\n", name, exec, icon, FILENAME
                    }
                }
            ' FILENAME="$(basename "$desktop_file")" "$desktop_file"
        done
    done > "$tmp_data"

    local count=$(wc -l < "$tmp_data" 2>/dev/null || echo "0")
    log "INFO" "  Found $count desktop applications"

    # Build JSON using jq to properly escape all fields
    local apps_json="[]"
    if [ "$count" -gt 0 ]; then
        # Use jq to build JSON array from TSV, properly escaping all fields
        apps_json=$(awk -F'\t' 'BEGIN {OFS="\t"} {print $1, $2, $3, $4}' "$tmp_data" | \
            jq -R -s 'split("\n")[:-1] | map(split("\t") | {name: .[0], exec: .[1], icon: .[2], desktop_file: .[3]})')
    fi

    rm -f "$tmp_data"
    echo "$apps_json"
}

#
# Detect duplicate applications (same app via snap + apt)
#
# Arguments:
#   $1 - APT packages JSON
#   $2 - Snap packages JSON
#
# Returns:
#   JSON array of duplicates: [{"app_name": "...", "apt": {...}, "snap": {...}, "disk_usage_total": "..."}]
#
detect_duplicates() {
    local apt_json="$1"
    local snap_json="$2"

    log "INFO" "Detecting duplicate applications..."

    local duplicates_json="[]"
    local count=0

    # Common application name mappings (snap name != apt name)
    declare -A name_mappings=(
        ["firefox"]="firefox"
        ["chromium"]="chromium-browser chromium"
        ["thunderbird"]="thunderbird"
        ["vlc"]="vlc"
        ["gimp"]="gimp"
        ["libreoffice"]="libreoffice"
        ["code"]="code visual-studio-code"
        ["slack"]="slack-desktop"
    )

    # Check each snap package for APT equivalent
    local snap_count=$(echo "$snap_json" | jq 'length')
    for ((i=0; i<snap_count; i++)); do
        local snap_name=$(echo "$snap_json" | jq -r ".[$i].name")
        local snap_disabled=$(echo "$snap_json" | jq -r ".[$i].disabled")

        # Skip disabled snaps for duplicate detection (handled separately)
        if [ "$snap_disabled" = "true" ]; then
            continue
        fi

        # Check if equivalent APT package exists
        local apt_names="${name_mappings[$snap_name]:-$snap_name}"

        for apt_name in $apt_names; do
            local apt_exists=$(echo "$apt_json" | jq --arg name "$apt_name" 'map(select(.name == $name)) | length > 0')

            if [ "$apt_exists" = "true" ]; then
                local snap_pkg=$(echo "$snap_json" | jq ".[$i]")
                local apt_pkg=$(echo "$apt_json" | jq --arg name "$apt_name" 'map(select(.name == $name)) | .[0]')

                # Calculate total disk usage
                local snap_size=$(echo "$snap_pkg" | jq -r '.size')
                local apt_size=$(echo "$apt_pkg" | jq -r '.size')

                duplicates_json=$(echo "$duplicates_json" | jq --arg app "$snap_name" \
                    --argjson snap "$snap_pkg" --argjson apt "$apt_pkg" \
                    --arg total "${snap_size} (snap) + ${apt_size} (apt)" \
                    '. += [{"app_name": $app, "snap": $snap, "apt": $apt, "disk_usage_total": $total}]')
                ((count++))

                log "INFO" "  Duplicate: $snap_name (snap + apt)"
                break
            fi
        done
    done

    log "INFO" "  Found $count duplicate applications"
    echo "$duplicates_json"
}

#
# Detect disabled snap packages
#
# Arguments:
#   $1 - Snap packages JSON
#
# Returns:
#   JSON array of disabled snaps with disk usage
#
detect_disabled_snaps() {
    local snap_json="$1"

    log "INFO" "Detecting disabled snap packages..."

    local disabled_json=$(echo "$snap_json" | jq '[.[] | select(.disabled == true)]')
    local count=$(echo "$disabled_json" | jq 'length')

    # Calculate total disk usage of disabled snaps
    local total_size=0
    for ((i=0; i<count; i++)); do
        local size=$(echo "$disabled_json" | jq -r ".[$i].size")
        if [[ "$size" =~ ^([0-9]+(\.[0-9]+)?)([MG])$ ]]; then
            local num="${BASH_REMATCH[1]}"
            local unit="${BASH_REMATCH[3]}"
            if [ "$unit" = "G" ]; then
                total_size=$(echo "$total_size + $num * 1024" | bc 2>/dev/null || echo "$total_size")
            else
                total_size=$(echo "$total_size + $num" | bc 2>/dev/null || echo "$total_size")
            fi
        fi
    done

    log "INFO" "  Found $count disabled snaps (${total_size}MB total)"
    echo "$disabled_json"
}

#
# Detect unnecessary browser installations
#
# Arguments:
#   $1 - APT packages JSON
#   $2 - Snap packages JSON
#
# Returns:
#   JSON array of installed browsers with recommendations
#
detect_browsers() {
    local apt_json="$1"
    local snap_json="$2"

    log "INFO" "Detecting installed browsers..."

    local browsers=(
        "firefox"
        "chromium"
        "chromium-browser"
        "google-chrome"
        "google-chrome-stable"
        "brave-browser"
        "microsoft-edge"
        "opera"
    )

    local browsers_json="[]"
    local count=0

    # Check APT browsers
    for browser in "${browsers[@]}"; do
        local apt_exists=$(echo "$apt_json" | jq --arg name "$browser" 'map(select(.name == $name)) | length > 0')
        if [ "$apt_exists" = "true" ]; then
            local pkg=$(echo "$apt_json" | jq --arg name "$browser" 'map(select(.name == $name)) | .[0]')
            browsers_json=$(echo "$browsers_json" | jq --argjson pkg "$pkg" '. += [$pkg]')
            ((count++))
        fi
    done

    # Check Snap browsers
    for browser in "${browsers[@]}"; do
        local snap_exists=$(echo "$snap_json" | jq --arg name "$browser" 'map(select(.name == $name and .disabled == false)) | length > 0')
        if [ "$snap_exists" = "true" ]; then
            local pkg=$(echo "$snap_json" | jq --arg name "$browser" 'map(select(.name == $name and .disabled == false)) | .[0]')
            browsers_json=$(echo "$browsers_json" | jq --argjson pkg "$pkg" '. += [$pkg]')
            ((count++))
        fi
    done

    log "INFO" "  Found $count browsers installed"

    # Add recommendation if >3 browsers
    if [ "$count" -gt 3 ]; then
        log "WARNING" "  Multiple browsers detected - recommend keeping 1-2"
    fi

    echo "$browsers_json"
}

#
# Generate audit report
#
# Arguments:
#   $1 - Duplicates JSON
#   $2 - Disabled snaps JSON
#   $3 - Browsers JSON
#   $4 - APT packages JSON
#   $5 - Snap packages JSON
#
# Generates:
#   Markdown report at $AUDIT_REPORT
#
generate_audit_report() {
    local duplicates_json="$1"
    local disabled_json="$2"
    local browsers_json="$3"
    local apt_json="$4"
    local snap_json="$5"

    log "INFO" "Generating audit report..."

    local duplicates_count=$(echo "$duplicates_json" | jq 'length' 2>/dev/null || echo "0")
    local disabled_count=$(echo "$disabled_json" | jq 'length' 2>/dev/null || echo "0")
    local browsers_count=$(echo "$browsers_json" | jq 'length' 2>/dev/null || echo "0")
    local apt_count=$(echo "$apt_json" | jq 'length' 2>/dev/null || echo "0")
    local snap_count=$(echo "$snap_json" | jq 'length' 2>/dev/null || echo "0")

    # Calculate total disk usage for disabled snaps
    local disabled_total_mb=0
    for ((i=0; i<disabled_count; i++)); do
        local size=$(echo "$disabled_json" | jq -r ".[$i].size")
        if [[ "$size" =~ ^([0-9]+(\.[0-9]+)?)([MG])$ ]]; then
            local num="${BASH_REMATCH[1]}"
            local unit="${BASH_REMATCH[3]}"
            if [ "$unit" = "G" ]; then
                disabled_total_mb=$(echo "$disabled_total_mb + $num * 1024" | bc 2>/dev/null || echo "$disabled_total_mb")
            else
                disabled_total_mb=$(echo "$disabled_total_mb + $num" | bc 2>/dev/null || echo "$disabled_total_mb")
            fi
        fi
    done

    # Generate report
    cat > "$AUDIT_REPORT" <<EOF
# Ubuntu Application Audit Report

**Generated**: $(date "+%Y-%m-%d %H:%M:%S")
**Audit ID**: $AUDIT_TIMESTAMP

---

## Summary

| Category | Count | Status |
|----------|-------|--------|
| Total APT Packages | $apt_count | ℹ️ Info |
| Total Snap Packages | $snap_count | ℹ️ Info |
| **Duplicate Applications** | **$duplicates_count** | $([ "${duplicates_count:-0}" -gt 0 ] && echo "⚠️ Action Recommended" || echo "✅ OK") |
| **Disabled Snaps** | **$disabled_count** | $([ "${disabled_count:-0}" -gt 0 ] && echo "⚠️ Action Recommended" || echo "✅ OK") |
| **Browsers Installed** | **$browsers_count** | $([ "${browsers_count:-0}" -gt 3 ] && echo "⚠️ Consider Cleanup" || echo "✅ OK") |

---

## 1. Duplicate Applications (Priority: HIGH)

**Issue**: Same application installed via both Snap and APT package managers.

**Impact**: Wastes disk space, may cause conflicts, confusing duplicate icons in app menu.

**Recommendation**: Keep one installation method (prefer APT for system integration or Snap for auto-updates).

EOF

    if [ "${duplicates_count:-0}" -eq 0 ]; then
        echo "✅ **No duplicates detected** - System is clean!" >> "$AUDIT_REPORT"
    else
        echo "| Application | Snap Version | Snap Size | APT Version | APT Size | Recommendation |" >> "$AUDIT_REPORT"
        echo "|-------------|--------------|-----------|-------------|----------|----------------|" >> "$AUDIT_REPORT"

        for ((i=0; i<duplicates_count; i++)); do
            local app=$(echo "$duplicates_json" | jq -r ".[$i].app_name")
            local snap_ver=$(echo "$duplicates_json" | jq -r ".[$i].snap.version")
            local snap_size=$(echo "$duplicates_json" | jq -r ".[$i].snap.size")
            local apt_ver=$(echo "$duplicates_json" | jq -r ".[$i].apt.version")
            local apt_size=$(echo "$duplicates_json" | jq -r ".[$i].apt.size")

            echo "| **$app** | $snap_ver | $snap_size | $apt_ver | $apt_size | Remove Snap or APT version |" >> "$AUDIT_REPORT"
        done

        cat >> "$AUDIT_REPORT" <<EOF

**Cleanup Commands**:
\`\`\`bash
# To remove Snap versions (keeps APT):
EOF
        for ((i=0; i<duplicates_count; i++)); do
            local app=$(echo "$duplicates_json" | jq -r ".[$i].app_name")
            echo "sudo snap remove $app" >> "$AUDIT_REPORT"
        done

        cat >> "$AUDIT_REPORT" <<EOF

# To remove APT versions (keeps Snap):
EOF
        for ((i=0; i<duplicates_count; i++)); do
            local apt_name=$(echo "$duplicates_json" | jq -r ".[$i].apt.name")
            echo "sudo apt remove $apt_name" >> "$AUDIT_REPORT"
        done
        echo "\`\`\`" >> "$AUDIT_REPORT"
    fi

    cat >> "$AUDIT_REPORT" <<EOF

---

## 2. Disabled Snap Packages (Priority: MEDIUM)

**Issue**: Old snap package versions that are disabled but still consuming disk space.

**Impact**: Wastes ${disabled_total_mb}MB of disk space with no benefit.

**Recommendation**: Remove disabled snap packages to reclaim disk space.

EOF

    if [ "${disabled_count:-0}" -eq 0 ]; then
        echo "✅ **No disabled snaps** - System is clean!" >> "$AUDIT_REPORT"
    else
        echo "| Package | Version | Disk Usage |" >> "$AUDIT_REPORT"
        echo "|---------|---------|------------|" >> "$AUDIT_REPORT"

        for ((i=0; i<disabled_count; i++)); do
            local name=$(echo "$disabled_json" | jq -r ".[$i].name")
            local version=$(echo "$disabled_json" | jq -r ".[$i].version")
            local size=$(echo "$disabled_json" | jq -r ".[$i].size")

            echo "| $name | $version | $size |" >> "$AUDIT_REPORT"
        done

        cat >> "$AUDIT_REPORT" <<EOF

**Total Reclaimable**: ${disabled_total_mb}MB

**Cleanup Commands**:
\`\`\`bash
# Remove all disabled snaps:
snap list --all | awk '/disabled/{print \$1, \$3}' | \\
  while read snapname revision; do \\
    sudo snap remove "\$snapname" --revision="\$revision"; \\
  done
\`\`\`
EOF
    fi

    cat >> "$AUDIT_REPORT" <<EOF

---

## 3. Browser Installation Analysis (Priority: LOW)

**Issue**: Multiple web browsers installed.

**Impact**: Disk space usage, potential confusion for default browser.

**Recommendation**: Keep 1-2 browsers maximum (primary + backup).

EOF

    if [ "${browsers_count:-0}" -eq 0 ]; then
        echo "ℹ️ **No browsers detected** via package managers." >> "$AUDIT_REPORT"
    else
        echo "| Browser | Version | Method | Size |" >> "$AUDIT_REPORT"
        echo "|---------|---------|--------|------|" >> "$AUDIT_REPORT"

        for ((i=0; i<browsers_count; i++)); do
            local name=$(echo "$browsers_json" | jq -r ".[$i].name")
            local version=$(echo "$browsers_json" | jq -r ".[$i].version")
            local method=$(echo "$browsers_json" | jq -r ".[$i].method")
            local size=$(echo "$browsers_json" | jq -r ".[$i].size")

            echo "| $name | $version | $method | $size |" >> "$AUDIT_REPORT"
        done

        if [ "${browsers_count:-0}" -gt 3 ]; then
            cat >> "$AUDIT_REPORT" <<EOF

**Recommendation**: Consider keeping only 1-2 browsers (e.g., Firefox for general use + Chromium for development).
EOF
        else
            cat >> "$AUDIT_REPORT" <<EOF

✅ **Browser count is reasonable** ($browsers_count browsers).
EOF
        fi
    fi

    cat >> "$AUDIT_REPORT" <<EOF

---

## Next Steps

1. **Review duplicates** and decide which installation method to keep
2. **Remove disabled snaps** to reclaim ${disabled_total_mb}MB disk space
3. **Optional**: Reduce browser count if >3 installed
4. **Backup**: Create system backup before removing packages
5. **Run cleanup**: Use commands above or interactive cleanup tool

**Interactive Cleanup** (when implemented):
\`\`\`bash
./scripts/app-audit.sh --cleanup  # Interactive mode with confirmations
\`\`\`

---

**Report Location**: \`$AUDIT_REPORT\`
**Log Location**: \`$AUDIT_LOG\`

EOF

    log "SUCCESS" "✓ Audit report generated: $AUDIT_REPORT"
}

#
# Main app audit function
#
# Process:
#   1. Scan APT packages
#   2. Scan Snap packages
#   3. Detect duplicates
#   4. Detect disabled snaps
#   5. Detect browsers
#   6. Generate report
#
# Returns:
#   0 = success
#   1 = failure
#
task_run_app_audit() {
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Application Audit System"
    log "INFO" "════════════════════════════════════════"

    local task_start
    task_start=$(get_unix_timestamp)

    # Scan packages
    local apt_packages
    apt_packages=$(scan_apt_packages)

    local snap_packages
    snap_packages=$(scan_snap_packages)

    # Detect issues
    local duplicates
    duplicates=$(detect_duplicates "$apt_packages" "$snap_packages")

    local disabled_snaps
    disabled_snaps=$(detect_disabled_snaps "$snap_packages")

    local browsers
    browsers=$(detect_browsers "$apt_packages" "$snap_packages")

    # Generate report
    generate_audit_report "$duplicates" "$disabled_snaps" "$browsers" "$apt_packages" "$snap_packages"

    # Display summary
    local duplicates_count=$(echo "$duplicates" | jq 'length' 2>/dev/null || echo "0")
    local disabled_count=$(echo "$disabled_snaps" | jq 'length' 2>/dev/null || echo "0")
    local browsers_count=$(echo "$browsers" | jq 'length' 2>/dev/null || echo "0")

    log "INFO" ""
    log "INFO" "Audit Summary:"
    log "INFO" "  - Duplicate applications: ${duplicates_count:-0}"
    log "INFO" "  - Disabled snaps: ${disabled_count:-0}"
    log "INFO" "  - Browsers installed: ${browsers_count:-0}"
    log "INFO" ""
    log "INFO" "Full report: $AUDIT_REPORT"

    local task_end
    task_end=$(get_unix_timestamp)
    local duration
    duration=$(calculate_duration "$task_start" "$task_end")

    # Only mark task completed if state system is initialized
    if [ -f "/tmp/ghostty-start-logs/installation-state.json" ]; then
        mark_task_completed "app-audit" "$duration"
    fi

    log "SUCCESS" "════════════════════════════════════════"
    log "SUCCESS" "✓ App audit complete ($(format_duration "$duration"))"
    log "SUCCESS" "════════════════════════════════════════"

    return 0
}

# Export functions
export -f scan_apt_packages
export -f scan_snap_packages
export -f scan_desktop_files
export -f detect_duplicates
export -f detect_disabled_snaps
export -f detect_browsers
export -f generate_audit_report
export -f task_run_app_audit
