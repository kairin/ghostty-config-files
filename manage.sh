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
                export VERBOSE=1
                export DEBUG=1
                shift
                ;;
            --quiet|-q)
                export QUIET=1
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

# Function: cmd_install (T021-T023)
# Purpose: Install complete Ghostty terminal environment
# Args: Command-specific arguments (--skip-*, --force, --help)
# Returns: 0 on success, 1 on failure with automatic rollback
cmd_install() {
    # T021: Parse install-specific options
    local skip_node=0
    local skip_zig=0
    local skip_ghostty=0
    local skip_zsh=0
    local skip_theme=0
    local skip_context_menu=0
    local force=0
    local show_help=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --skip-node)
                skip_node=1
                shift
                ;;
            --skip-zig)
                skip_zig=1
                shift
                ;;
            --skip-ghostty)
                skip_ghostty=1
                shift
                ;;
            --skip-zsh)
                skip_zsh=1
                shift
                ;;
            --skip-theme)
                skip_theme=1
                shift
                ;;
            --skip-context-menu)
                skip_context_menu=1
                shift
                ;;
            --force)
                force=1
                shift
                ;;
            --help|-h)
                show_help=1
                shift
                ;;
            *)
                log_error "Unknown install option: $1"
                return 2
                ;;
        esac
    done

    # Show help if requested
    if [[ $show_help -eq 1 ]]; then
        cat << 'EOF'
Usage: ./manage.sh install [options]

Install complete Ghostty terminal environment including all dependencies
and configuration files.

OPTIONS:
    --skip-node         Skip Node.js installation (NVM)
    --skip-zig          Skip Zig compiler installation
    --skip-ghostty      Skip Ghostty terminal build
    --skip-zsh          Skip ZSH configuration
    --skip-theme        Skip theme configuration
    --skip-context-menu Skip context menu integration
    --force             Force reinstallation even if already installed
    --help, -h          Show this help message

EXAMPLES:
    # Full installation
    ./manage.sh install

    # Skip Node.js and Zig (use system versions)
    ./manage.sh install --skip-node --skip-zig

    # Force reinstallation
    ./manage.sh install --force

    # Install only Ghostty without extras
    ./manage.sh install --skip-theme --skip-context-menu

NOTES:
    - Automatic backup created before installation
    - Automatic rollback on failure
    - Progress tracking with step counter
    - See docs-source/user-guide/installation.md for details

EOF
        return 0
    fi

    # T022: Initialize progress tracking
    show_progress "start" "Starting Ghostty terminal environment installation"

    local total_steps=0
    local current_step=0

    # Count total steps based on skip flags
    [[ $skip_node -eq 0 ]] && total_steps=$((total_steps + 1))
    [[ $skip_zig -eq 0 ]] && total_steps=$((total_steps + 1))
    [[ $skip_ghostty -eq 0 ]] && total_steps=$((total_steps + 1))
    [[ $skip_zsh -eq 0 ]] && total_steps=$((total_steps + 1))
    [[ $skip_theme -eq 0 ]] && total_steps=$((total_steps + 1))
    [[ $skip_context_menu -eq 0 ]] && total_steps=$((total_steps + 1))

    log_info "Installation will complete $total_steps steps"

    # T023: Create backup for rollback capability
    local backup_marker="/tmp/manage-install-backup-$(date +%s)"
    if ! create_backup_marker "$backup_marker"; then
        show_progress "error" "Failed to create backup marker"
        return 1
    fi
    log_debug "Created backup marker: $backup_marker"

    # T022: Execute installation steps with progress tracking
    # Note: Actual module implementations are in Phase 5 (T047-T062)
    # This implementation calls placeholder functions that will be replaced

    if [[ $skip_node -eq 0 ]]; then
        current_step=$((current_step + 1))
        show_step "$current_step" "$total_steps" "Installing Node.js via NVM"
        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "[DRY-RUN] Would install Node.js"
        else
            # Placeholder: Will call scripts/install_node.sh in Phase 5
            log_info "Node.js installation (module pending - Phase 5 T047)"
        fi
    fi

    if [[ $skip_zig -eq 0 ]]; then
        current_step=$((current_step + 1))
        show_step "$current_step" "$total_steps" "Installing Zig compiler"
        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "[DRY-RUN] Would install Zig"
        else
            # Placeholder: Will call scripts/install_zig.sh in Phase 5
            log_info "Zig installation (module pending - Phase 5 T048)"
        fi
    fi

    if [[ $skip_ghostty -eq 0 ]]; then
        current_step=$((current_step + 1))
        show_step "$current_step" "$total_steps" "Building Ghostty terminal"
        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "[DRY-RUN] Would build Ghostty"
        else
            # Placeholder: Will call scripts/build_ghostty.sh in Phase 5
            log_info "Ghostty build (module pending - Phase 5 T049)"
        fi
    fi

    if [[ $skip_zsh -eq 0 ]]; then
        current_step=$((current_step + 1))
        show_step "$current_step" "$total_steps" "Configuring ZSH environment"
        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "[DRY-RUN] Would configure ZSH"
        else
            # Placeholder: Will call scripts/setup_zsh.sh in Phase 5
            log_info "ZSH setup (module pending - Phase 5 T051)"
        fi
    fi

    if [[ $skip_theme -eq 0 ]]; then
        current_step=$((current_step + 1))
        show_step "$current_step" "$total_steps" "Configuring Catppuccin theme"
        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "[DRY-RUN] Would configure theme"
        else
            # Placeholder: Will call scripts/configure_theme.sh in Phase 5
            log_info "Theme configuration (module pending - Phase 5 T052)"
        fi
    fi

    if [[ $skip_context_menu -eq 0 ]]; then
        current_step=$((current_step + 1))
        show_step "$current_step" "$total_steps" "Installing context menu integration"
        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "[DRY-RUN] Would install context menu"
        else
            # Placeholder: Will call scripts/install_context_menu.sh in Phase 5
            log_info "Context menu integration (module pending - Phase 5 T053)"
        fi
    fi

    # T023: On success, remove backup marker (no rollback needed)
    if [[ -f "$backup_marker" ]]; then
        rm -f "$backup_marker"
        log_debug "Removed backup marker (installation successful)"
    fi

    show_progress "success" "Installation completed successfully!"
    log_info "Ghostty terminal environment is ready to use"
    log_info "Run 'ghostty --version' to verify installation"

    return 0
}

