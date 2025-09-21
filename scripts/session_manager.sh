#!/bin/bash

# Session Manager for Ghostty Installation
# Manages multiple start.sh executions with synchronized logs and screenshots

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="/tmp/ghostty-start-logs"
SCREENSHOTS_BASE="$PROJECT_ROOT/docs/assets/screenshots"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# List all installation sessions
list_sessions() {
    echo -e "${CYAN}📋 Ghostty Installation Sessions${NC}"
    echo "=================================="
    echo ""

    if [ ! -d "$LOG_DIR" ]; then
        echo -e "${YELLOW}⚠️  No sessions found. Run ./start.sh to create your first session.${NC}"
        return 0
    fi

    # Find all session manifests
    local sessions=()
    while IFS= read -r -d '' manifest; do
        sessions+=("$manifest")
    done < <(find "$LOG_DIR" -name "*-manifest.json" -print0 2>/dev/null | sort -z)

    if [ ${#sessions[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No complete sessions found.${NC}"
        return 0
    fi

    echo -e "${BLUE}Found ${#sessions[@]} session(s):${NC}"
    echo ""

    for manifest in "${sessions[@]}"; do
        local session_id=$(jq -r '.session_id' "$manifest" 2>/dev/null || echo "unknown")
        local terminal=$(jq -r '.terminal_detected' "$manifest" 2>/dev/null || echo "unknown")
        local created=$(jq -r '.created' "$manifest" 2>/dev/null || echo "unknown")
        local completed=$(jq -r '.status.completed' "$manifest" 2>/dev/null || echo "null")
        local duration=$(jq -r '.statistics.duration_seconds' "$manifest" 2>/dev/null || echo "0")
        local screenshots=$(jq -r '.statistics.screenshots_captured' "$manifest" 2>/dev/null || echo "0")
        local errors=$(jq -r '.statistics.errors_encountered' "$manifest" 2>/dev/null || echo "0")

        local status_icon="✅"
        local status_text="Completed"
        if [ "$completed" = "null" ]; then
            status_icon="🔄"
            status_text="In Progress"
        elif [ "$errors" -gt 0 ]; then
            status_icon="⚠️"
            status_text="With Warnings"
        fi

        echo -e "${BLUE}📋 Session: ${NC}$session_id"
        echo -e "   🏷️  Terminal: $terminal"
        echo -e "   📅 Created: $created"
        echo -e "   $status_icon Status: $status_text"

        if [ "$completed" != "null" ]; then
            echo -e "   ⏱️  Duration: ${duration}s"
            echo -e "   📸 Screenshots: $screenshots"
            if [ "$errors" -gt 0 ]; then
                echo -e "   ❌ Errors: $errors"
            fi
        fi
        echo ""
    done
}

# Show detailed session information
show_session() {
    local session_id="$1"
    local manifest="$LOG_DIR/$session_id-manifest.json"

    if [ ! -f "$manifest" ]; then
        echo -e "${RED}❌ Session not found: $session_id${NC}"
        return 1
    fi

    echo -e "${CYAN}📋 Session Details: $session_id${NC}"
    echo "=============================================="
    echo ""

    # Basic session info
    local terminal=$(jq -r '.terminal_detected' "$manifest")
    local created=$(jq -r '.created' "$manifest")
    local completed=$(jq -r '.status.completed' "$manifest")
    local hostname=$(jq -r '.machine_info.hostname' "$manifest")
    local user=$(jq -r '.machine_info.user' "$manifest")
    local os=$(jq -r '.machine_info.os' "$manifest")

    echo -e "${BLUE}🖥️  Machine Info:${NC}"
    echo "   Host: $hostname"
    echo "   User: $user"
    echo "   OS: $os"
    echo "   Terminal: $terminal"
    echo ""

    echo -e "${BLUE}📅 Session Timeline:${NC}"
    echo "   Started: $created"
    if [ "$completed" != "null" ]; then
        echo "   Completed: $completed"
        local duration=$(jq -r '.statistics.duration_seconds' "$manifest")
        echo "   Duration: ${duration}s"
    else
        echo "   Status: In Progress"
    fi
    echo ""

    # Statistics
    local total_stages=$(jq -r '.statistics.total_stages' "$manifest")
    local screenshots=$(jq -r '.statistics.screenshots_captured' "$manifest")
    local errors=$(jq -r '.statistics.errors_encountered' "$manifest")

    echo -e "${BLUE}📊 Statistics:${NC}"
    echo "   Stages: $total_stages"
    echo "   Screenshots: $screenshots"
    echo "   Errors: $errors"
    echo ""

    # Files
    echo -e "${BLUE}📁 Session Files:${NC}"
    echo "   📄 Main Log: $LOG_DIR/$session_id.log"
    echo "   📋 JSON Log: $LOG_DIR/$session_id.json"
    echo "   ❌ Error Log: $LOG_DIR/$session_id-errors.log"
    echo "   📊 Performance: $LOG_DIR/$session_id-performance.json"

    local screenshot_dir="$SCREENSHOTS_BASE/$session_id"
    if [ -d "$screenshot_dir" ]; then
        local screenshot_count=$(find "$screenshot_dir" -name "*.svg" 2>/dev/null | wc -l)
        echo "   📸 Screenshots: $screenshot_dir/ ($screenshot_count files)"
    else
        echo "   📸 Screenshots: None"
    fi
    echo ""

    # Stages
    echo -e "${BLUE}🔧 Installation Stages:${NC}"
    jq -r '.stages[] | "   \(.timestamp): \(.name) (\(.type))"' "$manifest" | head -10
    local stage_count=$(jq -r '.stages | length' "$manifest")
    if [ "$stage_count" -gt 10 ]; then
        echo "   ... and $((stage_count - 10)) more stages"
    fi
}

# Compare multiple sessions
compare_sessions() {
    echo -e "${CYAN}📊 Session Comparison${NC}"
    echo "====================="
    echo ""

    # Find all completed sessions
    local sessions=()
    while IFS= read -r -d '' manifest; do
        local completed=$(jq -r '.status.completed' "$manifest" 2>/dev/null)
        if [ "$completed" != "null" ]; then
            sessions+=("$manifest")
        fi
    done < <(find "$LOG_DIR" -name "*-manifest.json" -print0 2>/dev/null | sort -z)

    if [ ${#sessions[@]} -lt 2 ]; then
        echo -e "${YELLOW}⚠️  Need at least 2 completed sessions for comparison${NC}"
        return 0
    fi

    printf "%-35s %-12s %-10s %-12s %-10s\n" "Session ID" "Terminal" "Duration" "Screenshots" "Errors"
    printf "%-35s %-12s %-10s %-12s %-10s\n" "----------" "--------" "--------" "-----------" "------"

    for manifest in "${sessions[@]}"; do
        local session_id=$(jq -r '.session_id' "$manifest")
        local terminal=$(jq -r '.terminal_detected' "$manifest")
        local duration=$(jq -r '.statistics.duration_seconds' "$manifest")
        local screenshots=$(jq -r '.statistics.screenshots_captured' "$manifest")
        local errors=$(jq -r '.statistics.errors_encountered' "$manifest")

        printf "%-35s %-12s %-10ss %-12s %-10s\n" "$session_id" "$terminal" "$duration" "$screenshots" "$errors"
    done
}

# Clean up old sessions (keep last N)
cleanup_sessions() {
    local keep_count="${1:-5}"

    echo -e "${CYAN}🧹 Cleaning up old sessions (keeping last $keep_count)${NC}"
    echo "======================================================="
    echo ""

    # Find all session manifests sorted by creation time
    local sessions=()
    while IFS= read -r -d '' manifest; do
        sessions+=("$manifest")
    done < <(find "$LOG_DIR" -name "*-manifest.json" -print0 2>/dev/null | sort -z)

    local total_sessions=${#sessions[@]}

    if [ $total_sessions -le $keep_count ]; then
        echo -e "${GREEN}✅ Only $total_sessions sessions found, no cleanup needed${NC}"
        return 0
    fi

    local sessions_to_remove=$((total_sessions - keep_count))
    echo -e "${YELLOW}🗑️  Removing $sessions_to_remove old sessions...${NC}"

    for ((i=0; i<sessions_to_remove; i++)); do
        local manifest="${sessions[i]}"
        local session_id=$(jq -r '.session_id' "$manifest" 2>/dev/null || echo "unknown")

        echo "   Removing: $session_id"

        # Remove log files
        rm -f "$LOG_DIR/$session_id"* 2>/dev/null || true

        # Remove screenshot directory
        local screenshot_dir="$SCREENSHOTS_BASE/$session_id"
        if [ -d "$screenshot_dir" ]; then
            rm -rf "$screenshot_dir" 2>/dev/null || true
        fi
    done

    echo -e "${GREEN}✅ Cleanup complete${NC}"
}

# Export session data
export_session() {
    local session_id="$1"
    local output_dir="${2:-./session-export-$session_id}"

    echo -e "${CYAN}📦 Exporting session: $session_id${NC}"
    echo "=================================="

    mkdir -p "$output_dir"

    # Copy logs
    cp "$LOG_DIR/$session_id"* "$output_dir/" 2>/dev/null || true

    # Copy screenshots
    local screenshot_dir="$SCREENSHOTS_BASE/$session_id"
    if [ -d "$screenshot_dir" ]; then
        cp -r "$screenshot_dir" "$output_dir/screenshots" 2>/dev/null || true
    fi

    # Create README
    cat > "$output_dir/README.md" << EOF
# Ghostty Installation Session Export

**Session ID:** $session_id
**Exported:** $(date -Iseconds)

## Contents

- \`$session_id-manifest.json\` - Complete session metadata
- \`$session_id.log\` - Human-readable installation log
- \`$session_id.json\` - Structured JSON log
- \`$session_id-errors.log\` - Errors and warnings
- \`$session_id-performance.json\` - Performance metrics
- \`screenshots/\` - SVG screenshots captured during installation

## Usage

To view session details:
\`\`\`bash
jq '.' $session_id-manifest.json
\`\`\`

To view screenshots:
\`\`\`bash
ls screenshots/
\`\`\`
EOF

    echo -e "${GREEN}✅ Session exported to: $output_dir${NC}"
}

# Main command dispatcher
main() {
    case "${1:-list}" in
        "list"|"ls")
            list_sessions
            ;;
        "show"|"info")
            if [ -z "${2:-}" ]; then
                echo -e "${RED}❌ Usage: $0 show <session_id>${NC}"
                exit 1
            fi
            show_session "$2"
            ;;
        "compare"|"diff")
            compare_sessions
            ;;
        "cleanup"|"clean")
            cleanup_sessions "${2:-5}"
            ;;
        "export")
            if [ -z "${2:-}" ]; then
                echo -e "${RED}❌ Usage: $0 export <session_id> [output_dir]${NC}"
                exit 1
            fi
            export_session "$2" "${3:-}"
            ;;
        "help"|*)
            cat << EOF
Ghostty Installation Session Manager

Usage:
  $0 [command] [options]

Commands:
  list, ls                    List all installation sessions
  show <session_id>           Show detailed session information
  compare, diff               Compare completed sessions
  cleanup [keep_count]        Clean up old sessions (default: keep 5)
  export <session_id> [dir]   Export session data for sharing
  help                        Show this help message

Examples:
  $0 list
  $0 show 20250921-143000-ghostty-install
  $0 compare
  $0 cleanup 3
  $0 export 20250921-143000-ghostty-install

Session ID Format:
  YYYYMMDD-HHMMSS-TERMINAL-install

  Where TERMINAL is:
  - ghostty: Running in Ghostty terminal
  - ptyxis: Running in Ptyxis terminal
  - gnome-terminal: Running in GNOME Terminal
  - generic: Other/unknown terminal

Files Location:
  📄 Logs: /tmp/ghostty-start-logs/
  📸 Screenshots: docs/assets/screenshots/
  📊 Manifests: session-id-manifest.json

EOF
            ;;
    esac
}

# Run main function
main "$@"