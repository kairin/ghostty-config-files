#!/bin/bash
# Module: backup_utils.sh
# Purpose: Timestamped configuration backup utilities before making changes
# Dependencies: None
# Modules Required: scripts/common.sh
# Exit Codes: 0=success, 1=backup failed, 2=invalid argument

set -euo pipefail

# Module-level guard: Allow sourcing for testing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    SOURCED_FOR_TESTING=1
else
    SOURCED_FOR_TESTING=0
fi

# Source common utilities if not already loaded
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$(type -t log_info)" != "function" ]]; then
    # shellcheck source=./common.sh
    source "$SCRIPT_DIR/common.sh"
fi

# ============================================================
# CONFIGURATION
# ============================================================

# Default backup directory (can be overridden by MANAGE_BACKUP_DIR)
DEFAULT_BACKUP_DIR="${HOME}/.config/ghostty/backups"
BACKUP_DIR="${MANAGE_BACKUP_DIR:-$DEFAULT_BACKUP_DIR}"

# ============================================================
# PUBLIC FUNCTIONS (Module API)
# ============================================================

# Function: create_backup
# Purpose: Create timestamped backup of a file or directory
# Args: $1=source_path, $2=backup_name (optional, defaults to basename)
# Returns: 0 on success, 1 on failure
# Side Effects: Creates backup file in BACKUP_DIR with timestamp
create_backup() {
    local source_path="$1"
    local backup_name="${2:-$(basename "$source_path")}"

    # Validate source exists
    if [[ ! -e "$source_path" ]]; then
        log_error "Source path does not exist: $source_path"
        return 1
    fi

    # Ensure backup directory exists
    if ! ensure_dir "$BACKUP_DIR"; then
        log_error "Failed to create backup directory: $BACKUP_DIR"
        return 1
    fi

    # Generate timestamped backup filename
    local timestamp
    timestamp="$(get_timestamp file)"
    local backup_filename="${backup_name}.backup-${timestamp}"
    local backup_path="${BACKUP_DIR}/${backup_filename}"

    # Create backup
    log_debug "Creating backup: $source_path -> $backup_path"

    if [[ -d "$source_path" ]]; then
        # Backup directory
        if ! cp -a "$source_path" "$backup_path"; then
            log_error "Failed to backup directory: $source_path"
            return 1
        fi
    else
        # Backup file
        if ! cp -a "$source_path" "$backup_path"; then
            log_error "Failed to backup file: $source_path"
            return 1
        fi
    fi

    log_info "Created backup: $backup_path"
    echo "$backup_path"  # Return backup path for caller
    return 0
}

# Function: restore_backup
# Purpose: Restore a file or directory from backup
# Args: $1=backup_path, $2=target_path
# Returns: 0 on success, 1 on failure
# Side Effects: Overwrites target_path with backup content
restore_backup() {
    local backup_path="$1"
    local target_path="$2"

    # Validate backup exists
    if [[ ! -e "$backup_path" ]]; then
        log_error "Backup not found: $backup_path"
        return 1
    fi

    # Warn if target exists
    if [[ -e "$target_path" ]]; then
        log_warn "Target path will be overwritten: $target_path"
    fi

    # Restore backup
    log_info "Restoring backup: $backup_path -> $target_path"

    if [[ -d "$backup_path" ]]; then
        # Restore directory
        if ! cp -a "$backup_path" "$target_path"; then
            log_error "Failed to restore directory: $backup_path"
            return 1
        fi
    else
        # Restore file
        if ! cp -a "$backup_path" "$target_path"; then
            log_error "Failed to restore file: $backup_path"
            return 1
        fi
    fi

    log_info "Restored from backup: $target_path"
    return 0
}

