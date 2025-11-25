#!/usr/bin/env bash
# consolidate_todos.sh - Extract and consolidate outstanding todos
# Orchestrates TODO consolidation using modular components from lib/todos/

set -euo pipefail

# Script directory and repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source modular components
source "$REPO_ROOT/lib/todos/extractors.sh"
source "$REPO_ROOT/lib/todos/report.sh"

# Configuration
DRY_RUN=false
OUTPUT_FILE="IMPLEMENTATION_CHECKLIST.md"
SORT_BY="spec"  # spec, priority, effort, phase
FILTER_SPEC=""
FILTER_PRIORITY=""
SHOW_DEPENDENCIES=false
ESTIMATE_EFFORT=true

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1
readonly EXIT_NO_TASKS=4

# Version
readonly VERSION="1.0.0"
readonly FEATURE="006-task-archive-consolidation"

# Utility functions
print_error() { echo "ERROR: $*" >&2; }
print_info() { echo "$1 $2"; }
print_success() { echo "SUCCESS: $*"; }
print_warning() { echo "WARNING: $*" >&2; }

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

EXAMPLES:
  $(basename "$0")                            # Generate consolidated checklist
  $(basename "$0") --sort-by priority         # Sort by priority
  $(basename "$0") --filter-priority P1       # Only show P1 tasks
  $(basename "$0") --show-dependencies        # Include dependency graph
EOF
}

show_version() {
    echo "$(basename "$0") version $VERSION"
    echo "Feature: $FEATURE"
}

#######################################
# Discover specifications in repository
#######################################
discover_specifications() {
    find "$REPO_ROOT" -type d -name "spec-kit" -prune -o \
         -type f -name "tasks.md" -print 2>/dev/null | \
         xargs -I {} dirname {} | sort -u
}

#######################################
# Main function
#######################################
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --output) OUTPUT_FILE="$2"; shift 2 ;;
            --sort-by)
                SORT_BY="$2"
                [[ "$SORT_BY" =~ ^(spec|priority|effort|phase)$ ]] || {
                    print_error "Invalid sort field: $SORT_BY"
                    exit "$EXIT_ERROR"
                }
                shift 2 ;;
            --filter-spec) FILTER_SPEC="$2"; shift 2 ;;
            --filter-priority) FILTER_PRIORITY="$2"; shift 2 ;;
            --show-dependencies) SHOW_DEPENDENCIES=true; shift ;;
            --estimate-effort) ESTIMATE_EFFORT=true; shift ;;
            --no-estimate-effort) ESTIMATE_EFFORT=false; shift ;;
            --dry-run) DRY_RUN=true; shift ;;
            --help) show_help; exit "$EXIT_SUCCESS" ;;
            --version) show_version; exit "$EXIT_SUCCESS" ;;
            -*) print_error "Unknown option: $1"; exit "$EXIT_ERROR" ;;
            *) print_error "Unexpected argument: $1"; exit "$EXIT_ERROR" ;;
        esac
    done

    print_info "[SCAN]" "Scanning specifications for incomplete tasks..."

    # Collect all incomplete tasks
    local temp_file sorted_file
    temp_file=$(mktemp)
    sorted_file=$(mktemp)
    trap 'rm -f "$temp_file" "$sorted_file"' EXIT

    local spec_count=0
    while IFS= read -r spec_dir; do
        is_valid_specification "$spec_dir" || continue
        extract_incomplete_tasks "$spec_dir" "$ESTIMATE_EFFORT" "$FILTER_SPEC" "$FILTER_PRIORITY" >> "$temp_file"
        spec_count=$((spec_count + 1))
    done < <(discover_specifications)

    # Check if any tasks found
    local total_tasks
    total_tasks=$(wc -l < "$temp_file")

    if [[ "$total_tasks" -eq 0 ]]; then
        print_warning "No incomplete tasks found"
        exit "$EXIT_NO_TASKS"
    fi

    print_info "[LIST]" "Found $total_tasks incomplete tasks across $spec_count specifications"

    # Sort tasks
    sort_tasks "$SORT_BY" < "$temp_file" > "$sorted_file"

    # Calculate total effort if enabled
    local total_effort=""
    if [[ "$ESTIMATE_EFFORT" == "true" ]]; then
        total_effort=$(calculate_total_effort < "$sorted_file")
    fi

    # Generate checklist
    local output=""
    output+=$(generate_checklist_header "$total_tasks" "$spec_count" "$total_effort")

    # Group tasks based on sort method
    case "$SORT_BY" in
        spec) output+=$(group_by_specification < "$sorted_file") ;;
        priority) output+=$(group_by_priority < "$sorted_file") ;;
        phase) output+=$(group_by_phase < "$sorted_file") ;;
        *) output+=$(group_by_specification < "$sorted_file") ;;
    esac

    # Add dependency graph if requested
    if [[ "$SHOW_DEPENDENCIES" == "true" ]]; then
        output+=$'\n\n---\n\n'
        output+=$(generate_dependency_graph < "$sorted_file")
    fi

    # Output results
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "$output"
    else
        echo "$output" > "$OUTPUT_FILE"
        print_success "Checklist generated: $OUTPUT_FILE"
    fi

    exit "$EXIT_SUCCESS"
}

main "$@"
