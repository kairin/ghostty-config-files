#!/bin/bash

# Shared Logging Utility
# Usage: source 006-logs/logger.sh
# Logs are saved to 006-logs/YYYYMMDD-HHMMSS-<script_name>.log

# Get the directory of this script (006-logs)
LOGS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$LOGS_DIR")"

# Initialize log file
init_log() {
    local script_name=$(basename "$0" .sh)
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    LOG_FILE="$LOGS_DIR/${timestamp}-${script_name}.log"
    touch "$LOG_FILE"
    log "INFO" "Log initialized: $LOG_FILE"
}

# Log function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    # Console output (colorized)
    case "$level" in
        INFO)    echo -e "\033[34m[INFO]\033[0m $message" >&2 ;;
        SUCCESS) echo -e "\033[32m[SUCCESS]\033[0m $message" >&2 ;;
        WARNING) echo -e "\033[33m[WARNING]\033[0m $message" >&2 ;;
        ERROR)   echo -e "\033[31m[ERROR]\033[0m $message" >&2 ;;
        *)       echo "[$level] $message" >&2 ;;
    esac
    
    # File output
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Ensure log is initialized
if [ -z "${LOG_FILE:-}" ]; then
    init_log
fi

# =============================================================================
# Icon Installation Utilities (Prevent Icon Cache Corruption)
# =============================================================================

# Ensure icon theme infrastructure exists (index.theme is REQUIRED for GTK)
# Usage: ensure_icon_infrastructure "/usr/local/share/icons/hicolor" "sudo"
ensure_icon_infrastructure() {
    local icon_dir="$1"
    local use_sudo="${2:-}"
    local cmd_prefix=""

    if [ "$use_sudo" = "sudo" ]; then
        cmd_prefix="sudo "
    fi

    # Create directory if needed
    ${cmd_prefix}mkdir -p "$icon_dir"

    # CRITICAL: Copy index.theme if missing (without it, icon cache is invalid)
    if [ ! -f "$icon_dir/index.theme" ]; then
        if [ -f "/usr/share/icons/hicolor/index.theme" ]; then
            ${cmd_prefix}cp /usr/share/icons/hicolor/index.theme "$icon_dir/"
            log "SUCCESS" "Copied index.theme to $icon_dir"
            return 0
        else
            log "ERROR" "System index.theme not found - icons will not work correctly"
            return 1
        fi
    fi
    return 0
}

# Rebuild icon cache with validation
# Usage: rebuild_icon_cache "/usr/local/share/icons/hicolor" "sudo"
rebuild_icon_cache() {
    local icon_dir="$1"
    local use_sudo="${2:-}"
    local cmd_prefix=""

    if [ "$use_sudo" = "sudo" ]; then
        cmd_prefix="sudo "
    fi

    # Verify index.theme exists first
    if [ ! -f "$icon_dir/index.theme" ]; then
        log "ERROR" "Cannot rebuild cache: index.theme missing from $icon_dir"
        return 1
    fi

    if command -v gtk-update-icon-cache &> /dev/null; then
        if ${cmd_prefix}gtk-update-icon-cache --force "$icon_dir" 2>/dev/null; then
            # Verify cache is valid (should be > 1KB; invalid cache is ~496 bytes)
            local cache_size
            cache_size=$(stat -c%s "$icon_dir/icon-theme.cache" 2>/dev/null || echo "0")
            if [ "$cache_size" -gt 1024 ]; then
                log "SUCCESS" "Icon cache rebuilt (${cache_size} bytes)"
                return 0
            else
                log "WARNING" "Icon cache may be invalid (${cache_size} bytes, expected >1KB)"
                return 1
            fi
        else
            log "WARNING" "gtk-update-icon-cache failed"
            return 1
        fi
    else
        log "WARNING" "gtk-update-icon-cache not available"
        return 1
    fi
}

# Check if icon cache is valid (returns 0 if valid, 1 if invalid/missing)
# Usage: is_icon_cache_valid "/usr/local/share/icons/hicolor"
is_icon_cache_valid() {
    local icon_dir="$1"
    local cache_file="$icon_dir/icon-theme.cache"
    local min_valid_size=1024  # Valid cache should be > 1KB

    # Check index.theme exists
    if [ ! -f "$icon_dir/index.theme" ]; then
        return 1
    fi

    # Check cache exists and is valid size
    if [ -f "$cache_file" ]; then
        local cache_size
        cache_size=$(stat -c%s "$cache_file" 2>/dev/null || echo "0")
        if [ "$cache_size" -gt "$min_valid_size" ]; then
            return 0
        fi
    fi

    return 1
}

