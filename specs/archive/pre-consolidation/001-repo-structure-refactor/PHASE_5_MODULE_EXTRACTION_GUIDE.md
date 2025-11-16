# Phase 5: Modular Scripts - Extraction Guide

**Date Created**: 2025-11-09
**Status**: In Progress (1/14 modules complete)
**Purpose**: Step-by-step guide for extracting modules from start.sh

---

## 🎯 Overview

Phase 5 breaks down the monolithic `start.sh` into 10+ fine-grained modules following the template pattern established in Phase 1. This enables:
- Independent testing (<10s per module)
- Better maintainability
- Clear separation of concerns
- Gradual migration without breaking existing functionality

---

## ✅ Completed Modules (1/14)

### 1. install_node.sh ✅
- **Location**: `scripts/install_node.sh`
- **Test**: `.runners-local/tests/unit/test_install_node.sh`
- **Functions**:
  - `install_nvm()` - Install/update NVM
  - `install_node()` - Install Node.js via NVM
  - `update_npm()` - Update npm to latest
  - `install_node_full()` - Complete Node.js setup
- **Status**: Complete with 6 passing unit tests
- **Test Time**: <2 seconds

---

## 📋 Remaining Modules (13/14)

### Installation Modules

#### 2. install_zig.sh
- **Source Function**: `install_zig()` (line 1993-2037 in start.sh)
- **Purpose**: Download and install Zig compiler
- **Dependencies**: curl, tar
- **Functions to Extract**:
  - `install_zig(version)` - Download and install Zig
  - `_verify_zig_installation()` - Verify Zig works
- **Test Cases**:
  - Zig installs successfully
  - Zig version matches requested
  - Handles download failures gracefully

#### 3. build_ghostty.sh
- **Source Functions**:
  - `install_ghostty()` (line 2038-2148)
  - `build_and_install_ghostty()` (line 2149-2175)
- **Purpose**: Clone, build, and install Ghostty terminal
- **Dependencies**: git, zig, gtk4-dev, libadwaita-dev
- **Functions to Extract**:
  - `clone_ghostty_repo(target_dir)` - Clone Ghostty repository
  - `build_ghostty(repo_dir)` - Compile Ghostty
  - `install_ghostty_binary(repo_dir)` - Install to ~/.local/bin
  - `build_and_install_ghostty()` - Complete Ghostty build process
- **Test Cases**:
  - Repository clones successfully
  - Build succeeds with valid Zig
  - Binary installs to correct location
  - Handles build failures gracefully

#### 4. install_system_deps.sh
- **Source Function**: `install_system_deps()` (line 1926-1992)
- **Purpose**: Install system dependencies via APT
- **Dependencies**: apt-get
- **Functions to Extract**:
  - `install_system_deps()` - Install all system dependencies
  - `_check_apt_lock()` - Wait for APT lock if necessary
- **Test Cases**:
  - APT packages install successfully
  - Handles locked APT gracefully
  - Skips already installed packages

#### 5. install_modern_tools.sh
- **Source Function**: `install_modern_tools()` (line 1736-1925)
- **Purpose**: Install modern Unix tools (bat, fd, ripgrep, etc.)
- **Dependencies**: apt-get, cargo (for some tools)
- **Functions to Extract**:
  - `install_modern_tools()` - Install all modern CLI tools
  - `_install_bat()` - Install bat (better cat)
  - `_install_fd()` - Install fd (better find)
  - `_install_ripgrep()` - Install ripgrep (better grep)
- **Test Cases**:
  - Each tool installs successfully
  - Tools are available in PATH
  - Handles installation failures gracefully

#### 6. install_uv.sh
- **Source Function**: `install_uv()` (line 2372-2430)
- **Purpose**: Install UV Python package manager
- **Dependencies**: curl
- **Functions to Extract**:
  - `install_uv()` - Install UV via official installer
  - `_verify_uv_installation()` - Verify UV works
- **Test Cases**:
  - UV installs successfully
  - UV is available in PATH
  - Handles installer failures gracefully

### AI Tool Modules

#### 7. install_claude_code.sh
- **Source Function**: `install_claude_code()` (line 2549-2599)
- **Purpose**: Install Claude Code CLI
- **Dependencies**: npm, node
- **Functions to Extract**:
  - `install_claude_code()` - Install Claude Code via npm
  - `_verify_claude_code()` - Verify installation
- **Test Cases**:
  - Claude Code installs via npm
  - CLI is available globally
  - Handles npm failures gracefully

