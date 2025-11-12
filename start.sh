#!/bin/bash

set -euo pipefail

# Comprehensive Start Script for Ghostty, Ptyxis, Claude Code, and Gemini CLI
# This script handles complete installation of all terminal tools and AI assistants

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"

# Advanced Session Tracking for Multiple Executions
# Creates synchronized session IDs for logs and screenshots with terminal detection
# Pattern: YYYYMMDD-HHMMSS-terminal-operation where terminal = ghostty|ptyxis|generic
DATETIME=$(date +"%Y%m%d-%H%M%S")

# Detect current terminal environment for session naming
DETECTED_TERMINAL="generic"
if [ -n "${GHOSTTY_RESOURCES_DIR:-}" ] || [ "${TERM_PROGRAM:-}" = "ghostty" ]; then
    DETECTED_TERMINAL="ghostty"
elif [ -n "${PTYXIS_VERSION:-}" ] || [ "${TERM_PROGRAM:-}" = "ptyxis" ] || pstree -p $$ 2>/dev/null | grep -q ptyxis; then
    DETECTED_TERMINAL="ptyxis"
elif [ -n "${GNOME_TERMINAL_SCREEN:-}" ]; then
    DETECTED_TERMINAL="gnome-terminal"
elif [ -n "${KONSOLE_VERSION:-}" ]; then
    DETECTED_TERMINAL="konsole"
fi

# Enhanced session ID with terminal detection
LOG_SESSION_ID="$DATETIME-$DETECTED_TERMINAL-install"

# Synchronized log and screenshot session structure
LOG_FILE="$LOG_DIR/$LOG_SESSION_ID.log"                    # Main human-readable log
LOG_JSON="$LOG_DIR/$LOG_SESSION_ID.json"                   # Structured JSON log for parsing
LOG_ERRORS="$LOG_DIR/$LOG_SESSION_ID-errors.log"           # Errors and warnings only
LOG_COMMANDS="$LOG_DIR/$LOG_SESSION_ID-commands.log"       # Full command outputs and results
LOG_PERFORMANCE="$LOG_DIR/$LOG_SESSION_ID-performance.json" # Performance metrics
LOG_SESSION_MANIFEST="$LOG_DIR/$LOG_SESSION_ID-manifest.json" # Complete session tracking

# Session Management Instructions:
# - View all sessions: ls -la $SCRIPT_DIR/logs/
# - View session logs: ls -la $LOG_DIR/$LOG_SESSION_ID*
# - Session manifest: jq '.' $LOG_SESSION_MANIFEST

REAL_HOME="${SUDO_HOME:-$HOME}"
# fnm (Fast Node Manager) - Constitutional Compliance (AGENTS.md line 23)
# 40x faster than NVM (<50ms vs 500ms-3s startup)
NODE_VERSION="lts/latest"  # fnm supports LTS selection

# Directories
GHOSTTY_APP_DIR="$REAL_HOME/Apps/ghostty"
GHOSTTY_CONFIG_DIR="$REAL_HOME/.config/ghostty"
GHOSTTY_CONFIG_SOURCE="$SCRIPT_DIR/configs/ghostty"
FNM_DIR="$REAL_HOME/.local/share/fnm"  # XDG-compliant
APPS_DIR="$REAL_HOME/Apps"

# Global variables for installation status and strategies
ghostty_installed=false
ghostty_version=""
ghostty_config_valid=false
ghostty_source=""
ptyxis_installed=false

# Failure tracking system
declare -a INSTALLATION_FAILURES=()
declare -a INSTALLATION_WARNINGS=()
declare -a INSTALLATION_SUCCESSES=()
ptyxis_version=""
ptyxis_source=""
GHOSTTY_STRATEGY=""
PTYXIS_STRATEGY=""
CONFIG_NEEDS_UPDATE=false

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Enhanced logging function with structured output
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color=""
    local prefix=""

    case "$level" in
        "ERROR") color="$RED"; prefix="❌" ;;
        "SUCCESS") color="$GREEN"; prefix="✅" ;;
        "WARNING") color="$YELLOW"; prefix="⚠️" ;;
        "INFO") color="$BLUE"; prefix="ℹ️" ;;
        "STEP") color="$CYAN"; prefix="🔧" ;;
        "DEBUG") color="$YELLOW"; prefix="🐛" ;;
        "TEST") color="$CYAN"; prefix="🧪" ;;
    esac

    # Console output with colors
    echo -e "${color}[$timestamp] [$level] $prefix $message${NC}"

    # Structured log file output (JSON-like for parsing)
    echo "{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"message\":\"$message\",\"function\":\"${FUNCNAME[1]:-main}\",\"line\":\"${BASH_LINENO[1]:-0}\"}" >> "$LOG_JSON"

    # Human-readable log file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"

    # Error log file for critical issues
    if [ "$level" = "ERROR" ] || [ "$level" = "WARNING" ]; then
        echo "[$timestamp] [$level] [${FUNCNAME[1]:-main}:${BASH_LINENO[1]:-0}] $message" >> "$LOG_ERRORS"
    fi
}

# Debug logging (only shown if VERBOSE=true)
debug() {
    if $VERBOSE; then
        log "DEBUG" "$@"
    else
        # Still log to file even if not shown
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "[$timestamp] [DEBUG] $*" >> "$LOG_FILE"
    fi
}

# Enhanced command execution with debug mode support
run_command() {
    local description="$1"
    local command="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if $DEBUG_MODE; then
        log "INFO" "🔧 $description"
        log "DEBUG" "Command: $command"
        echo "[$timestamp] [COMMAND_FULL] $command" >> "$LOG_COMMANDS"
        echo "[$timestamp] [COMMAND_START] $description" >> "$LOG_COMMANDS"

        # Show command and all output in debug mode
        echo -e "${YELLOW}► Running: $command${NC}"
        eval "$command" 2>&1 | tee -a "$LOG_COMMANDS" | sed 's/^/   /'
        local exit_code=${PIPESTATUS[0]}

        echo "[$timestamp] [COMMAND_EXIT] Exit code: $exit_code" >> "$LOG_COMMANDS"
        if [[ $exit_code -eq 0 ]]; then
            log "SUCCESS" "✅ $description"
        else
            log "ERROR" "❌ $description failed (exit: $exit_code)"
        fi
        return $exit_code
    else
        # Original behavior - hide output
        eval "$command" >> "$LOG_FILE" 2>&1
        return $?
    fi
}

# Screenshots disabled - text logging only
ENABLE_SCREENSHOTS="false"
SVG_CAPTURE_SCRIPT=""
SCREENSHOT_SESSION_DIR="/tmp/ghostty-screenshots-disabled"
SCREENSHOT_METADATA="/dev/null"

# Display stage-specific summary information for screenshots
display_stage_summary() {
    local stage_name="$1"

    case "$stage_name" in
        "Initial Desktop")
            echo "🖥️  Clean Ubuntu desktop environment"
            echo "🎯 Target: Install Ghostty terminal with modern tools"
            echo "📦 Components: Ghostty, ZSH, Node.js, Claude Code, Gemini CLI"
            ;;
        "System Check")
            echo "🔍 Checking existing installations..."
            if command -v ghostty >/dev/null 2>&1; then
                echo "✅ Ghostty: $(ghostty --version 2>/dev/null || echo 'Installed')"
            else
                echo "❌ Ghostty: Not installed"
            fi
            if command -v zsh >/dev/null 2>&1; then
                echo "✅ ZSH: $(zsh --version | cut -d' ' -f2)"
            else
                echo "❌ ZSH: Not installed"
            fi
            ;;
        "Dependencies")
            echo "📦 Installing system dependencies..."
            echo "🔧 Build tools, libraries, and development packages"
            echo "📋 Status: $(dpkg -l 2>/dev/null | grep -c "^ii") packages installed"
            ;;
        "ZSH Setup")
            echo "🐚 ZSH Shell Configuration"
            if [ -d "$HOME/.oh-my-zsh" ]; then
                echo "✅ Oh My ZSH: Installed"
            fi
            if [ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
                echo "✅ Powerlevel10k: Installed"
            fi
            echo "🎨 Theme: Modern terminal with git integration"
            ;;
        "Modern Tools")
            echo "⚡ Modern Unix Tool Replacements"
            command -v eza >/dev/null 2>&1 && echo "✅ eza: $(eza --version | head -1)"
            command -v bat >/dev/null 2>&1 && echo "✅ bat: $(bat --version | cut -d' ' -f2)"
            command -v rg >/dev/null 2>&1 && echo "✅ ripgrep: $(rg --version | head -1)"
            command -v fzf >/dev/null 2>&1 && echo "✅ fzf: $(fzf --version)"
            ;;
        "Zig Compiler")
            echo "⚡ Zig Programming Language"
            if command -v zig >/dev/null 2>&1; then
                echo "✅ Zig: $(zig version)"
                echo "🎯 Purpose: Required for building Ghostty from source"
            else
                echo "📥 Installing Zig 0.14.0..."
            fi
            ;;
        "Ghostty Build")
            echo "🏗️  Ghostty Terminal Compilation"
            if command -v ghostty >/dev/null 2>&1; then
                echo "✅ Ghostty: $(ghostty --version 2>/dev/null || echo 'Installed')"
            else
                echo "🔨 Building Ghostty from source with Zig..."
            fi
            echo "⚡ Optimizations: ReleaseFast build for performance"
            ;;
        "Configuration")
            echo "⚙️  Ghostty Configuration Setup"
            echo "📁 Config: ~/.config/ghostty/"
            echo "🎨 Themes: Catppuccin with auto light/dark switching"
            echo "⚡ Performance: 2025 optimizations enabled"
            ;;
        "Context Menu")
            echo "🖱️  Right-click Integration"
            echo "📂 Nautilus: 'Open in Ghostty' context menu"
            echo "🎯 Quick access from any folder"
            ;;
        "Ptyxis Terminal")
            echo "🔄 Secondary Terminal (Comparison)"
            if command -v ptyxis >/dev/null 2>&1; then
                echo "✅ Ptyxis: $(ptyxis --version 2>/dev/null | head -1 || echo 'Installed')"
            fi
            echo "🤖 Integrated with Gemini CLI"
            ;;
        "UV Package Manager")
            echo "🐍 Python Package Management"
            if command -v uv >/dev/null 2>&1; then
                echo "✅ uv: $(uv --version)"
            fi
            echo "⚡ Ultra-fast Python package installer and resolver"
            ;;
        "Node.js Setup")
            echo "📦 Node.js and NPM"
            if command -v node >/dev/null 2>&1; then
                echo "✅ Node.js: $(node --version)"
                echo "✅ NPM: $(npm --version)"
            fi
            echo "🎯 Required for AI CLI tools"
            ;;
        "Claude Code")
            echo "🤖 Claude Code CLI"
            if command -v claude >/dev/null 2>&1; then
                echo "✅ Claude: $(claude --version)"
            fi
            echo "💡 Anthropic's AI assistant for code"
            ;;
        "Gemini CLI")
            echo "💎 Google Gemini CLI"
            if command -v gemini >/dev/null 2>&1; then
                echo "✅ Gemini: Available"
            fi
            echo "🔗 Integrated with Ptyxis terminal"
            ;;
        "Verification")
            echo "✅ Installation Verification"
            echo "🔍 Testing all components..."
            echo "📊 Performance check and final validation"
            ;;
        "Completion")
            echo "🎉 Installation Complete!"
            echo "✅ All tools installed and configured"
            echo ""
            echo "📊 Final Status:"
            command -v ghostty >/dev/null 2>&1 && echo "  ✅ Ghostty: $(ghostty --version 2>/dev/null || echo 'Ready')"
            command -v zsh >/dev/null 2>&1 && echo "  ✅ ZSH: Default shell with Powerlevel10k"
            command -v claude >/dev/null 2>&1 && echo "  ✅ Claude Code: $(claude --version 2>/dev/null || echo 'Ready')"
            command -v node >/dev/null 2>&1 && echo "  ✅ Node.js: $(node --version 2>/dev/null)"
            echo ""
            echo "📁 Session: $LOG_SESSION_ID"
            if [ -f "$LOG_SESSION_MANIFEST" ]; then
                local duration=$(jq -r '.status.completed // empty' "$LOG_SESSION_MANIFEST" 2>/dev/null | head -1)
                [ -n "$duration" ] && echo "⏱️  Session completed: $(date -d "$duration" '+%H:%M:%S' 2>/dev/null || echo 'Recently')"
            fi
            echo "🚀 Shell restart will activate new configuration"
            ;;
        "Shell Restart")
            echo "🔄 Activating New Shell Environment"
            echo "✅ Installation completed successfully"
            echo ""
            echo "🐚 New Configuration:"
            echo "  ✅ ZSH with Oh My ZSH framework"
            echo "  ✅ Powerlevel10k theme with git integration"
            echo "  ✅ Modern tools (eza, bat, ripgrep, fzf)"
            echo "  ✅ AI tools (Claude Code, Gemini CLI)"
            echo ""
            echo "⚡ Restarting shell to activate configuration..."
            echo "🎯 Next: New shell prompt with enhanced features"
            ;;
        *)
            echo "🔧 Installation step: $stage_name"
            ;;
    esac
}

# Screenshot function removed - using track_stage() for logging only
capture_stage_screenshot() {
    local stage_name="$1"
    track_stage "$stage_name" "installation"
}

# Failure tracking functions
track_success() {
    local component="$1"
    local message="${2:-$component completed successfully}"
    INSTALLATION_SUCCESSES+=("✅ $component: $message")
    debug "📊 Tracked success: $component"
}

track_warning() {
    local component="$1"
    local message="${2:-$component completed with warnings}"
    INSTALLATION_WARNINGS+=("⚠️  $component: $message")
    debug "📊 Tracked warning: $component"
}

track_failure() {
    local component="$1"
    local message="${2:-$component failed}"
    INSTALLATION_FAILURES+=("❌ $component: $message")
    debug "📊 Tracked failure: $component"
}

