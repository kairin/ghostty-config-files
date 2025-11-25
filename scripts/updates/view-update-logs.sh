#!/bin/bash
#
# Update Log Viewer Utility
# View daily update logs with various options
#
# Usage:
#   view-update-logs.sh              # Show latest summary
#   view-update-logs.sh --full       # Show full latest log
#   view-update-logs.sh --errors     # Show errors only
#   view-update-logs.sh --list       # List all log files
#   view-update-logs.sh --date YYYYMMDD  # Show logs from specific date

LOG_DIR="/tmp/daily-updates-logs"
SUMMARY_FILE="${LOG_DIR}/last-update-summary.txt"
LATEST_LOG="${LOG_DIR}/latest.log"

show_summary() {
    if [[ -f "$SUMMARY_FILE" ]]; then
        cat "$SUMMARY_FILE"
    else
        echo "⚠️  No update summary found. Updates may not have run yet."
        echo "Run: /home/kkk/Apps/ghostty-config-files/scripts/daily-updates.sh"
    fi
}

show_full_log() {
    if [[ -f "$LATEST_LOG" ]]; then
        echo "=== Latest Update Log ==="
        echo ""
        cat "$LATEST_LOG"
    else
        echo "⚠️  No update log found."
    fi
}

show_errors() {
    if [[ -d "$LOG_DIR" ]]; then
        local error_files=$(find "$LOG_DIR" -name "errors-*.log" -type f 2>/dev/null | sort -r)
        if [[ -n "$error_files" ]]; then
            echo "=== Recent Error Logs ==="
            echo ""
            head -100 $(echo "$error_files" | head -1)
        else
            echo "✅ No error logs found!"
        fi
    else
        echo "⚠️  Log directory not found."
    fi
}

list_logs() {
    if [[ -d "$LOG_DIR" ]]; then
        echo "=== Available Update Logs ==="
        echo ""
        ls -lht "$LOG_DIR" | head -20
        echo ""
        echo "Log directory: $LOG_DIR"
    else
        echo "⚠️  Log directory not found."
    fi
}

show_date_log() {
    local date="$1"
    local log_file="${LOG_DIR}/update-${date}*.log"

    # shellcheck disable=SC2086
    if ls $log_file 1>/dev/null 2>&1; then
        echo "=== Update Log for $date ==="
        echo ""
        # shellcheck disable=SC2086
        cat $log_file
    else
        echo "⚠️  No log found for date: $date"
        echo "Available dates:"
        ls "$LOG_DIR"/update-*.log 2>/dev/null | sed 's/.*update-//' | sed 's/-.*//' | sort -u
    fi
}

# Main
case "${1:-}" in
    --full|-f)
        show_full_log
        ;;
    --errors|-e)
        show_errors
        ;;
    --list|-l)
        list_logs
        ;;
    --date|-d)
        if [[ -n "${2:-}" ]]; then
            show_date_log "$2"
        else
            echo "Usage: $0 --date YYYYMMDD"
            exit 1
        fi
        ;;
    --help|-h)
        echo "Update Log Viewer"
        echo ""
        echo "Usage:"
        echo "  $0              Show latest summary"
        echo "  $0 --full       Show full latest log"
        echo "  $0 --errors     Show error logs"
        echo "  $0 --list       List all log files"
        echo "  $0 --date DATE  Show log from specific date (YYYYMMDD)"
        echo "  $0 --help       Show this help"
        ;;
    *)
        show_summary
        ;;
esac
