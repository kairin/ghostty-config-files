#!/bin/bash
set -euo pipefail

# Demo: Modern TUI Installation System
# This demonstrates the proposed TUI redesign using gum

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Adaptive box drawing
detect_terminal_capability() {
    if [[ "${TERM:-}" =~ (xterm|screen|tmux|ghostty|alacritty|kitty) ]] && [[ -z "${SSH_CONNECTION:-}" ]]; then
        echo "utf8"
    else
        echo "ascii"
    fi
}

draw_box() {
    local title="$1"
    local capability=$(detect_terminal_capability)

    if [ "$capability" = "utf8" ]; then
        # UTF-8 double-line box
        local width=60
        local top="╔$(printf '═%.0s' $(seq 1 $((width-2))))╗"
        local mid="║ $(printf '%-*s' $((width-4)) "$title") ║"
        local bot="╚$(printf '═%.0s' $(seq 1 $((width-2))))╝"

        echo "$top"
        echo "$mid"
        echo "$bot"
    else
        # ASCII box
        local width=60
        local top="+$(printf '=%.0s' $(seq 1 $((width-2))))+"
        local mid="| $(printf '%-*s' $((width-4)) "$title") |"
        local bot="+$(printf '=%.0s' $(seq 1 $((width-2))))+"

        echo "$top"
        echo "$mid"
        echo "$bot"
    fi
}

# Task execution with timing and real verification
execute_task() {
    local task_name="$1"
    local task_function="$2"
    local verify_function="$3"

    local start_time=$(date +%s.%N)

    # Show spinner while task runs
    gum spin --spinner dot --title "$task_name" -- bash -c "$task_function" 2>&1 | tee /tmp/task-output.log

    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)

    # Verify task actually succeeded
    if eval "$verify_function"; then
        printf "${GREEN}✓${NC} %-50s (%.1fs)\n" "$task_name" "$duration"
        return 0
    else
        printf "${RED}✗${NC} %-50s (%.1fs) - VERIFICATION FAILED\n" "$task_name" "$duration"
        return 1
    fi
}

# Real verification functions (no hard-coded success!)
verify_prerequisites() {
    command -v git &>/dev/null && \
    command -v curl &>/dev/null && \
    command -v wget &>/dev/null
}

verify_gum_installed() {
    command -v gum &>/dev/null && gum --version &>/dev/null
}

verify_node_version() {
    if command -v node &>/dev/null; then
        local version=$(node --version | sed 's/v//')
        [[ "${version%%.*}" -ge 25 ]]
    else
        return 1
    fi
}

verify_fnm_installed() {
    command -v fnm &>/dev/null && fnm --version &>/dev/null
}

# Demo task functions
task_verify_prereqs() {
    sleep 0.5  # Simulate work
    echo "Checking git, curl, wget..."
}

task_check_gum() {
    sleep 0.3
    echo "Verifying gum installation..."
}

task_check_node() {
    sleep 0.4
    echo "Checking Node.js version..."
}

task_check_fnm() {
    sleep 0.3
    echo "Verifying fnm..."
}

# Main demo
main() {
    clear

    echo ""
    draw_box "Ghostty Configuration - Modern TUI Demo"
    echo ""

    gum style \
        --foreground 212 --border-foreground 212 --border double \
        --align center --width 60 --margin "1 2" --padding "1 2" \
        'This demo showcases the proposed TUI redesign' \
        '' \
        'Features:' \
        '• Adaptive UTF-8/ASCII box drawing' \
        '• Real verification tests (not hard-coded)' \
        '• Progress spinners and timing' \
        '• Beautiful, professional output'

    echo ""
    echo "Starting demonstration..."
    echo ""

    # Progress bar simulation
    local total_tasks=4
    local completed=0

    # Task 1
    execute_task "Verify prerequisites" "task_verify_prereqs" "verify_prerequisites"
    ((completed++))

    # Task 2
    execute_task "Verify gum installation" "task_check_gum" "verify_gum_installed"
    ((completed++))

    # Task 3
    execute_task "Check Node.js version (>=25)" "task_check_node" "verify_node_version"
    ((completed++))

    # Task 4
    execute_task "Verify fnm (Fast Node Manager)" "task_check_fnm" "verify_fnm_installed"
    ((completed++))

    echo ""

    # Final summary
    gum style \
        --foreground 10 --border-foreground 10 --border rounded \
        --align center --width 60 --margin "1 2" --padding "1 2" \
        "✓ Demo Complete: $completed/$total_tasks tasks verified" \
        '' \
        'All verifications use REAL tests, not hard-coded success!' \
        '' \
        'Ready for full implementation via spec-kit workflow.'

    echo ""
    echo "Demo features demonstrated:"
    echo "  ✓ Adaptive box drawing (UTF-8 detected: $(detect_terminal_capability))"
    echo "  ✓ Task execution with spinners"
    echo "  ✓ Real verification functions"
    echo "  ✓ Timing measurement"
    echo "  ✓ Beautiful output with gum"
    echo ""

    gum confirm "Proceed with spec-kit integration?" && \
        echo "Great! Next step: Execute /speckit.constitution for full TUI redesign" || \
        echo "No problem. Review /tmp/TUI-SYSTEM-IMPLEMENTATION-PLAN.md when ready."
}

main "$@"
