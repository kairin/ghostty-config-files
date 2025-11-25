#!/usr/bin/env bash
#
# lib/health/resource_health.sh - CPU, memory, and load average health checks
#
# Dependencies: None (standalone module)
# Constitutional: Principle V - Modular Architecture (<300 lines)
#
# Functions:
#   - check_memory_available(): Validate available memory
#   - check_cpu_load(): Check CPU load average
#   - check_swap_usage(): Verify swap status
#   - get_resource_metrics(): Collect resource performance metrics
#

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_LIB_HEALTH_RESOURCE_HEALTH_SH:-}" ]] && return 0
readonly _LIB_HEALTH_RESOURCE_HEALTH_SH=1

# Module constants
readonly MEMORY_MIN_AVAILABLE_MB=500
readonly MEMORY_WARN_AVAILABLE_MB=1000
readonly LOAD_WARN_THRESHOLD=2.0
readonly SWAP_WARN_PERCENT=80

# ============================================================================
# MEMORY CHECKS
# ============================================================================

# Function: check_memory_available
check_memory_available() {
    local min_mb="${1:-$MEMORY_MIN_AVAILABLE_MB}"

    # Get memory statistics from /proc/meminfo
    local mem_total_kb mem_available_kb
    mem_total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    mem_available_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}')

    # Convert to MB
    MEMORY_TOTAL_MB=$((mem_total_kb / 1024))
    MEMORY_AVAILABLE_MB=$((mem_available_kb / 1024))
    MEMORY_USED_PCT=$(( (MEMORY_TOTAL_MB - MEMORY_AVAILABLE_MB) * 100 / MEMORY_TOTAL_MB ))

    # Export for use by caller
    export MEMORY_TOTAL_MB MEMORY_AVAILABLE_MB MEMORY_USED_PCT

    if [[ "$MEMORY_AVAILABLE_MB" -ge "$min_mb" ]]; then
        echo "PASS: Memory available: ${MEMORY_AVAILABLE_MB}MB (>=${min_mb}MB required)"
        return 0
    else
        echo "FAIL: Insufficient memory: ${MEMORY_AVAILABLE_MB}MB available (<${min_mb}MB required)" >&2
        return 1
    fi
}

# Function: check_memory_warning
check_memory_warning() {
    check_memory_available "$MEMORY_WARN_AVAILABLE_MB" >/dev/null 2>&1
    local result=$?

    if [[ $result -ne 0 ]] && [[ "$MEMORY_AVAILABLE_MB" -ge "$MEMORY_MIN_AVAILABLE_MB" ]]; then
        echo "WARN: Memory low: ${MEMORY_AVAILABLE_MB}MB available (warning at <${MEMORY_WARN_AVAILABLE_MB}MB)"
        return 1
    fi

    return 0
}

# ============================================================================
# CPU LOAD CHECKS
# ============================================================================

# Function: check_cpu_load
#   CPU_LOAD_1MIN - 1 minute load average
#   CPU_LOAD_5MIN - 5 minute load average
#   CPU_LOAD_15MIN - 15 minute load average
check_cpu_load() {
    local threshold="${1:-$LOAD_WARN_THRESHOLD}"

    # Get load averages
    local loadavg
    loadavg=$(cat /proc/loadavg)

    CPU_LOAD_1MIN=$(echo "$loadavg" | awk '{print $1}')
    CPU_LOAD_5MIN=$(echo "$loadavg" | awk '{print $2}')
    CPU_LOAD_15MIN=$(echo "$loadavg" | awk '{print $3}')

    # Get CPU count
    CPU_COUNT=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)

    # Export for use by caller
    export CPU_LOAD_1MIN CPU_LOAD_5MIN CPU_LOAD_15MIN CPU_COUNT

    # Calculate threshold based on CPU count
    local effective_threshold
    effective_threshold=$(echo "$threshold * $CPU_COUNT" | bc -l 2>/dev/null || echo "$threshold")

    # Compare 1-minute load with threshold
    local load_ok
    load_ok=$(echo "$CPU_LOAD_1MIN < $effective_threshold" | bc -l 2>/dev/null || echo "1")

    if [[ "$load_ok" == "1" ]]; then
        echo "PASS: CPU load: $CPU_LOAD_1MIN (threshold: $effective_threshold for $CPU_COUNT cores)"
        return 0
    else
        echo "WARN: CPU load high: $CPU_LOAD_1MIN (threshold: $effective_threshold for $CPU_COUNT cores)"
        return 0
    fi
}

