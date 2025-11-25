#!/usr/bin/env bash
# gh-pages-setup.sh - Zero-cost GitHub Pages setup with Astro

set -euo pipefail
IFS=$'\n\t'

# Script configuration
readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
readonly DOCS_DIR="$REPO_DIR/docs"
readonly NOJEKYLL_FILE="$DOCS_DIR/.nojekyll"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        "ERROR") echo -e "${RED}[$timestamp] [ERROR] $message${NC}" >&2 ;;
        "SUCCESS") echo -e "${GREEN}[$timestamp] [SUCCESS] $message${NC}" ;;
        "WARNING") echo -e "${YELLOW}[$timestamp] [WARNING] $message${NC}" ;;
        "INFO") echo -e "${BLUE}[$timestamp] [INFO] $message${NC}" ;;
        "STEP") echo -e "${CYAN}[$timestamp] [STEP] $message${NC}" ;;
    esac
}

# Error handler
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# Cleanup function
cleanup() {
    local exit_code=$?
    # Add any cleanup tasks here if needed
    exit $exit_code
}

# Register cleanup on exit
trap cleanup EXIT INT TERM

# Check dependencies
check_dependencies() {
    local missing_deps=()
    local optional_missing=()

    # Check for npx (required for Astro build)
    if ! command -v npx >/dev/null 2>&1; then
        missing_deps+=("npx (Node.js)")
    fi

    # GitHub CLI is optional (can configure manually)
    if ! command -v gh >/dev/null 2>&1; then
        optional_missing+=("gh (GitHub CLI)")
        log "WARNING" "GitHub CLI not found - manual configuration will be required"
    fi

    # jq is optional
    if ! command -v jq >/dev/null 2>&1; then
        optional_missing+=("jq")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        error_exit "Missing required dependencies: ${missing_deps[*]}"
    fi

    if [ ${#optional_missing[@]} -gt 0 ]; then
        log "INFO" "Optional dependencies not found: ${optional_missing[*]}"
    fi
}

# Verify .nojekyll file exists (CRITICAL for GitHub Pages + Astro)
verify_nojekyll() {
    log "STEP" "🔍 Verifying critical .nojekyll file..."

    if [ ! -f "$NOJEKYLL_FILE" ]; then
        log "ERROR" "CRITICAL: .nojekyll file missing from docs/ directory"
        log "ERROR" "Without this file, ALL CSS/JS assets will return 404 errors on GitHub Pages"
        log "INFO" "Creating .nojekyll file now..."

        if [ ! -d "$DOCS_DIR" ]; then
            mkdir -p "$DOCS_DIR"
        fi

        touch "$NOJEKYLL_FILE"
        log "SUCCESS" "✅ Created .nojekyll file at: $NOJEKYLL_FILE"
        log "WARNING" "⚠️ You must commit this file to git: git add docs/.nojekyll && git commit"
        return 1
    else
        log "SUCCESS" "✅ .nojekyll file exists (required for Astro + GitHub Pages)"
        return 0
    fi
}

# Verify Astro build output
verify_astro_build() {
    log "STEP" "🔍 Verifying Astro build output..."

    # Check if docs directory exists
    if [ ! -d "$DOCS_DIR" ]; then
        log "ERROR" "docs/ directory not found"
        log "INFO" "Run Astro build first: cd $REPO_DIR && npx astro build"
        return 1
    fi

    # Check for index.html
    if [ ! -f "$DOCS_DIR/index.html" ]; then
        log "ERROR" "No index.html found in docs/"
        log "INFO" "Run Astro build: cd $REPO_DIR && npx astro build"
        return 1
    fi

    # Check for _astro directory (contains CSS/JS assets)
    if [ ! -d "$DOCS_DIR/_astro" ]; then
        log "WARNING" "_astro/ directory not found - assets may be missing"
    else
        log "SUCCESS" "✅ _astro/ directory exists (CSS/JS assets)"
    fi

    # Count assets
    local html_count=$(find "$DOCS_DIR" -name "*.html" -type f 2>/dev/null | wc -l)
    local asset_count=$(find "$DOCS_DIR/_astro" -type f 2>/dev/null | wc -l || echo "0")

    log "SUCCESS" "✅ Astro build output verified"
    log "INFO" "   HTML files: $html_count"
    log "INFO" "   Asset files: $asset_count"

    return 0
}

# Run Astro build
run_astro_build() {
    log "STEP" "🚀 Running Astro build..."

    cd "$REPO_DIR"

    if npx astro build 2>&1; then
        log "SUCCESS" "✅ Astro build completed successfully"
        return 0
    else
        log "ERROR" "Astro build failed"
        log "INFO" "Check astro.config.mjs configuration"
        log "INFO" "Ensure all dependencies are installed: npm install"
        return 1
    fi
}

# Configure GitHub Pages via GitHub CLI
configure_github_pages() {
    log "STEP" "🔧 Configuring GitHub Pages deployment..."

    if ! command -v gh >/dev/null 2>&1; then
        log "WARNING" "GitHub CLI not available"
        show_manual_setup_instructions
        return 1
    fi

    # Check if authenticated
    if ! gh auth status >/dev/null 2>&1; then
        log "ERROR" "Not authenticated with GitHub CLI"
        log "INFO" "Run: gh auth login"
        return 1
    fi

    # Configure GitHub Pages
    log "INFO" "Configuring repository to serve from docs/ folder on main branch..."

    if gh api repos/:owner/:repo --method PATCH \
        --field source[branch]=main \
        --field source[path]="/docs" 2>&1; then
        log "SUCCESS" "✅ GitHub Pages configured to serve from docs/ folder"

        # Get Pages URL
        local pages_url
        pages_url=$(gh api repos/:owner/:repo --jq '.html_url' 2>/dev/null | sed 's/github.com/github.io/' | sed 's|$|/|')
        if [ -n "$pages_url" ]; then
            log "SUCCESS" "📄 Your site will be available at: $pages_url"
        fi

        return 0
    else
        log "ERROR" "Failed to configure GitHub Pages via API"
        show_manual_setup_instructions
        return 1
    fi
}

# Show manual setup instructions
show_manual_setup_instructions() {
    cat << EOF

${YELLOW}========================================${NC}
${YELLOW}Manual GitHub Pages Setup Required${NC}
${YELLOW}========================================${NC}

1. Go to your repository on GitHub
2. Click: Settings → Pages
3. Under "Source":
   - Select: ${GREEN}Deploy from a branch${NC}
   - Branch: ${GREEN}main${NC}
   - Folder: ${GREEN}/docs${NC}
4. Click ${GREEN}Save${NC}

Your site will be published at:
  https://<username>.github.io/<repository>/

${YELLOW}========================================${NC}

EOF
}

# Display help information
show_help() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTION]

Zero-cost GitHub Pages setup with Astro.build for ghostty-config-files.

Options:
    --verify      Verify Astro build output and .nojekyll file (no changes)
    --configure   Configure GitHub Pages deployment via GitHub CLI
    --build       Run Astro build and verify output
    --help        Display this help message and exit

Examples:
    $SCRIPT_NAME
        Complete setup: verify, build if needed, configure

    $SCRIPT_NAME --verify
        Only verify existing build output and .nojekyll file

    $SCRIPT_NAME --configure
        Only configure GitHub Pages (assumes build already complete)

    $SCRIPT_NAME --build
        Only run Astro build and verify output

Dependencies:
    Required: npx (Node.js)
    Optional: gh (GitHub CLI for automated configuration)
    Optional: jq (for enhanced JSON output)

Critical Files:
    docs/.nojekyll       REQUIRED - Prevents Jekyll processing on GitHub Pages
    docs/index.html      Main entry point for the site
    docs/_astro/         CSS/JS assets directory

Exit Codes:
    0    Success
    1    Error (missing dependencies, build failure, etc.)

Notes:
    - The .nojekyll file is CRITICAL for Astro + GitHub Pages
    - Without it, ALL CSS/JS assets will return 404 errors
    - This file should be committed to version control

EOF
}

