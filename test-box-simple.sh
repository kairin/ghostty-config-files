#!/bin/bash

# Simple test for box-drawing width calculation fix
# Extract only the necessary functions

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Extract get_string_width function from start.sh
get_string_width() {
    local string="$1"
    local clean_string=$(echo -e "$string" | sed -E '
        s/\x1b\[[0-9;]*m//g;
        s/\x1b\[[0-9;]*[A-Za-z]//g;
        s/\x1b\][^\x07]*\x07//g;
        s/\x1b[()][AB012]//g
    ')
    echo "${#clean_string}"
}

# Extract draw_colored_box function from start.sh  
draw_colored_box() {
    local color="$1"
    local title="$2"
    shift 2
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
    printf "${color}╔"
    printf '═%.0s' $(seq 1 $inner_width)
    printf "╗${NC}\n"

    # Draw title with padding and vertical borders
    local title_display=$(get_string_width "$title")
    local title_padding=$((content_width - title_display))
    printf "${color}║${NC}    "
    echo -ne "$title"
    printf '%*s' "$((title_padding + 4))" ''
    printf "${color}║${NC}\n"

    # Draw middle separator (╠══...══╣)
    printf "${color}╠"
    printf '═%.0s' $(seq 1 $inner_width)
    printf "╣${NC}\n"

    # Draw empty line with borders
    printf "${color}║${NC}    "
    printf '%*s' "$((content_width + 4))" ''
    printf "${color}║${NC}\n"

    # Draw content with padding and vertical borders
    for line in "${content[@]}"; do
        local line_display=$(get_string_width "$line")
        local line_padding=$((content_width - line_display))
        printf "${color}║${NC}    "
        echo -ne "$line"
        printf '%*s' "$((line_padding + 4))" ''
        printf "${color}║${NC}\n"
    done

    # Draw empty line with borders
    printf "${color}║${NC}    "
    printf '%*s' "$((content_width + 4))" ''
    printf "${color}║${NC}\n"

    # Draw bottom border (╚══...══╝)
    printf "${color}╚"
    printf '═%.0s' $(seq 1 $inner_width)
    printf "╝${NC}\n"
}

echo -e "${CYAN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}    Box Drawing Width Calculation Test            ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# Test 1: Plain text (baseline)
echo "Test 1: Plain text (should work perfectly)"
draw_colored_box "$BLUE" "Plain Text Test" \
    "This is a simple line" \
    "Another line without colors"
echo ""

# Test 2: Colored content
echo "Test 2: Colored content (was previously broken)"
draw_colored_box "$GREEN" "Colored Content Test" \
    "${GREEN}Installation Complete${NC}" \
    "${YELLOW}Version: 1.2.3${NC}" \
    "${RED}Some warning message${NC}"
echo ""

# Test 3: Mixed content (plain + colored)
echo "Test 3: Mixed content"
draw_colored_box "$MAGENTA" "Mixed Content Test" \
    "Plain text line" \
    "${CYAN}Colored line${NC}" \
    "Another plain line" \
    "${GREEN}Final colored line${NC}"
echo ""

# Test 4: Long lines
echo "Test 4: Long lines to ensure width calculation"
draw_colored_box "$YELLOW" "Long Line Test" \
    "${GREEN}This is a very long line with colors that should properly align${NC}" \
    "Short line" \
    "${RED}Another long colored line to test the right edge alignment fix${NC}"
echo ""

# Test 5: Real-world example (simulated installation box)
echo "Test 5: Real-world installation box (simulated)"
draw_colored_box "$GREEN" "ZSH Installation - Skipped" \
    "ZSH already installed" \
    "Version: 5.9" \
    "Use --force-zsh to reinstall"
echo ""

echo -e "${GREEN}All tests complete!${NC}"
echo -e "${CYAN}Verify that all right edges (║) are perfectly aligned.${NC}"