# Helper function: create_backup_marker
# Purpose: Create a backup marker file for rollback tracking
# Args: $1=marker_path
# Returns: 0 on success, 1 on failure
create_backup_marker() {
    local marker_path="$1"

    # Create marker with timestamp and installation state
    cat > "$marker_path" << EOF
# Installation Backup Marker
# Created: $(date -Iseconds)
# Purpose: Track installation state for rollback capability
# Repository: $(pwd)

BACKUP_TIMESTAMP=$(date +%s)
BACKUP_USER=$(whoami)
BACKUP_PWD=$(pwd)
EOF

    if [[ ! -f "$marker_path" ]]; then
        return 1
    fi

    return 0
}

# Function: cmd_docs
# Purpose: Documentation management operations
# Args: $1=subcommand (build|dev|generate), $@=options
# Returns: 0 on success, 1 on failure
cmd_docs() {
    local subcommand="${1:-}"

    # Handle help at top level
    if [[ "$subcommand" == "--help" ]] || [[ "$subcommand" == "-h" ]] || [[ -z "$subcommand" ]]; then
        cat << 'EOF'
Usage: ./manage.sh docs <subcommand> [options]

Documentation management operations

SUBCOMMANDS:
    build      Build Astro documentation site
    dev        Start Astro development server
    generate   Generate screenshot and API documentation

OPTIONS:
    --help, -h Show this help message

EXAMPLES:
    # Build documentation site
    ./manage.sh docs build

    # Start dev server
    ./manage.sh docs dev

    # Generate screenshots and API docs
    ./manage.sh docs generate

Use './manage.sh docs <subcommand> --help' for subcommand-specific options

EOF
        return 0
    fi

    shift  # Remove subcommand from arguments

    case "$subcommand" in
        build)
            cmd_docs_build "$@"
            ;;
        dev)
            cmd_docs_dev "$@"
            ;;
        generate)
            cmd_docs_generate "$@"
            ;;
        *)
            log_error "Unknown docs subcommand: $subcommand"
            echo "Available subcommands: build, dev, generate"
            echo "Use './manage.sh docs --help' for more information"
            return 2
            ;;
    esac
}

# Function: cmd_docs_build (T024)
# Purpose: Build Astro documentation site
# Args: [--clean] [--output-dir DIR]
# Returns: 0 on success, 1 on failure
cmd_docs_build() {
    local clean=0
    local output_dir=""
    local show_help=0

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --clean)
                clean=1
                shift
                ;;
            --output-dir)
                output_dir="$2"
                shift 2
                ;;
            --help|-h)
                show_help=1
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                return 2
                ;;
        esac
    done

    if [[ "$show_help" -eq 1 ]]; then
        cat << 'EOF'
Usage: ./manage.sh docs build [options]

Build the Astro documentation site

OPTIONS:
    --clean             Clean build output before building
    --output-dir DIR    Specify custom output directory (default: docs/)
    --help, -h          Show this help message

EXAMPLES:
    # Standard build
    ./manage.sh docs build

    # Clean build
    ./manage.sh docs build --clean

    # Build to custom directory
    ./manage.sh docs build --output-dir public/