# Main setup function
main() {
    local mode="${1:-full}"

    # Handle help first
    if [[ "$mode" == "--help" || "$mode" == "-h" ]]; then
        show_help
        exit 0
    fi

    log "INFO" "📄 Setting up zero-cost GitHub Pages with Astro..."

    # Check dependencies
    check_dependencies

    # Process command
    case "$mode" in
        --verify)
            verify_nojekyll
            verify_astro_build
            ;;
        --configure)
            verify_nojekyll || true
            configure_github_pages
            ;;
        --build)
            run_astro_build
            verify_nojekyll || true
            verify_astro_build
            ;;
        *)
            # Full setup process
            local nojekyll_ok=0
            local build_ok=0

            # Step 1: Verify .nojekyll
            verify_nojekyll && nojekyll_ok=1

            # Step 2: Verify or run build
            if ! verify_astro_build; then
                log "INFO" "Build verification failed, attempting Astro build..."
                if run_astro_build; then
                    verify_astro_build && build_ok=1
                    # Re-verify .nojekyll after build
                    verify_nojekyll || log "WARNING" "Verify .nojekyll file was not removed by build"
                fi
            else
                build_ok=1
            fi

            # Step 3: Configure GitHub Pages
            if [ $build_ok -eq 1 ]; then
                configure_github_pages || log "WARNING" "GitHub Pages configuration incomplete - see manual instructions above"
            else
                log "ERROR" "Cannot configure GitHub Pages - build verification failed"
                exit 1
            fi

            log "SUCCESS" "✅ GitHub Pages setup complete"
            ;;
    esac
}

# Execute main function
main "$@"
