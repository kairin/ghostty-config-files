#!/usr/bin/env bash
# lib/tasks/python_uv.sh - Python + uv package manager installation
# Constitutional: uv EXCLUSIVE (prohibit pip/poetry/pipenv)
# Performance: uv is 10-100x faster than pip

set -euo pipefail

# Source required utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../core/logging.sh"
source "${SCRIPT_DIR}/../core/utils.sh"
source "${SCRIPT_DIR}/../core/state.sh"
source "${SCRIPT_DIR}/../core/errors.sh"
source "${SCRIPT_DIR}/../verification/duplicate_detection.sh"
source "${SCRIPT_DIR}/../verification/unit_tests.sh"

# Installation constants
readonly UV_INSTALL_URL="https://astral.sh/uv/install.sh"
readonly UV_BIN_DIR="${HOME}/.local/bin"
readonly UV_BINARY="${UV_BIN_DIR}/uv"

# Conflicting package managers (constitutional prohibition)
readonly PYTHON_CONFLICTING_MANAGERS=(
    "pip"
    "pip3"
    "poetry"
    "pipenv"
    "pdm"
)

#
# Check for conflicting Python package managers
#
# Returns:
#   0 = no conflicts
#   1 = conflicts detected (warnings logged)
#
check_conflicting_package_managers() {
    log "INFO" "Checking for conflicting package managers..."

    local conflicts_found=0

    for manager in "${PYTHON_CONFLICTING_MANAGERS[@]}"; do
        if command_exists "$manager"; then
            log "WARNING" "  ⚠ Conflicting package manager detected: $manager"
            log "WARNING" "    Constitutional requirement: uv EXCLUSIVE"
            log "WARNING" "    Recommendation: Uninstall $manager to avoid conflicts"
            conflicts_found=1
        fi
    done

    if [ $conflicts_found -eq 0 ]; then
        log "SUCCESS" "✓ No conflicting package managers detected"
    else
        log "INFO" ""
        log "INFO" "Constitutional Compliance Note:"
        log "INFO" "  - uv is the EXCLUSIVE Python package manager for this project"
        log "INFO" "  - pip/poetry/pipenv usage is PROHIBITED"
        log "INFO" "  - To remove conflicts: sudo apt remove python3-pip python3-poetry"
        log "INFO" ""
    fi

    return 0  # Non-blocking (warnings only)
}

#
# Add constitutional warning to shell RC files
#
# Adds warning message to .zshrc/.bashrc about uv-exclusive policy
#
add_constitutional_warning() {
    log "INFO" "Adding constitutional compliance warning to shell configuration..."

    local warning_block='
# ═══════════════════════════════════════════════════════════════
# CONSTITUTIONAL COMPLIANCE: UV EXCLUSIVE PYTHON PACKAGE MANAGER
# ═══════════════════════════════════════════════════════════════
# This project uses uv (Astral Systems) as the EXCLUSIVE Python package manager.
#
# PROHIBITED COMMANDS: pip, pip3, python -m pip, poetry, pipenv
#
# Usage:
#   uv pip install <package>     # Install package
#   uv pip uninstall <package>   # Remove package
#   uv pip list                  # List installed packages
#   uv pip freeze                # Generate requirements.txt
#   uv venv                      # Create virtual environment
#
# Documentation: https://github.com/astral-sh/uv
# ═══════════════════════════════════════════════════════════════
'

    for rc_file in "$HOME/.zshrc" "$HOME/.bashrc"; do
        if [ -f "$rc_file" ]; then
            if ! grep -q "CONSTITUTIONAL COMPLIANCE: UV EXCLUSIVE" "$rc_file" 2>/dev/null; then
                echo "$warning_block" >> "$rc_file"
                log "INFO" "  ✓ Added constitutional warning to $rc_file"
            else
                log "INFO" "  ↷ Constitutional warning already in $rc_file"
            fi
        fi
    done
}

#
# Install uv package manager
#
# Uses official Astral installation script
#
# Returns:
#   0 = success
#   1 = failure
#
install_uv() {
    log "INFO" "Installing uv package manager..."

    # Download and run official installer
    if ! curl -LsSf "$UV_INSTALL_URL" | sh 2>&1 | tee -a "$(get_log_file)"; then
        handle_error "install-uv" 1 "uv installation failed" \
            "Check internet connection" \
            "Verify access: curl -I $UV_INSTALL_URL" \
            "Try manual installation: https://github.com/astral-sh/uv"
        return 1
    fi

    # Verify binary exists
    if [ ! -f "$UV_BINARY" ]; then
        handle_error "install-uv" 2 "uv binary not found after installation" \
            "Expected location: $UV_BINARY" \
            "Check installation logs" \
            "Verify write permissions to $UV_BIN_DIR"
        return 1
    fi

    # Make executable (should already be, but ensure)
    chmod +x "$UV_BINARY"

    log "SUCCESS" "✓ uv installed to $UV_BINARY"
    return 0
}

