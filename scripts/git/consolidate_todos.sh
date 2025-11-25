#!/usr/bin/env bash
# consolidate_todos.sh - Extract and consolidate outstanding todos


# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
# shellcheck source=scripts/archive_common.sh
source "$SCRIPT_DIR/archive_common.sh"

# Configuration
DRY_RUN=false
OUTPUT_FILE="IMPLEMENTATION_CHECKLIST.md"
SORT_BY="spec"  # spec, priority, effort, phase
FILTER_SPEC=""
FILTER_PRIORITY=""
SHOW_DEPENDENCIES=false
ESTIMATE_EFFORT=true

# Version
readonly VERSION="1.0.0"
readonly FEATURE="006-task-archive-consolidation"

#######################################
# Display help message
#######################################
show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Extract all incomplete tasks from active specifications and consolidate into
a unified, prioritized implementation checklist.

OPTIONS:
  --output FILE           Output checklist file (default: $OUTPUT_FILE)
  --sort-by FIELD         Sort by: spec, priority, effort, phase (default: spec)
  --filter-spec SPEC_ID   Only include tasks from specific spec
  --filter-priority LEVEL Only include specific priority (P1/P2/P3/P4)
  --show-dependencies     Include dependency graph visualization
  --estimate-effort       Calculate total effort estimates (default: true)
  --no-estimate-effort    Skip effort estimation
  --dry-run               Show output without writing file
  --help                  Show this help message
  --version               Show version information

EXIT CODES:
  0 - Success - checklist generated
  1 - General error (invalid arguments, missing dependencies)
  4 - No incomplete tasks found
  6 - Circular dependencies detected (warning, continues)

EXAMPLES:
  # Generate consolidated checklist
  $(basename "$0")

  # Sort by priority instead of specification
  $(basename "$0") --sort-by priority

  # Only show P1 tasks
  $(basename "$0") --filter-priority P1

  # Only tasks from specific spec
  $(basename "$0") --filter-spec 005

  # Include dependency graph
  $(basename "$0") --show-dependencies

  # Output to custom file
  $(basename "$0") --output /tmp/todos.md

  # Preview without writing
  $(basename "$0") --dry-run

EOF
}

#######################################
# Display version information
#######################################
show_version() {
    echo "$(basename "$0") version $VERSION"
    echo "Feature: $FEATURE"
}

#######################################
# Estimate effort for a task
# Arguments:
#   $1 - Task description
# Outputs:
#   Effort estimate string (e.g., "2 hours", "1 day")
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
# Parse effort to hours
# Arguments:
#   $1 - Effort string (e.g., "2 hours", "1 day", "2-3 days")
# Outputs:
#   Hours (integer, or range)
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
# Extract incomplete tasks from specification
# Arguments:
#   $1 - Specification directory
# Outputs:
#   TSV lines: task_id<TAB>priority<TAB>user_story<TAB>phase<TAB>effort<TAB>description<TAB>parallel
#######################################
extract_incomplete_tasks_from_spec() {
    local spec_dir="$1"
    local tasks_file="$spec_dir/tasks.md"
    local spec_id
    spec_id=$(get_spec_id "$spec_dir")
    local line_number=0
    local current_phase=""

    if [ ! -f "$tasks_file" ]; then
        return
    fi

    while IFS= read -r line; do
        line_number=$((line_number + 1))

        # Track current phase
        if echo "$line" | grep -qE '^## Phase [0-9]+:'; then
            current_phase=$(echo "$line" | sed 's/^## //')
        fi

        # Check if this is an incomplete task
        if echo "$line" | grep -qE '^- \[ \]'; then
            local task_id
            task_id=$(extract_task_id "$line")
            local priority
            priority=$(extract_task_priority "$line")
            local user_story
            user_story=$(extract_user_story "$line")
            local parallel="no"
            if is_parallel_task "$line"; then
                parallel="yes"
            fi

            # Extract description (remove markers)
            local description
            description=$(echo "$line" | sed -E 's/^- \[ \] +T[0-9]+ +(\[P\] +)?(\[P[1-4]\] +)?(\[US[0-9]+\] +)?//')

            # Estimate effort
            local effort=""
            if [ "$ESTIMATE_EFFORT" = true ]; then
                effort=$(estimate_task_effort "$description")
            fi

            # Apply filters
            if [ -n "$FILTER_SPEC" ] && [ "$spec_id" != "$FILTER_SPEC" ]; then
                continue
            fi

            if [ -n "$FILTER_PRIORITY" ] && [ "$priority" != "$FILTER_PRIORITY" ]; then
                continue
            fi

            # Output TSV
            echo "$spec_id	$task_id	$priority	$user_story	$current_phase	$effort	$description	$parallel"
        fi
    done < "$tasks_file"
}

