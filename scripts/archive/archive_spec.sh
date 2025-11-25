#!/usr/bin/env bash
# archive_spec.sh - Specification archive generator (orchestrator)
# Uses modular components from lib/archive/
# Original: 628 lines -> Orchestrator: ~275 lines (56% reduction)

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
VERSION="2.0.0"

# Source archive modules
source "${SCRIPT_DIR}/archive_common.sh"
source "${REPO_ROOT}/lib/archive/yaml-generator.sh"
source "${REPO_ROOT}/lib/archive/validators.sh"

# Options
DRY_RUN=false
FORCE=false
VALIDATE_ONLY=false
KEEP_ORIGINAL=false
ARCHIVE_ALL=false
OUTPUT_DIR="$ARCHIVE_DIR"

show_help() {
    cat << EOF
archive_spec.sh - YAML Archive Generator v${VERSION}

USAGE: $(basename "$0") [OPTIONS] [SPEC_ID...]

Generate concise YAML archives for completed specifications with >90% size
reduction, validate file existence, and move originals to archive location.

OPTIONS:
  --all             Archive all 100% complete specifications
  --force           Re-archive even if archive exists
  --dry-run         Show what would be archived without changes
  --validate-only   Only validate file existence, don't archive
  --output-dir DIR  Archive output directory (default: $ARCHIVE_DIR)
  --keep-original   Don't move original directory
  --help            Show this help message
  --version         Show version information

EXIT CODES:
  0 - Success
  1 - General error
  2 - Validation error (files missing)
  3 - Archive already exists (without --force)
  4 - Specification not found
  5 - Specification incomplete (<100%)

EXAMPLES:
  $(basename "$0") 004                    # Archive specific spec
  $(basename "$0") --all                  # Archive all complete specs
  $(basename "$0") --all --dry-run        # Preview what would be archived
  $(basename "$0") 002 --validate-only    # Validate files only
EOF
}

show_version() {
    echo "$(basename "$0") version $VERSION"
}

find_spec_dir() {
    local spec_id="$1"
    while IFS= read -r spec_dir; do
        if [ "$(get_spec_id "$spec_dir")" = "$spec_id" ]; then
            echo "$spec_dir"
            return 0
        fi
    done < <(discover_specifications)
    return 1
}

generate_archive() {
    local spec_dir="$1"
    local spec_id
    spec_id=$(get_spec_id "$spec_dir")
    local spec_title
    spec_title=$(get_spec_title "$spec_dir")
    local tasks_file="$spec_dir/tasks.md"
    local spec_file="$spec_dir/spec.md"
    local archive_file="$OUTPUT_DIR/${spec_id}.yaml"

    # Check existing archive
    if [ -f "$archive_file" ] && [ "$FORCE" = false ]; then
        print_error "Archive already exists: $archive_file (use --force)"
        return "$EXIT_ARCHIVE_EXISTS"
    fi

    # Validate completeness
    local total_tasks
    total_tasks=$(count_total_tasks "$tasks_file")
    local completed_tasks
    completed_tasks=$(count_completed_tasks "$tasks_file")
    local completion_pct
    completion_pct=$(calculate_completion_percentage "$completed_tasks" "$total_tasks")

    print_info "$EMOJI_SCAN" "Validating $spec_id..."
    echo "  Completion: $completed_tasks/$total_tasks (${completion_pct}%)"

    # Validate files for completed tasks
    if ! validate_completed_task_files "$tasks_file"; then
        return "$EXIT_VALIDATION_ERROR"
    fi

    local file_count
    file_count=$(find "$spec_dir" -type f | wc -l)
    print_success "  All files validated ($file_count files)"

    # Stop if validate-only
    [ "$VALIDATE_ONLY" = true ] && return "$EXIT_SUCCESS"

    # Dry run check
    if [ "$DRY_RUN" = true ]; then
        print_info "$EMOJI_ARCHIVE" "[DRY RUN] Would archive to $archive_file"
        return "$EXIT_SUCCESS"
    fi

    print_info "$EMOJI_ARCHIVE" "Archiving $spec_id..."
    mkdir -p "$OUTPUT_DIR"

    # Generate YAML using module
    local status="completed"
    [ "$completion_pct" -ne 100 ] && status="in-progress"

    local summary=""
    if [ -f "$spec_file" ]; then
        summary=$(grep -A10 '^## Overview' "$spec_file" 2>/dev/null | tail -n +2 | head -n 5 | sed 's/^/  /' || echo "  No summary")
    fi

    local functional_reqs
    functional_reqs=$(extract_functional_requirements "$spec_file" 2>/dev/null || echo '    - "No requirements documented"')
    local key_completed
    key_completed=$(extract_key_completed_tasks "$tasks_file" 10)
    local key_remaining
    key_remaining=$(extract_remaining_tasks "$tasks_file" 10)

    # Use template from yaml-generator module
    local yaml_content
    yaml_content=$(generate_yaml_archive \
        "$spec_id" \
        "$spec_title" \
        "$status" \
        "$completion_pct" \
        "$spec_dir" \
        "$summary" \
        "$functional_reqs" \
        "$total_tasks" \
        "$completed_tasks" \
        "$key_completed" \
        "$key_remaining")

    echo "$yaml_content" > "$archive_file"

    # Validate generated YAML
    if has_yq && ! validate_yaml "$archive_file"; then
        print_error "Generated YAML is invalid"
        rm -f "$archive_file"
        return "$EXIT_ERROR"
    fi

    local archive_lines
    archive_lines=$(wc -l < "$archive_file")
    print_success "  Generated YAML archive ($archive_lines lines)"

    # Move original if requested
    if [ "$KEEP_ORIGINAL" = false ]; then
        mv "$spec_dir" "$OUTPUT_DIR/${spec_id}-original"
        print_success "  Moved original to archive"
    fi

    print_success "Archive complete: $archive_file"
    return "$EXIT_SUCCESS"
}

