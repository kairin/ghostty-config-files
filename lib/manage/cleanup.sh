#!/usr/bin/env bash
# lib/manage/cleanup.sh - Cleanup commands for manage.sh
# Extracted for modularity compliance (300 line limit per module)
# Contains: cmd_cleanup, cmd_reset

set -euo pipefail

[ -z "${MANAGE_CLEANUP_SH_LOADED:-}" ] || return 0
MANAGE_CLEANUP_SH_LOADED=1

# cmd_cleanup - Clean up temporary files, logs, and build artifacts
cmd_cleanup() {
    local force=0 logs=0 backups=0 builds=0 all=0 show_help=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force) force=1; shift ;;
            --logs) logs=1; shift ;;
            --backups) backups=1; shift ;;
            --builds) builds=1; shift ;;
            --all) all=1; shift ;;
            --help|-h) show_help=1; shift ;;
            *) log_error "Unknown option: $1"; return 2 ;;
        esac
    done

    if [[ "$show_help" -eq 1 ]]; then
        cat << 'EOF'
Usage: ./manage.sh cleanup [options]

Clean up temporary files, logs, and build artifacts

OPTIONS:
    --logs          Clean log files
    --backups       Clean backup files (older than 30 days)
    --builds        Clean build artifacts
    --all           Clean all of the above
    --force         Skip confirmation prompts
    --help, -h      Show this help message

EXAMPLES:
    # Clean logs only
    ./manage.sh cleanup --logs

    # Clean everything with confirmation
    ./manage.sh cleanup --all

    # Clean everything without confirmation
    ./manage.sh cleanup --all --force
EOF
        return 0
    fi

    [[ "$all" -eq 1 ]] && { logs=1; backups=1; builds=1; }

    [[ "$logs" -eq 0 && "$backups" -eq 0 && "$builds" -eq 0 ]] && {
        log_warn "No cleanup options specified. Use --help for options."
        return 0
    }

    show_progress "start" "Starting cleanup"

    local total_cleaned=0

    if [[ "$logs" -eq 1 ]]; then
        show_progress "info" "Cleaning log files..."
        local log_count
        log_count=$(_cleanup_logs "$force")
        total_cleaned=$((total_cleaned + log_count))
        log_info "Cleaned $log_count log file(s)"
    fi

    if [[ "$backups" -eq 1 ]]; then
        show_progress "info" "Cleaning old backups..."
        local backup_count
        backup_count=$(_cleanup_backups "$force")
        total_cleaned=$((total_cleaned + backup_count))
        log_info "Cleaned $backup_count backup file(s)"
    fi

    if [[ "$builds" -eq 1 ]]; then
        show_progress "info" "Cleaning build artifacts..."
        local build_count
        build_count=$(_cleanup_builds "$force")
        total_cleaned=$((total_cleaned + build_count))
        log_info "Cleaned $build_count build artifact(s)"
    fi

    show_progress "success" "Cleanup complete: $total_cleaned items removed"
    return 0
}

# Helper: Clean up log files
_cleanup_logs() {
    local force="$1"
    local count=0

    local log_dir="${SCRIPT_DIR}/logs"
    [[ ! -d "$log_dir" ]] && { echo 0; return; }

    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        count=$(find "$log_dir" -type f -name "*.log" -mtime +7 2>/dev/null | wc -l)
        log_info "[DRY RUN] Would remove $count log files older than 7 days"
    else
        if [[ "$force" -eq 1 ]]; then
            count=$(find "$log_dir" -type f -name "*.log" -mtime +7 -delete -print 2>/dev/null | wc -l)
        else
            local files
            files=$(find "$log_dir" -type f -name "*.log" -mtime +7 2>/dev/null)
            if [[ -n "$files" ]]; then
                count=$(echo "$files" | wc -l)
                echo "Found $count log files older than 7 days. Remove? [y/N]"
                read -r confirm
                if [[ "$confirm" =~ ^[Yy] ]]; then
                    echo "$files" | xargs rm -f 2>/dev/null
                else
                    count=0
                    log_info "Cleanup cancelled by user"
                fi
            fi
        fi
    fi
    echo "$count"
}

