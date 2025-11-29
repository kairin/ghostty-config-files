#!/usr/bin/env bash
# daily-updates.sh - Daily system updates orchestrator (thin orchestrator)
# Orchestrates update modules from lib/updates/
# Original: 1,123 lines -> Orchestrator: ~145 lines (87% reduction)

set -uo pipefail  # No -e for graceful error handling

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LOG_DIR="/tmp/daily-updates-logs"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
LOG_FILE="${LOG_DIR}/update-${TIMESTAMP}.log"
SUMMARY_FILE="${LOG_DIR}/last-update-summary.txt"

mkdir -p "$LOG_DIR"

# VHS Auto-Recording Support
if [[ -f "${REPO_ROOT}/lib/ui/vhs-auto-record.sh" ]]; then
    source "${REPO_ROOT}/lib/ui/vhs-auto-record.sh"
    maybe_start_vhs_recording "daily-updates" "$0" "$@"
fi

# Source core utilities
source "${REPO_ROOT}/lib/core/logging.sh"
source "${REPO_ROOT}/lib/core/utils.sh"

# Source update modules
source "${REPO_ROOT}/lib/updates/apt_updates.sh"
source "${REPO_ROOT}/lib/updates/npm_updates.sh"
source "${REPO_ROOT}/lib/updates/source_updates.sh"
source "${REPO_ROOT}/lib/updates/system_updates.sh"

# Tracking arrays
declare -a SUCCESSFUL_UPDATES=()
declare -a FAILED_UPDATES=()
declare -a SKIPPED_UPDATES=()
declare -a ALREADY_LATEST=()

# Command-line flags
DRY_RUN=false
SKIP_APT=false
SKIP_NODE=false
SKIP_NPM=false
FORCE_UPDATE=false

show_help() {
    cat << 'EOF'
Daily System Updates - Orchestrator v2.0

USAGE: daily-updates.sh [OPTIONS]

OPTIONS:
  --dry-run       Show what would be updated without executing
  --skip-apt      Skip apt-based updates
  --skip-node     Skip Node.js/fnm updates
  --skip-npm      Skip npm and npm-based packages
  --force         Force updates even if already at latest
  -h, --help      Show this help message

COMPONENTS UPDATED:
  1. GitHub CLI (gh) - via apt
  2. System packages - via apt
  3. Oh My Zsh - native updater
  4. fnm & Node.js - latest version
  5. npm & global packages
  6. Claude CLI, Gemini CLI, Copilot CLI
  7. uv (Python) & spec-kit
  8. Ghostty Terminal (Snap)

LOG LOCATIONS:
  Full log: /tmp/daily-updates-logs/update-TIMESTAMP.log
  Summary:  /tmp/daily-updates-logs/last-update-summary.txt
EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)      DRY_RUN=true; shift ;;
            --skip-apt)     SKIP_APT=true; shift ;;
            --skip-node)    SKIP_NODE=true; shift ;;
            --skip-npm)     SKIP_NPM=true; shift ;;
            --force)        FORCE_UPDATE=true; shift ;;
            -h|--help)      show_help; exit 0 ;;
            *)              echo "Unknown option: $1"; show_help; exit 1 ;;
        esac
    done
}

print_summary() {
    echo ""
    echo "======================================"
    echo "Update Summary"
    echo "======================================"
    echo "Successful: ${#SUCCESSFUL_UPDATES[@]}"
    echo "Already Latest: ${#ALREADY_LATEST[@]}"
    echo "Skipped: ${#SKIPPED_UPDATES[@]}"
    echo "Failed: ${#FAILED_UPDATES[@]}"
    echo ""
    [[ ${#SUCCESSFUL_UPDATES[@]} -gt 0 ]] && printf '  + %s\n' "${SUCCESSFUL_UPDATES[@]}"
    [[ ${#FAILED_UPDATES[@]} -gt 0 ]] && printf '  ! %s\n' "${FAILED_UPDATES[@]}"
}

main() {
    parse_arguments "$@"

    log "INFO" "Starting daily updates - $(date)"
    log "INFO" "Log file: $LOG_FILE"

    [[ "$DRY_RUN" == true ]] && log "WARNING" "DRY RUN MODE"

    # Execute update modules (continue on error)
    update_github_cli || true
    update_system_packages || true
    update_oh_my_zsh || true
    update_fnm_nodejs || true
    update_npm_packages || true
    update_claude_cli || true
    update_gemini_cli || true
    update_copilot_cli || true
    update_uv_tools || true
    update_ghostty_snap || true

    # Generate summary
    print_summary | tee -a "$LOG_FILE"

    # Create summary file
    {
        echo "Daily Update Summary - $(date)"
        echo "Duration: ${SECONDS}s"
        print_summary
    } > "$SUMMARY_FILE"

    # Exit based on results
    local total_good=$((${#SUCCESSFUL_UPDATES[@]} + ${#ALREADY_LATEST[@]}))
    [[ $total_good -gt 0 ]] && exit 0 || exit 1
}

main "$@"
