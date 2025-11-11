#!/usr/bin/env bash

#######################################
# Script: performance-monitor.sh
# Purpose: Monitor Ghostty terminal performance and system metrics
# Usage: ./performance-monitor.sh [--test|--baseline|--compare|--weekly-report|--help]
# Dependencies: ghostty, jq (optional), time
#######################################

set -euo pipefail
IFS=$'\n\t'

# Script configuration
readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_DIR="$SCRIPT_DIR/../logs"
readonly REPO_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        "ERROR") echo -e "${RED}[$timestamp] [ERROR] $message${NC}" >&2 ;;
        "SUCCESS") echo -e "${GREEN}[$timestamp] [SUCCESS] $message${NC}" ;;
        "WARNING") echo -e "${YELLOW}[$timestamp] [WARNING] $message${NC}" ;;
        "INFO") echo -e "${BLUE}[$timestamp] [INFO] $message${NC}" ;;
    esac
}

# Error handler
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# Cleanup function
cleanup() {
    # Cleanup temporary files if any were created
    local exit_code=$?
    if [ -n "${TEMP_FILES:-}" ]; then
        rm -f "$TEMP_FILES" 2>/dev/null || true
    fi
    exit $exit_code
}

# Register cleanup on exit
trap cleanup EXIT INT TERM

# Dependency checking
check_dependencies() {
    local missing_deps=()

    if ! command -v ghostty >/dev/null 2>&1; then
        missing_deps+=("ghostty")
    fi

    # jq is optional but recommended
    if ! command -v jq >/dev/null 2>&1; then
        log "WARNING" "jq not found - JSON output will be basic"
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        error_exit "Missing required dependencies: ${missing_deps[*]}"
    fi
}

# Monitor Ghostty performance
monitor_ghostty_performance() {
    local test_mode="${1:-default}"

    log "INFO" "📊 Monitoring Ghostty performance (mode: $test_mode)..."

    # Startup time measurement
    local startup_time="0m0.000s"
    if command -v ghostty >/dev/null 2>&1; then
        startup_time=$( (time ghostty --version >/dev/null 2>&1) 2>&1 | grep real | awk '{print $2}' || echo "0m0.000s")
    else
        log "WARNING" "Ghostty not available for startup time measurement"
    fi

    # Configuration load time
    local config_time="0m0.000s"
    if ghostty +show-config >/dev/null 2>&1; then
        config_time=$( (time ghostty +show-config >/dev/null 2>&1) 2>&1 | grep real | awk '{print $2}' || echo "0m0.000s")
    else
        log "WARNING" "Unable to measure configuration load time"
    fi

    # Check for 2025 optimizations
    local config_file="$HOME/.config/ghostty/config"
    local cgroup_opt="false"
    local shell_integration_opt="false"

    if [ -f "$config_file" ]; then
        if grep -q "linux-cgroup.*single-instance" "$config_file" 2>/dev/null; then
            cgroup_opt="true"
            log "SUCCESS" "✅ CGroup single-instance optimization enabled"
        fi

        if grep -q "shell-integration.*detect" "$config_file" 2>/dev/null; then
            shell_integration_opt="true"
            log "SUCCESS" "✅ Shell integration auto-detection enabled"
        fi
    fi

    # Generate performance report
    local output_file="$LOG_DIR/performance-$(date +%s).json"
    cat > "$output_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "test_mode": "$test_mode",
    "startup_time": "$startup_time",
    "config_load_time": "$config_time",
    "optimizations": {
        "cgroup_single_instance": $cgroup_opt,
        "shell_integration_detect": $shell_integration_opt
    },
    "system": {
        "hostname": "$(hostname)",
        "kernel": "$(uname -r)",
        "uptime": "$(uptime -p 2>/dev/null || echo 'unknown')"
    }
}
EOF

    log "SUCCESS" "✅ Performance data collected: $output_file"

    # Display summary if jq is available
    if command -v jq >/dev/null 2>&1; then
        echo ""
        jq '.' "$output_file"
    fi
}

# Generate weekly performance report
generate_weekly_report() {
    log "INFO" "📈 Generating weekly performance report..."

    # Find all performance logs from the last 7 days
    local report_file="$LOG_DIR/weekly-report-$(date +%Y%m%d).txt"
    local logs_found=0

    {
        echo "======================================"
        echo "Weekly Performance Report"
        echo "Generated: $(date)"
        echo "======================================"
        echo ""

        # Find performance logs from last 7 days
        if command -v find >/dev/null 2>&1; then
            while IFS= read -r -d '' file; do
                logs_found=$((logs_found + 1))
                echo "--- $(basename "$file") ---"
                if command -v jq >/dev/null 2>&1; then
                    jq -r '. | "Time: \(.timestamp)\nStartup: \(.startup_time)\nConfig Load: \(.config_load_time)\nOptimizations: CGroup=\(.optimizations.cgroup_single_instance), Shell=\(.optimizations.shell_integration_detect)\n"' "$file" 2>/dev/null || cat "$file"
                else
                    cat "$file"
                fi
                echo ""
            done < <(find "$LOG_DIR" -name "performance-*.json" -type f -mtime -7 -print0 2>/dev/null)
        fi

        if [ $logs_found -eq 0 ]; then
            echo "No performance logs found in the last 7 days."
            echo "Run './performance-monitor.sh --test' to generate initial data."
        else
            echo "Total measurements: $logs_found"
        fi

        echo ""
        echo "======================================"
    } > "$report_file"

    cat "$report_file"
    log "SUCCESS" "✅ Weekly report saved to: $report_file"
}

# Display help information
show_help() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTION]

Monitor Ghostty terminal performance and generate performance reports.

Options:
    --test          Run performance test and collect metrics
    --baseline      Establish performance baseline
    --compare       Compare current performance to baseline
    --weekly-report Generate weekly performance summary report
    --help          Display this help message and exit

Examples:
    $SCRIPT_NAME --test
        Run a performance test and save metrics to JSON

    $SCRIPT_NAME --weekly-report
        Generate a summary of all performance data from the last 7 days

    $SCRIPT_NAME --baseline
        Establish a baseline for performance comparison

Dependencies:
    Required: ghostty
    Optional: jq (for enhanced JSON output)

Output:
    Performance data is saved to: $LOG_DIR/performance-*.json
    Weekly reports are saved to: $LOG_DIR/weekly-report-*.txt

Exit Codes:
    0    Success
    1    Error (missing dependencies, invalid arguments, etc.)

EOF
}

# Main function
main() {
    local mode="${1:-default}"

    # Handle help first
    if [[ "$mode" == "--help" || "$mode" == "-h" ]]; then
        show_help
        exit 0
    fi

    # Check dependencies
    check_dependencies

    # Process command
    case "$mode" in
        --test)
            monitor_ghostty_performance "test"
            ;;
        --baseline)
            monitor_ghostty_performance "baseline"
            ;;
        --compare)
            monitor_ghostty_performance "compare"
            log "INFO" "Comparison feature will be implemented in future version"
            ;;
        --weekly-report)
            generate_weekly_report
            ;;
        *)
            monitor_ghostty_performance "default"
            ;;
    esac
}

# Execute main function
main "$@"
