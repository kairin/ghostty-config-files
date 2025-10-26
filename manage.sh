#!/bin/bash
# manage.sh - Unified management interface for Ghostty Configuration Repository
# Purpose: Single entry point for all repository management operations
# Dependencies: bash 5.x+, scripts/* modules
# Exit Codes: 0=success, 1=general failure, 2=invalid arguments

set -euo pipefail

# ============================================================
# CONFIGURATION & INITIALIZATION
# ============================================================

# Get script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"

# Source common utilities
# shellcheck source=./scripts/common.sh
source "${SCRIPTS_DIR}/common.sh"

# shellcheck source=./scripts/progress.sh
source "${SCRIPTS_DIR}/progress.sh"

# Version information
VERSION="1.0.0"
BUILD_DATE="2025-10-27"

# ============================================================
# ENVIRONMENT VARIABLE SUPPORT (T019)
# ============================================================

# Function: load_environment_config
# Purpose: Load and validate environment variables for manage.sh
# Returns: 0 always (sets defaults if not specified)
load_environment_config() {
    # MANAGE_DEBUG: Enable debug logging (0 or 1)
    if [[ "${MANAGE_DEBUG:-}" == "1" ]]; then
        export DEBUG=1
        VERBOSE=1
        log_debug "Debug mode enabled via MANAGE_DEBUG"
    else
        export DEBUG="${DEBUG:-0}"
    fi

    # MANAGE_NO_COLOR: Disable colored output (0 or 1)
    if [[ "${MANAGE_NO_COLOR:-}" == "1" ]] || [[ "${NO_COLOR:-}" == "1" ]]; then
        export MANAGE_NO_COLOR=1
        log_debug "Colored output disabled"
    else
        export MANAGE_NO_COLOR="${MANAGE_NO_COLOR:-0}"
    fi

    # MANAGE_LOG_FILE: Path to log file for output
    if [[ -n "${MANAGE_LOG_FILE:-}" ]]; then
        # Validate log file path is writable
        local log_dir
        log_dir="$(dirname "$MANAGE_LOG_FILE")"
        if [[ ! -d "$log_dir" ]]; then
            log_warn "Log directory does not exist: $log_dir"
            log_info "Creating log directory: $log_dir"
            mkdir -p "$log_dir" || log_error "Failed to create log directory"
        fi

        if [[ -w "$log_dir" ]] || [[ ! -e "$MANAGE_LOG_FILE" ]]; then
            log_debug "Logging to file: $MANAGE_LOG_FILE"
            # Note: Actual redirection happens in main() if needed
        else
            log_warn "Log file not writable: $MANAGE_LOG_FILE"
            unset MANAGE_LOG_FILE
        fi
    fi

    # MANAGE_BACKUP_DIR: Custom backup directory
    if [[ -n "${MANAGE_BACKUP_DIR:-}" ]]; then
        if [[ ! -d "$MANAGE_BACKUP_DIR" ]]; then
            log_debug "Backup directory will be created: $MANAGE_BACKUP_DIR"
        else
            log_debug "Using custom backup directory: $MANAGE_BACKUP_DIR"
        fi
    else
        # Use default from backup_utils.sh
        log_debug "Using default backup directory"
    fi

    return 0
}

# ============================================================
# ERROR HANDLING & CLEANUP (T020)
# ============================================================

# Cleanup flag to prevent multiple cleanup calls
CLEANUP_DONE=0

# Temporary files to clean up
declare -a TEMP_FILES=()
declare -a TEMP_DIRS=()

# Function: register_temp_file
# Purpose: Register a temporary file for automatic cleanup
# Args: $1=file_path
register_temp_file() {
    local file_path="$1"
    TEMP_FILES+=("$file_path")
    log_debug "Registered temp file for cleanup: $file_path"
}

# Function: register_temp_dir
# Purpose: Register a temporary directory for automatic cleanup
# Args: $1=dir_path
register_temp_dir() {
    local dir_path="$1"
    TEMP_DIRS+=("$dir_path")
    log_debug "Registered temp directory for cleanup: $dir_path"
}

# Function: cleanup_on_exit
# Purpose: Cleanup function called on script exit (normal or error)
# Args: None
# Returns: 0 always
cleanup_on_exit() {
    # Prevent multiple cleanup calls
    if [[ "$CLEANUP_DONE" -eq 1 ]]; then
        return 0
    fi
    CLEANUP_DONE=1

    log_debug "Running cleanup on exit..."

    # Clean up temporary files
    for temp_file in "${TEMP_FILES[@]}"; do
        if [[ -f "$temp_file" ]]; then
            log_debug "Removing temp file: $temp_file"
            rm -f "$temp_file" 2>/dev/null || true
        fi
    done

    # Clean up temporary directories
    for temp_dir in "${TEMP_DIRS[@]}"; do
        if [[ -d "$temp_dir" ]]; then
            log_debug "Removing temp directory: $temp_dir"
            rm -rf "$temp_dir" 2>/dev/null || true
        fi
    done

    return 0
}

