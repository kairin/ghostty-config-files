# manager-runner.sh Usage Guide

**Author**: Claude Code (Sonnet 4.5)
**Date**: 2025-11-21
**Purpose**: Complete guide to using the reusable TUI wrapper for component installation managers

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Architecture](#architecture)
4. [Step Format](#step-format)
5. [API Reference](#api-reference)
6. [Usage Examples](#usage-examples)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)
9. [Advanced Topics](#advanced-topics)

---

## Overview

### What is manager-runner.sh?

`manager-runner.sh` is a **reusable TUI (Terminal User Interface) wrapper** that provides Docker-like installation experience for all component managers in the ghostty-config-files repository.

**Key Innovation**: Component managers define installation steps as **DATA** (not code), then delegate all TUI orchestration to `manager-runner.sh`.

### Benefits

✅ **Zero Code Duplication** - All TUI logic in one place
✅ **Consistent UX** - All installers look identical
✅ **Easy Maintenance** - Change TUI behavior in one file
✅ **Data-Driven** - Component managers are pure configuration
✅ **Professional Styling** - Docker-like collapsible output with gum styling
✅ **Error Handling** - Automatic error detection and display
✅ **Progress Tracking** - Real-time step counters and duration display

### Visual Experience

**Component Header** (gum-styled):
```
╔═══════════════════════════════════════════════════════════╗
║              Installing Ghostty Terminal                  ║
╚═══════════════════════════════════════════════════════════╝
```

**Task Execution** (Collapsible with spinners):
```
✓ Check Prerequisites (5s)
⠋ Downloading Zig Compiler... (30s estimated)
✓ Downloaded Zig Compiler (32s)
⠋ Extracting Zig Tarball...
✓ Extracted Zig Tarball (12s)
...
```

**Component Footer** (Summary):
```
═══════════════════════════════════════════════════════════
✅ Ghostty Terminal installation SUCCESS (9/9 steps, 185s total)
═══════════════════════════════════════════════════════════
```

---

## Quick Start

### Creating a New Component Manager

**Step 1**: Create directory structure
```bash
mkdir -p lib/installers/my_component/steps
```

**Step 2**: Create `lib/installers/my_component/steps/common.sh`
```bash
#!/usr/bin/env bash
# Source repository root detection
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
export REPO_ROOT
```

**Step 3**: Create `lib/installers/my_component/install.sh`
```bash
#!/usr/bin/env bash
#
# My Component Installation Manager
# Purpose: Orchestrates installation of My Component
# Dependencies: (list dependencies here)
# Exit Codes: 0=success, 1=failure
#
# Architecture: Data-driven with modular TUI integration via manager-runner.sh

set -euo pipefail

# Get script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STEPS_DIR="${SCRIPT_DIR}/steps"

# Source common functions and modular TUI wrapper
source "${STEPS_DIR}/common.sh"
source "${REPO_ROOT}/lib/installers/common/manager-runner.sh"

# Main installation orchestrator
main() {
    # Define installation steps as data (not loops)
    # Format: "script.sh|Display Name|Estimated Duration (seconds)"
    declare -a INSTALL_STEPS=(
        "00-check-prerequisites.sh|Check Prerequisites|5"
        "01-download-package.sh|Download Package|30"
        "02-install-package.sh|Install Package|10"
        "03-configure.sh|Configure Component|10"
        "04-verify.sh|Verify Installation|5"
    )

    # One function call runs everything with full TUI integration
    run_install_steps "My Component" "$STEPS_DIR" "${INSTALL_STEPS[@]}"
}

# Execute main function
main "$@"
```

**Step 4**: Create individual step scripts
```bash
# Example: lib/installers/my_component/steps/00-check-prerequisites.sh
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${REPO_ROOT}/lib/core/logging.sh"

main() {
    log "INFO" "Checking prerequisites for My Component..."

    # Check if required command exists
    if ! command -v some_command &>/dev/null; then
        log "ERROR" "some_command is not installed"
        return 1
    fi

    log "SUCCESS" "All prerequisites satisfied"
    return 0
}

main "$@"
```

**Step 5**: Make scripts executable
```bash
chmod +x lib/installers/my_component/install.sh
chmod +x lib/installers/my_component/steps/*.sh
```

**Step 6**: Test your installer
```bash
./lib/installers/my_component/install.sh
```

**That's it!** - Your installer now has full TUI integration with Docker-like collapsible output, gum styling, spinners, error handling, and progress tracking.

---

## Architecture

### Flow Diagram

```
Component Manager (install.sh)
    │
    ├─ Source manager-runner.sh
    ├─ Define INSTALL_STEPS array (data)
    └─ Call run_install_steps()
         │
         ├─ Validate step format
         ├─ Initialize TUI system
         ├─ Show component header (gum-styled)
         │
         └─ For each step:
              ├─ Register task
              ├─ Start task (show spinner)
              ├─ Execute step script
              ├─ Complete task (show ✓) OR Fail task (show ✗)
              └─ Update progress
         │
         └─ Show component footer (summary)
```

### Data-Driven Architecture

**Before** (Hard-Coded Loop):
```bash
for step in "${steps[@]}"; do
    log "INFO" "Step ${step_num}/9: ${step%.sh}"

    if ! "${STEPS_DIR}/${step}"; then
        log "ERROR" "Installation failed at step ${step_num}: ${step}"
        return 1
    fi

    ((step_num++))
done
```

**After** (Data-Driven with manager-runner.sh):
```bash
declare -a INSTALL_STEPS=(
    "00-check.sh|Check Prerequisites|5"
    "01-download.sh|Download Package|30"
    "02-install.sh|Install Package|10"
)

run_install_steps "ComponentName" "$STEPS_DIR" "${INSTALL_STEPS[@]}"
```

**Benefits**:
- 40 lines of loop code eliminated
- All TUI logic centralized in manager-runner.sh
- Component manager is pure configuration (data, not code)

---

## Step Format

### Anatomy of a Step Definition

```bash
"SCRIPT|DISPLAY_NAME|DURATION"
```

**Fields** (pipe-delimited):

1. **SCRIPT**: Filename of the step script (e.g., `00-check-prerequisites.sh`)
2. **DISPLAY_NAME**: Human-readable task name (e.g., `Check Prerequisites`)
3. **DURATION**: Estimated duration in seconds (e.g., `5`)

### Examples

```bash
# Simple prerequisite check
"00-check-prerequisites.sh|Check Prerequisites|5"

# Download operation
"01-download-zig.sh|Download Zig Compiler|30"

# Long-running build
"04-build-ghostty.sh|Build Ghostty|90"

# Configuration step
"06-configure-ghostty.sh|Configure Ghostty|10"
```

### Field Guidelines

#### SCRIPT Field
- Must be a valid filename in the `steps/` directory
- Recommended naming: `##-action-target.sh` (e.g., `00-check-prerequisites.sh`)
- Must be executable (`chmod +x`)
- Must use `set -euo pipefail` for proper error handling

#### DISPLAY_NAME Field
- Short, descriptive, user-friendly
- Use title case (e.g., "Install Node.js")
- Avoid technical jargon if possible
- Max recommended length: 50 characters

#### DURATION Field
- Estimated time in seconds
- Used for progress tracking and user expectations
- Round to nearest 5 seconds for simplicity
- Examples:
  - Quick checks: 5s
  - Downloads: 20-30s
  - Builds: 60-120s
  - Installations: 10-15s

### Validation

manager-runner.sh automatically validates:
- ✓ Exactly 3 pipe-delimited fields
- ✓ No empty fields
- ✓ Duration is a positive integer
- ✓ Script file exists and is executable

**Example Error** (invalid format):
```
[ERROR] Invalid step format: '00-check.sh|Check Prerequisites' (expected: 'script|name|duration')
```

---

## API Reference

### Main Function

#### `run_install_steps()`

**Purpose**: Execute installation steps with full TUI integration

**Signature**:
```bash
run_install_steps COMPONENT_NAME STEPS_DIR INSTALL_STEPS[@]
```

**Parameters**:
1. `COMPONENT_NAME` - Display name (e.g., "Ghostty Terminal", "ZSH Shell")
2. `STEPS_DIR` - Absolute path to steps directory
3. `INSTALL_STEPS[@]` - Array of step definitions (format: "script|name|duration")

**Returns**:
- `0` - All steps completed successfully
- `1` - One or more steps failed
- `2` - Configuration error (invalid step format)

**Example**:
```bash
declare -a INSTALL_STEPS=(
    "00-check.sh|Check Prerequisites|5"
    "01-install.sh|Install Package|30"
)

run_install_steps "My Component" "$STEPS_DIR" "${INSTALL_STEPS[@]}"
```

### Helper Functions

#### `show_component_header()`

**Purpose**: Display styled header for component installation

**Signature**:
```bash
show_component_header COMPONENT_NAME
```

**Output** (gum-styled):
```
╔═══════════════════════════════════════════════════════════╗
║              Installing My Component                      ║
╚═══════════════════════════════════════════════════════════╝
```

#### `show_component_footer()`

**Purpose**: Display summary footer after installation

**Signature**:
```bash
show_component_footer COMPONENT_NAME TOTAL_STEPS STATUS
```

**Parameters**:
- `STATUS` - One of: `SUCCESS`, `FAILED`, `PARTIAL`

**Output**:
```
═══════════════════════════════════════════════════════════
✅ My Component installation SUCCESS (5/5 steps, 60s total)
═══════════════════════════════════════════════════════════
```

#### `validate_step_format()`

**Purpose**: Validate step definition format

**Signature**:
```bash
validate_step_format STEP_INFO
```

**Returns**:
- `0` - Valid format
- `1` - Invalid format

**Example**:
```bash
if validate_step_format "00-check.sh|Check Prerequisites|5"; then
    echo "Valid"
fi
```

#### `calculate_total_duration()`

**Purpose**: Sum estimated durations from all steps

**Signature**:
```bash
calculate_total_duration INSTALL_STEPS[@]
```

**Returns**: Total duration in seconds

**Example**:
```bash
total=$(calculate_total_duration "${INSTALL_STEPS[@]}")
echo "Estimated time: $(format_duration "$total")"
```

---

## Usage Examples

### Example 1: Simple 3-Step Installer

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STEPS_DIR="${SCRIPT_DIR}/steps"

source "${STEPS_DIR}/common.sh"
source "${REPO_ROOT}/lib/installers/common/manager-runner.sh"

main() {
    declare -a INSTALL_STEPS=(
        "00-check-prerequisites.sh|Check Prerequisites|5"
        "01-install-package.sh|Install Package|20"
        "02-verify.sh|Verify Installation|5"
    )

    run_install_steps "Simple Package" "$STEPS_DIR" "${INSTALL_STEPS[@]}"
}

main "$@"
```

### Example 2: Complex Multi-Stage Installer

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STEPS_DIR="${SCRIPT_DIR}/steps"

source "${STEPS_DIR}/common.sh"
source "${REPO_ROOT}/lib/installers/common/manager-runner.sh"

main() {
    # Stage 1: Prerequisites and downloads
    declare -a INSTALL_STEPS=(
        "00-check-prerequisites.sh|Check Prerequisites|5"
        "01-download-dependencies.sh|Download Dependencies|45"
        "02-extract-archives.sh|Extract Archives|15"

        # Stage 2: Build from source
        "03-configure-build.sh|Configure Build System|10"
        "04-compile-source.sh|Compile Source Code|120"
        "05-run-tests.sh|Run Test Suite|60"

        # Stage 3: Installation and configuration
        "06-install-binaries.sh|Install Binaries|10"
        "07-configure-system.sh|Configure System|15"
        "08-create-symlinks.sh|Create Symlinks|5"
        "09-verify-installation.sh|Verify Installation|5"
    )

    run_install_steps "Complex Build System" "$STEPS_DIR" "${INSTALL_STEPS[@]}"
}

main "$@"
```

### Example 3: Conditional Steps (Advanced)

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STEPS_DIR="${SCRIPT_DIR}/steps"

source "${STEPS_DIR}/common.sh"
source "${REPO_ROOT}/lib/installers/common/manager-runner.sh"

main() {
    # Build step array based on conditions
    declare -a INSTALL_STEPS=(
        "00-check-prerequisites.sh|Check Prerequisites|5"
    )

    # Add OS-specific steps
    if [[ "$(uname)" == "Linux" ]]; then
        INSTALL_STEPS+=(
            "01-install-apt-packages.sh|Install APT Packages|30"
        )
    elif [[ "$(uname)" == "Darwin" ]]; then
        INSTALL_STEPS+=(
            "01-install-brew-packages.sh|Install Homebrew Packages|30"
        )
    fi

    # Common steps
    INSTALL_STEPS+=(
        "02-configure.sh|Configure Component|10"
        "03-verify.sh|Verify Installation|5"
    )

    run_install_steps "Cross-Platform Component" "$STEPS_DIR" "${INSTALL_STEPS[@]}"
}

main "$@"
```

---

## Best Practices

### 1. Step Script Design

**DO**:
✅ Use `set -euo pipefail` for proper error handling
✅ Source required libraries (logging.sh, utils.sh)
✅ Log at appropriate levels (INFO, SUCCESS, ERROR)
✅ Return proper exit codes (0=success, 1=failure)
✅ Keep steps focused (single responsibility)
✅ Make steps idempotent (can run multiple times safely)

**DON'T**:
❌ Use hard-coded paths (use REPO_ROOT, SCRIPT_DIR)
❌ Ignore errors (always check command exit codes)
❌ Write overly long steps (split into multiple)
❌ Skip prerequisite checks (validate early)
❌ Use interactive prompts (breaks automation)

### 2. Duration Estimates

**Guidelines**:
- Round to nearest 5 seconds
- Over-estimate rather than under-estimate
- Test on slower hardware if possible
- Account for network variability (downloads)
- Consider build parallelization (`-j$(nproc)`)

**Examples**:
```bash
# Quick checks (no I/O)
"00-check-prerequisites.sh|Check Prerequisites|5"

# File operations (local disk)
"02-extract-tarball.sh|Extract Tarball|10"

# Network operations (variable)
"01-download-package.sh|Download Package|30"

# CPU-intensive operations
"04-build-project.sh|Build Project|90"
```

### 3. Display Names

**Guidelines**:
- Use active voice ("Install Package" not "Installing Package")
- Keep under 50 characters
- Use title case
- Be specific ("Install Node.js" not "Install")
- Match user expectations

**Examples**:
```bash
# Good
"Install Python UV Package Manager"
"Configure ZSH Shell Integration"
"Verify Ghostty Installation"

# Bad
"installing python uv"  # Wrong case
"Install"  # Too vague
"Installing Python UV Package Manager and Configuring Shell"  # Too long
```

### 4. Error Handling

**Step Script Pattern**:
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${REPO_ROOT}/lib/core/logging.sh"

main() {
    log "INFO" "Starting operation..."

    # Check prerequisites
    if ! command_exists "required_tool"; then
        log "ERROR" "required_tool is not installed"
        log "ERROR" "Install with: apt install required-tool"
        return 1
    fi

    # Perform operation with error checking
    if ! some_command --option arg; then
        log "ERROR" "some_command failed"
        return 1
    fi

    log "SUCCESS" "Operation complete"
    return 0
}

main "$@"
```

### 5. Idempotency

**Pattern for Idempotent Steps**:
```bash
main() {
    # Check if already installed
    if command_exists "my_tool" && [[ "$(my_tool --version)" == "1.2.3" ]]; then
        log "INFO" "my_tool 1.2.3 already installed (skipping)"
        return 0  # Success (idempotent)
    fi

    # Perform installation
    log "INFO" "Installing my_tool 1.2.3..."
    # ... installation logic ...

    log "SUCCESS" "my_tool 1.2.3 installed"
    return 0
}
```

---

## Troubleshooting

### Common Issues

#### Issue 1: Step Format Validation Error

**Symptom**:
```
[ERROR] Invalid step format: '00-check.sh|Check Prerequisites' (expected: 'script|name|duration')
```

**Cause**: Missing duration field

**Solution**:
```bash
# Wrong
"00-check.sh|Check Prerequisites"

# Correct
"00-check.sh|Check Prerequisites|5"
```

#### Issue 2: Step Script Not Found

**Symptom**:
```
[ERROR] Step script not found: /path/to/steps/00-check.sh
```

**Cause**: Script filename mismatch or file doesn't exist

**Solution**:
```bash
# Verify script exists
ls -la lib/installers/my_component/steps/

# Check filename matches INSTALL_STEPS array
grep "00-check" lib/installers/my_component/install.sh
```

#### Issue 3: Step Script Not Executable

**Symptom**:
```
[WARNING] Step script not executable, attempting to fix: /path/to/steps/00-check.sh
```

**Cause**: Script missing executable permission

**Solution**:
```bash
# Make all step scripts executable
chmod +x lib/installers/my_component/steps/*.sh
```

#### Issue 4: TUI Not Displaying

**Symptom**: Plain text output instead of styled TUI

**Cause**: gum not installed or TUI not initialized

**Solution**:
```bash
# Check if gum is installed
command -v gum

# Install gum
go install github.com/charmbracelet/gum@latest

# Verify TUI initialization in install.sh
grep "source.*manager-runner.sh" lib/installers/my_component/install.sh
```

#### Issue 5: Duration Not Displaying

**Symptom**: Duration shows as 0s

**Cause**: Invalid duration format (not a number)

**Solution**:
```bash
# Wrong
"00-check.sh|Check Prerequisites|five"

# Correct
"00-check.sh|Check Prerequisites|5"
```

---

## Advanced Topics

### Custom TUI Styling

If you need custom styling beyond the default, you can:

1. **Modify manager-runner.sh** (affects all installers)
2. **Call TUI functions directly** (component-specific styling)

**Example** (Custom header in component manager):
```bash
main() {
    # Initialize TUI
    source "${REPO_ROOT}/lib/ui/tui.sh"
    init_tui

    # Custom header
    show_box "My Custom Header" \
        "Version: 1.2.3" \
        "Author: John Doe" \
        "License: MIT"

    # Standard installation
    declare -a INSTALL_STEPS=(...)
    run_install_steps "My Component" "$STEPS_DIR" "${INSTALL_STEPS[@]}"
}
```

### Integration with start.sh

To integrate your component manager with the main `start.sh` orchestrator:

1. Add your component to the global components list
2. Source your installer in start.sh
3. Call your installer during orchestration

**Example**:
```bash
# In start.sh
source "${REPO_ROOT}/lib/installers/my_component/install.sh"

# Call during installation
if ! install_my_component; then
    log "ERROR" "My Component installation failed"
    exit 1
fi
```

### Parallel Execution (Future Enhancement)

Currently, component managers run sequentially. For parallel execution:

**Option 1**: Use GNU Parallel
```bash
parallel ::: \
    "./lib/installers/component1/install.sh" \
    "./lib/installers/component2/install.sh" \
    "./lib/installers/component3/install.sh"
```

**Option 2**: Background processes with wait
```bash
./lib/installers/component1/install.sh &
./lib/installers/component2/install.sh &
./lib/installers/component3/install.sh &
wait
```

**Note**: Parallel execution requires careful output buffering to avoid interleaved logs.

---

## Appendix

### Complete Example Project

**Directory Structure**:
```
lib/installers/example/
├── install.sh
└── steps/
    ├── common.sh
    ├── 00-check-prerequisites.sh
    ├── 01-download-package.sh
    ├── 02-install-package.sh
    ├── 03-configure.sh
    └── 04-verify.sh
```

**install.sh**:
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STEPS_DIR="${SCRIPT_DIR}/steps"

source "${STEPS_DIR}/common.sh"
source "${REPO_ROOT}/lib/installers/common/manager-runner.sh"

main() {
    declare -a INSTALL_STEPS=(
        "00-check-prerequisites.sh|Check Prerequisites|5"
        "01-download-package.sh|Download Package|30"
        "02-install-package.sh|Install Package|10"
        "03-configure.sh|Configure Component|10"
        "04-verify.sh|Verify Installation|5"
    )

    run_install_steps "Example Component" "$STEPS_DIR" "${INSTALL_STEPS[@]}"
}

main "$@"
```

### References

- **manager-runner.sh**: `/home/kkk/Apps/ghostty-config-files/lib/installers/common/manager-runner.sh`
- **TUI Library**: `/home/kkk/Apps/ghostty-config-files/lib/ui/tui.sh`
- **Collapsible Output**: `/home/kkk/Apps/ghostty-config-files/lib/ui/collapsible.sh`
- **Logging**: `/home/kkk/Apps/ghostty-config-files/lib/core/logging.sh`
- **Specification**: `/home/kkk/Apps/ghostty-config-files/documentation/specifications/001-modern-tui-system/spec.md`
- **Implementation Status**: `/home/kkk/Apps/ghostty-config-files/documentation/specifications/001-modern-tui-system/IMPLEMENTATION_STATUS.md`

---

**End of Guide**

**Version**: 1.0
**Last Updated**: 2025-11-21
**Status**: ACTIVE
