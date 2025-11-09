#!/bin/bash
# migration_backup.sh - Package migration backup system
# Feature: 005-apt-snap-migration (Phase 4: User Story 2)
# Tasks: T036-T039 (Backup System)
#
# Purpose: Creates comprehensive system backups before package migration
# - .deb file download and verification (T036)
# - Configuration file backup with rsync (T037)
# - Systemd service state capture (T038)
# - PPA metadata backup (T038a)
# - MigrationBackup JSON metadata generation (T039)
#
# Output: MigrationBackup JSON object per data-model.md
# Exit codes: 0 = success, 1 = backup failure, 2 = invalid argument

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# ==============================================================================
# Constants & Configuration
# ==============================================================================

# Backup configuration
readonly BACKUP_BASE_DIR="${HOME}/.config/package-migration/backups"
readonly RETENTION_DAYS=30
readonly CHECKSUM_ALGORITHM="sha256sum"

# ==============================================================================
# T036: .deb Download Function
# ==============================================================================

# Download .deb file for apt package
# Args: $1 = package name, $2 = backup directory
# Returns: Relative path to downloaded .deb file
# Side Effects: Downloads .deb to backup_directory/debs/
download_deb_file() {
    # Redirect all logs to stderr to keep stdout clean for return value
    exec 3>&1 1>&2

    local package_name="$1"
    local backup_dir="$2"
    local debs_dir="$backup_dir/debs"

    mkdir -p "$debs_dir"

    log_event "INFO" "Downloading .deb file for package: $package_name"

    # Get package version
    local package_version
    package_version=$(dpkg-query -W -f='${Version}' "$package_name" 2>/dev/null || echo "")

    if [[ -z "$package_version" ]]; then
        log_event "ERROR" "Package $package_name not found or not installed"
        return 1
    fi

    # Download .deb file using apt-get download
    local deb_filename
    cd "$debs_dir"
    if apt-get download "$package_name" >/dev/null 2>&1; then
        # Find the downloaded .deb file (may have architecture suffix)
        deb_filename=$(ls -t "${package_name}"_*.deb 2>/dev/null | head -1)

        if [[ -z "$deb_filename" ]]; then
            log_event "ERROR" "Failed to locate downloaded .deb file for $package_name"
            return 1
        fi

        log_event "INFO" "Downloaded: $deb_filename"

        # Return relative path to original stdout
        echo "debs/$deb_filename" >&3
        return 0
    else
        log_event "ERROR" "apt-get download failed for $package_name"
        return 1
    fi
}

# Verify .deb file integrity
# Args: $1 = absolute path to .deb file, $2 = package name
# Returns: 0 if valid, 1 if invalid
verify_deb_file() {
    local deb_path="$1"
    local package_name="$2"

    if [[ ! -f "$deb_path" ]]; then
        log_event "ERROR" ".deb file not found: $deb_path"
        return 1
    fi

    # Verify using dpkg
    if dpkg --verify "$deb_path" >/dev/null 2>&1 || dpkg-deb --info "$deb_path" >/dev/null 2>&1; then
        log_event "INFO" ".deb file verified: $deb_path"
        return 0
    else
        log_event "ERROR" ".deb file verification failed: $deb_path"
        return 1
    fi
}

# Calculate checksum for file
# Args: $1 = file path
# Returns: sha256 checksum string
calculate_checksum() {
    # Redirect logs to stderr
    exec 3>&1 1>&2

    local file_path="$1"

    if [[ ! -f "$file_path" ]]; then
        log_event "ERROR" "Cannot calculate checksum - file not found: $file_path"
        return 1
    fi

    local checksum
    checksum=$($CHECKSUM_ALGORITHM "$file_path" 2>/dev/null | awk '{print $1}')
    echo "sha256:$checksum" >&3
}

# ==============================================================================
# T037: Configuration File Backup Function
# ==============================================================================

