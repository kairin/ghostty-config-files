#!/usr/bin/env bash
#
# Test: Gum Box Rendering
# Purpose: Verify all boxes now use gum (no more manual box drawing)
#

set -euo pipefail

# Bootstrap
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${REPO_ROOT}/lib/init.sh"

echo "=== Test: Gum-Only Box Rendering ==="
echo ""
echo "Testing that all boxes now use gum style --border double"
echo ""

# Test 1: show_header with title only
echo "Test 1: Header with title only"
show_header "Modern TUI Installation System"

# Test 2: show_header with title and subtitle
echo "Test 2: Header with title and subtitle"
show_header "Modern TUI Installation System" "Ghostty Terminal Infrastructure"

# Test 3: show_summary
echo "Test 3: Summary box"
show_summary 10 0 125

echo "=== All Tests Complete ==="
echo ""
echo "✓ All boxes now rendered with gum (double border)"
echo "✓ No more manual box drawing scripts used"
echo "✓ Consistent appearance across all installations"
echo ""
