#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Attempting to uninstall feh..."

# Check status first
check_script="$(dirname "$0")/../000-check/check_feh.sh"
if [ ! -f "$check_script" ]; then
    log "ERROR" "Check script not found at $check_script"
    exit 1
fi

# Output format: INSTALLED|Version|Method|Location
output=$("$check_script" 2>/dev/null)

if [[ "$output" == *"INSTALLED|"* ]]; then
    IFS='|' read -r status version method location <<< "$output"
    
    log "INFO" "Found feh installed via $method at $location"
    
    case "$method" in
        "Apt")
            log "INFO" "Removing feh via apt..."
            if sudo apt-get remove -y feh; then
                log "SUCCESS" "feh uninstalled successfully (apt)"
            else
                log "ERROR" "Failed to uninstall feh (apt)"
                exit 1
            fi
            ;;
        "Snap")
            log "INFO" "Removing feh via snap..."
            if sudo snap remove feh; then
                log "SUCCESS" "feh uninstalled successfully (snap)"
            else
                log "ERROR" "Failed to uninstall feh (snap)"
                exit 1
            fi
            ;;
        "Source")
            log "INFO" "Removing feh binary from $location..."
            if sudo rm "$location"; then
                log "SUCCESS" "feh binary removed"
            else
                log "ERROR" "Failed to remove feh binary"
                exit 1
            fi
            ;;
        *)
            log "WARNING" "Unknown installation method: $method. Attempting manual removal of binary..."
            if [ -f "$location" ]; then
                if sudo rm "$location"; then
                    log "SUCCESS" "feh binary removed"
                else
                    log "ERROR" "Failed to remove feh binary"
                    exit 1
                fi
            else
                log "ERROR" "Could not locate feh binary to remove."
                exit 1
            fi
            ;;
    esac
else
    log "INFO" "feh is not installed, nothing to do."
fi
