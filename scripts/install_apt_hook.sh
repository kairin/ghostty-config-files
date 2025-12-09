#!/bin/bash
source "$(dirname "$0")/006-logs/logger.sh"

log "INFO" "Installing APT hook for Antigravity zsh completion permissions..."

HOOK_FILE="/etc/apt/apt.conf.d/99antigravity-permission-fix"
HOOK_CONTENT='DPkg::Post-Invoke { "if [ -f /usr/share/zsh/vendor-completions/_antigravity ]; then chown root:root /usr/share/zsh/vendor-completions/_antigravity; fi"; };'

# Check if we have sudo access or are root
if [ "$EUID" -ne 0 ]; then
    log "INFO" "Sudo access required to write to $HOOK_FILE"
    if ! command -v sudo &> /dev/null; then
        log "ERROR" "sudo is not installed and script is not run as root."
        exit 1
    fi
    CMD_PREFIX="sudo"
else
    CMD_PREFIX=""
fi

# Write the file
echo "$HOOK_CONTENT" | $CMD_PREFIX tee "$HOOK_FILE" > /dev/null

if [ $? -eq 0 ]; then
    log "SUCCESS" "APT hook installed to $HOOK_FILE"
    # Verify file content
    if [ -f "$HOOK_FILE" ]; then
        log "INFO" "Hook content verified."
    else
        log "ERROR" "File was not created."
        exit 1
    fi
else
    log "ERROR" "Failed to write APT hook."
    exit 1
fi
