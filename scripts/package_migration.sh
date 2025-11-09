#!/bin/bash
# Module: package_migration.sh
# Purpose: Main CLI orchestrator for package migration system (apt → snap)
# Dependencies: audit_packages.sh, common.sh, progress.sh
# Exit Codes: 0=success, 1=general failure, 2=invalid argument, 3=missing dependency

set -euo pipefail

# Module-level guard: Allow sourcing for testing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    PM_SOURCED_FOR_TESTING=1
else
    PM_SOURCED_FOR_TESTING=0
fi

# Source required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/progress.sh"

# ============================================================
# CONFIGURATION
# ============================================================

VERSION="0.1.0"
PROG_NAME="$(basename "$0")"

# Default configuration
CONFIG_FILE="${HOME}/.config/package-migration/config.json"
CACHE_DIR="${HOME}/.config/package-migration/cache"
BACKUP_DIR="${HOME}/.config/package-migration/backups"

# ============================================================
# UTILITY FUNCTIONS
# ============================================================

# Function: show_version
# Purpose: Display version information
# Args: None
# Returns: 0
# Side Effects: Prints version to stdout
show_version() {
    cat <<EOF
$PROG_NAME version $VERSION
Package Migration System (apt → snap)
EOF
    return 0
}

# Function: show_help
# Purpose: Display usage help
# Args: None
# Returns: 0
# Side Effects: Prints help text to stdout
show_help() {
    cat <<EOF
Usage: $PROG_NAME <command> [options]

Package Migration System - Safely migrate apt packages to snap equivalents

COMMANDS:
    audit       Audit installed packages and identify snap alternatives
    health      Run pre-migration health checks
    migrate     Migrate packages from apt to snap
    rollback    Rollback a migration to restore apt packages
    status      Show current migration status
    help        Show this help message
    version     Show version information

AUDIT COMMAND:
    $PROG_NAME audit [options]

    OPTIONS:
        --json              Output results in JSON format (default: text table)
        --no-cache          Force fresh audit, ignore cache
        --filter <pattern>  Filter packages by name pattern (regex)
        --sort <field>      Sort by field: name|size|equivalence (default: name)
        --output <file>     Write output to file instead of stdout

    EXAMPLES:
        $PROG_NAME audit                    # Run audit with text output
        $PROG_NAME audit --json             # Run audit with JSON output
        $PROG_NAME audit --no-cache --json  # Force fresh audit, output JSON
        $PROG_NAME audit --filter "^firefox" # Audit only Firefox-related packages

HEALTH COMMAND:
    $PROG_NAME health [options]

    OPTIONS:
        --check <type>      Run specific check: disk|network|snapd|conflicts|all
        --fix               Attempt to fix detected issues
        --json              Output results in JSON format

MIGRATE COMMAND:
    $PROG_NAME migrate <package> [options]

    OPTIONS:
        --dry-run           Simulate migration without making changes
        --no-backup         Skip backup creation (not recommended)
        --force             Skip interactive confirmations

ROLLBACK COMMAND:
    $PROG_NAME rollback <backup-id> [options]

    OPTIONS:
        --dry-run           Simulate rollback without making changes
        --force             Skip interactive confirmations

ENVIRONMENT VARIABLES:
    CACHE_TTL           Cache expiration time in seconds (default: 3600)
    LOG_JSON            Enable JSON logging (default: 0)
    DEBUG               Enable debug logging (default: 0)

EXAMPLES:
    $PROG_NAME audit --json > audit-report.json
    $PROG_NAME health --check all
    $PROG_NAME migrate firefox --dry-run
    $PROG_NAME rollback 20251109-143000

For more information, see: documentations/user/package-migration/
EOF
    return 0
}

# ============================================================
# COMMAND HANDLERS
# ============================================================