#
# Configure shell integration for uv
#
# Adds uv to PATH and completion scripts
#
configure_shell_integration() {
    log "INFO" "Configuring shell integration..."

    # Add UV_BIN_DIR to PATH if not already present
    for rc_file in "$HOME/.zshrc" "$HOME/.bashrc"; do
        if [ -f "$rc_file" ]; then
            if ! grep -q "\.local/bin.*uv" "$rc_file" 2>/dev/null; then
                echo "" >> "$rc_file"
                echo "# uv (Astral Python package manager)" >> "$rc_file"
                echo "export PATH=\"${UV_BIN_DIR}:\$PATH\"" >> "$rc_file"
                log "INFO" "  ✓ Added uv to PATH in $rc_file"
            else
                log "INFO" "  ↷ uv already in PATH ($rc_file)"
            fi

            # Add shell completion (if supported by uv)
            if command_exists "uv" && uv --help | grep -q "completion" 2>/dev/null; then
                if ! grep -q "uv.*completion" "$rc_file" 2>/dev/null; then
                    echo "" >> "$rc_file"
                    echo "# uv shell completion" >> "$rc_file"

                    if [[ "$rc_file" == *".zshrc" ]]; then
                        echo 'eval "$(uv completion zsh)"' >> "$rc_file"
                    else
                        echo 'eval "$(uv completion bash)"' >> "$rc_file"
                    fi

                    log "INFO" "  ✓ Added uv completion to $rc_file"
                fi
            fi
        fi
    done

    log "SUCCESS" "✓ Shell integration configured"
}

#
# Benchmark uv performance (documentation only)
#
# Compares uv vs pip performance on simple operation
#
benchmark_uv_performance() {
    log "INFO" "Running uv performance benchmark..."

    # Only benchmark if pip is available for comparison
    if ! command_exists "pip" && ! command_exists "pip3"; then
        log "INFO" "  ↷ Skipping benchmark (pip not available for comparison)"
        return 0
    fi

    local pip_cmd="pip"
    command_exists "pip3" && pip_cmd="pip3"

    log "INFO" "  Benchmarking: uv vs $pip_cmd"

    # Simple benchmark: list installed packages
    local uv_start uv_end uv_duration
    local pip_start pip_end pip_duration

    # Benchmark uv
    uv_start=$(date +%s%N)
    "$UV_BINARY" pip list > /dev/null 2>&1 || true
    uv_end=$(date +%s%N)
    uv_duration=$(( (uv_end - uv_start) / 1000000 ))  # Convert to milliseconds

    # Benchmark pip
    pip_start=$(date +%s%N)
    $pip_cmd list > /dev/null 2>&1 || true
    pip_end=$(date +%s%N)
    pip_duration=$(( (pip_end - pip_start) / 1000000 ))

    # Calculate speedup
    local speedup
    if [ "$pip_duration" -gt 0 ]; then
        speedup=$(echo "scale=1; $pip_duration / $uv_duration" | bc)
    else
        speedup="N/A"
    fi

    log "INFO" ""
    log "INFO" "Performance Benchmark Results:"
    log "INFO" "  uv:   ${uv_duration}ms"
    log "INFO" "  $pip_cmd: ${pip_duration}ms"
    log "INFO" "  Speedup: ${speedup}x faster"
    log "INFO" ""

    return 0
}

#
# Install Python + uv package manager
#
# Process:
#   1. Check duplicate detection (skip if already installed)
#   2. Check for conflicting package managers (warn if detected)
#   3. Install uv via official installer
#   4. Configure shell integration
#   5. Add constitutional compliance warnings
#   6. Benchmark performance (optional)
#   7. Verify installation
#
# Returns:
#   0 = success
#   1 = failure
#
task_install_uv() {
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Installing Python + uv Package Manager"
    log "INFO" "════════════════════════════════════════"

    local task_start
    task_start=$(get_unix_timestamp)

    # Step 1: Duplicate Detection (Idempotency)
    log "INFO" "Checking for existing uv installation..."

    if verify_python_uv 2>/dev/null; then
        log "INFO" "↷ uv already installed and functional"
        mark_task_completed "install-uv" 0  # 0 seconds (skipped)
        return 0
    fi

    # Step 2: Check for conflicting package managers
    check_conflicting_package_managers

    # Step 3: Install uv
    if ! install_uv; then
        return 1
    fi

    # Step 4: Configure shell integration
    configure_shell_integration

    # Step 5: Add constitutional compliance warning
    add_constitutional_warning

    # Step 6: Benchmark performance (optional, non-blocking)
    benchmark_uv_performance || true

    # Step 7: Verify installation
    log "INFO" "Verifying installation..."

    if verify_python_uv; then
        local task_end
        task_end=$(get_unix_timestamp)
        local duration
        duration=$(calculate_duration "$task_start" "$task_end")

        mark_task_completed "install-uv" "$duration"

        log "SUCCESS" "════════════════════════════════════════"
        log "SUCCESS" "✓ uv installed successfully ($(format_duration "$duration"))"
        log "SUCCESS" "════════════════════════════════════════"
        log "INFO" ""
        log "INFO" "Next steps:"
        log "INFO" "  1. Restart terminal or run: source ~/.zshrc (or ~/.bashrc)"
        log "INFO" "  2. Verify: uv --version"
        log "INFO" "  3. Usage: uv pip install <package>"
        log "INFO" "  4. Documentation: https://github.com/astral-sh/uv"
        log "INFO" ""
        log "INFO" "Constitutional Compliance:"
        log "INFO" "  ✓ uv EXCLUSIVE Python package manager"
        log "INFO" "  ✓ pip/poetry/pipenv usage PROHIBITED"
        return 0
    else
        handle_error "install-uv" 3 "Installation verification failed" \
            "Check logs for errors" \
            "Try manual verification: ~/.local/bin/uv --version"
        return 1
    fi
}

# Export functions
export -f check_conflicting_package_managers
export -f add_constitutional_warning
export -f install_uv
export -f configure_shell_integration
export -f benchmark_uv_performance
export -f task_install_uv
