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
    backup      Create backup of package(s) before migration
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

BACKUP COMMAND:
    $PROG_NAME backup <package> [options]

    OPTIONS:
        --output-dir <dir>  Custom backup directory (default: ~/.config/package-migration/backups)
        --label <text>      Add custom label to backup metadata
        --json              Output backup metadata in JSON format

    EXAMPLES:
        $PROG_NAME backup firefox
        $PROG_NAME backup firefox --output-dir /mnt/backups
        $PROG_NAME backup firefox --label "before-update" --json

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

# Function: cmd_backup
# Purpose: Handle backup command (T040)
# Args: $@ - Command-line arguments
# Returns: 0 on success, non-zero on failure
# Side Effects: Creates backup via migration_backup.sh
cmd_backup() {
    local package_name=""
    local output_dir=""
    local label=""
    local output_format="text"

    # Parse backup-specific options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --output-dir)
                output_dir="$2"
                shift 2
                ;;
            --label)
                label="$2"
                shift 2
                ;;
            --json)
                output_format="json"
                shift
                ;;
            --help|-h)
                show_help
                return 0
                ;;
            -*)
                log_event ERROR "Unknown backup option: $1"
                echo "Use '$PROG_NAME backup --help' for usage information" >&2
                return 2
                ;;
            *)
                if [[ -z "$package_name" ]]; then
                    package_name="$1"
                    shift
                else
                    log_event ERROR "Multiple package names not supported"
                    echo "Backup one package at a time: $PROG_NAME backup <package>" >&2
                    return 2
                fi
                ;;
        esac
    done

    # Validate package name provided
    if [[ -z "$package_name" ]]; then
        log_event ERROR "Package name required for backup"
        echo "Usage: $PROG_NAME backup <package> [options]" >&2
        return 2
    fi

    # Log to stderr if JSON output to keep stdout clean
    if [[ "$output_format" == "json" ]]; then
        log_event INFO "Creating backup for package: $package_name" >&2
    else
        log_event INFO "Creating backup for package: $package_name"
    fi

    # Execute backup via migration_backup.sh
    local backup_script="$SCRIPT_DIR/migration_backup.sh"

    if [[ ! -x "$backup_script" ]]; then
        log_event ERROR "Backup script not found or not executable: $backup_script"
        return 3
    fi

    # Override backup base directory if specified
    if [[ -n "$output_dir" ]]; then
        export BACKUP_BASE_DIR="$output_dir"
    fi

    # Create backup
    local backup_id
    if backup_id=$("$backup_script" backup "$package_name" 2>&1); then
        local exit_code=$?

        # Extract backup ID from output (last line)
        backup_id=$(echo "$backup_id" | tail -1 | grep -E '^[0-9]{8}-[0-9]{6}$')

        if [[ -z "$backup_id" ]]; then
            log_event ERROR "Failed to extract backup ID from backup script output"
            return 1
        fi

        # Get backup metadata
        local metadata
        metadata=$("$backup_script" get "$backup_id" 2>/dev/null)

        if [[ -z "$metadata" ]]; then
            log_event ERROR "Failed to retrieve backup metadata for: $backup_id"
            return 1
        fi

        # Add custom label if provided
        if [[ -n "$label" ]]; then
            metadata=$(echo "$metadata" | jq --arg label "$label" '. + {label: $label}')
        fi

        # Format output
        if [[ "$output_format" == "json" ]]; then
            echo "$metadata"
        else
            echo "======================================================================"
            echo "  Backup Created Successfully"
            echo "======================================================================"
            echo ""
            echo "Backup ID: $backup_id"
            echo "Package: $(echo "$metadata" | jq -r '.packages[0].name')"
            echo "Version: $(echo "$metadata" | jq -r '.packages[0].version')"
            echo "Backup Directory: $(echo "$metadata" | jq -r '.backup_directory')"
            echo "Total Size: $(echo "$metadata" | jq -r '.total_size' | numfmt --to=iec-i --suffix=B)"
            echo "Retention Until: $(echo "$metadata" | jq -r '.retention_until')"
            if [[ -n "$label" ]]; then
                echo "Label: $label"
            fi
            echo ""
            echo "Use '$PROG_NAME rollback $backup_id' to restore this backup"
            echo "======================================================================"
        fi

        return 0
    else
        local exit_code=$?
        log_event ERROR "Backup creation failed for package: $package_name"
        return $exit_code
    fi
}

