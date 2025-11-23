#!/bin/bash
#
# Passwordless Sudo Verification Script
# Verifies that passwordless sudo is configured for /usr/bin/apt
# Used by start.sh to ensure automated installation can proceed
#
# Exit codes:
#   0 - Passwordless sudo is properly configured
#   1 - Passwordless sudo is NOT configured
#   2 - Script error

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_NAME="Passwordless Sudo Verification"
REQUIRED_COMMAND="/usr/bin/apt"

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    local title="$1"
    local title_width=${#title}
    local total_width=$((title_width + 8))

    echo -e "${CYAN}$(printf '━%.0s' $(seq 1 $total_width))${NC}"
    printf "${CYAN}    %-${title_width}s    ${NC}\n" "$title"
    echo -e "${CYAN}$(printf '━%.0s' $(seq 1 $total_width))${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# ============================================================================
# Verification Functions
# ============================================================================

check_passwordless_sudo() {
    # Test if sudo can run apt commands without password prompt
    # Uses -n flag which means "non-interactive" - fails if password required
    if sudo -n "$REQUIRED_COMMAND" update --help >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

show_configuration_instructions() {
    local header_width=76
    local box_width=76

    cat << EOF

$(printf '═%.0s' $(seq 1 $header_width))
    HOW TO CONFIGURE PASSWORDLESS SUDO
$(printf '═%.0s' $(seq 1 $header_width))

This repository requires passwordless sudo for /usr/bin/apt to enable:
  • Automated daily updates at 9:00 AM
  • One-command installation without password prompts
  • Local CI/CD workflows

SECURITY NOTE: This grants passwordless access ONLY to apt commands,
               NOT unrestricted sudo access.

$(printf '─%.0s' $(seq 1 $box_width))
  STEP 1: Open sudoers configuration
$(printf '─%.0s' $(seq 1 $box_width))

Run this command:

    sudo EDITOR=nano visudo

$(printf '─%.0s' $(seq 1 $box_width))
  STEP 2: Add passwordless sudo rule
$(printf '─%.0s' $(seq 1 $box_width))

Add this line at the VERY END of the file:

    USERNAME ALL=(ALL) NOPASSWD: /usr/bin/apt

Replace USERNAME with your actual username (current: $USER)

Example:
    kkk ALL=(ALL) NOPASSWD: /usr/bin/apt

$(printf '─%.0s' $(seq 1 $box_width))
  STEP 3: Save and exit
$(printf '─%.0s' $(seq 1 $box_width))

In nano:
  1. Press Ctrl+End to go to end of file
  2. Add the line above
  3. Press Ctrl+O to save, then Enter
  4. Press Ctrl+X to exit

$(printf '─%.0s' $(seq 1 $box_width))
  STEP 4: Verify configuration
$(printf '─%.0s' $(seq 1 $box_width))

Run this script again to verify:

    ./scripts/verify-passwordless-sudo.sh

Or test manually:

    sudo -n apt update

If successful, you should see apt output without a password prompt.

$(printf '─%.0s' $(seq 1 $box_width))
  ALTERNATIVE: Interactive Installation
$(printf '─%.0s' $(seq 1 $box_width))

If you prefer NOT to configure passwordless sudo, you can:
  • Manually enter password during installation (when prompted)
  • Skip automated daily updates feature
  • Run update-all manually when needed

$(printf '═%.0s' $(seq 1 $header_width))
    SECURITY INFORMATION
$(printf '═%.0s' $(seq 1 $header_width))

✅ SECURE: Only /usr/bin/apt can run without password
✅ SECURE: Other sudo commands still require password
✅ SECURE: No unrestricted root access granted
❌ INSECURE: Do NOT use "kkk ALL=(ALL) NOPASSWD: ALL" (unrestricted)

For more information, see:
  • Documentation: documentations/developer/analysis/passwordless-sudo-research.md
  • CLAUDE.md: Installation Prerequisites section

EOF
}

# ============================================================================
# Main Verification
# ============================================================================

main() {
    local exit_code=0

    print_header "Passwordless Sudo Verification for $REQUIRED_COMMAND"
    echo ""

    print_info "Testing passwordless sudo configuration..."
    echo ""

    if check_passwordless_sudo; then
        print_success "Passwordless sudo is PROPERLY CONFIGURED"
        echo ""
        print_info "Configuration verified:"
        echo "    • Command: $REQUIRED_COMMAND"
        echo "    • Status: ✅ Can run without password"
        echo "    • User: $USER"
        echo ""
        print_success "You can proceed with ./start.sh installation"
        echo ""
        exit_code=0
    else
        print_error "Passwordless sudo is NOT configured"
        echo ""
        print_warning "Installation cannot proceed without passwordless sudo"
        echo ""
        print_info "What this means:"
        echo "    • apt commands require password prompt"
        echo "    • Automated installation will fail"
        echo "    • Daily updates cannot run automatically"
        echo ""

        show_configuration_instructions

        exit_code=1
    fi

    print_header "Verification Complete"

    return $exit_code
}

# Run main function
main "$@"
