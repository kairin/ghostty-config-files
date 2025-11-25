# Refactoring Lessons Learned

**Document Version**: 1.0
**Last Updated**: 2025-11-25
**Status**: Active Reference

## Overview

This document captures lessons learned from the Modularity Constitution Implementation (Phases 3-7), which refactored large scripts into modular components following the 300-line constitutional limit.

---

## The Orchestrator Pattern

### Definition
An **orchestrator** is a thin parent script that:
1. Sources modular components from subdirectories
2. Acts as a router/dispatcher for functionality
3. Re-exports functions for backward compatibility
4. Contains only minimal coordination logic

### Structure Template
```bash
#!/usr/bin/env bash
# lib/example/parent.sh - Example orchestrator

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_EXAMPLE_SOURCED:-}" ]] && return 0
readonly _EXAMPLE_SOURCED=1

# Determine script directory for relative sourcing
SCRIPT_DIR="${BASH_SOURCE[0]%/*}"

# Source modular components
if [[ -f "${SCRIPT_DIR}/submodule/component.sh" ]]; then
    source "${SCRIPT_DIR}/submodule/component.sh"
fi

# Orchestrator-specific functions (minimal)
orchestrate_workflow() {
    component_function_a
    component_function_b
}

# Export and re-export for backward compatibility
export -f orchestrate_workflow
export -f component_function_a 2>/dev/null || true
```

### Key Characteristics
- **Line count**: <150 lines (ideally <100)
- **Primary role**: Coordination, not implementation
- **Sourcing**: Uses `${BASH_SOURCE[0]%/*}` for reliable relative paths
- **Backward compatibility**: Re-exports sourced functions

---

## Source Guard Implementation

### Standard Pattern
```bash
# Source guard - prevent redundant loading
[[ -n "${_MODULE_NAME_SOURCED:-}" ]] && return 0
readonly _MODULE_NAME_SOURCED=1
```

### Naming Convention
- Use uppercase with underscores: `_MODULE_NAME_SOURCED`
- Include the module's purpose in the name
- Use `readonly` to prevent accidental modification

### Why Source Guards Matter
1. Prevent function redefinition warnings
2. Avoid duplicate initialization
3. Enable safe circular sourcing patterns
4. Improve script load performance

---

## Function Documentation Headers

### Minimal Header (Preferred for space)
```bash
# Brief description of function
function_name() {
    # implementation
}
```

### Standard Header (When space permits)
```bash
#######################################
# Description: What the function does
# Arguments:
#   $1 - First argument description
#   $2 - Second argument (optional)
# Outputs: What it writes to stdout
# Returns: Exit codes
#######################################
function_name() {
    # implementation
}
```

### Compact Documentation
When fighting the 300-line limit, prefer inline comments:
```bash
# Function: brief purpose (Args: $1=name, $2=value; Returns: 0/1)
function_name() { ... }
```

---

## Variable Scope Best Practices

### Local Variables
Always declare loop variables and temporary values as local:
```bash
function_name() {
    local file line count=0
    while IFS= read -r line; do
        count=$((count + 1))
    done
}
```

### Exported Functions
Use `export -f` at the end of the module:
```bash
# Export functions
export -f function_a function_b function_c
```

### Conditional Re-export
For backward compatibility when sourcing might fail:
```bash
export -f function_from_submodule 2>/dev/null || true
```

---

## TUI Integration Patterns

### Separation of Concerns
Split TUI modules into:
1. **Rendering** (`render.sh`): Visual output, progress bars, headers
2. **Input** (`input.sh`): User prompts, selections, confirmations

### Gum Dependency Pattern
```bash
# Check for gum, provide fallback
if command -v gum &>/dev/null; then
    gum confirm "$prompt"
else
    read -rp "$prompt [y/N]: " response
    [[ "$response" =~ ^[Yy] ]]
fi
```

### Progress Display
```bash
show_progress_bar() {
    local current="$1" total="$2" description="${3:-}"
    local percentage=$((current * 100 / total))
    local completed=$((current * 40 / total))
    local bar=$(printf '%*s' "$completed" '' | tr ' ' '#')
    printf "\r[%-40s] %3d%% %s" "$bar" "$percentage" "$description"
}
```

---

## Refactoring Strategies by Violation Size

### Small Violations (300-330 lines)
**Strategy**: Inline optimization
- Remove verbose comments
- Consolidate export statements
- Merge related small functions
- Remove unnecessary blank lines

### Medium Violations (330-400 lines)
**Strategy**: Extract one module
- Identify logical grouping (e.g., input vs output)
- Create single subdirectory module
- Keep orchestrator minimal

### Large Violations (400+ lines)
**Strategy**: Full modularization
- Create subdirectory for modules
- Split by functional domain
- Multiple extraction passes
- Example: `dashboard.sh` -> `dashboard/{stats,render}.sh`

---

## Module Hierarchy Examples

### Updates Domain
```
lib/updates/
    ghostty-specific.sh          # Orchestrator (141 lines)
    ghostty/
        build.sh                 # Build operations (188 lines)
        install.sh               # Install operations (209 lines)
```

### Documentation Domain
```
lib/docs/
    dashboard.sh                 # Orchestrator (141 lines)
    dashboard/
        stats.sh                 # Statistics (234 lines)
        render.sh                # Output formatting (293 lines)
```

### Validation Domain
```
lib/core/
    validation.sh                # Orchestrator (61 lines)
    validation/
        files.sh                 # File/directory validation (214 lines)
        input.sh                 # Input/data validation (253 lines)
```

### TUI Domain
```
lib/installers/common/
    tui-helpers.sh               # Orchestrator (67 lines)
lib/ui/tui/
    render.sh                    # Visual rendering (225 lines)
    input.sh                     # User input (260 lines)
```

---

## Common Pitfalls

### 1. Breaking Sourcing Chains
**Problem**: Child module can't find sibling
**Solution**: Use `${BASH_SOURCE[0]%/*}` for consistent paths

### 2. Export Timing
**Problem**: Functions not available to callers
**Solution**: Export at end of module, after all definitions

### 3. Circular Dependencies
**Problem**: Module A sources B, B sources A
**Solution**: Source guards prevent infinite loops

### 4. Lost Backward Compatibility
**Problem**: Refactoring breaks existing callers
**Solution**: Re-export all functions from orchestrator

### 5. Over-Modularization
**Problem**: Too many tiny files
**Solution**: Only split when >300 lines or clear domain separation

---

## Verification Checklist

After refactoring, verify:

- [ ] All modules <300 lines
- [ ] Syntax validates: `bash -n <file>`
- [ ] Source guards present
- [ ] Functions documented
- [ ] Exports configured
- [ ] Module map updated
- [ ] Integration tests pass
- [ ] Constitutional compliance test passes

---

## Constitutional Compliance

### The 300-Line Limit
- **Hard limit**: No script may exceed 300 lines
- **Verification**: `tests/constitutional/test_script_line_limits.sh`
- **Grace period**: Existing violations documented in catalog
- **New code**: Must be compliant from creation

### Compliance Test
```bash
./tests/constitutional/test_script_line_limits.sh
```

### Log Output
Results saved to: `logs/constitutional_check.log`

---

## References

- **Module Map**: `docs/developer/module_map.md`
- **Violations Catalog**: `violations-catalog.md`
- **Constitutional Principles**: `.claude/instructions-for-agents/principles/`
- **Test Script**: `tests/constitutional/test_script_line_limits.sh`

---

**Document Maintainer**: System Architecture Team
**Review Cycle**: After each major refactoring effort
