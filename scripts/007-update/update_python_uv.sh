#!/bin/bash
# update_python_uv.sh - Update uv (Python package manager) in-place
#
# uv's install script is idempotent and handles updates automatically

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../006-logs/logger.sh"

log "INFO" "Current uv version: $(uv --version 2>/dev/null || echo 'none')"

# Re-run the official installer (handles updates automatically)
log "INFO" "Running uv installer..."

if curl -LsSf https://astral.sh/uv/install.sh | sh; then
    # Refresh PATH to pick up new version
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

    log "SUCCESS" "uv updated"
    log "INFO" "New version: $(uv --version 2>/dev/null)"
else
    log "ERROR" "uv update failed"
    exit 1
fi

log "SUCCESS" "Python/uv update complete"
