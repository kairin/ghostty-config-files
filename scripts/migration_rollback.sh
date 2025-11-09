#!/bin/bash
# Module: migration_rollback.sh
# Purpose: Package migration rollback system
# Dependencies: common.sh
# Modules Required: common.sh
# Exit Codes: 0=rollback successful, 1=rollback failed, 2=invalid argument

set -euo pipefail

# Module-level guard: Allow sourcing for testing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    SOURCED_FOR_TESTING=1
else
    SOURCED_FOR_TESTING=0
fi

# ============================================================
# MODULE DEPENDENCIES
# ============================================================

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "${SCRIPT_DIR}/common.sh"

# ============================================================
# ROLLBACK FUNCTIONS
# ============================================================

# Function: verify_backup
# Purpose: Validate backup integrity before rollback (T047)
# Args: $1=backup_id or backup_metadata_file
# Returns: 0 if valid, 1 if corrupted
# Side Effects: Logs validation results
verify_backup() {
    local backup_ref="${1:-}"

    if [[ -z "$backup_ref" ]]; then
        log_error "Backup ID or metadata file required for verification"
        return 2
    fi

    log_info "Verifying backup integrity: $backup_ref"

    # Determine if this is a backup ID or metadata file path
    local metadata_file
    if [[ -f "$backup_ref" ]]; then
        metadata_file="$backup_ref"
    else
        # Assume it's a backup ID, construct metadata path
        local backup_dir="${MIGRATION_BACKUP_DIR:-$HOME/.config/package-migration/backups}"
        metadata_file="$backup_dir/$backup_ref/metadata.json"
    fi

    # Check if metadata file exists
    if [[ ! -f "$metadata_file" ]]; then
        log_error "Backup metadata not found: $metadata_file"
        return 1
    fi

    # Parse metadata
    local backup_directory=$(json_parse "$metadata_file" '.backup_directory')

    if [[ ! -d "$backup_directory" ]]; then
        log_error "Backup directory not found: $backup_directory"
        return 1
    fi

    # Verify .deb files exist and checksums match
    local packages_count=$(json_parse "$metadata_file" '.packages | length')
    local verified=0
    local failed=0

    for ((i=0; i<packages_count; i++)); do
        local pkg_name=$(json_parse "$metadata_file" ".packages[$i].name")
        local deb_file=$(json_parse "$metadata_file" ".packages[$i].deb_file")
        local deb_checksum=$(json_parse "$metadata_file" ".packages[$i].deb_checksum")

        local full_deb_path="$backup_directory/$deb_file"

        # Check if .deb file exists
        if [[ ! -f "$full_deb_path" ]]; then
            log_error "Package backup missing: $pkg_name ($full_deb_path)"
            ((failed++))
            continue
        fi

        # Verify checksum
        local actual_checksum=$(sha256sum "$full_deb_path" | awk '{print $1}')
        local expected_checksum="${deb_checksum#sha256:}"  # Remove sha256: prefix

        if [[ "$actual_checksum" != "$expected_checksum" ]]; then
            log_error "Checksum mismatch for $pkg_name: expected $expected_checksum, got $actual_checksum"
            ((failed++))
        else
            log_debug "Verified backup for $pkg_name: checksum OK"
            ((verified++))
        fi
    done

    if [[ $failed -gt 0 ]]; then
        log_error "Backup verification failed: $failed/$packages_count packages corrupted"
        return 1
    fi

    log_info "Backup verification passed: $verified/$packages_count packages verified"
    return 0
}

# Function: remove_snap_package
# Purpose: Uninstall snap package with purge option (T048)
# Args: $1=package_name
# Returns: 0 if removed, 1 if failed
# Side Effects: Removes snap package from system
remove_snap_package() {
    local package_name="${1:-}"

    if [[ -z "$package_name" ]]; then
        log_error "Package name required for snap removal"
        return 2
    fi

    log_info "Removing snap package: $package_name"

    # Check if snap package is installed
    if ! snap list "$package_name" &>/dev/null; then
        log_warn "Snap package not installed: $package_name"
        return 0  # Not an error, already removed
    fi

    # Remove snap package (snap remove automatically purges)
    if sudo snap remove --purge "$package_name" 2>&1 | tee -a "$MIGRATION_LOG_DIR/rollback.log"; then
        log_info "Successfully removed snap package: $package_name"
        return 0
    else
        log_error "Failed to remove snap package: $package_name"
        return 1
    fi
}