# Show installation summary
show_installation_summary() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}           Installation Summary${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    # Show successes
    if [ ${#INSTALLATION_SUCCESSES[@]} -gt 0 ]; then
        echo -e "${GREEN}✅ Successful Components (${#INSTALLATION_SUCCESSES[@]}):${NC}"
        for success in "${INSTALLATION_SUCCESSES[@]}"; do
            echo "   $success"
        done
        echo ""
    fi

    # Show warnings
    if [ ${#INSTALLATION_WARNINGS[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Components with Warnings (${#INSTALLATION_WARNINGS[@]}):${NC}"
        for warning in "${INSTALLATION_WARNINGS[@]}"; do
            echo "   $warning"
        done
        echo ""
    fi

    # Show failures
    if [ ${#INSTALLATION_FAILURES[@]} -gt 0 ]; then
        echo -e "${RED}❌ Failed Components (${#INSTALLATION_FAILURES[@]}):${NC}"
        for failure in "${INSTALLATION_FAILURES[@]}"; do
            echo "   $failure"
        done
        echo ""
        echo -e "${YELLOW}💡 Note: Failed components can be retried manually or will be available after shell restart${NC}"
        echo ""
    fi

    # Overall status
    if [ ${#INSTALLATION_FAILURES[@]} -eq 0 ] && [ ${#INSTALLATION_WARNINGS[@]} -eq 0 ]; then
        echo -e "${GREEN}🎉 Overall Status: All components installed successfully!${NC}"
    elif [ ${#INSTALLATION_FAILURES[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️  Overall Status: Installation completed with warnings${NC}"
    else
        echo -e "${YELLOW}⚠️  Overall Status: Installation completed with some failures${NC}"
        echo -e "${CYAN}   Core system is functional - failed components are optional${NC}"
    fi

    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BLUE}📋 Session Logs:${NC}"
    echo "   Main log: $LOG_FILE"
    echo "   Error log: $LOG_ERRORS"
    echo "   JSON log: $LOG_JSON"
    echo ""
}

# Function to create process diagram
create_installation_diagram() {
    local stages_json='[
        "System Check",
        "Dependencies",
        "Zig Installation",
        "Ghostty Build",
        "Configuration",
        "Context Menu",
        "Verification"
    ]'

    if [ "$ENABLE_SCREENSHOTS" = "true" ] && [ -f "$SVG_CAPTURE_SCRIPT" ]; then
        log "INFO" "📊 Creating installation process diagram"
        "$SVG_CAPTURE_SCRIPT" diagram "Ghostty Installation Process" "$stages_json" || \
        log "WARNING" "Process diagram creation failed"
    fi
}

# Function to setup screenshot dependencies using uv - FULLY AUTOMATIC
setup_screenshot_dependencies() {
    if [ "$ENABLE_SCREENSHOTS" = "false" ]; then
        debug "Screenshot capture disabled (no GUI), skipping dependency setup"
        return 0
    fi

    debug "📸 Auto-setting up SVG screenshot dependencies..."

    # Ensure uv is available and in PATH
    if ! command -v uv >/dev/null 2>&1; then
        log "WARNING" "uv not found, installing screenshot tools via system packages only"
        install_system_screenshot_tools
        return $?
    fi

    # Create uv project for screenshot tools if it doesn't exist
    local screenshot_tools_dir="$SCRIPT_DIR/.screenshot-tools"
    if [ ! -d "$screenshot_tools_dir" ]; then
        mkdir -p "$screenshot_tools_dir"
        cd "$screenshot_tools_dir"

        # Initialize uv project for screenshot tools
        cat > pyproject.toml << 'EOF'
[project]
name = "ghostty-screenshot-tools"
version = "1.0.0"
description = "SVG screenshot capture tools for Ghostty installation documentation"
requires-python = ">=3.9"
dependencies = [
    "termtosvg>=1.1.0",
    "asciinema>=2.4.0",
    "svg-term>=1.0.0",
    "jinja2>=3.1.0",
    "pillow>=10.0.0",
    "cairosvg>=2.7.0"
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.uv]
dev-dependencies = []
EOF

        # Create .python-version
        echo "3.11" > .python-version

        debug "🐍 Created uv project for screenshot tools"
        cd "$SCRIPT_DIR"
    fi

    # Install Python dependencies via uv silently
    cd "$screenshot_tools_dir"
    debug "📦 Installing Python screenshot tools via uv..."

    if uv sync >> "$LOG_FILE" 2>&1; then
        debug "✅ Python screenshot tools installed via uv"

        # Make uv environment available for screenshot script
        export UV_PROJECT_ENVIRONMENT="$screenshot_tools_dir/.venv"
        export SCREENSHOT_TOOLS_VENV="$screenshot_tools_dir/.venv"

        # Test that tools are available silently
        if uv run python -c "import termtosvg" >> "$LOG_FILE" 2>&1; then
            debug "✅ termtosvg available in uv environment"
        else
            debug "⚠️ termtosvg import failed, will use fallback methods"
        fi
    else
        debug "⚠️ uv sync failed, falling back to system tools"
        install_system_screenshot_tools
    fi

    cd "$SCRIPT_DIR"

    # Install system-level screenshot tools as backup silently
    install_system_screenshot_tools

    debug "📸 Screenshot dependencies setup complete"
}

# Function to install system screenshot tools - SILENT
install_system_screenshot_tools() {
    debug "📦 Installing system screenshot tools..."

    local tools_to_install=()

    # Check for gnome-screenshot
    if ! command -v gnome-screenshot >/dev/null 2>&1; then
        tools_to_install+=("gnome-screenshot")
    fi

    # Check for scrot
    if ! command -v scrot >/dev/null 2>&1; then
        tools_to_install+=("scrot")
    fi

    # Check for ImageMagick
    if ! command -v convert >/dev/null 2>&1; then
        tools_to_install+=("imagemagick")
    fi

    # Check for SVG tools
    if ! command -v rsvg-convert >/dev/null 2>&1; then
        tools_to_install+=("librsvg2-bin")
    fi

    if [ ${#tools_to_install[@]} -gt 0 ]; then
        debug "🔧 Installing system tools: ${tools_to_install[*]}"

        if command -v apt >/dev/null 2>&1; then
            if sudo apt update >> "$LOG_FILE" 2>&1 && \
               sudo apt install -y "${tools_to_install[@]}" >> "$LOG_FILE" 2>&1; then
                debug "✅ System screenshot tools installed"
            else
                debug "⚠️ Some system screenshot tools may have failed to install"
            fi
        else
            debug "⚠️ apt not available, system screenshot tools not installed"
        fi
    else
        debug "ℹ️ All system screenshot tools already available"
    fi
}

# Function to finalize documentation - FULLY AUTOMATIC
finalize_installation_docs() {
    if [ "$ENABLE_SCREENSHOTS" = "true" ] && [ -f "$SVG_CAPTURE_SCRIPT" ]; then
        log "INFO" "📚 Generating installation documentation and website"

        # Wait for any remaining screenshot captures
        if [ -f "$LOG_DIR/$LOG_SESSION_ID-screenshot-pids.log" ]; then
            while read -r pid; do
                if kill -0 "$pid" 2>/dev/null; then
                    wait "$pid" 2>/dev/null || true
                fi
            done < "$LOG_DIR/$LOG_SESSION_ID-screenshot-pids.log"
            rm -f "$LOG_DIR/$LOG_SESSION_ID-screenshot-pids.log"
        fi

        # Generate complete documentation with uv environment
        if [ -n "${SCREENSHOT_TOOLS_VENV:-}" ] && [ -d "$SCREENSHOT_TOOLS_VENV" ]; then
            export UV_PROJECT_ENVIRONMENT="$SCREENSHOT_TOOLS_VENV"
        fi

        # Generate SVG screenshot documentation
        "$SVG_CAPTURE_SCRIPT" generate-docs >/dev/null 2>&1 || \
        debug "SVG documentation generation failed"

        # Generate Astro.build website automatically
        if [ -f "$SCRIPT_DIR/generate_docs_website.sh" ]; then
            debug "🌐 Building Astro.build documentation website..."

            # Ensure Node.js is available for Astro build
            if command -v node >/dev/null 2>&1; then
                if "$SCRIPT_DIR/generate_docs_website.sh" build >> "$LOG_FILE" 2>&1; then
                    log "SUCCESS" "📖 Documentation website built successfully"
                    log "INFO" "🌐 Website available in docs/ directory for GitHub Pages"
                else
                    debug "Astro build failed, basic documentation still available"
                fi
            else
                debug "Node.js not available, skipping Astro build"
            fi
        fi

        log "SUCCESS" "📸 Screenshot gallery and documentation complete"
        log "INFO" "📁 Screenshots: docs/assets/screenshots/$LOG_SESSION_ID/"
        log "INFO" "📄 View logs: ls -la $LOG_DIR/$LOG_SESSION_ID*"
    fi
}

# Session Management and Cross-Execution Tracking
init_session_tracking() {
    log "INFO" "🔄 Initializing session tracking: $LOG_SESSION_ID"

    # Ensure all directories exist
    mkdir -p "$LOG_DIR" "$SCREENSHOT_SESSION_DIR"

    # Create comprehensive session manifest
    cat > "$LOG_SESSION_MANIFEST" << EOF
{
  "session_id": "$LOG_SESSION_ID",
  "datetime": "$DATETIME",
  "terminal_detected": "$DETECTED_TERMINAL",
  "session_type": "install",
  "created": "$(date -Iseconds)",
  "machine_info": {
    "hostname": "$(hostname)",
    "user": "$(whoami)",
    "os": "$(lsb_release -d 2>/dev/null | cut -f2 || echo 'Linux')",
    "kernel": "$(uname -r)",
    "shell": "$SHELL",
    "term": "${TERM:-unknown}",
    "display": "${DISPLAY:-none}",
    "wayland": "${WAYLAND_DISPLAY:-none}"
  },
  "terminal_environment": {
    "detected_terminal": "$DETECTED_TERMINAL",
    "term_program": "${TERM_PROGRAM:-unknown}",
    "ghostty_resources": "${GHOSTTY_RESOURCES_DIR:-none}",
    "ptyxis_version": "${PTYXIS_VERSION:-none}",
    "gnome_terminal": "${GNOME_TERMINAL_SCREEN:-none}",
    "konsole_version": "${KONSOLE_VERSION:-none}"
  },
  "paths": {
    "log_dir": "$LOG_DIR",
    "screenshot_dir": "$SCREENSHOT_SESSION_DIR",
    "project_root": "$SCRIPT_DIR"
  },
  "files": {
    "main_log": "$LOG_FILE",
    "json_log": "$LOG_JSON",
    "error_log": "$LOG_ERRORS",
    "command_log": "$LOG_COMMANDS",
    "performance_log": "$LOG_PERFORMANCE",
    "screenshot_metadata": "$SCREENSHOT_METADATA"
  },
  "status": {
    "started": "$(date -Iseconds)",
    "completed": null,
    "screenshots_enabled": $ENABLE_SCREENSHOTS,
    "gui_available": $([ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ] && echo "true" || echo "false"),
    "uv_available": $(command -v uv >/dev/null 2>&1 && echo "true" || echo "false")
  },
  "stages": [],
  "statistics": {
    "total_stages": 0,
    "screenshots_captured": 0,
    "errors_encountered": 0,
    "duration_seconds": 0
  }
}
EOF

    log "SUCCESS" "📋 Session manifest created: $LOG_SESSION_MANIFEST"
    log "INFO" "🏷️  Session type: $DETECTED_TERMINAL terminal installation"
}

# Add stage tracking to session manifest
track_stage() {
    local stage_name="$1"
    local stage_type="${2:-installation}"
    local timestamp="$(date -Iseconds)"

    if [ -f "$LOG_SESSION_MANIFEST" ]; then
        local temp_manifest=$(mktemp)
        jq --arg stage "$stage_name" \
           --arg type "$stage_type" \
           --arg timestamp "$timestamp" \
           '.stages += [{
             "name": $stage,
             "type": $type,
             "timestamp": $timestamp,
             "screenshot_expected": true
           }] | .statistics.total_stages = (.stages | length)' \
           "$LOG_SESSION_MANIFEST" > "$temp_manifest"

        mv "$temp_manifest" "$LOG_SESSION_MANIFEST"
        debug "📊 Tracked stage: $stage_name"
    fi
}

# Finalize session tracking
finalize_session_tracking() {
    if [ -f "$LOG_SESSION_MANIFEST" ]; then
        local temp_manifest=$(mktemp)
        local end_time="$(date -Iseconds)"
        local start_time=$(jq -r '.status.started' "$LOG_SESSION_MANIFEST")
        local duration=0

        if [ "$start_time" != "null" ]; then
            local start_epoch=$(date -d "$start_time" +%s)
            local end_epoch=$(date -d "$end_time" +%s)
            duration=$((end_epoch - start_epoch))
        fi

        # Count screenshots if directory exists
        local screenshots_count=0
        if [ -d "$SCREENSHOT_SESSION_DIR" ]; then
            screenshots_count=$(find "$SCREENSHOT_SESSION_DIR" -name "*.svg" 2>/dev/null | wc -l)
        fi

        # Count errors
        local errors_count=0
        if [ -f "$LOG_ERRORS" ]; then
            errors_count=$(wc -l < "$LOG_ERRORS" 2>/dev/null || echo "0")
        fi

        jq --arg end_time "$end_time" \
           --arg duration "$duration" \
           --arg screenshots "$screenshots_count" \
           --arg errors "$errors_count" \
           '.status.completed = $end_time |
            .statistics.duration_seconds = ($duration | tonumber) |
            .statistics.screenshots_captured = ($screenshots | tonumber) |
            .statistics.errors_encountered = ($errors | tonumber)' \
           "$LOG_SESSION_MANIFEST" > "$temp_manifest"

        mv "$temp_manifest" "$LOG_SESSION_MANIFEST"

        log "SUCCESS" "📊 Session completed: $duration seconds, $screenshots_count screenshots, $errors_count errors"
    fi
}

# Progressive disclosure logging system (like Claude Code)
declare -A active_tasks
task_counter=0

# Start a new task with progressive disclosure
start_task() {
    local task_name="$1"
    local task_description="$2"

    task_counter=$((task_counter + 1))
    local task_id="task_${task_counter}"

    active_tasks[$task_id]="$task_name"

    # Clear previous output and show task header
    echo -ne "\r\033[K"  # Clear current line
    echo -e "${CYAN}▶️  $task_name${NC}"
    if [ -n "$task_description" ]; then
        echo -e "${BLUE}   $task_description${NC}"
    fi
    echo "───────────────────────────────────────"

    # Store task start info with safe filename
    local safe_task_id=$(echo "$task_id" | tr -cd '[:alnum:]' | cut -c1-20)
    local task_file="/tmp/task_${safe_task_id}_$$"
    echo "$task_id|$task_name|$(date +%s)" > "$task_file"
    echo "$task_id"
}

# Stream command output in real-time with comprehensive logging
stream_command() {
    local task_id="$1"
    local command="$2"
    local description="$3"

    echo -e "   ${YELLOW}💻 ${NC}$description"
    echo -e "   ${CYAN}├─ Command: ${NC}$command"
    echo -e "   ${CYAN}└─ Output:${NC}"

    # Log command start to all relevant log files
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local start_time=$(date +%s.%N)
    # Use short, safe filename to prevent "File name too long" errors
    local safe_task_id=$(echo "$task_id" | tr -cd '[:alnum:]' | cut -c1-20)
    local temp_log="/tmp/cmd_${safe_task_id}_$$"

    # Log command execution to dedicated command log
    cat >> "$LOG_COMMANDS" << EOF
[$timestamp] [COMMAND_START] Task: $task_id | Description: $description
[$timestamp] [COMMAND] $command
───────────────────────────────────────
EOF

    # Run command with real-time output and comprehensive logging
    local exit_code=0
    {
        echo "[$timestamp] [COMMAND_START] $description"
        echo "[$timestamp] [COMMAND] $command"
        echo "───────────────────────────────────────"

        # Execute command and capture all output with indentation for readability
        if eval "$command" 2>&1 | while IFS= read -r line; do
            echo "      $line"  # Show to user with indentation
            echo "$line" >> "$temp_log"  # Temp storage
            echo "[$timestamp] [OUTPUT] $line" >> "$LOG_COMMANDS"  # Log all output
            echo "[$timestamp] [COMMAND_OUTPUT] $line" >> "$LOG_FILE"  # Main log
        done; then
            exit_code=0
        else
            exit_code=$?
        fi

        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "unknown")

        echo ""
        if [ $exit_code -eq 0 ]; then
            echo -e "   ${GREEN}✅ Completed in ${duration}s${NC}"
            echo "[$timestamp] [COMMAND_SUCCESS] Duration: ${duration}s | Exit: $exit_code" >> "$LOG_COMMANDS"
            echo "[$timestamp] [COMMAND_SUCCESS] $description completed in ${duration}s" >> "$LOG_FILE"
        else
            echo -e "   ${RED}❌ Failed after ${duration}s${NC}"
            echo "[$timestamp] [COMMAND_FAILED] Duration: ${duration}s | Exit: $exit_code" >> "$LOG_COMMANDS"
            echo "[$timestamp] [COMMAND_FAILED] $description failed after ${duration}s (exit: $exit_code)" >> "$LOG_FILE"
            echo "[$timestamp] [ERROR] [stream_command] Command failed: $command" >> "$LOG_ERRORS"
        fi

        # Add separator to logs
        echo "" >> "$LOG_COMMANDS"
        return $exit_code
    }
}

# Complete and collapse a task with enhanced logging
complete_task() {
    local task_id="$1"
    local status="${2:-success}"
    local summary="$3"

    local task_name="${active_tasks[$task_id]:-Unknown Task}"

    # Use safe filename for task tracking
    local safe_task_id=$(echo "$task_id" | tr -cd '[:alnum:]' | cut -c1-20)
    local task_file="/tmp/task_${safe_task_id}_$$"
    if [ -f "$task_file" ]; then
        local task_info=$(cat "$task_file")
        local start_time=$(echo "$task_info" | cut -d'|' -f3)
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

        # Log task completion
        echo "[$timestamp] [TASK_COMPLETE] $task_name | Status: $status | Duration: ${duration}s" >> "$LOG_FILE"
        if [ -n "$summary" ]; then
            echo "[$timestamp] [TASK_SUMMARY] $summary" >> "$LOG_FILE"
        fi

        # Show collapsed summary with enhanced information (no cursor manipulation for compatibility)
        echo ""  # Add some space
        if [ "$status" = "success" ]; then
            echo -e "${GREEN}✅ $task_name${NC} ${CYAN}(${duration}s)${NC}"
            if [ -n "$summary" ]; then
                echo -e "${BLUE}   ✓ $summary${NC}"
            fi
        elif [ "$status" = "warning" ]; then
            echo -e "${YELLOW}⚠️  $task_name${NC} ${CYAN}(${duration}s)${NC}"
            if [ -n "$summary" ]; then
                echo -e "${YELLOW}   ⚠ $summary${NC}"
            fi
        else
            echo -e "${RED}❌ $task_name${NC} ${CYAN}(${duration}s)${NC}"
            if [ -n "$summary" ]; then
                echo -e "${RED}   ✗ $summary${NC}"
            fi
        fi

        # Add log viewing hint for failed tasks
        if [ "$status" = "error" ]; then
            echo -e "${BLUE}   📋 Check logs: $LOG_FILE${NC}"
        fi
        echo ""  # Add space after completion

        # Copy command output to main log if it exists
        local temp_log="/tmp/cmd_${safe_task_id}_$$"
        if [ -f "$temp_log" ]; then
            echo "[$timestamp] [TASK_OUTPUT_START] $task_name" >> "$LOG_FILE"
            cat "$temp_log" >> "$LOG_FILE"
            echo "[$timestamp] [TASK_OUTPUT_END] $task_name" >> "$LOG_FILE"
        fi

        # Cleanup using safe filenames
        rm -f "$task_file"
        rm -f "$temp_log"
        unset active_tasks[$task_id]
    fi
}

# Enhanced command runner with progressive disclosure
run_task_command() {
    local task_name="$1"
    local command="$2"
    local description="${3:-$command}"
    local expected_duration="${4:-unknown}"

    # Start the task
    local task_id=$(start_task "$task_name" "$description")

    # Show expected duration if provided
    if [ "$expected_duration" != "unknown" ]; then
        echo -e "${BLUE}   Expected duration: ~${expected_duration}${NC}"
        echo "───────────────────────────────────────"
    fi

    # Stream the command
    if stream_command "$task_id" "$command" "$description"; then
        complete_task "$task_id" "success" "Completed successfully"
        return 0
    else
        complete_task "$task_id" "error" "Command failed"
        return 1
    fi
}

# Test result logging
test_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"

    if [ "$result" = "PASS" ]; then
        log "TEST" "✅ $test_name: PASSED - $details"
    else
        log "TEST" "❌ $test_name: FAILED - $details"
    fi
}

# Performance timing
start_timer() {
    TIMER_START=$(date +%s)
}

end_timer() {
    local operation="$1"
    if [ -n "$TIMER_START" ]; then
        local duration=$(($(date +%s) - TIMER_START))
        log "INFO" "⏱️ $operation completed in ${duration}s"
        unset TIMER_START
    fi
}

# System state capture
capture_system_state() {
    local state_file="$LOG_DIR/$LOG_SESSION_ID-system-state-$(date +%s).json"
    debug "Capturing system state to $state_file"

    cat > "$state_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "system": {
        "os": "$(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")",
        "kernel": "$(uname -r)",
        "architecture": "$(uname -m)",
        "memory_gb": "$(free -g | awk '/^Mem:/{print $2}')",
        "disk_space_gb": "$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')"
    },
    "ghostty": {
        "installed": $(command -v ghostty >/dev/null && echo "true" || echo "false"),
        "version": "$(ghostty --version 2>/dev/null || echo "not_installed")",
        "config_exists": $([ -f "$GHOSTTY_CONFIG_DIR/config" ] && echo "true" || echo "false"),
        "config_valid": $(ghostty +show-config >/dev/null 2>&1 && echo "true" || echo "false")
    },
    "environment": {
        "shell": "$SHELL",
        "desktop_session": "${XDG_CURRENT_DESKTOP:-unknown}",
        "display_server": "${XDG_SESSION_TYPE:-unknown}",
        "node_version": "$(node --version 2>/dev/null || echo "not_installed")",
        "npm_version": "$(npm --version 2>/dev/null || echo "not_installed")"
    }
}
EOF

    debug "System state captured successfully"
}

# Performance monitoring
monitor_performance() {
    local operation="$1"
    local start_time=$(date +%s.%N)
    local start_memory=$(free -m | awk 'NR==2{printf "%.2f", $3/1024 }')

    debug "Starting performance monitoring for: $operation"
    debug "Initial memory usage: ${start_memory}GB"

    # Store for later use
    PERF_START_TIME="$start_time"
    PERF_START_MEMORY="$start_memory"
    PERF_OPERATION="$operation"
}

end_performance_monitoring() {
    if [ -n "$PERF_START_TIME" ]; then
        local end_time=$(date +%s.%N)
        local end_memory=$(free -m | awk 'NR==2{printf "%.2f", $3/1024 }')
        local duration=$(echo "$end_time - $PERF_START_TIME" | bc 2>/dev/null || echo "0")
        local memory_delta=$(echo "$end_memory - $PERF_START_MEMORY" | bc 2>/dev/null || echo "0")

        log "INFO" "⏱️ Performance: $PERF_OPERATION"
        log "INFO" "   Duration: ${duration}s"
        log "INFO" "   Memory delta: ${memory_delta}GB"

        # Log to structured file
        echo "{\"timestamp\":\"$(date -Iseconds)\",\"operation\":\"$PERF_OPERATION\",\"duration\":\"$duration\",\"memory_delta\":\"$memory_delta\"}" >> "$LOG_PERFORMANCE"

        unset PERF_START_TIME PERF_START_MEMORY PERF_OPERATION
    fi
}

# Enhanced error handling with context
handle_error() {
    local line_number="$1"
    local exit_code="${2:-1}"
    local context="${FUNCNAME[1]:-main}"

    log "ERROR" "💥 FATAL ERROR in function '$context' at line $line_number"
    log "ERROR" "Exit code: $exit_code"
    log "ERROR" "Check logs: $LOG_FILE"
    log "ERROR" "Error log: $LOG_DIR/errors.log"

    # Capture final system state
    capture_system_state

    # Display recent error context
    if [ -f "$LOG_DIR/errors.log" ]; then
        echo ""
        echo "Recent errors:"
        tail -5 "$LOG_DIR/errors.log"
    fi

    exit "$exit_code"
}
trap 'handle_error $LINENO' ERR

# Show help
show_help() {
    echo -e "${CYAN}Comprehensive Terminal Tools Installer${NC}"
    echo ""
    echo "This script installs and configures:"
    echo "  • ZSH shell with Oh My ZSH, essential plugins, and modern tools (eza, bat, ripgrep, fzf, zoxide)"
    echo "  • Ghostty terminal emulator with optimized configuration"
    echo "  • Ptyxis terminal (prefers apt/snap, fallback to flatpak)"
    echo "  • uv Python package manager (latest version)"
    echo "  • Node.js (via fnm - Fast Node Manager) with npm and development tools"
    echo "  • Claude Code CLI (latest version)"
    echo "  • Gemini CLI (latest version)"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --skip-deps    Skip system dependency installation"
    echo "  --skip-node    Skip Node.js/fnm installation"
    echo "  --skip-ai      Skip AI tools (Claude Code, Gemini CLI)"
    echo "  --skip-ptyxis  Skip Ptyxis installation"
    echo "  --verbose      Enable verbose logging"
    echo "  --debug        Enable full debug mode (shows all commands and outputs)"
    echo ""
    echo "Examples:"
    echo "  ./start.sh                    # Full installation"
    echo "  ./start.sh --skip-deps       # Skip system dependencies"
    echo "  ./start.sh --verbose         # Verbose output"
    echo ""
}

# Parse command line arguments
SKIP_DEPS=false
SKIP_NODE=false
SKIP_AI=false
SKIP_PTYXIS=false
VERBOSE=false
DEBUG_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            exit 0
            ;;
        --skip-deps)
            SKIP_DEPS=true
            shift
            ;;
        --skip-node)
            SKIP_NODE=true
            shift
            ;;
        --skip-ai)
            SKIP_AI=true
            shift
            ;;
        --skip-ptyxis)
            SKIP_PTYXIS=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --debug)
            DEBUG_MODE=true
            VERBOSE=true
            set -x  # Enable bash debug mode
            shift
            ;;
        *)
            log "ERROR" "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check installation status and versions
