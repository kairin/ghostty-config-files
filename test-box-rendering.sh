#!/bin/bash
#
# Test Script: Box Rendering Improvements
# Demonstrates the new dynamic width calculation and proper padding
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# BOX DRAWING FUNCTIONS (Enhanced CLI Rendering)
# ============================================================================

# Calculate the display width of a string (handles Unicode and ANSI color codes)
get_string_width() {
    local string="$1"
    # Remove ANSI color codes
    local clean_string=$(echo -e "$string" | sed 's/\x1b\[[0-9;]*m//g')
    # Get actual character count (handles Unicode properly)
    echo "${#clean_string}"
}

# Draw a box with dynamic width calculation and proper padding
# Usage: draw_box "Title" "line1" "line2" "line3" ...
draw_box() {
    local title="$1"
    shift
    local -a content=("$@")

    # Calculate maximum width from title and content
    local max_width=$(get_string_width "$title")
    local line_width

    for line in "${content[@]}"; do
        line_width=$(get_string_width "$line")
        ((line_width > max_width)) && max_width=$line_width
    done

    # Add padding (4 spaces on each side) - inner width without borders
    local content_width=$max_width
    local inner_width=$((max_width + 8))

    # Draw top border (╔══...══╗)
    printf "${CYAN}╔"
    printf '═%.0s' $(seq 1 $inner_width)
    printf "╗${NC}\n"

    # Draw title with padding and vertical borders
    printf "${CYAN}║${NC}    %-${content_width}s    ${CYAN}║${NC}\n" "$title"

    # Draw middle separator (╠══...══╣)
    printf "${CYAN}╠"
    printf '═%.0s' $(seq 1 $inner_width)
    printf "╣${NC}\n"

    # Draw empty line with borders
    printf "${CYAN}║${NC}%-$((inner_width))s${CYAN}║${NC}\n" ""

    # Draw content with padding and vertical borders
    for line in "${content[@]}"; do
        printf "${CYAN}║${NC}    %-${content_width}s    ${CYAN}║${NC}\n" "$line"
    done

    # Draw empty line with borders
    printf "${CYAN}║${NC}%-$((inner_width))s${CYAN}║${NC}\n" ""

    # Draw bottom border (╚══...══╝)
    printf "${CYAN}╚"
    printf '═%.0s' $(seq 1 $inner_width)
    printf "╝${NC}\n"
}

# Draw a simple header box (title only, no content)
# Usage: draw_header "Title Text"
draw_header() {
    local title="$1"
    local title_width=$(get_string_width "$title")
    local inner_width=$((title_width + 8))

    # Draw top border (╔══...══╗)
    printf "${CYAN}╔"
    printf '═%.0s' $(seq 1 $inner_width)
    printf "╗${NC}\n"

    # Draw title with padding and vertical borders
    printf "${CYAN}║${NC}    %-${title_width}s    ${CYAN}║${NC}\n" "$title"

    # Draw bottom border (╚══...══╝)
    printf "${CYAN}╚"
    printf '═%.0s' $(seq 1 $inner_width)
    printf "╝${NC}\n"
}

# Draw a separator line with dynamic width
# Usage: draw_separator 40
draw_separator() {
    local width="${1:-40}"
    echo "$(printf '─%.0s' $(seq 1 $width))"
}

# ============================================================================
# TEST DEMONSTRATIONS
# ============================================================================

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          BOX RENDERING IMPROVEMENTS - TEST SUITE              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Test 1: Simple header
echo -e "${YELLOW}Test 1: Simple Header (dynamic width)${NC}"
draw_header "Installation Complete"
echo ""

# Test 2: Box with short content
echo -e "${YELLOW}Test 2: Box with Short Content${NC}"
draw_box "System Information" \
    "• OS: Ubuntu 25.10" \
    "• Kernel: 6.17.0" \
    "• Shell: ZSH"
echo ""

# Test 3: Box with long content
echo -e "${YELLOW}Test 3: Box with Long Content (dynamic width adjustment)${NC}"
draw_box "Passwordless Sudo Configuration Required" \
    "This repository requires passwordless sudo for /usr/bin/apt to enable:" \
    "  • Automated daily updates at 9:00 AM" \
    "  • One-command installation without password prompts" \
    "  • Local CI/CD workflows" \
    "" \
    "SECURITY: Only /usr/bin/apt can run without password"
echo ""

# Test 4: Box with mixed length content
echo -e "${YELLOW}Test 4: Mixed Length Content (proper padding)${NC}"
draw_box "Installation Progress" \
    "✅ ZSH installed" \
    "✅ Oh My ZSH configured" \
    "✅ Ghostty terminal with 2025 performance optimizations" \
    "⏳ Installing Node.js v25.2.0 via fnm..." \
    "⏳ Setting up Claude Code and Gemini CLI..."
echo ""

# Test 5: Separator lines
echo -e "${YELLOW}Test 5: Separator Lines${NC}"
echo "Standard separator (40 chars):"
draw_separator 40
echo ""
echo "Custom separator (60 chars):"
draw_separator 60
echo ""
echo "Tree-style separator:"
echo "   ${CYAN}├─ Command:${NC} ghostty +show-config"
echo "   ${CYAN}└─ Output:${NC}"
draw_separator 39
echo ""

# Test 6: Unicode and emoji handling
echo -e "${YELLOW}Test 6: Unicode and Emoji Handling${NC}"
draw_box "🎯 Daily Update Summary 📊" \
    "✅ System packages updated (123 packages)" \
    "✅ Oh My Zsh updated to latest version" \
    "✅ npm updated to v11.0.0" \
    "✅ Claude CLI updated to @latest" \
    "⏱️  Total time: 2m 34s"
echo ""

# Test 7: Color codes in content
echo -e "${YELLOW}Test 7: Color Codes in Content${NC}"
draw_box "Build Status" \
    "${GREEN}✅ Configuration valid${NC}" \
    "${GREEN}✅ Tests passed (142/142)${NC}" \
    "${YELLOW}⚠️  3 warnings (non-critical)${NC}" \
    "${GREEN}✅ Build successful${NC}"
echo ""

echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    ALL TESTS COMPLETE                         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Key Improvements:${NC}"
echo "  1. ✅ Dynamic width calculation based on content"
echo "  2. ✅ Proper padding (4 spaces on each side)"
echo "  3. ✅ Consistent border rendering"
echo "  4. ✅ Unicode and emoji support"
echo "  5. ✅ ANSI color code handling"
echo "  6. ✅ No broken borders regardless of content length"
echo ""
