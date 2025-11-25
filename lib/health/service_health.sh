#!/usr/bin/env bash
#
# lib/health/service_health.sh - Systemd services and process health checks
#
# Dependencies: None (standalone module)
# Constitutional: Principle V - Modular Architecture (<300 lines)
#
# Functions:
#   - check_systemd_status(): Validate systemd is running
#   - check_critical_services(): Verify important services
#   - check_process_health(): Basic process health validation
#   - get_service_metrics(): Collect service status metrics
#

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_LIB_HEALTH_SERVICE_HEALTH_SH:-}" ]] && return 0
readonly _LIB_HEALTH_SERVICE_HEALTH_SH=1

# Module constants
readonly CRITICAL_SERVICES=("dbus" "systemd-journald")
readonly OPTIONAL_SERVICES=("NetworkManager" "snapd")


# Function: check_systemd_status
check_systemd_status() {
    # Check if systemd is the init system
    if [[ ! -d /run/systemd/system ]]; then
        echo "INFO: Not running under systemd (may be container or different init)"
        return 0
    fi

    # Check systemd overall status
    local system_state
    system_state=$(systemctl is-system-running 2>/dev/null || echo "unknown")

    case "$system_state" in
        running)
            echo "PASS: Systemd status: running"
            return 0
            ;;
        degraded)
            echo "WARN: Systemd status: degraded (some units failed)"
            return 0
            ;;
        starting|initializing)
            echo "INFO: Systemd status: $system_state (system still booting)"
            return 0
            ;;
        maintenance)
            echo "WARN: Systemd status: maintenance mode"
            return 0
            ;;
        *)
            echo "WARN: Systemd status: $system_state"
            return 0
            ;;
    esac
}

# Function: check_critical_services
check_critical_services() {
    # Skip if not using systemd
    if [[ ! -d /run/systemd/system ]]; then
        echo "INFO: Skipping service checks (not running under systemd)"
        return 0
    fi

    local failures=0
    local service

    echo "Checking critical services..."

    for service in "${CRITICAL_SERVICES[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo "  PASS: $service is running"
        elif systemctl list-unit-files "$service.service" 2>/dev/null | grep -q "$service"; then
            echo "  WARN: $service is not running" >&2
            ((failures++))
        else
            # Service doesn't exist on this system
            echo "  INFO: $service not installed (may be OK)"
        fi
    done

    if [[ $failures -eq 0 ]]; then
        echo "PASS: All critical services running"
        return 0
    else
        echo "FAIL: $failures critical service(s) not running" >&2
        return 1
    fi
}

# Function: check_optional_services
check_optional_services() {
    # Skip if not using systemd
    if [[ ! -d /run/systemd/system ]]; then
        return 0
    fi

    local service

    echo "Checking optional services..."

    for service in "${OPTIONAL_SERVICES[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo "  INFO: $service is running"
        elif systemctl list-unit-files "$service.service" 2>/dev/null | grep -q "$service"; then
            echo "  INFO: $service is installed but not running"
        else
            echo "  INFO: $service not installed"
        fi
    done

    return 0
}


# Function: check_process_health
check_process_health() {
    local zombie_count
    local total_processes

    # Count zombie processes
    zombie_count=$(ps aux 2>/dev/null | grep -c 'Z' || echo "0")
    # Subtract header line if present
    zombie_count=$((zombie_count > 0 ? zombie_count - 1 : 0))

    # Count total processes
    total_processes=$(ps aux 2>/dev/null | wc -l || echo "0")
    total_processes=$((total_processes - 1))  # Subtract header

    echo "Process stats: $total_processes total, $zombie_count zombie"

    # Warn if many zombies
    if [[ $zombie_count -gt 10 ]]; then
        echo "WARN: High number of zombie processes: $zombie_count"
        return 0
    fi

    echo "PASS: Process health OK"
    return 0
}

# Function: check_init_process
check_init_process() {
    local init_pid=1

    # Check if PID 1 exists and is running
    if kill -0 $init_pid 2>/dev/null; then
        local init_name
        init_name=$(ps -p $init_pid -o comm= 2>/dev/null || echo "unknown")
        echo "PASS: Init process running ($init_name)"
        return 0
    fi

    # In containers, PID 1 might be the application
    echo "INFO: Init process check skipped (may be containerized)"
    return 0
}


# Function: get_failed_units
#   List of failed units (stdout)
get_failed_units() {
    if [[ ! -d /run/systemd/system ]]; then
        echo "[]"
        return 0
    fi

    local failed_units
    failed_units=$(systemctl --failed --no-legend 2>/dev/null | awk '{print $1}' || echo "")

    if [[ -z "$failed_units" ]]; then
        echo "No failed units"
    else
        echo "Failed units:"
        echo "$failed_units" | while read -r unit; do
            echo "  - $unit"
        done
    fi
}

# Function: check_failed_units_count
check_failed_units_count() {
    local max_failed="${1:-5}"

    if [[ ! -d /run/systemd/system ]]; then
        return 0
    fi

    local failed_count
    failed_count=$(systemctl --failed --no-legend 2>/dev/null | wc -l || echo "0")

    if [[ $failed_count -le $max_failed ]]; then
        echo "PASS: $failed_count failed unit(s) (<=$max_failed acceptable)"
        return 0
    else
        echo "WARN: $failed_count failed unit(s) (>$max_failed)"
        return 0
    fi
}


# Function: get_service_metrics
#   JSON-formatted service metrics (stdout)
get_service_metrics() {
    local systemd_state="unknown"
    local failed_count=0
    local total_services=0
    local running_services=0

    if [[ -d /run/systemd/system ]]; then
        systemd_state=$(systemctl is-system-running 2>/dev/null || echo "unknown")
        failed_count=$(systemctl --failed --no-legend 2>/dev/null | wc -l || echo "0")
        total_services=$(systemctl list-units --type=service --no-legend 2>/dev/null | wc -l || echo "0")
        running_services=$(systemctl list-units --type=service --state=running --no-legend 2>/dev/null | wc -l || echo "0")
    fi

    local zombie_count
    zombie_count=$(ps aux 2>/dev/null | grep -c 'Z' || echo "0")
    zombie_count=$((zombie_count > 0 ? zombie_count - 1 : 0))

    local total_processes
    total_processes=$(ps aux 2>/dev/null | wc -l || echo "0")
    total_processes=$((total_processes - 1))

    cat <<EOF
{
  "systemd_state": "$systemd_state",
  "failed_units": $failed_count,
  "total_services": $total_services,
  "running_services": $running_services,
  "total_processes": $total_processes,
  "zombie_processes": $zombie_count
}
EOF
}

# Function: run_all_service_checks
run_all_service_checks() {
    local failures=0
    local warnings=0

    echo "=== Service Health Checks ==="
    echo

    # Check systemd status
    if ! check_systemd_status; then
        ((warnings++))
    fi

    # Check critical services
    if ! check_critical_services; then
        ((failures++))
    fi

    # Check optional services
    check_optional_services

    # Check process health
    if ! check_process_health; then
        ((warnings++))
    fi

    # Check init process
    if ! check_init_process; then
        ((warnings++))
    fi

    # Check failed units
    if ! check_failed_units_count 5; then
        ((warnings++))
    fi

    echo
    if [[ $failures -eq 0 ]]; then
        if [[ $warnings -gt 0 ]]; then
            echo "Service health: PASS with $warnings warning(s)"
        else
            echo "Service health: PASS"
        fi
        return 0
    else
        echo "Service health: FAIL ($failures critical issue(s))" >&2
        return 1
    fi
}