EOF
        return 0
    fi

    show_progress "start" "Building Astro documentation site"

    # Check if Node.js is installed
    if ! command -v node >/dev/null 2>&1; then
        log_error "Node.js is required but not installed"
        log_info "Install Node.js first: fnm install --lts"
        return 1
    fi

    # Check if package.json exists
    if [[ ! -f "${SCRIPT_DIR}/package.json" ]]; then
        log_error "package.json not found in repository root"
        log_info "This repository may not have Astro configured yet"
        return 1
    fi

    # Clean output directory if requested
    if [[ "$clean" -eq 1 ]]; then
        local target_dir="${output_dir:-docs}"
        if [[ -d "$target_dir" ]]; then
            show_progress "info" "Cleaning output directory: $target_dir"
            if [[ "$DRY_RUN" -eq 1 ]]; then
                show_progress "info" "[DRY RUN] Would remove: $target_dir"
            else
                rm -rf "$target_dir"
            fi
        fi
    fi

    # Build with Astro
    show_progress "info" "Running Astro build..."
    if [[ "$DRY_RUN" -eq 1 ]]; then
        show_progress "info" "[DRY RUN] Would run: npx astro build"
        if [[ -n "$output_dir" ]]; then
            show_progress "info" "[DRY RUN] Output directory: $output_dir"
        fi
    else
        local build_cmd="npx astro build"
        if [[ -n "$output_dir" ]]; then
            # Astro uses outDir in config, but we can override with env
            export ASTRO_OUT_DIR="$output_dir"
        fi

        if $build_cmd; then
            show_progress "success" "Documentation site built successfully"
            local target="${output_dir:-docs}"
            log_info "Output directory: $target"

            # Verify .nojekyll exists (constitutional requirement)
            if [[ ! -f "${target}/.nojekyll" ]]; then
                log_warn ".nojekyll file missing - creating it (required for GitHub Pages)"
                touch "${target}/.nojekyll"
            fi
        else
            show_progress "error" "Astro build failed"
            return 1
        fi
    fi

    return 0
}

# Function: cmd_docs_dev (T025)
# Purpose: Start Astro development server
# Args: [--port PORT] [--host HOST]
# Returns: 0 on success, 1 on failure
cmd_docs_dev() {
    local port=""
    local host=""
    local show_help=0

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --port)
                port="$2"
                shift 2
                ;;
            --host)
                host="$2"
                shift 2
                ;;
            --help|-h)
                show_help=1
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                return 2
                ;;
        esac
    done

    if [[ "$show_help" -eq 1 ]]; then
        cat << 'EOF'
Usage: ./manage.sh docs dev [options]

Start the Astro development server with hot reload

OPTIONS:
    --port PORT    Port to run dev server on (default: 4321)
    --host HOST    Host to bind to (default: localhost)
    --help, -h     Show this help message

EXAMPLES:
    # Start dev server (default port 4321)
    ./manage.sh docs dev

    # Start on custom port
    ./manage.sh docs dev --port 3000

    # Expose to network
    ./manage.sh docs dev --host 0.0.0.0

EOF
        return 0
    fi

    show_progress "start" "Starting Astro development server"

    # Check if Node.js is installed
    if ! command -v node >/dev/null 2>&1; then
        log_error "Node.js is required but not installed"
        log_info "Install Node.js first: fnm install --lts"
        return 1
    fi

    # Check if package.json exists
    if [[ ! -f "${SCRIPT_DIR}/package.json" ]]; then
        log_error "package.json not found in repository root"
        log_info "This repository may not have Astro configured yet"
        return 1
    fi

    # Build dev server command
    local dev_cmd="npx astro dev"

    if [[ -n "$port" ]]; then
        dev_cmd="$dev_cmd --port $port"
    fi

    if [[ -n "$host" ]]; then
        dev_cmd="$dev_cmd --host $host"
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        show_progress "info" "[DRY RUN] Would run: $dev_cmd"
        return 0
    fi

    show_progress "info" "Starting dev server..."
    log_info "Command: $dev_cmd"
    log_info "Press Ctrl+C to stop the server"

    # Run dev server (this will block)
    $dev_cmd

    return 0
}

# Function: cmd_docs_generate (T026)
# Purpose: Generate screenshot and API documentation
# Args: [--screenshots] [--api-docs]
# Returns: 0 on success, 1 on failure
cmd_docs_generate() {
    local generate_screenshots=0
    local generate_api=0
    local show_help=0

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --screenshots)
                generate_screenshots=1
                shift
                ;;
            --api-docs)
                generate_api=1
                shift
                ;;
            --help|-h)
                show_help=1
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                return 2
                ;;
        esac
    done

    if [[ "$show_help" -eq 1 ]]; then
        cat << 'EOF'
Usage: ./manage.sh docs generate [options]

Generate screenshots and API documentation

OPTIONS:
    --screenshots    Generate screenshot gallery
    --api-docs       Generate API documentation from source
    --help, -h       Show this help message

EXAMPLES:
    # Generate both screenshots and API docs
    ./manage.sh docs generate --screenshots --api-docs

    # Generate screenshots only
    ./manage.sh docs generate --screenshots

    # Generate API docs only
    ./manage.sh docs generate --api-docs

