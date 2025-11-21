# Repository Restructuring Proposal

**Date**: 2025-11-21
**Status**: 📋 PROPOSAL
**Purpose**: Simplify repository structure based on user feedback
**Requested By**: User

---

## Executive Summary

The repository has grown organically and now contains structural confusions and redundancies. This proposal addresses 5 key organizational issues to create a cleaner, more intuitive structure.

---

## Issues Identified

### 1. ❓ `manage.sh` vs `start.sh` - Two Entry Points

**Current State**:
- `start.sh` (591 lines) - Modern TUI installation orchestrator
- `manage.sh` (2,435 lines) - Unified management interface

**Analysis**:
- **Purpose Overlap**: Both are entry point scripts in root
- **User Confusion**: Which script does what?
- **Maintainability**: Two large scripts to maintain

**CLAUDE.md Says**: `start.sh` is the primary installation orchestrator

**Recommendation**: ✅ **MOVE `manage.sh` → `scripts/manage.sh`**

**Rationale**:
- `start.sh` is THE installation entry point (should stay in root)
- `manage.sh` is a management utility (belongs in `scripts/`)
- Clearer separation: Installation (root) vs Management (scripts/)
- Constitutional compliance: Single entry point for installation

---

### 2. ❓ `docs/` vs `documentation/` - Folder Confusion

**Current State**:
- `docs/` - **Astro.build OUTPUT** (GitHub Pages deployment)
- `documentation/` - **Source documentation** (architecture, setup, developer guides)

**Analysis**:
- **Purpose**: COMPLETELY DIFFERENT
  - `docs/` = Build artifact (HTML, CSS, JS from Astro)
  - `documentation/` = Source markdown files
- **Confusion**: Names suggest same purpose
- **Critical**: `docs/.nojekyll` REQUIRED for GitHub Pages

**CLAUDE.md Section**:
```markdown
### 🚨 CRITICAL: Documentation Structure (CONSTITUTIONAL REQUIREMENT - Restructured 2025-11-20)
- **`docs/`** - **Astro.build output ONLY** → GitHub Pages deployment (committed, DO NOT manually edit)
- **`astro-website/src/`** - **Astro source files** → Editable markdown documentation
- **`documentation/`** - **SINGLE documentation folder** (consolidated from docs-setup/, documentations/, specs/)
```

**Recommendation**: ✅ **KEEP AS IS - NO CHANGE**

**Rationale**:
- `docs/` = Build output (MUST be named `docs/` for GitHub Pages)
- `documentation/` = Source files (clear, descriptive name)
- Changing either would break:
  - GitHub Pages deployment (`docs/` is the publish directory)
  - Astro build configuration (`outDir: '../docs'`)
  - All internal documentation references
- **Alternative**: Add `.github/CONTRIBUTING.md` explaining the difference

---

### 3. ❓ `tests/` - Should It Move to `scripts/`?

**Current State**:
- `tests/` - Test infrastructure (root level)
- `scripts/` - Utility scripts

**Analysis**:
- **Standard Practice**: Tests typically in root (like `/tests`, `/spec`, `/__tests__`)
- **Precedent**: Most projects have tests at root level
- **CI/CD**: Test discovery tools expect root-level test directories
- **Separation of Concerns**:
  - `tests/` = Automated testing (validation)
  - `scripts/` = Operational utilities (execution)

**Recommendation**: ✅ **KEEP `tests/` AT ROOT - NO CHANGE**

**Rationale**:
- Industry standard: Tests at root level
- Clear separation: Testing vs Scripting
- CI/CD integration expects `/tests`
- Moving to `scripts/` would confuse "test scripts" with "utility scripts"

**Alternative**: If consolidation desired, move to `.runners-local/tests/` (local CI/CD infrastructure)

---

### 4. ❓ `configs/` - Should It Move to `scripts/`?

**Current State**:
- `configs/` - Configuration files (Ghostty config, themes, dircolors, workspace)
- `scripts/` - Executable scripts