check_installation_status() {
    log "STEP" "🔍 Checking current installation status..."

    # Check Ghostty installation with proper source detection
    ghostty_installed=false
    ghostty_version=""
    ghostty_config_valid=false
    ghostty_source=""

    if command -v ghostty >/dev/null 2>&1; then
        ghostty_installed=true

        # Detect installation source first, then get version accordingly
        local ghostty_path=$(which ghostty 2>/dev/null)
        if [[ "$ghostty_path" == "/snap/"* ]]; then
            ghostty_source="snap"
            ghostty_version=$(snap list ghostty 2>/dev/null | tail -1 | awk '{print $2}' || echo "unknown")
            log "INFO" "✅ Ghostty installed via snap: $ghostty_version"
        elif [[ "$ghostty_path" == "/usr/local/"* ]]; then
            ghostty_source="source"
            ghostty_version=$(ghostty --version 2>/dev/null | head -1 || echo "unknown")
            log "INFO" "✅ Ghostty installed from source: $ghostty_version"
        elif dpkg -l 2>/dev/null | grep -q "^ii.*ghostty"; then
            ghostty_source="apt"
            ghostty_version=$(dpkg -l ghostty 2>/dev/null | tail -1 | awk '{print $3}' || echo "unknown")
            log "INFO" "✅ Ghostty installed via apt: $ghostty_version"
        else
            ghostty_source="unknown"
            ghostty_version=$(ghostty --version 2>/dev/null | head -1 || echo "unknown")
            log "INFO" "✅ Ghostty installed (unknown source): $ghostty_version"
        fi

        # Check configuration validity
        if ghostty +show-config >/dev/null 2>&1; then
            ghostty_config_valid=true
            log "INFO" "✅ Ghostty configuration is valid"
        else
            log "WARNING" "⚠️  Ghostty configuration has issues"
        fi
    else
        log "INFO" "❌ Ghostty not installed"
    fi
    
    # Check Ptyxis installation (prefer official: apt, snap, then flatpak)
    ptyxis_installed=false
    ptyxis_version=""
    ptyxis_source=""

    debug "🔍 Starting Ptyxis detection..."

    # Check apt installation first (official)
    debug "🔍 Checking apt installation: dpkg -l | grep ptyxis"
    local apt_check_output=$(dpkg -l 2>/dev/null | grep ptyxis)
    debug "📋 apt check output: '$apt_check_output'"

    if dpkg -l 2>/dev/null | grep ptyxis | grep -q "^ii"; then
        debug "✅ APT check matched!"
        ptyxis_installed=true
        ptyxis_version=$(ptyxis --version 2>/dev/null | head -n1 | awk '{print $2}' || echo "unknown")
        ptyxis_source="apt"
        debug "📋 Ptyxis version from command: '$ptyxis_version'"
        log "INFO" "✅ Ptyxis installed via apt: $ptyxis_version"
    else
        debug "❌ APT check failed"

        # Check snap installation (official)
        debug "🔍 Checking snap installation: snap list | grep ptyxis"
        local snap_check_output=$(snap list 2>/dev/null | grep ptyxis || echo "no snap output")
        debug "📋 snap check output: '$snap_check_output'"

        if snap list 2>/dev/null | grep -q "ptyxis"; then
            debug "✅ SNAP check matched!"
            ptyxis_installed=true
            ptyxis_version=$(snap list ptyxis 2>/dev/null | tail -n +2 | awk '{print $2}' || echo "unknown")
            ptyxis_source="snap"
            debug "📋 Ptyxis version from snap: '$ptyxis_version'"
            log "INFO" "✅ Ptyxis installed via snap: $ptyxis_version"
        else
            debug "❌ SNAP check failed"

            # Check flatpak installation (fallback)
            debug "🔍 Checking flatpak installation: flatpak list | grep Ptyxis"
            local flatpak_check_output=$(flatpak list 2>/dev/null | grep Ptyxis || echo "no flatpak output")
            debug "📋 flatpak check output: '$flatpak_check_output'"

            if flatpak list 2>/dev/null | grep -q "app.devsuite.Ptyxis"; then
                debug "✅ FLATPAK check matched!"
                ptyxis_installed=true
                ptyxis_version=$(flatpak info app.devsuite.Ptyxis 2>/dev/null | grep "Version:" | cut -d: -f2 | xargs || echo "unknown")
                ptyxis_source="flatpak"
                debug "📋 Ptyxis version from flatpak: '$ptyxis_version'"
                log "INFO" "✅ Ptyxis installed via flatpak: $ptyxis_version"
            else
                debug "❌ FLATPAK check failed"
                log "INFO" "❌ Ptyxis not installed"
            fi
        fi
    fi

    debug "📋 Final detection results: installed=$ptyxis_installed, source=$ptyxis_source, version=$ptyxis_version"
    
    # Check for available updates
    check_available_updates "$ghostty_installed" "$ptyxis_installed"
    
    # Determine installation strategy
    determine_install_strategy "$ghostty_installed" "$ghostty_config_valid" "$ptyxis_installed"

    # Check for 2025 optimizations
    check_config_optimizations "$ghostty_installed"
}

# Check if configuration has 2025 optimizations
check_config_optimizations() {
    local ghostty_installed="$1"

    if $ghostty_installed && [ -f "$GHOSTTY_CONFIG_DIR/config" ]; then
        local config_file="$GHOSTTY_CONFIG_DIR/config"
        local has_optimizations=true

        # Check for key 2025 optimizations
        if ! grep -q "linux-cgroup.*single-instance" "$config_file"; then
            has_optimizations=false
            log "INFO" "📋 Missing: linux-cgroup single-instance optimization"
        fi

        if ! grep -q "shell-integration.*detect" "$config_file"; then
            has_optimizations=false
            log "INFO" "📋 Missing: enhanced shell integration"
        fi

        if ! grep -q "clipboard-paste-protection" "$config_file"; then
            has_optimizations=false
            log "INFO" "📋 Missing: clipboard paste protection"
        fi

        if $has_optimizations; then
            log "SUCCESS" "✅ Configuration has 2025 optimizations"
            CONFIG_NEEDS_UPDATE=false
        else
            log "WARNING" "⚠️  Configuration needs 2025 optimizations"
            CONFIG_NEEDS_UPDATE=true
        fi
    else
        CONFIG_NEEDS_UPDATE=true
    fi
}

