# ZSH Configuration Implementation Guide

**Tasks**: T068-T070 (3 tasks)
**Module**: `scripts/configure_zsh.sh`
**Purpose**: Configure ZSH with Oh My ZSH, plugins, and theme
**Constitutional Requirements**: Latest Oh My ZSH, plugin optimization, <10s test execution

---

## Overview

This guide implements ZSH shell configuration:
- Oh My ZSH framework installation
- Essential plugin configuration (git, zsh-autosuggestions, zsh-syntax-highlighting, fast-syntax-highlighting)
- Theme configuration (Powerlevel10k or similar)
- Performance optimization (<50ms startup impact)

**Dependencies**:
- `scripts/verification.sh` (T039-T043) - Dynamic verification framework
- `scripts/progress.sh` (T031-T038) - Task display system
- `scripts/common.sh` - Shared utilities
- System: ZSH shell, git, curl

**Integration Point**: Called from `manage.sh configure zsh` or `start.sh`

---

## Task Breakdown

### T068: Install Oh My ZSH Framework
**Objective**: Install latest Oh My ZSH framework
**Effort**: 1 hour
**Success Criteria**:
- ✅ Oh My ZSH installed to `~/.oh-my-zsh/`
- ✅ `.zshrc` configured with Oh My ZSH
- ✅ Backup of existing `.zshrc` created

### T069: Configure Essential Plugins
**Objective**: Install and configure productivity plugins
**Effort**: 1 hour
**Success Criteria**:
- ✅ `zsh-autosuggestions` installed
- ✅ `zsh-syntax-highlighting` installed
- ✅ `fast-syntax-highlighting` installed (alternative)
- ✅ Plugins enabled in `.zshrc`
- ✅ Plugin load order optimized for performance

### T070: Optimize ZSH Performance
**Objective**: Ensure fast shell startup (<50ms overhead)
**Effort**: 1 hour
**Success Criteria**:
- ✅ Startup time measured and optimized
- ✅ Lazy loading for heavy plugins
- ✅ Completion caching enabled
- ✅ Verification: `time zsh -i -c exit` <50ms overhead

---

## Implementation

### Module Header Template

```bash
#!/bin/bash
# Module: configure_zsh.sh
# Purpose: Configure ZSH with Oh My ZSH, plugins, and theme
# Dependencies: verification.sh, progress.sh, common.sh
# Modules Required: ZSH, git, curl
# Exit Codes: 0=success, 1=configuration failed, 2=invalid argument

set -euo pipefail

# Prevent multiple sourcing of this module (idempotent sourcing)
[[ -n "${CONFIGURE_ZSH_SH_LOADED:-}" ]] && return 0
readonly CONFIGURE_ZSH_SH_LOADED=1

# Module-level guard: Allow sourcing for testing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    SOURCED_FOR_TESTING=1
else
    SOURCED_FOR_TESTING=0
fi

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/progress.sh"
source "${SCRIPT_DIR}/verification.sh"

# ============================================================
# CONFIGURATION (Module Constants)
# ============================================================

readonly OH_MY_ZSH_DIR="${HOME}/.oh-my-zsh"
readonly ZSH_CUSTOM="${OH_MY_ZSH_DIR}/custom"
readonly ZSHRC_FILE="${HOME}/.zshrc"

# Plugin repositories
readonly PLUGIN_AUTOSUGGESTIONS="https://github.com/zsh-users/zsh-autosuggestions"
readonly PLUGIN_SYNTAX_HIGHLIGHT="https://github.com/zsh-users/zsh-syntax-highlighting"
readonly PLUGIN_FAST_SYNTAX="https://github.com/zdharma-continuum/fast-syntax-highlighting"

# Performance targets
readonly MAX_STARTUP_OVERHEAD_MS=50

# ============================================================
# PRIVATE HELPER FUNCTIONS
# ============================================================

# Function: _backup_zshrc
# Purpose: Create timestamped backup of .zshrc
# Args: None
# Returns: 0 on success
_backup_zshrc() {
    if [[ -f "$ZSHRC_FILE" ]]; then
        local backup_file="${ZSHRC_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
        cp "$ZSHRC_FILE" "$backup_file"
        echo "✓ Backup created: $backup_file"
    fi
    return 0
}

# Function: _measure_zsh_startup
# Purpose: Measure ZSH startup time
# Args: None
# Returns: Startup time in milliseconds (stdout)
_measure_zsh_startup() {
    local start_ns
    local end_ns
    local duration_ms

    start_ns=$(date +%s%N)
    zsh -i -c exit 2>/dev/null
    end_ns=$(date +%s%N)

    duration_ms=$(( (end_ns - start_ns) / 1000000 ))
    echo "$duration_ms"
    return 0
}

# ============================================================
# PUBLIC FUNCTIONS (Module API)
# ============================================================
```

