#!/bin/bash
# daily-updates.sh - Automated Update Everything Workflow
# Constitutional Compliance: Script Proliferation Prevention (justified orchestrator)
#
# This script provides comprehensive update management:
# - Detects available updates for all installed tools
# - Creates backups before applying updates
# - Applies updates via existing 004-reinstall scripts (reuse, not proliferation)
# - Runs complete CI/CD validation after updates
# - Supports interactive, non-interactive (cron), and dry-run modes
# - Provides lock file management to prevent concurrent runs
#
# Exit Codes:
#   0: All updates successful (or dry-run complete)
#   1: Some updates failed (non-critical)
#   2: Validation failed (rollback recommended)
#   3: Already running (lock file exists)
#   4: Prerequisites not met

set -euo pipefail

# =============================================================================
# INITIALIZATION (30 lines)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
LOCK_FILE="/tmp/daily-updates.lock"

# Source shared utilities
source "${SCRIPT_DIR}/006-logs/logger.sh"

# State variables
DRY_RUN=0
NON_INTERACTIVE=0
INSTALL_CRON=0
SKIP_VALIDATION=0
BACKUP_PATH=""
START_TIME=$(date +%s)

# Counters
UPDATES_TOTAL=0
UPDATES_SUCCESS=0
UPDATES_FAILED=0
UPDATES_SKIPPED=0

# =============================================================================
# ARGUMENT PARSING (30 lines)
# =============================================================================

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Automated update workflow for all installed tools.

Options:
    --dry-run           Check for updates without applying
    --non-interactive   Run without prompts (for cron)
    --install-cron      Install daily cron job (9 AM)
    --skip-validation   Skip CI/CD validation after updates
    -h, --help          Show this help message

Examples:
    $(basename "$0")                 # Interactive mode
    $(basename "$0") --dry-run       # Check only
    $(basename "$0") --non-interactive  # Cron mode
    $(basename "$0") --install-cron  # Setup automation

Exit codes: 0=success, 1=partial failure, 2=validation failed, 3=locked, 4=prereq failed
EOF
    exit 0
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run) DRY_RUN=1; shift ;;
            --non-interactive) NON_INTERACTIVE=1; shift ;;
            --install-cron) INSTALL_CRON=1; shift ;;
            --skip-validation) SKIP_VALIDATION=1; shift ;;
            -h|--help) usage ;;
            *) echo "Unknown option: $1"; usage ;;
        esac
    done
}

# =============================================================================
# LOCK MANAGEMENT (20 lines)
# =============================================================================

acquire_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        local pid
        pid=$(cat "$LOCK_FILE" 2>/dev/null) || pid=""
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            log "ERROR" "Another update process is running (PID: $pid)"
            return 3
        fi
        log "WARNING" "Stale lock file found, removing"
        rm -f "$LOCK_FILE"
    fi
    echo $$ > "$LOCK_FILE"
    trap release_lock EXIT
    return 0
}

release_lock() {
    rm -f "$LOCK_FILE"
}

# =============================================================================
# UPDATE DETECTION (30 lines)
# =============================================================================

# Tool to install script mapping
declare -A TOOL_SCRIPTS=(
    ["Ghostty"]="install_ghostty.sh"
    ["Fastfetch"]="install_fastfetch.sh"
    ["Glow"]="install_glow.sh"
    ["Go"]="install_go.sh"
    ["Gum"]="install_gum.sh"
    ["Node.js"]="install_nodejs.sh"
    ["Python (uv)"]="install_python_uv.sh"
    ["VHS"]="install_vhs.sh"
    ["Nerd Fonts"]="install_nerdfonts.sh"
    ["Feh"]="install_feh.sh"
    ["Zsh"]="install_zsh.sh"
    ["Local AI Tools"]="install_ai_tools.sh"
)