#######################################
# Group tasks by specification
# Arguments:
#   stdin - TSV task data
# Outputs:
#   Grouped markdown sections
#######################################
group_by_specification() {
    local current_spec=""
    local task_count=0
    local spec_effort=""

    while IFS=$'\t' read -r spec_id task_id priority user_story phase effort description parallel; do
        if [ "$spec_id" != "$current_spec" ]; then
            # Print previous spec summary
            if [ -n "$current_spec" ]; then
                echo ""
            fi

            # Print new spec header
            current_spec="$spec_id"
            task_count=0
            spec_effort=""

            local spec_title
            local spec_dir
            spec_dir=$(find_spec_dir "$spec_id" || echo "")
            if [ -n "$spec_dir" ]; then
                spec_title=$(get_spec_title "$spec_dir")
            else
                spec_title="Unknown"
            fi

            echo "### $spec_id - $spec_title"
            echo ""
        fi

        # Print task
        local priority_label=""
        if [ -n "$priority" ]; then
            priority_label="($priority) "
        fi

        local effort_label=""
        if [ -n "$effort" ]; then
            effort_label=" ($effort)"
        fi

        local parallel_label=""
        if [ "$parallel" = "yes" ]; then
            parallel_label=" [P]"
        fi

        echo "- [ ] $task_id ${priority_label}${parallel_label}$description${effort_label}"
        task_count=$((task_count + 1))
    done
}

#######################################
# Group tasks by priority
# Arguments:
#   stdin - TSV task data
# Outputs:
#   Grouped markdown sections
#######################################
group_by_priority() {
    local current_priority=""

    while IFS=$'\t' read -r spec_id task_id priority user_story phase effort description parallel; do
        if [ "$priority" != "$current_priority" ]; then
            # Print previous priority summary
            if [ -n "$current_priority" ]; then
                echo ""
            fi

            # Print new priority header
            current_priority="$priority"

            if [ -n "$current_priority" ]; then
                echo "### Priority: $current_priority"
            else
                echo "### No Priority Assigned"
            fi
            echo ""
        fi

        # Print task
        local effort_label=""
        if [ -n "$effort" ]; then
            effort_label=" ($effort)"
        fi

        local parallel_label=""
        if [ "$parallel" = "yes" ]; then
            parallel_label=" [P]"
        fi

        echo "- [ ] $task_id ${parallel_label}[$spec_id] $description${effort_label}"
    done
}

#######################################
# Generate dependency graph
# Arguments:
#   stdin - TSV task data
# Outputs:
#   Markdown dependency visualization
#######################################
generate_dependency_graph() {
    echo "## Task Dependencies"
    echo ""
    echo "_Note: Dependencies are inferred from phase order and parallel markers_"
    echo ""

    local current_spec=""

    while IFS=$'\t' read -r spec_id task_id priority user_story phase effort description parallel; do
        if [ "$spec_id" != "$current_spec" ]; then
            if [ -n "$current_spec" ]; then
                echo ""
            fi

            current_spec="$spec_id"
            echo "### $spec_id"
            echo ""
        fi

        # Show task with phase context
        if [ "$parallel" = "yes" ]; then
            echo "- $task_id: $description [Can run in parallel]"
        else
            echo "- $task_id: $description [Sequential, depends on previous tasks]"
        fi
    done

    echo ""
    print_warning "⚠️ Dependency analysis is based on task order and [P] markers"
}

#######################################
# Calculate total effort
# Arguments:
#   stdin - TSV task data
# Outputs:
#   Total effort estimate string
#######################################
calculate_total_effort() {
    local total_hours=0
    local total_min_hours=0
    local total_max_hours=0
    local has_ranges=false

    while IFS=$'\t' read -r spec_id task_id priority user_story phase effort description parallel; do
        if [ -n "$effort" ]; then
            local hours
            hours=$(parse_effort_to_hours "$effort")

            if echo "$hours" | grep -q '-'; then
                # Range
                has_ranges=true
                local min_hours max_hours
                min_hours=$(echo "$hours" | cut -d'-' -f1)
                max_hours=$(echo "$hours" | cut -d'-' -f2)
                total_min_hours=$((total_min_hours + min_hours))
                total_max_hours=$((total_max_hours + max_hours))
            elif [ -n "$hours" ]; then
                # Single value
                total_hours=$((total_hours + hours))
            fi
        fi
    done

    if [ "$has_ranges" = true ]; then
        # Convert to days
        local min_days=$((total_min_hours / 8))
        local max_days=$((total_max_hours / 8))
        echo "$min_days-$max_days days"
    elif [ "$total_hours" -gt 0 ]; then
        local days=$((total_hours / 8))
        if [ "$days" -gt 0 ]; then
            echo "$days days"
        else
            echo "$total_hours hours"
        fi
    else
        echo "Unknown"
    fi
}

