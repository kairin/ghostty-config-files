#!/usr/bin/env bash
#
# lib/health/disk_health.sh - Disk space, mount points, and I/O health checks
#
# Purpose: Validates disk-related system health metrics
# Dependencies: None (standalone module)
# Constitutional: Principle V - Modular Architecture (<300 lines)
#
# Functions:
#   - check_disk_space(): Validate available disk space
#   - check_mount_points(): Verify critical mount points
#   - check_disk_io(): Basic disk I/O health
#   - get_disk_metrics(): Collect disk performance metrics
#

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_LIB_HEALTH_DISK_HEALTH_SH:-}" ]] && return 0
readonly _LIB_HEALTH_DISK_HEALTH_SH=1

# Module constants
readonly DISK_MIN_SPACE_GB=10
readonly DISK_WARN_SPACE_GB=20

# ============================================================================
# DISK SPACE CHECKS
# ============================================================================

# Function: check_disk_space
# Purpose: Validate available disk space meets minimum requirements
# Args:
#   $1 - Mount point to check (default: /)
#   $2 - Minimum required GB (default: 10)
# Returns:
#   0 = sufficient space, 1 = insufficient space
# Outputs:
#   DISK_AVAILABLE_GB - Available disk space in GB
#   DISK_TOTAL_GB - Total disk space in GB
#   DISK_USAGE_PCT - Disk usage percentage
check_disk_space() {
    local mount_point="${1:-/}"
    local min_gb="${2:-$DISK_MIN_SPACE_GB}"

    # Get disk statistics
    local df_output
    df_output=$(df -BG "$mount_point" 2>/dev/null | tail -1)

    if [[ -z "$df_output" ]]; then
        echo "ERROR: Cannot read disk statistics for $mount_point" >&2
        return 1
    fi

    # Parse df output
    DISK_TOTAL_GB=$(echo "$df_output" | awk '{print $2}' | sed 's/G//')
    DISK_AVAILABLE_GB=$(echo "$df_output" | awk '{print $4}' | sed 's/G//')
    DISK_USAGE_PCT=$(echo "$df_output" | awk '{print $5}' | sed 's/%//')

    # Export for use by caller
    export DISK_TOTAL_GB DISK_AVAILABLE_GB DISK_USAGE_PCT

    # Check minimum space requirement
    if [[ "$DISK_AVAILABLE_GB" -ge "$min_gb" ]]; then
        echo "PASS: Disk space: ${DISK_AVAILABLE_GB}GB available (>=${min_gb}GB required)"
        return 0
    else
        echo "FAIL: Insufficient disk space: ${DISK_AVAILABLE_GB}GB available (<${min_gb}GB required)" >&2
        return 1
    fi
}

# Function: check_disk_space_warning
# Purpose: Check if disk space is low but not critical
# Args:
#   $1 - Mount point to check (default: /)
# Returns:
#   0 = space OK, 1 = warning threshold reached
check_disk_space_warning() {
    local mount_point="${1:-/}"

    check_disk_space "$mount_point" "$DISK_WARN_SPACE_GB" >/dev/null 2>&1
    local result=$?

    if [[ $result -ne 0 ]] && [[ "$DISK_AVAILABLE_GB" -ge "$DISK_MIN_SPACE_GB" ]]; then
        echo "WARN: Disk space low: ${DISK_AVAILABLE_GB}GB available (warning at <${DISK_WARN_SPACE_GB}GB)"
        return 1
    fi

    return 0
}

# ============================================================================
# MOUNT POINT CHECKS
# ============================================================================

# Function: check_mount_points
# Purpose: Verify critical mount points are accessible
# Args: None
# Returns:
#   0 = all mount points OK, 1 = issues found
check_mount_points() {
    local issues=0
    local critical_mounts=("/" "/home" "/tmp")

    for mount in "${critical_mounts[@]}"; do
        if [[ -d "$mount" ]]; then
            # Check if mount is writable
            if [[ -w "$mount" ]]; then
                echo "PASS: Mount point $mount accessible and writable"
            else
                echo "WARN: Mount point $mount not writable" >&2
                ((issues++))
            fi
        else
            # /home and /tmp may not exist as separate mounts
            if [[ "$mount" == "/" ]]; then
                echo "FAIL: Root mount point / not accessible" >&2
                ((issues++))
            fi
        fi
    done

    return $issues
}