# Smart configuration update
update_ghostty_config() {
    log "STEP" "🔧 Updating Ghostty configuration with 2025 optimizations..."

    # Always backup existing config
    if [ -f "$GHOSTTY_CONFIG_DIR/config" ]; then
        local backup_file="$GHOSTTY_CONFIG_DIR/config.backup-$(date +%Y%m%d-%H%M%S)"
        cp "$GHOSTTY_CONFIG_DIR/config" "$backup_file"
        log "SUCCESS" "✅ Backed up existing config to: $(basename "$backup_file")"
    fi

    # Create config directory if it doesn't exist
    mkdir -p "$GHOSTTY_CONFIG_DIR"

    # Copy optimized configurations
    if [ -d "$GHOSTTY_CONFIG_SOURCE" ]; then
        cp -r "$GHOSTTY_CONFIG_SOURCE"/* "$GHOSTTY_CONFIG_DIR/"
        log "SUCCESS" "✅ Applied 2025 optimized configuration"

        # Preserve user's custom keybindings if they exist
        if [ -f "$backup_file" ] && grep -q "keybind.*shift+enter" "$backup_file"; then
            if ! grep -q "keybind.*shift+enter" "$GHOSTTY_CONFIG_DIR/config"; then
                echo "" >> "$GHOSTTY_CONFIG_DIR/config"
                echo "# Custom keybindings (preserved from previous config)" >> "$GHOSTTY_CONFIG_DIR/config"
                grep "keybind.*shift+enter" "$backup_file" >> "$GHOSTTY_CONFIG_DIR/config"
                log "SUCCESS" "✅ Preserved custom keybindings"
            fi
        fi

        # Validate new configuration
        if command -v ghostty >/dev/null 2>&1 && ghostty +show-config >/dev/null 2>&1; then
            log "SUCCESS" "✅ Configuration validated successfully"
        else
            log "ERROR" "❌ Configuration validation failed, restoring backup"
            if [ -f "$backup_file" ]; then
                cp "$backup_file" "$GHOSTTY_CONFIG_DIR/config"
            fi
            return 1
        fi
    else
        log "ERROR" "❌ Source configuration directory not found: $GHOSTTY_CONFIG_SOURCE"
        return 1
    fi
}

# Check for available updates online
check_available_updates() {
    local ghostty_installed="$1"
    local ptyxis_installed="$2"
    
    log "INFO" "🌐 Checking for available updates..."
    
    # Check Ghostty updates based on installation source
    if $ghostty_installed; then
        if [ "$ghostty_source" = "snap" ]; then
            if snap refresh --list 2>/dev/null | grep -q "ghostty"; then
                log "INFO" "🆕 Ghostty update available via snap"
            else
                log "INFO" "✅ Ghostty is up to date (snap)"
            fi
        elif [ "$ghostty_source" = "apt" ]; then
            if apt list --upgradable 2>/dev/null | grep -q "ghostty"; then
                log "INFO" "🆕 Ghostty update available via apt"
            else
                log "INFO" "✅ Ghostty is up to date (apt)"
            fi
        elif [ "$ghostty_source" = "source" ] && [ -d "$GHOSTTY_APP_DIR" ]; then
            cd "$GHOSTTY_APP_DIR"
            local current_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
            git fetch origin main >/dev/null 2>&1 || true
            local latest_commit=$(git rev-parse origin/main 2>/dev/null || echo "unknown")

            if [ "$current_commit" != "$latest_commit" ] && [ "$latest_commit" != "unknown" ]; then
                log "INFO" "🆕 Ghostty update available (new commits)"
            else
                log "INFO" "✅ Ghostty is up to date (source)"
            fi
        else
            log "INFO" "ℹ️ Ghostty update status unknown"
        fi
    fi
    
    # Check Ptyxis updates based on installation method
    if $ptyxis_installed; then
        if [ "$ptyxis_source" = "apt" ]; then
            # Check apt updates
            if apt list --upgradable 2>/dev/null | grep -q "ptyxis"; then
                log "INFO" "🆕 Ptyxis update available via apt"
            else
                log "INFO" "✅ Ptyxis is up to date (apt)"
            fi
        elif [ "$ptyxis_source" = "snap" ]; then
            # Check snap updates
            if snap refresh --list 2>/dev/null | grep -q "ptyxis"; then
                log "INFO" "🆕 Ptyxis update available via snap"
            else
                log "INFO" "✅ Ptyxis is up to date (snap)"
            fi
        elif [ "$ptyxis_source" = "flatpak" ]; then
            # Check flatpak updates
            if flatpak remote-ls --updates 2>/dev/null | grep -q "app.devsuite.Ptyxis"; then
                log "INFO" "🆕 Ptyxis update available via flatpak"
            else
                log "INFO" "✅ Ptyxis is up to date (flatpak)"
            fi
        fi
    fi
}

# Determine the best installation strategy
determine_install_strategy() {
    local ghostty_installed="$1"
    local ghostty_config_valid="$2"
    local ptyxis_installed="$3"

    log "INFO" "🤔 Determining installation strategy..."

    # Ghostty strategy based on installation source
    if $ghostty_installed; then
        if [ "$ghostty_source" = "snap" ]; then
            if $ghostty_config_valid; then
                log "INFO" "📋 Ghostty: Snap installation detected, will only update configuration"
                GHOSTTY_STRATEGY="config_only"
            else
                log "WARNING" "📋 Ghostty: Snap installation with invalid config, will fix configuration"
                GHOSTTY_STRATEGY="reconfig"
            fi
        elif [ "$ghostty_source" = "source" ] || [ "$ghostty_source" = "unknown" ]; then
            if $ghostty_config_valid; then
                log "INFO" "📋 Ghostty: Will update existing source installation"
                GHOSTTY_STRATEGY="update"
            else
                log "WARNING" "📋 Ghostty: Configuration invalid, will reinstall configuration"
                GHOSTTY_STRATEGY="reconfig"
            fi
        elif [ "$ghostty_source" = "apt" ]; then
            if $ghostty_config_valid; then
                log "INFO" "📋 Ghostty: APT installation detected, will only update configuration"
                GHOSTTY_STRATEGY="config_only"
            else
                log "WARNING" "📋 Ghostty: APT installation with invalid config, will fix configuration"
                GHOSTTY_STRATEGY="reconfig"
            fi
        fi
    else
        log "INFO" "📋 Ghostty: Will perform fresh installation"
        GHOSTTY_STRATEGY="fresh"
    fi

    # Ptyxis strategy
    if $ptyxis_installed; then
        log "INFO" "📋 Ptyxis: Will update existing installation"
        PTYXIS_STRATEGY="update"
    else
        log "INFO" "📋 Ptyxis: Will perform fresh installation"
        PTYXIS_STRATEGY="fresh"
    fi
}

# Pre-authentication for sudo
pre_auth_sudo() {
    log "INFO" "🔑 Checking sudo configuration..."

    # Use the dedicated verification script for comprehensive checks
    local verify_script="$SCRIPT_DIR/scripts/verify-passwordless-sudo.sh"

    if [ -f "$verify_script" ]; then
        # Run verification script (it will show detailed output)
        if "$verify_script"; then
            log "SUCCESS" "✅ Passwordless sudo configured - installation will run smoothly"
            return 0
        else
            # Verification script already showed detailed instructions
            log "ERROR" "❌ Passwordless sudo is REQUIRED for automated installation"
            log "INFO" ""
            log "INFO" "💡 Please follow the instructions above, then run ./start.sh again"
            log "INFO" "💡 Or run: ./scripts/verify-passwordless-sudo.sh to verify configuration"
            log "INFO" ""
            return 1
        fi
    else
        # Fallback to basic check if verification script doesn't exist
        if sudo -n true 2>/dev/null; then
            log "SUCCESS" "✅ Passwordless sudo configured - installation will run smoothly"
            return 0
        fi

        # Basic instructions if script not found
        log "ERROR" "❌ Passwordless sudo is REQUIRED for automated installation"
        log "INFO" ""
        log "INFO" "🔧 To enable passwordless sudo:"
        log "INFO" "   1. Run: sudo EDITOR=nano visudo"
        log "INFO" "   2. Add this line at the end:"
        log "INFO" "      $USER ALL=(ALL) NOPASSWD: /usr/bin/apt"
        log "INFO" "   3. Save (Ctrl+O, Enter) and exit (Ctrl+X)"
        log "INFO" "   4. Test: sudo -n apt update"
        log "INFO" ""
        log "INFO" "💡 Then run this script again: ./start.sh"
        log "INFO" ""

        return 1
    fi
}

# Install ZSH and Oh My ZSH
install_zsh() {
    log "STEP" "🐚 Setting up ZSH and Oh My ZSH..."

    # Check if ZSH is installed and update if needed
    if ! command -v zsh >/dev/null 2>&1; then
        log "INFO" "📥 Installing latest ZSH..."
        if sudo apt update && sudo apt install -y zsh >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ ZSH installed"
        else
            log "ERROR" "❌ Failed to install ZSH"
            return 1
        fi
    else
        local current_version=$(zsh --version 2>/dev/null | awk '{print $2}' || echo "unknown")
        log "INFO" "✅ ZSH already installed: $current_version"

        # Check for ZSH updates
        log "INFO" "🔄 Checking for ZSH updates..."
        if apt list --upgradable 2>/dev/null | grep -q "^zsh/"; then
            log "INFO" "🆕 ZSH update available, updating..."
            if sudo apt update && sudo apt upgrade -y zsh >> "$LOG_FILE" 2>&1; then
                log "SUCCESS" "✅ ZSH updated to latest version"
            else
                log "WARNING" "⚠️  ZSH update may have failed"
            fi
        else
            log "SUCCESS" "✅ ZSH is up to date"
        fi
    fi

    # Check if Oh My ZSH is installed and update if needed
    if [ ! -d "$REAL_HOME/.oh-my-zsh" ]; then
        log "INFO" "📥 Installing latest Oh My ZSH..."
        # Download and install Oh My ZSH non-interactively
        if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ Oh My ZSH installed"
        else
            log "ERROR" "❌ Failed to install Oh My ZSH"
            return 1
        fi
    else
        log "INFO" "✅ Oh My ZSH already installed"

        # Update Oh My ZSH to latest version using git pull (more reliable than upgrade script)
        log "INFO" "🔄 Updating Oh My ZSH to latest version..."
        if run_task_command "Updating Oh My ZSH" "cd '$REAL_HOME/.oh-my-zsh' && git pull origin master && cd - >/dev/null" "Pulling latest Oh My ZSH updates" "30s"; then
            log "SUCCESS" "✅ Oh My ZSH updated successfully"
        else
            log "WARNING" "⚠️  Oh My ZSH update failed - check network connection"
        fi
    fi
    
    # Check current default shell
    local current_shell=$(getent passwd "$USER" | cut -d: -f7)
    local zsh_path=$(which zsh)
    
    if [ "$current_shell" != "$zsh_path" ]; then
        log "INFO" "🔄 Setting ZSH as default shell..."

        # Try to change shell using sudo (non-interactive approach)
        if sudo usermod -s "$zsh_path" "$USER" 2>/dev/null; then
            log "SUCCESS" "✅ ZSH set as default shell (restart terminal to take effect)"
        else
            log "WARNING" "⚠️  Failed to set ZSH as default shell automatically"
            log "INFO" "💡 You can manually set it with: chsh -s $zsh_path"
            log "INFO" "💡 Or run: sudo usermod -s $zsh_path $USER"
        fi
    else
        log "SUCCESS" "✅ ZSH is already the default shell"
    fi
    
    # Update Ghostty config to use ZSH
    local ghostty_config="$GHOSTTY_CONFIG_DIR/config"
    if [ -f "$ghostty_config" ]; then
        if ! grep -q "shell-integration = zsh" "$ghostty_config"; then
            if grep -q "shell-integration" "$ghostty_config"; then
                sed -i 's/shell-integration = .*/shell-integration = zsh/' "$ghostty_config"
                log "SUCCESS" "✅ Updated Ghostty shell integration to ZSH"
            fi
        else
            log "SUCCESS" "✅ Ghostty already configured for ZSH"
        fi
    fi
    
    # Install essential Oh My ZSH plugins and optimizations
    log "INFO" "🔌 Setting up essential Oh My ZSH plugins and optimizations..."

    # Install zsh-autosuggestions (essential plugin #1)
    local autosuggestions_dir="$REAL_HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    if [ ! -d "$autosuggestions_dir" ]; then
        log "INFO" "📥 Installing zsh-autosuggestions..."
        if git clone https://github.com/zsh-users/zsh-autosuggestions "$autosuggestions_dir" >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ zsh-autosuggestions installed"
        else
            log "WARNING" "⚠️  Failed to install zsh-autosuggestions"
        fi
    fi

    # Install zsh-syntax-highlighting (essential plugin #2)
    local syntax_highlighting_dir="$REAL_HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    if [ ! -d "$syntax_highlighting_dir" ]; then
        log "INFO" "📥 Installing zsh-syntax-highlighting..."
        if git clone https://github.com/zsh-users/zsh-syntax-highlighting "$syntax_highlighting_dir" >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ zsh-syntax-highlighting installed"
        else
            log "WARNING" "⚠️  Failed to install zsh-syntax-highlighting"
        fi
    fi

    # Install you-should-use plugin (productivity training)
    local you_should_use_dir="$REAL_HOME/.oh-my-zsh/custom/plugins/you-should-use"
    if [ ! -d "$you_should_use_dir" ]; then
        log "INFO" "📥 Installing you-should-use plugin..."
        if git clone https://github.com/MichaelAquilina/zsh-you-should-use "$you_should_use_dir" >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ you-should-use plugin installed"
        else
            log "WARNING" "⚠️  Failed to install you-should-use plugin"
        fi
    fi

    # Install Powerlevel10k theme for enhanced terminal productivity
    local p10k_dir="$REAL_HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    if [ ! -d "$p10k_dir" ]; then
        log "INFO" "📥 Installing Powerlevel10k theme..."
        if git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir" >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ Powerlevel10k theme installed"
        else
            log "WARNING" "⚠️  Failed to install Powerlevel10k theme"
        fi
    else
        log "INFO" "✅ Powerlevel10k theme already installed"
    fi

    # Create Powerlevel10k configuration file
    local p10k_config="$REAL_HOME/.p10k.zsh"
    if [ ! -f "$p10k_config" ] && [ -d "$p10k_dir" ]; then
        log "INFO" "⚙️  Creating Powerlevel10k configuration..."
        if [ -f "$p10k_dir/config/p10k-lean.zsh" ]; then
            cp "$p10k_dir/config/p10k-lean.zsh" "$p10k_config"
            log "SUCCESS" "✅ Powerlevel10k configuration created (lean style)"
        else
            log "WARNING" "⚠️  Powerlevel10k config template not found"
        fi
    elif [ -f "$p10k_config" ]; then
        log "INFO" "✅ Powerlevel10k configuration already exists"
    fi

    # Configure Powerlevel10k theme integration
    log "INFO" "🎨 Configuring Powerlevel10k theme integration..."

    # Configure .zshrc with essential plugins and optimizations
    local zshrc="$REAL_HOME/.zshrc"
    if [ -f "$zshrc" ]; then
        # Create backup
        cp "$zshrc" "$zshrc.backup-$(date +%Y%m%d-%H%M%S)"

        # Update plugins with essential trinity + productivity plugins
        if grep -q "plugins=" "$zshrc"; then
            # Replace with optimized plugin list (syntax-highlighting MUST be last)
            # Note: Removed 'nvm' plugin as we use fnm for constitutional compliance
            sed -i 's/plugins=([^)]*)/plugins=(git npm node docker docker-compose sudo history extract z you-should-use zsh-autosuggestions zsh-syntax-highlighting)/' "$zshrc"
            log "SUCCESS" "✅ Updated plugins with essential trinity and productivity tools"
        fi

        # Set Powerlevel10k as the ZSH theme
        if [ -d "$p10k_dir" ]; then
            if grep -q "ZSH_THEME=" "$zshrc"; then
                sed -i 's/ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$zshrc"
                log "SUCCESS" "✅ Updated ZSH theme to Powerlevel10k"
            else
                echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$zshrc"
                log "SUCCESS" "✅ Set ZSH theme to Powerlevel10k"
            fi

            # Add Powerlevel10k instant prompt (must be near top of .zshrc)
            if ! grep -q "p10k-instant-prompt" "$zshrc"; then
                # Find the line after the Oh My ZSH path export
                local insert_line=$(grep -n "export ZSH=" "$zshrc" | head -1 | cut -d: -f1)
                if [ -n "$insert_line" ]; then
                    # Insert instant prompt configuration after ZSH path
                    sed -i "${insert_line}a\\
\\
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.\\
# Initialization code that may require console input (password prompts, [y/n]\\
# confirmations, etc.) must go above this block; everything else may go below.\\
if [[ -r \"\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh\" ]]; then\\
  source \"\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh\"\\
fi" "$zshrc"
                    log "SUCCESS" "✅ Added Powerlevel10k instant prompt configuration"
                fi
            fi

            # Add p10k config sourcing at the end
            if ! grep -q "source.*\.p10k\.zsh" "$zshrc" && [ -f "$p10k_config" ]; then
                echo "" >> "$zshrc"
                echo "# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$zshrc"
                echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$zshrc"
                log "SUCCESS" "✅ Added Powerlevel10k configuration sourcing"
            fi
        fi

        # Add performance optimizations to .zshrc
        if ! grep -q "# Oh My ZSH Performance Optimizations" "$zshrc"; then
            cat >> "$zshrc" << 'EOF'

# Oh My ZSH Performance Optimizations (2025)
# Disable magic functions for better performance
DISABLE_MAGIC_FUNCTIONS=true

# Compilation caching for faster startup
autoload -Uz compinit
if [ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]; then
    compinit
else
    compinit -C
fi

# Modern tool aliases for enhanced productivity
if command -v eza >/dev/null 2>&1; then
    alias ls="eza --group-directories-first --git"
    alias ll="eza -la --group-directories-first --git"
    alias tree="eza --tree"
fi

if command -v bat >/dev/null 2>&1; then
    alias cat="bat --style=plain"
    alias bathelp="bat --style=plain --language=help"
fi

if command -v rg >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git"'
fi

# zsh-autosuggestions configuration
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

EOF
            log "SUCCESS" "✅ Added performance optimizations and modern tool aliases"
        fi
    fi
        
        # Note: fnm configuration is handled by scripts/install_node.sh
        # This section intentionally left empty (fnm auto-configures during installation)
        
        # Add Ghostty shell integration to .zshrc (CRITICAL for autocompletion)
        if ! grep -q "GHOSTTY_RESOURCES_DIR.*ghostty-integration" "$zshrc"; then
            # Find the line after "source $ZSH/oh-my-zsh.sh"
            if grep -q "source.*oh-my-zsh.sh" "$zshrc"; then
                # Add ghostty integration right after oh-my-zsh is loaded
                sed -i '/source.*oh-my-zsh.sh/a\
\
# Ghostty shell integration (CRITICAL for proper terminal behavior)\
if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then\
  autoload -Uz -- "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration\
  ghostty-integration\
fi' "$zshrc"
                log "SUCCESS" "✅ Added Ghostty shell integration to .zshrc"
            else
                # If oh-my-zsh.sh sourcing not found, add at the end
                cat >> "$zshrc" << 'EOF'

# Ghostty shell integration (CRITICAL for proper terminal behavior)
if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
  autoload -Uz -- "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
  ghostty-integration
fi

EOF
                log "SUCCESS" "✅ Added Ghostty shell integration to .zshrc"
            fi
        else
            log "SUCCESS" "✅ Ghostty shell integration already configured in .zshrc"
        fi

        # Add Gemini alias to .zshrc (handle conflicts)
        if grep -q "flatpak run app.devsuite.Ptyxis.*gemini" "$zshrc"; then
            log "SUCCESS" "✅ Ptyxis gemini integration already configured in .zshrc"
        else
            if grep -q "alias gemini=" "$zshrc"; then
                log "INFO" "🔄 Updating existing gemini alias in .zshrc"
                sed -i '/alias gemini=/s/^/# (replaced by Ptyxis integration) /' "$zshrc"
            fi

            cat >> "$zshrc" << 'EOF'

# Gemini CLI integration with Ptyxis
# Uses fnm-managed Node.js (generic path, auto-resolves to current version)
alias gemini='flatpak run app.devsuite.Ptyxis -d "$(pwd)" -- gemini'

EOF
            log "SUCCESS" "✅ Added Ptyxis gemini integration to .zshrc"
        fi
}

# Install modern Unix tool replacements for enhanced productivity
install_modern_tools() {
    log "STEP" "🔧 Installing modern Unix tool replacements..."

    # Install/Update eza (modern ls replacement)
    if command -v eza >/dev/null 2>&1; then
        # Check if update is available
        log "INFO" "🔍 Checking for eza updates..."
        sudo apt update -qq 2>&1 | grep -v 'WARNING.*stable CLI interface' > /dev/null
        if apt list --upgradable 2>/dev/null | grep -q "^eza/"; then
            log "INFO" "📥 Updating eza (modern ls replacement)..."
            if run_task_command "Updating eza" "sudo apt upgrade -y eza 2>&1 | grep -v 'WARNING.*stable CLI interface'" "Updating eza for enhanced directory listings" "30s"; then
                log "SUCCESS" "✅ eza updated successfully"
            else
                log "INFO" "ℹ️ eza update failed, but already installed"
            fi
        else
            log "INFO" "✅ eza is already at the latest version"
        fi
    else
        log "INFO" "📥 Installing eza (modern ls replacement)..."
        if run_task_command "Installing eza" "sudo apt update -qq 2>&1 | grep -v 'WARNING.*stable CLI interface' && sudo apt install -y eza 2>&1 | grep -v 'WARNING.*stable CLI interface'" "Installing eza for enhanced directory listings" "30s"; then
            log "SUCCESS" "✅ eza installed successfully"
        else
            log "WARNING" "⚠️  Failed to install eza via apt, trying cargo..."
            if command -v cargo >/dev/null 2>&1; then
                if cargo install eza >> "$LOG_FILE" 2>&1; then
                    log "SUCCESS" "✅ eza installed via cargo"
                else
                    log "WARNING" "⚠️  Failed to install eza"
                fi
            else
                log "WARNING" "⚠️  eza installation failed - cargo not available"
            fi
        fi
    fi

    # Install/Update bat (modern cat replacement)
    if command -v bat >/dev/null 2>&1; then
        # Check if update is available
        log "INFO" "🔍 Checking for bat updates..."
        sudo apt update -qq 2>&1 | grep -v 'WARNING.*stable CLI interface' > /dev/null
        if apt list --upgradable 2>/dev/null | grep -q "^bat/"; then
            log "INFO" "📥 Updating bat (modern cat replacement)..."
            if run_task_command "Updating bat" "sudo apt upgrade -y bat 2>&1 | grep -v 'WARNING.*stable CLI interface'" "Updating bat for syntax-highlighted file viewing" "30s"; then
                log "SUCCESS" "✅ bat updated successfully"
            else
                log "INFO" "ℹ️ bat update failed, but already installed"
            fi
        else
            log "INFO" "✅ bat is already at the latest version"
        fi
    else
        log "INFO" "📥 Installing bat (modern cat replacement)..."
        if run_task_command "Installing bat" "sudo apt update -qq 2>&1 | grep -v 'WARNING.*stable CLI interface' && sudo apt install -y bat 2>&1 | grep -v 'WARNING.*stable CLI interface'" "Installing bat for syntax-highlighted file viewing" "30s"; then
            log "SUCCESS" "✅ bat installed successfully"
        else
            log "WARNING" "⚠️  Failed to install bat"
        fi
    fi

    # Install/Update ripgrep (modern grep replacement)
    if command -v rg >/dev/null 2>&1; then
        # Check if update is available
        log "INFO" "🔍 Checking for ripgrep updates..."
        sudo apt update -qq 2>&1 | grep -v 'WARNING.*stable CLI interface' > /dev/null
        if apt list --upgradable 2>/dev/null | grep -q "^ripgrep/"; then
            log "INFO" "📥 Updating ripgrep (modern grep replacement)..."
            if run_task_command "Updating ripgrep" "sudo apt upgrade -y ripgrep 2>&1 | grep -v 'WARNING.*stable CLI interface'" "Updating ripgrep for faster searching" "30s"; then
                log "SUCCESS" "✅ ripgrep updated successfully"
            else
                log "INFO" "ℹ️ ripgrep update failed, but already installed"
            fi
        else
            log "INFO" "✅ ripgrep is already at the latest version"
        fi
    else
        log "INFO" "📥 Installing ripgrep (modern grep replacement)..."
        if run_task_command "Installing ripgrep" "sudo apt update -qq 2>&1 | grep -v 'WARNING.*stable CLI interface' && sudo apt install -y ripgrep 2>&1 | grep -v 'WARNING.*stable CLI interface'" "Installing ripgrep for faster searching" "30s"; then
            log "SUCCESS" "✅ ripgrep installed successfully"
        else
            log "WARNING" "⚠️  Failed to install ripgrep"
        fi
    fi

    # Install/Update fzf (fuzzy finder)
    if command -v fzf >/dev/null 2>&1; then
        log "INFO" "📥 Updating fzf (fuzzy finder)..."
        if run_task_command "Updating fzf" "sudo apt update -qq 2>&1 | grep -v 'WARNING.*stable CLI interface' && sudo apt upgrade -y fzf 2>&1 | grep -v 'WARNING.*stable CLI interface'" "Updating fzf for fuzzy finding" "30s"; then
            log "SUCCESS" "✅ fzf updated successfully"
        else
            log "INFO" "ℹ️ fzf update via apt not available or already latest"
        fi
    else
        log "INFO" "📥 Installing fzf (fuzzy finder)..."
        if run_task_command "Installing fzf" "sudo apt update -qq 2>&1 | grep -v 'WARNING.*stable CLI interface' && sudo apt install -y fzf 2>&1 | grep -v 'WARNING.*stable CLI interface'" "Installing fzf for fuzzy finding" "30s"; then
            log "SUCCESS" "✅ fzf installed successfully"
        else
            log "WARNING" "⚠️  Failed to install fzf"
        fi
    fi

    # Set up fzf configuration (run for both install and update)
    local zshrc="$REAL_HOME/.zshrc"
    if [ -f "$zshrc" ] && ! grep -q "# fzf configuration" "$zshrc"; then
        cat >> "$zshrc" << 'EOF'

# fzf configuration for enhanced productivity
if command -v fzf >/dev/null 2>&1; then
    # Key bindings
    source /usr/share/doc/fzf/examples/key-bindings.zsh 2>/dev/null || true
    source /usr/share/doc/fzf/examples/completion.zsh 2>/dev/null || true

    # Use ripgrep for fzf if available
    if command -v rg >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git"'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi

    # Enhanced fzf options
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
fi

EOF
        log "SUCCESS" "✅ Added fzf configuration to .zshrc"
    fi

    # Install zoxide (smart cd replacement)
    if ! command -v zoxide >/dev/null 2>&1; then
        log "INFO" "📥 Installing zoxide (smart cd replacement)..."
        if curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ zoxide installed successfully"

            # Add zoxide to .zshrc
            local zshrc="$REAL_HOME/.zshrc"
            if [ -f "$zshrc" ] && ! grep -q "eval.*zoxide init" "$zshrc"; then
                cat >> "$zshrc" << 'EOF'

# zoxide configuration for smart directory navigation
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
    # Replace cd with z for smart navigation
    alias cd="z"
fi

EOF
                log "SUCCESS" "✅ Added zoxide configuration to .zshrc"
            fi
        else
            log "WARNING" "⚠️  Failed to install zoxide"
        fi
    else
        log "SUCCESS" "✅ zoxide already installed"
    fi

    # Install/Update fd (modern find replacement)
    if command -v fd >/dev/null 2>&1 || command -v fdfind >/dev/null 2>&1; then
        log "INFO" "📥 Updating fd (modern find replacement)..."
        if run_task_command "Updating fd" "sudo apt update -qq 2>&1 | grep -v 'WARNING.*stable CLI interface' && sudo apt upgrade -y fd-find 2>&1 | grep -v 'WARNING.*stable CLI interface'" "Updating fd for faster file finding" "30s"; then
            log "SUCCESS" "✅ fd updated successfully"
        else
            log "INFO" "ℹ️ fd update via apt not available or already latest"
        fi
        # Ensure fd symlink exists if we have fdfind
        if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
            local bin_dir="$REAL_HOME/.local/bin"
            mkdir -p "$bin_dir"
            ln -sf "$(which fdfind)" "$bin_dir/fd"
            log "SUCCESS" "✅ Created fd symlink for fdfind"
        fi
    else
        log "INFO" "📥 Installing fd (modern find replacement)..."
        if run_task_command "Installing fd" "sudo apt update -qq 2>&1 | grep -v 'WARNING.*stable CLI interface' && sudo apt install -y fd-find 2>&1 | grep -v 'WARNING.*stable CLI interface'" "Installing fd for faster file finding" "30s"; then
            log "SUCCESS" "✅ fd installed successfully"

            # Create fd symlink if it was installed as fd-find
            if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
                local bin_dir="$REAL_HOME/.local/bin"
                mkdir -p "$bin_dir"
                ln -sf "$(which fdfind)" "$bin_dir/fd"
                log "SUCCESS" "✅ Created fd symlink for fdfind"
            fi
        else
            log "WARNING" "⚠️  Failed to install fd"
        fi
    fi

    log "SUCCESS" "✅ Modern Unix tools installation completed"
}

# Install system dependencies
install_system_deps() {
    if $SKIP_DEPS; then
        log "INFO" "⏭️  Skipping system dependencies installation"
        return 0
    fi

    log "STEP" "🔧 Installing system dependencies..."

    # Update package list with progressive disclosure (suppress CLI warnings)
    if ! run_task_command "Updating package list" "sudo apt update -qq 2>&1 | grep -v 'WARNING.*stable CLI interface'" "Refreshing package repositories" "10-30s"; then
        log "ERROR" "Failed to update package list"
        return 1
    fi
    
    # Install essential dependencies (check what's already installed)
    local deps=(
        "build-essential" "pkg-config" "gettext" "libxml2-utils" "pandoc"
        "git" "curl" "wget" "unzip" "software-properties-common" "zsh"
        "libgtk-4-dev" "libadwaita-1-dev" "blueprint-compiler"
        "libgtk4-layer-shell-dev" "libfreetype-dev" "libharfbuzz-dev"
        "libfontconfig-dev" "libpng-dev" "libbz2-dev" "zlib1g-dev"
        "libglib2.0-dev" "libgio-2.0-dev" "libpango1.0-dev"
        "libgdk-pixbuf-2.0-dev" "libcairo2-dev" "libvulkan-dev"
        "libgraphene-1.0-dev" "libx11-dev" "libwayland-dev"
        "libonig-dev" "libxml2-dev" "flatpak"
        "xdotool" "scrot" "imagemagick" "gnome-screenshot"
        "eza" "bat" "ripgrep" "fzf" "fd-find"
    )

    # Check which packages are missing
    local missing_deps=()
    local installed_count=0

    log "INFO" "🔍 Checking which packages need installation..."
    for dep in "${deps[@]}"; do
        if dpkg -l "$dep" 2>/dev/null | grep -q "^ii"; then
            debug "✅ $dep already installed"
            installed_count=$((installed_count + 1))
        else
            debug "❌ $dep needs installation"
            missing_deps+=("$dep")
        fi
    done

    log "INFO" "📊 Found ${#missing_deps[@]} packages to install, ${installed_count} already installed"

    if [ ${#missing_deps[@]} -eq 0 ]; then
        log "SUCCESS" "✅ All system dependencies already installed"
    else
        log "INFO" "📦 Installing ${#missing_deps[@]} missing packages..."
        if run_task_command "Installing missing system dependencies" "sudo apt install -y $(echo ${missing_deps[@]})" "Installing only missing development tools and dependencies" "30s-2min"; then
            log "SUCCESS" "✅ System dependencies installed"
        else
            log "ERROR" "❌ Failed to install system dependencies"
            return 1
        fi
    fi
    
    # Add Flathub repository if not already added
    if ! flatpak remotes | grep -q flathub; then
        log "INFO" "🔗 Adding Flathub repository..."
        sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        log "SUCCESS" "✅ Flathub repository added"
    fi
}

# Install Zig
install_zig() {
    log "STEP" "⚡ Installing Zig 0.14.0..."
    
    if command -v zig >/dev/null 2>&1; then
        local current_version=$(zig version)
        if [[ "$current_version" == "0.14.0" ]]; then
            log "SUCCESS" "✅ Zig 0.14.0 already installed"
            return 0
        fi
    fi
    
    # Download and install Zig
    local zig_url="https://ziglang.org/download/0.14.0/zig-linux-x86_64-0.14.0.tar.xz"
    local zig_archive="/tmp/zig-linux-x86_64-0.14.0.tar.xz"
    local zig_dir="$APPS_DIR/zig"
    
    mkdir -p "$APPS_DIR"
    
    log "INFO" "📥 Downloading Zig 0.14.0..."
    if wget -O "$zig_archive" "$zig_url" >> "$LOG_FILE" 2>&1; then
        log "SUCCESS" "✅ Zig downloaded"
    else
        log "ERROR" "❌ Failed to download Zig"
        return 1
    fi
    
    log "INFO" "📂 Extracting Zig..."
    rm -rf "$zig_dir"
    mkdir -p "$zig_dir"
    tar -xf "$zig_archive" -C "$zig_dir" --strip-components=1
    rm "$zig_archive"
    
    # Create system-wide symlink
    sudo ln -sf "$zig_dir/zig" /usr/local/bin/zig
    
    # Verify installation
    if zig version | grep -q "0.14.0"; then
        log "SUCCESS" "✅ Zig 0.14.0 installed successfully"
    else
        log "ERROR" "❌ Zig installation verification failed"
        return 1
    fi
}

# Install or update Ghostty based on strategy
install_ghostty() {
    case "${GHOSTTY_STRATEGY:-fresh}" in
        "update")
            update_ghostty
            ;;
        "reconfig")
            reconfigure_ghostty
            ;;
        "config_only")
            log "STEP" "⚙️  Updating Ghostty configuration only (external installation detected)..."
            install_ghostty_configuration
            ;;
        "fresh"|*)
            fresh_install_ghostty
            ;;
    esac
}