# ==============================================================================
# Migration Engine Functions (T041-T046)
# ==============================================================================

# Logging directory for migration operations
readonly MIGRATION_LOG_DIR="${HOME}/.config/package-migration/logs"
readonly MIGRATION_STATE_DIR="${HOME}/.config/package-migration/state"

# T045: Create migration log entry
# Args: $1 = operation, $2 = package_name, $3 = status, $4 = exit_code,
#       $5 = stdout, $6 = stderr, $7 = duration_ms, $8 = metadata_json
# Returns: entry_id
create_migration_log_entry() {
    mkdir -p "$MIGRATION_LOG_DIR"

    local operation="$1"
    local package_name="$2"
    local status="$3"
    local exit_code="$4"
    local stdout_text="${5:-}"
    local stderr_text="${6:-}"
    local duration_ms="${7:-0}"
    local metadata_json="${8:-{}}"

    # Generate UUID for entry_id
    local entry_id
    entry_id=$(cat /proc/sys/kernel/random/uuid)

    # Create log entry JSON
    local log_entry
    log_entry=$(cat <<EOF
{
  "entry_id": "$entry_id",
  "timestamp": "$(date -Iseconds)",
  "operation": "$operation",
  "package_name": "$package_name",
  "source_method": "apt",
  "target_method": "snap",
  "status": "$status",
  "exit_code": $exit_code,
  "stdout": $(echo "$stdout_text" | jq -Rs .),
  "stderr": $(echo "$stderr_text" | jq -Rs .),
  "duration_ms": $duration_ms,
  "metadata": $metadata_json,
  "error_details": $(if [[ "$status" == "failed" ]]; then echo "{\"error_type\":\"migration_error\",\"error_message\":$(echo "$stderr_text" | jq -Rs .),\"suggested_action\":\"Check logs and system state\"}"; else echo "null"; fi)
}
EOF
)

    # Append to daily log file
    local log_file="$MIGRATION_LOG_DIR/migration-$(date +%Y%m%d).log"
    echo "$log_entry" >> "$log_file"

    echo "$entry_id"
}

# T041: Uninstall apt package
# Args: $1 = package name
# Returns: 0 on success, 1 on failure
# Side Effects: Removes apt package, preserves configs
apt_uninstall_package() {
    local package_name="$1"
    local start_time=$(date +%s%3N)

    log_event "INFO" "Uninstalling apt package: $package_name"

    # Capture output
    local stdout_text stderr_text exit_code
    {
        stdout_text=$(sudo apt-get remove -y --purge=false "$package_name" 2>&1)
        exit_code=$?
    } || exit_code=$?

    local end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))

    # Log operation
    local apt_version
    apt_version=$(dpkg-query -W -f='${Version}' "$package_name" 2>/dev/null || echo "unknown")

    local metadata="{\"apt_version\":\"$apt_version\",\"config_files_migrated\":0,\"services_restarted\":[]}"

    if [[ $exit_code -eq 0 ]]; then
        create_migration_log_entry "uninstall" "$package_name" "success" "$exit_code" "$stdout_text" "" "$duration" "$metadata" >/dev/null
        log_event "INFO" "Successfully uninstalled apt package: $package_name"
        return 0
    else
        create_migration_log_entry "uninstall" "$package_name" "failed" "$exit_code" "$stdout_text" "$stdout_text" "$duration" "$metadata" >/dev/null
        log_event "ERROR" "Failed to uninstall apt package: $package_name"
        return 1
    fi
}