# Backup configuration files for a package
# Args: $1 = package name, $2 = backup directory
# Returns: JSON array of backed up config files
# Side Effects: Copies configs to backup_directory/configs/
backup_config_files() {
    # Redirect logs to stderr
    exec 3>&1 1>&2

    local package_name="$1"
    local backup_dir="$2"
    local configs_dir="$backup_dir/configs/$package_name"

    mkdir -p "$configs_dir"

    log_event "INFO" "Backing up configuration files for: $package_name"

    # Get list of config files for this package
    local config_files
    config_files=$(dpkg-query -W -f='${Conffiles}\n' "$package_name" 2>/dev/null | awk '{print $1}' | grep -v '^$' || echo "")

    if [[ -z "$config_files" ]]; then
        log_event "INFO" "No configuration files found for $package_name"
        echo "[]" >&3
        return 0
    fi

    # Backup each config file and generate JSON
    local json_array="["
    local first=true

    while IFS= read -r config_file; do
        if [[ ! -f "$config_file" ]]; then
            log_event "WARNING" "Config file does not exist, skipping: $config_file"
            continue
        fi

        # Create backup path preserving directory structure
        local relative_backup_path="configs/${package_name}${config_file}"
        local absolute_backup_path="$backup_dir/$relative_backup_path"

        # Create parent directories
        mkdir -p "$(dirname "$absolute_backup_path")"

        # Copy with rsync to preserve permissions and ownership
        if rsync -a --no-perms --no-owner --no-group "$config_file" "$absolute_backup_path" 2>/dev/null; then
            # Get file metadata
            local permissions=$(stat -c '%a' "$config_file")
            local owner=$(stat -c '%U:%G' "$config_file")
            local checksum=$(calculate_checksum "$absolute_backup_path")

            # Add to JSON array
            if $first; then
                first=false
            else
                json_array+=","
            fi

            json_array+=$(cat <<EOF
{
  "source_path": "$config_file",
  "backup_path": "$relative_backup_path",
  "checksum": "$checksum",
  "permissions": "$permissions",
  "owner": "$owner"
}
EOF
)
            log_event "INFO" "Backed up config: $config_file → $relative_backup_path"
        else
            log_event "WARNING" "Failed to backup config file: $config_file"
        fi
    done <<< "$config_files"

    json_array+="]"
    echo "$json_array" >&3
}

# ==============================================================================
# T038: Systemd Service State Capture Function
# ==============================================================================

# Capture systemd service states for a package
# Args: $1 = package name, $2 = backup directory
# Returns: JSON array of service states
# Side Effects: Copies service unit files to backup_directory/services/
capture_service_states() {
    # Redirect logs to stderr
    exec 3>&1 1>&2

    local package_name="$1"
    local backup_dir="$2"
    local services_dir="$backup_dir/services"

    mkdir -p "$services_dir"

    log_event "INFO" "Capturing systemd service states for: $package_name"

    # Find services associated with this package
    local service_files
    service_files=$(dpkg-query -L "$package_name" 2>/dev/null | grep -E '\.service$' || echo "")

    if [[ -z "$service_files" ]]; then
        log_event "INFO" "No systemd services found for $package_name"
        echo "[]" >&3
        return 0
    fi

    # Capture each service state
    local json_array="["
    local first=true

    while IFS= read -r service_file; do
        if [[ ! -f "$service_file" ]]; then
            continue
        fi

        local service_name=$(basename "$service_file")
        local service_unit="${service_name%.service}"

        # Check if service is enabled
        local is_enabled="false"
        if systemctl is-enabled "$service_unit" >/dev/null 2>&1; then
            is_enabled="true"
        fi

        # Check if service is active
        local is_active="false"
        if systemctl is-active "$service_unit" >/dev/null 2>&1; then
            is_active="true"
        fi

        # Backup service unit file
        local relative_service_path="services/$service_name"
        local absolute_service_path="$backup_dir/$relative_service_path"

        if cp "$service_file" "$absolute_service_path" 2>/dev/null; then
            # Add to JSON array
            if $first; then
                first=false
            else
                json_array+=","
            fi

            json_array+=$(cat <<EOF
{
  "service_name": "$service_unit",
  "service_file": "$relative_service_path",
  "enabled": $is_enabled,
  "active": $is_active
}
EOF
)
            log_event "INFO" "Captured service state: $service_unit (enabled=$is_enabled, active=$is_active)"
        else
            log_event "WARNING" "Failed to backup service file: $service_file"
        fi
    done <<< "$service_files"

    json_array+="]"
    echo "$json_array" >&3
}

# ==============================================================================
# T038a: PPA Metadata Backup Function
# ==============================================================================