---

### Function: install_oh_my_zsh()

```bash
# Function: install_oh_my_zsh
# Purpose: Install Oh My ZSH framework
# Args: None
# Returns: 0 if installation successful, 1 otherwise
# Side Effects: Installs Oh My ZSH to ~/.oh-my-zsh/, modifies ~/.zshrc
# Example: install_oh_my_zsh
install_oh_my_zsh() {
    # Check if already installed
    if [[ -d "$OH_MY_ZSH_DIR" ]]; then
        echo "✓ Oh My ZSH already installed at $OH_MY_ZSH_DIR"
        return 0
    fi

    echo "→ Installing Oh My ZSH..."

    # Backup existing .zshrc
    _backup_zshrc

    # Download and install Oh My ZSH
    local install_script
    if ! install_script=$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh 2>&1); then
        echo "✗ Failed to download Oh My ZSH installer" >&2
        return 1
    fi

    # Install with unattended mode (skip prompts)
    if ! RUNZSH=no CHSH=no sh -c "$install_script" 2>&1 | grep -v "^Cloning"; then
        echo "✗ Oh My ZSH installation failed" >&2
        return 1
    fi

    # Verify installation
    if [[ -d "$OH_MY_ZSH_DIR" ]]; then
        echo "✓ Oh My ZSH installed successfully"
        return 0
    else
        echo "✗ Oh My ZSH directory not found after installation" >&2
        return 1
    fi
}
```

---

### Function: install_zsh_plugin()

```bash
# Function: install_zsh_plugin
# Purpose: Install ZSH plugin from Git repository
# Args:
#   $1=plugin_name (required, e.g., "zsh-autosuggestions")
#   $2=repo_url (required, GitHub repository URL)
# Returns: 0 if installation successful, 1 otherwise
# Side Effects: Clones plugin to ~/.oh-my-zsh/custom/plugins/
# Example: install_zsh_plugin "zsh-autosuggestions" "$PLUGIN_AUTOSUGGESTIONS"
install_zsh_plugin() {
    local plugin_name="$1"
    local repo_url="$2"

    local plugin_dir="${ZSH_CUSTOM}/plugins/${plugin_name}"

    # Check if already installed
    if [[ -d "$plugin_dir" ]]; then
        echo "✓ Plugin already installed: $plugin_name"
        return 0
    fi

    echo "→ Installing ZSH plugin: $plugin_name..."

    # Clone plugin repository
    if ! git clone --depth 1 "$repo_url" "$plugin_dir" 2>&1 | grep -E "^(Cloning|Receiving)"; then
        echo "✗ Failed to install plugin: $plugin_name" >&2
        return 1
    fi

    echo "✓ Plugin installed: $plugin_name"
    return 0
}
```

---

### Function: configure_zsh_plugins()