# Function: check_tmp_space
# Purpose: Verify /tmp has sufficient space for installation
# Args:
#   $1 - Minimum required MB (default: 500)
# Returns:
#   0 = sufficient space, 1 = insufficient space
check_tmp_space() {
    local min_mb="${1:-500}"

    local tmp_available_mb
    tmp_available_mb=$(df -BM /tmp 2>/dev/null | tail -1 | awk '{print $4}' | sed 's/M//')

    if [[ -z "$tmp_available_mb" ]]; then
        echo "WARN: Cannot determine /tmp space"
        return 0
    fi

    if [[ "$tmp_available_mb" -ge "$min_mb" ]]; then
        echo "PASS: /tmp space: ${tmp_available_mb}MB available (>=${min_mb}MB required)"
        return 0
    else
        echo "FAIL: /tmp space insufficient: ${tmp_available_mb}MB available (<${min_mb}MB required)" >&2
        return 1
    fi
}

# ============================================================================
# DISK I/O CHECKS
# ============================================================================

# Function: check_disk_io_basic
# Purpose: Basic disk I/O health check
# Args: None
# Returns:
#   0 = I/O healthy, 1 = I/O issues detected
check_disk_io_basic() {
    local test_file="/tmp/.disk_io_test_$$"
    local start_time end_time duration_ms

    # Create test file
    start_time=$(date +%s%N)
    if ! echo "disk_io_test" > "$test_file" 2>/dev/null; then
        echo "FAIL: Cannot write to /tmp (disk I/O issue)" >&2
        return 1
    fi

    # Read test file
    if ! cat "$test_file" >/dev/null 2>&1; then
        echo "FAIL: Cannot read from /tmp (disk I/O issue)" >&2
        rm -f "$test_file" 2>/dev/null
        return 1
    fi

    end_time=$(date +%s%N)
    duration_ms=$(( (end_time - start_time) / 1000000 ))

    # Cleanup
    rm -f "$test_file" 2>/dev/null

    # Check if I/O is unusually slow (>1000ms for simple read/write)
    if [[ $duration_ms -gt 1000 ]]; then
        echo "WARN: Disk I/O slow: ${duration_ms}ms for basic read/write"
        return 0
    fi

    echo "PASS: Disk I/O healthy (${duration_ms}ms)"
    return 0
}

# ============================================================================
# METRICS COLLECTION
# ============================================================================

# Function: get_disk_metrics
# Purpose: Collect comprehensive disk metrics for reporting
# Args: None
# Returns:
#   JSON-formatted disk metrics (stdout)
get_disk_metrics() {
    local root_total root_avail root_used_pct
    local home_total home_avail home_used_pct

    # Root partition metrics
    root_total=$(df -BG / | tail -1 | awk '{print $2}' | sed 's/G//')
    root_avail=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
    root_used_pct=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

    # Home partition metrics (may be same as root)
    if df -BG /home 2>/dev/null | grep -v "^Filesystem" | grep -q .; then
        home_total=$(df -BG /home | tail -1 | awk '{print $2}' | sed 's/G//')
        home_avail=$(df -BG /home | tail -1 | awk '{print $4}' | sed 's/G//')
        home_used_pct=$(df /home | tail -1 | awk '{print $5}' | sed 's/%//')
    else
        home_total="$root_total"
        home_avail="$root_avail"
        home_used_pct="$root_used_pct"
    fi

    cat <<EOF
{
  "root": {
    "total_gb": $root_total,
    "available_gb": $root_avail,
    "used_percent": $root_used_pct
  },
  "home": {
    "total_gb": $home_total,
    "available_gb": $home_avail,
    "used_percent": $home_used_pct
  },
  "minimum_required_gb": $DISK_MIN_SPACE_GB,
  "warning_threshold_gb": $DISK_WARN_SPACE_GB
}
EOF
}

# Function: run_all_disk_checks
# Purpose: Run comprehensive disk health validation
# Args: None
# Returns:
#   0 = all checks passed, 1 = failures detected
run_all_disk_checks() {
    local failures=0
    local warnings=0

    echo "=== Disk Health Checks ==="
    echo

    # Check disk space
    if ! check_disk_space "/" "$DISK_MIN_SPACE_GB"; then
        ((failures++))
    fi

    # Check disk space warning
    if ! check_disk_space_warning "/"; then
        ((warnings++))
    fi

    # Check /tmp space
    if ! check_tmp_space 500; then
        ((failures++))
    fi

    # Check mount points
    if ! check_mount_points; then
        ((warnings++))
    fi

    # Check disk I/O
    if ! check_disk_io_basic; then
        ((failures++))
    fi

    echo
    if [[ $failures -eq 0 ]]; then
        if [[ $warnings -gt 0 ]]; then
            echo "Disk health: PASS with $warnings warning(s)"
        else
            echo "Disk health: PASS"
        fi
        return 0
    else
        echo "Disk health: FAIL ($failures critical issue(s))" >&2
        return 1
    fi
}