detect_updates() {
    log "INFO" "Detecting available updates..."
    local updates_json
    updates_json=$("${SCRIPT_DIR}/check_updates.sh" --json 2>/dev/null) || true

    # Parse JSON output for tools with updates
    echo "$updates_json" | grep -o '"tool": "[^"]*", "current": "[^"]*", "latest": "[^"]*", "update_available": true' | \
        sed 's/"tool": "\([^"]*\)", "current": "\([^"]*\)", "latest": "\([^"]*\)".*/\1|\2|\3/'
}

map_tool_to_script() {
    local tool_name="$1"
    echo "${TOOL_SCRIPTS[$tool_name]:-}"
}

# =============================================================================
# UPDATE APPLICATION (40 lines)
# =============================================================================

apply_update() {
    local tool_name="$1"
    local current_version="$2"
    local target_version="$3"

    local script_name=$(map_tool_to_script "$tool_name")
    local script_path="${SCRIPT_DIR}/004-reinstall/${script_name}"

    if [[ -z "$script_name" ]] || [[ ! -x "$script_path" ]]; then
        log "WARNING" "No install script found for ${tool_name}"
        log_update_result "$tool_name" "SKIPPED" "No install script available"
        ((UPDATES_SKIPPED++))
        return 1
    fi

    log_update_start "$tool_name" "$current_version" "$target_version"

    if [[ $DRY_RUN -eq 1 ]]; then
        log "INFO" "[DRY-RUN] Would update ${tool_name} using ${script_name}"
        log_update_result "$tool_name" "SKIPPED" "Dry-run mode"
        ((UPDATES_SKIPPED++))
        return 0
    fi

    # Execute the install script (which handles updates by installing latest)
    if bash "$script_path" 2>&1; then
        log_update_result "$tool_name" "SUCCESS" "Updated to ${target_version}"
        ((UPDATES_SUCCESS++))
        return 0
    else
        log_update_result "$tool_name" "ERROR" "Update failed"
        ((UPDATES_FAILED++))
        return 1
    fi
}

apply_all_updates() {
    local updates="$1"

    while IFS='|' read -r tool current latest; do
        [[ -z "$tool" ]] && continue
        ((UPDATES_TOTAL++))
        apply_update "$tool" "$current" "$latest" || true
    done <<< "$updates"
}

# =============================================================================
# VALIDATION (30 lines)
# =============================================================================

run_validation() {
    if [[ $SKIP_VALIDATION -eq 1 ]]; then
        log "INFO" "Skipping validation (--skip-validation)"
        return 0
    fi

    log "INFO" "Running post-update validation..."

    local validation_script="${REPO_ROOT}/.runners-local/workflows/gh-workflow-local.sh"
    if [[ -x "$validation_script" ]]; then
        if "$validation_script" all 2>&1; then
            log "SUCCESS" "CI/CD validation passed"
            return 0
        else
            log "ERROR" "CI/CD validation failed"
            return 2
        fi
    else
        log "WARNING" "Validation script not found: ${validation_script}"
        return 0
    fi
}

# =============================================================================
# USER INTERACTION (40 lines)
# =============================================================================

confirm_updates() {
    local updates="$1"
    local count=$(echo "$updates" | grep -c '|' || echo "0")

    if [[ $NON_INTERACTIVE -eq 1 ]]; then
        log "INFO" "Non-interactive mode: proceeding with ${count} update(s)"
        return 0
    fi

    echo ""
    echo "Available Updates:"
    echo "════════════════════════════════════════════════════════════════"
    while IFS='|' read -r tool current latest; do
        [[ -z "$tool" ]] && continue
        printf "  %-20s %s -> %s\n" "$tool" "$current" "$latest"
    done <<< "$updates"
    echo "════════════════════════════════════════════════════════════════"
    echo ""

    read -p "Apply ${count} update(s)? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "INFO" "Update cancelled by user"
        return 1
    fi
    return 0
}

