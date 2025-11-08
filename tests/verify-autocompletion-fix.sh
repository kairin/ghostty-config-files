#!/bin/bash
# Verification Script for Oh My Zsh Autocompletion Fix
# This script tests the autocompletion fix logic without modifying the actual system

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test environment
TEST_DIR="/tmp/ghostty-autocompletion-test-$(date +%Y%m%d-%H%M%S)"
TEST_ZSHRC="$TEST_DIR/.zshrc"
TEST_LOG="$TEST_DIR/verification.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Autocompletion Fix Verification Test${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Setup test environment
setup_test_env() {
    echo -e "${BLUE}[SETUP]${NC} Creating test environment at $TEST_DIR"
    mkdir -p "$TEST_DIR"

    # Create a mock .zshrc similar to what Oh My Zsh creates
    cat > "$TEST_ZSHRC" << 'EOF'
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="robbyrussell"

# Which plugins would you like to load?
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration
# export MANPATH="/usr/local/man:$MANPATH"

. "$HOME/.local/bin/env"

export PATH="$PATH:$(npm config get prefix)/bin"
# XDG-compliant dircolors configuration
eval "$(dircolors ${XDG_CONFIG_HOME:-$HOME/.config}/dircolors)"
EOF

    echo -e "${GREEN}✓${NC} Test .zshrc created"
}

# Test 1: Verify Ghostty shell integration logic
test_ghostty_integration() {
    echo ""
    echo -e "${CYAN}[TEST 1]${NC} Ghostty Shell Integration Logic"
    echo "----------------------------------------"

    local test_zshrc="$TEST_ZSHRC"
    local backup_created=false

    # Backup original
    cp "$test_zshrc" "$test_zshrc.backup"

    # Simulate the start.sh logic
    if ! grep -q "GHOSTTY_RESOURCES_DIR.*ghostty-integration" "$test_zshrc"; then
        echo -e "${BLUE}[INFO]${NC} Ghostty integration not found, adding..."

        if grep -q "source.*oh-my-zsh.sh" "$test_zshrc"; then
            sed -i '/source.*oh-my-zsh.sh/a\
\
# Ghostty shell integration (CRITICAL for proper terminal behavior)\
if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then\
  autoload -Uz -- "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration\
  ghostty-integration\
fi' "$test_zshrc"
            echo -e "${GREEN}✓${NC} Ghostty integration added after oh-my-zsh.sh"
        else
            echo -e "${RED}✗${NC} Could not find 'source.*oh-my-zsh.sh' line"
            return 1
        fi
    else
        echo -e "${YELLOW}[SKIP]${NC} Ghostty integration already present"
    fi

    # Verify the integration was added correctly
    if grep -q "GHOSTTY_RESOURCES_DIR.*ghostty-integration" "$test_zshrc"; then
        echo -e "${GREEN}✓${NC} Verification: Ghostty integration present in .zshrc"

        # Check it's in the right place (after oh-my-zsh.sh)
        local omz_line=$(grep -n "source.*oh-my-zsh.sh" "$test_zshrc" | cut -d: -f1)
        local ghostty_line=$(grep -n "GHOSTTY_RESOURCES_DIR" "$test_zshrc" | head -1 | cut -d: -f1)

        if [ "$ghostty_line" -gt "$omz_line" ]; then
            echo -e "${GREEN}✓${NC} Verification: Integration placed after oh-my-zsh.sh (line $omz_line < $ghostty_line)"
        else
            echo -e "${RED}✗${NC} Error: Integration not in correct position"
            return 1
        fi

        # Show the added section
        echo -e "\n${CYAN}Added section:${NC}"
        sed -n "$((ghostty_line-1)),$((ghostty_line+4))p" "$test_zshrc" | sed 's/^/  /'

    else
        echo -e "${RED}✗${NC} Verification failed: Integration not found"
        return 1
    fi
}

# Test 2: Verify idempotency (running twice shouldn't duplicate)
test_idempotency() {
    echo ""
    echo -e "${CYAN}[TEST 2]${NC} Idempotency Check"
    echo "----------------------------------------"

    local test_zshrc="$TEST_ZSHRC"
    local before_count=$(grep -c "GHOSTTY_RESOURCES_DIR" "$test_zshrc" || echo "0")

    # Run the logic again
    if ! grep -q "GHOSTTY_RESOURCES_DIR.*ghostty-integration" "$test_zshrc"; then
        sed -i '/source.*oh-my-zsh.sh/a\
\
# Ghostty shell integration (CRITICAL for proper terminal behavior)\
if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then\
  autoload -Uz -- "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration\
  ghostty-integration\
fi' "$test_zshrc"
        echo -e "${RED}✗${NC} Integration was added again (should have been skipped)"
        return 1
    else
        echo -e "${GREEN}✓${NC} Integration correctly skipped on second run"
    fi

    local after_count=$(grep -c "GHOSTTY_RESOURCES_DIR" "$test_zshrc" || echo "0")

    if [ "$before_count" -eq "$after_count" ]; then
        echo -e "${GREEN}✓${NC} Verification: No duplicates (count: $before_count = $after_count)"
    else
        echo -e "${RED}✗${NC} Error: Duplicate entries detected ($before_count -> $after_count)"
        return 1
    fi
}