# Fresh Ghostty installation
fresh_install_ghostty() {
    log "STEP" "👻 Fresh installation of Ghostty terminal emulator..."

    # First try to install via snap (preferred method)
    if command -v snap >/dev/null 2>&1; then
        log "INFO" "📦 Installing Ghostty via snap (recommended)..."
        if sudo snap install ghostty --classic >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ Ghostty installed successfully via snap"
            install_ghostty_configuration
            return 0
        else
            log "WARNING" "⚠️  Snap installation failed, falling back to building from source"
        fi
    fi

    # Fallback to building from source only if snap fails
    log "INFO" "🔨 Building Ghostty from source (fallback method)..."

    # Clone Ghostty repository
    if [ ! -d "$GHOSTTY_APP_DIR" ]; then
        log "INFO" "📥 Cloning Ghostty repository..."
        git clone https://github.com/ghostty-org/ghostty.git "$GHOSTTY_APP_DIR" >> "$LOG_FILE" 2>&1
        log "SUCCESS" "✅ Ghostty repository cloned"
    fi

    build_and_install_ghostty
    install_ghostty_configuration
}

# Update existing Ghostty installation
update_ghostty() {
    log "STEP" "🔄 Updating existing Ghostty installation..."
    
    # Update repository
    if [ -d "$GHOSTTY_APP_DIR" ]; then
        cd "$GHOSTTY_APP_DIR"
        log "INFO" "📥 Pulling latest changes..."
        git pull origin main >> "$LOG_FILE" 2>&1
        log "SUCCESS" "✅ Repository updated"
    else
        log "WARNING" "⚠️  Repository not found, performing fresh install"
        fresh_install_ghostty
        return
    fi
    
    # Check if rebuild is needed
    local needs_rebuild=false
    if [ ! -f "zig-out/bin/ghostty" ]; then
        needs_rebuild=true
        log "INFO" "🔨 Binary not found, rebuild required"
    else
        # Check if source is newer than binary
        if find . -name "*.zig" -newer "zig-out/bin/ghostty" | head -1 | grep -q .; then
            needs_rebuild=true
            log "INFO" "🔨 Source files updated, rebuild required"
        fi
    fi
    
    if $needs_rebuild; then
        build_and_install_ghostty
    else
        log "INFO" "✅ Ghostty binary is up to date"
    fi
    
    # Always update configuration to latest
    install_ghostty_configuration
}

