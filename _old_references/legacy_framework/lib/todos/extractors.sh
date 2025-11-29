#!/usr/bin/env bash
# lib/todos/extractors.sh - TODO extraction and parsing utilities
# Extracted from scripts/git/consolidate_todos.sh for modularity

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_TODOS_EXTRACTORS_SOURCED:-}" ]] && return 0
readonly _TODOS_EXTRACTORS_SOURCED=1

#######################################
# Estimate effort for a task from its description
# Arguments:
#   $1 - Task description
# Outputs:
#   Effort estimate string (e.g., "2 hours", "1 day") or empty
#######################################
estimate_task_effort() {
    local task_desc="$1"

    # Extract explicit effort from description
    if echo "$task_desc" | grep -qE '\([0-9]+-?[0-9]* (hour|day)s?\)'; then
        echo "$task_desc" | grep -oE '\([0-9]+-?[0-9]* (hour|day)s?\)' | tr -d '()'
    elif echo "$task_desc" | grep -qE '\([0-9]+ (hour|day)s?\)'; then
        echo "$task_desc" | grep -oE '\([0-9]+ (hour|day)s?\)' | tr -d '()'
    else
        echo ""
    fi
}

#######################################
# Parse effort string to hours
# Arguments:
#   $1 - Effort string (e.g., "2 hours", "1 day", "2-3 days")
# Outputs:
#   Hours (integer or range like "16-24")
#######################################
parse_effort_to_hours() {
    local effort="$1"

    if echo "$effort" | grep -qE '[0-9]+-[0-9]+ days?'; then
        # Range of days
        local min_days max_days
        min_days=$(echo "$effort" | grep -oE '[0-9]+' | head -1)
        max_days=$(echo "$effort" | grep -oE '[0-9]+' | tail -1)
        echo "$((min_days * 8))-$((max_days * 8))"
    elif echo "$effort" | grep -qE '[0-9]+ days?'; then
        # Single day value
        local days
        days=$(echo "$effort" | grep -oE '[0-9]+')
        echo "$((days * 8))"
    elif echo "$effort" | grep -qE '[0-9]+-[0-9]+ hours?'; then
        # Range of hours
        echo "$effort" | grep -oE '[0-9]+-[0-9]+'
    elif echo "$effort" | grep -qE '[0-9]+ hours?'; then
        # Single hour value
        echo "$effort" | grep -oE '[0-9]+'
    else
        echo ""
    fi
}

#######################################
# Extract task ID from task line
# Arguments:
#   $1 - Task line
# Outputs:
#   Task ID (e.g., "T001") or empty
#######################################
extract_task_id() {
    local line="$1"
    echo "$line" | grep -oE 'T[0-9]{3}' | head -1 || echo ""
}

#######################################
# Extract task priority from task line
# Arguments:
#   $1 - Task line
# Outputs:
#   Priority (e.g., "P1", "P2") or empty
#######################################
extract_task_priority() {
    local line="$1"
    echo "$line" | grep -oE '\[P[1-4]\]' | tr -d '[]' || echo ""
}

#######################################
# Extract user story reference from task line
# Arguments:
#   $1 - Task line
# Outputs:
#   User story ID (e.g., "US001") or empty
#######################################
extract_user_story() {
    local line="$1"
    echo "$line" | grep -oE '\[US[0-9]+\]' | tr -d '[]' || echo ""
}

#######################################
# Check if task is marked as parallel
# Arguments:
#   $1 - Task line
# Returns:
#   0 if parallel, 1 if not
#######################################
is_parallel_task() {
    local line="$1"
    echo "$line" | grep -qE '\[P\]'
}