# Function: list_backups
# Purpose: List all backups for a given file or directory
# Args: $1=original_name (e.g., "config" for config.backup-*)
# Returns: 0 if backups found, 1 if none found
# Side Effects: Prints list of backup files to stdout
list_backups() {
    local original_name="$1"

    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_warn "Backup directory does not exist: $BACKUP_DIR"
        return 1
    fi

    local backup_pattern="${BACKUP_DIR}/${original_name}.backup-*"
    local backup_files
    backup_files=( $backup_pattern )

    if [[ ${#backup_files[@]} -eq 0 ]] || [[ ! -e "${backup_files[0]}" ]]; then
        log_info "No backups found for: $original_name"
        return 1
    fi

    echo "Backups for '$original_name':"
    for backup in "${backup_files[@]}"; do
        if [[ -e "$backup" ]]; then
            local backup_timestamp
            backup_timestamp=$(stat -c '%y' "$backup" 2>/dev/null || stat -f '%Sm' "$backup" 2>/dev/null)
            echo "  - $(basename "$backup") (created: $backup_timestamp)"
        fi
    done

    return 0
}

# Function: find_latest_backup
# Purpose: Find the most recent backup for a given file
# Args: $1=original_name
# Returns: 0 if backup found, 1 if none found
# Side Effects: Prints path to latest backup to stdout
find_latest_backup() {
    local original_name="$1"

    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_warn "Backup directory does not exist: $BACKUP_DIR"
        return 1
    fi

    local backup_pattern="${BACKUP_DIR}/${original_name}.backup-*"
    local latest_backup

    # Find newest backup (by modification time)
    latest_backup=$(find "$BACKUP_DIR" -name "${original_name}.backup-*" -type f -o -type d 2>/dev/null | \
                    xargs ls -t 2>/dev/null | head -n1)

    if [[ -z "$latest_backup" ]] || [[ ! -e "$latest_backup" ]]; then
        log_error "No backup found for: $original_name"
        return 1
    fi

    echo "$latest_backup"
    return 0
}

# Function: cleanup_old_backups
# Purpose: Remove backups older than specified days
# Args: $1=original_name, $2=days_to_keep (default: 30)
# Returns: 0 on success
# Side Effects: Deletes old backup files
cleanup_old_backups() {
    local original_name="$1"
    local days_to_keep="${2:-30}"

    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_info "No backup directory to clean: $BACKUP_DIR"
        return 0
    fi

    log_info "Cleaning backups older than $days_to_keep days for: $original_name"

    local deleted_count=0
    local backup_pattern="${BACKUP_DIR}/${original_name}.backup-*"

    # Find and delete old backups
    while IFS= read -r backup_file; do
        if [[ -e "$backup_file" ]]; then
            log_debug "Removing old backup: $backup_file"
            rm -rf "$backup_file"
            deleted_count=$((deleted_count + 1))
        fi
    done < <(find "$BACKUP_DIR" -name "${original_name}.backup-*" \( -type f -o -type d \) -mtime "+${days_to_keep}" 2>/dev/null)

    if [[ $deleted_count -gt 0 ]]; then
        log_info "Removed $deleted_count old backup(s)"
    else
        log_info "No old backups to remove"
    fi

    return 0
}

# Function: get_backup_size
# Purpose: Get total size of all backups
# Args: None
# Returns: 0 always
# Side Effects: Prints total backup size to stdout
get_backup_size() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo "0"
        return 0
    fi

    local total_size
    total_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1 || echo "0")

    echo "$total_size"
    return 0
}

# Function: verify_backup
# Purpose: Verify that a backup file is readable and non-empty
# Args: $1=backup_path
# Returns: 0 if valid, 1 if invalid
# Side Effects: Logs verification result
verify_backup() {
    local backup_path="$1"

    if [[ ! -e "$backup_path" ]]; then
        log_error "Backup does not exist: $backup_path"
        return 1
    fi

    if [[ ! -r "$backup_path" ]]; then
        log_error "Backup is not readable: $backup_path"
        return 1
    fi

    if [[ -f "$backup_path" ]]; then
        # For files, check if non-empty
        if [[ ! -s "$backup_path" ]]; then
            log_warn "Backup file is empty: $backup_path"
            return 1
        fi
    elif [[ -d "$backup_path" ]]; then
        # For directories, check if has content
        if [[ -z "$(ls -A "$backup_path" 2>/dev/null)" ]]; then
            log_warn "Backup directory is empty: $backup_path"
            return 1
        fi
    fi

    log_debug "Backup verified: $backup_path"
    return 0
}

# Function: create_config_backup
# Purpose: Convenience function to backup Ghostty config with metadata
# Args: $1=reason (optional description of why backup is being created)
# Returns: 0 on success, 1 on failure
# Side Effects: Creates backup of config file with metadata
create_config_backup() {
    local reason="${1:-manual backup}"
    local config_path="${HOME}/.config/ghostty/config"

    if [[ ! -f "$config_path" ]]; then
        log_warn "Ghostty config not found: $config_path"
        return 1
    fi

    # Create backup
    local backup_path
    if ! backup_path=$(create_backup "$config_path" "config"); then
        return 1
    fi

    # Create metadata file alongside backup
    local metadata_path="${backup_path}.meta"
    cat > "$metadata_path" << EOF
Backup Created: $(date '+%Y-%m-%d %H:%M:%S')
Reason: $reason
Original Path: $config_path
Hostname: $(hostname)
User: $USER
EOF

    log_info "Backup metadata saved: $metadata_path"
    return 0
}

# ============================================================
# MAIN EXECUTION (Skipped when sourced)
# ============================================================

if [[ "${SOURCED_FOR_TESTING}" -eq 0 ]]; then
    # If run directly, show usage
    cat << 'EOF'
This module provides backup utility functions and should be sourced, not executed directly.

Usage:
    source scripts/backup_utils.sh

Available functions:
    - create_backup <source_path> [backup_name]
    - restore_backup <backup_path> <target_path>
    - list_backups <original_name>
    - find_latest_backup <original_name>
    - cleanup_old_backups <original_name> [days_to_keep]
    - get_backup_size
    - verify_backup <backup_path>
    - create_config_backup [reason]

Environment Variables:
    MANAGE_BACKUP_DIR - Custom backup directory (default: ~/.config/ghostty/backups)

Example:
    source scripts/backup_utils.sh
    create_backup ~/.config/ghostty/config
    list_backups config
    LATEST=$(find_latest_backup config)
    restore_backup "$LATEST" ~/.config/ghostty/config
EOF
    exit 0
fi
