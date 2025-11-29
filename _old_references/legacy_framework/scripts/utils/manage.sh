#!/usr/bin/env bash
# manage.sh - Unified management interface (thin router)
# Routes commands to modular implementations in lib/manage/
# Original: 2,436 lines -> Router: ~90 lines (96% reduction)

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
VERSION="2.0.0"
BUILD_DATE="2025-11-25"

# Source core utilities
source "${REPO_ROOT}/lib/core/logging.sh"
source "${REPO_ROOT}/lib/core/utils.sh"

# Source command modules
source "${REPO_ROOT}/lib/manage/cleanup.sh"
source "${REPO_ROOT}/lib/manage/docs.sh"
source "${REPO_ROOT}/lib/manage/install.sh"
source "${REPO_ROOT}/lib/manage/screenshots.sh"
source "${REPO_ROOT}/lib/manage/status.sh"
source "${REPO_ROOT}/lib/manage/update.sh"
source "${REPO_ROOT}/lib/manage/validate.sh"

# Global flags
VERBOSE=0
QUIET=0
DRY_RUN=0

show_help() {
    cat << EOF
manage.sh - Ghostty Configuration Repository Management (v${VERSION})

USAGE: ./manage.sh <command> [options]

COMMANDS:
    install         Install complete Ghostty terminal environment
    docs            Documentation management (build, dev, generate)
    screenshots     Screenshot capture and gallery generation
    update          Update repository components
    validate        Run validation checks
    status          Show installation status
    cleanup         Clean temporary files and artifacts
    help            Show this help message
    version         Show version information

GLOBAL OPTIONS:
    --help, -h      Show help for command
    --version, -v   Show version information
    --verbose       Enable verbose output
    --quiet, -q     Suppress non-essential output
    --dry-run       Show what would be done without executing

EXAMPLES:
    ./manage.sh install --help
    ./manage.sh docs build
    ./manage.sh validate all
    ./manage.sh status --verbose

VERSION: ${VERSION} (${BUILD_DATE})
EOF
}

show_version() {
    echo "manage.sh version ${VERSION}"
    echo "Build Date: ${BUILD_DATE}"
    echo "Platform: $(uname -s) $(uname -m)"
}

main() {
    # Handle global flags first
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --version|-v) show_version; exit 0 ;;
            --help|-h) [[ $# -eq 1 ]] && { show_help; exit 0; }; break ;;
            --verbose) export VERBOSE=1; shift ;;
            --quiet|-q) export QUIET=1; shift ;;
            --dry-run) export DRY_RUN=1; shift ;;
            -*) break ;;  # Let command handle unknown options
            *) break ;;
        esac
    done

    local command="${1:-help}"
    [[ $# -gt 0 ]] && shift

    # Route to command handler
    case "$command" in
        install)        cmd_install "$@" ;;
        docs)           cmd_docs "$@" ;;
        screenshots)    cmd_screenshots "$@" ;;
        update)         cmd_update "$@" ;;
        validate)       cmd_validate "$@" ;;
        status|info)    cmd_status "$@" ;;
        cleanup|clean)  cmd_cleanup "$@" ;;
        help)           show_help ;;
        version)        show_version ;;
        *)
            log "ERROR" "Unknown command: $command"
            echo "Use './manage.sh help' for available commands"
            exit 2
            ;;
    esac
}

main "$@"