**Analysis**:
- **Purpose**: Configs are DATA, not executable scripts
- **Standard Practice**: Configuration files separate from scripts
- **Precedent**: Most projects have `/config`, `/configs`, `.config` separate from `/scripts`
- **File Types**:
  - `configs/` = Data files (.conf, .theme, dircolors)
  - `scripts/` = Executable files (.sh, .bash)

**Recommendation**: ✅ **KEEP `configs/` AT ROOT - NO CHANGE**

**Rationale**:
- Clear separation: Data vs Executables
- Industry standard: `/config` or `/configs` separate from `/scripts`
- Mixing configs into `scripts/` creates conceptual confusion
- `configs/` is discoverable and semantically correct

---

### 5. 💡 Modular Installer Architecture - Smart Component Managers

**Current State**:
```
start.sh → Calls 37 individual modular scripts directly
```

**User's Vision**:
> "each manager for each component can be a subfolder containing each of their respective sub installer scripts"

**Proposed Structure**:
```
/home/kkk/Apps/ghostty-config-files/
├── start.sh                    # Main orchestrator (SIMPLIFIED)
├── lib/
│   └── installers/             # Component managers (NEW)
│       ├── ghostty/
│       │   ├── install.sh      # Manager script (orchestrates 9 steps)
│       │   ├── steps/
│       │   │   ├── 00-check-prerequisites.sh
│       │   │   ├── 01-download-zig.sh
│       │   │   ├── 02-extract-zig.sh
│       │   │   ├── 03-clone-ghostty.sh
│       │   │   ├── 04-build-ghostty.sh
│       │   │   ├── 05-install-binary.sh
│       │   │   ├── 06-configure-ghostty.sh
│       │   │   ├── 07-create-desktop-entry.sh
│       │   │   └── 08-verify-installation.sh
│       │   └── common.sh
│       │
│       ├── zsh/
│       │   ├── install.sh      # Manager script
│       │   ├── steps/
│       │   │   ├── 00-check-prerequisites.sh
│       │   │   ├── 01-install-oh-my-zsh.sh
│       │   │   ├── 02-install-plugins.sh
│       │   │   ├── 03-configure-zshrc.sh
│       │   │   ├── 04-install-security-check.sh
│       │   │   └── 05-verify-installation.sh
│       │   └── common.sh
│       │
│       ├── python_uv/
│       │   ├── install.sh
│       │   ├── steps/
│       │   └── common.sh
│       │
│       ├── nodejs_fnm/
│       │   ├── install.sh
│       │   ├── steps/
│       │   └── common.sh
│       │
│       ├── ai_tools/
│       │   ├── install.sh
│       │   ├── steps/
│       │   └── common.sh
│       │
│       └── context_menu/
│           ├── install.sh
│           ├── steps/
│           └── common.sh
```

**New TASK_REGISTRY** (Simplified):
```bash
readonly TASK_REGISTRY=(
    # Prerequisites
    "verify-prereqs||pre_installation_health_check|verify_health|0|10"
    "install-gum|verify-prereqs|task_install_gum|verify_gum_installed|1|30"

    # Component Managers (each manages its own sub-steps)
    "install-ghostty|verify-prereqs|script:lib/installers/ghostty/install.sh|verify_ghostty_installed|1|185"
    "install-zsh|verify-prereqs|script:lib/installers/zsh/install.sh|verify_zsh_configured|1|70"
    "install-uv|verify-prereqs|script:lib/installers/python_uv/install.sh|verify_python_uv|1|50"
    "install-fnm|verify-prereqs|script:lib/installers/nodejs_fnm/install.sh|verify_fnm_installed|1|70"
    "install-ai-tools|install-fnm|script:lib/installers/ai_tools/install.sh|verify_claude_cli|3|105"
    "install-context-menu|install-ghostty|script:lib/installers/context_menu/install.sh|verify_context_menu|2|20"

    # App Audit
    "run-app-audit|install-ai-tools,install-context-menu|task_run_app_audit|verify_app_audit_report|4|20"
)
```