show_summary() {
    local duration=$(($(date +%s) - START_TIME))

    echo ""
    echo "Update Summary"
    echo "════════════════════════════════════════════════════════════════"
    echo "  Total:    ${UPDATES_TOTAL}"
    echo "  Success:  ${UPDATES_SUCCESS}"
    echo "  Failed:   ${UPDATES_FAILED}"
    echo "  Skipped:  ${UPDATES_SKIPPED}"
    echo "  Duration: ${duration}s"
    echo "════════════════════════════════════════════════════════════════"

    finalize_update_log "$UPDATES_TOTAL" "$UPDATES_SUCCESS" "$UPDATES_FAILED" "$UPDATES_SKIPPED" "$duration"
}

# =============================================================================
# CRON INSTALLATION (20 lines)
# =============================================================================

install_cron_job() {
    local cron_entry="0 9 * * * ${SCRIPT_DIR}/daily-updates.sh --non-interactive >> ${REPO_ROOT}/.runners-local/logs/cron-updates.log 2>&1"

    # Check if already installed
    if crontab -l 2>/dev/null | grep -q "daily-updates.sh"; then
        log "INFO" "Cron job already installed"
        crontab -l 2>/dev/null | grep "daily-updates.sh"
        return 0
    fi

    # Add to crontab
    (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
    log "SUCCESS" "Installed daily cron job (9:00 AM)"
    log "INFO" "Entry: $cron_entry"
    return 0
}

# =============================================================================
# MAIN WORKFLOW (40 lines)
# =============================================================================

check_prerequisites() {
    # Check for required scripts
    if [[ ! -x "${SCRIPT_DIR}/check_updates.sh" ]]; then
        log "ERROR" "Required script not found: check_updates.sh"
        return 4
    fi

    if [[ ! -d "${SCRIPT_DIR}/004-reinstall" ]]; then
        log "ERROR" "Install scripts directory not found: 004-reinstall/"
        return 4
    fi

    return 0
}

main() {
    parse_arguments "$@"

    # Handle cron installation separately
    if [[ $INSTALL_CRON -eq 1 ]]; then
        install_cron_job
        exit $?
    fi

    log "INFO" "Starting daily update workflow..."
    [[ $DRY_RUN -eq 1 ]] && log "INFO" "Running in DRY-RUN mode"
    [[ $NON_INTERACTIVE -eq 1 ]] && log "INFO" "Running in NON-INTERACTIVE mode"

    # Prerequisites
    check_prerequisites || exit $?

    # Acquire lock
    acquire_lock || exit $?

    # Initialize logging
    init_update_log

    # Detect updates
    local updates
    updates=$(detect_updates)

    if [[ -z "$updates" ]]; then
        log "SUCCESS" "All tools are up to date"
        finalize_update_log 0 0 0 0 0
        exit 0
    fi

    # Confirm with user (unless non-interactive or dry-run)
    if [[ $DRY_RUN -eq 0 ]]; then
        confirm_updates "$updates" || exit 0
    fi

    # Create backup before updates
    if [[ $DRY_RUN -eq 0 ]]; then
        BACKUP_PATH=$(backup_configs "pre-update") || log "WARNING" "Backup skipped"
        cleanup_old_backups
    fi

    # Apply updates
    apply_all_updates "$updates"

    # Show summary
    show_summary

    # Run validation
    if [[ $DRY_RUN -eq 0 ]] && [[ $UPDATES_SUCCESS -gt 0 ]]; then
        run_validation
        local validation_result=$?
        if [[ $validation_result -ne 0 ]] && [[ -n "$BACKUP_PATH" ]]; then
            log "WARNING" "Validation failed. Backup available at: $BACKUP_PATH"
            log "INFO" "To restore: source ${SCRIPT_DIR}/006-logs/logger.sh && restore_from_backup '$BACKUP_PATH'"
        fi
        exit $validation_result
    fi

    # Exit based on results
    [[ $UPDATES_FAILED -gt 0 ]] && exit 1
    exit 0
}

main "$@"
