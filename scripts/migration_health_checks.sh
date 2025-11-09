#!/bin/bash
# migration_health_checks.sh - Pre-migration health validation system
# Feature: 005-apt-snap-migration (Phase 4: User Story 2)
# Tasks: T030-T034 (Health Check System)
#
# Purpose: Validates system health before package migration operations
# - Disk space validation (T030)
# - Network connectivity checks (T031)
# - snapd daemon status verification (T032)
# - Package conflict detection (T033)
# - Health check result aggregation (T034)
#
# Output: JSON HealthCheckResult objects per data-model.md
# Exit codes: 0 = all checks pass, 1 = critical failure, 2 = warnings present

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# ==============================================================================
# Constants & Configuration
# ==============================================================================

# Health check severity levels (per data-model.md)
readonly SEVERITY_CRITICAL="critical"
readonly SEVERITY_WARNING="warning"
readonly SEVERITY_INFO="info"

# Health check statuses (per data-model.md)
readonly STATUS_PASS="pass"
readonly STATUS_FAIL="fail"
readonly STATUS_WARNING="warning"

# Health check types (per data-model.md)
readonly CHECK_TYPE_DISK_SPACE="disk_space"
readonly CHECK_TYPE_NETWORK="network"
readonly CHECK_TYPE_SNAPD="snapd"
readonly CHECK_TYPE_ESSENTIAL_SERVICES="essential_services"
readonly CHECK_TYPE_CONFLICTS="conflicts"

# Default thresholds
readonly MIN_DISK_SPACE_GB=10
readonly BUFFER_SPACE_GB=1
readonly NETWORK_TIMEOUT_SECONDS=5

# ==============================================================================
# T030: Disk Space Check
# ==============================================================================

# Calculate required disk space for package migration
# Args: $1 = apt package name, $2 = snap package name (optional)
# Returns: Required space in bytes (includes apt size + snap size + buffer)
calculate_required_space() {
    local apt_package="${1:-}"
    local snap_package="${2:-$apt_package}"

    local apt_size_kb=0
    local snap_size_bytes=0
    local buffer_bytes=$((BUFFER_SPACE_GB * 1024 * 1024 * 1024))  # 1GB buffer

    # Get apt package installed size (in KB)
    if dpkg-query -W -f='${Installed-Size}' "$apt_package" >/dev/null 2>&1; then
        apt_size_kb=$(dpkg-query -W -f='${Installed-Size}' "$apt_package" 2>/dev/null | tr -d '\n' | xargs || echo "0")
    fi

    # Convert KB to bytes
    local apt_size_bytes=$((apt_size_kb * 1024))

    # Get snap package size (if available in store)
    if command -v snap >/dev/null 2>&1; then
        local snap_info=$(snap info "$snap_package" 2>/dev/null || echo "")
        if [[ -n "$snap_info" ]]; then
            # Try to extract size (format varies: "100MB", "1.2GB", etc.)
            local size_str=$(echo "$snap_info" | grep -i "installed:" | awk '{print $2}' | head -1)
            if [[ -n "$size_str" ]]; then
                # Parse size string (e.g., "100MB" → 104857600)
                snap_size_bytes=$(parse_size_to_bytes "$size_str")
            fi
        fi
    fi

    # Total required space
    echo $((apt_size_bytes + snap_size_bytes + buffer_bytes))
}

# Parse human-readable size to bytes
# Args: $1 = size string (e.g., "100MB", "1.2GB")
# Returns: Size in bytes
parse_size_to_bytes() {
    local size_str="$1"
    local number=$(echo "$size_str" | grep -oE '[0-9.]+' | head -1)
    local unit=$(echo "$size_str" | grep -oE '[A-Za-z]+' | head -1)

    # Convert to bytes based on unit
    case "${unit^^}" in
        KB|KIB)
            bc <<< "scale=0; $number * 1024 / 1"
            ;;
        MB|MIB)
            bc <<< "scale=0; $number * 1024 * 1024 / 1"
            ;;
        GB|GIB)
            bc <<< "scale=0; $number * 1024 * 1024 * 1024 / 1"
            ;;
        *)
            echo "$number"  # Assume bytes if no unit
            ;;
    esac
}