# Test 3: Verify plugins configuration
test_plugins_config() {
    echo ""
    echo -e "${CYAN}[TEST 3]${NC} Plugin Configuration Logic"
    echo "----------------------------------------"

    local test_zshrc="$TEST_ZSHRC"

    # Check current plugins
    local current_plugins=$(grep "^plugins=" "$test_zshrc" || echo "plugins=()")
    echo -e "${BLUE}[INFO]${NC} Current plugins: $current_plugins"

    # Simulate plugin update (from start.sh line 1593)
    if grep -q "plugins=" "$test_zshrc"; then
        sed -i 's/plugins=([^)]*)/plugins=(git npm node nvm docker docker-compose sudo history extract z you-should-use zsh-autosuggestions zsh-syntax-highlighting)/' "$test_zshrc"
        echo -e "${GREEN}✓${NC} Updated plugins configuration"
    fi

    # Verify plugins
    local updated_plugins=$(grep "^plugins=" "$test_zshrc")
    echo -e "${BLUE}[INFO]${NC} Updated plugins: $updated_plugins"

    # Check for critical plugins
    local critical_plugins=("zsh-autosuggestions" "zsh-syntax-highlighting")
    for plugin in "${critical_plugins[@]}"; do
        if echo "$updated_plugins" | grep -q "$plugin"; then
            echo -e "${GREEN}✓${NC} Critical plugin present: $plugin"
        else
            echo -e "${RED}✗${NC} Missing critical plugin: $plugin"
            return 1
        fi
    done

    # Verify syntax-highlighting is last
    if echo "$updated_plugins" | grep -q "zsh-syntax-highlighting)"; then
        echo -e "${GREEN}✓${NC} zsh-syntax-highlighting is correctly placed last"
    else
        echo -e "${YELLOW}⚠${NC}  zsh-syntax-highlighting may not be last in list"
    fi
}

# Test 4: Verify start.sh script syntax
test_start_script_syntax() {
    echo ""
    echo -e "${CYAN}[TEST 4]${NC} Start Script Syntax Check"
    echo "----------------------------------------"

    # Check bash syntax
    if bash -n "$SCRIPT_DIR/start.sh" 2>&1; then
        echo -e "${GREEN}✓${NC} start.sh syntax is valid"
    else
        echo -e "${RED}✗${NC} start.sh has syntax errors"
        return 1
    fi

    # Check for the new Ghostty integration code
    if grep -q "Add Ghostty shell integration to .zshrc (CRITICAL for autocompletion)" "$SCRIPT_DIR/start.sh"; then
        echo -e "${GREEN}✓${NC} Ghostty integration code present in start.sh"
    else
        echo -e "${RED}✗${NC} Ghostty integration code not found in start.sh"
        return 1
    fi

    # Verify the autoload command structure
    if grep -q 'autoload.*GHOSTTY_RESOURCES_DIR.*ghostty-integration' "$SCRIPT_DIR/start.sh"; then
        echo -e "${GREEN}✓${NC} Ghostty integration autoload command structure is correct"
    else
        echo -e "${RED}✗${NC} Ghostty integration autoload command not found"
        return 1
    fi
}

# Test 5: Verify documentation exists
test_documentation() {
    echo ""
    echo -e "${CYAN}[TEST 5]${NC} Documentation Verification"
    echo "----------------------------------------"

    local docs=(
        "$SCRIPT_DIR/docs/TROUBLESHOOTING_AUTOCOMPLETION.md"
        "$SCRIPT_DIR/configs/zsh/plugins-reference.conf"
    )

    for doc in "${docs[@]}"; do
        if [ -f "$doc" ]; then
            local line_count=$(wc -l < "$doc")
            echo -e "${GREEN}✓${NC} Found: $(basename $doc) ($line_count lines)"
        else
            echo -e "${RED}✗${NC} Missing: $(basename $doc)"
            return 1
        fi
    done

    # Check documentation content
    if grep -q "Ghostty shell integration" "$SCRIPT_DIR/docs/TROUBLESHOOTING_AUTOCOMPLETION.md"; then
        echo -e "${GREEN}✓${NC} Documentation mentions Ghostty shell integration"
    else
        echo -e "${YELLOW}⚠${NC}  Documentation may be incomplete"
    fi
}

