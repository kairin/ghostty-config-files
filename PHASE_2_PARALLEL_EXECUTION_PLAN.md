# Phase 2: Parallel Execution Plan - Task Modularity

**Date**: 2025-11-20
**Status**: ✅ Ready for Parallel Execution
**Total Scripts to Create**: 50+ modular scripts across 8 task groups
**Estimated Timeline**: 4 weeks sequential → **1 week parallel** (4x speedup)
**Strategy**: Independent task groups executed in parallel with comprehensive documentation

---

## Executive Summary

### Parallel Execution Strategy

**Core Insight**: All 8 task groups are **completely independent** and can be implemented in parallel.

**Benefits of Parallel Execution**:
- ⚡ **4x speedup**: 4 weeks → 1 week
- 🔄 **Independent development**: No blocking dependencies between task groups
- ✅ **Easier review**: Each task group can be reviewed independently
- 🐛 **Isolated debugging**: Issues in one group don't block others
- 📊 **Clear progress tracking**: 8 parallel streams vs 1 sequential stream

**Execution Model**:
```
Week 1 (Parallel Execution):
├── Stream 1: Ghostty modularity    (8 scripts) → lib/tasks/ghostty/
├── Stream 2: ZSH modularity        (6 scripts) → lib/tasks/zsh/
├── Stream 3: Python UV modularity  (5 scripts) → lib/tasks/python_uv/
├── Stream 4: Node.js FNM modularity(6 scripts) → lib/tasks/nodejs_fnm/
├── Stream 5: AI Tools modularity   (5 scripts) → lib/tasks/ai_tools/
├── Stream 6: Context Menu modularity(3 scripts) → lib/tasks/context_menu/
├── Stream 7: Gum modularity        (4 scripts) → lib/tasks/gum/
└── Stream 8: App Audit modularity  (7 scripts) → lib/tasks/app_audit/

Week 2 (Integration):
├── Merge all 8 parallel streams
├── Update start.sh task registry
├── End-to-end testing
└── Documentation finalization
```

---

## Task Group Breakdown

### Stream 1: Ghostty Modularity (Priority: HIGH)
**Current File**: `lib/tasks/ghostty.sh` (500+ lines)
**Target Directory**: `lib/tasks/ghostty/`
**Scripts to Create**: 9 files (8 modular + 1 common)
**Estimated Effort**: 8 hours

#### Files to Create:
1. **00-check-prerequisites.sh** (~50 lines)
   - Check if Ghostty already installed
   - Check Ghostty version
   - Exit code: 0=not installed, 2=already installed (skip)

2. **01-download-zig.sh** (~80 lines)
   - Download Zig 0.14.0 tarball
   - Show real-time curl progress
   - Verify download checksum
   - Exit code: 0=success, 1=failure

3. **02-extract-zig.sh** (~60 lines)
   - Extract Zig tarball
   - Show real-time tar extraction output
   - Verify extraction successful
   - Exit code: 0=success, 1=failure

4. **03-build-zig.sh** (~100 lines)
   - Build Zig from source (if needed)
   - Show real-time build output
   - Verify Zig binary works
   - Exit code: 0=success, 1=failure

5. **04-clone-repository.sh** (~70 lines)
   - Clone Ghostty repository
   - Show real-time git clone output
   - Verify repository cloned
   - Exit code: 0=success, 1=failure

6. **05-build-ghostty.sh** (~120 lines)
   - Build Ghostty with Zig
   - Show real-time Zig build output
   - Verify build artifacts
   - Exit code: 0=success, 1=failure

7. **06-install-binary.sh** (~80 lines)
   - Install Ghostty binary to ~/.local/bin
   - Create desktop entry
   - Verify installation
   - Exit code: 0=success, 1=failure

8. **07-verify-installation.sh** (~60 lines)
   - Verify Ghostty binary works
   - Check Ghostty version
   - Test basic functionality
   - Exit code: 0=success, 1=failure

