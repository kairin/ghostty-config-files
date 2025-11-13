#!/bin/bash

# Test suite for box rendering with ANSI color codes
# Purpose: Verify that all box drawing functions handle ANSI color codes correctly
# without misaligning borders after the fixes applied to start.sh

set -euo pipefail

# Source the main script to get box drawing functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# We need to source start.sh but prevent it from executing
# Extract only the box drawing functions
# Alternatively, we'll define them here directly to avoid side effects

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Box drawing functions (copied from start.sh with fixes)
draw_box() {
    local title="$1"
    shift
    local lines=("$@")

    # Calculate max width (accounting for ANSI color codes)
    local max_width=0
    local visible_length
    for line in "${lines[@]}"; do
        # Remove ANSI color codes to get visible length
        local stripped=$(echo -e "$line" | sed 's/\x1b\[[0-9;]*m//g')
        visible_length=${#stripped}
        if [ "$visible_length" -gt "$max_width" ]; then
            max_width=$visible_length
        fi
    done

    # Ensure title fits
    local title_length=${#title}
    if [ "$title_length" -gt "$((max_width - 2))" ]; then
        max_width=$((title_length + 2))
    fi

    # Top border with title
    local border_width=$((max_width + 2))
    echo -n "╔"
    printf '═%.0s' $(seq 1 $border_width)
    echo "╗"

    # Title line
    local title_padding=$(( (max_width - title_length) / 2 ))
    echo -n "║ "
    printf ' %.0s' $(seq 1 $title_padding)
    echo -n "$title"
    printf ' %.0s' $(seq 1 $((max_width - title_length - title_padding)))
    echo " ║"

    # Separator
    echo -n "╠"
    printf '═%.0s' $(seq 1 $border_width)
    echo "╣"

    # Content lines
    for line in "${lines[@]}"; do
        # Calculate visible length (without ANSI codes)
        local stripped=$(echo -e "$line" | sed 's/\x1b\[[0-9;]*m//g')
        visible_length=${#stripped}
        local padding=$((max_width - visible_length))

        echo -n "║ "
        echo -ne "$line"
        printf ' %.0s' $(seq 1 $padding)
        echo " ║"
    done

    # Bottom border
    echo -n "╚"
    printf '═%.0s' $(seq 1 $border_width)
    echo "╝"
}

draw_colored_box() {
    local border_color="$1"
    local title="$2"
    shift 2
    local lines=("$@")

    # Calculate max width (accounting for ANSI color codes)
    local max_width=0
    local visible_length
    for line in "${lines[@]}"; do
        # Remove ANSI color codes to get visible length
        local stripped=$(echo -e "$line" | sed 's/\x1b\[[0-9;]*m//g')
        visible_length=${#stripped}
        if [ "$visible_length" -gt "$max_width" ]; then
            max_width=$visible_length
        fi
    done

    # Ensure title fits
    local title_length=${#title}
    if [ "$title_length" -gt "$((max_width - 2))" ]; then
        max_width=$((title_length + 2))
    fi

    # Top border with title
    local border_width=$((max_width + 2))
    echo -ne "${border_color}╔"
    printf '═%.0s' $(seq 1 $border_width)
    echo -e "╗${NC}"

    # Title line
    local title_padding=$(( (max_width - title_length) / 2 ))
    echo -ne "${border_color}║${NC} "
    printf ' %.0s' $(seq 1 $title_padding)
    echo -n "$title"
    printf ' %.0s' $(seq 1 $((max_width - title_length - title_padding)))
    echo -e " ${border_color}║${NC}"

    # Separator
    echo -ne "${border_color}╠"
    printf '═%.0s' $(seq 1 $border_width)
    echo -e "╣${NC}"

    # Content lines
    for line in "${lines[@]}"; do
        # Calculate visible length (without ANSI codes)
        local stripped=$(echo -e "$line" | sed 's/\x1b\[[0-9;]*m//g')
        visible_length=${#stripped}
        local padding=$((max_width - visible_length))

        echo -ne "${border_color}║${NC} "
        echo -ne "$line"
        printf ' %.0s' $(seq 1 $padding)
        echo -e " ${border_color}║${NC}"
    done

    # Bottom border
    echo -ne "${border_color}╚"
    printf '═%.0s' $(seq 1 $border_width)
    echo -e "╝${NC}"
}

# Test counter
TEST_NUM=0

# Function to draw a simple header box
draw_header() {
    local title="$1"
    local color="${2:-$GREEN}"

    # Strip ANSI codes for width calculation
    local clean_title=$(echo -e "$title" | sed 's/\x1b\[[0-9;]*m//g')
    local title_width=${#clean_title}

    # Add padding (4 spaces each side)
    local content_width=$title_width
    local inner_width=$((title_width + 8))

    # Draw top border
    printf "${color}╔"
    printf '═%.0s' $(seq 1 $inner_width)
    printf "╗${NC}\n"

    # Draw title
    printf "${color}║${NC}    %-${content_width}s    ${color}║${NC}\n" "$title"

    # Draw bottom border
    printf "${color}╚"
    printf '═%.0s' $(seq 1 $inner_width)
    printf "╝${NC}\n"
}

# Function to show test header
show_test() {
    TEST_NUM=$((TEST_NUM + 1))
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}TEST $TEST_NUM: $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Main test suite
draw_header "BOX COLOR RENDERING - TEST SUITE" "$GREEN"

# Test 1: draw_box with colored content
show_test "draw_box() with colored status messages"
draw_box "Installation Status" \
    "$(echo -e "${GREEN}✅ ZSH 5.9 installed${NC}")" \
    "$(echo -e "${GREEN}✅ Node.js v25.2.0 active${NC}")" \
    "$(echo -e "${YELLOW}⚠️  Some warnings detected${NC}")" \
    "$(echo -e "${GREEN}✅ Installation complete${NC}")"

# Test 2: draw_colored_box with GREEN border and colored content
show_test "draw_colored_box() with GREEN border and multi-color content"
draw_colored_box "$GREEN" "Build Status" \
    "$(echo -e "${GREEN}✅ Configuration valid${NC}")" \
    "$(echo -e "${GREEN}✅ Tests passed (142/142)${NC}")" \
    "$(echo -e "${YELLOW}⚠️  3 warnings (non-critical)${NC}")" \
    "$(echo -e "${GREEN}✅ Build successful${NC}")"

# Test 3: draw_colored_box with MAGENTA border
show_test "draw_colored_box() with MAGENTA border (Terminal tools)"
draw_colored_box "$MAGENTA" "Ghostty Installation" \
    "$(echo -e "${GREEN}✅ Ghostty v1.2.3 detected${NC}")" \
    "$(echo -e "${CYAN}🔧 Updating configuration files${NC}")" \
    "$(echo -e "${GREEN}✅ 2025 optimizations applied${NC}")" \
    "$(echo -e "${GREEN}✅ Context menu integrated${NC}")"

# Test 4: draw_colored_box with BLUE border
show_test "draw_colored_box() with BLUE border (Shell tools)"
draw_colored_box "$BLUE" "ZSH Setup Complete" \
    "$(echo -e "${GREEN}✅ ZSH 5.9 installed and configured${NC}")" \
    "$(echo -e "${GREEN}✅ Oh My ZSH framework installed${NC}")" \
    "$(echo -e "${GREEN}✅ Essential plugins: autosuggestions, syntax-highlighting${NC}")" \
    "$(echo -e "${GREEN}✅ Powerlevel10k theme configured${NC}")"

# Test 5: Long colored content (edge case)
show_test "Long content with multiple color changes"
draw_box "Complex Status" \
    "$(echo -e "${GREEN}✅ Success${NC} | ${YELLOW}⚠️  Warning${NC} | ${RED}❌ Error${NC} | ${BLUE}ℹ️  Info${NC}")" \
    "$(echo -e "This line has ${GREEN}green${NC}, ${YELLOW}yellow${NC}, ${RED}red${NC}, and ${BLUE}blue${NC} colors")" \
    "$(echo -e "Testing: ${GREEN}Success${NC} ${YELLOW}Warning${NC} ${RED}Failure${NC} all in one line")"

# Test 6: Emoji with colors
show_test "Emoji combined with color codes"
draw_colored_box "$CYAN" "🎉 Daily Update Summary 📊" \
    "$(echo -e "${GREEN}✅ System packages updated (123 packages)${NC}")" \
    "$(echo -e "${GREEN}✅ Oh My Zsh updated to latest version${NC}")" \
    "$(echo -e "${GREEN}✅ npm updated to v11.0.0${NC}")" \
    "$(echo -e "${GREEN}✅ Claude CLI updated to @latest${NC}")" \
    "$(echo -e "${CYAN}⏱️  Total time: 2m 34s${NC}")"

# Test 7: Mixed length colored content
show_test "Mixed length content with colors (alignment test)"
draw_box "Installation Progress" \
    "$(echo -e "${GREEN}✅ Short${NC}")" \
    "$(echo -e "${GREEN}✅ Medium length line here${NC}")" \
    "$(echo -e "${GREEN}✅ This is a much longer line with multiple words and content${NC}")" \
    "$(echo -e "${YELLOW}⚠️  Warning message${NC}")" \
    "$(echo -e "${GREEN}✅ Back to short${NC}")"

# Test 8: All borders with YELLOW
show_test "draw_colored_box() with YELLOW border (System tools)"
SEGMENT_SYSTEM='\033[1;33m'
draw_colored_box "$SEGMENT_SYSTEM" "System Dependencies" \
    "$(echo -e "${GREEN}✅ apt packages up to date${NC}")" \
    "$(echo -e "${GREEN}✅ Build tools configured${NC}")" \
    "$(echo -e "${GREEN}✅ All 42 packages installed${NC}")"

# Test 9: Plain text (no colors) for comparison
show_test "Plain text (no color codes) - baseline"
draw_box "Plain Text Status" \
    "No color codes in this line" \
    "Another plain line" \
    "Third line without colors"

# Test 10: Edge case - empty lines with colors
show_test "Empty and whitespace with color codes"
draw_box "Edge Cases" \
    "$(echo -e "${GREEN}✅ Normal line${NC}")" \
    "$(echo -e "")" \
    "$(echo -e "${GREEN}✅ After empty${NC}")" \
    "$(echo -e "    ${GREEN}✅ Indented line${NC}")"

# Test 11: Very long lines with colors (stress test)
show_test "Very long lines with multiple colors (stress test)"
draw_colored_box "$RED" "Stress Test - Long Content" \
    "$(echo -e "${GREEN}✅ This is an extremely long line with multiple color codes ${YELLOW}embedded throughout${NC} ${CYAN}the entire${NC} ${MAGENTA}content${NC} ${GREEN}to test width calculation${NC}")" \
    "$(echo -e "${BLUE}Short${NC}")" \
    "$(echo -e "${GREEN}✅ Another very long line that should properly calculate the visible width despite having ${RED}many${NC} ${YELLOW}different${NC} ${CYAN}color${NC} ${MAGENTA}codes${NC} ${GREEN}embedded${NC}")"

# Test 12: Color codes at boundaries
show_test "Color codes at line boundaries (edge case)"
draw_box "Boundary Test" \
    "$(echo -e "${GREEN}Start with color")" \
    "$(echo -e "End with color${NC}")" \
    "$(echo -e "${GREEN}Both ends${NC}")" \
    "$(echo -e "${GREEN}${YELLOW}${RED}Multiple at start${NC}")"

# Test 13: Nested color codes (malformed)
show_test "Nested/Malformed color codes handling"
draw_colored_box "$YELLOW" "Robustness Test" \
    "$(echo -e "${GREEN}Normal ${GREEN}double green${NC}")" \
    "$(echo -e "${GREEN}Unclosed color")" \
    "$(echo -e "Multiple resets${NC}${NC}${NC}")"

# Test 14: Special characters with colors
show_test "Special characters combined with colors"
draw_box "Special Characters + Colors" \
    "$(echo -e "${GREEN}✅ Checkmark: ✓ ✔ ✅${NC}")" \
    "$(echo -e "${YELLOW}⚠️  Warning: ⚠ ⚡ ⚙${NC}")" \
    "$(echo -e "${RED}❌ Error: ✗ ✘ ❌${NC}")" \
    "$(echo -e "${BLUE}ℹ️  Info: ℹ ⓘ 🛈${NC}")" \
    "$(echo -e "${CYAN}🔧 Wrench • Gear ⚙ • Settings ⚙️${NC}")"

# Test 15: All segment colors (from start.sh)
show_test "All segment colors from start.sh configuration"
SEGMENT_TERMINAL='\033[0;35m'
SEGMENT_SHELL='\033[0;34m'
SEGMENT_SYSTEM='\033[1;33m'
SEGMENT_NODE='\033[0;32m'
SEGMENT_AI='\033[0;36m'

draw_colored_box "$SEGMENT_TERMINAL" "Terminal Tools (Magenta)" \
    "$(echo -e "${GREEN}✅ Ghostty configured${NC}")"

draw_colored_box "$SEGMENT_SHELL" "Shell Tools (Blue)" \
    "$(echo -e "${GREEN}✅ ZSH configured${NC}")"

draw_colored_box "$SEGMENT_SYSTEM" "System Dependencies (Yellow)" \
    "$(echo -e "${GREEN}✅ System packages installed${NC}")"

draw_colored_box "$SEGMENT_NODE" "Node.js Environment (Green)" \
    "$(echo -e "${GREEN}✅ Node.js v25.2.0${NC}")"

draw_colored_box "$SEGMENT_AI" "AI Tools (Cyan)" \
    "$(echo -e "${GREEN}✅ Claude CLI installed${NC}")"

# Summary
echo ""
draw_header "ALL TESTS COMPLETE" "$GREEN"
echo ""
echo -e "${CYAN}Visual Inspection Checklist:${NC}"
echo "  1. ✓ All right borders (║) should be perfectly aligned"
echo "  2. ✓ Color codes should not cause width miscalculation"
echo "  3. ✓ Emoji should not break box alignment"
echo "  4. ✓ Mixed-length content should pad correctly"
echo "  5. ✓ Border colors should match the specified segment color"
echo "  6. ✓ Empty lines should render correctly"
echo "  7. ✓ Special characters should not affect alignment"
echo "  8. ✓ Very long lines should calculate width correctly"
echo ""
echo -e "${YELLOW}⚠️  If any right borders appear misaligned, the color code"
echo -e "    width calculation needs further adjustment.${NC}"
echo ""
echo -e "${CYAN}📝 Tested Functions:${NC}"
echo "    • draw_box() - 8 tests with various color combinations"
echo "    • draw_colored_box() - 7 tests with all segment colors"
echo "    • Edge cases - Empty lines, nested colors, special chars"
echo "    • Stress tests - Very long lines with multiple colors"
echo ""
echo -e "${GREEN}✅ Test suite execution complete!${NC}"
echo ""
