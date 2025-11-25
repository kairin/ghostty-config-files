#!/usr/bin/env bash
#
# Constitutional Compliance Test: Script Line Limits
#
# Purpose: Validate that no scripts exceed the 300-line modularity limit
# Enforcement: MANDATORY - Constitutional Principle
# Exception: Test files in tests/ directory
#

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

echo "════════════════════════════════════════"
echo "Constitutional Check: Script Line Limits"
echo "════════════════════════════════════════"
echo ""

# Counter for violations
VIOLATIONS=0
VIOLATION_FILES=()

# Find all .sh files excluding tests and .git
while IFS= read -r file; do
    # Skip test files (exempt from limit)
    if [[ "$file" == tests/* ]] || [[ "$file" == *"test_"* ]] || [[ "$file" == *"_test.sh" ]]; then
        continue
    fi
    
    # Count lines
    lines=$(wc -l < "$file" 2>/dev/null || echo "0")
    
    # Check against limit
    if [ "$lines" -gt 300 ]; then
        echo "❌ VIOLATION: $file"
        echo "   Lines: $lines (limit: 300, excess: $((lines - 300)))"
        echo ""
        VIOLATIONS=$((VIOLATIONS + 1))
        VIOLATION_FILES+=("$file:$lines")
    fi
done < <(find . -name "*.sh" -type f -not -path "*/.git/*" 2>/dev/null)

echo "════════════════════════════════════════"
echo "Summary"
echo "════════════════════════════════════════"
echo "Total violations: $VIOLATIONS"
echo ""

if [ "$VIOLATIONS" -eq 0 ]; then
    echo "✅ PASS: All scripts comply with 300-line limit"
    echo ""
    echo "📊 This project maintains excellent modularity!"
    exit 0
else
    echo "⚠️  FAIL: $VIOLATIONS scripts exceed 300-line limit"
    echo ""
    echo "📋 Violations Details:"
    for violation in "${VIOLATION_FILES[@]}"; do
        file="${violation%:*}"
        lines="${violation#*:}"
        echo "  - $file ($lines lines)"
    done
    echo ""
    echo "🔧 Action Required:"
    echo "  1. Review violations catalog: violations-catalog.md"
    echo "  2. Apply refactoring strategies from modularity-limits.md"
    echo "  3. See: .claude/instructions-for-agents/principles/modularity-limits.md"
    echo ""
    
    # Note: Return 0 (success) during grace period for existing violations
    # Change to 'exit 1' after all violations are fixed to enforce limit
    echo "⏰ GRACE PERIOD: Existing violations cataloged, not failing build"
    echo "   After refactoring, change this script to 'exit 1' for enforcement"
    exit 0  # Change to: exit 1
fi