9. **common.sh** (~100 lines)
   - Shared constants (ZIG_VERSION, GHOSTTY_REPO_URL)
   - Shared helper functions
   - Path definitions

#### Implementation Template (for 01-download-zig.sh):
```bash
#!/usr/bin/env bash
set -euo pipefail

# Bootstrap using centralized init
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/init.sh"

# Source common utilities for this task group
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ═══════════════════════════════════════════════════════════════
# TASK: Download Zig Compiler
# ═══════════════════════════════════════════════════════════════

main() {
    local task_id="ghostty-download-zig"

    # Register task with progress tracking
    register_task "$task_id" "Downloading Zig ${ZIG_VERSION}"
    start_task "$task_id"

    # Real-time visible output using run_command_collapsible
    log "INFO" "Downloading Zig ${ZIG_VERSION} from ${ZIG_URL}"

    if run_command_collapsible "$task_id" \
        curl -fsSL -o "$ZIG_TARBALL" "$ZIG_URL"; then

        complete_task "$task_id" "$(get_task_duration "$task_id")"
        exit 0
    else
        fail_task "$task_id" "Failed to download Zig"
        exit 1
    fi
}

main "$@"
```

#### Documentation to Create:
- **IMPLEMENTATION_LOG_GHOSTTY.md**: Detailed log of implementation decisions, challenges, and solutions
- Include code snippets, test results, and lessons learned

---

### Stream 2: ZSH Modularity (Priority: HIGH)
**Current File**: `lib/tasks/zsh.sh` (300+ lines)
**Target Directory**: `lib/tasks/zsh/`
**Scripts to Create**: 7 files (6 modular + 1 common)
**Estimated Effort**: 6 hours

#### Files to Create:
1. **00-check-prerequisites.sh** (~40 lines)
   - Check if ZSH already configured
   - Check Oh My Zsh installation
   - Exit code: 0=proceed, 2=skip

2. **01-install-oh-my-zsh.sh** (~100 lines)
   - Install Oh My Zsh framework
   - Show real-time installation output
   - Preserve existing .zshrc
   - Exit code: 0=success, 1=failure

3. **02-install-plugins.sh** (~120 lines)
   - Install ZSH plugins (zsh-autosuggestions, zsh-syntax-highlighting)
   - Show real-time git clone output
   - Configure plugin loading
   - Exit code: 0=success, 1=failure

4. **03-configure-zshrc.sh** (~150 lines)
   - Configure .zshrc with custom settings
   - Preserve user customizations
   - Add dircolors configuration
   - Exit code: 0=success, 1=failure

5. **04-install-security-check.sh** (~80 lines)
   - Install ZSH security check script
   - Configure automatic daily checks
   - Add aliases (zsh-check-security, zsh-fix-security)
   - Exit code: 0=success, 1=failure

6. **05-verify-installation.sh** (~60 lines)
   - Verify ZSH configuration valid
   - Test plugin loading
   - Check security check system
   - Exit code: 0=success, 1=failure

7. **common.sh** (~80 lines)
   - ZSH paths and constants
   - Plugin URLs
   - Backup helpers

#### Documentation to Create:
- **IMPLEMENTATION_LOG_ZSH.md**

---

### Stream 3: Python UV Modularity (Priority: MEDIUM)
**Current File**: `lib/tasks/python_uv.sh` (200+ lines)
**Target Directory**: `lib/tasks/python_uv/`
**Scripts to Create**: 6 files (5 modular + 1 common)
**Estimated Effort**: 4 hours

#### Files to Create:
1. **00-check-prerequisites.sh** (~40 lines)
2. **01-download-uv.sh** (~70 lines)
3. **02-extract-uv.sh** (~60 lines)
4. **03-install-uv.sh** (~80 lines)
5. **04-verify-installation.sh** (~60 lines)
6. **common.sh** (~50 lines)

#### Documentation to Create:
- **IMPLEMENTATION_LOG_PYTHON_UV.md**

