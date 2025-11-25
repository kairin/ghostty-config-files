#!/usr/bin/env bash
# lib/audit/app-detectors.sh - Application duplicate and issue detection
# Extracted from lib/tasks/app_audit.sh for modularity compliance (300 line limit)
# FR-026: Detect duplicates (snap+apt), FR-064: Categorize, FR-066: Calc disk usage

set -euo pipefail

[ -z "${APP_DETECTORS_SH_LOADED:-}" ] || return 0
APP_DETECTORS_SH_LOADED=1

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
    local snap_count
    snap_count=$(echo "$snap_json" | jq 'length')
    for ((i=0; i<snap_count; i++)); do
        local snap_name snap_disabled
        snap_name=$(echo "$snap_json" | jq -r ".[$i].name")
        snap_disabled=$(echo "$snap_json" | jq -r ".[$i].disabled")

        # Skip disabled snaps for duplicate detection (handled separately)
        if [ "$snap_disabled" = "true" ]; then
            continue
        fi

        # Check if equivalent APT package exists
        local apt_names="${name_mappings[$snap_name]:-$snap_name}"

        for apt_name in $apt_names; do
            local apt_exists
            apt_exists=$(echo "$apt_json" | jq --arg name "$apt_name" 'map(select(.name == $name)) | length > 0')

            if [ "$apt_exists" = "true" ]; then
                local snap_pkg apt_pkg snap_size apt_size
                snap_pkg=$(echo "$snap_json" | jq ".[$i]")
                apt_pkg=$(echo "$apt_json" | jq --arg name "$apt_name" 'map(select(.name == $name)) | .[0]')
                snap_size=$(echo "$snap_pkg" | jq -r '.size')
                apt_size=$(echo "$apt_pkg" | jq -r '.size')

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

    local disabled_json count
    disabled_json=$(echo "$snap_json" | jq '[.[] | select(.disabled == true)]')
    count=$(echo "$disabled_json" | jq 'length')

    # Calculate total disk usage of disabled snaps
    local total_size=0
    for ((i=0; i<count; i++)); do
        local size
        size=$(echo "$disabled_json" | jq -r ".[$i].size")
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
        "firefox" "chromium" "chromium-browser" "google-chrome"
        "google-chrome-stable" "brave-browser" "microsoft-edge" "opera"
    )

    local browsers_json="[]"
    local count=0

    # Check APT browsers
    for browser in "${browsers[@]}"; do
        local apt_exists
        apt_exists=$(echo "$apt_json" | jq --arg name "$browser" 'map(select(.name == $name)) | length > 0')
        if [ "$apt_exists" = "true" ]; then
            local pkg
            pkg=$(echo "$apt_json" | jq --arg name "$browser" 'map(select(.name == $name)) | .[0]')
            browsers_json=$(echo "$browsers_json" | jq --argjson pkg "$pkg" '. += [$pkg]')
            ((count++))
        fi
    done

    # Check Snap browsers
    for browser in "${browsers[@]}"; do
        local snap_exists
        snap_exists=$(echo "$snap_json" | jq --arg name "$browser" 'map(select(.name == $name and .disabled == false)) | length > 0')
        if [ "$snap_exists" = "true" ]; then
            local pkg
            pkg=$(echo "$snap_json" | jq --arg name "$browser" 'map(select(.name == $name and .disabled == false)) | .[0]')
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

export -f detect_duplicates
export -f detect_disabled_snaps
export -f detect_browsers