# Function: get_cpu_info
#   CPU information (stdout)
get_cpu_info() {
    local cpu_model cpu_speed_mhz

    cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ *//')
    cpu_speed_mhz=$(grep "cpu MHz" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ *//' | cut -d. -f1)

    if [[ -n "$cpu_model" ]]; then
        echo "CPU: $cpu_model"
    fi

    if [[ -n "$cpu_speed_mhz" ]]; then
        echo "Speed: ${cpu_speed_mhz}MHz"
    fi
}

# ============================================================================
# SWAP CHECKS
# ============================================================================

# Function: check_swap_usage
check_swap_usage() {
    local warn_percent="${1:-$SWAP_WARN_PERCENT}"

    # Get swap statistics
    local swap_total_kb swap_free_kb
    swap_total_kb=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
    swap_free_kb=$(grep SwapFree /proc/meminfo | awk '{print $2}')

    if [[ "$swap_total_kb" -eq 0 ]]; then
        echo "INFO: No swap configured"
        SWAP_TOTAL_MB=0
        SWAP_USED_MB=0
        SWAP_USED_PCT=0
        export SWAP_TOTAL_MB SWAP_USED_MB SWAP_USED_PCT
        return 0
    fi

    # Convert to MB
    SWAP_TOTAL_MB=$((swap_total_kb / 1024))
    local swap_used_kb=$((swap_total_kb - swap_free_kb))
    SWAP_USED_MB=$((swap_used_kb / 1024))
    SWAP_USED_PCT=$((swap_used_kb * 100 / swap_total_kb))

    # Export for use by caller
    export SWAP_TOTAL_MB SWAP_USED_MB SWAP_USED_PCT

    if [[ "$SWAP_USED_PCT" -lt "$warn_percent" ]]; then
        echo "PASS: Swap usage: ${SWAP_USED_PCT}% of ${SWAP_TOTAL_MB}MB"
        return 0
    else
        echo "WARN: Swap usage high: ${SWAP_USED_PCT}% of ${SWAP_TOTAL_MB}MB"
        return 0
    fi
}

# ============================================================================
# SYSTEM UPTIME
# ============================================================================

# Function: get_uptime_info
#   Uptime information (stdout)
get_uptime_info() {
    local uptime_seconds uptime_formatted

    uptime_seconds=$(cat /proc/uptime | cut -d. -f1)

    local days hours minutes
    days=$((uptime_seconds / 86400))
    hours=$(((uptime_seconds % 86400) / 3600))
    minutes=$(((uptime_seconds % 3600) / 60))

    if [[ $days -gt 0 ]]; then
        uptime_formatted="${days}d ${hours}h ${minutes}m"
    elif [[ $hours -gt 0 ]]; then
        uptime_formatted="${hours}h ${minutes}m"
    else
        uptime_formatted="${minutes}m"
    fi

    echo "Uptime: $uptime_formatted"
}

# ============================================================================
# METRICS COLLECTION
# ============================================================================

# Function: get_resource_metrics
#   JSON-formatted resource metrics (stdout)
get_resource_metrics() {
    # Ensure all metrics are collected
    check_memory_available "$MEMORY_MIN_AVAILABLE_MB" >/dev/null 2>&1 || true
    check_cpu_load >/dev/null 2>&1 || true
    check_swap_usage >/dev/null 2>&1 || true

    local uptime_seconds
    uptime_seconds=$(cat /proc/uptime | cut -d. -f1)

    cat <<EOF
{
  "memory": {
    "total_mb": ${MEMORY_TOTAL_MB:-0},
    "available_mb": ${MEMORY_AVAILABLE_MB:-0},
    "used_percent": ${MEMORY_USED_PCT:-0}
  },
  "cpu": {
    "cores": ${CPU_COUNT:-1},
    "load_1min": ${CPU_LOAD_1MIN:-0},
    "load_5min": ${CPU_LOAD_5MIN:-0},
    "load_15min": ${CPU_LOAD_15MIN:-0}
  },
  "swap": {
    "total_mb": ${SWAP_TOTAL_MB:-0},
    "used_mb": ${SWAP_USED_MB:-0},
    "used_percent": ${SWAP_USED_PCT:-0}
  },
  "uptime_seconds": $uptime_seconds
}
EOF
}

# Function: run_all_resource_checks
run_all_resource_checks() {
    local failures=0
    local warnings=0

    echo "=== Resource Health Checks ==="
    echo

    # Display CPU info
    get_cpu_info
    echo

    # Check memory
    if ! check_memory_available "$MEMORY_MIN_AVAILABLE_MB"; then
        ((failures++))
    fi

    # Check memory warning
    if ! check_memory_warning; then
        ((warnings++))
    fi

    # Check CPU load
    if ! check_cpu_load; then
        ((warnings++))
    fi

    # Check swap
    if ! check_swap_usage; then
        ((warnings++))
    fi

    # Display uptime
    get_uptime_info

    echo
    if [[ $failures -eq 0 ]]; then
        if [[ $warnings -gt 0 ]]; then
            echo "Resource health: PASS with $warnings warning(s)"
        else
            echo "Resource health: PASS"
        fi
        return 0
    else
        echo "Resource health: FAIL ($failures critical issue(s))" >&2
        return 1
    fi
}
