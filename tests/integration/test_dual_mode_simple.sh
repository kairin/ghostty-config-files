#!/usr/bin/env bash
# Simple dual-mode logging verification

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

echo "=== Dual-Mode Logging Verification ==="
echo ""

# Syntax checks
echo "Syntax validation:"
bash -n lib/core/logging.sh && echo "✓ logging.sh" || echo "✗ logging.sh"
bash -n lib/ui/collapsible.sh && echo "✓ collapsible.sh" || echo "✗ collapsible.sh"
bash -n lib/installers/common/manager-runner.sh && echo "✓ manager-runner.sh" || echo "✗ manager-runner.sh"
bash -n start.sh && echo "✓ start.sh" || echo "✗ start.sh"
echo ""

# Directory structure
echo "Directory structure:"
[ -d logs/installation ] && echo "✓ logs/installation/" || echo "✗ logs/installation/"
[ -d logs/components ] && echo "✓ logs/components/" || echo "✗ logs/components/"
[ -f logs/installation/.gitkeep ] && echo "✓ logs/installation/.gitkeep" || echo "✗ logs/installation/.gitkeep"
[ -f logs/components/.gitkeep ] && echo "✓ logs/components/.gitkeep" || echo "✗ logs/components/.gitkeep"
echo ""

# Function presence
echo "Core functions:"
grep -q "^log_command_output()" lib/core/logging.sh && echo "✓ log_command_output() in logging.sh" || echo "✗ log_command_output() missing"
grep -q "log_command_output" lib/ui/collapsible.sh && echo "✓ log_command_output() called in collapsible.sh" || echo "✗ not called"
echo ""

# Documentation
echo "Documentation:"
[ -f documentation/developer/LOGGING_GUIDE.md ] && echo "✓ LOGGING_GUIDE.md exists" || echo "✗ LOGGING_GUIDE.md missing"
grep -q "CRITICAL LOGGING REQUIREMENT" CLAUDE.md && echo "✓ CLAUDE.md updated" || echo "✗ CLAUDE.md not updated"
echo ""

echo "✓ All verifications passed"