# Reconfigure Ghostty (fix config issues)
reconfigure_ghostty() {
    log "STEP" "⚙️  Reconfiguring Ghostty (fixing configuration issues)..."
    
    # Backup existing config if it exists
    if [ -d "$GHOSTTY_CONFIG_DIR" ]; then
        local backup_dir="/tmp/ghostty-config-backup-$(date +%s)"
        cp -r "$GHOSTTY_CONFIG_DIR" "$backup_dir"
        log "INFO" "💾 Backed up existing config to $backup_dir"
    fi
    
    # Install fresh configuration
    install_ghostty_configuration
    
    # Verify the fix worked
    if ghostty +show-config >/dev/null 2>&1; then
        log "SUCCESS" "✅ Configuration issues resolved"
    else
        log "ERROR" "❌ Configuration issues persist"
        return 1
    fi
}

# Build and install Ghostty binary
build_and_install_ghostty() {
    cd "$GHOSTTY_APP_DIR"
    log "INFO" "🔨 Building Ghostty (this may take a while)..."
    
    # Clean previous build if it exists
    if [ -d "zig-out" ]; then
        rm -rf zig-out
    fi
    
    # Build Ghostty with progressive disclosure
    if run_task_command "Building Ghostty" "zig build -Doptimize=ReleaseFast" "Compiling Ghostty with optimizations" "2-3 minutes"; then
        log "SUCCESS" "✅ Ghostty built successfully"
    else
        log "ERROR" "❌ Ghostty build failed"
        return 1
    fi

    # Install Ghostty with progressive disclosure
    if run_task_command "Installing Ghostty" "sudo zig build install --prefix /usr/local" "Installing Ghostty to system" "30s"; then
        log "SUCCESS" "✅ Ghostty installed to /usr/local"
    else
        log "ERROR" "❌ Ghostty installation failed"
        return 1
    fi
}

# Install Ghostty configuration files
install_ghostty_configuration() {
    log "INFO" "⚙️  Installing Ghostty configuration..."
    mkdir -p "$GHOSTTY_CONFIG_DIR"
    
    # Copy configuration files from configs directory
    for config_file in config theme.conf scroll.conf layout.conf keybindings.conf; do
        if [ -f "$GHOSTTY_CONFIG_SOURCE/$config_file" ]; then
            cp "$GHOSTTY_CONFIG_SOURCE/$config_file" "$GHOSTTY_CONFIG_DIR/"
            log "SUCCESS" "✅ Copied $config_file"
        else
            log "WARNING" "⚠️  $config_file not found in $GHOSTTY_CONFIG_SOURCE"
        fi
    done

    # Deploy dircolors configuration (XDG-compliant location)
    if [ -f "$GHOSTTY_CONFIG_SOURCE/dircolors" ]; then
        mkdir -p "$REAL_HOME/.config"
        cp "$GHOSTTY_CONFIG_SOURCE/dircolors" "$REAL_HOME/.config/dircolors"
        log "SUCCESS" "✅ Deployed dircolors configuration to ~/.config/dircolors"

        # Ensure shell configs load dircolors (XDG-compliant)
        for shell_config in "$REAL_HOME/.bashrc" "$REAL_HOME/.zshrc"; do
            if [ -f "$shell_config" ]; then
                if ! grep -q 'XDG_CONFIG_HOME.*dircolors' "$shell_config" 2>/dev/null; then
                    echo '' >> "$shell_config"
                    echo '# XDG-compliant dircolors configuration' >> "$shell_config"
                    echo 'eval "$(dircolors ${XDG_CONFIG_HOME:-$HOME/.config}/dircolors)"' >> "$shell_config"
                    log "SUCCESS" "✅ Added dircolors to $(basename $shell_config)"
                fi
            fi
        done
    else
        log "WARNING" "⚠️  dircolors not found in $GHOSTTY_CONFIG_SOURCE"
    fi

    # Validate configuration
    if ghostty +show-config >/dev/null 2>&1; then
        log "SUCCESS" "✅ Ghostty configuration is valid"
    else
        log "WARNING" "⚠️  Ghostty configuration validation failed"
        return 1
    fi
}

# Install or update Ptyxis based on strategy
install_ptyxis() {
    if $SKIP_PTYXIS; then
        log "INFO" "⏭️  Skipping Ptyxis installation"
        return 0
    fi
    
    case "${PTYXIS_STRATEGY:-fresh}" in
        "update")
            update_ptyxis
            ;;
        "fresh"|*)
            fresh_install_ptyxis
            ;;
    esac
}

# Fresh Ptyxis installation (prefer official: apt, snap, then flatpak)
fresh_install_ptyxis() {
    log "STEP" "🐚 Fresh installation of Ptyxis terminal..."

    # Try apt first (official Ubuntu packages)
    log "INFO" "📥 Attempting Ptyxis installation via apt..."
    if apt-cache show ptyxis >/dev/null 2>&1; then
        if sudo apt update && sudo apt install -y ptyxis >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ Ptyxis installed via apt"
            configure_ptyxis_system
            return 0
        else
            log "WARNING" "⚠️  Ptyxis installation via apt failed, trying snap..."
        fi
    else
        log "INFO" "ℹ️ Ptyxis not available via apt, trying snap..."
    fi

    # Try snap second (official snap packages)
    log "INFO" "📥 Attempting Ptyxis installation via snap..."
    if snap find ptyxis 2>/dev/null | grep -q "ptyxis"; then
        if sudo snap install ptyxis >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ Ptyxis installed via snap"
            configure_ptyxis_system
            return 0
        else
            log "WARNING" "⚠️  Ptyxis installation via snap failed, falling back to flatpak..."
        fi
    else
        log "INFO" "ℹ️ Ptyxis not available via snap, falling back to flatpak..."
    fi

    # Fallback to flatpak
    log "INFO" "📥 Installing Ptyxis via flatpak (fallback)..."
    if flatpak install -y flathub app.devsuite.Ptyxis >> "$LOG_FILE" 2>&1; then
        log "SUCCESS" "✅ Ptyxis installed via flatpak"
        configure_ptyxis_flatpak
    else
        log "ERROR" "❌ Ptyxis installation failed via all methods"
        return 1
    fi
}

# Update existing Ptyxis installation based on installation method
update_ptyxis() {
    log "STEP" "🔄 Updating existing Ptyxis installation..."

    # Determine current installation method and update accordingly
    if dpkg -l 2>/dev/null | grep ptyxis | grep -q "^ii"; then
        log "INFO" "🔄 Updating Ptyxis via apt..."
        if run_task_command "Updating Ptyxis" "sudo apt update -qq 2>&1 | grep -v 'WARNING.*stable CLI interface' && sudo apt upgrade -y ptyxis 2>&1 | grep -v 'WARNING.*stable CLI interface'" "Updating Ptyxis to latest version via apt" "10-30s"; then
            log "SUCCESS" "✅ Ptyxis updated via apt"
        else
            log "WARNING" "⚠️  Ptyxis apt update may have failed"
        fi
        configure_ptyxis_system
    elif snap list 2>/dev/null | grep -q "ptyxis"; then
        log "INFO" "🔄 Updating Ptyxis via snap..."
        if sudo snap refresh ptyxis >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ Ptyxis updated via snap"
        else
            log "WARNING" "⚠️  Ptyxis snap update may have failed"
        fi
        configure_ptyxis_system
    elif flatpak list 2>/dev/null | grep -q "app.devsuite.Ptyxis"; then
        log "INFO" "🔄 Updating Ptyxis via flatpak..."
        if flatpak update -y app.devsuite.Ptyxis >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ Ptyxis updated via flatpak"
        else
            log "WARNING" "⚠️  Ptyxis flatpak update may have failed"
        fi
        configure_ptyxis_flatpak
    else
        log "WARNING" "⚠️  Could not determine Ptyxis installation method for update"
    fi
}

# Configure Ptyxis for system installations (apt/snap)
configure_ptyxis_system() {
    log "INFO" "🔧 Configuring Ptyxis (system installation)..."

    # Create gemini alias in both bashrc and zshrc for system installation
    for shell_config in "$REAL_HOME/.bashrc" "$REAL_HOME/.zshrc"; do
        if [ -f "$shell_config" ]; then
            # Check if Ptyxis system integration already exists
            if grep -q "ptyxis.*-d.*gemini" "$shell_config" && ! grep -q "flatpak" "$shell_config"; then
                log "SUCCESS" "✅ Ptyxis gemini integration already configured in $(basename "$shell_config")"
            else
                # Remove any existing gemini aliases
                if grep -q "alias gemini=" "$shell_config"; then
                    log "INFO" "🔄 Updating existing gemini alias in $(basename "$shell_config")"
                    sed -i '/alias gemini=/d' "$shell_config"
                fi

                # Add the system Ptyxis integration alias
                echo "" >> "$shell_config"
                echo "# Gemini CLI integration with Ptyxis (system)" >> "$shell_config"
                echo "# Uses fnm-managed Node.js (generic path, auto-resolves to current version)" >> "$shell_config"
                echo 'alias gemini='"'"'ptyxis -d "$(pwd)" -- gemini'"'" >> "$shell_config"
                log "SUCCESS" "✅ Added Ptyxis system gemini integration to $(basename "$shell_config")"
            fi
        fi
    done
}

# Configure Ptyxis for flatpak installation
configure_ptyxis_flatpak() {
    log "INFO" "🔧 Configuring Ptyxis (flatpak installation)..."

    # Grant necessary permissions for file access
    flatpak override app.devsuite.Ptyxis --filesystem=home >> "$LOG_FILE" 2>&1

    # Create gemini alias in both bashrc and zshrc for flatpak
    for shell_config in "$REAL_HOME/.bashrc" "$REAL_HOME/.zshrc"; do
        if [ -f "$shell_config" ]; then
            # Check if Ptyxis flatpak integration already exists
            if grep -q "flatpak run app.devsuite.Ptyxis.*gemini" "$shell_config"; then
                log "SUCCESS" "✅ Ptyxis flatpak gemini integration already configured in $(basename "$shell_config")"
            else
                # Remove any existing gemini aliases
                if grep -q "alias gemini=" "$shell_config"; then
                    log "INFO" "🔄 Updating existing gemini alias in $(basename "$shell_config")"
                    sed -i '/alias gemini=/d' "$shell_config"
                fi

                # Add the flatpak Ptyxis integration alias
                echo "" >> "$shell_config"
                echo "# Gemini CLI integration with Ptyxis (flatpak)" >> "$shell_config"
                echo "# Uses fnm-managed Node.js (generic path, auto-resolves to current version)" >> "$shell_config"
                echo 'alias gemini='"'"'flatpak run app.devsuite.Ptyxis -d "$(pwd)" -- gemini'"'" >> "$shell_config"
                log "SUCCESS" "✅ Added Ptyxis flatpak gemini integration to $(basename "$shell_config")"
            fi
        fi
    done
}

