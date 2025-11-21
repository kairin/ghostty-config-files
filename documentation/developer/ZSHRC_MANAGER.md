# .zshrc Manager Utility

## Overview

The `.zshrc` Manager is an intelligent utility that provides **Powerlevel10k (P10k) compliant** modifications to `.zshrc` configuration files. It prevents console output warnings during shell initialization by ensuring all content is placed in the correct location relative to the P10k instant prompt block.

**Location**: `lib/utils/zshrc_manager.sh`

## Problem Statement

### Issue: Powerlevel10k Instant Prompt Warnings

When shell configuration produces console output (like `fnm env` showing "Using Node v25.2.1") **after** the P10k instant prompt block initializes, users see warnings like:

```
[WARNING]: Console output during zsh initialization detected.

When using Powerlevel10k with instant prompt, console output during zsh
initialization may indicate issues.
```

### Root Cause

Installation/update scripts were appending configuration to the **end** of `.zshrc`, placing it after the P10k instant prompt block:

```zsh
# (Line 27-32) P10k instant prompt - MUST come early
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ... other configuration ...

# (Line 150+) fnm initialization - WRONG LOCATION!
eval "$(fnm env --use-on-cd)"  # <-- Produces console output AFTER P10k
```

### Solution

The `.zshrc` Manager automatically detects the P10k instant prompt location and injects content in the **correct** position:

```zsh
# (Line 24) fnm initialization - CORRECT LOCATION (before P10k)
export FNM_DIR="$HOME/.local/share/fnm"
if [ -d "$FNM_DIR" ]; then
  export PATH="$FNM_DIR:$PATH"
  eval "$(fnm env --use-on-cd)"  # Now executes BEFORE P10k
fi

# (Line 36-41) P10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
```

## API Reference

### `inject_into_zshrc()`

Inject content into `.zshrc` at the correct location based on P10k compliance requirements.

**Signature**:
```bash
inject_into_zshrc description content placement [marker]
```

**Parameters**:
- `description` (string): Human-readable description for logging
- `content` (string): Content block to inject
- `placement` (string): Where to inject: `"before_p10k"` | `"after_p10k"` | `"end"`
- `marker` (string, optional): Unique string for duplicate detection

**Returns**:
- `0` - Success
- `1` - Failed
- `2` - Already exists (skipped)

**Examples**:

```bash
# Example 1: Inject fnm before P10k (prevents console output)
source lib/utils/zshrc_manager.sh

fnm_block='
# fnm (Fast Node Manager)
export FNM_DIR="$HOME/.local/share/fnm"
if [ -d "$FNM_DIR" ]; then
  export PATH="$FNM_DIR:$PATH"
  eval "$(fnm env --use-on-cd)"
fi
'

inject_into_zshrc "fnm initialization" "$fnm_block" "before_p10k" "fnm env"
# ✓ Added fnm initialization to .zshrc (line 25, placement: before_p10k)
```

```bash
# Example 2: Inject aliases after P10k (no console output concern)
alias_block='
# Custom aliases
alias ll="ls -la"
alias grep="rg"
'

inject_into_zshrc "custom aliases" "$alias_block" "after_p10k" "# Custom aliases"
# ✓ Added custom aliases to .zshrc (line 120, placement: after_p10k)
```

### `remove_from_zshrc()`

Remove content block from `.zshrc` (for cleanup/updates).

**Signature**:
```bash
remove_from_zshrc start_marker [end_marker]
```

**Parameters**:
- `start_marker` (string): Line containing this will be removed
- `end_marker` (string, optional): For multi-line blocks

**Returns**:
- `0` - Success
- `1` - Failed
- `2` - Not found (already removed)

**Example**:
```bash
remove_from_zshrc "# fnm (Fast Node Manager)" "fi"
# ✓ Removed content from .zshrc
```

### `verify_p10k_compliance()`

Diagnostic function to check `.zshrc` P10k compliance.

**Signature**:
```bash
verify_p10k_compliance
```

**Returns**:
- `0` - Compliant
- `1` - Issues detected

**Example**:
```bash
verify_p10k_compliance
# ✓ P10k instant prompt detected (lines 36-41)
# ✓ No console output detected inside P10k block
```

## Placement Strategy Guide

### When to use `before_p10k`