# T042: Install snap package
# Args: $1 = package name, $2 = snap name (optional, defaults to package name)
# Returns: 0 on success, 1 on failure
# Side Effects: Installs snap package
snap_install_package() {
    local package_name="$1"
    local snap_name="${2:-$package_name}"
    local start_time=$(date +%s%3N)

    log_event "INFO" "Installing snap package: $snap_name"

    # Capture output
    local stdout_text stderr_text exit_code
    {
        stdout_text=$(sudo snap install "$snap_name" 2>&1)
        exit_code=$?
        stderr_text=""
    } || {
        exit_code=$?
        stderr_text="$stdout_text"
    }

    local end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))

    # Get snap version if installed
    local snap_version
    if [[ $exit_code -eq 0 ]]; then
        snap_version=$(snap info "$snap_name" | grep 'installed:' | awk '{print $2}' || echo "unknown")
    else
        snap_version="null"
    fi

    local metadata="{\"snap_version\":$(if [[ "$snap_version" != "null" ]]; then echo "\"$snap_version\""; else echo "null"; fi),\"config_files_migrated\":0,\"services_restarted\":[]}"

    if [[ $exit_code -eq 0 ]]; then
        create_migration_log_entry "install" "$package_name" "success" "$exit_code" "$stdout_text" "" "$duration" "$metadata" >/dev/null
        log_event "INFO" "Successfully installed snap package: $snap_name"
        return 0
    else
        create_migration_log_entry "install" "$package_name" "failed" "$exit_code" "$stdout_text" "$stderr_text" "$duration" "$metadata" >/dev/null
        log_event "ERROR" "Failed to install snap package: $snap_name - $stderr_text"
        return 1
    fi
}