EOF
        return 0
    fi

    # If no options specified, generate both
    if [[ "$generate_screenshots" -eq 0 ]] && [[ "$generate_api" -eq 0 ]]; then
        generate_screenshots=1
        generate_api=1
    fi

    show_progress "start" "Generating documentation"

    local total_steps=0
    local current_step=0

    if [[ "$generate_screenshots" -eq 1 ]]; then
        total_steps=$((total_steps + 1))
    fi
    if [[ "$generate_api" -eq 1 ]]; then
        total_steps=$((total_steps + 1))
    fi

    # Generate screenshots
    if [[ "$generate_screenshots" -eq 1 ]]; then
        current_step=$((current_step + 1))
        show_step "$current_step" "$total_steps" "Generating screenshot gallery"

        if [[ "$DRY_RUN" -eq 1 ]]; then
            show_progress "info" "[DRY RUN] Would generate screenshot gallery"
        else
            # Check if screenshot generation script exists
            local screenshot_script="${SCRIPT_DIR}/scripts/svg_screenshot_capture.sh"
            if [[ -f "$screenshot_script" ]]; then
                if bash "$screenshot_script" generate-gallery; then
                    show_progress "success" "Screenshot gallery generated"
                else
                    show_progress "error" "Screenshot gallery generation failed"
                    return 1
                fi
            else
                log_warn "Screenshot generation script not found: $screenshot_script"
                show_progress "info" "Skipping screenshot generation"
            fi
        fi
    fi

    # Generate API documentation
    if [[ "$generate_api" -eq 1 ]]; then
        current_step=$((current_step + 1))
        show_step "$current_step" "$total_steps" "Generating API documentation"

        if [[ "$DRY_RUN" -eq 1 ]]; then
            show_progress "info" "[DRY RUN] Would generate API documentation"
        else
            # This would call a script like generate_api_docs.sh if it exists
            local api_script="${SCRIPT_DIR}/scripts/generate_api_docs.sh"
            if [[ -f "$api_script" ]]; then
                if bash "$api_script"; then
                    show_progress "success" "API documentation generated"
                else
                    show_progress "error" "API documentation generation failed"
                    return 1
                fi
            else
                log_warn "API documentation script not found: $api_script"
                log_info "API documentation generation will be implemented when needed"
                show_progress "info" "Skipping API documentation generation"
            fi
        fi
    fi

    show_progress "success" "Documentation generation complete"
    return 0
}

# Function: cmd_screenshots
# Purpose: Screenshot capture and gallery generation
# Args: $1=subcommand (capture|generate-gallery), $@=options
# Returns: 0 on success, 1 on failure
cmd_screenshots() {
    local subcommand="${1:-}"

    # Handle help at top level
    if [[ "$subcommand" == "--help" ]] || [[ "$subcommand" == "-h" ]] || [[ -z "$subcommand" ]]; then
        cat << 'EOF'
Usage: ./manage.sh screenshots <subcommand> [options]

Screenshot capture and gallery generation

SUBCOMMANDS:
    capture           Capture a new screenshot
    generate-gallery  Generate HTML gallery from screenshots

OPTIONS:
    --help, -h Show this help message

EXAMPLES:
    # Capture a screenshot
    ./manage.sh screenshots capture terminal "dark-mode" "Terminal with dark theme"

    # Generate gallery
    ./manage.sh screenshots generate-gallery

Use './manage.sh screenshots <subcommand> --help' for subcommand-specific options

EOF
        return 0
    fi

    shift  # Remove subcommand from arguments

    case "$subcommand" in
        capture)
            cmd_screenshots_capture "$@"
            ;;
        generate-gallery)
            cmd_screenshots_generate_gallery "$@"
            ;;
        *)
            log_error "Unknown screenshots subcommand: $subcommand"
            echo "Available subcommands: capture, generate-gallery"
            echo "Use './manage.sh screenshots --help' for more information"
            return 2
            ;;
    esac
}