# Function: handle_error
# Purpose: Error handler called when a command fails
# Args: $1=exit_code, $2=line_number, $3=bash_command
# Returns: Never (exits with error code)
handle_error() {
    local exit_code=$1
    local line_number=$2
    local bash_command="${3:-unknown command}"

    log_error "Command failed with exit code $exit_code at line $line_number"
    log_error "Failed command: $bash_command"

    # Run cleanup
    cleanup_on_exit

    # Exit with the error code
    exit "$exit_code"
}

# Function: handle_interrupt
# Purpose: Handle Ctrl+C and other interrupts gracefully
# Args: None
# Returns: Never (exits with code 130)
handle_interrupt() {
    echo ""  # New line after ^C
    log_warn "Interrupted by user (Ctrl+C)"

    # Run cleanup
    cleanup_on_exit

    # Exit with standard interrupt code
    exit 130
}

# Set up error handling and cleanup traps
trap cleanup_on_exit EXIT
trap 'handle_error $? $LINENO "$BASH_COMMAND"' ERR
trap handle_interrupt INT TERM

# ============================================================
# HELP & USAGE
# ============================================================

# Function: show_help
# Purpose: Display comprehensive help information
show_help() {
    cat << 'EOF'
═══════════════════════════════════════════════════════════════════
  manage.sh - Ghostty Configuration Repository Management
═══════════════════════════════════════════════════════════════════

USAGE:
    ./manage.sh <command> [options] [arguments]

COMMANDS:
    install         Install complete Ghostty terminal environment
    docs            Documentation management operations
    screenshots     Screenshot capture and gallery generation
    update          Update repository components
    validate        Run validation checks
    help            Show this help message
    version         Show version information

GLOBAL OPTIONS:
    --help, -h          Show help for command
    --version, -v       Show version information
    --verbose           Enable verbose output
    --quiet, -q         Suppress non-essential output
    --dry-run           Show what would be done without executing

ENVIRONMENT VARIABLES:
    MANAGE_DEBUG        Enable debug logging (0 or 1)
    MANAGE_NO_COLOR     Disable colored output (0 or 1)
    MANAGE_LOG_FILE     Path to log file for output
    MANAGE_BACKUP_DIR   Custom backup directory

EXAMPLES:
    # Show help for install command
    ./manage.sh install --help

    # Install with verbose output
    ./manage.sh install --verbose

    # Dry-run to see what would be installed
    ./manage.sh install --dry-run

    # Build documentation
    ./manage.sh docs build

    # Validate all configurations
    ./manage.sh validate

DOCUMENTATION:
    For detailed documentation, see:
    - README.md - Quick start and overview
    - docs-source/user-guide/ - User documentation
    - docs-source/developer/ - Developer guides

VERSION: ${VERSION} (${BUILD_DATE})

═══════════════════════════════════════════════════════════════════
EOF
}

# Function: show_version
# Purpose: Display version information
show_version() {
    cat << EOF
manage.sh version ${VERSION}
Build Date: ${BUILD_DATE}
Repository: Ghostty Configuration Files
Platform: $(uname -s) $(uname -m)
Bash Version: ${BASH_VERSION}
EOF
}

# ============================================================
# ARGUMENT PARSING
# ============================================================

# Global flags (set by parse_global_options)
VERBOSE=0
QUIET=0
DRY_RUN=0
SHOW_HELP=0
SHOW_VERSION=0

# Function: parse_global_options
# Purpose: Parse global options that apply to all commands
# Args: All command-line arguments
# Returns: 0 on success
# Side Effects: Sets global flag variables, removes parsed options from arguments
parse_global_options() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                SHOW_HELP=1
                shift
                ;;
            --version|-v)
                SHOW_VERSION=1
                shift
                ;;
            --verbose)
                VERBOSE=1
                export DEBUG=1
                shift
                ;;
            --quiet|-q)
                QUIET=1
                shift
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            -*)
                log_error "Unknown global option: $1"
                echo "Use --help to see available options" >&2
                return 2
                ;;
            *)
                # Not a global option, stop parsing
                break
                ;;
        esac
    done

    # Return remaining arguments
    echo "$@"
    return 0
}

# ============================================================
# COMMAND ROUTING
# ============================================================

