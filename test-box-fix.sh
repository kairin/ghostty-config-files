#!/bin/bash

# Test script for box-drawing width calculation fix
# This script tests the fixed box-drawing functions with ANSI color codes

# Source color definitions and box functions from start.sh
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Source the box-drawing functions from start.sh
source /home/kkk/Apps/ghostty-config-files/start.sh 2>/dev/null || true

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

# Test 5: Header function
echo "Test 5: Header function"
draw_header "Simple Header Test"
echo ""

# Test 6: Actual installation-style boxes
echo "Test 6: Real-world installation box (simulated)"
draw_colored_box "$GREEN" "ZSH Installation - Skipped" \
    "ZSH already installed" \
    "Version: 5.9" \
    "Use --force-zsh to reinstall"
echo ""

echo -e "${GREEN}✅ All tests complete!${NC}"
echo -e "${CYAN}Check that all right edges (║) are perfectly aligned.${NC}"
