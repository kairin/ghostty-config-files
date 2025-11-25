# Module Mapping & Orchestration Verification

**Generated**: 2025-11-25
**Last Updated**: 2025-11-25 (Comprehensive Audit Complete)
**Purpose**: Comprehensive map of all orchestrators, modules, and their relationships.

---

## 1. Bootstrap & Initialization

### Orchestrator: `lib/init.sh`
**Role**: Core bootstrap script - single entry point for all scripts.
**Sources**:
- `lib/core/logging.sh`
- `lib/core/utils.sh`
- `lib/core/errors.sh`
- `lib/core/state.sh`
- `lib/ui/tui.sh`
- `lib/ui/collapsible.sh`
- `lib/ui/progress.sh`
- `lib/verification/health_checks.sh`
- `lib/verification/environment.sh`

---

## 2. Updates & Installation

### Orchestrator: `scripts/updates/update_ghostty.sh`
**Role**: Manages the Ghostty update process (build, install, verify).
**Sources**:
- `lib/updates/ghostty-specific.sh` (orchestrator)
- `lib/installers/zig.sh`
- `lib/installers/ghostty-deps.sh`

### Sub-orchestrator: `lib/updates/ghostty-specific.sh`
**Role**: Coordinates Ghostty build and installation modules.
**Sources**:
- `lib/updates/ghostty/build.sh`
- `lib/updates/ghostty/install.sh`

### Orchestrator: `scripts/updates/daily-updates.sh`
**Role**: Daily update orchestrator with VHS recording.
**Sources**:
- `lib/ui/vhs-auto-record.sh`
- `lib/updates/apt_updates.sh`
- `lib/updates/npm_updates.sh`
- `lib/updates/source_updates.sh`
- `lib/updates/system_updates.sh`

### Orchestrator: `lib/installers/common/manager-runner.sh`
**Role**: TUI wrapper for installation managers.
**Sources**:
- `lib/installers/common/tui-helpers.sh` (orchestrator)
- `lib/ui/tui.sh`
- `lib/ui/collapsible.sh`

### Sub-orchestrator: `lib/installers/common/tui-helpers.sh`
**Role**: Coordinates TUI rendering and input modules.
**Sources**:
- `lib/ui/tui/render.sh`
- `lib/ui/tui/input.sh`

---

## 3. Documentation & Reporting

### Orchestrator: `scripts/docs/generate_dashboard.sh`
**Role**: Generates project status dashboard.
**Sources**:
- `lib/docs/dashboard.sh` (orchestrator)

### Sub-orchestrator: `lib/docs/dashboard.sh`
**Role**: Coordinates dashboard statistics and rendering.
**Sources**:
- `lib/docs/dashboard/stats.sh`
- `lib/docs/dashboard/render.sh`

### Orchestrator: `scripts/docs/generate_docs_website.sh`
**Role**: Generates documentation website.
**Sources**:
- `lib/docs/markdown_generator.sh`
- `lib/docs/index_builder.sh`
- `lib/docs/asset_compiler.sh`

### Orchestrator: `scripts/git/consolidate_todos.sh`
**Role**: Extracts and reports TODOs.
**Sources**:
- `lib/todos/extractors.sh`
- `lib/todos/report.sh` (orchestrator)

### Sub-orchestrator: `lib/todos/report.sh`
**Role**: Coordinates markdown and JSON report generation.
**Sources**:
- `lib/todos/reporters/markdown.sh`
- `lib/todos/reporters/json.sh`

---

## 4. Core Libraries & Validation

### Orchestrator: `scripts/lib/common.sh`
**Role**: Backward compatibility layer for core utilities.
**Sources**:
- `lib/core/paths.sh`
- `lib/core/validation.sh` (orchestrator)

### Sub-orchestrator: `lib/core/validation.sh`
**Role**: Unified validation API.
**Sources**:
- `lib/core/validation/files.sh`
- `lib/core/validation/input.sh`

### Core Libraries (Sourced Globally via init.sh)
| Module | Purpose |
|--------|---------|
| `lib/core/utils.sh` | Common utility functions |
| `lib/core/logging.sh` | Logging framework |
| `lib/core/state.sh` | State management |
| `lib/core/errors.sh` | Error handling |
| `lib/core/paths.sh` | Path manipulation |
| `lib/core/validation.sh` | Validation API |
| `lib/core/version-intelligence.sh` | Version comparison utilities |
| `lib/core/installation-check.sh` | Installation status checks |
| `lib/core/uninstaller.sh` | Uninstallation utilities |

---

## 5. System Health & Configuration