Use for configuration that:
- Produces console output (e.g., `fnm env`, `nvm`, version managers)
- Exports environment variables needed early
- Must execute before shell prompt initialization

**Examples**:
- fnm/nvm initialization
- Python version managers (pyenv, uv)
- Ruby version managers (rbenv, rvm)
- Any tool that prints version info during init

### When to use `after_p10k`

Use for configuration that:
- Does not produce console output
- Configures prompt behavior
- Loads completion systems
- Sources additional scripts

**Examples**:
- ZSH plugins (zsh-autosuggestions, zsh-syntax-highlighting)
- Completion configurations
- Directory colors (dircolors)
- Oh My Zsh configuration

### When to use `end`

Use for configuration that:
- Is user-specific customization
- Has no P10k interaction
- Is safe to load last

**Examples**:
- User aliases
- Project-specific environment variables
- Custom functions

## Integration with Installation Scripts

### Before (❌ Problematic)

```bash
# lib/installers/nodejs_fnm/steps/03-configure-shell.sh
echo 'eval "$(fnm env --use-on-cd)"' >> "$HOME/.zshrc"
# Problem: Appends to end, causes P10k warnings
```

### After (✅ P10k-Compliant)

```bash
# lib/installers/nodejs_fnm/steps/03-configure-shell.sh
source "${REPO_ROOT}/lib/utils/zshrc_manager.sh"

fnm_block='...'
inject_into_zshrc "fnm initialization" "$fnm_block" "before_p10k" "fnm env"
# Solution: Injects before P10k, prevents warnings
```

## Testing

### Manual Test

```bash
# Test P10k compliance
source lib/utils/zshrc_manager.sh
verify_p10k_compliance

# Test injection
fnm_block='# Test content'
inject_into_zshrc "test" "$fnm_block" "before_p10k" "# Test"

# Verify placement
grep -n "# Test content" ~/.zshrc
```

### Integration Test

```bash
# Run test suite
./.runners-local/tests/unit/test_zshrc_manager.sh
```

## Troubleshooting

### Warning: Console output during zsh initialization

**Symptom**: Powerlevel10k warning on terminal startup

**Cause**: Configuration producing console output after P10k instant prompt

**Solution**:
1. Identify problematic configuration:
   ```bash
   source lib/utils/zshrc_manager.sh
   verify_p10k_compliance
   ```

2. Move configuration before P10k:
   ```bash
   # Remove old configuration
   remove_from_zshrc "problematic config marker"

   # Re-inject before P10k
   inject_into_zshrc "description" "$config" "before_p10k" "marker"
   ```

3. Verify fix:
   ```bash
   verify_p10k_compliance
   # Restart terminal
   ```

### P10k instant prompt not detected

**Symptom**: `verify_p10k_compliance` shows "P10k instant prompt not detected"

**Cause**: P10k not installed or `.zshrc` modified incorrectly

**Solution**:
1. Check for P10k installation:
   ```bash
   ls -la ~/.oh-my-zsh/custom/themes/powerlevel10k
   ```

2. Verify `.zshrc` contains P10k block:
   ```bash
   grep -A 5 "Enable Powerlevel10k instant prompt" ~/.zshrc
   ```

3. If missing, install P10k:
   ```bash
   git clone https://github.com/romkatv/powerlevel10k.git \
     ~/.oh-my-zsh/custom/themes/powerlevel10k
   ```

## Constitutional Compliance

This utility enforces:

- ✅ **Performance**: Prevents shell startup degradation from P10k warnings
- ✅ **User Experience**: Eliminates confusing warning messages
- ✅ **Modularity**: Centralized .zshrc management logic
- ✅ **Idempotency**: Safe to re-run, prevents duplicates
- ✅ **Script Proliferation Prevention**: Single utility for all .zshrc modifications

## Version History

- **v1.0** (2025-11-22): Initial release
  - P10k-compliant injection
  - Duplicate detection
  - Automatic placement calculation
  - Diagnostic functions

## Related Documentation

- [Critical Requirements - Powerlevel10k](/.claude/instructions-for-agents/requirements/CRITICAL-requirements.md#powerlevel10k-performance)
- [Script Proliferation Prevention](/.claude/instructions-for-agents/principles/script-proliferation.md)
- [First-Time Setup](/.claude/instructions-for-agents/guides/first-time-setup.md)