#######################################
# Find specification directory by ID
# Arguments:
#   $1 - Specification ID
# Outputs:
#   Specification directory path
# Returns:
#   0 if found, 1 if not found
#######################################
find_spec_dir() {
    local spec_id="$1"
    local spec_dir

    while IFS= read -r spec_dir; do
        if [ "$(get_spec_id "$spec_dir")" = "$spec_id" ]; then
            echo "$spec_dir"
            return 0
        fi
    done < <(discover_specifications)

    return 1
}

#######################################
# Main function
#######################################
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            --sort-by)
                SORT_BY="$2"
                if [[ ! "$SORT_BY" =~ ^(spec|priority|effort|phase)$ ]]; then
                    print_error "Invalid sort field: $SORT_BY"
                    echo "Use: spec, priority, effort, or phase" >&2
                    exit "$EXIT_ERROR"
                fi
                shift 2
                ;;
            --filter-spec)
                FILTER_SPEC="$2"
                shift 2
                ;;
            --filter-priority)
                FILTER_PRIORITY="$2"
                shift 2
                ;;
            --show-dependencies)
                SHOW_DEPENDENCIES=true
                shift
                ;;
            --estimate-effort)
                ESTIMATE_EFFORT=true
                shift
                ;;
            --no-estimate-effort)
                ESTIMATE_EFFORT=false
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help)
                show_help
                exit "$EXIT_SUCCESS"
                ;;
            --version)
                show_version
                exit "$EXIT_SUCCESS"
                ;;
            -*)
                print_error "Unknown option: $1"
                echo "Use --help for usage information" >&2
                exit "$EXIT_ERROR"
                ;;
            *)
                print_error "Unexpected argument: $1"
                echo "Use --help for usage information" >&2
                exit "$EXIT_ERROR"
                ;;
        esac
    done

    print_info "$EMOJI_SCAN" "Scanning specifications for incomplete tasks..."

    # Collect all incomplete tasks
    local temp_file
    temp_file=$(mktemp)
    local sorted_file=""

    local spec_count=0
    while IFS= read -r spec_dir; do
        if ! is_valid_specification "$spec_dir"; then
            continue
        fi

        extract_incomplete_tasks_from_spec "$spec_dir" >> "$temp_file"
        spec_count=$((spec_count + 1))
    done < <(discover_specifications)

    # Check if any tasks found
    local total_tasks
    total_tasks=$(wc -l < "$temp_file")

    if [ "$total_tasks" -eq 0 ]; then
        print_warning "No incomplete tasks found"
        exit "$EXIT_NO_TASKS"
    fi

    print_info "$EMOJI_CHECKLIST" "Found $total_tasks incomplete tasks across $spec_count specifications"

    # Sort tasks
    sorted_file=$(mktemp)
    trap 'rm -f "$temp_file" "$sorted_file"' EXIT

    case "$SORT_BY" in
        spec)
            sort -t$'\t' -k1,1 -k2,2 "$temp_file" > "$sorted_file"
            ;;
        priority)
            sort -t$'\t' -k3,3 -k1,1 -k2,2 "$temp_file" > "$sorted_file"
            ;;
        effort)
            sort -t$'\t' -k6,6 -k1,1 -k2,2 "$temp_file" > "$sorted_file"
            ;;
        phase)
            sort -t$'\t' -k5,5 -k1,1 -k2,2 "$temp_file" > "$sorted_file"
            ;;
    esac

    # Generate checklist
    local output=""
    output+=$(cat <<EOF
# Implementation Checklist

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')
**Total Incomplete Tasks**: $total_tasks
**Specifications Scanned**: $spec_count

EOF
)

    # Add effort estimate if enabled
    if [ "$ESTIMATE_EFFORT" = true ]; then
        local total_effort
        total_effort=$(calculate_total_effort < "$sorted_file")
        output+=$(cat <<EOF
**Estimated Effort**: $total_effort

EOF
)
    fi

    output+=$(cat <<EOF

## Tasks by Specification

EOF
)

    # Group tasks based on sort method
    case "$SORT_BY" in
        spec)
            output+=$(group_by_specification < "$sorted_file")
            ;;
        priority)
            output+=$(group_by_priority < "$sorted_file")
            ;;
        *)
            output+=$(group_by_specification < "$sorted_file")
            ;;
    esac

    # Add dependency graph if requested
    if [ "$SHOW_DEPENDENCIES" = true ]; then
        output+=$(cat <<EOF


---

$(generate_dependency_graph < "$sorted_file")
EOF
)
    fi

    # Output results
    if [ "$DRY_RUN" = true ]; then
        echo "$output"
    else
        echo "$output" > "$OUTPUT_FILE"
        print_success "Checklist generated: $OUTPUT_FILE"
    fi

    exit "$EXIT_SUCCESS"
}

# Run main function
main "$@"
