#!/usr/bin/env bash
# app_audit.sh - Application audit orchestrator
# FR-026: Detect duplicates (snap+apt), FR-064: Categorize, FR-066: Calc disk usage
#
# Modular Architecture (Principle V compliance):
#   - lib/audit/scanners.sh     - Package scanning functions
#   - lib/audit/app-detectors.sh - Duplicate/issue detection
#   - lib/audit/app-report.sh   - Report generation

set -euo pipefail

# Source required utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../core/logging.sh"
source "${SCRIPT_DIR}/../core/utils.sh"
source "${SCRIPT_DIR}/../core/state.sh"
source "${SCRIPT_DIR}/../core/errors.sh"

# Source audit modules
source "${SCRIPT_DIR}/../audit/scanners.sh"
source "${SCRIPT_DIR}/../audit/app-detectors.sh"
source "${SCRIPT_DIR}/../audit/app-report.sh"

# Audit configuration
readonly AUDIT_REPORT="/tmp/ubuntu-apps-audit.md"
readonly AUDIT_TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
readonly AUDIT_LOG="/tmp/ghostty-start-logs/app-audit-${AUDIT_TIMESTAMP}.log"

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
    log "INFO" "========================================"
    log "INFO" "Application Audit System"
    log "INFO" "========================================"

    local task_start
    task_start=$(get_unix_timestamp)

    # Phase 1: Scan packages
    local apt_packages snap_packages
    apt_packages=$(scan_apt_packages)
    snap_packages=$(scan_snap_packages)

    # Phase 2: Detect issues
    local duplicates disabled_snaps browsers
    duplicates=$(detect_duplicates "$apt_packages" "$snap_packages")
    disabled_snaps=$(detect_disabled_snaps "$snap_packages")
    browsers=$(detect_browsers "$apt_packages" "$snap_packages")

    # Phase 3: Generate report
    generate_audit_report "$duplicates" "$disabled_snaps" "$browsers" "$apt_packages" "$snap_packages"

    # Display summary
    local duplicates_count disabled_count browsers_count
    duplicates_count=$(echo "$duplicates" | jq 'length' 2>/dev/null || echo "0")
    disabled_count=$(echo "$disabled_snaps" | jq 'length' 2>/dev/null || echo "0")
    browsers_count=$(echo "$browsers" | jq 'length' 2>/dev/null || echo "0")

    log "INFO" ""
    log "INFO" "Audit Summary:"
    log "INFO" "  - Duplicate applications: ${duplicates_count:-0}"
    log "INFO" "  - Disabled snaps: ${disabled_count:-0}"
    log "INFO" "  - Browsers installed: ${browsers_count:-0}"
    log "INFO" ""
    log "INFO" "Full report: $AUDIT_REPORT"

    local task_end duration
    task_end=$(get_unix_timestamp)
    duration=$(calculate_duration "$task_start" "$task_end")

    # Only mark task completed if state system is initialized
    if [ -f "/tmp/ghostty-start-logs/installation-state.json" ]; then
        mark_task_completed "app-audit" "$duration"
    fi

    log "SUCCESS" "========================================"
    log "SUCCESS" "App audit complete ($(format_duration "$duration"))"
    log "SUCCESS" "========================================"

    return 0
}

# Export functions
export -f task_run_app_audit
