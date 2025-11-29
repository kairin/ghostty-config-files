#!/usr/bin/env bash
#
# Post-Update VHS Demo Generation
# Purpose: Generate demo GIFs after successful updates/commits
# Usage: Called automatically by update workflows and git hooks
#
# Constitutional Compliance:
# - Principle V: Modular Architecture
# - Automated documentation via VHS recordings
# - Keep demos synchronized with latest code state
#

set -euo pipefail

# Get repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source core utilities
source "${REPO_ROOT}/lib/core/logging.sh"
source "${REPO_ROOT}/lib/core/utils.sh"

# Check if VHS is available
if ! command_exists "vhs"; then
    log "WARNING" "VHS not installed, skipping demo generation"
    log "INFO" "Install with: lib/installers/vhs/install.sh"
    exit 0
fi

# Check dependencies
check_vhs_dependencies() {
    local missing=()

    if ! command_exists "ffmpeg"; then
        missing+=("ffmpeg")
    fi

    if ! command_exists "ttyd"; then
        missing+=("ttyd")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        log "WARNING" "Missing VHS dependencies: ${missing[*]}"
        log "INFO" "Skipping demo generation"
        return 1
    fi

    return 0
}

# Main execution
main() {
    log "INFO" "Post-Update: VHS Demo Generation"

    if ! check_vhs_dependencies; then
        exit 0
    fi

    # Generate demos
    log "INFO" "Generating documentation demos..."
    if "${SCRIPT_DIR}/generate-demos.sh"; then
        log "SUCCESS" "✓ Demos generated successfully"

        # Check if demos should be committed
        if git -C "$REPO_ROOT" status --porcelain documentation/demos/*.gif 2>/dev/null | grep -q "^??"; then
            log "INFO" "New demo GIFs detected"
            log "INFO" "Consider committing with: git add documentation/demos/ && git commit"
        fi
    else
        log "WARNING" "Demo generation failed (non-critical)"
    fi
}

main "$@"
