#!/usr/bin/env bash
# lib/manage/update.sh - Update commands for manage.sh
# Extracted for modularity compliance (300 line limit per module)
# Contains: cmd_update

set -euo pipefail

[ -z "${MANAGE_UPDATE_SH_LOADED:-}" ] || return 0
MANAGE_UPDATE_SH_LOADED=1

# cmd_update - Update repository components
cmd_update() {
    local check_only=0 force=0 component="" show_help=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --check-only) check_only=1; shift ;;
            --force) force=1; shift ;;
            --component) component="$2"; shift 2 ;;
            --help|-h) show_help=1; shift ;;
            *) log_error "Unknown option: $1"; return 2 ;;
        esac
    done

    if [[ "$show_help" -eq 1 ]]; then
        cat << 'EOF'
Usage: ./manage.sh update [options]

Update repository components with user customization preservation

OPTIONS:
    --check-only        Check for updates without applying them
    --force             Force update even if no changes detected
    --component NAME    Update specific component only (ghostty, zsh, docs)
    --help, -h          Show this help message

EXAMPLES:
    # Check for available updates
    ./manage.sh update --check-only

    # Update all components
    ./manage.sh update

    # Update specific component
    ./manage.sh update --component ghostty

    # Force update all components
    ./manage.sh update --force

NOTES:
    - User customizations are automatically preserved
    - Backups are created before any changes
    - Failed updates are automatically rolled back
EOF
        return 0
    fi

    show_progress "start" "Checking for updates"

    local update_script="${SCRIPT_DIR}/scripts/check_updates.sh"
    if [[ ! -f "$update_script" ]]; then
        log_error "Update script not found: $update_script"
        return 1
    fi

    # Source backup utilities for customization preservation
    [[ -f "${SCRIPTS_DIR}/backup_utils.sh" ]] && source "${SCRIPTS_DIR}/backup_utils.sh"

    local update_cmd="$update_script"
    [[ "$check_only" -eq 1 ]] && update_cmd="$update_cmd --check"
    [[ "$force" -eq 1 ]] && update_cmd="$update_cmd --force"

    if [[ -n "$component" ]]; then
        case "$component" in
            ghostty|zsh|docs) update_cmd="$update_cmd --component $component" ;;
            *) log_error "Unknown component: $component"; return 2 ;;
        esac
    fi

    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        show_progress "info" "[DRY RUN] Would run: $update_cmd"
        return 0
    fi

    show_progress "info" "Preserving user customizations..."

    local config_backup=""
    if [[ -f "${HOME}/.config/ghostty/config" ]]; then
        config_backup=$(_create_config_backup 2>/dev/null || echo "")
        [[ -n "$config_backup" ]] && log_debug "Configuration backed up: $config_backup"
    fi

    show_progress "info" "Running update check..."

    if $update_cmd; then
        if [[ "$check_only" -eq 1 ]]; then
            show_progress "success" "Update check complete"
        else
            show_progress "success" "Update complete"
            log_info "User customizations have been preserved"
            [[ -n "$config_backup" ]] && log_debug "Backup available at: $config_backup"
        fi
    else
        show_progress "error" "Update failed"

        if [[ -n "$config_backup" ]] && [[ -f "$config_backup" ]]; then
            show_progress "info" "Rolling back to previous configuration..."
            if _restore_config_backup "$config_backup"; then
                show_progress "success" "Rollback complete"
            else
                log_error "Rollback failed - manual restoration may be required"
                log_error "Backup location: $config_backup"
            fi
        fi
        return 1
    fi
    return 0
}

# Helper: Create config backup
_create_config_backup() {
    local config_file="${HOME}/.config/ghostty/config"
    local backup_dir="${HOME}/.config/ghostty/backups"
    local timestamp
    timestamp=$(date +"%Y%m%d-%H%M%S")
    local backup_file="${backup_dir}/config-${timestamp}.bak"

    mkdir -p "$backup_dir"
    cp "$config_file" "$backup_file"
    echo "$backup_file"
}

# Helper: Restore config backup
_restore_config_backup() {
    local backup_file="$1"
    local config_file="${HOME}/.config/ghostty/config"

    [[ -f "$backup_file" ]] && cp "$backup_file" "$config_file"
}

export -f cmd_update