# Function: reinstall_apt_package
# Purpose: Reinstall apt package from preserved .deb file (T049)
# Args: $1=package_name, $2=deb_file_path
# Returns: 0 if installed, 1 if failed
# Side Effects: Installs .deb package via dpkg
reinstall_apt_package() {
    local package_name="${1:-}"
    local deb_file="${2:-}"

    if [[ -z "$package_name" ]] || [[ -z "$deb_file" ]]; then
        log_error "Package name and .deb file path required for apt reinstall"
        return 2
    fi

    if [[ ! -f "$deb_file" ]]; then
        log_error ".deb file not found: $deb_file"
        return 1
    fi

    log_info "Reinstalling apt package from backup: $package_name"

    # Install .deb file via dpkg
    if sudo dpkg -i "$deb_file" 2>&1 | tee -a "$MIGRATION_LOG_DIR/rollback.log"; then
        # Fix any dependency issues
        sudo apt-get install -f -y &>/dev/null || true

        # Verify installation
        if dpkg -l "$package_name" 2>/dev/null | grep -q "^ii"; then
            log_info "Successfully reinstalled apt package: $package_name"
            return 0
        else
            log_error "Package reinstallation verification failed: $package_name"
            return 1
        fi
    else
        log_error "Failed to reinstall apt package: $package_name"
        return 1
    fi
}

# Function: restore_configs
# Purpose: Restore configuration files from backup (T050)
# Args: $1=backup_directory, $2=package_metadata_json
# Returns: 0 if restored, 1 if failed
# Side Effects: Restores config files to original locations
restore_configs() {
    local backup_directory="${1:-}"
    local package_json="${2:-}"

    if [[ -z "$backup_directory" ]] || [[ -z "$package_json" ]]; then
        log_error "Backup directory and package metadata required for config restoration"
        return 2
    fi

    local package_name=$(echo "$package_json" | jq -r '.name')
    log_info "Restoring configuration files for: $package_name"

    # Get config files array length
    local config_count=$(echo "$package_json" | jq '.config_files | length')

    if [[ "$config_count" == "0" ]] || [[ "$config_count" == "null" ]]; then
        log_debug "No configuration files to restore for $package_name"
        return 0
    fi

    local restored=0
    local failed=0

    for ((i=0; i<config_count; i++)); do
        local source_path=$(echo "$package_json" | jq -r ".config_files[$i].source_path")
        local backup_path=$(echo "$package_json" | jq -r ".config_files[$i].backup_path")
        local permissions=$(echo "$package_json" | jq -r ".config_files[$i].permissions")
        local owner=$(echo "$package_json" | jq -r ".config_files[$i].owner")

        local full_backup_path="$backup_directory/$backup_path"

        # Check if backup file exists
        if [[ ! -f "$full_backup_path" ]]; then
            log_warn "Config backup not found: $backup_path (skipping)"
            ((failed++))
            continue
        fi

        # Create parent directory if needed
        local parent_dir=$(dirname "$source_path")
        if [[ ! -d "$parent_dir" ]]; then
            sudo mkdir -p "$parent_dir"
        fi

        # Restore config file using rsync to preserve metadata
        if sudo rsync -a --checksum "$full_backup_path" "$source_path"; then
            # Restore permissions and ownership
            sudo chmod "$permissions" "$source_path"
            sudo chown "$owner" "$source_path"

            log_debug "Restored config: $source_path"
            ((restored++))
        else
            log_error "Failed to restore config: $source_path"
            ((failed++))
        fi
    done

    if [[ $failed -gt 0 ]]; then
        log_warn "Config restoration partially failed: $restored restored, $failed failed"
    else
        log_info "Successfully restored $restored configuration files"
    fi

    return 0
}

# Function: restore_services
# Purpose: Restore systemd service states (T051)
# Args: $1=package_metadata_json
# Returns: 0 if restored, 1 if failed
# Side Effects: Enables/starts systemd services
restore_services() {
    local package_json="${1:-}"

    if [[ -z "$package_json" ]]; then
        log_error "Package metadata required for service restoration"
        return 2
    fi

    local package_name=$(echo "$package_json" | jq -r '.name')
    log_info "Restoring systemd services for: $package_name"

    # Get services array length
    local service_count=$(echo "$package_json" | jq '.systemd_services | length')

    if [[ "$service_count" == "0" ]] || [[ "$service_count" == "null" ]]; then
        log_debug "No systemd services to restore for $package_name"
        return 0
    fi

    local restored=0
    local failed=0

    for ((i=0; i<service_count; i++)); do
        local service_name=$(echo "$package_json" | jq -r ".systemd_services[$i].service_name")
        local was_enabled=$(echo "$package_json" | jq -r ".systemd_services[$i].enabled")
        local was_active=$(echo "$package_json" | jq -r ".systemd_services[$i].active")

        log_debug "Restoring service $service_name (enabled=$was_enabled, active=$was_active)"

        # Restore enabled state
        if [[ "$was_enabled" == "true" ]]; then
            if sudo systemctl enable "$service_name" &>/dev/null; then
                log_debug "Enabled service: $service_name"
            else
                log_warn "Failed to enable service: $service_name"
                ((failed++))
            fi
        else
            sudo systemctl disable "$service_name" &>/dev/null || true
        fi

        # Restore active state
        if [[ "$was_active" == "true" ]]; then
            if sudo systemctl start "$service_name" &>/dev/null; then
                log_debug "Started service: $service_name"
                ((restored++))
            else
                log_warn "Failed to start service: $service_name"
                ((failed++))
            fi
        else
            sudo systemctl stop "$service_name" &>/dev/null || true
        fi
    done

    if [[ $failed -gt 0 ]]; then
        log_warn "Service restoration partially failed: $restored restored, $failed failed"
    else
        log_info "Successfully restored $restored systemd services"
    fi

    return 0
}