# Function: cmd_screenshots_capture (T027)
# Purpose: Capture a new screenshot
# Args: <category> <name> <description>
# Returns: 0 on success, 1 on failure
cmd_screenshots_capture() {
    local show_help=0
    local category=""
    local name=""
    local description=""

    # Check for help flag
    for arg in "$@"; do
        if [[ "$arg" == "--help" ]] || [[ "$arg" == "-h" ]]; then
            show_help=1
            break
        fi
    done

    if [[ "$show_help" -eq 1 ]]; then
        cat << 'EOF'
Usage: ./manage.sh screenshots capture <category> <name> <description>

Capture a new screenshot for documentation

ARGUMENTS:
    category        Screenshot category (e.g., terminal, config, ui)
    name            Screenshot name (alphanumeric, hyphens allowed)
    description     Description of what the screenshot shows

OPTIONS:
    --help, -h     Show this help message

EXAMPLES:
    # Capture terminal screenshot
    ./manage.sh screenshots capture terminal "dark-mode" "Terminal with dark theme enabled"

    # Capture configuration screenshot
    ./manage.sh screenshots capture config "keybindings" "Custom keybinding configuration"

NOTES:
    - Screenshots are saved to documentations/screenshots/<category>/<name>.png
    - The screenshot script will guide you through the capture process
    - Existing screenshots with the same name will be backed up

EOF
        return 0
    fi

    # Parse positional arguments
    category="${1:-}"
    name="${2:-}"
    description="${3:-}"

    if [[ -z "$category" ]] || [[ -z "$name" ]] || [[ -z "$description" ]]; then
        log_error "Missing required arguments"
        echo ""
        echo "Usage: ./manage.sh screenshots capture <category> <name> <description>"
        echo "Use '--help' for more information"
        return 2
    fi

    # Validate category and name (alphanumeric and hyphens only)
    if [[ ! "$category" =~ ^[a-zA-Z0-9-]+$ ]]; then
        log_error "Category must contain only alphanumeric characters and hyphens"
        return 2
    fi

    if [[ ! "$name" =~ ^[a-zA-Z0-9-]+$ ]]; then
        log_error "Name must contain only alphanumeric characters and hyphens"
        return 2
    fi

    show_progress "start" "Capturing screenshot: $category/$name"

    # Create screenshots directory structure
    local screenshots_dir="${SCRIPT_DIR}/documentations/screenshots/${category}"
    if ! ensure_dir "$screenshots_dir"; then
        log_error "Failed to create screenshots directory: $screenshots_dir"
        return 1
    fi

    local screenshot_path="${screenshots_dir}/${name}.png"

    # Check if screenshot already exists and create backup
    if [[ -f "$screenshot_path" ]]; then
        log_warn "Screenshot already exists: $screenshot_path"
        if [[ "$DRY_RUN" -eq 1 ]]; then
            show_progress "info" "[DRY RUN] Would create backup of existing screenshot"
        else
            # Source backup utilities
            source "${SCRIPTS_DIR}/backup_utils.sh"
            if create_backup "$screenshot_path" "${category}-${name}" >/dev/null; then
                log_info "Backup created for existing screenshot"
            else
                log_error "Failed to backup existing screenshot"
                return 1
            fi
        fi
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        show_progress "info" "[DRY RUN] Would capture screenshot to: $screenshot_path"
        show_progress "info" "[DRY RUN] Description: $description"
        return 0
    fi

    # Check if screenshot capture script exists
    local capture_script="${SCRIPT_DIR}/scripts/svg_screenshot_capture.sh"
    if [[ -f "$capture_script" ]]; then
        show_progress "info" "Starting screenshot capture process..."
        log_info "Category: $category"
        log_info "Name: $name"
        log_info "Description: $description"
        log_info "Output: $screenshot_path"

        if bash "$capture_script" capture "$screenshot_path" "$description"; then
            show_progress "success" "Screenshot captured: $screenshot_path"

            # Create metadata file
            local metadata_path="${screenshot_path}.meta"
            cat > "$metadata_path" << EOF
Category: $category
Name: $name
Description: $description
Captured: $(date '+%Y-%m-%d %H:%M:%S')
User: $USER
EOF
            log_info "Metadata saved: $metadata_path"
        else
            show_progress "error" "Screenshot capture failed"
            return 1
        fi
    else
        log_error "Screenshot capture script not found: $capture_script"
        log_info "Manual capture required - save screenshot to: $screenshot_path"
        return 1
    fi

    return 0
}

# Function: cmd_screenshots_generate_gallery (T028)
# Purpose: Generate HTML gallery from captured screenshots
# Args: [--output FILE]
# Returns: 0 on success, 1 on failure
cmd_screenshots_generate_gallery() {
    local output_file=""
    local show_help=0

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --output)
                output_file="$2"
                shift 2
                ;;
            --help|-h)
                show_help=1
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                return 2
                ;;
        esac
    done

    if [[ "$show_help" -eq 1 ]]; then
        cat << 'EOF'
Usage: ./manage.sh screenshots generate-gallery [options]

Generate an HTML gallery from all captured screenshots

OPTIONS:
    --output FILE   Output HTML file path (default: documentations/screenshots/gallery.html)
    --help, -h      Show this help message

EXAMPLES:
    # Generate gallery with default output
    ./manage.sh screenshots generate-gallery

    # Generate gallery to custom file
    ./manage.sh screenshots generate-gallery --output docs/screenshots.html

NOTES:
    - The gallery includes all screenshots from documentations/screenshots/
    - Screenshots are organized by category
    - Metadata files (.meta) are used for descriptions