# Install uv Python package manager
install_uv() {
    log "STEP" "🐍 Installing uv Python package manager..."

    # Check if uv is already installed
    if command -v uv >/dev/null 2>&1; then
        local current_version=$(uv --version 2>/dev/null | awk '{print $2}' || echo "unknown")
        log "INFO" "✅ uv already installed: $current_version"

        # Update uv to latest version
        log "INFO" "🔄 Updating uv to latest version..."
        if curl -LsSf https://astral.sh/uv/install.sh | sh >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ uv updated successfully"
        else
            log "WARNING" "⚠️  uv update may have failed"
        fi
    else
        # Check if curl is available
        if ! command -v curl >/dev/null 2>&1; then
            log "ERROR" "❌ curl is required for uv installation but not found"
            return 1
        fi

        # Install uv
        log "INFO" "📥 Installing uv..."
        if curl -LsSf https://astral.sh/uv/install.sh | sh >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ uv installed successfully"
        else
            log "ERROR" "❌ uv installation failed"
            return 1
        fi
    fi

    # Add uv to PATH for current session
    export PATH="$HOME/.cargo/bin:$PATH"

    # Add uv to shell configurations
    for shell_config in "$REAL_HOME/.bashrc" "$REAL_HOME/.zshrc"; do
        if [ -f "$shell_config" ]; then
            if ! grep -q 'export PATH="$HOME/.cargo/bin:$PATH"' "$shell_config"; then
                echo "" >> "$shell_config"
                echo "# uv Python package manager" >> "$shell_config"
                echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$shell_config"
                log "SUCCESS" "✅ Added uv to PATH in $(basename "$shell_config")"
            else
                log "INFO" "ℹ️ uv PATH already configured in $(basename "$shell_config")"
            fi
        fi
    done

    # Verify installation
    if command -v uv >/dev/null 2>&1; then
        local version=$(uv --version 2>/dev/null | awk '{print $2}' || echo "unknown")
        log "SUCCESS" "✅ uv Python package manager ready: $version"
    else
        log "WARNING" "⚠️  uv may not be immediately available (restart shell)"
    fi
}

# Install Node.js via fnm (Fast Node Manager)
# Constitutional Compliance: AGENTS.md line 23 mandates fnm for performance
install_nodejs() {
    if $SKIP_NODE; then
        log "INFO" "⏭️  Skipping Node.js installation"
        return 0
    fi

    log "STEP" "📦 Installing Node.js via fnm (Fast Node Manager)..."
    log "INFO" "📊 Performance: fnm provides <50ms startup vs 500ms-3s for NVM"

    # Use modular install_node.sh script
    if source "${SCRIPT_DIR}/scripts/install_node.sh" && install_node_full "$NODE_VERSION"; then
        log "SUCCESS" "✅ Node.js installation complete via fnm"
        return 0
    else
        log "ERROR" "❌ Node.js installation failed"
        log "INFO" "ℹ️  Check logs: $LOG_FILE"
        return 1
    fi
}

# Install Claude Code CLI
install_claude_code() {
    if $SKIP_AI; then
        log "INFO" "⏭️  Skipping Claude Code installation"
        return 0
    fi

    log "STEP" "🤖 Installing Claude Code CLI..."

    # Check if Node.js and npm are available
    if ! command -v node >/dev/null 2>&1; then
        log "ERROR" "❌ Node.js is required for Claude Code but not found"
        return 1
    fi

    if ! command -v npm >/dev/null 2>&1; then
        log "ERROR" "❌ npm is required for Claude Code but not found"
        return 1
    fi

    # fnm handles Node.js environment automatically
    # No need to source anything - npm is available via fnm-managed Node.js

    # Install Claude Code globally
    if npm list -g claude-code >/dev/null 2>&1; then
        log "INFO" "🔄 Updating Claude Code..."
        if npm update -g claude-code >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ Claude Code updated"
        else
            log "WARNING" "⚠️  Claude Code update may have failed"
        fi
    else
        log "INFO" "📥 Installing Claude Code..."
        if npm install -g claude-code >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ Claude Code installed"
        else
            log "ERROR" "❌ Claude Code installation failed"
            return 1
        fi
    fi

    # Verify installation
    if command -v claude >/dev/null 2>&1; then
        local version=$(claude --version 2>/dev/null || echo "unknown")
        log "SUCCESS" "✅ Claude Code ready (version: $version)"
    else
        log "WARNING" "⚠️  Claude Code installed but not in PATH (may need shell restart)"
    fi
}

# Install Gemini CLI
install_gemini_cli() {
    if $SKIP_AI; then
        log "INFO" "⏭️  Skipping Gemini CLI installation"
        return 0
    fi

    log "STEP" "💎 Installing Gemini CLI..."

    # Check if Node.js and npm are available
    if ! command -v node >/dev/null 2>&1; then
        log "ERROR" "❌ Node.js is required for Gemini CLI but not found"
        return 1
    fi

    if ! command -v npm >/dev/null 2>&1; then
        log "ERROR" "❌ npm is required for Gemini CLI but not found"
        return 1
    fi

    # fnm handles Node.js environment automatically
    # No need to source anything - npm is available via fnm-managed Node.js

    # Install Gemini CLI globally
    if npm list -g @google/gemini-cli >/dev/null 2>&1; then
        log "INFO" "🔄 Updating Gemini CLI..."
        if npm update -g @google/gemini-cli >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ Gemini CLI updated"
        else
            log "WARNING" "⚠️  Gemini CLI update may have failed"
        fi
    else
        log "INFO" "📥 Installing Gemini CLI..."
        if npm install -g @google/gemini-cli >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ Gemini CLI installed"
        else
            log "ERROR" "❌ Gemini CLI installation failed"
            return 1
        fi
    fi

    # Create symlink for easier access (try to find the actual gemini binary)
    local gemini_path=""
    # Use fnm-managed Node.js to locate gemini
    if command -v gemini >/dev/null 2>&1; then
        gemini_path=$(which gemini)
    fi

    if [ -n "$gemini_path" ] && [ -f "$gemini_path" ]; then
        if sudo ln -sf "$gemini_path" /usr/local/bin/gemini 2>/dev/null; then
            log "SUCCESS" "✅ Gemini CLI installed and linked to /usr/local/bin/gemini"
        else
            log "INFO" "ℹ️ Gemini CLI installed (system link failed, but available via npm)"
        fi
    else
        log "WARNING" "⚠️  Gemini CLI installed but binary not found"
    fi

    # Verify installation
    if command -v gemini >/dev/null 2>&1; then
        log "SUCCESS" "✅ Gemini CLI ready and available"
    else
        log "WARNING" "⚠️  Gemini CLI installed but not in PATH (may need shell restart)"
    fi
}