list_specifications() {
    print_info "$EMOJI_SCAN" "Scanning specifications..."
    local complete=0 incomplete=0

    while IFS= read -r spec_dir; do
        is_valid_specification "$spec_dir" || continue
        local spec_id
        spec_id=$(get_spec_id "$spec_dir")
        local tasks_file="$spec_dir/tasks.md"
        local total
        total=$(count_total_tasks "$tasks_file")
        local completed
        completed=$(count_completed_tasks "$tasks_file")
        local pct
        pct=$(calculate_completion_percentage "$completed" "$total")

        if [ "$pct" -eq 100 ]; then
            echo "  + $spec_id (100% complete)"
            ((complete++))
        else
            echo "  o $spec_id (${pct}% complete)"
            ((incomplete++))
        fi
    done < <(discover_specifications)

    echo ""
    echo "Found $((complete + incomplete)) specifications ($complete complete, $incomplete incomplete)"
    echo ""
    echo "Use: $(basename "$0") SPEC_ID     # Archive specific spec"
    echo "     $(basename "$0") --all       # Archive all complete specs"
}

main() {
    local spec_ids=()

    while [[ $# -gt 0 ]]; do
        case $1 in
            --all)           ARCHIVE_ALL=true; shift ;;
            --force)         FORCE=true; shift ;;
            --dry-run)       DRY_RUN=true; shift ;;
            --validate-only) VALIDATE_ONLY=true; shift ;;
            --output-dir)    OUTPUT_DIR="$2"; shift 2 ;;
            --keep-original) KEEP_ORIGINAL=true; shift ;;
            --help)          show_help; exit 0 ;;
            --version)       show_version; exit 0 ;;
            -*)              print_error "Unknown option: $1"; exit 1 ;;
            *)               spec_ids+=("$1"); shift ;;
        esac
    done

    # If no specs and not --all, list available
    if [ ${#spec_ids[@]} -eq 0 ] && [ "$ARCHIVE_ALL" = false ]; then
        list_specifications
        exit 0
    fi

    # Collect specs to archive
    local specs_to_archive=()

    if [ "$ARCHIVE_ALL" = true ]; then
        while IFS= read -r spec_dir; do
            is_valid_specification "$spec_dir" || continue
            local tasks_file="$spec_dir/tasks.md"
            local pct
            pct=$(calculate_completion_percentage "$(count_completed_tasks "$tasks_file")" "$(count_total_tasks "$tasks_file")")
            [ "$pct" -eq 100 ] && specs_to_archive+=("$spec_dir")
        done < <(discover_specifications)
    else
        for spec_id in "${spec_ids[@]}"; do
            local spec_dir
            if ! spec_dir=$(find_spec_dir "$spec_id"); then
                print_error "Specification not found: $spec_id"
                exit "$EXIT_NOT_FOUND"
            fi
            specs_to_archive+=("$spec_dir")
        done
    fi

    # Archive each specification
    local success=0 failure=0
    for spec_dir in "${specs_to_archive[@]}"; do
        if generate_archive "$spec_dir"; then ((success++)); else ((failure++)); fi
        echo ""
    done

    # Summary
    print_success "Archived $success specification(s)"
    [ "$failure" -gt 0 ] && print_warning "Failed: $failure specification(s)"
    [ "$failure" -eq 0 ] && exit 0 || exit 1
}

main "$@"