# Function: rollback_single_package
# Purpose: Complete rollback for a single package
# Args: $1=backup_metadata_file, $2=package_name
# Returns: 0 if successful, 1 if failed
# Side Effects: Performs complete rollback operation
rollback_single_package() {
    local metadata_file="${1:-}"
    local package_name="${2:-}"

    if [[ -z "$metadata_file" ]] || [[ -z "$package_name" ]]; then
        log_error "Metadata file and package name required for rollback"
        return 2
    fi

    log_info "Starting rollback for package: $package_name"

    # Parse backup metadata
    local backup_directory=$(json_parse "$metadata_file" '.backup_directory')

    # Find package in metadata
    local packages_count=$(json_parse "$metadata_file" '.packages | length')
    local package_json=""

    for ((i=0; i<packages_count; i++)); do
        local pkg_name=$(json_parse "$metadata_file" ".packages[$i].name")
        if [[ "$pkg_name" == "$package_name" ]]; then
            package_json=$(json_parse "$metadata_file" ".packages[$i]")
            break
        fi
    done

    if [[ -z "$package_json" ]]; then
        log_error "Package not found in backup: $package_name"
        return 1
    fi

    # Extract package details
    local deb_file=$(echo "$package_json" | jq -r '.deb_file')
    local full_deb_path="$backup_directory/$deb_file"

    # Step 1: Remove snap package
    log_info "Step 1/4: Removing snap package..."
    if ! remove_snap_package "$package_name"; then
        log_warn "Snap package removal failed (may not be installed)"
    fi

    # Step 2: Reinstall apt package
    log_info "Step 2/4: Reinstalling apt package..."
    if ! reinstall_apt_package "$package_name" "$full_deb_path"; then
        log_error "Rollback failed: apt package reinstallation failed"
        return 1
    fi

    # Step 3: Restore configurations
    log_info "Step 3/4: Restoring configuration files..."
    if ! restore_configs "$backup_directory" "$package_json"; then
        log_warn "Configuration restoration had issues (continuing)"
    fi

    # Step 4: Restore services
    log_info "Step 4/4: Restoring systemd services..."
    if ! restore_services "$package_json"; then
        log_warn "Service restoration had issues (continuing)"
    fi

    log_info "Rollback completed successfully for package: $package_name"
    return 0
}

