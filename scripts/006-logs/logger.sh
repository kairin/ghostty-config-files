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
if [ -z "$LOG_FILE" ]; then
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
