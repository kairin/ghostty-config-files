#!/usr/bin/env bash
#
# VHS Demo Generation Script
# Purpose: Generate all VHS demo GIFs for documentation
# Usage: ./scripts/vhs/generate-demos.sh
#
# Constitutional Compliance:
# - Principle V: Modular Architecture
# - Automated demo generation for documentation
# - Run during updates/commits to keep demos current
#

set -euo pipefail

# Get repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source core utilities
source "${REPO_ROOT}/lib/core/logging.sh"
source "${REPO_ROOT}/lib/core/utils.sh"

# VHS tape files
readonly TAPES_DIR="${SCRIPT_DIR}"
readonly OUTPUT_DIR="${REPO_ROOT}/documentation/demos"

# Ensure VHS is installed
check_vhs_installed() {
    if ! command_exists "vhs"; then
        log "ERROR" "VHS not installed"
        log "ERROR" "Install with: lib/installers/vhs/install.sh"
        exit 1
    fi

    # Check dependencies
    local missing_deps=()

    if ! command_exists "ffmpeg"; then
        missing_deps+=("ffmpeg")
    fi

    if ! command_exists "ttyd"; then
        missing_deps+=("ttyd")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log "ERROR" "Missing VHS dependencies: ${missing_deps[*]}"
        log "ERROR" "Install with: lib/installers/vhs/install.sh"
        exit 1
    fi

    log "SUCCESS" "✓ VHS and dependencies installed"
}

# Generate a single demo
generate_demo() {
    local tape_file="$1"
    local tape_name
    tape_name=$(basename "$tape_file" .tape)

    log "INFO" "Generating demo: $tape_name"
    echo "  ⠋ Recording with VHS..."

    # Create output directory
    mkdir -p "$OUTPUT_DIR"

    # Run VHS (with timeout to prevent hanging)
    if timeout 120s vhs "$tape_file" 2>&1 | tee -a "${REPO_ROOT}/logs/vhs-generation.log"; then
        log "SUCCESS" "  ✓ Generated: documentation/demos/${tape_name%-demo}.gif"
        return 0
    else
        log "ERROR" "  ✗ Failed to generate demo (timeout or error)"
        return 1
    fi
}

# Main function
main() {
    log "INFO" "════════════════════════════════════════"
    log "INFO" "VHS Demo Generation"
    log "INFO" "════════════════════════════════════════"
    echo ""

    # Check VHS installation
    check_vhs_installed
    echo ""

    # Find all tape files
    local tape_files
    mapfile -t tape_files < <(find "$TAPES_DIR" -name "*.tape" -type f | sort)

    if [ ${#tape_files[@]} -eq 0 ]; then
        log "WARNING" "No .tape files found in $TAPES_DIR"
        exit 0
    fi

    log "INFO" "Found ${#tape_files[@]} demo tape(s)"
    echo ""

    # Generate each demo
    local success_count=0
    local fail_count=0

    for tape in "${tape_files[@]}"; do
        if generate_demo "$tape"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
        echo ""
    done

    # Summary
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Generation Summary"
    log "INFO" "════════════════════════════════════════"
    log "SUCCESS" "Successful: $success_count"
    [ "$fail_count" -gt 0 ] && log "ERROR" "Failed: $fail_count"
    echo ""

    if [ "$fail_count" -eq 0 ]; then
        log "SUCCESS" "✓ All demos generated successfully"
        return 0
    else
        log "ERROR" "Some demos failed to generate"
        return 1
    fi
}

main "$@"
