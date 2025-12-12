#!/usr/bin/env bash
# Quick Boot Scan - Fast issue detection for startup banner
# Outputs count of critical/moderate issues (no TUI, silent operation)
# Used by start.sh to show warning banner if issues found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Only source what we need for speed
source "$SCRIPT_DIR/lib/issue_registry.sh"

# Collect all issues from detectors
declare -a ALL_ISSUES=()

run_detector() {
    local detector="$1"
    [[ -x "$detector" ]] || return 0

    while IFS= read -r line; do
        [[ -n "$line" ]] && ALL_ISSUES+=("$line")
    done < <("$detector" 2>/dev/null || true)
}

# Run all detectors
for detector in "$SCRIPT_DIR/detectors"/detect_*.sh; do
    run_detector "$detector"
done

# Count by severity
critical_count=0
moderate_count=0
low_count=0

for issue in "${ALL_ISSUES[@]}"; do
    severity=$(echo "$issue" | cut -d'|' -f2)
    case "$severity" in
        CRITICAL) ((critical_count++)) || true ;;
        MODERATE) ((moderate_count++)) || true ;;
        LOW)      ((low_count++)) || true ;;
    esac
done

# Output mode based on arguments
case "${1:-count}" in
    count)
        # Just output the count of actionable issues (critical + moderate)
        echo "$((critical_count + moderate_count))"
        ;;
    summary)
        # Output summary for banner
        if [[ $critical_count -gt 0 || $moderate_count -gt 0 ]]; then
            echo "CRITICAL:$critical_count MODERATE:$moderate_count LOW:$low_count"
        fi
        ;;
    details)
        # Output all issues for detailed view
        for issue in "${ALL_ISSUES[@]}"; do
            echo "$issue"
        done
        ;;
    critical)
        # Only output critical issues
        for issue in "${ALL_ISSUES[@]}"; do
            severity=$(echo "$issue" | cut -d'|' -f2)
            [[ "$severity" == "CRITICAL" ]] && echo "$issue"
        done
        ;;
    fixable)
        # Only output fixable issues (YES or MAYBE)
        for issue in "${ALL_ISSUES[@]}"; do
            fixable=$(echo "$issue" | cut -d'|' -f5)
            [[ "$fixable" == "YES" || "$fixable" == "MAYBE" ]] && echo "$issue"
        done
        ;;
esac