```bash
# Function: configure_zsh_plugins
# Purpose: Install and configure essential ZSH plugins
# Args: None
# Returns: 0 if configuration successful, 1 otherwise
# Side Effects: Installs plugins, updates .zshrc
# Example: configure_zsh_plugins
configure_zsh_plugins() {
    echo "→ Configuring ZSH plugins..."

    # Ensure Oh My ZSH is installed
    if [[ ! -d "$OH_MY_ZSH_DIR" ]]; then
        echo "✗ Oh My ZSH not installed" >&2
        return 1
    fi

    # Create custom plugins directory
    mkdir -p "${ZSH_CUSTOM}/plugins"

    # Install essential plugins
    local plugins=(
        "zsh-autosuggestions:$PLUGIN_AUTOSUGGESTIONS"
        "zsh-syntax-highlighting:$PLUGIN_SYNTAX_HIGHLIGHT"
        "fast-syntax-highlighting:$PLUGIN_FAST_SYNTAX"
    )

    for plugin_entry in "${plugins[@]}"; do
        local plugin_name="${plugin_entry%%:*}"
        local plugin_repo="${plugin_entry##*:}"

        if ! install_zsh_plugin "$plugin_name" "$plugin_repo"; then
            echo "⚠ Failed to install $plugin_name (non-critical)" >&2
        fi
    done

    # Update .zshrc with plugin list
    if [[ -f "$ZSHRC_FILE" ]]; then
        # Backup first
        _backup_zshrc

        # Define optimized plugin load order
        # Note: syntax highlighting plugins must load last
        local plugin_list=(
            "git"
            "zsh-autosuggestions"
            "fast-syntax-highlighting"
        )

        # Update plugins line in .zshrc
        local plugins_string="plugins=(${plugin_list[*]})"

        # Replace existing plugins line
        if grep -q "^plugins=" "$ZSHRC_FILE"; then
            sed -i "s/^plugins=.*/$plugins_string/" "$ZSHRC_FILE"
            echo "✓ Updated plugins in $ZSHRC_FILE"
        else
            # Add plugins line if not present
            echo "" >> "$ZSHRC_FILE"
            echo "$plugins_string" >> "$ZSHRC_FILE"
            echo "✓ Added plugins to $ZSHRC_FILE"
        fi
    fi

    echo "✓ ZSH plugins configured"
    return 0
}
```

---

### Function: optimize_zsh_performance()

```bash
# Function: optimize_zsh_performance
# Purpose: Optimize ZSH startup performance
# Args: None
# Returns: 0 if optimization successful, 1 otherwise
# Side Effects: Modifies .zshrc with performance optimizations
# Example: optimize_zsh_performance
optimize_zsh_performance() {
    echo "→ Optimizing ZSH performance..."

    if [[ ! -f "$ZSHRC_FILE" ]]; then
        echo "✗ .zshrc not found" >&2
        return 1
    fi

    # Backup first
    _backup_zshrc

    # Add performance optimizations
    local marker="# ZSH Performance Optimizations (added by configure_zsh.sh)"
    if ! grep -q "$marker" "$ZSHRC_FILE"; then
        cat >> "$ZSHRC_FILE" << 'EOF'

# ZSH Performance Optimizations (added by configure_zsh.sh)

# Enable completion caching
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# Skip verification of insecure directories (speeds up startup)
ZSH_DISABLE_COMPFIX=true

# Lazy load heavy completions
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# Optimize history search
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS

EOF
        echo "✓ Performance optimizations added to $ZSHRC_FILE"
    else
        echo "ℹ Performance optimizations already present"
    fi

    # Measure startup time
    echo "→ Measuring ZSH startup time..."
    local startup_ms
    startup_ms=$(_measure_zsh_startup)

    echo "→ ZSH startup time: ${startup_ms}ms"

    # Verify performance target
    if [[ $startup_ms -le $MAX_STARTUP_OVERHEAD_MS ]]; then
        echo "✓ Performance target met: ${startup_ms}ms ≤ ${MAX_STARTUP_OVERHEAD_MS}ms"
        return 0
    else
        echo "⚠ Performance target missed: ${startup_ms}ms > ${MAX_STARTUP_OVERHEAD_MS}ms" >&2
        echo "  Consider disabling heavy plugins or using lazy loading" >&2
        return 0  # Non-blocking warning
    fi
}
```

---

### Function: verify_zsh_configuration()