### Orchestrator: `scripts/health/system_health_check.sh`
**Role**: Comprehensive system health verification.
**Sources**:
- `lib/health/disk_health.sh`
- `lib/health/network_health.sh`
- `lib/health/service_health.sh`
- `lib/health/resource_health.sh`

### Orchestrator: `scripts/config/configure_zsh.sh`
**Role**: ZSH configuration management.
**Sources**:
- `lib/config/zsh/plugins.sh`
- `lib/config/zsh/theme.sh`
- `lib/config/zsh/aliases.sh`
- `lib/config/zsh/functions.sh`

### Orchestrator: `lib/verification/health_checks.sh`
**Role**: Installation verification checks.
**Sources**:
- `lib/verification/checks/pre_install_checks.sh`
- `lib/verification/checks/post_install_checks.sh`
- `lib/verification/checks/performance_checks.sh`

---

## 6. Audit Systems

### Orchestrator: `lib/tasks/app_audit.sh`
**Role**: Application audit and detection.
**Sources**:
- `lib/audit/scanners.sh`
- `lib/audit/app-detectors.sh`
- `lib/audit/app-report.sh`

### Orchestrator: `lib/tasks/system_audit.sh`
**Role**: System-wide audit with version intelligence.
**Sources**:
- `lib/audit/detectors.sh`
- `lib/audit/report.sh`

### Audit Modules Summary
| Module | Purpose |
|--------|---------|
| `lib/audit/scanners.sh` | Package scanning (APT, Snap, Flatpak) |
| `lib/audit/detectors.sh` | Duplicate/issue detection |
| `lib/audit/report.sh` | Audit report generation |
| `lib/audit/app-detectors.sh` | Application-specific detection |
| `lib/audit/app-report.sh` | Application audit reporting |

---

## 7. Archive & Specification

### Orchestrator: `scripts/archive/archive_spec.sh`
**Role**: Specification archiving.
**Sources**:
- `lib/archive/yaml-generator.sh`
- `lib/archive/validators.sh`

---

## 8. Workflows & CI/CD

### Orchestrator: `.runners-local/workflows/gh-cli-integration.sh`
**Role**: GitHub CLI integration.
**Sources**:
- `lib/workflows/gh-cli/auth.sh`
- `lib/workflows/gh-cli/api.sh`

### Orchestrator: `.runners-local/workflows/pre-commit-local.sh`
**Role**: Pre-commit validation.
**Sources**:
- `lib/workflows/pre-commit/validators.sh`
- `lib/workflows/pre-commit/formatters.sh`

---

## 9. Verification & Testing

### Orchestrator: `lib/verification/integration_tests.sh`
**Role**: Integration test runner.
**Sources**:
- `lib/verification/tests/zsh-fnm-test.sh`
- `lib/verification/tests/ghostty-zsh-test.sh`
- `lib/verification/tests/ai-nodejs-test.sh`
- `lib/verification/tests/context-menu-test.sh`
- `lib/verification/tests/phase8-tests.sh`

### Verification Modules Summary
| Module | Purpose |
|--------|---------|
| `lib/verification/unit_tests.sh` | Unit test framework |
| `lib/verification/integration_tests.sh` | Integration test orchestrator |
| `lib/verification/health_checks.sh` | Health check orchestrator |
| `lib/verification/environment.sh` | Environment detection |
| `lib/verification/duplicate_detection.sh` | Duplicate package detection |
| `lib/verification/test_runner.sh` | Generic test runner |
| `lib/verification/test_version_compare.sh` | Version comparison tests |

### Test Script: `tests/constitutional/test_script_line_limits.sh`
**Role**: Validates 300-line constitutional limit compliance.

---

## 10. UI Components

### Orchestrator: `lib/ui/collapsible.sh`
**Role**: Docker-like progressive summarization.
**Sources**:
- `lib/ui/components/task_state.sh`
- `lib/ui/components/spinner.sh`
- `lib/ui/components/render.sh`

### UI Modules Summary
| Module | Purpose |
|--------|---------|
| `lib/ui/tui.sh` | Main TUI framework (gum-based) |
| `lib/ui/collapsible.sh` | Collapsible output orchestrator |
| `lib/ui/progress.sh` | Progress bar components |
| `lib/ui/colors.sh` | Color palette definitions |
| `lib/ui/vhs-recorder.sh` | VHS recording utilities |
| `lib/ui/vhs-auto-record.sh` | Automatic VHS recording |
| `lib/ui/boxes.sh` | **DEPRECATED** - use gum instead |

