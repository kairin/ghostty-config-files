#!/usr/bin/env bash
# Detect unsupported snap packages
# Finds snaps that fail due to Ubuntu version incompatibility

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/issue_registry.sh"

# Check journal for "platform not supported" errors from snaps
check_journal_for_snap_errors() {
    local snap_errors
    snap_errors=$(journalctl -b --no-pager -p err 2>/dev/null | grep -i "platform.*not supported" | head -10) || true

    [[ -z "$snap_errors" ]] && return 0

    # Extract snap names from the error messages
    while read -r error_line; do
        [[ -z "$error_line" ]] && continue

        # Try to extract snap name from the journal entry
        # Format: "Dec 12 08:31:02 host canonical-livepatch.canonical-livepatchd[3369]: The platform Ubuntu 25.10 is not supported"
        local snap_name
        snap_name=$(echo "$error_line" | grep -oP '(?<=\s)[a-z0-9-]+(?=\.|\[)' | head -1) || continue

        # Verify it's actually an installed snap
        if snap list "$snap_name" &>/dev/null; then
            local ubuntu_version
            ubuntu_version=$(get_ubuntu_version)

            format_issue \
                "$TYPE_UNSUPPORTED_SNAP" \
                "$SEVERITY_CRITICAL" \
                "$snap_name" \
                "Snap not supported on Ubuntu $ubuntu_version (non-LTS)" \
                "YES" \
                "sudo snap remove $snap_name"
        fi
    done <<< "$snap_errors"
}

# Check known problematic snaps based on Ubuntu version
check_known_snap_issues() {
    # canonical-livepatch only works on LTS
    if ! is_lts_release; then
        if snap list canonical-livepatch &>/dev/null 2>&1; then
            # Check if it's actually failing
            if systemctl is-failed snap.canonical-livepatch.canonical-livepatchd.service &>/dev/null; then
                format_issue \
                    "$TYPE_UNSUPPORTED_SNAP" \
                    "$SEVERITY_CRITICAL" \
                    "canonical-livepatch" \
                    "Livepatch only supports LTS releases (you're on $(get_ubuntu_version))" \
                    "YES" \
                    "sudo snap remove canonical-livepatch"
            fi
        fi
    fi
}

# Check for failed snap services
check_failed_snap_services() {
    while read -r service_name; do
        [[ -z "$service_name" ]] && continue
        [[ "$service_name" != snap.* ]] && continue

        # Extract snap name from service
        local snap_name
        snap_name=$(echo "$service_name" | sed 's/^snap\.//' | cut -d. -f1)

        # Check if it's a platform support issue
        local error_reason
        error_reason=$(journalctl -u "$service_name" -b --no-pager -n 5 2>/dev/null | grep -i "not supported\|incompatible" | head -1) || true

        if [[ -n "$error_reason" ]]; then
            format_issue \
                "$TYPE_UNSUPPORTED_SNAP" \
                "$SEVERITY_CRITICAL" \
                "$snap_name" \
                "Snap service failing: $error_reason" \
                "YES" \
                "sudo snap remove $snap_name"
        fi
    done < <(systemctl --failed --no-legend 2>/dev/null | awk '{print $1}' | grep "^snap\.")
}

# Main execution
check_known_snap_issues
check_failed_snap_services
check_journal_for_snap_errors