# Auto-fix icon cache issues (detects and fixes)
# Usage: auto_fix_icon_cache "/usr/local/share/icons/hicolor" "sudo"
auto_fix_icon_cache() {
    local icon_dir="$1"
    local use_sudo="${2:-}"
    local fixes_applied=0

    log "INFO" "Checking icon cache health for $icon_dir..."

    # Check if directory exists
    if [ ! -d "$icon_dir" ]; then
        log "INFO" "Icon directory does not exist - skipping"
        return 0
    fi

    # Fix 1: Ensure index.theme exists
    if [ ! -f "$icon_dir/index.theme" ]; then
        log "WARNING" "Missing index.theme - auto-fixing..."
        if ensure_icon_infrastructure "$icon_dir" "$use_sudo"; then
            fixes_applied=$((fixes_applied + 1))
        else
            log "ERROR" "Failed to fix missing index.theme"
            return 1
        fi
    fi

    # Fix 2: Check and rebuild cache if invalid
    if ! is_icon_cache_valid "$icon_dir"; then
        log "WARNING" "Icon cache invalid - rebuilding..."
        if rebuild_icon_cache "$icon_dir" "$use_sudo"; then
            fixes_applied=$((fixes_applied + 1))
        else
            log "ERROR" "Failed to rebuild icon cache"
            return 1
        fi
    fi

    if [ $fixes_applied -gt 0 ]; then
        log "SUCCESS" "Applied $fixes_applied icon cache fix(es)"
    else
        log "SUCCESS" "Icon cache is healthy"
    fi

    return 0
}

# =============================================================================
# Shell Environment Utilities
# =============================================================================

# Display shell reload instructions (for tools that modify PATH/environment)
# Usage: show_shell_reload_instructions
show_shell_reload_instructions() {
    local shell_config="$HOME/.zshrc"
    if [ -f "$HOME/.bashrc" ]; then shell_config="$HOME/.bashrc"; fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  IMPORTANT: Reload your shell to use the new commands"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Option 1 (recommended): Open a NEW terminal tab/window"
    echo "  Option 2: Restart current shell: exec zsh"
    echo "  Option 3: Reload configuration: source $shell_config"
    echo ""
}

# Check if a command will be available after shell reload
# Usage: check_command_in_path_after_reload "claude" "$HOME/.local/bin/claude"
check_command_in_path_after_reload() {
    local cmd_name="$1"
    local cmd_path="$2"

    # Check if command is already in PATH
    if command -v "$cmd_name" &> /dev/null; then
        return 0  # Already accessible
    fi

    # Check if binary exists at expected location
    if [ -x "$cmd_path" ] || [ -L "$cmd_path" ]; then
        # Check if .zshrc/.bashrc configures PATH correctly
        local shell_config="$HOME/.zshrc"
        if [ -f "$HOME/.bashrc" ]; then shell_config="$HOME/.bashrc"; fi

        if grep -q "$HOME/.local/bin" "$shell_config" 2>/dev/null; then
            return 0  # Will be available after reload
        fi
    fi

    return 1  # Not found or PATH not configured
}

# =============================================================================
# Update Logging Utilities
# =============================================================================

# Update log directory and current log file (session-scoped)
UPDATE_LOG_DIR="${REPO_ROOT}/../.runners-local/logs"
UPDATE_LOG_FILE=""

# Initialize update summary log
# Usage: init_update_log
# Creates: .runners-local/logs/update-summary-YYYYMMDD-HHMMSS.log
init_update_log() {
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    UPDATE_LOG_DIR="$(dirname "$(dirname "${BASH_SOURCE[0]}")")/../.runners-local/logs"
    mkdir -p "$UPDATE_LOG_DIR"
    UPDATE_LOG_FILE="${UPDATE_LOG_DIR}/update-summary-${timestamp}.log"

    # Write header
    cat > "$UPDATE_LOG_FILE" <<EOF
# Update Summary Log
# Generated: $(date "+%Y-%m-%d %H:%M:%S")
# Host: $(hostname)
# User: $(whoami)
#
# Format: TYPE|data1|data2|data3|timestamp
#
EOF
    echo "HEADER|START|$(date +%s)|$(date "+%Y-%m-%d %H:%M:%S")" >> "$UPDATE_LOG_FILE"
    log "INFO" "Update log initialized: $UPDATE_LOG_FILE"
}

