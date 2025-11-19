#!/usr/bin/env bash
#
# Fix ZSH Compinit Security Issues
#
# This script automatically detects and fixes insecure zsh completion files
# that cause "zsh compinit: insecure files" warnings during shell startup.
#
# Issue: Completion files with incorrect ownership (e.g., nobody:nogroup)
# Solution: Change ownership to root:root and set proper permissions (644)
#
# Usage:
#   ./fix-zsh-compinit-security.sh           # Interactive mode (prompts for sudo)
#   ./fix-zsh-compinit-security.sh --auto    # Automatic mode (requires passwordless sudo)
#   ./fix-zsh-compinit-security.sh --check   # Check only, don't fix

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Parse command line arguments
MODE="interactive"
if [[ "${1:-}" == "--auto" ]]; then
    MODE="auto"
elif [[ "${1:-}" == "--check" ]]; then
    MODE="check"
fi

# Function to check for insecure files
check_insecure_files() {
    local insecure_files=()

    if command -v compaudit >/dev/null 2>&1; then
        # Capture compaudit output
        while IFS= read -r file; do
            if [[ -n "$file" && -f "$file" ]]; then
                insecure_files+=("$file")
            fi
        done < <(compaudit 2>/dev/null || true)
    else
        log_error "compaudit command not found. Is zsh installed?"
        return 1
    fi

    # Return the array via stdout (one file per line)
    printf '%s\n' "${insecure_files[@]}"
}

# Function to get file details
get_file_details() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    # Get owner and permissions
    local owner
    local perms
    owner=$(stat -c '%U:%G' "$file" 2>/dev/null || stat -f '%Su:%Sg' "$file" 2>/dev/null)
    perms=$(stat -c '%a' "$file" 2>/dev/null || stat -f '%A' "$file" 2>/dev/null)

    echo "$file|$owner|$perms"
}

# Function to fix file ownership and permissions
fix_file() {
    local file="$1"
    local auto_mode="${2:-false}"

    log_info "Fixing: $file"

    # Get current details
    local details
    details=$(get_file_details "$file")
    local current_owner
    current_owner=$(echo "$details" | cut -d'|' -f2)

    log_info "  Current owner: $current_owner"
    log_info "  Target owner: root:root"
    log_info "  Target permissions: 644"

    if [[ "$auto_mode" == "true" ]]; then
        # Automatic mode - try without prompting
        if sudo -n chown root:root "$file" 2>/dev/null && sudo -n chmod 644 "$file" 2>/dev/null; then
            log_success "  Fixed automatically"
            return 0
        else
            log_error "  Failed: Passwordless sudo not configured"
            return 1
        fi
    else
        # Interactive mode - prompt for password
        if sudo chown root:root "$file" && sudo chmod 644 "$file"; then
            log_success "  Fixed successfully"
            return 0
        else
            log_error "  Failed to fix file"
            return 1
        fi
    fi
}

# Main execution
main() {
    echo ""
    log_info "====================================================="
    log_info "  ZSH Compinit Security Fix Utility"
    log_info "====================================================="
    echo ""

    # Check if zsh is installed
    if ! command -v zsh >/dev/null 2>&1; then
        log_error "ZSH is not installed on this system"
        exit 1
    fi

    log_info "Checking for insecure completion files..."
    echo ""

    # Get list of insecure files
    mapfile -t insecure_files < <(check_insecure_files)

    # Filter out empty entries
    local filtered_files=()
    for file in "${insecure_files[@]}"; do
        if [[ -n "$file" && -f "$file" ]]; then
            filtered_files+=("$file")
        fi
    done
    insecure_files=("${filtered_files[@]}")

    if [[ ${#insecure_files[@]} -eq 0 ]]; then
        log_success "No insecure files found!"
        log_success "Your zsh completion system is secure."
        exit 0
    fi

    log_warning "Found ${#insecure_files[@]} insecure file(s):"
    echo ""

    # Display insecure files with details
    for file in "${insecure_files[@]}"; do
        if [[ -n "$file" && -f "$file" ]]; then
            local details
            details=$(get_file_details "$file")
            local owner
            local perms
            owner=$(echo "$details" | cut -d'|' -f2)
            perms=$(echo "$details" | cut -d'|' -f3)

            echo "  📄 $file"
            echo "     Owner: $owner | Permissions: $perms"
        fi
    done
    echo ""

    # Check-only mode
    if [[ "$MODE" == "check" ]]; then
        log_info "Check-only mode: Not applying fixes"
        log_info "Run without --check flag to fix these issues"
        exit 1
    fi

    # Fix files based on mode
    local fixed_count=0
    local failed_count=0

    if [[ "$MODE" == "auto" ]]; then
        log_info "Running in automatic mode..."
        echo ""

        for file in "${insecure_files[@]}"; do
            if fix_file "$file" "true"; then
                ((fixed_count++))
            else
                ((failed_count++))
            fi
        done
    else
        log_info "Running in interactive mode..."
        log_warning "You will be prompted for your sudo password"
        echo ""

        for file in "${insecure_files[@]}"; do
            if fix_file "$file" "false"; then
                ((fixed_count++))
            else
                ((failed_count++))
            fi
        done
    fi

    # Summary
    echo ""
    log_info "====================================================="
    log_info "  Summary"
    log_info "====================================================="
    log_success "Fixed: $fixed_count file(s)"

    if [[ $failed_count -gt 0 ]]; then
        log_error "Failed: $failed_count file(s)"
    fi

    # Final verification
    echo ""
    log_info "Verifying fix..."
    mapfile -t remaining_issues < <(check_insecure_files)

    if [[ ${#remaining_issues[@]} -eq 0 ]]; then
        log_success "All issues resolved!"
        log_success "You can now restart zsh without warnings"
        exit 0
    else
        log_warning "Some issues remain:"
        printf '  %s\n' "${remaining_issues[@]}"
        exit 1
    fi
}

# Run main function
main "$@"