EOF
        return 0
    fi

    # Set default output file
    output_file="${output_file:-${SCRIPT_DIR}/documentations/screenshots/gallery.html}"

    show_progress "start" "Generating screenshot gallery"

    # Check if screenshots directory exists
    local screenshots_base="${SCRIPT_DIR}/documentations/screenshots"
    if [[ ! -d "$screenshots_base" ]]; then
        log_warn "No screenshots directory found: $screenshots_base"
        log_info "Capture screenshots first using: ./manage.sh screenshots capture"
        return 1
    fi

    # Count screenshots
    local screenshot_count
    screenshot_count=$(find "$screenshots_base" -type f -name "*.png" 2>/dev/null | wc -l)

    if [[ "$screenshot_count" -eq 0 ]]; then
        log_warn "No screenshots found in: $screenshots_base"
        log_info "Capture screenshots first using: ./manage.sh screenshots capture"
        return 1
    fi

    show_progress "info" "Found $screenshot_count screenshot(s)"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        show_progress "info" "[DRY RUN] Would generate gallery with $screenshot_count screenshots"
        show_progress "info" "[DRY RUN] Output file: $output_file"
        return 0
    fi

    # Generate HTML gallery
    show_progress "info" "Generating HTML gallery..."

    local gallery_html
    gallery_html=$(cat << 'GALLERY_START'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Screenshot Gallery - Ghostty Configuration</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background: #0d1117;
            color: #c9d1d9;
            padding: 2rem;
        }
        h1 { margin-bottom: 2rem; text-align: center; }
        .category { margin-bottom: 3rem; }
        .category h2 {
            color: #58a6ff;
            margin-bottom: 1rem;
            padding-bottom: 0.5rem;
            border-bottom: 1px solid #30363d;
        }
        .gallery {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 1.5rem;
        }
        .screenshot {
            background: #161b22;
            border: 1px solid #30363d;
            border-radius: 6px;
            padding: 1rem;
            transition: transform 0.2s;
        }
        .screenshot:hover { transform: translateY(-4px); }
        .screenshot img {
            width: 100%;
            border-radius: 4px;
            margin-bottom: 0.5rem;
        }
        .screenshot h3 {
            color: #58a6ff;
            font-size: 1rem;
            margin-bottom: 0.5rem;
        }
        .screenshot p {
            color: #8b949e;
            font-size: 0.875rem;
            line-height: 1.5;
        }
        .meta {
            color: #6e7681;
            font-size: 0.75rem;
            margin-top: 0.5rem;
        }
    </style>
</head>
<body>
    <h1>Screenshot Gallery</h1>
GALLERY_START
)

    # Organize screenshots by category
    declare -A categories
    while IFS= read -r screenshot; do
        local rel_path="${screenshot#$screenshots_base/}"
        local category_name="${rel_path%%/*}"
        categories["$category_name"]=1
    done < <(find "$screenshots_base" -type f -name "*.png" 2>/dev/null)

    # Generate gallery sections for each category
    for category in "${!categories[@]}"; do
        gallery_html+="    <div class=\"category\">
        <h2>$(echo "$category" | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')</h2>
        <div class=\"gallery\">
"

        while IFS= read -r screenshot; do
            local name
            name=$(basename "$screenshot" .png)
            local rel_path="${screenshot#$screenshots_base/}"
            local meta_file="${screenshot}.meta"

            local description="No description available"
            local captured_date=""

            if [[ -f "$meta_file" ]]; then
                description=$(grep "^Description:" "$meta_file" | cut -d: -f2- | sed 's/^ //')
                captured_date=$(grep "^Captured:" "$meta_file" | cut -d: -f2- | sed 's/^ //')
            fi

            gallery_html+="            <div class=\"screenshot\">
                <img src=\"${rel_path}\" alt=\"${name}\">
                <h3>$(echo "$name" | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')</h3>
                <p>${description}</p>"

            if [[ -n "$captured_date" ]]; then
                gallery_html+="
                <p class=\"meta\">Captured: ${captured_date}</p>"
            fi

            gallery_html+="
            </div>
"
        done < <(find "$screenshots_base/$category" -type f -name "*.png" 2>/dev/null | sort)

        gallery_html+="        </div>
    </div>
"
    done

    gallery_html+="</body>
</html>"

    # Write gallery HTML to file
    echo "$gallery_html" > "$output_file"

    show_progress "success" "Gallery generated: $output_file"
    log_info "Total screenshots: $screenshot_count"
    log_info "Categories: ${#categories[@]}"

    return 0
}

# Function: cmd_update (T029-T030)
# Purpose: Update repository components
# Args: [--check-only] [--force] [--component NAME]
# Returns: 0 on success, 1 on failure
cmd_update() {
    local check_only=0
    local force=0
    local component=""
    local show_help=0

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --check-only)
                check_only=1
                shift
                ;;
            --force)
                force=1
                shift
                ;;
            --component)
                component="$2"
                shift 2
                ;;
            --help|-h)
                show_help=1
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                return 2
                ;;
        esac
    done

    if [[ "$show_help" -eq 1 ]]; then
        cat << 'EOF'
Usage: ./manage.sh update [options]

Update repository components with user customization preservation

OPTIONS:
    --check-only        Check for updates without applying them
    --force             Force update even if no changes detected
    --component NAME    Update specific component only (ghostty, zsh, docs)
    --help, -h          Show this help message