# Function: cmd_audit
# Purpose: Handle audit command
# Args: $@ - Command-line arguments
# Returns: Exit code from audit_packages.sh
# Side Effects: Executes audit and prints results
cmd_audit() {
    local output_format="text"
    local use_cache="true"
    local filter_pattern=""
    local sort_field="name"
    local output_file=""

    # Parse audit-specific options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                output_format="json"
                shift
                ;;
            --no-cache)
                use_cache="false"
                shift
                ;;
            --filter)
                filter_pattern="$2"
                shift 2
                ;;
            --sort)
                sort_field="$2"
                shift 2
                ;;
            --output)
                output_file="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                return 0
                ;;
            *)
                log_event ERROR "Unknown audit option: $1"
                echo "Use '$PROG_NAME audit --help' for usage information" >&2
                return 2
                ;;
        esac
    done

    log_event INFO "Starting package audit (format: $output_format, cache: $use_cache)"

    # Execute audit via audit_packages.sh
    local audit_script="$SCRIPT_DIR/audit_packages.sh"

    if [[ ! -x "$audit_script" ]]; then
        log_event ERROR "Audit script not found or not executable: $audit_script"
        return 3
    fi

    # Build command arguments
    local audit_args=()
    [[ "$output_format" == "json" ]] && audit_args+=("--json")
    [[ "$use_cache" == "false" ]] && audit_args+=("--no-cache")

    # Execute audit
    if [[ -n "$output_file" ]]; then
        "$audit_script" "${audit_args[@]}" > "$output_file"
        log_event INFO "Audit results written to: $output_file"
    else
        "$audit_script" "${audit_args[@]}"
    fi

    return $?
}

# Function: cmd_health
# Purpose: Handle health check command (T035)
# Args: $@ - Command-line arguments
# Returns: 0 if all checks pass, 1 if critical failure, 2 if warnings
# Side Effects: Executes health checks via migration_health_checks.sh
cmd_health() {
    local check_type="all"
    local auto_fix="false"
    local output_format="text"
    local apt_package=""
    local snap_package=""

    # Parse health-specific options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --check)
                check_type="$2"
                shift 2
                ;;
            --fix)
                auto_fix="true"
                shift
                ;;
            --json)
                output_format="json"
                shift
                ;;
            --package)
                apt_package="$2"
                snap_package="${3:-$2}"
                shift 2
                [[ -n "${3:-}" ]] && shift
                ;;
            --help|-h)
                show_help
                return 0
                ;;
            *)
                log_event ERROR "Unknown health option: $1"
                echo "Use '$PROG_NAME health --help' for usage information" >&2
                return 2
                ;;
        esac
    done

    # Log to stderr if JSON output to keep stdout clean
    if [[ "$output_format" == "json" ]]; then
        log_event INFO "Running health checks (type: $check_type, auto-fix: $auto_fix)" >&2
    else
        log_event INFO "Running health checks (type: $check_type, auto-fix: $auto_fix)"
    fi

    # Execute health checks via migration_health_checks.sh
    local health_script="$SCRIPT_DIR/migration_health_checks.sh"

    if [[ ! -x "$health_script" ]]; then
        log_event ERROR "Health check script not found or not executable: $health_script"
        return 3
    fi

    # Build command arguments
    local health_args=()

    case "$check_type" in
        disk|disk-space)
            health_args+=("disk-space")
            [[ -n "$apt_package" ]] && health_args+=("$apt_package" "$snap_package")
            ;;
        network|net)
            health_args+=("network")
            ;;
        snapd|daemon)
            health_args+=("snapd")
            [[ "$auto_fix" == "true" ]] && health_args+=("auto-fix")
            ;;
        conflicts)
            if [[ -z "$apt_package" ]]; then
                log_event ERROR "Conflicts check requires --package option"
                echo "Use: $PROG_NAME health --check conflicts --package <name>" >&2
                return 2
            fi
            health_args+=("conflicts" "$apt_package" "$snap_package")
            ;;
        all|aggregate)
            health_args+=("all")
            [[ -n "$apt_package" ]] && health_args+=("$apt_package" "$snap_package")
            [[ "$auto_fix" == "true" ]] && health_args+=("auto-fix")
            ;;
        *)
            log_event ERROR "Invalid check type: $check_type"
            echo "Valid types: disk, network, snapd, conflicts, all" >&2
            return 2
            ;;
    esac

    # Execute health checks and capture both stdout and exit code
    local result
    local exit_code
    result=$("$health_script" "${health_args[@]}" 2>&1)
    exit_code=$?

    # Extract JSON array from result (filter out log lines)
    # JSON array starts with '[{' and ends with '}]'
    local json_result
    json_result=$(echo "$result" | sed -n '/^\[{/,/^}]$/p')

    if [[ -z "$json_result" ]]; then
        # No JSON found, output raw result
        echo "$result" >&2
        return $exit_code
    fi

    # Format output based on requested format
    if [[ "$output_format" == "json" ]]; then
        echo "$json_result"
    else
        # Pretty-print JSON results for text format
        if command -v jq >/dev/null 2>&1; then
            echo "======================================================================"
            echo "  Health Check Results"
            echo "======================================================================"
            echo ""
            echo "$json_result" | jq -r '.[] | "[\(.status | ascii_upcase)] \(.check_name)\n  Status: \(.measured_value)\n  Message: \(.message)" + (if .remediation != null then "\n  Remediation: \(.remediation)" else "" end) + "\n"'
            echo "======================================================================"

            # Summary
            local total=$(echo "$json_result" | jq '. | length')
            local passed=$(echo "$json_result" | jq '[.[] | select(.status == "pass")] | length')
            local failed=$(echo "$json_result" | jq '[.[] | select(.status == "fail")] | length')
            local warnings=$(echo "$json_result" | jq '[.[] | select(.status == "warning")] | length')

            echo "Summary: $passed passed, $warnings warnings, $failed failed (total: $total)"
            echo "======================================================================"
        else
            # Fallback if jq not available
            echo "$json_result"
        fi
    fi

    return $exit_code
}