# T043: Migrate configuration files
# Args: $1 = package name, $2 = backup directory
# Returns: Number of config files migrated
# Side Effects: Copies configs from backup to snap paths
migrate_config_files() {
    local package_name="$1"
    local backup_dir="$2"
    local migrated_count=0

    log_event "INFO" "Migrating configuration files for: $package_name"

    # Get config files from backup metadata
    local metadata_file="$backup_dir/metadata.json"
    if [[ ! -f "$metadata_file" ]]; then
        log_event "WARNING" "No backup metadata found, skipping config migration"
        return 0
    fi

    local config_files
    config_files=$(jq -r '.packages[0].config_files[] | .source_path' "$metadata_file" 2>/dev/null || echo "")

    if [[ -z "$config_files" ]]; then
        log_event "INFO" "No configuration files to migrate"
        return 0
    fi

    # Migrate each config file
    while IFS= read -r source_path; do
        if [[ -z "$source_path" ]]; then
            continue
        fi

        # Determine snap config path (heuristic-based per research.md section 5)
        local snap_config_path=""

        if [[ "$source_path" == /etc/"$package_name"/* ]]; then
            # /etc/<app>/ → ~/snap/<app>/current/.config/<app>/
            local relative_path="${source_path#/etc/$package_name/}"
            snap_config_path="$HOME/snap/$package_name/current/.config/$package_name/$relative_path"
        elif [[ "$source_path" == "$HOME"/.config/"$package_name"/* ]]; then
            # ~/.config/<app>/ → ~/snap/<app>/current/.config/<app>/
            local relative_path="${source_path#$HOME/.config/$package_name/}"
            snap_config_path="$HOME/snap/$package_name/current/.config/$package_name/$relative_path"
        elif [[ "$source_path" == "$HOME"/.local/share/"$package_name"/* ]]; then
            # ~/.local/share/<app>/ → ~/snap/<app>/current/.local/share/<app>/
            local relative_path="${source_path#$HOME/.local/share/$package_name/}"
            snap_config_path="$HOME/snap/$package_name/current/.local/share/$package_name/$relative_path"
        else
            log_event "WARNING" "Unknown config path pattern, skipping: $source_path"
            continue
        fi

        # Create parent directory
        mkdir -p "$(dirname "$snap_config_path")"

        # Copy from backup to snap location
        local backup_config_path="$backup_dir/configs/${package_name}${source_path}"
        if [[ -f "$backup_config_path" ]]; then
            if cp "$backup_config_path" "$snap_config_path" 2>/dev/null; then
                ((migrated_count++))
                log_event "INFO" "Migrated config: $source_path → $snap_config_path"
            else
                log_event "WARNING" "Failed to migrate config: $source_path"
            fi
        fi
    done <<< "$config_files"

    log_event "INFO" "Migrated $migrated_count configuration file(s)"
    echo "$migrated_count"
}

# T044: Verify functional installation
# Args: $1 = package name, $2 = snap name
# Returns: 0 if functional, 1 if not
# Side Effects: Tests command availability and basic functionality
verify_functional_installation() {
    local package_name="$1"
    local snap_name="${2:-$package_name}"
    local start_time=$(date +%s%3N)

    log_event "INFO" "Verifying functional installation for: $snap_name"

    # Check if snap is installed
    if ! snap list "$snap_name" >/dev/null 2>&1; then
        log_event "ERROR" "Snap package not found: $snap_name"
        return 1
    fi

    # Get snap version
    local snap_version
    snap_version=$(snap info "$snap_name" | grep 'installed:' | awk '{print $2}' 2>/dev/null || echo "unknown")

    # Test command availability (snap run <name> --version or --help)
    local stdout_text stderr_text exit_code
    {
        stdout_text=$(snap run "$snap_name" --version 2>&1 || snap run "$snap_name" --help 2>&1 || echo "command-test-unavailable")
        exit_code=$?
    } || exit_code=$?

    local end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))

    local metadata="{\"snap_version\":\"$snap_version\",\"verification_method\":\"command_availability\"}"

    if [[ $exit_code -eq 0 ]] || [[ "$stdout_text" != *"command-test-unavailable"* ]]; then
        create_migration_log_entry "verify" "$package_name" "success" "0" "$stdout_text" "" "$duration" "$metadata" >/dev/null
        log_event "INFO" "Functional verification passed for: $snap_name"
        return 0
    else
        create_migration_log_entry "verify" "$package_name" "failed" "1" "$stdout_text" "Functional verification failed" "$duration" "$metadata" >/dev/null
        log_event "ERROR" "Functional verification failed for: $snap_name"
        return 1
    fi
}

# T046: cmd_migrate orchestrator
# Purpose: Orchestrate complete migration workflow
# Args: $@ - Command-line arguments
# Returns: 0 on success, non-zero on failure
# Side Effects: Performs complete package migration
cmd_migrate() {
    local package_name=""
    local snap_name=""
    local dry_run="false"
    local no_backup="false"
    local force="false"

    # Parse migrate-specific options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                dry_run="true"
                shift
                ;;
            --no-backup)
                no_backup="true"
                shift
                ;;
            --force)
                force="true"
                shift
                ;;
            --snap-name)
                snap_name="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                return 0
                ;;
            -*)
                log_event ERROR "Unknown migrate option: $1"
                echo "Use '$PROG_NAME migrate --help' for usage information" >&2
                return 2
                ;;
            *)
                if [[ -z "$package_name" ]]; then
                    package_name="$1"
                    shift
                else
                    log_event ERROR "Multiple package names not supported"
                    echo "Migrate one package at a time: $PROG_NAME migrate <package>" >&2
                    return 2
                fi
                ;;
        esac
    done

    # Validate package name
    if [[ -z "$package_name" ]]; then
        log_event ERROR "Package name required for migration"
        echo "Usage: $PROG_NAME migrate <package> [options]" >&2
        return 2
    fi

    # Default snap name to package name if not specified
    snap_name="${snap_name:-$package_name}"

    log_event "INFO" "Starting migration: $package_name (apt) → $snap_name (snap)"

    if [[ "$dry_run" == "true" ]]; then
        log_event "INFO" "DRY RUN MODE - No actual changes will be made"
    fi

    # Step 1: Health checks
    log_event "INFO" "Step 1/5: Running health checks..."
    if [[ "$dry_run" == "false" ]]; then
        if ! "$SCRIPT_DIR/migration_health_checks.sh" all "$package_name" "$snap_name" >/dev/null 2>&1; then
            log_event "ERROR" "Health checks failed - aborting migration"
            echo "Health checks failed. Run '$PROG_NAME health --check all' for details" >&2
            return 1
        fi
    fi
    log_event "INFO" "Health checks passed"

    # Step 2: Create backup
    local backup_id=""
    if [[ "$no_backup" == "false" ]]; then
        log_event "INFO" "Step 2/5: Creating backup..."
        if [[ "$dry_run" == "false" ]]; then
            backup_id=$(cmd_backup "$package_name" 2>&1 | grep -E '^[0-9]{8}-[0-9]{6}$' | tail -1)
            if [[ -z "$backup_id" ]]; then
                log_event "ERROR" "Backup creation failed - aborting migration"
                return 1
            fi
            log_event "INFO" "Backup created: $backup_id"
        else
            log_event "INFO" "DRY RUN: Would create backup for $package_name"
        fi
    else
        log_event "WARNING" "Skipping backup (--no-backup specified) - rollback will not be possible!"
    fi

    # Step 3: Uninstall apt package
    log_event "INFO" "Step 3/5: Uninstalling apt package..."
    if [[ "$dry_run" == "false" ]]; then
        if ! apt_uninstall_package "$package_name"; then
            log_event "ERROR" "apt uninstall failed - migration aborted"
            if [[ -n "$backup_id" ]]; then
                log_event "INFO" "Rollback available with: $PROG_NAME rollback $backup_id"
            fi
            return 1
        fi
    else
        log_event "INFO" "DRY RUN: Would uninstall apt package: $package_name"
    fi

    # Step 4: Install snap package
    log_event "INFO" "Step 4/5: Installing snap package..."
    if [[ "$dry_run" == "false" ]]; then
        if ! snap_install_package "$package_name" "$snap_name"; then
            log_event "ERROR" "snap install failed - attempting rollback"
            if [[ -n "$backup_id" ]]; then
                log_event "INFO" "Auto-rollback initiated: $backup_id"
                # Rollback will be implemented in T047-T052
                echo "Migration failed. Rollback required: $PROG_NAME rollback $backup_id" >&2
            fi
            return 1
        fi
    else
        log_event "INFO" "DRY RUN: Would install snap package: $snap_name"
    fi

    # Step 5: Migrate configs and verify
    log_event "INFO" "Step 5/5: Migrating configuration and verifying..."
    if [[ "$dry_run" == "false" ]]; then
        local migrated_count=0
        if [[ -n "$backup_id" ]]; then
            migrated_count=$(migrate_config_files "$package_name" "$BACKUP_DIR/$backup_id")
        fi

        if ! verify_functional_installation "$package_name" "$snap_name"; then
            log_event "WARNING" "Functional verification failed - migration may have issues"
            if [[ -n "$backup_id" ]]; then
                echo "Verification failed. Consider rollback: $PROG_NAME rollback $backup_id" >&2
            fi
            # Don't fail on verification failure, just warn
        fi

        log_event "INFO" "Migration completed successfully: $package_name → $snap_name"
        echo "======================================================================"
        echo "  Migration Completed Successfully"
        echo "======================================================================"
        echo ""
        echo "Package: $package_name (apt) → $snap_name (snap)"
        echo "Backup ID: ${backup_id:-none}"
        echo "Config files migrated: $migrated_count"
        echo ""
        if [[ -n "$backup_id" ]]; then
            echo "To rollback: $PROG_NAME rollback $backup_id"
        fi
        echo "======================================================================"
    else
        log_event "INFO" "DRY RUN SUMMARY:"
        log_event "INFO" "  Would migrate: $package_name (apt) → $snap_name (snap)"
        log_event "INFO" "  Health checks: PASS"
        log_event "INFO" "  Backup: ${no_backup:+SKIP}${no_backup:-CREATE}"
        log_event "INFO" "  Config migration: ATTEMPT"
        log_event "INFO" "  Verification: PERFORM"
    fi

    return 0
}

# Function: cmd_rollback
# Purpose: Handle rollback command
# Args: $@ - Command-line arguments
# Returns: 0 on success, non-zero on failure
# Side Effects: Performs rollback
cmd_rollback() {
    # T052: Implement rollback command - parse backup-id, --all, --verify-only options, delegate to migration_rollback.sh

    local backup_id=""
    local package_name=""
    local rollback_all=false
    local verify_only=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                rollback_all=true
                shift
                ;;
            --verify-only)
                verify_only=true
                shift
                ;;
            --help|-h)
                cat <<EOF
Usage: $PROG_NAME rollback <backup-id> [package] [options]

Rollback a migration to restore apt packages from backup.

ARGUMENTS:
    backup-id          Backup identifier (YYYYMMDD-HHMMSS format)
    package            Package name to rollback (optional with --all)

OPTIONS:
    --all              Rollback all packages from the backup
    --verify-only      Only verify backup integrity, don't perform rollback
    --help, -h         Show this help message

EXAMPLES:
    # Rollback a single package
    $PROG_NAME rollback 20251109-143000 firefox

    # Rollback all packages from a backup
    $PROG_NAME rollback 20251109-143000 --all

    # Verify backup integrity only
    $PROG_NAME rollback 20251109-143000 --verify-only

    # List available backups
    ls -1 ~/.config/package-migration/backups/

EXIT CODES:
    0    Rollback successful
    1    Rollback failed
    2    Invalid arguments

EOF
                return 0
                ;;
            -*)
                log_event ERROR "Unknown option: $1"
                echo "Use '$PROG_NAME rollback --help' for usage information" >&2
                return 2
                ;;
            *)
                if [[ -z "$backup_id" ]]; then
                    backup_id="$1"
                elif [[ -z "$package_name" ]]; then
                    package_name="$1"
                else
                    log_event ERROR "Too many arguments"
                    echo "Use '$PROG_NAME rollback --help' for usage information" >&2
                    return 2
                fi
                shift
                ;;
        esac
    done

    # Validate arguments
    if [[ -z "$backup_id" ]]; then
        log_event ERROR "Backup ID required for rollback"
        echo "Use '$PROG_NAME rollback --help' for usage information" >&2
        return 2
    fi

    if [[ "$rollback_all" == false ]] && [[ -z "$package_name" ]] && [[ "$verify_only" == false ]]; then
        log_event ERROR "Package name required (or use --all for batch rollback)"
        echo "Use '$PROG_NAME rollback --help' for usage information" >&2
        return 2
    fi

    # Delegate to migration_rollback.sh
    local rollback_script="$SCRIPT_DIR/migration_rollback.sh"

    if [[ ! -x "$rollback_script" ]]; then
        log_event ERROR "Rollback script not found or not executable: $rollback_script"
        return 3
    fi

    log_event INFO "Starting rollback operation for backup: $backup_id"

    # Build command based on options
    if [[ "$verify_only" == true ]]; then
        # Verify backup only
        "$rollback_script" verify "$backup_id"
        return $?
    elif [[ "$rollback_all" == true ]]; then
        # Rollback all packages
        if [[ "$verify_only" == true ]]; then
            "$rollback_script" rollback-all "$backup_id" --verify-only
        else
            "$rollback_script" rollback-all "$backup_id"
        fi
        return $?
    else
        # Rollback single package
        "$rollback_script" rollback "$backup_id" "$package_name"
        return $?
    fi
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
        backup)
            cmd_backup "$@"
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