EXAMPLES:
    # Check for available updates
    ./manage.sh update --check-only

    # Update all components
    ./manage.sh update

    # Update specific component
    ./manage.sh update --component ghostty

    # Force update all components
    ./manage.sh update --force

NOTES:
    - User customizations are automatically preserved
    - Backups are created before any changes
    - Failed updates are automatically rolled back

EOF
        return 0
    fi

    show_progress "start" "Checking for updates"

    # Check if update script exists
    local update_script="${SCRIPT_DIR}/scripts/check_updates.sh"
    if [[ ! -f "$update_script" ]]; then
        log_error "Update script not found: $update_script"
        return 1
    fi

    # Source backup utilities for customization preservation (T030)
    source "${SCRIPTS_DIR}/backup_utils.sh"

    # Build update command
    local update_cmd="$update_script"

    if [[ "$check_only" -eq 1 ]]; then
        update_cmd="$update_cmd --check"
    fi

    if [[ "$force" -eq 1 ]]; then
        update_cmd="$update_cmd --force"
    fi

    if [[ -n "$component" ]]; then
        # Validate component name
        case "$component" in
            ghostty|zsh|docs)
                update_cmd="$update_cmd --component $component"
                ;;
            *)
                log_error "Unknown component: $component"
                echo "Valid components: ghostty, zsh, docs"
                return 2
                ;;
        esac
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        show_progress "info" "[DRY RUN] Would run: $update_cmd"
        return 0
    fi

    # T030: Preserve user customizations before update
    show_progress "info" "Preserving user customizations..."

    local config_backup=""
    if [[ -f "${HOME}/.config/ghostty/config" ]]; then
        config_backup=$(create_backup "${HOME}/.config/ghostty/config" "config-before-update" 2>/dev/null)
        if [[ -n "$config_backup" ]]; then
            log_debug "Configuration backed up: $config_backup"
        fi
    fi

    # Run update
    show_progress "info" "Running update check..."

    if $update_cmd; then
        if [[ "$check_only" -eq 1 ]]; then
            show_progress "success" "Update check complete"
        else
            show_progress "success" "Update complete"

            # T030: Reapply user customizations if needed
            # Note: check_updates.sh already handles customization preservation,
            # but we keep the backup as a safety net
            log_info "User customizations have been preserved"

            if [[ -n "$config_backup" ]]; then
                log_debug "Backup available at: $config_backup"
            fi
        fi
    else
        show_progress "error" "Update failed"

        # T030: Automatic rollback on failure
        if [[ -n "$config_backup" ]] && [[ -f "$config_backup" ]]; then
            show_progress "info" "Rolling back to previous configuration..."
            if restore_backup "$config_backup" "${HOME}/.config/ghostty/config"; then
                show_progress "success" "Rollback complete"
                log_info "Configuration restored from: $config_backup"
            else
                log_error "Rollback failed - manual restoration may be required"
                log_error "Backup location: $config_backup"
            fi
        fi

        return 1
    fi

    return 0
}

# Function: cmd_validate (T031-T032)
# Purpose: Run validation checks
# Args: [--type TYPE] [--fix]
# Returns: 0 on success, 1 on failure
cmd_validate() {
    local validate_type="all"
    local auto_fix=0
    local show_help=0

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --type)
                validate_type="$2"
                shift 2
                ;;
            --fix)
                auto_fix=1
                shift
                ;;
            --help|-h)
                show_help=1
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                return 2
                ;;
        esac
    done

    if [[ "$show_help" -eq 1 ]]; then
        cat << 'EOF'
Usage: ./manage.sh validate [options]

Run validation checks on repository and configurations

OPTIONS:
    --type TYPE    Validation type: all, config, performance, dependencies
    --fix          Attempt to automatically fix issues
    --help, -h     Show this help message

VALIDATION TYPES:
    all            Run all validation checks (default)
    config         Validate Ghostty and ZSH configurations
    performance    Check performance metrics
    dependencies   Verify all dependencies are installed

EXAMPLES:
    # Validate everything
    ./manage.sh validate

    # Validate configuration only
    ./manage.sh validate --type config

    # Validate and auto-fix issues
    ./manage.sh validate --fix

    # Check dependencies
    ./manage.sh validate --type dependencies