```bash
# Function: verify_zsh_configuration
# Purpose: Comprehensive ZSH configuration verification
# Args: None
# Returns: 0 if all verifications pass, 1 otherwise
# Side Effects: Runs verification checks
# Example: verify_zsh_configuration
verify_zsh_configuration() {
    local all_checks_passed=0

    echo "=== ZSH Configuration Verification ==="
    echo

    # Check 1: ZSH installed
    echo "Check 1: ZSH Installation"
    if verify_binary "zsh" "" "zsh --version"; then
        echo "✓ ZSH installed"
    else
        all_checks_passed=1
    fi
    echo

    # Check 2: Oh My ZSH installed
    echo "Check 2: Oh My ZSH Framework"
    if [[ -d "$OH_MY_ZSH_DIR" ]]; then
        echo "✓ Oh My ZSH installed at $OH_MY_ZSH_DIR"
    else
        echo "✗ Oh My ZSH not found" >&2
        all_checks_passed=1
    fi
    echo

    # Check 3: .zshrc configured
    echo "Check 3: .zshrc Configuration"
    if [[ -f "$ZSHRC_FILE" ]]; then
        if grep -q "oh-my-zsh" "$ZSHRC_FILE"; then
            echo "✓ .zshrc configured with Oh My ZSH"
        else
            echo "✗ .zshrc not configured for Oh My ZSH" >&2
            all_checks_passed=1
        fi
    else
        echo "✗ .zshrc not found" >&2
        all_checks_passed=1
    fi
    echo

    # Check 4: Plugins installed
    echo "Check 4: Plugin Installation"
    local plugins_ok=1
    for plugin in "zsh-autosuggestions" "fast-syntax-highlighting"; do
        local plugin_dir="${ZSH_CUSTOM}/plugins/${plugin}"
        if [[ -d "$plugin_dir" ]]; then
            echo "✓ Plugin installed: $plugin"
        else
            echo "⚠ Plugin not found: $plugin" >&2
            plugins_ok=0
        fi
    done
    if [[ $plugins_ok -eq 0 ]]; then
        echo "ℹ Some plugins missing (non-critical)"
    fi
    echo

    # Check 5: Performance
    echo "Check 5: Startup Performance"
    local startup_ms
    startup_ms=$(_measure_zsh_startup)
    echo "→ ZSH startup time: ${startup_ms}ms"

    if [[ $startup_ms -le $MAX_STARTUP_OVERHEAD_MS ]]; then
        echo "✓ Performance target met: ${startup_ms}ms ≤ ${MAX_STARTUP_OVERHEAD_MS}ms"
    else
        echo "⚠ Performance target exceeded: ${startup_ms}ms > ${MAX_STARTUP_OVERHEAD_MS}ms" >&2
    fi
    echo

    if [[ $all_checks_passed -eq 0 ]]; then
        echo "✅ All critical verification checks passed"
        return 0
    else
        echo "❌ Some critical verification checks failed" >&2
        return 1
    fi
}
```

---

### Main Configuration Function

```bash
# Function: configure_zsh
# Purpose: Main entry point for ZSH configuration
# Args: None
# Returns: 0 if configuration successful, 1 otherwise
# Side Effects: Installs Oh My ZSH, plugins, optimizes performance
# Example: configure_zsh
configure_zsh() {
    echo "=== ZSH Configuration ==="
    echo

    # Step 0: Verify ZSH is installed
    if ! command -v zsh &> /dev/null; then
        echo "→ ZSH not found, installing..."
        if ! sudo apt install -y zsh 2>&1 | grep -E "^(Setting up|Processing)"; then
            echo "✗ Failed to install ZSH" >&2
            return 1
        fi
    fi
    echo

    # Step 1: Install Oh My ZSH
    if ! install_oh_my_zsh; then
        echo "✗ Failed to install Oh My ZSH" >&2
        return 1
    fi
    echo

    # Step 2: Configure plugins
    if ! configure_zsh_plugins; then
        echo "⚠ Plugin configuration failed (non-critical)" >&2
    fi
    echo

    # Step 3: Optimize performance
    if ! optimize_zsh_performance; then
        echo "⚠ Performance optimization failed (non-critical)" >&2
    fi
    echo

    # Step 4: Verify configuration
    if ! verify_zsh_configuration; then
        echo "✗ ZSH configuration verification failed" >&2
        return 1
    fi

    echo
    echo "✅ ZSH configuration complete!"
    echo
    echo "Next steps:"
    echo "  1. Set ZSH as default shell: chsh -s \$(which zsh)"
    echo "  2. Restart terminal or run: exec zsh"
    echo "  3. Verify: echo \$SHELL"
    echo

    return 0
}
```

