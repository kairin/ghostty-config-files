#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Attempting to uninstall ghostty..."

# Check status first
check_script="$(dirname "$0")/../000-check/check_ghostty.sh"
if [ ! -f "$check_script" ]; then
    log "ERROR" "Check script not found at $check_script"
    exit 1
fi

# Output format: INSTALLED|Version|Method|Location
output=$("$check_script" 2>/dev/null)

if [[ "$output" == *"INSTALLED|"* ]]; then
    IFS='|' read -r status version method location <<< "$output"
    
    log "INFO" "Found ghostty installed via $method at $location"
    
    case "$method" in
        "Snap")
            log "INFO" "Removing ghostty via snap..."
            if sudo snap remove ghostty; then
                log "SUCCESS" "ghostty uninstalled successfully (snap)"
            else
                log "ERROR" "Failed to uninstall ghostty (snap)"
                exit 1
            fi
            ;;
        "Apt")
            log "INFO" "Removing ghostty via apt..."
            if sudo apt-get remove -y ghostty; then
                log "SUCCESS" "ghostty uninstalled successfully (apt)"
            else
                log "ERROR" "Failed to uninstall ghostty (apt)"
                exit 1
            fi
            ;;
        "Source")
            log "INFO" "Removing ghostty binary from $location..."
            if sudo rm "$location"; then
                log "SUCCESS" "ghostty binary removed"
            else
                log "ERROR" "Failed to remove ghostty binary"
                exit 1
            fi
            ;;
        *)
            log "WARNING" "Unknown installation method: $method. Attempting manual removal of binary..."
            if [ -f "$location" ]; then
                if sudo rm "$location"; then
                    log "SUCCESS" "ghostty binary removed"
                else
                    log "ERROR" "Failed to remove ghostty binary"
                    exit 1
                fi
            else
                log "ERROR" "Could not locate ghostty binary to remove."
                exit 1
            fi
            ;;
    esac
else
    log "INFO" "ghostty is not installed, nothing to do."
fi