**Benefits**:
- ✅ **Cleaner start.sh**: 9 tasks instead of 37
- ✅ **Component Encapsulation**: Each component manages its own sub-steps
- ✅ **Smart Managers**: `ghostty/install.sh` calls its 9 sub-scripts
- ✅ **Better Debugging**: "Ghostty installation failed at step 4 (build)" instead of "ghostty-build failed"
- ✅ **Easier Maintenance**: Add/modify Ghostty steps without touching start.sh
- ✅ **Reusability**: Component managers can be called independently

**Manager Script Example** (`lib/installers/ghostty/install.sh`):
```bash
#!/usr/bin/env bash
#
# Ghostty Installation Manager
# Orchestrates 9-step Ghostty installation process
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STEPS_DIR="${SCRIPT_DIR}/steps"

source "${SCRIPT_DIR}/common.sh"
source "${REPO_ROOT}/lib/core/logging.sh"

main() {
    log "INFO" "Starting Ghostty installation (9 steps)..."

    local steps=(
        "00-check-prerequisites.sh"
        "01-download-zig.sh"
        "02-extract-zig.sh"
        "03-clone-ghostty.sh"
        "04-build-ghostty.sh"
        "05-install-binary.sh"
        "06-configure-ghostty.sh"
        "07-create-desktop-entry.sh"
        "08-verify-installation.sh"
    )

    local step_num=1
    for step in "${steps[@]}"; do
        log "INFO" "Step ${step_num}/9: ${step%.sh}"

        if ! "${STEPS_DIR}/${step}"; then
            log "ERROR" "Ghostty installation failed at step ${step_num}: ${step}"
            return 1
        fi

        ((step_num++))
    done

    log "SUCCESS" "Ghostty installation complete (9/9 steps)"
    return 0
}

main "$@"
```

**Recommendation**: ✅ **IMPLEMENT COMPONENT MANAGERS**

**Migration Path**:
1. Create `lib/installers/` directory structure
2. Move existing modular scripts from `lib/tasks/*/` to `lib/installers/*/steps/`
3. Create manager scripts (`install.sh`) for each component
4. Update `start.sh` TASK_REGISTRY to call managers instead of individual steps
5. Test each component manager independently
6. Update documentation

---

## Summary of Recommendations

| Issue | Recommendation | Priority |
|-------|---------------|----------|
| 1. `manage.sh` vs `start.sh` | ✅ Move `manage.sh` → `scripts/` | HIGH |
| 2. `docs/` vs `documentation/` | ✅ Keep as is (add CONTRIBUTING.md) | LOW |
| 3. `tests/` location | ✅ Keep at root | N/A |
| 4. `configs/` location | ✅ Keep at root | N/A |
| 5. Component managers | ✅ Implement smart installer architecture | HIGH |

---

## Proposed Final Structure

```
/home/kkk/Apps/ghostty-config-files/
├── start.sh                        # Main installation orchestrator
├── README.md                       # User documentation
├── AGENTS.md                       # AI assistant instructions
├── CLAUDE.md → AGENTS.md          # Symlink
├── GEMINI.md → AGENTS.md          # Symlink
│
├── configs/                        # Configuration files (DATA)
│   ├── ghostty/
│   ├── themes/
│   ├── dircolors
│   └── workspace/
│
├── scripts/                        # Utility scripts (EXECUTABLES)
│   ├── manage.sh                   # ← MOVED FROM ROOT
│   ├── check_updates.sh
│   ├── fix-zsh-compinit-security.sh
│   └── ...
│
├── tests/                          # Test infrastructure (VALIDATION)
│   ├── contract/
│   ├── unit/
│   └── integration/
│
├── lib/                            # Core libraries
│   ├── installers/                 # ← NEW: Component managers
│   │   ├── ghostty/
│   │   │   ├── install.sh          # Manager
│   │   │   ├── steps/              # Sub-scripts
│   │   │   └── common.sh
│   │   ├── zsh/
│   │   ├── python_uv/
│   │   ├── nodejs_fnm/
│   │   ├── ai_tools/
│   │   └── context_menu/
│   │
│   ├── core/                       # Core utilities
│   ├── ui/                         # TUI components
│   └── verification/               # Verification functions
│
├── documentation/                  # Source documentation (MARKDOWN)
│   ├── setup/
│   ├── architecture/
│   ├── developer/
│   └── specifications/
│
├── docs/                           # Build output (HTML - DO NOT EDIT)
│   └── .nojekyll                   # CRITICAL for GitHub Pages
│
├── astro-website/                  # Astro source files
│   ├── src/
│   └── astro.config.mjs            # outDir: '../docs'
│
└── .runners-local/                 # Local CI/CD infrastructure
    ├── workflows/
    ├── tests/
    └── logs/
```