---

### Stream 4: Node.js FNM Modularity (Priority: MEDIUM)
**Current File**: `lib/tasks/nodejs_fnm.sh` (150+ lines)
**Target Directory**: `lib/tasks/nodejs_fnm/`
**Scripts to Create**: 7 files (6 modular + 1 common)
**Estimated Effort**: 5 hours

#### Files to Create:
1. **00-check-prerequisites.sh** (~40 lines)
2. **01-download-fnm.sh** (~70 lines)
3. **02-install-fnm.sh** (~80 lines)
4. **03-install-nodejs.sh** (~100 lines)
5. **04-configure-shell.sh** (~90 lines)
6. **05-verify-installation.sh** (~60 lines)
7. **common.sh** (~60 lines)

#### Documentation to Create:
- **IMPLEMENTATION_LOG_NODEJS_FNM.md**

---

### Stream 5: AI Tools Modularity (Priority: LOW)
**Current File**: `lib/tasks/ai_tools.sh` (100+ lines)
**Target Directory**: `lib/tasks/ai_tools/`
**Scripts to Create**: 6 files (5 modular + 1 common)
**Estimated Effort**: 4 hours

#### Files to Create:
1. **00-check-prerequisites.sh** (~40 lines)
2. **01-install-claude-cli.sh** (~80 lines)
3. **02-install-gemini-cli.sh** (~80 lines)
4. **03-install-copilot-cli.sh** (~80 lines)
5. **04-verify-installation.sh** (~60 lines)
6. **common.sh** (~60 lines)

#### Documentation to Create:
- **IMPLEMENTATION_LOG_AI_TOOLS.md**

---

### Stream 6: Context Menu Modularity (Priority: LOW)
**Current File**: `lib/tasks/context_menu.sh` (50+ lines)
**Target Directory**: `lib/tasks/context_menu/`
**Scripts to Create**: 4 files (3 modular + 1 common)
**Estimated Effort**: 2 hours

#### Files to Create:
1. **00-check-prerequisites.sh** (~30 lines)
2. **01-install-context-menu.sh** (~80 lines)
3. **02-verify-installation.sh** (~40 lines)
4. **common.sh** (~40 lines)

#### Documentation to Create:
- **IMPLEMENTATION_LOG_CONTEXT_MENU.md**

---

### Stream 7: Gum Modularity (Priority: HIGH - needed by TUI)
**Current File**: `lib/tasks/gum.sh` (100+ lines)
**Target Directory**: `lib/tasks/gum/`
**Scripts to Create**: 5 files (4 modular + 1 common)
**Estimated Effort**: 3 hours

#### Files to Create:
1. **00-check-prerequisites.sh** (~40 lines)
2. **01-download-gum.sh** (~70 lines)
3. **02-install-gum.sh** (~80 lines)
4. **03-verify-installation.sh** (~50 lines)
5. **common.sh** (~50 lines)

#### Documentation to Create:
- **IMPLEMENTATION_LOG_GUM.md**

---

### Stream 8: App Audit Modularity (Priority: LOW)
**Current File**: `lib/tasks/app_audit.sh` (200+ lines)
**Target Directory**: `lib/tasks/app_audit/`
**Scripts to Create**: 8 files (7 modular + 1 common)
**Estimated Effort**: 5 hours

#### Files to Create:
1. **00-check-prerequisites.sh** (~40 lines)
2. **01-scan-apt-packages.sh** (~100 lines)
3. **02-scan-snap-packages.sh** (~80 lines)
4. **03-scan-desktop-files.sh** (~70 lines)
5. **04-detect-duplicates.sh** (~120 lines)
6. **05-generate-report.sh** (~100 lines)
7. **06-verify-cleanup.sh** (~60 lines)
8. **common.sh** (~80 lines)

#### Documentation to Create:
- **IMPLEMENTATION_LOG_APP_AUDIT.md**

---

## Integration Phase (Week 2)

