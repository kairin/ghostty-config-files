#!/usr/bin/env bash
# Detect failed systemd services
# Identifies services that failed to start during boot

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/issue_registry.sh"

# Check for failed system services
check_failed_system_services() {
    while read -r service_name; do
        [[ -z "$service_name" ]] && continue

        # Skip snap services (handled by detect_unsupported_snaps.sh)
        [[ "$service_name" == snap.* ]] && continue

        # Get failure reason from journal
        local failure_reason
        failure_reason=$(journalctl -u "$service_name" -b --no-pager -n 10 2>/dev/null | \
            grep -iE "failed|error|cannot|unable" | head -1 | \
            sed 's/^.*: //' | cut -c1-80) || failure_reason="Unknown failure"

        # Check if it's a known cosmetic issue
        local is_cosmetic=false
        for pattern in "${!JOURNAL_PATTERNS[@]}"; do
            if echo "$failure_reason" | grep -qiE "$pattern"; then
                local pattern_info="${JOURNAL_PATTERNS[$pattern]}"
                local severity
                severity=$(echo "$pattern_info" | cut -d'|' -f2)
                if [[ "$severity" == "LOW" ]]; then
                    is_cosmetic=true
                    break
                fi
            fi
        done

        [[ "$is_cosmetic" == "true" ]] && continue

        # Determine if we can suggest a fix
        local fixable="MAYBE"
        local fix_cmd="Manual investigation required - check: journalctl -u $service_name -b"

        # Check for common fixable patterns
        if echo "$failure_reason" | grep -qiE "not found|no such file"; then
            fixable="YES"
            fix_cmd="sudo systemctl disable $service_name (service has missing dependencies)"
        elif echo "$failure_reason" | grep -qiE "permission denied"; then
            fixable="MAYBE"
            fix_cmd="Check permissions: systemctl status $service_name"
        fi

        format_issue \
            "$TYPE_FAILED_SERVICE" \
            "$SEVERITY_CRITICAL" \
            "$service_name" \
            "${failure_reason:0:80}" \
            "$fixable" \
            "$fix_cmd"
    done < <(systemctl --failed --no-legend 2>/dev/null | awk '{print $1}' | grep -v "^$")
}

# Check for failed user services
check_failed_user_services() {
    while read -r service_name; do
        [[ -z "$service_name" ]] && continue

        # Get failure reason
        local failure_reason
        failure_reason=$(journalctl --user -u "$service_name" -b --no-pager -n 10 2>/dev/null | \
            grep -iE "failed|error|cannot|unable" | head -1 | \
            sed 's/^.*: //' | cut -c1-80) || failure_reason="Unknown failure"

        # User services are generally safe to disable
        local fix_cmd="systemctl --user disable $service_name"

        format_issue \
            "$TYPE_FAILED_SERVICE" \
            "$SEVERITY_CRITICAL" \
            "$service_name (user)" \
            "${failure_reason:0:80}" \
            "YES" \
            "$fix_cmd"
    done < <(systemctl --user --failed --no-legend 2>/dev/null | awk '{print $1}' | grep -v "^$")
}

# Main execution
check_failed_system_services
check_failed_user_services
