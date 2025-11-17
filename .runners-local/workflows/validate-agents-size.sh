#!/bin/bash
# Validate AGENTS.md size against constitutional limits

set -e

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
AGENTS_FILE="$REPO_ROOT/AGENTS.md"

echo "Validating AGENTS.md size..."
echo ""

if [ ! -f "$AGENTS_FILE" ]; then
    echo "ERROR: AGENTS.md not found"
    exit 1
fi

# Get file size
AGENTS_SIZE=$(stat -c%s "$AGENTS_FILE" 2>/dev/null || stat -f%z "$AGENTS_FILE")
AGENTS_KB=$((AGENTS_SIZE / 1024))

# Calculate percentage of limit
LIMIT_KB=40
PERCENTAGE=$((AGENTS_KB * 100 / LIMIT_KB))

echo "AGENTS.md Current Size: ${AGENTS_KB}KB"
echo "Constitutional Limit: ${LIMIT_KB}KB"
echo "Percentage of Limit: ${PERCENTAGE}%"
echo ""

# Determine zone and recommendations
if [ $AGENTS_KB -gt 40 ]; then
    echo "🚨 RED ZONE: Size violation (${AGENTS_KB}KB > 40KB)"
    echo "Status: CRITICAL - BLOCKING COMMIT"
    echo ""
    echo "Action Required:"
    echo "  1. Emergency modularization required"
    echo "  2. Identify largest sections:"
    echo "     grep -n '^##' AGENTS.md"
    echo "  3. Extract to separate files in documentations/"
    echo "  4. Update AGENTS.md with summaries and links"
    echo ""
    exit 1
elif [ $AGENTS_KB -gt 35 ]; then
    echo "🟧 ORANGE ZONE: Critical size (${AGENTS_KB}KB)"
    echo "Status: WARNING - Approaching limit"
    echo ""
    echo "Action Recommended:"
    echo "  1. Proactive modularization recommended"
    echo "  2. Review sections for extraction:"
    echo "     grep -n '^##' AGENTS.md"
    echo "  3. Plan modularization before next major update"
    echo ""
    exit 0
elif [ $AGENTS_KB -gt 30 ]; then
    echo "🟨 YELLOW ZONE: Warning size (${AGENTS_KB}KB)"
    echo "Status: CAUTION - Monitor closely"
    echo ""
    echo "Recommendation:"
    echo "  - Monitor size growth"
    echo "  - Consider proactive modularization"
    echo "  - Review content for optimization opportunities"
    echo ""
    exit 0
else
    echo "🟩 GREEN ZONE: Size compliant (${AGENTS_KB}KB)"
    echo "Status: EXCELLENT - Well within limits"
    echo ""
    echo "No action required."
    echo ""
    exit 0
fi