# Function: cmd_migrate
# Purpose: Handle migration command
# Args: $@ - Command-line arguments
# Returns: 0 on success, non-zero on failure
# Side Effects: Performs package migration
cmd_migrate() {
    log_event ERROR "Migration command not yet implemented"
    echo "The 'migrate' command will be available in Phase 4 (User Story 2)" >&2
    return 1
}

# Function: cmd_rollback
# Purpose: Handle rollback command
# Args: $@ - Command-line arguments
# Returns: 0 on success, non-zero on failure
# Side Effects: Performs rollback
cmd_rollback() {
    log_event ERROR "Rollback command not yet implemented"
    echo "The 'rollback' command will be available in Phase 4 (User Story 2)" >&2
    return 1
}

# Function: cmd_status
# Purpose: Handle status command
# Args: $@ - Command-line arguments
# Returns: 0 on success, non-zero on failure
# Side Effects: Displays migration status
cmd_status() {
    log_event INFO "Checking migration system status..."

    echo "======================================================================"
    echo "  Package Migration System Status"
    echo "======================================================================"
    echo ""
    echo "Configuration:"
    echo "  Config file: $CONFIG_FILE"
    echo "  Cache directory: $CACHE_DIR"
    echo "  Backup directory: $BACKUP_DIR"
    echo ""

    # Check directory existence
    echo "Directory Status:"
    [[ -d "$CACHE_DIR" ]] && echo "  ✓ Cache directory exists" || echo "  ✗ Cache directory missing"
    [[ -d "$BACKUP_DIR" ]] && echo "  ✓ Backup directory exists" || echo "  ✗ Backup directory missing"
    echo ""

    # Check for active migrations
    echo "Active Migrations: None (migration tracking not yet implemented)"
    echo ""

    # Check dependencies
    echo "Dependencies:"
    command -v dpkg-query >/dev/null 2>&1 && echo "  ✓ dpkg-query available" || echo "  ✗ dpkg-query missing"
    command -v apt-cache >/dev/null 2>&1 && echo "  ✓ apt-cache available" || echo "  ✗ apt-cache missing"
    command -v jq >/dev/null 2>&1 && echo "  ✓ jq available" || echo "  ✗ jq missing"
    command -v curl >/dev/null 2>&1 && echo "  ✓ curl available" || echo "  ✗ curl missing"
    [[ -e "/run/snapd.socket" ]] && echo "  ✓ snapd socket available" || echo "  ✗ snapd socket missing"
    echo ""

    echo "======================================================================"
    echo "System ready for Phase 3 (Audit) operations"
    echo "======================================================================"

    return 0
}

# ============================================================
# MAIN EXECUTION
# ============================================================

if [[ "${PM_SOURCED_FOR_TESTING}" -eq 0 ]]; then
    # Ensure configuration directories exist
    mkdir -p "$CACHE_DIR" "$BACKUP_DIR"

    # Parse global options
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi

    # Get command
    COMMAND="$1"
    shift

    # Route to appropriate command handler
    case "$COMMAND" in
        audit)
            cmd_audit "$@"
            exit $?
            ;;
        health)
            cmd_health "$@"
            exit $?
            ;;
        migrate)
            cmd_migrate "$@"
            exit $?
            ;;
        rollback)
            cmd_rollback "$@"
            exit $?
            ;;
        status)
            cmd_status "$@"
            exit $?
            ;;
        version|-v|--version)
            show_version
            exit 0
            ;;
        help|-h|--help)
            show_help
            exit 0
            ;;
        *)
            log_event ERROR "Unknown command: $COMMAND"
            echo "Use '$PROG_NAME help' for usage information" >&2
            exit 2
            ;;
    esac
fi