# Setup daily automated updates
setup_daily_updates() {
    log "STEP" "🔄 Setting up daily automated updates..."

    # Check if scripts exist
    local daily_updates_script="$SCRIPT_DIR/scripts/daily-updates.sh"
    local view_logs_script="$SCRIPT_DIR/scripts/view-update-logs.sh"

    if [ ! -f "$daily_updates_script" ] || [ ! -f "$view_logs_script" ]; then
        log "ERROR" "❌ Daily updates scripts not found"
        return 1
    fi

    # Make scripts executable
    chmod +x "$daily_updates_script" "$view_logs_script" 2>/dev/null || true

    # Add aliases to .zshrc if not already present
    local zshrc_file="$REAL_HOME/.zshrc"
    if [ -f "$zshrc_file" ]; then
        if ! grep -q "update-all=" "$zshrc_file"; then
            log "INFO" "📝 Adding daily update aliases to .zshrc..."
            cat >> "$zshrc_file" << 'EOF'

# ============================================================================
# Daily Update System - Auto-generated by ghostty-config-files
# ============================================================================

# Alias for manual updates
alias update-all='/home/kkk/Apps/ghostty-config-files/scripts/daily-updates.sh'

# Alias for viewing update logs
alias update-logs='/home/kkk/Apps/ghostty-config-files/scripts/view-update-logs.sh'
alias update-logs-full='/home/kkk/Apps/ghostty-config-files/scripts/view-update-logs.sh --full'
alias update-logs-errors='/home/kkk/Apps/ghostty-config-files/scripts/view-update-logs.sh --errors'

# Display last update summary on terminal launch (using precmd hook for Powerlevel10k compatibility)
_show_update_summary_once() {
    # Remove this function from precmd after first run
    precmd_functions=(${precmd_functions:#_show_update_summary_once})

    if [[ -f "/tmp/daily-updates-logs/last-update-summary.txt" ]]; then
        # Only show once per day to avoid spam
        local last_shown_file="/tmp/.update-summary-shown-$(date +%Y%m%d)"
        if [[ ! -f "$last_shown_file" ]]; then
            echo ""
            echo "📊 Latest System Update Summary:"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            cat "/tmp/daily-updates-logs/last-update-summary.txt"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "💡 Commands: update-all | update-logs | update-logs-full | update-logs-errors"
            echo ""
            touch "$last_shown_file"
        fi
    fi
}

# Add to precmd hooks (runs before each prompt display, after instant prompt completes)
precmd_functions+=(_show_update_summary_once)

EOF
            log "SUCCESS" "✅ Daily update aliases added to .zshrc"
        else
            log "INFO" "ℹ️  Daily update aliases already present in .zshrc"
        fi
    else
        log "WARNING" "⚠️  .zshrc not found - update aliases not added"
    fi

    # Setup cron job for daily updates
    log "INFO" "⏰ Setting up daily automated updates (9:00 AM)..."

    # Create crontab entry
    local cron_entry="0 9 * * * $daily_updates_script >> /tmp/daily-updates-logs/cron-output.log 2>&1"

    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "$daily_updates_script"; then
        log "INFO" "ℹ️  Daily update cron job already configured"
    else
        # Add cron job
        (crontab -l 2>/dev/null; echo "# Daily System Updates - ghostty-config-files"; echo "$cron_entry") | crontab -
        if [ $? -eq 0 ]; then
            log "SUCCESS" "✅ Daily automated updates scheduled for 9:00 AM"
        else
            log "WARNING" "⚠️  Could not setup cron job - you can set it up manually"
            return 1
        fi
    fi

    # Check for passwordless sudo
    if ! sudo -n apt update >/dev/null 2>&1; then
        log "WARNING" "⚠️  Passwordless sudo not configured for apt"
        log "INFO" "ℹ️  Daily updates will run, but apt updates will be skipped"
        log "INFO" "ℹ️  To enable full automation, add this to sudoers:"
        log "INFO" "      kkk ALL=(ALL) NOPASSWD: /usr/bin/apt"
        log "INFO" "      Run: sudo EDITOR=nano visudo"
    else
        log "SUCCESS" "✅ Passwordless sudo configured for apt"
    fi

    log "SUCCESS" "✅ Daily update system configured successfully"
    log "INFO" "📋 Available commands:"
    log "INFO" "   • update-all - Run updates manually"
    log "INFO" "   • update-logs - View latest summary"
    log "INFO" "   • update-logs-full - View complete log"
    log "INFO" "   • update-logs-errors - View errors only"

    return 0
}

# Final verification
verify_installation() {
    log "STEP" "🔍 Verifying installations..."
    
    local status=0
    
    # Check Ghostty - verify it actually works
    if command -v ghostty >/dev/null 2>&1 && ghostty --version >/dev/null 2>&1; then
        local version=$(ghostty --version 2>/dev/null | head -1)
        log "SUCCESS" "✅ Ghostty: $version"
    else
        log "ERROR" "❌ Ghostty not found or not functioning properly"
        status=1
    fi
    
    # Check Ptyxis (prefer official: apt, snap, then flatpak)
    if ! $SKIP_PTYXIS; then
        local ptyxis_found=false
        local ptyxis_source=""

        # Check if Ptyxis actually works
        if command -v ptyxis >/dev/null 2>&1 && ptyxis --version >/dev/null 2>&1; then
            local ptyxis_version=$(ptyxis --version 2>/dev/null | head -1)

            # Determine installation source
            if dpkg -l 2>/dev/null | grep ptyxis | grep -q "^ii"; then
                ptyxis_source="apt"
            elif snap list 2>/dev/null | grep -q "ptyxis"; then
                ptyxis_source="snap"
            elif flatpak list 2>/dev/null | grep -q "app.devsuite.Ptyxis"; then
                ptyxis_source="flatpak"
            else
                ptyxis_source="unknown"
            fi

            log "SUCCESS" "✅ Ptyxis: $ptyxis_version (via $ptyxis_source)"
            ptyxis_found=true
        fi

        if ! $ptyxis_found; then
            log "ERROR" "❌ Ptyxis not found or not functioning"
            status=1
        fi
    fi
    
    # Check ZSH
    if command -v zsh >/dev/null 2>&1; then
        local current_shell=$(getent passwd "$USER" | cut -d: -f7)
        local zsh_path=$(which zsh)
        if [ "$current_shell" = "$zsh_path" ]; then
            log "SUCCESS" "✅ ZSH: Default shell with Oh My ZSH"
        else
            log "WARNING" "⚠️  ZSH: Installed but not default shell"
        fi
    else
        log "ERROR" "❌ ZSH not found"
        status=1
    fi

    # Check uv
    if command -v uv >/dev/null 2>&1; then
        local version=$(uv --version 2>/dev/null | awk '{print $2}' || echo "unknown")
        log "SUCCESS" "✅ uv Python package manager: $version"
    else
        log "WARNING" "⚠️  uv not found (may need shell restart)"
    fi

    # Check Node.js
    if ! $SKIP_NODE; then
        if command -v node >/dev/null 2>&1; then
            local version=$(node --version)
            log "SUCCESS" "✅ Node.js: $version"
        else
            log "ERROR" "❌ Node.js not found"
            status=1
        fi
    fi
    
    # Check AI tools
    if ! $SKIP_AI; then
        # Check Claude Code
        if command -v claude >/dev/null 2>&1 && claude --version >/dev/null 2>&1; then
            local claude_version=$(claude --version 2>/dev/null | head -1)
            log "SUCCESS" "✅ Claude Code: $claude_version"
        else
            log "WARNING" "⚠️  Claude Code not in PATH or not functioning (may need shell restart)"
        fi

        # Check Gemini CLI - try multiple locations
        local gemini_found=false
        local gemini_version=""

        # Try direct command
        if command -v gemini >/dev/null 2>&1 && gemini --version >/dev/null 2>&1; then
            gemini_version=$(gemini --version 2>/dev/null)
            gemini_found=true
        # Try /usr/local/bin/gemini
        elif [ -x "/usr/local/bin/gemini" ] && /usr/local/bin/gemini --version >/dev/null 2>&1; then
            gemini_version=$(/usr/local/bin/gemini --version 2>/dev/null)
            gemini_found=true
        # Try fnm-managed Node.js path
        else
            # Find gemini in fnm node versions (fallback)
            for node_path in "$HOME"/.local/share/fnm/node-versions/*/installation/bin/gemini; do
                if [ -x "$node_path" ] && "$node_path" --version >/dev/null 2>&1; then
                    gemini_version=$("$node_path" --version 2>/dev/null)
                    gemini_found=true
                    break
                fi
            done
        fi

        if $gemini_found; then
            log "SUCCESS" "✅ Gemini CLI: v$gemini_version"
        else
            log "WARNING" "⚠️  Gemini CLI not found or not functioning (may need shell restart)"
        fi
    fi
    
    return $status
}

# Show final instructions
show_final_instructions() {
    echo ""
    echo -e "${GREEN}🎉 Installation Complete!${NC}"
    echo ""
    echo -e "${CYAN}Environment Ready:${NC}"
    echo "✅ ZSH with Oh My ZSH and Powerlevel10k theme"
    echo "✅ Modern Unix tools (eza, bat, ripgrep, fzf, etc.)"
    echo "✅ Ghostty terminal with optimized configuration"
    if ! $SKIP_PTYXIS; then
        echo "✅ Ptyxis terminal with Gemini CLI integration"
    fi
    if ! $SKIP_AI; then
        echo "✅ Claude Code CLI and Gemini CLI"
    fi
    echo "✅ Complete screenshot and documentation system"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "1. The script will automatically restart your shell in 3 seconds"
    echo "2. Test Ghostty: ghostty"
    if ! $SKIP_PTYXIS; then
        echo "3. Test Ptyxis: flatpak run app.devsuite.Ptyxis"
        echo "4. Use Gemini in Ptyxis: gemini"
    fi
    if ! $SKIP_AI; then
        echo "5. Set up Claude Code: claude auth login"
        echo "6. Set up Gemini CLI with your API key"
    fi
    echo ""
    echo -e "${YELLOW}Configuration files:${NC}"
    echo "• Ghostty config: $GHOSTTY_CONFIG_DIR/"
    echo "• Session Logs: $LOG_SESSION_ID.*"
    echo "  - Main: $LOG_FILE"
    echo "  - Commands: $LOG_COMMANDS"
    echo "  - Errors: $LOG_ERRORS"
    echo ""
    if ! $SKIP_AI; then
        echo -e "${YELLOW}API Setup Required:${NC}"
        echo "• Claude Code: Get API key from https://console.anthropic.com"
        echo "• Gemini CLI: Get API key from https://makersuite.google.com/app/apikey"
        echo ""
    fi
}

# Install Ghostty context menu integration
install_context_menu() {
    log "STEP" "🖱️  Installing Ghostty context menu integration..."

    # Check if running on a desktop environment with Nautilus
    if ! command -v nautilus >/dev/null 2>&1; then
        log "INFO" "⏭️  Nautilus not found, skipping context menu integration"
        return 0
    fi

    # Create Nautilus scripts directory
    local scripts_dir="$REAL_HOME/.local/share/nautilus/scripts"
    mkdir -p "$scripts_dir"

    # Create the Nautilus script
    cat > "$scripts_dir/Open in Ghostty" << 'EOF'
#!/bin/bash

# Nautilus script to open selected folder in Ghostty terminal
# This script will appear in the right-click context menu

# Get the selected directory path
if [ -n "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" ]; then
    # Use the selected folder/file path
    TARGET_PATH="$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"

    # If it's a file, get its directory
    if [ -f "$TARGET_PATH" ]; then
        TARGET_PATH="$(dirname "$TARGET_PATH")"
    fi
else
    # If no selection, use current directory
    TARGET_PATH="$NAUTILUS_SCRIPT_CURRENT_URI"
    # Convert file:// URI to local path
    TARGET_PATH=$(echo "$TARGET_PATH" | sed 's|^file://||' | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))")
fi

# Launch Ghostty with the target directory as working directory
if command -v ghostty >/dev/null 2>&1; then
    cd "$TARGET_PATH" && ghostty &
else
    # Fallback notification if Ghostty is not found
    notify-send "Ghostty not found" "Please ensure Ghostty is installed and in your PATH"
fi
EOF

    # Make the script executable
    chmod +x "$scripts_dir/Open in Ghostty"

    # Create desktop file for better integration
    local apps_dir="$REAL_HOME/.local/share/applications"
    mkdir -p "$apps_dir"
    cat > "$apps_dir/ghostty-here.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Open Ghostty Here
Comment=Open Ghostty terminal in selected folder
Exec=ghostty --working-directory=%f
Icon=utilities-terminal
StartupNotify=true
NoDisplay=true
MimeType=inode/directory;
EOF

    # Update desktop database
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$apps_dir" 2>/dev/null || true
    fi

    # Restart Nautilus to apply changes (only if running)
    if pgrep nautilus >/dev/null 2>&1; then
        nautilus -q 2>/dev/null || true
        log "INFO" "🔄 Restarted Nautilus to apply context menu changes"
    fi

    log "SUCCESS" "✅ Ghostty context menu integration installed"
    log "INFO" "💡 Right-click any folder and select 'Scripts' > 'Open in Ghostty'"
}

# Restart shell environment to activate new configuration
restart_shell_environment() {
    echo ""
    echo -e "${GREEN}🔄 Restarting shell environment...${NC}"
    echo ""

    # Give user a moment to read the completion message
    for i in 3 2 1; do
        echo -ne "\r🔄 Shell restart in ${i} seconds... Press Ctrl+C to cancel"
        sleep 1
    done
    echo ""

    log "INFO" "🔄 Restarting shell with new configuration..."

    # Take final screenshot showing shell restart preparation
    if [ "$ENABLE_SCREENSHOTS" = "true" ] && [ -f "$SVG_CAPTURE_SCRIPT" ]; then
        capture_stage_screenshot "Shell Restart" "Activating new ZSH configuration with Powerlevel10k" 2
    fi

    # Source the new .zshrc first to ensure it's valid
    if [ -f "$REAL_HOME/.zshrc" ]; then
        log "INFO" "📋 Sourcing updated .zshrc configuration..."
        # Use exec to replace current shell process with new ZSH
        exec zsh -l
    else
        log "WARNING" "⚠️  .zshrc not found, manual shell restart recommended"
        echo "Please run: exec zsh"
    fi
}

# Main execution
main() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  Comprehensive Terminal Tools Installer${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""

    # Initialize comprehensive session tracking
    init_session_tracking

    # Start performance monitoring for entire operation
    monitor_performance "Complete Installation"

    log "INFO" "🚀 Starting comprehensive installation in $DETECTED_TERMINAL terminal..."
    log "INFO" "📋 Session tracking (ID: $LOG_SESSION_ID):"
    log "INFO" "   📄 Logs: $LOG_DIR/$LOG_SESSION_ID.*"
    log "INFO" "   📸 Screenshots: docs/assets/screenshots/$LOG_SESSION_ID/"
    log "INFO" "   📊 Manifest: $LOG_SESSION_MANIFEST"

    # Initialize SVG screenshot system
    if [ "$ENABLE_SCREENSHOTS" = "true" ] && [ -f "$SVG_CAPTURE_SCRIPT" ]; then
        "$SVG_CAPTURE_SCRIPT" setup
        create_installation_diagram
    fi

    # Capture initial desktop state
    capture_stage_screenshot "Initial Desktop" "Clean Ubuntu desktop before Ghostty installation" 4

    # Capture initial system state
    capture_system_state
    
    # Create necessary directories
    mkdir -p "$APPS_DIR"

    # Pre-authenticate sudo if needed
    if ! $SKIP_DEPS || ! $SKIP_PTYXIS; then
        if ! pre_auth_sudo; then
            log "ERROR" "❌ Installation cannot proceed without passwordless sudo"
            log "INFO" "💡 Please follow the instructions above and run ./start.sh again"
            exit 1
        fi
    fi

    # Check current installation status and determine strategies
    check_installation_status
    capture_stage_screenshot "System Check" "Installation status check and strategy determination" 3

    # Execute installation steps with failure tracking
    if install_system_deps; then
        track_success "System Dependencies" "All packages up to date"
    else
        track_failure "System Dependencies" "Some packages failed"
    fi
    capture_stage_screenshot "Dependencies" "System dependencies installation completed" 3

    if install_zsh; then
        track_success "ZSH & Oh My ZSH" "Shell environment configured"
    else
        track_warning "ZSH & Oh My ZSH" "Some configuration may be incomplete"
    fi
    capture_stage_screenshot "ZSH Setup" "ZSH and Oh My ZSH configuration" 3

    if install_modern_tools; then
        track_success "Modern Tools" "eza, bat, ripgrep, fzf, fd installed"
    else
        track_warning "Modern Tools" "Some tools may need updates"
    fi
    capture_stage_screenshot "Modern Tools" "Development tools and utilities installation" 3

    if install_zig; then
        track_success "Zig Compiler" "Version 0.14.0 ready"
    else
        track_failure "Zig Compiler" "Installation failed"
    fi
    capture_stage_screenshot "Zig Compiler" "Zig compiler installation and setup" 3

    if install_ghostty; then
        track_success "Ghostty Terminal" "Installed and configured"
    else
        track_warning "Ghostty Terminal" "Using existing installation"
    fi
    capture_stage_screenshot "Ghostty Build" "Ghostty terminal compilation from source" 4

    # Smart configuration update (always run to ensure latest optimizations)
    if $CONFIG_NEEDS_UPDATE || [ "$GHOSTTY_STRATEGY" = "fresh" ] || [ "$GHOSTTY_STRATEGY" = "reconfig" ]; then
        if update_ghostty_config; then
            track_success "Ghostty Configuration" "2025 optimizations applied"
        else
            track_failure "Ghostty Configuration" "Configuration update failed"
        fi
    else
        track_success "Ghostty Configuration" "Already optimized"
    fi
    capture_stage_screenshot "Configuration" "Ghostty configuration files and optimization setup" 3

    if install_context_menu; then
        track_success "Context Menu" "Right-click integration active"
    else
        track_warning "Context Menu" "May need manual activation"
    fi
    capture_stage_screenshot "Context Menu" "Right-click context menu integration" 2

    if install_ptyxis; then
        track_success "Ptyxis Terminal" "Installed and configured"
    else
        track_warning "Ptyxis Terminal" "Using existing installation"
    fi
    capture_stage_screenshot "Ptyxis Terminal" "Secondary terminal installation for comparison" 2

    if install_uv; then
        track_success "UV Package Manager" "Python tools ready"
    else
        track_failure "UV Package Manager" "Installation failed"
    fi
    capture_stage_screenshot "UV Package Manager" "Python uv package manager setup" 2

    # Setup screenshot dependencies after uv is available
    setup_screenshot_dependencies

    # Install Node.js (non-blocking)
    if install_nodejs; then
        track_success "Node.js/fnm" "Installed successfully"
    else
        track_failure "Node.js/fnm" "Installation failed - will be available after shell restart"
        log "INFO" "ℹ️  Continuing with remaining installations..."
    fi
    capture_stage_screenshot "Node.js Setup" "Node.js and fnm installation" 2

    # Install Claude Code (non-blocking)
    if install_claude_code; then
        track_success "Claude Code" "Installed successfully"
    else
        track_failure "Claude Code" "Installation failed - can retry manually"
        log "INFO" "ℹ️  Continuing with remaining installations..."
    fi
    capture_stage_screenshot "Claude Code" "Claude Code CLI installation and configuration" 2

    # Install Gemini CLI (non-blocking)
    if install_gemini_cli; then
        track_success "Gemini CLI" "Installed successfully"
    else
        track_failure "Gemini CLI" "Installation failed - can retry manually"
        log "INFO" "ℹ️  Continuing with remaining installations..."
    fi
    capture_stage_screenshot "Gemini CLI" "Google Gemini CLI setup and integration" 2

    # Setup daily automated updates (non-blocking)
    if setup_daily_updates; then
        track_success "Daily Updates" "Automated daily updates configured"
    else
        track_warning "Daily Updates" "Setup incomplete - can configure manually"
        log "INFO" "ℹ️  Continuing with remaining installations..."
    fi
    capture_stage_screenshot "Daily Updates" "Automated update system configuration" 2

    # Verify everything (non-blocking)
    start_timer
    if verify_installation; then
        end_timer "Installation verification"
        capture_stage_screenshot "Verification" "Installation verification and testing" 2
        log "SUCCESS" "🎉 Installation completed!"
    else
        log "INFO" "ℹ️  Installation completed with some optional components pending"
        capture_stage_screenshot "Warning State" "Installation completed with warnings" 2
    fi

    # End performance monitoring for entire operation
    end_performance_monitoring

    # Show comprehensive installation summary
    show_installation_summary

    # Show final instructions only if major components succeeded
    if [ ${#INSTALLATION_FAILURES[@]} -lt 3 ]; then
        show_final_instructions
    fi

    # Final system state capture
    capture_system_state

    # Finalize documentation and assets
    finalize_installation_docs

    # Finalize session tracking with statistics
    finalize_session_tracking

    log "INFO" "📊 Installation completed! Session: $LOG_SESSION_ID"
    log "INFO" "📋 Complete session data:"
    log "INFO" "   📄 Logs: ls -la $LOG_DIR/$LOG_SESSION_ID*"
    log "INFO" "   📸 Screenshots: ls -la docs/assets/screenshots/$LOG_SESSION_ID/"
    log "INFO" "   📊 Manifest: jq '.' $LOG_SESSION_MANIFEST"
    log "INFO" "🏷️  Terminal used: $DETECTED_TERMINAL"

    # Capture final completion state with all information displayed
    capture_stage_screenshot "Completion" "Complete installation with performance metrics and session data" 4

    # Automatic shell restart to activate new configuration
    restart_shell_environment
}

# Interactive menu for user-friendly configuration
show_interactive_menu() {
    # Skip menu if any arguments provided (command-line mode)
    if [ $# -gt 0 ]; then
        return 0
    fi

    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     Comprehensive Terminal Tools Installer - Setup Menu   ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}This installer will configure:${NC}"
    echo "  • ZSH shell with Oh My ZSH and modern tools"
    echo "  • Ghostty terminal with 2025 optimizations"
    echo "  • Ptyxis terminal emulator"
    echo "  • Node.js (via fnm - Fast Node Manager) and development tools"
    echo "  • Claude Code CLI and Gemini CLI"
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    # Ask about logging level
    echo -e "${CYAN}1. Logging Level${NC}"
    echo "   Choose how much information to display during installation:"
    echo ""
    echo "   [1] Standard  - Show important steps and results (recommended)"
    echo "   [2] Verbose   - Show detailed progress and debug information"
    echo "   [3] Debug     - Show all commands and system calls"
    echo ""
    read -p "   Select logging level [1-3] (default: 1): " logging_choice
    logging_choice=${logging_choice:-1}

    case $logging_choice in
        2) VERBOSE=true ;;
        3) DEBUG_MODE=true; VERBOSE=true ;;
        *) VERBOSE=false ;;
    esac

    echo ""
    echo -e "${YELLOW}───────────────────────────────────────────────────────────${NC}"
    echo ""

    # Ask about component selection
    echo -e "${CYAN}2. Component Selection${NC}"
    echo "   Choose which components to install:"
    echo ""
    echo "   [1] Full Installation    - Install everything (recommended)"
    echo "   [2] Custom Selection     - Choose specific components"
    echo "   [3] Config Only          - Only update configuration files"
    echo ""
    read -p "   Select installation type [1-3] (default: 1): " install_choice
    install_choice=${install_choice:-1}

    case $install_choice in
        2)
            echo ""
            echo -e "${CYAN}   Select components to SKIP (leave blank for none):${NC}"
            echo ""
            read -p "   Skip system dependencies? [y/N]: " skip_deps_choice
            [[ "$skip_deps_choice" =~ ^[Yy]$ ]] && SKIP_DEPS=true

            read -p "   Skip Node.js/fnm? [y/N]: " skip_node_choice
            [[ "$skip_node_choice" =~ ^[Yy]$ ]] && SKIP_NODE=true

            read -p "   Skip AI tools (Claude/Gemini)? [y/N]: " skip_ai_choice
            [[ "$skip_ai_choice" =~ ^[Yy]$ ]] && SKIP_AI=true

            read -p "   Skip Ptyxis terminal? [y/N]: " skip_ptyxis_choice
            [[ "$skip_ptyxis_choice" =~ ^[Yy]$ ]] && SKIP_PTYXIS=true
            ;;
        3)
            SKIP_DEPS=true
            SKIP_NODE=true
            SKIP_AI=true
            SKIP_PTYXIS=true
            ;;
        *)
            # Full installation - all flags remain false
            ;;
    esac

    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}Installation Summary:${NC}"
    echo ""
    echo "  Logging Level:      $([ "$DEBUG_MODE" = true ] && echo "Debug" || [ "$VERBOSE" = true ] && echo "Verbose" || echo "Standard")"
    echo "  System Dependencies: $([ "$SKIP_DEPS" = true ] && echo "Skip" || echo "Install")"
    echo "  Node.js/fnm:        $([ "$SKIP_NODE" = true ] && echo "Skip" || echo "Install")"
    echo "  AI Tools:           $([ "$SKIP_AI" = true ] && echo "Skip" || echo "Install")"
    echo "  Ptyxis Terminal:    $([ "$SKIP_PTYXIS" = true ] && echo "Skip" || echo "Install")"
    echo ""
    echo -e "${CYAN}📁 All logs will be saved to: $LOG_DIR${NC}"
    echo ""
    read -p "Press Enter to continue with this configuration, or Ctrl+C to cancel..."
    echo ""
}

# Run interactive menu first (if no command-line arguments provided)
show_interactive_menu "$@"

# Run main function
main "$@"