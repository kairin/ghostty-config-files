#!/usr/bin/env bash
#
# lib/ui/progress.sh - Progress bars, spinners, and time estimation
#
# Provides visual progress indicators for installation system:
# - Progress bars (●○○○○ 20% - 2/10 tasks)
# - Spinners (gum integration with graceful degradation)
# - Time elapsed and estimated remaining
# - Header and footer boxes
#
# Constitutional Compliance:
# - Principle V: Modular Architecture
# - gum integration (constitutional requirement)
# - Graceful degradation if gum unavailable
# - Clean, professional output
#

set -euo pipefail

# Source guard - prevent redundant loading
[ -z "${PROGRESS_SH_LOADED:-}" ] || return 0
PROGRESS_SH_LOADED=1

# Source required utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../core/logging.sh"
source "${SCRIPT_DIR}/../core/utils.sh"
source "${SCRIPT_DIR}/tui.sh"   # gum integration
source "${SCRIPT_DIR}/boxes.sh" # Box drawing

# Progress bar constants
readonly PROGRESS_BAR_WIDTH=30
readonly PROGRESS_FILLED="●"
readonly PROGRESS_EMPTY="○"

# Time tracking
INSTALLATION_START_TIME=0

#
# Initialize progress tracking
#
# Sets up time tracking for installation
#
init_progress_tracking() {
    INSTALLATION_START_TIME=$(get_unix_timestamp)
    log "INFO" "Progress tracking initialized"
}

#
# Calculate progress percentage
#
# Args:
#   $1 - Completed tasks
#   $2 - Total tasks
#
# Returns:
#   Progress percentage (0-100)
#
calculate_progress_percentage() {
    local completed="$1"
    local total="$2"

    if [ "$total" -eq 0 ]; then
        echo "0"
        return
    fi

    local percentage
    percentage=$(( (completed * 100) / total ))
    echo "$percentage"
}

#
# Render progress bar
#
# Args:
#   $1 - Completed tasks
#   $2 - Total tasks
#
# Returns:
#   Formatted progress bar string
#
render_progress_bar() {
    local completed="$1"
    local total="$2"

    local percentage
    percentage=$(calculate_progress_percentage "$completed" "$total")

    # Calculate filled and empty segments
    local filled_count
    filled_count=$(( (percentage * PROGRESS_BAR_WIDTH) / 100 ))
    local empty_count
    empty_count=$(( PROGRESS_BAR_WIDTH - filled_count ))

    # Build progress bar
    local bar=""
    for (( i=0; i<filled_count; i++ )); do
        bar="${bar}${PROGRESS_FILLED}"
    done
    for (( i=0; i<empty_count; i++ )); do
        bar="${bar}${PROGRESS_EMPTY}"
    done

    # Format: ●●●●●○○○○○ 50% - 5/10 tasks
    echo "$bar ${percentage}% - ${completed}/${total} tasks"
}

#
# Show progress bar
#
# Args:
#   $1 - Completed tasks
#   $2 - Total tasks
#   $3 - Optional title (default: "Installation Progress")
#
show_progress_bar() {
    local completed="$1"
    local total="$2"
    local title="${3:-Installation Progress}"

    local progress_bar
    progress_bar=$(render_progress_bar "$completed" "$total")

    echo "$title: $progress_bar"
}

#
# Show spinner with title (gum wrapper)
#
# Args:
#   $1 - Title/message
#   $2 - Command to execute (optional)
#
# Returns:
#   Exit code from command (or 0 if no command)
#
show_spinner() {
    local title="$1"
    local command="${2:-}"

    # Use gum spinner if available (from tui.sh)
    if [ -n "$command" ]; then
        show_spinner_wrapper "$title" "$command"
    else
        # Just show title (no command to execute)
        echo "$title..."
    fi
}

#
# Calculate elapsed time
#
# Returns:
#   Elapsed time in seconds since init_progress_tracking()
#
calculate_elapsed_time() {
    local current_time
    current_time=$(get_unix_timestamp)

    local elapsed
    elapsed=$(( current_time - INSTALLATION_START_TIME ))

    echo "$elapsed"
}