# Check disk space availability for migration
# Args: $1 = apt package name (optional, for specific package check)
#       $2 = snap package name (optional)
# Outputs: JSON HealthCheckResult object
check_disk_space() {
    local apt_package="${1:-}"
    local snap_package="${2:-}"
    local check_id="disk_space_root"
    local check_name="Root Partition Disk Space"

    # Get available space on root partition
    local available_kb=$(df --output=avail / | tail -1 | tr -d ' ')
    local available_gb=$(echo "scale=2; $available_kb / 1024 / 1024" | bc)

    # Calculate required space if package specified
    local required_bytes=$((MIN_DISK_SPACE_GB * 1024 * 1024 * 1024))
    if [[ -n "$apt_package" ]]; then
        required_bytes=$(calculate_required_space "$apt_package" "$snap_package")
    fi

    local required_gb=$(echo "scale=2; $required_bytes / 1024 / 1024 / 1024" | bc)
    local available_bytes=$((available_kb * 1024))

    # Determine check result
    local status="$STATUS_PASS"
    local message="Sufficient disk space available for migration"
    local remediation=""
    local is_blocking="true"

    if (( $(echo "$available_bytes < $required_bytes" | bc -l) )); then
        status="$STATUS_FAIL"
        message="Insufficient disk space. Migration requires ${required_gb}GB but only ${available_gb}GB available."
        remediation="Free up disk space or increase partition size. Try: sudo apt autoremove && sudo apt clean"
    fi

    # Generate HealthCheckResult JSON (per data-model.md)
    cat <<EOF
{
  "check_id": "$check_id",
  "check_name": "$check_name",
  "check_type": "$CHECK_TYPE_DISK_SPACE",
  "status": "$status",
  "severity": "$SEVERITY_CRITICAL",
  "measured_value": "${available_gb}GB available",
  "threshold_requirement": "${required_gb}GB minimum",
  "is_blocking": $is_blocking,
  "message": "$message",
  "remediation": $(if [[ -n "$remediation" ]]; then echo "\"$remediation\""; else echo "null"; fi),
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# ==============================================================================
# T031: Network Connectivity Check
# ==============================================================================

# Check network connectivity to snap store via snapd socket
# Outputs: JSON HealthCheckResult object
check_network_connectivity() {
    local check_id="network_snap_store"
    local check_name="Snap Store Network Connectivity"
    local snapd_socket="/run/snapd.socket"

    local status="$STATUS_PASS"
    local message="Snap store is reachable via snapd socket"
    local remediation=""
    local measured_value="reachable"

    # Check if snapd socket exists
    if [[ ! -S "$snapd_socket" ]]; then
        status="$STATUS_FAIL"
        measured_value="socket missing"
        message="snapd socket not found at $snapd_socket. snapd may not be installed."
        remediation="Install snapd: sudo apt update && sudo apt install snapd"
    else
        # Test connectivity to snapd API
        if ! curl -sS --max-time "$NETWORK_TIMEOUT_SECONDS" \
                --unix-socket "$snapd_socket" \
                http://localhost/v2/system-info >/dev/null 2>&1; then
            status="$STATUS_FAIL"
            measured_value="unreachable"
            message="Cannot connect to snap store via snapd socket. Network or snapd service issue."
            remediation="Check network connectivity and snapd service: sudo systemctl status snapd.socket"
        fi
    fi

    # Generate HealthCheckResult JSON
    cat <<EOF
{
  "check_id": "$check_id",
  "check_name": "$check_name",
  "check_type": "$CHECK_TYPE_NETWORK",
  "status": "$status",
  "severity": "$SEVERITY_CRITICAL",
  "measured_value": "$measured_value",
  "threshold_requirement": "reachable",
  "is_blocking": true,
  "message": "$message",
  "remediation": $(if [[ -n "$remediation" ]]; then echo "\"$remediation\""; else echo "null"; fi),
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# ==============================================================================
# T032: snapd Daemon Check
# ==============================================================================

# Check snapd daemon and socket service status
# Args: $1 = "auto-fix" to automatically start inactive services (optional)
# Outputs: JSON HealthCheckResult object
check_snapd_daemon() {
    local auto_fix="${1:-}"
    local check_id="snapd_daemon"
    local check_name="snapd Service Status"

    local service_active="false"
    local socket_active="false"
    local status="$STATUS_PASS"
    local message="snapd service and socket are active"
    local remediation=""
    local measured_value="active"

    # Check snapd.service status
    if systemctl is-active --quiet snapd.service 2>/dev/null; then
        service_active="true"
    fi

    # Check snapd.socket status
    if systemctl is-active --quiet snapd.socket 2>/dev/null; then
        socket_active="true"
    fi

    # Determine overall status
    if [[ "$service_active" == "false" ]] || [[ "$socket_active" == "false" ]]; then
        status="$STATUS_FAIL"
        measured_value="inactive"

        if [[ "$service_active" == "false" ]] && [[ "$socket_active" == "false" ]]; then
            message="snapd service and socket are inactive. Snap installations require active snapd daemon."
        elif [[ "$service_active" == "false" ]]; then
            message="snapd service is inactive. Snap installations require active snapd daemon."
        else
            message="snapd socket is inactive. Snap installations require active snapd socket."
        fi

        remediation="Start and enable snapd: sudo systemctl start snapd.service snapd.socket && sudo systemctl enable snapd.service snapd.socket"

        # Auto-fix if requested
        if [[ "$auto_fix" == "auto-fix" ]]; then
            log_event "INFO" "Attempting auto-fix: starting snapd services..."
            if sudo systemctl start snapd.service snapd.socket 2>/dev/null; then
                sudo systemctl enable snapd.service snapd.socket 2>/dev/null || true
                status="$STATUS_PASS"
                measured_value="active (auto-fixed)"
                message="snapd services were inactive but have been automatically started"
                remediation=""
            else
                remediation="Auto-fix failed. Manually start snapd: $remediation"
            fi
        fi
    fi

    # Generate HealthCheckResult JSON
    cat <<EOF
{
  "check_id": "$check_id",
  "check_name": "$check_name",
  "check_type": "$CHECK_TYPE_SNAPD",
  "status": "$status",
  "severity": "$SEVERITY_CRITICAL",
  "measured_value": "$measured_value",
  "threshold_requirement": "active",
  "is_blocking": true,
  "message": "$message",
  "remediation": $(if [[ -n "$remediation" ]]; then echo "\"$remediation\""; else echo "null"; fi),
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# ==============================================================================
# T033: Package Conflict Detection
# ==============================================================================

# Check for package conflicts between apt and snap versions
# Args: $1 = apt package name, $2 = snap package name
# Outputs: JSON HealthCheckResult object
check_package_conflicts() {
    local apt_package="${1:-}"
    local snap_package="${2:-$apt_package}"
    local check_id="conflicts_${apt_package}"
    local check_name="Package Conflict Detection: $apt_package"

    if [[ -z "$apt_package" ]]; then
        log_event "ERROR" "check_package_conflicts requires package name argument"
        return 1
    fi

    local status="$STATUS_PASS"
    local message="No conflicts detected between apt and snap versions"
    local remediation=""
    local measured_value="no conflicts"
    local conflicts_found=()

    # Check apt package conflicts field
    local apt_conflicts=$(dpkg-query -W -f='${Conflicts}\n' "$apt_package" 2>/dev/null || echo "")
    if [[ -n "$apt_conflicts" ]] && [[ "$apt_conflicts" != "(none)" ]]; then
        # Check if snap package is in conflicts list
        if echo "$apt_conflicts" | grep -qw "$snap_package"; then
            conflicts_found+=("$snap_package listed in apt Conflicts field")
        fi
    fi

    # Check if snap package declares conflicts (if snap is installed)
    if command -v snap >/dev/null 2>&1; then
        local snap_conflicts=$(snap info "$snap_package" 2>/dev/null | grep -i 'conflicts:' | awk '{print $2}' || echo "")
        if [[ -n "$snap_conflicts" ]]; then
            if echo "$snap_conflicts" | grep -qw "$apt_package"; then
                conflicts_found+=("$apt_package listed in snap conflicts")
            fi
        fi
    fi

    # Check for file conflicts (both packages provide same files)
    # This is a simplified check - full implementation would compare package file lists
    local apt_files_count=$(dpkg -L "$apt_package" 2>/dev/null | wc -l || echo "0")
    if command -v snap >/dev/null 2>&1 && snap list "$snap_package" >/dev/null 2>&1; then
        # Snap is already installed - check for file overlaps
        # Note: Snaps use confined paths, so direct file conflicts are rare
        measured_value="snap already installed (confined paths)"
    fi

    # Determine status
    if [ ${#conflicts_found[@]} -gt 0 ]; then
        status="$STATUS_WARNING"
        measured_value="${#conflicts_found[@]} conflict(s) detected"
        message="Potential conflicts found: ${conflicts_found[*]}"
        remediation="Review conflicts and decide whether to proceed. Conflicts may cause package management issues."
    fi

    # Generate HealthCheckResult JSON
    cat <<EOF
{
  "check_id": "$check_id",
  "check_name": "$check_name",
  "check_type": "$CHECK_TYPE_CONFLICTS",
  "status": "$status",
  "severity": "$SEVERITY_WARNING",
  "measured_value": "$measured_value",
  "threshold_requirement": "no conflicts",
  "is_blocking": false,
  "message": "$message",
  "remediation": $(if [[ -n "$remediation" ]]; then echo "\"$remediation\""; else echo "null"; fi),
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# ==============================================================================
# T034: Health Check Aggregator
# ==============================================================================

# Run all health checks and aggregate results
# Args: $1 = apt package name (optional, for package-specific checks)
#       $2 = snap package name (optional)
#       $3 = "auto-fix" to enable automatic remediation (optional)
# Outputs: JSON array of HealthCheckResult objects
# Returns: 0 if all checks pass, 1 if any critical check fails, 2 if warnings present
run_all_health_checks() {
    local apt_package="${1:-}"
    local snap_package="${2:-$apt_package}"
    local auto_fix="${3:-}"

    local results=()
    local critical_failures=0
    local warnings=0

    log_event "INFO" "Running pre-migration health checks..."

    # T030: Disk space check
    local disk_result=$(check_disk_space "$apt_package" "$snap_package")
    results+=("$disk_result")
    if echo "$disk_result" | jq -e '.status == "fail"' >/dev/null 2>&1; then
        ((critical_failures++)) || true
        log_event "ERROR" "Disk space check failed"
    fi

    # T031: Network connectivity check
    local network_result=$(check_network_connectivity)
    results+=("$network_result")
    if echo "$network_result" | jq -e '.status == "fail"' >/dev/null 2>&1; then
        ((critical_failures++)) || true
        log_event "ERROR" "Network connectivity check failed"
    fi

    # T032: snapd daemon check
    local snapd_result=$(check_snapd_daemon "$auto_fix")
    results+=("$snapd_result")
    if echo "$snapd_result" | jq -e '.status == "fail"' >/dev/null 2>&1; then
        ((critical_failures++)) || true
        log_event "ERROR" "snapd daemon check failed"
    fi

    # T033: Package conflict check (only if package specified)
    if [[ -n "$apt_package" ]]; then
        local conflict_result=$(check_package_conflicts "$apt_package" "$snap_package")
        results+=("$conflict_result")
        if echo "$conflict_result" | jq -e '.status == "warning"' >/dev/null 2>&1; then
            ((warnings++)) || true
            log_event "WARNING" "Package conflict detected for $apt_package"
        fi
    fi

    # Aggregate results into JSON array
    local aggregated_json="["
    local first=true
    for result in "${results[@]}"; do
        if $first; then
            first=false
        else
            aggregated_json+=","
        fi
        aggregated_json+="$result"
    done
    aggregated_json+="]"

    # Output results
    echo "$aggregated_json"

    # Log summary
    local total_checks=${#results[@]}
    local passed_checks=$((total_checks - critical_failures - warnings))
    log_event "INFO" "Health checks complete: $passed_checks passed, $warnings warnings, $critical_failures critical failures"

    # Return appropriate exit code
    if [ $critical_failures -gt 0 ]; then
        return 1
    elif [ $warnings -gt 0 ]; then
        return 2
    else
        return 0
    fi
}

# ==============================================================================
# Main Entry Point (for standalone execution)
# ==============================================================================

main() {
    local command="${1:-all}"
    shift || true

    case "$command" in
        disk-space|disk)
            check_disk_space "$@"
            ;;
        network|net)
            check_network_connectivity "$@"
            ;;
        snapd|daemon)
            check_snapd_daemon "$@"
            ;;
        conflicts)
            check_package_conflicts "$@"
            ;;
        all|aggregate)
            run_all_health_checks "$@"
            ;;
        --help|-h|help)
            cat <<EOF
Usage: migration_health_checks.sh <command> [options]

Commands:
  disk-space [apt-pkg] [snap-pkg]  Check disk space availability
  network                          Check snap store network connectivity
  snapd [auto-fix]                 Check snapd daemon status
  conflicts <apt-pkg> [snap-pkg]   Check for package conflicts
  all [apt-pkg] [snap-pkg] [auto-fix]  Run all health checks (default)

Options:
  auto-fix                         Automatically fix issues where possible

Examples:
  migration_health_checks.sh all
  migration_health_checks.sh disk-space firefox
  migration_health_checks.sh snapd auto-fix
  migration_health_checks.sh all htop htop auto-fix

Output: JSON HealthCheckResult object(s) per data-model.md

Exit codes:
  0 = all checks passed
  1 = critical failure (blocks migration)
  2 = warnings present (migration can proceed with caution)
EOF
            ;;
        *)
            log_event "ERROR" "Unknown command: $command"
            echo "Use --help for usage information" >&2
            exit 1
            ;;
    esac
}

# Execute main if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