### Task: Update start.sh Task Registry
**File**: `start.sh`
**Effort**: 4 hours

#### Changes Required:

**Current Task Registry** (Monolithic):
```bash
TASK_REGISTRY=(
    "ghostty|verify-prereqs|task_install_ghostty|verify_ghostty_installed|5|180"
    "zsh|ghostty|task_install_zsh|verify_zsh_configured|1|30"
    "python-uv|zsh|task_install_python_uv|verify_uv_installed|1|20"
    "nodejs-fnm|zsh|task_install_nodejs_fnm|verify_fnm_installed|1|30"
    "ai-tools|nodejs-fnm|task_install_ai_tools|verify_ai_tools_installed|1|60"
    "context-menu|ghostty|task_install_context_menu|verify_context_menu_installed|1|10"
    "gum|verify-prereqs|task_install_gum|verify_gum_installed|1|10"
    "app-audit|verify-prereqs|task_run_app_audit|verify_app_audit_completed|0|30"
)
```

**New Task Registry** (Modular - 50+ granular tasks):
```bash
TASK_REGISTRY=(
    # ═══════════════════════════════════════════════════════════════
    # Ghostty Installation (8 granular steps)
    # ═══════════════════════════════════════════════════════════════
    "ghostty-00-check|verify-prereqs|ghostty/00-check-prerequisites.sh|verify_ghostty_installed|5|0"
    "ghostty-01-download-zig|ghostty-00-check|ghostty/01-download-zig.sh|verify_zig_downloaded|1|30"
    "ghostty-02-extract-zig|ghostty-01-download-zig|ghostty/02-extract-zig.sh|verify_zig_extracted|1|10"
    "ghostty-03-build-zig|ghostty-02-extract-zig|ghostty/03-build-zig.sh|verify_zig_built|1|60"
    "ghostty-04-clone-repo|ghostty-03-build-zig|ghostty/04-clone-repository.sh|verify_ghostty_cloned|1|20"
    "ghostty-05-build|ghostty-04-clone-repo|ghostty/05-build-ghostty.sh|verify_ghostty_built|1|90"
    "ghostty-06-install|ghostty-05-build|ghostty/06-install-binary.sh|verify_ghostty_installed_binary|1|10"
    "ghostty-07-verify|ghostty-06-install|ghostty/07-verify-installation.sh|verify_ghostty_functional|1|5"

    # ═══════════════════════════════════════════════════════════════
    # ZSH Configuration (6 granular steps)
    # ═══════════════════════════════════════════════════════════════
    "zsh-00-check|ghostty-07-verify|zsh/00-check-prerequisites.sh|verify_zsh_installed|1|5"
    "zsh-01-oh-my-zsh|zsh-00-check|zsh/01-install-oh-my-zsh.sh|verify_oh_my_zsh|1|30"
    "zsh-02-plugins|zsh-01-oh-my-zsh|zsh/02-install-plugins.sh|verify_zsh_plugins|1|20"
    "zsh-03-configure|zsh-02-plugins|zsh/03-configure-zshrc.sh|verify_zshrc_configured|1|15"
    "zsh-04-security|zsh-03-configure|zsh/04-install-security-check.sh|verify_security_check|1|10"
    "zsh-05-verify|zsh-04-security|zsh/05-verify-installation.sh|verify_zsh_functional|1|5"

    # ═══════════════════════════════════════════════════════════════
    # Python UV (5 granular steps)
    # ═══════════════════════════════════════════════════════════════
    "python-uv-00-check|zsh-05-verify|python_uv/00-check-prerequisites.sh|verify_uv_not_installed|1|5"
    "python-uv-01-download|python-uv-00-check|python_uv/01-download-uv.sh|verify_uv_downloaded|1|10"
    "python-uv-02-extract|python-uv-01-download|python_uv/02-extract-uv.sh|verify_uv_extracted|1|5"
    "python-uv-03-install|python-uv-02-extract|python_uv/03-install-uv.sh|verify_uv_installed_binary|1|10"
    "python-uv-04-verify|python-uv-03-install|python_uv/04-verify-installation.sh|verify_uv_functional|1|5"

    # ═══════════════════════════════════════════════════════════════
    # Node.js FNM (6 granular steps)
    # ═══════════════════════════════════════════════════════════════
    "nodejs-fnm-00-check|zsh-05-verify|nodejs_fnm/00-check-prerequisites.sh|verify_fnm_not_installed|1|5"
    "nodejs-fnm-01-download|nodejs-fnm-00-check|nodejs_fnm/01-download-fnm.sh|verify_fnm_downloaded|1|10"
    "nodejs-fnm-02-install|nodejs-fnm-01-download|nodejs_fnm/02-install-fnm.sh|verify_fnm_installed_binary|1|10"
    "nodejs-fnm-03-nodejs|nodejs-fnm-02-install|nodejs_fnm/03-install-nodejs.sh|verify_nodejs_installed|1|60"
    "nodejs-fnm-04-configure|nodejs-fnm-03-nodejs|nodejs_fnm/04-configure-shell.sh|verify_shell_configured|1|10"
    "nodejs-fnm-05-verify|nodejs-fnm-04-configure|nodejs_fnm/05-verify-installation.sh|verify_fnm_functional|1|5"

    # ═══════════════════════════════════════════════════════════════
    # AI Tools (5 granular steps)
    # ═══════════════════════════════════════════════════════════════
    "ai-tools-00-check|nodejs-fnm-05-verify|ai_tools/00-check-prerequisites.sh|verify_ai_tools_not_installed|1|5"
    "ai-tools-01-claude|ai-tools-00-check|ai_tools/01-install-claude-cli.sh|verify_claude_installed|1|30"
    "ai-tools-02-gemini|ai-tools-01-claude|ai_tools/02-install-gemini-cli.sh|verify_gemini_installed|1|30"
    "ai-tools-03-copilot|ai-tools-02-gemini|ai_tools/03-install-copilot-cli.sh|verify_copilot_installed|1|30"
    "ai-tools-04-verify|ai-tools-03-copilot|ai_tools/04-verify-installation.sh|verify_ai_tools_functional|1|5"

    # ═══════════════════════════════════════════════════════════════
    # Context Menu (3 granular steps)
    # ═══════════════════════════════════════════════════════════════
    "context-menu-00-check|ghostty-07-verify|context_menu/00-check-prerequisites.sh|verify_context_menu_not_installed|1|5"
    "context-menu-01-install|context-menu-00-check|context_menu/01-install-context-menu.sh|verify_context_menu_installed|1|10"
    "context-menu-02-verify|context-menu-01-install|context_menu/02-verify-installation.sh|verify_context_menu_functional|1|5"

    # ═══════════════════════════════════════════════════════════════
    # Gum TUI (4 granular steps)
    # ═══════════════════════════════════════════════════════════════
    "gum-00-check|verify-prereqs|gum/00-check-prerequisites.sh|verify_gum_not_installed|1|5"
    "gum-01-download|gum-00-check|gum/01-download-gum.sh|verify_gum_downloaded|1|10"
    "gum-02-install|gum-01-download|gum/02-install-gum.sh|verify_gum_installed_binary|1|10"
    "gum-03-verify|gum-02-install|gum/03-verify-installation.sh|verify_gum_functional|1|5"

    # ═══════════════════════════════════════════════════════════════
    # App Audit (7 granular steps)
    # ═══════════════════════════════════════════════════════════════
    "app-audit-00-check|verify-prereqs|app_audit/00-check-prerequisites.sh|verify_audit_not_run|0|5"
    "app-audit-01-scan-apt|app-audit-00-check|app_audit/01-scan-apt-packages.sh|verify_apt_scanned|0|30"
    "app-audit-02-scan-snap|app-audit-01-scan-apt|app_audit/02-scan-snap-packages.sh|verify_snap_scanned|0|20"
    "app-audit-03-scan-desktop|app-audit-02-scan-snap|app_audit/03-scan-desktop-files.sh|verify_desktop_scanned|0|10"
    "app-audit-04-detect-dups|app-audit-03-scan-desktop|app_audit/04-detect-duplicates.sh|verify_duplicates_detected|0|20"
    "app-audit-05-report|app-audit-04-detect-dups|app_audit/05-generate-report.sh|verify_report_generated|0|10"
    "app-audit-06-verify|app-audit-05-report|app_audit/06-verify-cleanup.sh|verify_audit_completed|0|5"
)
```

