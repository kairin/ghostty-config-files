#!/usr/bin/env bash
#
# lib/health/network_health.sh - Network connectivity and interface health checks
#
# Purpose: Validates network-related system health metrics
# Dependencies: None (standalone module)
# Constitutional: Principle V - Modular Architecture (<300 lines)
#
# Functions:
#   - check_internet_connectivity(): Validate internet access
#   - check_dns_resolution(): Verify DNS is working
#   - check_critical_hosts(): Test connectivity to required hosts
#   - get_network_metrics(): Collect network performance metrics
#

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_LIB_HEALTH_NETWORK_HEALTH_SH:-}" ]] && return 0
readonly _LIB_HEALTH_NETWORK_HEALTH_SH=1

# Module constants
readonly NETWORK_TIMEOUT_SECONDS=5
readonly CRITICAL_HOSTS=("github.com" "raw.githubusercontent.com" "npmjs.org")
readonly DNS_TEST_HOST="github.com"
readonly IP_TEST_HOST="8.8.8.8"

# ============================================================================
# CONNECTIVITY CHECKS
# ============================================================================

# Function: check_internet_connectivity
# Purpose: Validate basic internet connectivity
# Args: None
# Returns:
#   0 = internet accessible, 1 = no connectivity
check_internet_connectivity() {
    # Try DNS-based connectivity first (most reliable)
    if ping -c 1 -W "$NETWORK_TIMEOUT_SECONDS" "$DNS_TEST_HOST" &>/dev/null; then
        echo "PASS: Internet connectivity verified (${DNS_TEST_HOST} reachable)"
        return 0
    fi

    # Try IP-based connectivity (DNS may be failing)
    if ping -c 1 -W "$NETWORK_TIMEOUT_SECONDS" "$IP_TEST_HOST" &>/dev/null; then
        echo "WARN: Internet reachable but DNS may have issues (IP ${IP_TEST_HOST} reachable, hostname failed)"
        return 0
    fi

    echo "FAIL: No internet connectivity detected" >&2
    return 1
}

# Function: check_dns_resolution
# Purpose: Verify DNS resolution is working
# Args:
#   $1 - Hostname to resolve (default: github.com)
# Returns:
#   0 = DNS working, 1 = DNS issues
check_dns_resolution() {
    local hostname="${1:-$DNS_TEST_HOST}"

    # Use getent for DNS resolution (more reliable than nslookup/dig which may not be installed)
    if getent hosts "$hostname" &>/dev/null; then
        local resolved_ip
        resolved_ip=$(getent hosts "$hostname" | head -1 | awk '{print $1}')
        echo "PASS: DNS resolution working ($hostname -> $resolved_ip)"
        return 0
    fi

    # Fallback: try ping to check resolution
    if ping -c 1 -W 2 "$hostname" &>/dev/null; then
        echo "PASS: DNS resolution working ($hostname resolvable)"
        return 0
    fi

    echo "FAIL: DNS resolution failed for $hostname" >&2
    return 1
}

# ============================================================================
# HOST CONNECTIVITY CHECKS
# ============================================================================

# Function: check_critical_hosts
# Purpose: Test connectivity to hosts required for installation
# Args: None
# Returns:
#   0 = all hosts reachable, 1 = some hosts unreachable
check_critical_hosts() {
    local failures=0
    local host

    echo "Checking connectivity to critical hosts..."

    for host in "${CRITICAL_HOSTS[@]}"; do
        if check_host_reachable "$host"; then
            echo "  PASS: $host reachable"
        else
            echo "  FAIL: $host unreachable" >&2
            ((failures++))
        fi
    done

    if [[ $failures -eq 0 ]]; then
        echo "PASS: All critical hosts reachable"
        return 0
    else
        echo "FAIL: $failures critical host(s) unreachable" >&2
        return 1
    fi
}

# Function: check_host_reachable
# Purpose: Test if a specific host is reachable
# Args:
#   $1 - Hostname to check
#   $2 - Timeout in seconds (default: 5)
# Returns:
#   0 = reachable, 1 = unreachable
check_host_reachable() {
    local host="$1"
    local timeout="${2:-$NETWORK_TIMEOUT_SECONDS}"

    # Try HTTPS connection first (most reliable for web services)
    if command -v curl &>/dev/null; then
        if curl -s --connect-timeout "$timeout" --max-time "$((timeout * 2))" -o /dev/null "https://$host" 2>/dev/null; then
            return 0
        fi
    fi

    # Fallback to ping
    if ping -c 1 -W "$timeout" "$host" &>/dev/null; then
        return 0
    fi

    return 1
}