# Test 6: Verify actual .zshrc in home directory
test_actual_zshrc() {
    echo ""
    echo -e "${CYAN}[TEST 6]${NC} Actual System .zshrc Verification"
    echo "----------------------------------------"

    local actual_zshrc="$HOME/.zshrc"

    if [ ! -f "$actual_zshrc" ]; then
        echo -e "${YELLOW}⚠${NC}  .zshrc not found at $actual_zshrc"
        return 0
    fi

    # Check if Ghostty integration is present
    if grep -q "GHOSTTY_RESOURCES_DIR.*ghostty-integration" "$actual_zshrc"; then
        echo -e "${GREEN}✓${NC} Ghostty integration present in actual .zshrc"

        # Show the section
        echo -e "\n${CYAN}Current integration in ~/.zshrc:${NC}"
        grep -A 4 "Ghostty shell integration" "$actual_zshrc" | sed 's/^/  /'
    else
        echo -e "${YELLOW}⚠${NC}  Ghostty integration NOT present in actual .zshrc"
        echo -e "${BLUE}[INFO]${NC} Run ./start.sh to apply the fix"
    fi

    # Check plugins
    if grep -q "plugins=.*zsh-autosuggestions" "$actual_zshrc"; then
        echo -e "${GREEN}✓${NC} zsh-autosuggestions plugin configured"
    else
        echo -e "${YELLOW}⚠${NC}  zsh-autosuggestions not in plugins list"
    fi

    if grep -q "plugins=.*zsh-syntax-highlighting" "$actual_zshrc"; then
        echo -e "${GREEN}✓${NC} zsh-syntax-highlighting plugin configured"
    else
        echo -e "${YELLOW}⚠${NC}  zsh-syntax-highlighting not in plugins list"
    fi
}

# Test 7: Check plugin installation status
test_plugin_installation() {
    echo ""
    echo -e "${CYAN}[TEST 7]${NC} Plugin Installation Status"
    echo "----------------------------------------"

    local plugins_dir="$HOME/.oh-my-zsh/custom/plugins"

    if [ ! -d "$plugins_dir" ]; then
        echo -e "${YELLOW}⚠${NC}  Oh My Zsh custom plugins directory not found"
        return 0
    fi

    local required_plugins=("zsh-autosuggestions" "zsh-syntax-highlighting")

    for plugin in "${required_plugins[@]}"; do
        if [ -d "$plugins_dir/$plugin" ]; then
            echo -e "${GREEN}✓${NC} Plugin installed: $plugin"

            # Check if it's a git repo
            if [ -d "$plugins_dir/$plugin/.git" ]; then
                local commit=$(cd "$plugins_dir/$plugin" && git rev-parse --short HEAD 2>/dev/null)
                echo -e "  ${BLUE}[INFO]${NC} Latest commit: $commit"
            fi
        else
            echo -e "${YELLOW}⚠${NC}  Plugin NOT installed: $plugin"
        fi
    done
}

# Cleanup
cleanup() {
    echo ""
    echo -e "${BLUE}[CLEANUP]${NC} Removing test environment"
    rm -rf "$TEST_DIR"
    echo -e "${GREEN}✓${NC} Cleanup complete"
}

# Generate report
generate_report() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}Verification Summary${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""

    cat > "$TEST_LOG" << EOF
Autocompletion Fix Verification Report
Generated: $(date)
Test Directory: $TEST_DIR
Script Directory: $SCRIPT_DIR

Test Results:
-------------
EOF

    echo -e "${GREEN}All tests completed!${NC}"
    echo ""
    echo -e "Test artifacts saved to: $TEST_DIR"
    echo -e "Full log available at: $TEST_LOG"
    echo ""

    # Show test .zshrc diff
    echo -e "${CYAN}Test .zshrc Changes:${NC}"
    if [ -f "$TEST_ZSHRC.backup" ]; then
        diff -u "$TEST_ZSHRC.backup" "$TEST_ZSHRC" | tail -20 || true
    fi
}

# Main execution
main() {
    local test_failed=0

    # Run all tests
    setup_test_env || test_failed=1

    test_ghostty_integration || test_failed=1
    test_idempotency || test_failed=1
    test_plugins_config || test_failed=1
    test_start_script_syntax || test_failed=1
    test_documentation || test_failed=1
    test_actual_zshrc || test_failed=1
    test_plugin_installation || test_failed=1

    generate_report

    # Keep test directory for inspection
    echo -e "${BLUE}[INFO]${NC} Test directory preserved at: $TEST_DIR"
    echo -e "${BLUE}[INFO]${NC} Inspect with: ls -la $TEST_DIR"
    echo -e "${BLUE}[INFO]${NC} View test .zshrc: cat $TEST_ZSHRC"

    echo ""
    if [ $test_failed -eq 0 ]; then
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}✓ ALL VERIFICATIONS PASSED${NC}"
        echo -e "${GREEN}========================================${NC}"
        return 0
    else
        echo -e "${RED}========================================${NC}"
        echo -e "${RED}✗ SOME VERIFICATIONS FAILED${NC}"
        echo -e "${RED}========================================${NC}"
        return 1
    fi
}

# Run main
main "$@"