**Modified Script Execution Function**:
```bash
execute_single_task() {
    local task_id="$1"
    local deps="$2"
    local script_path="$3"      # Changed from function name to script path
    local verify_fn="$4"
    local is_optional="$5"
    local est_time="$6"

    # ... dependency checking logic (unchanged) ...

    # Execute modular script (location-independent via lib/init.sh)
    local full_script_path="${LIB_DIR}/tasks/${script_path}"

    log "INFO" "Executing modular script: $script_path"

    if bash "$full_script_path"; then
        local exit_code=$?

        if [[ $exit_code -eq 0 ]]; then
            complete_task "$task_id" "$(get_task_duration "$task_id")"
        elif [[ $exit_code -eq 2 ]]; then
            skip_task "$task_id" "Already installed or not needed"
        else
            fail_task "$task_id" "Script failed with exit code $exit_code: $script_path"
            return 1
        fi
    else
        fail_task "$task_id" "Failed to execute: $script_path"
        return 1
    fi
}
```

---

## Testing Strategy

### Unit Testing (Per Task Group)
Each task group creates its own test file:

**Example**: `tests/unit/test_ghostty_modular.sh`
```bash
#!/usr/bin/env bash
set -euo pipefail

source "$(git rev-parse --show-toplevel)/lib/init.sh"

test_ghostty_00_check() {
    echo "Testing ghostty/00-check-prerequisites.sh..."

    # Mock: Ghostty not installed
    if bash lib/tasks/ghostty/00-check-prerequisites.sh; then
        echo "✓ PASS: Prerequisites check works when not installed"
    else
        echo "✗ FAIL: Prerequisites check failed"
        return 1
    fi
}

test_ghostty_01_download() {
    echo "Testing ghostty/01-download-zig.sh..."

    # Mock download (dry run)
    if DRY_RUN=true bash lib/tasks/ghostty/01-download-zig.sh; then
        echo "✓ PASS: Download Zig script works in dry-run mode"
    else
        echo "✗ FAIL: Download Zig script failed"
        return 1
    fi
}

# ... more tests ...

main() {
    local failed=0

    test_ghostty_00_check || ((failed++))
    test_ghostty_01_download || ((failed++))
    # ... run all tests ...

    if [[ $failed -eq 0 ]]; then
        echo "ALL GHOSTTY TESTS PASSED"
        exit 0
    else
        echo "FAILED TESTS: $failed"
        exit 1
    fi
}

main "$@"
```