# Function: route_command
# Purpose: Route to appropriate command handler
# Args: $1=command, $@=remaining arguments
# Returns: Exit code from command handler
route_command() {
    local command="${1:-}"

    if [[ -z "$command" ]]; then
        log_error "No command specified"
        echo ""
        show_help
        return 2
    fi

    # Check for help or version flags
    if [[ "$SHOW_HELP" -eq 1 ]]; then
        show_help
        return 0
    fi

    if [[ "$SHOW_VERSION" -eq 1 ]]; then
        show_version
        return 0
    fi

    # Route to command handler
    case "$command" in
        install)
            shift  # Remove 'install' from arguments
            cmd_install "$@"
            ;;
        docs)
            shift  # Remove 'docs' from arguments
            cmd_docs "$@"
            ;;
        screenshots)
            shift  # Remove 'screenshots' from arguments
            cmd_screenshots "$@"
            ;;
        update)
            shift  # Remove 'update' from arguments
            cmd_update "$@"
            ;;
        validate)
            shift  # Remove 'validate' from arguments
            cmd_validate "$@"
            ;;
        help)
            show_help
            return 0
            ;;
        version)
            show_version
            return 0
            ;;
        *)
            log_error "Unknown command: $command"
            echo ""
            echo "Available commands: install, docs, screenshots, update, validate, help, version"
            echo "Use './manage.sh --help' for more information"
            return 2
            ;;
    esac
}

# ============================================================
# COMMAND HANDLERS (Stubs - will be implemented in later tasks)
# ============================================================

# Function: cmd_install
# Purpose: Install complete Ghostty terminal environment
# Args: Command-specific arguments
# Returns: 0 on success, 1 on failure
cmd_install() {
    show_progress "start" "Install command (not yet implemented)"
    log_info "This command will be implemented in tasks T021-T023"
    show_progress "info" "Use './manage.sh install --help' for options once implemented"
    return 0
}

# Function: cmd_docs
# Purpose: Documentation management operations
# Args: $1=subcommand (build|dev|generate), $@=options
# Returns: 0 on success, 1 on failure
cmd_docs() {
    local subcommand="${1:-}"

    if [[ -z "$subcommand" ]]; then
        log_error "Docs subcommand required: build, dev, or generate"
        return 2
    fi

    case "$subcommand" in
        build|dev|generate)
            show_progress "start" "Docs $subcommand command (not yet implemented)"
            log_info "This command will be implemented in tasks T024-T026"
            ;;
        *)
            log_error "Unknown docs subcommand: $subcommand"
            echo "Available subcommands: build, dev, generate"
            return 2
            ;;
    esac

    return 0
}

# Function: cmd_screenshots
# Purpose: Screenshot capture and gallery generation
# Args: $1=subcommand (capture|generate-gallery), $@=options
# Returns: 0 on success, 1 on failure
cmd_screenshots() {
    local subcommand="${1:-}"

    if [[ -z "$subcommand" ]]; then
        log_error "Screenshots subcommand required: capture or generate-gallery"
        return 2
    fi

    case "$subcommand" in
        capture|generate-gallery)
            show_progress "start" "Screenshots $subcommand command (not yet implemented)"
            log_info "This command will be implemented in tasks T027-T028"
            ;;
        *)
            log_error "Unknown screenshots subcommand: $subcommand"
            echo "Available subcommands: capture, generate-gallery"
            return 2
            ;;
    esac

    return 0
}

# Function: cmd_update
# Purpose: Update repository components
# Args: Command-specific arguments
# Returns: 0 on success, 1 on failure
cmd_update() {
    show_progress "start" "Update command (not yet implemented)"
    log_info "This command will be implemented in tasks T029-T030"
    return 0
}

# Function: cmd_validate
# Purpose: Run validation checks
# Args: Command-specific arguments
# Returns: 0 on success, 1 on failure
cmd_validate() {
    show_progress "start" "Validate command (not yet implemented)"
    log_info "This command will be implemented in tasks T031-T032"
    return 0
}

# ============================================================
# MAIN EXECUTION
# ============================================================

main() {
    # Load environment configuration
    load_environment_config

    # Handle version and help flags first
    for arg in "$@"; do
        case "$arg" in
            --version|-v)
                show_version
                exit 0
                ;;
            --help|-h)
                if [[ $# -eq 1 ]]; then
                    show_help
                    exit 0
                fi
                ;;
        esac
    done

    # Parse global options
    local remaining_args
    remaining_args=$(parse_global_options "$@") || exit $?

    # Convert remaining_args back to array
    eval set -- "$remaining_args"

    # Route to command handler
    route_command "$@"
}

# Execute main function with all arguments
main "$@"
exit $?