#### 8. install_gemini_cli.sh
- **Source Function**: `install_gemini_cli()` (line 2600-2833)
- **Purpose**: Install Gemini CLI
- **Dependencies**: pip, python
- **Functions to Extract**:
  - `install_gemini_cli()` - Install Gemini CLI
  - `_configure_gemini_env()` - Setup environment variables
- **Test Cases**:
  - Gemini CLI installs successfully
  - Configuration is correct
  - Handles installation failures gracefully

### Configuration Modules

#### 9. setup_zsh.sh
- **Source Function**: `install_zsh()` (line 1432-1735)
- **Purpose**: Install and configure ZSH with Oh My ZSH
- **Dependencies**: zsh, git, curl
- **Functions to Extract**:
  - `install_zsh_shell()` - Install ZSH package
  - `install_oh_my_zsh()` - Install Oh My ZSH framework
  - `install_zsh_plugins()` - Install ZSH plugins
  - `configure_zshrc()` - Configure .zshrc
  - `set_default_shell()` - Set ZSH as default shell
- **Test Cases**:
  - ZSH installs successfully
  - Oh My ZSH installs without errors
  - Plugins install correctly
  - .zshrc is configured properly

#### 10. install_ghostty_config.sh
- **Source Function**: `install_ghostty_configuration()` (line 2176-2220)
- **Purpose**: Install Ghostty configuration files
- **Dependencies**: None
- **Functions to Extract**:
  - `install_ghostty_config()` - Copy configuration files
  - `_backup_existing_config()` - Backup existing configuration
  - `_verify_config()` - Validate configuration syntax
- **Test Cases**:
  - Config files copy successfully
  - Existing configs are backed up
  - Configuration validates correctly

#### 11. install_context_menu.sh ✅ (Already exists!)
- **Location**: `scripts/install_context_menu.sh`
- **Status**: Already extracted (line 2834+)
- **Action**: Verify it follows module contract, write unit test

### Optional/Conditional Modules

#### 12. install_ptyxis.sh
- **Source Functions**:
  - `install_ptyxis()` (line 2221-2314)
  - `configure_ptyxis_system()` (line 2315-2341)
  - `configure_ptyxis_flatpak()` (line 2342-2371)
- **Purpose**: Install and configure Ptyxis terminal (Flatpak)
- **Dependencies**: flatpak
- **Functions to Extract**:
  - `install_ptyxis_flatpak()` - Install Ptyxis via Flatpak
  - `configure_ptyxis()` - Configure Ptyxis settings
- **Test Cases**:
  - Flatpak installation works
  - Configuration applies correctly
  - Handles missing Flatpak gracefully

#### 13. configure_dircolors.sh
- **Source**: Dircolors configuration logic (scattered)
- **Purpose**: Setup XDG-compliant dircolors
- **Dependencies**: None
- **Functions to Extract**:
  - `install_dircolors()` - Copy dircolors to ~/.config/
  - `configure_shell_dircolors()` - Add dircolors to .bashrc/.zshrc
- **Test Cases**:
  - Dircolors file copies correctly
  - Shell RC files updated properly
  - XDG_CONFIG_HOME respected

#### 14. update_components.sh (NEW - for future)
- **Purpose**: Intelligent update of all components
- **Dependencies**: All installation modules
- **Functions to Create**:
  - `update_all_components()` - Update all installed components
  - `check_component_updates()` - Check for available updates
  - `update_component(name)` - Update specific component
- **Test Cases**:
  - Detects outdated components
  - Updates components individually
  - Preserves user customizations

---

## 🏗️ Module Template Pattern

### Directory Structure
```
scripts/
├── install_node.sh          ✅ Complete
├── install_zig.sh
├── build_ghostty.sh
├── install_system_deps.sh
├── install_modern_tools.sh
├── install_uv.sh
├── install_claude_code.sh
├── install_gemini_cli.sh
├── setup_zsh.sh
├── install_ghostty_config.sh
├── install_context_menu.sh  ✅ Exists (needs test)
├── install_ptyxis.sh
├── configure_dircolors.sh
└── update_components.sh

.runners-local/tests/unit/
├── test_install_node.sh     ✅ Complete (6 tests)
├── test_install_zig.sh
├── test_build_ghostty.sh
└── [... one test file per module]
```