# Function: rollback_batch
# Purpose: Rollback multiple packages in reverse migration order
# Args: $1=backup_metadata_file, $2=package_list (optional, defaults to all)
# Returns: 0 if successful, 1 if any package failed
# Side Effects: Performs batch rollback operation
rollback_batch() {
    local metadata_file="${1:-}"
    local package_list="${2:-}"

    if [[ -z "$metadata_file" ]]; then
        log_error "Metadata file required for batch rollback"
        return 2
    fi

    log_info "Starting batch rollback..."

    # Get all packages from backup
    local packages_count=$(json_parse "$metadata_file" '.packages | length')
    local packages_to_rollback=()

    if [[ -z "$package_list" ]]; then
        # Rollback all packages in reverse order
        for ((i=packages_count-1; i>=0; i--)); do
            local pkg_name=$(json_parse "$metadata_file" ".packages[$i].name")
            packages_to_rollback+=("$pkg_name")
        done
    else
        # Rollback specific packages in reverse order
        IFS=',' read -ra PKG_ARRAY <<< "$package_list"
        for ((i=${#PKG_ARRAY[@]}-1; i>=0; i--)); do
            packages_to_rollback+=("${PKG_ARRAY[$i]}")
        done
    fi

    local total=${#packages_to_rollback[@]}
    local succeeded=0
    local failed=0

    for pkg in "${packages_to_rollback[@]}"; do
        log_info "Rolling back package $((succeeded + failed + 1))/$total: $pkg"

        if rollback_single_package "$metadata_file" "$pkg"; then
            ((succeeded++))
        else
            ((failed++))
            log_error "Rollback failed for package: $pkg"
        fi
    done

    log_info "Batch rollback completed: $succeeded succeeded, $failed failed"

    if [[ $failed -gt 0 ]]; then
        return 1
    fi

    return 0
}

# ============================================================
# CLI INTERFACE
# ============================================================

# Function: show_usage
# Purpose: Display help message for rollback command
show_usage() {
    cat << 'EOF'
Usage: migration_rollback.sh <command> [options]

Commands:
  verify <backup-id>         Verify backup integrity before rollback
  rollback <backup-id> <pkg> Rollback single package
  rollback-all <backup-id>   Rollback all packages from backup

Options:
  --verify-only              Only verify backup, don't perform rollback
  --help                     Show this help message

Examples:
  migration_rollback.sh verify 20251109-143000
  migration_rollback.sh rollback 20251109-143000 firefox
  migration_rollback.sh rollback-all 20251109-143000
  migration_rollback.sh rollback-all 20251109-143000 --verify-only

Exit Codes:
  0 - Rollback successful
  1 - Rollback failed
  2 - Invalid arguments

EOF
}

# ============================================================
# MAIN EXECUTION
# ============================================================

if [[ "${SOURCED_FOR_TESTING}" -eq 0 ]]; then
    # Parse command line arguments
    COMMAND="${1:-}"
    VERIFY_ONLY="false"

    # Load configuration
    load_config "$HOME/.config/package-migration/config.json" 2>/dev/null || true

    # Ensure log directory exists
    MIGRATION_LOG_DIR="${MIGRATION_LOG_DIR:-/tmp/ghostty-start-logs}"
    ensure_dir "$MIGRATION_LOG_DIR"

    case "$COMMAND" in
        verify)
            BACKUP_ID="${2:-}"
            if [[ -z "$BACKUP_ID" ]]; then
                echo "Error: Backup ID required" >&2
                show_usage
                exit 2
            fi

            if verify_backup "$BACKUP_ID"; then
                echo "Backup verification: PASS"
                exit 0
            else
                echo "Backup verification: FAIL"
                exit 1
            fi
            ;;

        rollback)
            BACKUP_ID="${2:-}"
            PACKAGE_NAME="${3:-}"

            if [[ -z "$BACKUP_ID" ]] || [[ -z "$PACKAGE_NAME" ]]; then
                echo "Error: Backup ID and package name required" >&2
                show_usage
                exit 2
            fi

            # Construct metadata file path
            BACKUP_DIR="${MIGRATION_BACKUP_DIR:-$HOME/.config/package-migration/backups}"
            METADATA_FILE="$BACKUP_DIR/$BACKUP_ID/metadata.json"

            # Verify backup first
            if ! verify_backup "$METADATA_FILE"; then
                echo "Error: Backup verification failed" >&2
                exit 1
            fi

            # Perform rollback
            if rollback_single_package "$METADATA_FILE" "$PACKAGE_NAME"; then
                echo "Rollback completed successfully: $PACKAGE_NAME"
                exit 0
            else
                echo "Rollback failed: $PACKAGE_NAME"
                exit 1
            fi
            ;;

        rollback-all)
            BACKUP_ID="${2:-}"
            shift 2 || true

            if [[ -z "$BACKUP_ID" ]]; then
                echo "Error: Backup ID required" >&2
                show_usage
                exit 2
            fi

            # Parse options
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --verify-only)
                        VERIFY_ONLY="true"
                        shift
                        ;;
                    *)
                        echo "Error: Unknown option: $1" >&2
                        show_usage
                        exit 2
                        ;;
                esac
            done

            # Construct metadata file path
            BACKUP_DIR="${MIGRATION_BACKUP_DIR:-$HOME/.config/package-migration/backups}"
            METADATA_FILE="$BACKUP_DIR/$BACKUP_ID/metadata.json"

            # Verify backup
            if ! verify_backup "$METADATA_FILE"; then
                echo "Error: Backup verification failed" >&2
                exit 1
            fi

            if [[ "$VERIFY_ONLY" == "true" ]]; then
                echo "Backup verification passed (verify-only mode)"
                exit 0
            fi

            # Perform batch rollback
            if rollback_batch "$METADATA_FILE"; then
                echo "Batch rollback completed successfully"
                exit 0
            else
                echo "Batch rollback failed (check logs for details)"
                exit 1
            fi
            ;;

        --help|help)
            show_usage
            exit 0
            ;;

        *)
            echo "Error: Unknown command: $COMMAND" >&2
            show_usage
            exit 2
            ;;
    esac
fi