# Function: check_github_api
# Purpose: Verify GitHub API is accessible (for releases, etc.)
# Args: None
# Returns:
#   0 = API accessible, 1 = API issues
check_github_api() {
    if ! command -v curl &>/dev/null; then
        echo "WARN: curl not available, cannot test GitHub API"
        return 0
    fi

    local api_url="https://api.github.com/rate_limit"
    local response

    response=$(curl -s --connect-timeout "$NETWORK_TIMEOUT_SECONDS" "$api_url" 2>/dev/null)

    if [[ -n "$response" ]] && echo "$response" | grep -q "rate"; then
        echo "PASS: GitHub API accessible"
        return 0
    fi

    echo "WARN: GitHub API may have issues (rate limit check failed)"
    return 0
}

# ============================================================================
# NETWORK INTERFACE CHECKS
# ============================================================================

# Function: check_network_interfaces
# Purpose: Verify network interfaces are up
# Args: None
# Returns:
#   0 = interfaces OK, 1 = issues detected
check_network_interfaces() {
    local active_interfaces=0

    # Get list of interfaces (excluding loopback)
    local interfaces
    interfaces=$(ip -o link show 2>/dev/null | grep -v "lo:" | awk -F': ' '{print $2}' | cut -d'@' -f1)

    if [[ -z "$interfaces" ]]; then
        echo "WARN: No network interfaces detected (may be containerized environment)"
        return 0
    fi

    for iface in $interfaces; do
        local state
        state=$(ip -o link show "$iface" 2>/dev/null | grep -oP 'state \K\w+')

        if [[ "$state" == "UP" ]]; then
            echo "  PASS: Interface $iface is UP"
            ((active_interfaces++))
        else
            echo "  INFO: Interface $iface is $state"
        fi
    done

    if [[ $active_interfaces -gt 0 ]]; then
        echo "PASS: $active_interfaces active network interface(s)"
        return 0
    else
        echo "FAIL: No active network interfaces" >&2
        return 1
    fi
}

# ============================================================================
# METRICS COLLECTION
# ============================================================================

# Function: get_network_metrics
# Purpose: Collect comprehensive network metrics for reporting
# Args: None
# Returns:
#   JSON-formatted network metrics (stdout)
get_network_metrics() {
    local internet_ok="false"
    local dns_ok="false"
    local github_ok="false"
    local latency_ms="null"

    # Test internet connectivity
    if ping -c 1 -W 3 "$DNS_TEST_HOST" &>/dev/null; then
        internet_ok="true"
        # Get latency
        latency_ms=$(ping -c 1 -W 3 "$DNS_TEST_HOST" 2>/dev/null | grep -oP 'time=\K[0-9.]+' || echo "null")
    fi

    # Test DNS
    if getent hosts "$DNS_TEST_HOST" &>/dev/null; then
        dns_ok="true"
    fi

    # Test GitHub
    if check_host_reachable "github.com" 3 2>/dev/null; then
        github_ok="true"
    fi

    cat <<EOF
{
  "internet_connected": $internet_ok,
  "dns_working": $dns_ok,
  "github_reachable": $github_ok,
  "latency_ms": $latency_ms,
  "timeout_seconds": $NETWORK_TIMEOUT_SECONDS
}
EOF
}

# Function: run_all_network_checks
# Purpose: Run comprehensive network health validation
# Args: None
# Returns:
#   0 = all checks passed, 1 = failures detected
run_all_network_checks() {
    local failures=0
    local warnings=0

    echo "=== Network Health Checks ==="
    echo

    # Check internet connectivity
    if ! check_internet_connectivity; then
        ((failures++))
    fi

    # Check DNS resolution
    if ! check_dns_resolution; then
        ((warnings++))
    fi

    # Check critical hosts
    if ! check_critical_hosts; then
        ((failures++))
    fi

    # Check GitHub API
    if ! check_github_api; then
        ((warnings++))
    fi

    # Check network interfaces
    if ! check_network_interfaces; then
        ((warnings++))
    fi

    echo
    if [[ $failures -eq 0 ]]; then
        if [[ $warnings -gt 0 ]]; then
            echo "Network health: PASS with $warnings warning(s)"
        else
            echo "Network health: PASS"
        fi
        return 0
    else
        echo "Network health: FAIL ($failures critical issue(s))" >&2
        return 1
    fi
}