# Helper: Clean up old backups (older than 30 days)
_cleanup_backups() {
    local force="$1"
    local count=0

    local backup_dirs=(
        "${SCRIPT_DIR}/backups"
        "${HOME}/.config/ghostty/backups"
    )

    for backup_dir in "${backup_dirs[@]}"; do
        [[ ! -d "$backup_dir" ]] && continue

        if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
            local dir_count
            dir_count=$(find "$backup_dir" -type f -mtime +30 2>/dev/null | wc -l)
            count=$((count + dir_count))
        else
            if [[ "$force" -eq 1 ]]; then
                local dir_count
                dir_count=$(find "$backup_dir" -type f -mtime +30 -delete -print 2>/dev/null | wc -l)
                count=$((count + dir_count))
            else
                local files
                files=$(find "$backup_dir" -type f -mtime +30 2>/dev/null)
                if [[ -n "$files" ]]; then
                    local dir_count
                    dir_count=$(echo "$files" | wc -l)
                    echo "Found $dir_count backup files older than 30 days in $backup_dir. Remove? [y/N]"
                    read -r confirm
                    if [[ "$confirm" =~ ^[Yy] ]]; then
                        echo "$files" | xargs rm -f 2>/dev/null
                        count=$((count + dir_count))
                    fi
                fi
            fi
        fi
    done

    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        log_info "[DRY RUN] Would remove $count backup files older than 30 days"
    fi
    echo "$count"
}

# Helper: Clean up build artifacts
_cleanup_builds() {
    local force="$1"
    local count=0

    local build_dirs=(
        "${SCRIPT_DIR}/.zig-cache"
        "${SCRIPT_DIR}/build"
        "/tmp/ghostty-build-*"
    )

    for build_pattern in "${build_dirs[@]}"; do
        for build_dir in $build_pattern; do
            [[ ! -e "$build_dir" ]] && continue

            if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
                log_info "[DRY RUN] Would remove: $build_dir"
                count=$((count + 1))
            else
                if [[ "$force" -eq 1 ]]; then
                    rm -rf "$build_dir" 2>/dev/null && count=$((count + 1))
                else
                    echo "Remove build directory: $build_dir? [y/N]"
                    read -r confirm
                    if [[ "$confirm" =~ ^[Yy] ]]; then
                        rm -rf "$build_dir" 2>/dev/null && count=$((count + 1))
                    fi
                fi
            fi
        done
    done
    echo "$count"
}

# cmd_reset - Reset configuration to defaults
cmd_reset() {
    local force=0 config_only=0 full=0 show_help=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force) force=1; shift ;;
            --config-only) config_only=1; shift ;;
            --full) full=1; shift ;;
            --help|-h) show_help=1; shift ;;
            *) log_error "Unknown option: $1"; return 2 ;;
        esac
    done

    if [[ "$show_help" -eq 1 ]]; then
        cat << 'EOF'
Usage: ./manage.sh reset [options]

Reset configuration to defaults with automatic backup

OPTIONS:
    --config-only   Only reset Ghostty configuration
    --full          Full reset (config + shell settings)
    --force         Skip confirmation prompts
    --help, -h      Show this help message

WARNING:
    Reset operations create backups but may still result in data loss.
    Always review what will be reset before confirming.
EOF
        return 0
    fi

    if [[ "$config_only" -eq 0 && "$full" -eq 0 ]]; then
        log_warn "Please specify --config-only or --full"
        return 2
    fi

    if [[ "$force" -eq 0 ]]; then
        local reset_type=$([[ "$full" -eq 1 ]] && echo "FULL" || echo "config-only")
        echo "WARNING: This will perform a $reset_type reset."
        echo "A backup will be created before any changes."
        echo "Continue? [y/N]"
        read -r confirm
        [[ ! "$confirm" =~ ^[Yy] ]] && { log_info "Reset cancelled"; return 0; }
    fi

    show_progress "start" "Starting reset"

    local backup_dir="${SCRIPT_DIR}/backups/reset-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    show_progress "info" "Backup directory: $backup_dir"

    if [[ "$config_only" -eq 1 ]] || [[ "$full" -eq 1 ]]; then
        local config_file="${HOME}/.config/ghostty/config"
        if [[ -f "$config_file" ]]; then
            if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
                log_info "[DRY RUN] Would backup and reset: $config_file"
            else
                cp "$config_file" "$backup_dir/"
                local default_config="${SCRIPT_DIR}/configs/ghostty/config.default"
                if [[ -f "$default_config" ]]; then
                    cp "$default_config" "$config_file"
                    log_info "Configuration reset to defaults"
                else
                    log_warn "Default config not found, creating minimal config"
                    cat > "$config_file" << 'EOF'
# Ghostty Configuration - Reset to defaults
# Generated by manage.sh reset
font-family = monospace
font-size = 12
EOF
                fi
            fi
        fi
    fi

    if [[ "$full" -eq 1 ]]; then
        local zshrc="${HOME}/.zshrc"
        if [[ -f "$zshrc" ]]; then
            if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
                log_info "[DRY RUN] Would backup (but NOT reset) shell config: $zshrc"
            else
                cp "$zshrc" "$backup_dir/"
                log_info "Shell configuration backed up (manual review recommended)"
            fi
        fi
    fi

    show_progress "success" "Reset complete. Backup saved to: $backup_dir"
    return 0
}

export -f cmd_cleanup cmd_reset