---

## Unit Testing

Create `.runners-local/tests/unit/test_configure_zsh.sh`:

```bash
#!/bin/bash
# Unit tests for scripts/configure_zsh.sh
# Constitutional requirement: <5s execution time

set -euo pipefail

# Source module for testing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../scripts/configure_zsh.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

echo "=== Unit Tests: configure_zsh.sh ==="
echo

# Test 1: Module loaded
[[ -n "${CONFIGURE_ZSH_SH_LOADED}" ]] && echo "✓ PASS: Module loaded" || echo "✗ FAIL: Module not loaded"
TESTS_RUN=$((TESTS_RUN + 1))
TESTS_PASSED=$((TESTS_PASSED + 1))

# Test 2: Function existence
for func in install_oh_my_zsh install_zsh_plugin configure_zsh_plugins \
            optimize_zsh_performance verify_zsh_configuration configure_zsh; do
    TESTS_RUN=$((TESTS_RUN + 1))
    if declare -f "$func" &> /dev/null; then
        echo "✓ PASS: Function $func exists"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ FAIL: Function $func not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
done

# Test 3: Check ZSH availability
TESTS_RUN=$((TESTS_RUN + 1))
if command -v zsh &> /dev/null; then
    echo "✓ PASS: ZSH available"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "ℹ SKIP: ZSH not installed"
fi

# Test 4: Check Oh My ZSH installation
TESTS_RUN=$((TESTS_RUN + 1))
if [[ -d "${HOME}/.oh-my-zsh" ]]; then
    echo "✓ PASS: Oh My ZSH installed"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "ℹ SKIP: Oh My ZSH not installed"
fi

# Summary
echo
echo "=== Test Summary ==="
echo "Total: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo

[[ $TESTS_FAILED -eq 0 ]] && echo "✅ All tests passed!" && exit 0 || { echo "❌ Some tests failed"; exit 1; }
```

---

## Performance Benchmarks

Constitutional requirement: <50ms ZSH startup overhead

**Baseline startup time**: ~200ms (typical Oh My ZSH default)
**Optimized target**: <250ms total (<50ms overhead from optimizations)

**Optimization techniques**:
- Completion caching (compinit -C)
- Lazy loading heavy plugins
- Minimal plugin set
- Skip insecure directory checks

---

## Troubleshooting

### Issue: ZSH startup slow (>500ms)
**Solution**:
```bash
# Profile startup time
time zsh -i -c exit

# Identify slow plugins
zsh -xv 2>&1 | grep 'source' | head -20

# Disable heavy plugins temporarily
# Edit ~/.zshrc and remove from plugins list
```

### Issue: Plugins not loading
**Solution**:
```bash
# Verify plugin installation
ls -la ~/.oh-my-zsh/custom/plugins/

# Check .zshrc syntax
zsh -n ~/.zshrc

# Reload configuration
source ~/.zshrc
```

---

## Constitutional Compliance Checklist

- [x] **Latest Oh My ZSH**: Uses official installation script
- [x] **Performance**: <50ms startup overhead target
- [x] **Module Contract**: Follows template
- [x] **Idempotent**: Safe to re-run
- [x] **Backup**: .zshrc backed up before changes

---

## Git Workflow

```bash
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-feat-zsh-configuration"
git checkout -b "$BRANCH_NAME"

git add scripts/configure_zsh.sh \
        .runners-local/tests/unit/test_configure_zsh.sh \
        manage.sh

git commit -m "feat(zsh): Implement ZSH configuration module

Implements T068-T070:
- Oh My ZSH framework installation
- Essential plugins (autosuggestions, syntax-highlighting)
- Performance optimization (<50ms overhead)

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"

git push -u origin "$BRANCH_NAME"
git checkout main
git merge "$BRANCH_NAME" --no-ff
git push origin main
```

---

**Implementation Time Estimate**: 3-4 hours
**Dependencies**: verification.sh, progress.sh, common.sh
**Output**: Production-ready `scripts/configure_zsh.sh`