#
# Estimate remaining time
#
# Args:
#   $1 - Completed tasks
#   $2 - Total tasks
#
# Returns:
#   Estimated remaining time in seconds
#
estimate_remaining_time() {
    local completed="$1"
    local total="$2"

    if [ "$completed" -eq 0 ]; then
        echo "N/A"
        return
    fi

    local elapsed
    elapsed=$(calculate_elapsed_time)

    # Calculate average time per task
    local avg_time_per_task
    avg_time_per_task=$(( elapsed / completed ))

    # Estimate remaining time
    local remaining_tasks
    remaining_tasks=$(( total - completed ))

    local estimated_remaining
    estimated_remaining=$(( remaining_tasks * avg_time_per_task ))

    echo "$estimated_remaining"
}

#
# Show header box
#
# Args:
#   $1 - Title
#   $2 - Subtitle (optional)
#
show_header() {
    local title="$1"
    local subtitle="${2:-}"

    # Pass title as box title, subtitle as content
    if [ -n "$subtitle" ]; then
        draw_box "$title" 70 "$subtitle"
    else
        draw_box "$title" 70
    fi
    echo ""
}

#
# Show footer box with time information
#
# Args:
#   $1 - Completed tasks
#   $2 - Total tasks
#
show_footer() {
    local completed="$1"
    local total="$2"

    local elapsed
    elapsed=$(calculate_elapsed_time)
    local elapsed_formatted
    elapsed_formatted=$(format_duration "$elapsed")

    local remaining
    remaining=$(estimate_remaining_time "$completed" "$total")

    local footer_lines=(
        "Time Elapsed: $elapsed_formatted"
    )

    if [ "$remaining" != "N/A" ]; then
        local remaining_formatted
        remaining_formatted=$(format_duration "$remaining")
        footer_lines+=("Estimated Remaining: $remaining_formatted")
    fi

    echo ""
    draw_box "Installation Progress" "${footer_lines[@]}"
}

#
# Show full installation status
#
# Args:
#   $1 - Completed tasks
#   $2 - Total tasks
#   $3 - Current task name (optional)
#
show_installation_status() {
    local completed="$1"
    local total="$2"
    local current_task="${3:-}"

    echo ""
    show_progress_bar "$completed" "$total" "Progress"

    if [ -n "$current_task" ]; then
        echo "Current: $current_task"
    fi

    show_footer "$completed" "$total"
    echo ""
}

#
# Show summary box after installation
#
# Args:
#   $1 - Total tasks completed
#   $2 - Total tasks failed
#   $3 - Total duration (seconds)
#
show_summary() {
    local completed="$1"
    local failed="$2"
    local duration="$3"

    local duration_formatted
    duration_formatted=$(format_duration "$duration")

    local summary_lines=(
        "Installation Complete"
        ""
        "Tasks Completed: $completed"
    )

    if [ "$failed" -gt 0 ]; then
        summary_lines+=("Tasks Failed: $failed")
    fi

    summary_lines+=(
        "Total Duration: $duration_formatted"
    )

    echo ""
    draw_box "Summary" 70 "${summary_lines[@]}"
    echo ""
}

#
# Demo progress visualization
#
# Demonstrates progress bar and time estimation
#
demo_progress() {
    init_progress_tracking

    local total_tasks=10

    show_header "Modern TUI Installation System" "Demo Progress Visualization"

    for (( i=0; i<=total_tasks; i++ )); do
        show_installation_status "$i" "$total_tasks" "Task $i of $total_tasks"
        sleep 1
    done

    show_summary "$total_tasks" 0 "$(calculate_elapsed_time)"
}

# Export functions
export -f init_progress_tracking
export -f calculate_progress_percentage
export -f render_progress_bar
export -f show_progress_bar
export -f show_spinner
export -f calculate_elapsed_time
export -f estimate_remaining_time
export -f show_header
export -f show_footer
export -f show_installation_status
export -f show_summary
export -f demo_progress