---

## Implementation Plan

### Phase 1: Move manage.sh (LOW RISK)
```bash
git mv manage.sh scripts/manage.sh
# Update any references in documentation
# Test: ./scripts/manage.sh --help
```

### Phase 2: Add CONTRIBUTING.md (NO RISK)
```markdown
# Contributing Guide

## Documentation Structure

**IMPORTANT**: We have TWO separate documentation locations:

1. **`documentation/`** - Source markdown files (EDIT THESE)
   - Architecture docs
   - Setup guides
   - Developer documentation

2. **`docs/`** - Astro.build OUTPUT (DO NOT EDIT DIRECTLY)
   - Generated HTML for GitHub Pages
   - Auto-built from `astro-website/src/`
   - Contains critical `.nojekyll` file

To update documentation:
- Edit files in `documentation/` for technical docs
- Edit files in `astro-website/src/` for website content
- Run `npm run build` in `astro-website/` to regenerate `docs/`
```

### Phase 3: Implement Component Managers (MEDIUM RISK)
1. Create `lib/installers/` structure
2. Create manager scripts for each component
3. Move existing scripts to `steps/` subdirectories
4. Update `start.sh` TASK_REGISTRY
5. Test each component independently
6. Test full installation flow

**Estimated Effort**: 2-3 hours for Phase 3

---

## Testing Strategy

### Phase 1 Testing (manage.sh move):
```bash
# Test manage.sh after move
./scripts/manage.sh --help
./scripts/manage.sh --version

# Test start.sh still works
./start.sh --help
```

### Phase 3 Testing (Component managers):
```bash
# Test individual component managers
./lib/installers/ghostty/install.sh
./lib/installers/zsh/install.sh
./lib/installers/python_uv/install.sh

# Test full installation
./start.sh

# Test idempotency (re-run should skip completed steps)
./start.sh
```

---

## Risk Assessment

| Change | Risk Level | Impact | Mitigation |
|--------|-----------|--------|------------|
| Move `manage.sh` | LOW | Scripts and docs reference it | Update references, test |
| Keep `docs/` name | NONE | No change | Document the difference |
| Keep `tests/` root | NONE | No change | N/A |
| Keep `configs/` root | NONE | No change | N/A |
| Component managers | MEDIUM | Changes start.sh orchestration | Incremental rollout, testing |

---

## Questions for User

1. **manage.sh**: Approve moving to `scripts/manage.sh`?
2. **Component Managers**: Approve implementing smart installer architecture?
3. **Timeline**: Implement all at once or incrementally?
4. **Testing**: Want to test Phase 1 before proceeding to Phase 3?

---

## Conclusion

The proposed restructuring addresses all 5 user concerns while:
- ✅ Maintaining GitHub Pages functionality (`docs/` untouched)
- ✅ Following industry standards (`tests/` and `configs/` at root)
- ✅ Simplifying orchestration (component managers)
- ✅ Improving maintainability (clearer separation of concerns)
- ✅ Preserving all existing functionality

**Recommended Action**: Approve Phase 1 (move manage.sh) immediately, then implement Phase 3 (component managers) as a separate effort.

---

**End of Proposal**

**Author**: Claude Code (Sonnet 4.5)
**Date**: 2025-11-21
**Status**: Awaiting User Approval
