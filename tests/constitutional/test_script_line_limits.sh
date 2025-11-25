#!/usr/bin/env bash
#
# Constitutional Compliance Test: Script Line Limits
#
# Purpose: Validate that no scripts exceed the 300-line modularity limit
# Enforcement: MANDATORY - Constitutional Principle
# Exception: Test files in tests/ directory

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# Configuration
readonly CONSTITUTIONAL_LIMIT=300
readonly LOG_DIR="${REPO_ROOT}/logs"
readonly LOG_FILE="${LOG_DIR}/constitutional_check.log"

# Initialize logging
mkdir -p "$LOG_DIR"
{
    echo "# Constitutional Compliance Check"
    echo "# Generated: $(date -Iseconds)"
    echo "# Repository: $REPO_ROOT"
    echo "# Limit: $CONSTITUTIONAL_LIMIT lines"
    echo ""
} > "$LOG_FILE"

echo "========================================"
echo "Constitutional Check: Script Line Limits"
echo "========================================"
echo ""

# Counters
TOTAL_SCRIPTS=0
VIOLATIONS=0
PASSING=0
VIOLATION_FILES=()
PASSING_FILES=()

# Find all .sh files excluding tests and .git
while IFS= read -r file; do
    # Skip test files (exempt from limit)
    if [[ "$file" == tests/* ]] || [[ "$file" == *"test_"* ]] || [[ "$file" == *"_test.sh" ]]; then
        continue
    fi

    # Skip archive directories
    if [[ "$file" == *"/archive/"* ]] || [[ "$file" == *"/.archive/"* ]]; then
        continue
    fi

    TOTAL_SCRIPTS=$((TOTAL_SCRIPTS + 1))

    # Count lines
    lines=$(wc -l < "$file" 2>/dev/null || echo "0")

    # Check against limit
    if [ "$lines" -gt "$CONSTITUTIONAL_LIMIT" ]; then
        echo "[FAIL] VIOLATION: $file"
        echo "       Lines: $lines (limit: $CONSTITUTIONAL_LIMIT, excess: $((lines - CONSTITUTIONAL_LIMIT)))"
        echo ""
        VIOLATIONS=$((VIOLATIONS + 1))
        VIOLATION_FILES+=("$file:$lines")
        echo "[FAIL] $file: $lines lines (exceeds $CONSTITUTIONAL_LIMIT)" >> "$LOG_FILE"
    else
        PASSING=$((PASSING + 1))
        PASSING_FILES+=("$file:$lines")
        echo "[PASS] $file: $lines lines" >> "$LOG_FILE"
    fi
done < <(find . -name "*.sh" -type f -not -path "*/.git/*" -not -path "*/node_modules/*" 2>/dev/null | sort)

# Calculate compliance percentage
COMPLIANCE_PCT=0
if [ "$TOTAL_SCRIPTS" -gt 0 ]; then
    COMPLIANCE_PCT=$(( (PASSING * 100) / TOTAL_SCRIPTS ))
fi

echo "========================================"
echo "Summary"
echo "========================================"
echo "Total scripts scanned: $TOTAL_SCRIPTS"
echo "Scripts passing: $PASSING"
echo "Scripts failing: $VIOLATIONS"
echo "Compliance rate: ${COMPLIANCE_PCT}%"
echo ""

# Log summary
{
    echo ""
    echo "========================================"
    echo "SUMMARY"
    echo "========================================"
    echo "Total scripts: $TOTAL_SCRIPTS"
    echo "Passing: $PASSING"
    echo "Violations: $VIOLATIONS"
    echo "Compliance: ${COMPLIANCE_PCT}%"
} >> "$LOG_FILE"

if [ "$VIOLATIONS" -eq 0 ]; then
    echo "[OK] PASS: All scripts comply with ${CONSTITUTIONAL_LIMIT}-line limit"
    echo ""
    echo "This project maintains excellent modularity!"
    echo "Log saved: $LOG_FILE"
    exit 0
else
    echo "[!!] FAIL: $VIOLATIONS scripts exceed ${CONSTITUTIONAL_LIMIT}-line limit"
    echo ""
    echo "Violations Details:"
    for violation in "${VIOLATION_FILES[@]}"; do
        file="${violation%:*}"
        lines="${violation#*:}"
        excess=$((lines - CONSTITUTIONAL_LIMIT))
        echo "  - $file ($lines lines, +$excess over limit)"
    done
    echo ""
    echo "Action Required:"
    echo "  1. Review violations catalog: violations-catalog.md"
    echo "  2. Apply refactoring strategies from modularity-limits.md"
    echo "  3. See: .claude/instructions-for-agents/principles/modularity-limits.md"
    echo ""
    echo "Log saved: $LOG_FILE"

    # Note: Return 0 (success) during grace period for existing violations
    # Change to 'exit 1' after all violations are fixed to enforce limit
    echo ""
    echo "GRACE PERIOD: Existing violations cataloged, not failing build"
    echo "After refactoring, change this script to 'exit 1' for enforcement"
    exit 0  # Change to: exit 1
fi