# Log tool update start
# Usage: log_update_start "tool_name" "current_version" "target_version"
log_update_start() {
    local tool_name="$1"
    local current_version="${2:--}"
    local target_version="${3:--}"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    if [[ -n "$UPDATE_LOG_FILE" ]] && [[ -f "$UPDATE_LOG_FILE" ]]; then
        echo "UPDATE_START|${tool_name}|${current_version}|${target_version}|${timestamp}" >> "$UPDATE_LOG_FILE"
    fi
    log "INFO" "Updating ${tool_name}: ${current_version} -> ${target_version}"
}

# Log tool update result
# Usage: log_update_result "tool_name" "SUCCESS|ERROR|SKIPPED" "message"
log_update_result() {
    local tool_name="$1"
    local status="$2"
    local message="${3:-}"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    if [[ -n "$UPDATE_LOG_FILE" ]] && [[ -f "$UPDATE_LOG_FILE" ]]; then
        echo "UPDATE_RESULT|${tool_name}|${status}|${message}|${timestamp}" >> "$UPDATE_LOG_FILE"
    fi

    case "$status" in
        SUCCESS) log "SUCCESS" "${tool_name}: ${message:-Update successful}" ;;
        ERROR)   log "ERROR" "${tool_name}: ${message:-Update failed}" ;;
        SKIPPED) log "INFO" "${tool_name}: ${message:-Skipped}" ;;
        *)       log "INFO" "${tool_name}: ${status} - ${message}" ;;
    esac
}

# Finalize update summary
# Usage: finalize_update_log total success failed skipped
finalize_update_log() {
    local total="${1:-0}"
    local success="${2:-0}"
    local failed="${3:-0}"
    local skipped="${4:-0}"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local duration="${5:-0}"

    if [[ -n "$UPDATE_LOG_FILE" ]] && [[ -f "$UPDATE_LOG_FILE" ]]; then
        echo "HEADER|END|$(date +%s)|${timestamp}" >> "$UPDATE_LOG_FILE"
        echo "SUMMARY|total=${total}|success=${success}|failed=${failed}|skipped=${skipped}|duration=${duration}s" >> "$UPDATE_LOG_FILE"
    fi
    log "INFO" "Update complete: ${success}/${total} succeeded, ${failed} failed, ${skipped} skipped"
}

# Show latest update summary (for update-logs alias)
# Usage: show_latest_update_summary
show_latest_update_summary() {
    local log_dir="$(dirname "$(dirname "${BASH_SOURCE[0]}")")/../.runners-local/logs"
    local latest_log=$(ls -t "${log_dir}"/update-summary-*.log 2>/dev/null | head -1)

    if [[ -z "$latest_log" ]] || [[ ! -f "$latest_log" ]]; then
        echo "No update logs found in ${log_dir}"
        return 1
    fi

    echo ""
    echo "Latest Update Summary: $(basename "$latest_log")"
    echo "════════════════════════════════════════════════════════════════"

    # Parse and display summary
    local summary_line=$(grep "^SUMMARY|" "$latest_log" 2>/dev/null | tail -1)
    if [[ -n "$summary_line" ]]; then
        echo "$summary_line" | awk -F'|' '{
            gsub(/total=/, "Total: ", $2)
            gsub(/success=/, "Success: ", $3)
            gsub(/failed=/, "Failed: ", $4)
            gsub(/skipped=/, "Skipped: ", $5)
            gsub(/duration=/, "Duration: ", $6)
            print "  " $2 " | " $3 " | " $4 " | " $5 " | " $6
        }'
    fi

    echo ""
    echo "Update Details:"
    echo "────────────────────────────────────────────────────────────────"
    grep "^UPDATE_RESULT|" "$latest_log" 2>/dev/null | while IFS='|' read -r type tool status msg ts; do
        case "$status" in
            SUCCESS) printf "  \033[32m%-20s %s\033[0m\n" "$tool" "$msg" ;;
            ERROR)   printf "  \033[31m%-20s %s\033[0m\n" "$tool" "$msg" ;;
            SKIPPED) printf "  \033[33m%-20s %s\033[0m\n" "$tool" "$msg" ;;
            *)       printf "  %-20s %s\n" "$tool" "$msg" ;;
        esac
    done
    echo ""
}