### Integration Testing
**File**: `tests/integration/test_modular_installation.sh`

Test complete installation flow with all modular scripts:
```bash
#!/usr/bin/env bash
set -euo pipefail

# Full end-to-end test
# 1. Fresh VM setup
# 2. Run start.sh with all modular tasks
# 3. Verify all 50+ steps execute correctly
# 4. Verify real-time output visibility
# 5. Verify total time < 10 minutes
```

---

## Documentation Requirements

### Per-Stream Documentation
Each parallel stream creates:

1. **IMPLEMENTATION_LOG_[STREAM].md**
   - Implementation decisions
   - Code challenges and solutions
   - Test results
   - Lessons learned

2. **Code comments**
   - Explain complex logic
   - Document exit codes
   - Reference original monolithic file

### Final Integration Documentation
**File**: `documentation/developer/PHASE_2_IMPLEMENTATION_SUMMARY.md`

- Summary of all 8 parallel streams
- Total scripts created: 50+
- Total lines of code: ~3,500
- Test coverage: Unit + Integration
- Performance metrics: Before/after comparison
- User experience improvements

---

## Success Criteria

### Functional Requirements
- ✅ All 50+ modular scripts execute correctly
- ✅ Real-time output visible for long operations (>10s)
- ✅ Each script follows Single Responsibility Principle
- ✅ All scripts use centralized bootstrap (lib/init.sh)
- ✅ Exit codes: 0=success, 1=failure, 2=skip
- ✅ Comprehensive logging with task IDs

