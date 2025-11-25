#!/usr/bin/env bash
# lib/todos/reporters/markdown.sh - Markdown report generation for TODOs
# Extracted from lib/todos/report.sh for modularity

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_TODOS_MARKDOWN_REPORTER_SOURCED:-}" ]] && return 0
readonly _TODOS_MARKDOWN_REPORTER_SOURCED=1

#######################################
# Generate checklist header
# Arguments:
#   $1 - Total tasks count
#   $2 - Spec count
#   $3 - Total effort estimate (optional)
# Outputs:
#   Markdown header
#######################################
generate_checklist_header() {
    local total_tasks="$1"
    local spec_count="$2"
    local total_effort="${3:-}"

    cat <<EOF
# Implementation Checklist

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')
**Total Incomplete Tasks**: $total_tasks
**Specifications Scanned**: $spec_count
EOF

    if [[ -n "$total_effort" ]]; then
        echo "**Estimated Effort**: $total_effort"
    fi

    echo ""
    echo "## Tasks by Specification"
    echo ""
}

#######################################
# Generate summary statistics
# Arguments:
#   $1 - Total tasks
#   $2 - Spec count
#   $3 - P1 count
#   $4 - P2 count
#   $5 - P3 count
#   $6 - P4 count
# Outputs:
#   Markdown statistics table
#######################################
generate_summary_stats() {
    local total_tasks="$1"
    local spec_count="$2"
    local p1_count="${3:-0}"
    local p2_count="${4:-0}"
    local p3_count="${5:-0}"
    local p4_count="${6:-0}"

    cat <<EOF
## Summary Statistics

| Metric | Count |
|--------|-------|
| Total Tasks | $total_tasks |
| Specifications | $spec_count |
| P1 (Critical) | $p1_count |
| P2 (High) | $p2_count |
| P3 (Medium) | $p3_count |
| P4 (Low) | $p4_count |
EOF
}

#######################################
# Group tasks by specification in markdown
# Arguments:
#   stdin - TSV task data
# Outputs:
#   Grouped markdown sections
#######################################
group_by_specification() {
    local current_spec=""

    while IFS=$'\t' read -r spec_id task_id priority user_story phase effort description parallel; do
        if [[ "$spec_id" != "$current_spec" ]]; then
            # Print previous spec summary
            if [[ -n "$current_spec" ]]; then
                echo ""
            fi

            # Print new spec header
            current_spec="$spec_id"

            local spec_title="Unknown"
            # Try to get title if function available
            if declare -f get_spec_title &>/dev/null; then
                local spec_dir
                spec_dir=$(find_spec_dir "$spec_id" 2>/dev/null || echo "")
                if [[ -n "$spec_dir" ]]; then
                    spec_title=$(get_spec_title "$spec_dir")
                fi
            fi

            echo "### $spec_id - $spec_title"
            echo ""
        fi

        # Print task
        local priority_label=""
        if [[ -n "$priority" ]]; then
            priority_label="($priority) "
        fi

        local effort_label=""
        if [[ -n "$effort" ]]; then
            effort_label=" ($effort)"
        fi

        local parallel_label=""
        if [[ "$parallel" == "yes" ]]; then
            parallel_label=" [P]"
        fi

        echo "- [ ] $task_id ${priority_label}${parallel_label}$description${effort_label}"
    done
}

#######################################
# Group tasks by priority in markdown
# Arguments:
#   stdin - TSV task data
# Outputs:
#   Grouped markdown sections
#######################################
group_by_priority() {
    local current_priority=""

    while IFS=$'\t' read -r spec_id task_id priority user_story phase effort description parallel; do
        if [[ "$priority" != "$current_priority" ]]; then
            # Print previous priority summary
            if [[ -n "$current_priority" ]]; then
                echo ""
            fi

            # Print new priority header
            current_priority="$priority"

            if [[ -n "$current_priority" ]]; then
                echo "### Priority: $current_priority"
            else
                echo "### No Priority Assigned"
            fi
            echo ""
        fi

        # Print task
        local effort_label=""
        if [[ -n "$effort" ]]; then
            effort_label=" ($effort)"
        fi

        local parallel_label=""
        if [[ "$parallel" == "yes" ]]; then
            parallel_label=" [P]"
        fi

        echo "- [ ] $task_id ${parallel_label}[$spec_id] $description${effort_label}"
    done
}

#######################################
# Group tasks by phase in markdown
# Arguments:
#   stdin - TSV task data
# Outputs:
#   Grouped markdown sections
#######################################
group_by_phase() {
    local current_phase=""

    while IFS=$'\t' read -r spec_id task_id priority user_story phase effort description parallel; do
        if [[ "$phase" != "$current_phase" ]]; then
            if [[ -n "$current_phase" ]]; then
                echo ""
            fi

            current_phase="$phase"

            if [[ -n "$current_phase" ]]; then
                echo "### $current_phase"
            else
                echo "### Unphased Tasks"
            fi
            echo ""
        fi

        local priority_label=""
        if [[ -n "$priority" ]]; then
            priority_label="($priority) "
        fi

        local effort_label=""
        if [[ -n "$effort" ]]; then
            effort_label=" ($effort)"
        fi

        echo "- [ ] $task_id ${priority_label}[$spec_id] $description${effort_label}"
    done
}

#######################################
# Generate dependency graph visualization
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
        if [[ "$spec_id" != "$current_spec" ]]; then
            if [[ -n "$current_spec" ]]; then
                echo ""
            fi

            current_spec="$spec_id"
            echo "### $spec_id"
            echo ""
        fi

        # Show task with phase context
        if [[ "$parallel" == "yes" ]]; then
            echo "- $task_id: $description [Can run in parallel]"
        else
            echo "- $task_id: $description [Sequential, depends on previous tasks]"
        fi
    done

    echo ""
    echo "Note: Dependency analysis is based on task order and [P] markers"
}

# Export functions
export -f generate_checklist_header generate_summary_stats
export -f group_by_specification group_by_priority group_by_phase
export -f generate_dependency_graph