# Backup PPA metadata for a package
# Args: $1 = package name, $2 = backup directory
# Returns: JSON object with PPA information
# Side Effects: Copies PPA sources and GPG keys to backup_directory/ppa/
backup_ppa_metadata() {
    # Redirect logs to stderr
    exec 3>&1 1>&2

    local package_name="$1"
    local backup_dir="$2"
    local ppa_dir="$backup_dir/ppa"

    mkdir -p "$ppa_dir"

    log_event "INFO" "Checking for PPA sources for: $package_name"

    # Check if package is from a PPA
    local package_source
    package_source=$(apt-cache policy "$package_name" 2>/dev/null | grep -oP '(?<= )http[s]?://ppa\.launchpad\.net/[^ ]+' | head -1 || echo "")

    if [[ -z "$package_source" ]]; then
        log_event "INFO" "Package $package_name is not from a PPA"
        echo '{"is_ppa": false}' >&3
        return 0
    fi

    # Extract PPA details
    local ppa_url="$package_source"
    local ppa_owner=$(echo "$ppa_url" | grep -oP 'ppa\.launchpad\.net/\K[^/]+' || echo "unknown")
    local ppa_name=$(echo "$ppa_url" | grep -oP 'ppa\.launchpad\.net/[^/]+/\K[^/]+' || echo "unknown")

    log_event "INFO" "Package $package_name is from PPA: $ppa_owner/$ppa_name"

    # Find and backup PPA source file
    local ppa_source_files=$(ls /etc/apt/sources.list.d/*${ppa_owner}*${ppa_name}*.list 2>/dev/null || echo "")
    local backed_up_sources="["
    local first=true

    if [[ -n "$ppa_source_files" ]]; then
        while IFS= read -r source_file; do
            if [[ -f "$source_file" ]]; then
                local source_filename=$(basename "$source_file")
                local backup_source_path="$ppa_dir/$source_filename"

                if cp "$source_file" "$backup_source_path" 2>/dev/null; then
                    if $first; then
                        first=false
                    else
                        backed_up_sources+=","
                    fi
                    backed_up_sources+="\"ppa/$source_filename\""
                    log_event "INFO" "Backed up PPA source: $source_filename"
                fi
            fi
        done <<< "$ppa_source_files"
    fi

    backed_up_sources+="]"

    # Backup GPG keys (stored in /etc/apt/trusted.gpg.d/)
    local gpg_keys=$(ls /etc/apt/trusted.gpg.d/*${ppa_owner}* 2>/dev/null || echo "")
    local backed_up_keys="["
    first=true

    if [[ -n "$gpg_keys" ]]; then
        while IFS= read -r gpg_key; do
            if [[ -f "$gpg_key" ]]; then
                local key_filename=$(basename "$gpg_key")
                local backup_key_path="$ppa_dir/$key_filename"

                if cp "$gpg_key" "$backup_key_path" 2>/dev/null; then
                    if $first; then
                        first=false
                    else
                        backed_up_keys+=","
                    fi
                    backed_up_keys+="\"ppa/$key_filename\""
                    log_event "INFO" "Backed up PPA GPG key: $key_filename"
                fi
            fi
        done <<< "$gpg_keys"
    fi

    backed_up_keys+="]"

    # Generate PPA metadata JSON
    cat <<EOF >&3
{
  "is_ppa": true,
  "ppa_owner": "$ppa_owner",
  "ppa_name": "$ppa_name",
  "ppa_url": "$ppa_url",
  "source_files": $backed_up_sources,
  "gpg_keys": $backed_up_keys
}
EOF
}

# ==============================================================================
# T039: Backup Metadata Generation Function
# ==============================================================================

# Create complete backup for a package
# Args: $1 = package name
# Returns: Backup ID (YYYYMMDD-HHMMSS)
# Side Effects: Creates backup directory with all artifacts and metadata.json
create_package_backup() {
    local package_name="$1"

    # Generate backup ID
    local backup_id=$(date +"%Y%m%d-%H%M%S")
    local backup_dir="$BACKUP_BASE_DIR/$backup_id"

    log_event "INFO" "Creating backup for package: $package_name (backup_id: $backup_id)"

    # Create backup directory structure
    mkdir -p "$backup_dir"/{debs,configs,services,ppa}

    # Get package metadata
    local package_version
    package_version=$(dpkg-query -W -f='${Version}' "$package_name" 2>/dev/null || echo "unknown")

    # Get package dependencies
    local dependencies
    dependencies=$(dpkg-query -W -f='${Depends}\n' "$package_name" 2>/dev/null | tr ',' '\n' | awk '{print $1}' | grep -v '^$' || echo "")
    local deps_json="["
    local first=true
    while IFS= read -r dep; do
        if [[ -n "$dep" ]]; then
            if $first; then
                first=false
            else
                deps_json+=","
            fi
            deps_json+="\"$dep\""
        fi
    done <<< "$dependencies"
    deps_json+="]"

    # T036: Download .deb file
    local deb_relative_path
    if deb_relative_path=$(download_deb_file "$package_name" "$backup_dir"); then
        local deb_absolute_path="$backup_dir/$deb_relative_path"
        local deb_checksum=$(calculate_checksum "$deb_absolute_path")
        verify_deb_file "$deb_absolute_path" "$package_name"
    else
        log_event "ERROR" "Failed to download .deb file for $package_name"
        return 1
    fi

    # T037: Backup configuration files
    local config_files_json
    config_files_json=$(backup_config_files "$package_name" "$backup_dir")

    # T038: Capture service states
    local services_json
    services_json=$(capture_service_states "$package_name" "$backup_dir")

    # T038a: Backup PPA metadata
    local ppa_metadata_json
    ppa_metadata_json=$(backup_ppa_metadata "$package_name" "$backup_dir")

    # Calculate total backup size
    local total_size
    total_size=$(du -sb "$backup_dir" | awk '{print $1}')

    # Calculate retention date
    local retention_until
    retention_until=$(date -d "+${RETENTION_DAYS} days" -Iseconds)

    # Generate MigrationBackup JSON metadata
    local metadata_json
    metadata_json=$(cat <<EOF
{
  "backup_id": "$backup_id",
  "timestamp": "$(date -Iseconds)",
  "backup_directory": "$backup_dir",
  "packages": [
    {
      "name": "$package_name",
      "version": "$package_version",
      "installation_method": "apt",
      "deb_file": "$deb_relative_path",
      "deb_checksum": "$deb_checksum",
      "dependencies": $deps_json,
      "config_files": $config_files_json,
      "systemd_services": $services_json,
      "ppa_metadata": $ppa_metadata_json
    }
  ],
  "total_size": $total_size,
  "retention_until": "$retention_until"
}
EOF
)

    # Write metadata to file
    echo "$metadata_json" > "$backup_dir/metadata.json"

    log_event "INFO" "Backup completed successfully: $backup_id"
    log_event "INFO" "Backup location: $backup_dir"
    log_event "INFO" "Total backup size: $(numfmt --to=iec-i --suffix=B $total_size)"

    # Return backup ID
    echo "$backup_id"
}

# List all backups
# Returns: JSON array of backup metadata summaries
list_backups() {
    local backups_json="["
    local first=true

    if [[ -d "$BACKUP_BASE_DIR" ]]; then
        for backup_dir in "$BACKUP_BASE_DIR"/*/; do
            if [[ -f "$backup_dir/metadata.json" ]]; then
                if $first; then
                    first=false
                else
                    backups_json+=","
                fi

                local metadata=$(cat "$backup_dir/metadata.json")
                backups_json+="$metadata"
            fi
        done
    fi

    backups_json+="]"
    echo "$backups_json"
}

# Get specific backup metadata
# Args: $1 = backup ID
# Returns: MigrationBackup JSON object
get_backup_metadata() {
    local backup_id="$1"
    local metadata_file="$BACKUP_BASE_DIR/$backup_id/metadata.json"

    if [[ ! -f "$metadata_file" ]]; then
        log_event "ERROR" "Backup not found: $backup_id"
        return 1
    fi

    cat "$metadata_file"
}

# ==============================================================================
# Main Entry Point (for standalone execution)
# ==============================================================================

main() {
    local command="${1:-backup}"
    shift || true

    case "$command" in
        backup|create)
            if [[ $# -lt 1 ]]; then
                echo "Error: Package name required" >&2
                echo "Usage: migration_backup.sh backup <package-name>" >&2
                return 2
            fi
            create_package_backup "$1"
            ;;
        list)
            list_backups
            ;;
        get)
            if [[ $# -lt 1 ]]; then
                echo "Error: Backup ID required" >&2
                echo "Usage: migration_backup.sh get <backup-id>" >&2
                return 2
            fi
            get_backup_metadata "$1"
            ;;
        --help|-h|help)
            cat <<EOF
Usage: migration_backup.sh <command> [options]

Commands:
  backup <package>    Create backup for specified apt package
  list                List all available backups
  get <backup-id>     Get metadata for specific backup

Examples:
  migration_backup.sh backup firefox
  migration_backup.sh list | jq '.[] | {backup_id, packages}'
  migration_backup.sh get 20251109-143000

Output: MigrationBackup JSON object per data-model.md

Exit codes:
  0 = success
  1 = backup failure
  2 = invalid argument
EOF
            ;;
        *)
            log_event "ERROR" "Unknown command: $command"
            echo "Use --help for usage information" >&2
            return 2
            ;;
    esac
}

# Execute main if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