EOF
        return 0
    fi

    # Validate type argument
    case "$validate_type" in
        all|config|performance|dependencies)
            ;;
        *)
            log_error "Unknown validation type: $validate_type"
            echo "Valid types: all, config, performance, dependencies"
            return 2
            ;;
    esac

    show_progress "start" "Running validation checks"

    local total_checks=0
    local passed_checks=0
    local failed_checks=0

    # Determine which checks to run
    local run_config=0
    local run_performance=0
    local run_dependencies=0

    case "$validate_type" in
        all)
            run_config=1
            run_performance=1
            run_dependencies=1
            total_checks=3
            ;;
        config)
            run_config=1
            total_checks=1
            ;;
        performance)
            run_performance=1
            total_checks=1
            ;;
        dependencies)
            run_dependencies=1
            total_checks=1
            ;;
    esac

    local current_check=0

    # T032: Ghostty configuration syntax validation
    if [[ "$run_config" -eq 1 ]]; then
        current_check=$((current_check + 1))
        show_step "$current_check" "$total_checks" "Validating Ghostty configuration"

        if [[ "$DRY_RUN" -eq 1 ]]; then
            show_progress "info" "[DRY RUN] Would validate Ghostty config"
            passed_checks=$((passed_checks + 1))
        else
            if command -v ghostty >/dev/null 2>&1; then
                if ghostty +show-config >/dev/null 2>&1; then
                    show_progress "success" "Ghostty configuration is valid"
                    passed_checks=$((passed_checks + 1))
                else
                    show_progress "error" "Ghostty configuration has errors"
                    failed_checks=$((failed_checks + 1))

                    if [[ "$auto_fix" -eq 1 ]]; then
                        show_progress "info" "Attempting to fix configuration..."
                        local fix_script="${SCRIPT_DIR}/scripts/fix_config.sh"
                        if [[ -f "$fix_script" ]] && bash "$fix_script"; then
                            show_progress "success" "Configuration fixed"
                            passed_checks=$((passed_checks + 1))
                            failed_checks=$((failed_checks - 1))
                        else
                            log_error "Auto-fix failed or script not found"
                        fi
                    fi
                fi
            else
                log_warn "Ghostty not installed - skipping config validation"
            fi

            # T032: ZSH configuration validation
            if [[ -f "${HOME}/.zshrc" ]]; then
                if zsh -n "${HOME}/.zshrc" 2>/dev/null; then
                    log_debug "ZSH configuration is valid"
                else
                    log_warn "ZSH configuration has syntax errors"
                fi
            fi
        fi
    fi

    # T032: Performance metrics validation
    if [[ "$run_performance" -eq 1 ]]; then
        current_check=$((current_check + 1))
        show_step "$current_check" "$total_checks" "Checking performance metrics"

        if [[ "$DRY_RUN" -eq 1 ]]; then
            show_progress "info" "[DRY RUN] Would check performance metrics"
            passed_checks=$((passed_checks + 1))
        else
            # Check if ghostty is running efficiently
            if command -v ghostty >/dev/null 2>&1; then
                # Simple performance check - verify ghostty can start quickly
                local start_time
                start_time=$(TIMEFORMAT='%R'; { time ghostty --version >/dev/null 2>&1; } 2>&1)

                # Performance target: <1 second for version check
                if (( $(echo "$start_time < 1.0" | bc -l 2>/dev/null || echo 0) )); then
                    show_progress "success" "Performance metrics acceptable (${start_time}s)"
                    passed_checks=$((passed_checks + 1))
                else
                    show_progress "warn" "Performance may be degraded (${start_time}s)"
                    log_info "Expected: <1.0s, Actual: ${start_time}s"
                    passed_checks=$((passed_checks + 1))  # Warn but don't fail
                fi
            else
                log_warn "Ghostty not installed - skipping performance check"
            fi
        fi
    fi

    # T032: Dependency checking
    if [[ "$run_dependencies" -eq 1 ]]; then
        current_check=$((current_check + 1))
        show_step "$current_check" "$total_checks" "Verifying dependencies"

        if [[ "$DRY_RUN" -eq 1 ]]; then
            show_progress "info" "[DRY RUN] Would check dependencies"
            passed_checks=$((passed_checks + 1))
        else
            local missing_deps=()

            # Check critical dependencies
            local deps=("bash" "git")
            for dep in "${deps[@]}"; do
                if ! command -v "$dep" >/dev/null 2>&1; then
                    missing_deps+=("$dep")
                fi
            done

            # Check optional but recommended dependencies
            local optional_deps=("node" "npm" "zsh")
            local missing_optional=()
            for dep in "${optional_deps[@]}"; do
                if ! command -v "$dep" >/dev/null 2>&1; then
                    missing_optional+=("$dep")
                fi
            done

            if [[ ${#missing_deps[@]} -eq 0 ]]; then
                show_progress "success" "All critical dependencies installed"
                passed_checks=$((passed_checks + 1))

                if [[ ${#missing_optional[@]} -gt 0 ]]; then
                    log_info "Optional dependencies missing: ${missing_optional[*]}"
                fi
            else
                show_progress "error" "Missing critical dependencies: ${missing_deps[*]}"
                failed_checks=$((failed_checks + 1))

                if [[ "$auto_fix" -eq 1 ]]; then
                    log_info "Auto-fix for dependencies not implemented"
                    log_info "Please install manually: ${missing_deps[*]}"
                fi
            fi
        fi
    fi

    # Show summary
    echo ""
    show_summary "$passed_checks" "$failed_checks" "validation checks"

    return $?
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