### Module Structure (from .module-template.sh)
```bash
#!/bin/bash
# Module: [name].sh
# Purpose: [description]
# Dependencies: [external commands needed]
# Modules Required: [other bash modules needed]
# Exit Codes: 0=success, 1=failure, 2=[specific error]

set -euo pipefail

# Sourcing guard for testing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    SOURCED_FOR_TESTING=1
else
    SOURCED_FOR_TESTING=0
fi

# Source required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"  # For logging

# ============================================================
# MODULE CONFIGURATION
# ============================================================
: "${VAR_NAME:=default_value}"  # Environment variable defaults

# ============================================================
# PUBLIC FUNCTIONS (Module API)
# ============================================================
public_function() {
    # Implementation using common.sh log functions:
    # log_info, log_warn, log_error, log_debug
}

# ============================================================
# PRIVATE FUNCTIONS (Internal helpers)
# ============================================================
_private_helper() {
    # Internal implementation
}

# ============================================================
# MAIN EXECUTION (Skipped when sourced)
# ============================================================
if [[ "${SOURCED_FOR_TESTING}" -eq 0 ]]; then
    public_function "$@"
    exit $?
fi
```

### Test Structure (from .test-template.sh)
```bash
#!/bin/bash
# Unit Test: test_[module].sh
# Purpose: Unit tests for [module].sh
# Dependencies: test_functions.sh
# Exit Codes: 0=all pass, 1=failures

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_functions.sh"
source "${SCRIPT_DIR}/../../../scripts/[module].sh"

# Test cases using available assertions:
# - assert_equals
# - assert_not_equals
# - assert_contains
# - assert_success
# - assert_fails
# - assert_file_exists
# - assert_dir_exists
# - assert_completes_within
```

---

## 📝 Extraction Process (Step-by-Step)

For each module, follow this process:

### 1. Identify Source Function
```bash
# Find the function in start.sh
grep -n "^install_xyz()" start.sh
```

### 2. Extract to New Module
```bash
# Copy module template
cp scripts/.module-template.sh scripts/install_xyz.sh

# Fill in header
# - Module name
# - Purpose
# - Dependencies
# - Exit codes

# Extract function from start.sh
# Adapt to use common.sh logging (log_info, log_warn, log_error)
# Make executable
chmod +x scripts/install_xyz.sh
```

### 3. Create Unit Test
```bash
# Copy test template
cp .runners-local/tests/unit/.test-template.sh .runners-local/tests/unit/test_install_xyz.sh

# Write test cases:
# - Module sources successfully
# - Public functions exist
# - Basic functionality works
# - Error handling works

# Make executable
chmod +x .runners-local/tests/unit/test_install_xyz.sh

# Run tests
./.runners-local/tests/unit/test_install_xyz.sh
```

### 4. Integrate into manage.sh (Future)
```bash
# In manage.sh install command:
source "${SCRIPTS_DIR}/install_xyz.sh"
install_xyz || handle_error "xyz installation failed"
```

### 5. Update Documentation
```bash
# Update this file (PHASE_5_MODULE_EXTRACTION_GUIDE.md)
# Mark module as complete
# Update progress counter
```

---

## 🎯 Success Criteria Per Module

Each module must:
1. ✅ Follow template structure (.module-template.sh)
2. ✅ Source common.sh for logging
3. ✅ Use proper header comments
4. ✅ Have unit tests that run in <10 seconds
5. ✅ Have at least 4-6 test cases
6. ✅ Be independently executable
7. ✅ Be sourceable for testing
8. ✅ Pass shellcheck validation (optional but recommended)

---

## 🚀 Next Steps

**Immediate**:
1. Extract `install_zig.sh` (similar complexity to install_node.sh)
2. Extract `install_system_deps.sh` (straightforward APT installs)
3. Extract `install_uv.sh` (simple installer script)

**Medium Priority**:
4. Extract `build_ghostty.sh` (core functionality)
5. Extract `setup_zsh.sh` (complex but high value)
6. Extract `install_ghostty_config.sh` (configuration management)

**Lower Priority**:
7-13. Remaining modules (AI tools, optional components)

**Future**:
14. Create `update_components.sh` to orchestrate updates

---

## 📊 Progress Tracking

- **Total Modules**: 14
- **Completed**: 1 (install_node.sh)
- **In Progress**: 0
- **Remaining**: 13
- **Progress**: 7% complete

**Estimated Time**:
- Per module: 30-60 minutes (extraction + testing)
- Total remaining: 6-13 hours
- Can be done incrementally over multiple sessions

---

## 🔗 References

- **Module Template**: `scripts/.module-template.sh`
- **Test Template**: `.runners-local/tests/unit/.test-template.sh`
- **Example Module**: `scripts/install_node.sh`
- **Example Test**: `.runners-local/tests/unit/test_install_node.sh`
- **Source Code**: `start.sh` (functions to extract)
- **Spec**: `documentations/specifications/001-repo-structure-refactor/spec.md`
- **Implementation Status**: `documentations/specifications/001-repo-structure-refactor/IMPLEMENTATION_STATUS.md`

---

**Last Updated**: 2025-11-09
**Maintainer**: Project Team
**Status**: Active Development
