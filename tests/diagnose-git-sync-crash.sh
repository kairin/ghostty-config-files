#!/bin/bash
# Diagnostic script to isolate Ghostty crash during /001-03-git-sync
# This runs each command from the skill individually with delays
# Run this in Ghostty to identify which command triggers the crash
#
# Usage: ./tests/diagnose-git-sync-crash.sh [--with-output | --minimal]
#   --with-output: Show full command output (may trigger crash faster)
#   --minimal: Suppress output to reduce rendering load

set -e

MODE="${1:---with-output}"
LOG_FILE="/tmp/git-sync-crash-diag-$(date +%Y%m%d-%H%M%S).log"

log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

run_cmd() {
    local desc="$1"
    local cmd="$2"

    log ">>> Starting: $desc"
    log "    Command: $cmd"

    if [ "$MODE" = "--minimal" ]; then
        eval "$cmd" >/dev/null 2>&1
    else
        eval "$cmd" 2>&1 | tee -a "$LOG_FILE"
    fi

    log "<<< Completed: $desc"
    echo ""
    sleep 1  # Delay between commands
}

echo "=========================================="
echo "Git-Sync Crash Diagnostic Tool"
echo "=========================================="
echo "Mode: $MODE"
echo "Log file: $LOG_FILE"
echo "If Ghostty crashes, the last logged command is the trigger."
echo ""
echo "Starting in 3 seconds..."
sleep 3

log "=== DIAGNOSTIC START ==="
log "Ghostty version: $(ghostty --version 2>&1 | head -1)"
log "Terminal: $TERM"
log "Mode: $MODE"

# Phase 1: Basic git commands
log "=== PHASE 1: Basic Commands ==="
run_cmd "git status" "git status"
run_cmd "git branch (current)" "git branch --show-current"
run_cmd "git branch -vv (tracking info)" "git branch -vv"

# Phase 2: Network operations
log "=== PHASE 2: Network Commands ==="
run_cmd "git remote -v" "git remote -v"
run_cmd "git fetch --dry-run" "git fetch --dry-run"
run_cmd "git fetch --all --prune" "git fetch --all --prune"

# Phase 3: Rev-list counting (potential rapid output)
log "=== PHASE 3: Rev-list Operations ==="
run_cmd "Check upstream" "git rev-parse --abbrev-ref @{u} 2>/dev/null || echo 'no upstream'"
run_cmd "Count ahead" "git rev-list --count @{u}..HEAD 2>/dev/null || echo 'N/A'"
run_cmd "Count behind" "git rev-list --count HEAD..@{u} 2>/dev/null || echo 'N/A'"

# Phase 4: Log output (high volume, potential trigger)
log "=== PHASE 4: Log Output (High Volume) ==="
run_cmd "git log oneline (last 5)" "git log --oneline -5"
run_cmd "git log oneline @{u}..HEAD" "git log --oneline @{u}..HEAD 2>/dev/null || echo 'no upstream'"

# Phase 5: Formatted output (tables, borders)
log "=== PHASE 5: Formatted Output ==="
run_cmd "Echo table borders" "echo '====================================='"
run_cmd "Printf table row" "printf '| %-15s | %-15s |\\n' 'Status' 'UP-TO-DATE'"

# Phase 6: Rapid succession (simulate skill output)
log "=== PHASE 6: Rapid Succession (No Delays) ==="
git status >/dev/null
git branch --show-current >/dev/null
git branch -vv >/dev/null
git remote -v >/dev/null
log "Rapid succession completed without crash"

# Phase 7: Test SIGUSR2 conflict
log "=== PHASE 7: SIGUSR2 Signal Test ==="
log "Theme switcher status: $(systemctl --user is-active ghostty-theme-switcher.service 2>/dev/null || echo 'not installed')"
log "Ghostty PIDs: $(pgrep -f ghostty 2>/dev/null | tr '\n' ' ')"

log "=== DIAGNOSTIC COMPLETE ==="
echo ""
echo "=========================================="
echo "SUCCESS: All commands completed!"
echo "=========================================="
echo "No crash detected. The crash may be:"
echo "  1. Intermittent (race condition)"
echo "  2. Related to Claude Code's output rendering"
echo "  3. Triggered by specific repo state"
echo ""
echo "Recommendations:"
echo "  1. Temporarily stop theme switcher:"
echo "     systemctl --user stop ghostty-theme-switcher.service"
echo "  2. Disable git colors:"
echo "     git config --global color.ui false"
echo "  3. Test in different terminal (gnome-terminal, kitty)"
echo ""
echo "Log saved to: $LOG_FILE"