### TUI Sub-modules (under lib/ui/tui/)
| Module | Purpose |
|--------|---------|
| `lib/ui/tui/render.sh` | TUI rendering functions |
| `lib/ui/tui/input.sh` | User input handling |

### Component Sub-modules (under lib/ui/components/)
| Module | Purpose |
|--------|---------|
| `lib/ui/components/task_state.sh` | Task state management |
| `lib/ui/components/spinner.sh` | Spinner/loading animations |
| `lib/ui/components/render.sh` | Component rendering |

---

## 11. Management Scripts

### Orchestrator: `scripts/utils/manage.sh`
**Role**: Unified management CLI.
**Sources**:
- `lib/manage/cleanup.sh`
- `lib/manage/docs.sh`
- `lib/manage/install.sh`
- `lib/manage/screenshots.sh`
- `lib/manage/status.sh`
- `lib/manage/update.sh`
- `lib/manage/validate.sh`

---

## 12. Task Modules

### Task Modules Summary (lib/tasks/)
| Module | Purpose | Dependencies |
|--------|---------|--------------|
| `lib/tasks/ghostty.sh` | Ghostty installation task | core modules |
| `lib/tasks/python_uv.sh` | Python + UV installation | duplicate_detection, unit_tests |
| `lib/tasks/nodejs_fnm.sh` | Node.js + FNM installation | core modules |
| `lib/tasks/zsh.sh` | ZSH configuration task | zshrc_manager |
| `lib/tasks/ai_tools.sh` | AI tools installation | core modules |
| `lib/tasks/gum.sh` | Gum TUI installation | core modules |
| `lib/tasks/glow.sh` | Glow markdown viewer | core modules |
| `lib/tasks/vhs.sh` | VHS recorder installation | core modules |
| `lib/tasks/feh.sh` | Feh image viewer | core modules |
| `lib/tasks/fastfetch.sh` | Fastfetch system info | core modules |
| `lib/tasks/go.sh` | Go language installation | core modules |
| `lib/tasks/context_menu.sh` | Context menu integration | core modules |
| `lib/tasks/system_audit.sh` | System audit task | audit modules |
| `lib/tasks/app_audit.sh` | Application audit task | audit modules |

---

## 13. Utility Modules

### Utility Modules Summary
| Module | Purpose | Used By |
|--------|---------|---------|
| `lib/utils/zshrc_manager.sh` | ZSH RC file management | nodejs_fnm steps |

---

## 14. Installer Modules

### Top-level Installer Modules
| Module | Purpose |
|--------|---------|
| `lib/installers/zig.sh` | Zig compiler installation |
| `lib/installers/ghostty-deps.sh` | Ghostty dependencies |

### Installer Step Directories
Each installer has its own step-based architecture:
- `lib/installers/ghostty/steps/` (5 steps + common)
- `lib/installers/python_uv/steps/` (5 steps + common)
- `lib/installers/nodejs_fnm/steps/` (5 steps + common)
- `lib/installers/zsh/steps/` (6 steps + common)
- `lib/installers/ai_tools/steps/` (5 steps + common)
- `lib/installers/gum/steps/` (3 steps + common)
- `lib/installers/glow/steps/` (3 steps + common)
- `lib/installers/vhs/steps/` (5 steps + common)
- `lib/installers/feh/steps/` (4 steps + common)
- `lib/installers/fastfetch/steps/` (3 steps + common)
- `lib/installers/go/steps/` (2 steps + common)
- `lib/installers/context_menu/steps/` (3 steps + common)

---

## Deprecated/Removed Modules

| Module | Status | Replacement |
|--------|--------|-------------|
| `lib/ui/boxes.sh` | DEPRECATED | Use `gum` TUI framework |

---

## Verification Status

**Comprehensive Audit (2025-11-25)**:
- [x] All 93 lib/ modules pass syntax check (bash -n)
- [x] All orchestrators correctly source their modules
- [x] No orphaned scripts (all modules are sourced somewhere)
- [x] 1 deprecated module identified (lib/ui/boxes.sh)

**Module Count by Category**:
| Category | Count |
|----------|-------|
| Core | 9 |
| UI | 10 |
| Audit | 5 |
| Tasks | 14 |
| Verification | 12 |
| Updates | 7 |
| Health | 4 |
| Config | 4 |
| Docs | 6 |
| Workflows | 4 |
| Manage | 7 |
| Archive | 2 |
| Todos | 4 |
| Utils | 1 |
| Installers | 2 |
| **Total** | **91** |

**Constitutional Compliance**:
- Total Scripts: 233
- Passing (<300 lines): 200
- Failing (>300 lines): 33 (legacy violations in catalog)
- Compliance Rate: 85%