#######################################
# Extract incomplete tasks from a specification directory
# Arguments:
#   $1 - Specification directory path
#   $2 - Whether to estimate effort (true/false)
#   $3 - Filter spec ID (optional)
#   $4 - Filter priority (optional)
# Outputs:
#   TSV: spec_id<TAB>task_id<TAB>priority<TAB>user_story<TAB>phase<TAB>effort<TAB>description<TAB>parallel
#######################################
extract_incomplete_tasks() {
    local spec_dir="$1"
    local estimate_effort="${2:-true}"
    local filter_spec="${3:-}"
    local filter_priority="${4:-}"

    local tasks_file="$spec_dir/tasks.md"

    # Get spec ID from directory name
    local spec_id
    spec_id=$(basename "$spec_dir")

    local current_phase=""

    if [[ ! -f "$tasks_file" ]]; then
        return
    fi

    while IFS= read -r line; do
        # Track current phase
        if echo "$line" | grep -qE '^## Phase [0-9]+:'; then
            current_phase=$(echo "$line" | sed 's/^## //')
        fi

        # Check if this is an incomplete task
        if echo "$line" | grep -qE '^- \[ \]'; then
            local task_id priority user_story parallel="no"

            task_id=$(extract_task_id "$line")
            priority=$(extract_task_priority "$line")
            user_story=$(extract_user_story "$line")

            if is_parallel_task "$line"; then
                parallel="yes"
            fi

            # Extract description (remove markers)
            local description
            description=$(echo "$line" | sed -E 's/^- \[ \] +T[0-9]+ +(\[P\] +)?(\[P[1-4]\] +)?(\[US[0-9]+\] +)?//')

            # Estimate effort if enabled
            local effort=""
            if [[ "$estimate_effort" == "true" ]]; then
                effort=$(estimate_task_effort "$description")
            fi

            # Apply filters
            if [[ -n "$filter_spec" ]] && [[ "$spec_id" != "$filter_spec" ]]; then
                continue
            fi

            if [[ -n "$filter_priority" ]] && [[ "$priority" != "$filter_priority" ]]; then
                continue
            fi

            # Output TSV
            echo "$spec_id	$task_id	$priority	$user_story	$current_phase	$effort	$description	$parallel"
        fi
    done < "$tasks_file"
}

#######################################
# Extract completed tasks from a specification
# Arguments:
#   $1 - Specification directory path
#   $2 - Maximum tasks to extract (optional, default 10)
# Outputs:
#   TSV: spec_id<TAB>task_id<TAB>description
#######################################
extract_completed_tasks() {
    local spec_dir="$1"
    local max_tasks="${2:-10}"

    local tasks_file="$spec_dir/tasks.md"
    local spec_id
    spec_id=$(basename "$spec_dir")
    local count=0

    if [[ ! -f "$tasks_file" ]]; then
        return
    fi

    while IFS= read -r line && [[ "$count" -lt "$max_tasks" ]]; do
        if echo "$line" | grep -qE '^- \[[xX]\]'; then
            local task_id description
            task_id=$(extract_task_id "$line")
            description=$(echo "$line" | sed -E 's/^- \[[xX]\] +T[0-9]+ +(\[P\] +)?(\[US[0-9]+\] +)?//')
            echo "$spec_id	$task_id	$description"
            ((count++))
        fi
    done < "$tasks_file"
}

#######################################
# Count tasks by status in a tasks file
# Arguments:
#   $1 - Tasks file path
# Outputs:
#   total<TAB>completed<TAB>incomplete
#######################################
count_tasks() {
    local tasks_file="$1"

    if [[ ! -f "$tasks_file" ]]; then
        echo "0	0	0"
        return
    fi

    local total completed incomplete
    total=$(grep -cE '^- \[([ xX])\]' "$tasks_file" 2>/dev/null || echo "0")
    completed=$(grep -cE '^- \[[xX]\]' "$tasks_file" 2>/dev/null || echo "0")
    incomplete=$(grep -cE '^- \[ \]' "$tasks_file" 2>/dev/null || echo "0")

    echo "$total	$completed	$incomplete"
}

#######################################
# Discover all specification directories
# Arguments:
#   $1 - Base directory to search (optional)
# Outputs:
#   List of specification directory paths (one per line)
#######################################
discover_spec_directories() {
    local base_dir="${1:-.}"

    # Find directories containing spec.md or tasks.md
    # shellcheck disable=SC2038 # Using -I {} placeholder safely handles spaces
    find "$base_dir" -type d -name "spec-kit" -prune -o \
         -type f \( -name "tasks.md" -o -name "spec.md" \) -print 2>/dev/null | \
         xargs -I {} dirname {} | sort -u
}

#######################################
# Validate specification directory
# Arguments:
#   $1 - Directory path
# Returns:
#   0 if valid, 1 if not
#######################################
is_valid_specification() {
    local spec_dir="$1"
    [[ -d "$spec_dir" ]] && [[ -f "$spec_dir/tasks.md" ]]
}

#######################################
# Get specification title from spec.md
# Arguments:
#   $1 - Specification directory
# Outputs:
#   Title string or "Unknown"
#######################################
get_spec_title() {
    local spec_dir="$1"
    local spec_file="$spec_dir/spec.md"

    if [[ -f "$spec_file" ]]; then
        grep -m1 '^# ' "$spec_file" | sed 's/^# //' || echo "Unknown"
    else
        echo "Unknown"
    fi
}

# Export functions
export -f estimate_task_effort parse_effort_to_hours
export -f extract_task_id extract_task_priority extract_user_story is_parallel_task
export -f extract_incomplete_tasks extract_completed_tasks
export -f count_tasks discover_spec_directories is_valid_specification get_spec_title