# =============================================================================
# Configuration Backup/Restore Utilities
# =============================================================================

# Backup directory
BACKUP_DIR="${HOME}/.config/ghostty-backups"

# Backup configurations before updates
# Usage: backup_configs ["pre-update"|"manual"]
backup_configs() {
    local backup_type="${1:-pre-update}"
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    local backup_path="${BACKUP_DIR}/${backup_type}-${timestamp}"

    mkdir -p "$backup_path"

    local backed_up=0

    # Backup Ghostty config
    if [[ -d "${HOME}/.config/ghostty" ]]; then
        cp -r "${HOME}/.config/ghostty" "${backup_path}/ghostty" 2>/dev/null && ((backed_up++))
    fi

    # Backup ZSH config
    if [[ -f "${HOME}/.zshrc" ]]; then
        cp "${HOME}/.zshrc" "${backup_path}/zshrc" 2>/dev/null && ((backed_up++))
    fi
    if [[ -f "${HOME}/.p10k.zsh" ]]; then
        cp "${HOME}/.p10k.zsh" "${backup_path}/p10k.zsh" 2>/dev/null && ((backed_up++))
    fi

    # Backup fastfetch config
    if [[ -d "${HOME}/.config/fastfetch" ]]; then
        cp -r "${HOME}/.config/fastfetch" "${backup_path}/fastfetch" 2>/dev/null && ((backed_up++))
    fi

    if [[ $backed_up -gt 0 ]]; then
        log "SUCCESS" "Backed up ${backed_up} config(s) to ${backup_path}"
        echo "$backup_path"
        return 0
    else
        log "WARNING" "No configurations found to backup"
        rmdir "$backup_path" 2>/dev/null
        return 1
    fi
}

# Restore from backup
# Usage: restore_from_backup "/path/to/backup"
restore_from_backup() {
    local backup_path="$1"

    if [[ -z "$backup_path" ]] || [[ ! -d "$backup_path" ]]; then
        log "ERROR" "Invalid backup path: $backup_path"
        return 1
    fi

    local restored=0

    # Restore Ghostty config
    if [[ -d "${backup_path}/ghostty" ]]; then
        rm -rf "${HOME}/.config/ghostty"
        cp -r "${backup_path}/ghostty" "${HOME}/.config/ghostty" && ((restored++))
    fi

    # Restore ZSH config
    if [[ -f "${backup_path}/zshrc" ]]; then
        cp "${backup_path}/zshrc" "${HOME}/.zshrc" && ((restored++))
    fi
    if [[ -f "${backup_path}/p10k.zsh" ]]; then
        cp "${backup_path}/p10k.zsh" "${HOME}/.p10k.zsh" && ((restored++))
    fi

    # Restore fastfetch config
    if [[ -d "${backup_path}/fastfetch" ]]; then
        rm -rf "${HOME}/.config/fastfetch"
        cp -r "${backup_path}/fastfetch" "${HOME}/.config/fastfetch" && ((restored++))
    fi

    if [[ $restored -gt 0 ]]; then
        log "SUCCESS" "Restored ${restored} config(s) from ${backup_path}"
        return 0
    else
        log "WARNING" "No configurations restored"
        return 1
    fi
}

# Cleanup old backups (keep last 5)
# Usage: cleanup_old_backups
cleanup_old_backups() {
    local keep_count=5

    if [[ ! -d "$BACKUP_DIR" ]]; then
        return 0
    fi

    local backup_count=$(ls -d "${BACKUP_DIR}"/*/ 2>/dev/null | wc -l)

    if [[ $backup_count -le $keep_count ]]; then
        log "INFO" "Backup cleanup: ${backup_count} backups (keeping ${keep_count})"
        return 0
    fi

    local to_remove=$((backup_count - keep_count))

    ls -dt "${BACKUP_DIR}"/*/ 2>/dev/null | tail -n "$to_remove" | while read -r old_backup; do
        rm -rf "$old_backup"
        log "INFO" "Removed old backup: $(basename "$old_backup")"
    done

    log "SUCCESS" "Backup cleanup: removed ${to_remove} old backup(s)"
}