### Performance Requirements
- ✅ Total installation time: <10 minutes (unchanged)
- ✅ Individual script overhead: <100ms
- ✅ Progress tracking granularity: 50+ steps vs 8 steps

### Quality Requirements
- ✅ All scripts pass unit tests
- ✅ Integration tests pass (end-to-end installation)
- ✅ Code coverage: 100% (all scripts tested)
- ✅ Documentation: Implementation logs for all 8 streams
- ✅ User experience: Real-time visibility into all operations

### Constitutional Compliance
- ✅ Single Responsibility Principle: Each script does ONE thing
- ✅ Modular Architecture: lib/ structure maintained
- ✅ Location-Independent: All scripts use lib/init.sh bootstrap
- ✅ Idempotency: Safe to re-run at any step
- ✅ Performance: <10ms overhead per script

---

## Execution Timeline

### Week 1 (Parallel Development)
**Monday-Friday**: All 8 streams execute in parallel
- Each stream creates modular scripts + common.sh
- Each stream creates unit tests
- Each stream creates implementation log

**Deliverables** (End of Week 1):
- ✅ 50+ modular scripts created
- ✅ 8 implementation logs
- ✅ 8 unit test suites
- ✅ All monolithic files ready for deletion

### Week 2 (Integration)
**Monday-Tuesday**: Integration
- Merge all 8 parallel streams
- Update start.sh task registry
- Delete monolithic files

**Wednesday-Thursday**: Testing
- Run integration tests
- End-to-end installation testing
- Performance benchmarking

**Friday**: Documentation & Finalization
- Create Phase 2 Implementation Summary
- Update COMPLETE_REFACTORING_ROADMAP.md
- Mark Phase 2 as ✅ COMPLETE

---

## Risk Mitigation

### Risk 1: Script Interdependencies
**Mitigation**: All streams are designed to be independent. No shared code except lib/init.sh (already complete).

### Risk 2: Integration Conflicts
**Mitigation**: Each stream works in isolated directory (lib/tasks/[stream]/). No file conflicts possible.

### Risk 3: Testing Complexity
**Mitigation**: Unit tests per stream + single integration test at end. Isolated failures don't block other streams.

### Risk 4: Documentation Overhead
**Mitigation**: Implementation logs created as we code (not post-facto). Clear template provided.

---

## Next Steps

### Immediate Actions
1. ✅ Review this parallel execution plan
2. ✅ Approve parallel execution strategy
3. ✅ Begin all 8 streams simultaneously

### Command to Execute
```bash
# Each stream can be executed independently by different LLM instances or in sequence

# Stream 1: Ghostty
# Create lib/tasks/ghostty/ directory and 9 scripts

# Stream 2: ZSH
# Create lib/tasks/zsh/ directory and 7 scripts

# ... continue for all 8 streams ...

# Integration (after all streams complete)
# Update start.sh task registry
# Run integration tests
# Delete monolithic files
```

---

**Plan Created**: 2025-11-20
**Status**: ✅ Ready for Execution
**Estimated Completion**: 2 weeks (1 week parallel dev + 1 week integration)
**Original Estimate**: 4 weeks sequential
**Speedup**: 2x overall (4x for development phase)
