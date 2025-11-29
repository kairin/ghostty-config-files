#!/usr/bin/env bash
#
# scripts/vhs/auto-record.sh - Automatic VHS recording wrapper
#
# Purpose: Automatically record ./start.sh installation with VHS
# Creates professional demo GIFs for documentation
#
# Usage:
#   ./scripts/vhs/auto-record.sh [output-name]
#
# Example:
#   ./scripts/vhs/auto-record.sh installation
#   # Creates: documentation/demos/installation-TIMESTAMP.gif
#

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OUTPUT_DIR="${REPO_ROOT}/documentation/demos"
OUTPUT_NAME="${1:-installation}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_FILE="${OUTPUT_DIR}/${OUTPUT_NAME}-${TIMESTAMP}.gif"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Check if VHS is available
if ! command -v vhs >/dev/null 2>&1; then
    echo "ERROR: VHS not installed"
    echo "Install with: sudo apt install vhs"
    echo "Or see: https://github.com/charmbracelet/vhs"
    exit 1
fi

# Create temporary VHS tape file
TAPE_FILE="/tmp/vhs-auto-record-${TIMESTAMP}.tape"

cat > "$TAPE_FILE" <<'EOF'
# Auto-generated VHS Recording
# Captures installation process for documentation

# Video settings
Output ${OUTPUT_FILE}
Set Shell "bash"
Set FontSize 14
Set Width 1400
Set Height 900
Set TypingSpeed 50ms
Set Theme "Catppuccin Mocha"
Set PlaybackSpeed 1.5

# Title
Type "# Ghostty Configuration Files - Installation"
Enter
Sleep 500ms
Type "# Automated terminal environment setup with 2025 optimizations"
Enter
Sleep 1s
Enter

# Start installation
Type "./start.sh"
Sleep 300ms
Enter

# Wait for pre-installation audit (10s)
Sleep 10s

# Auto-confirm installation (simulate 'y' press)
Type "y"
Enter

# Let installation run (adjust time based on your system)
# Typical install: 2-3 minutes
Sleep 180s

# Show completion
Sleep 3s

# Show version verification
Type "ghostty --version"
Enter
Sleep 2s

Type "gum --version"
Enter
Sleep 2s

# Credits
Enter
Type "# Demo recorded with VHS (Charm Bracelet)"
Enter
Sleep 2s
EOF

# Replace ${OUTPUT_FILE} placeholder
sed -i "s|\${OUTPUT_FILE}|${OUTPUT_FILE}|g" "$TAPE_FILE"

echo "Starting VHS recording..."
echo "Output: $OUTPUT_FILE"
echo "Tape file: $TAPE_FILE"
echo ""
echo "This will take approximately 3-5 minutes..."
echo ""

# Run VHS recording
vhs "$TAPE_FILE"

# Check if recording was successful
if [ -f "$OUTPUT_FILE" ]; then
    echo ""
    echo "SUCCESS: Recording saved to $OUTPUT_FILE"
    echo ""
    echo "File size: $(du -h "$OUTPUT_FILE" | cut -f1)"
    echo ""
    echo "View with:"
    echo "  firefox \"$OUTPUT_FILE\""
    echo "  google-chrome \"$OUTPUT_FILE\""
    echo ""

    # Cleanup temp tape file
    rm -f "$TAPE_FILE"

    exit 0
else
    echo ""
    echo "ERROR: Recording failed"
    echo "Tape file preserved at: $TAPE_FILE"
    echo ""
    exit 1
fi
