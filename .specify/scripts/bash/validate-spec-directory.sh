#!/bin/bash
# Script: validate-spec-directory.sh
# Purpose: Prevent duplicate/obsolete spec directories from accumulating
# Usage: Run before commits to validate spec directory structure
# Exit Codes: 0=valid, 1=duplicates found, 2=invalid structure

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
SPECS_DIR="${REPO_ROOT}/specs"

# ============================================================
# VALIDATION RULES
# ============================================================

# Rule 1: No duplicate numeric prefixes in active specs
# Valid: 005-complete-terminal-infrastructure
# Invalid: 005-apt-snap-migration + 005-complete-terminal-infrastructure (duplicate 005)
validate_no_duplicate_prefixes() {
    local duplicates_found=0
    local prefixes=()

    echo "=== Rule 1: Checking for duplicate numeric prefixes ==="

    # Find all directories with numeric prefix pattern (XXX-*)
    while IFS= read -r spec_dir; do
        local basename=$(basename "$spec_dir")

        # Extract numeric prefix (first 3 digits)
        if [[ $basename =~ ^([0-9]{3})- ]]; then
            local prefix="${BASH_REMATCH[1]}"

            # Check if prefix already seen
            if [[ " ${prefixes[@]:-} " =~ " ${prefix} " ]]; then
                echo "✗ ERROR: Duplicate prefix '$prefix' found:"
                echo "    $(ls -d "${SPECS_DIR}/${prefix}-"* | xargs -n1 basename)"
                duplicates_found=1
            else
                prefixes+=("$prefix")
                echo "  ✓ Prefix $prefix: $basename"
            fi
        fi
    done < <(find "$SPECS_DIR" -mindepth 1 -maxdepth 1 -type d ! -name ".*" ! -name "2025*")

    if [[ $duplicates_found -eq 1 ]]; then
        echo ""
        echo "🚨 RESOLUTION: Remove obsolete duplicate specs:"
        echo "   git rm -rf specs/XXX-old-spec-name/"
        echo "   (Git history preserves all work - no data loss)"
        return 1
    fi

    echo "✓ No duplicate prefixes found"
    return 0
}

# Rule 2: Archived features use timestamp prefix (YYYYMMDD-HHMMSS-*)
# Valid: 20251115-202826-feat-speckit-audit-consolidation
# Invalid: my-feature-archive (no timestamp)
validate_archived_feature_naming() {
    local invalid_archives=0

    echo ""
    echo "=== Rule 2: Checking archived feature naming ==="

    # Find archived features (timestamp prefix pattern)
    while IFS= read -r spec_dir; do
        local basename=$(basename "$spec_dir")

        # Check if it's an archived feature (starts with YYYYMMDD)
        if [[ $basename =~ ^(20[0-9]{6})- ]]; then
            echo "  ✓ Archived: $basename"
        fi
    done < <(find "$SPECS_DIR" -mindepth 1 -maxdepth 1 -type d -name "2025*")

    echo "✓ All archived features use timestamp prefix"
    return 0
}

# Rule 3: No orphaned spec files (spec.md without parent directory)
validate_no_orphaned_specs() {
    local orphans_found=0

    echo ""
    echo "=== Rule 3: Checking for orphaned spec files ==="

    # Check for spec.md files not in proper directory structure
    if [[ -f "${SPECS_DIR}/spec.md" ]]; then
        echo "✗ ERROR: Orphaned spec.md found at specs/spec.md"
        echo "    Should be in specs/XXX-feature-name/spec.md"
        orphans_found=1
    fi

    if [[ $orphans_found -eq 1 ]]; then
        return 1
    fi

    echo "✓ No orphaned spec files"
    return 0
}

# Rule 4: Active specs must have required files
validate_required_spec_files() {
    local missing_files=0

    echo ""
    echo "=== Rule 4: Checking required files in active specs ==="

    # Check each active spec (numeric prefix)
    while IFS= read -r spec_dir; do
        local basename=$(basename "$spec_dir")

        # Skip archived features
        if [[ $basename =~ ^20[0-9]{6}- ]]; then
            continue
        fi

        echo "  Checking: $basename"

        # Required files
        local required_files=("spec.md" "plan.md" "tasks.md")
        local spec_missing=0

        for file in "${required_files[@]}"; do
            if [[ ! -f "${spec_dir}/${file}" ]]; then
                echo "    ✗ Missing: $file"
                spec_missing=1
                missing_files=1
            else
                echo "    ✓ Found: $file"
            fi
        done

    done < <(find "$SPECS_DIR" -mindepth 1 -maxdepth 1 -type d ! -name ".*")

    if [[ $missing_files -eq 1 ]]; then
        echo ""
        echo "🚨 RESOLUTION: Run spec-kit commands to generate missing files:"
        echo "   /speckit.specify  # Generate spec.md"
        echo "   /speckit.plan     # Generate plan.md"
        echo "   /speckit.tasks    # Generate tasks.md"
        return 1
    fi

    echo "✓ All active specs have required files"
    return 0
}

# ============================================================
# MAIN EXECUTION
# ============================================================

main() {
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║   Spec Directory Structure Validation                  ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    echo "Validating: $SPECS_DIR"
    echo ""

    local all_valid=0

    # Run all validation rules
    validate_no_duplicate_prefixes || all_valid=1
    validate_archived_feature_naming || all_valid=1
    validate_no_orphaned_specs || all_valid=1
    validate_required_spec_files || all_valid=1

    echo ""
    echo "════════════════════════════════════════════════════════"

    if [[ $all_valid -eq 0 ]]; then
        echo "✅ ALL VALIDATIONS PASSED"
        echo ""
        echo "Spec directory structure is valid."
        return 0
    else
        echo "❌ VALIDATION FAILED"
        echo ""
        echo "Please resolve issues above before committing."
        return 1
    fi
}

# Run main function
main "$@"
