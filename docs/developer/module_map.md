# Module Mapping & Orchestration Verification

**Generated**: 2025-11-25
**Last Updated**: 2025-11-25 (Phase 6 & 7 Complete)
**Purpose**: Ensure all modules are correctly mapped to orchestrators and no scripts are orphaned.

---

## 1. Updates & Installation

### Orchestrator: `scripts/updates/update_ghostty.sh`
**Role**: Manages the Ghostty update process (build, install, verify).
**Sources**:
- `lib/updates/ghostty-specific.sh` (orchestrator)
- `lib/installers/zig.sh`
- `lib/installers/ghostty-deps.sh`

**Function Calls**:
- `install_ghostty_dependencies()` -> `ghostty-deps.sh`
- `verify_build_tools()` -> `ghostty-deps.sh`
- `install_zig()` -> `zig.sh`
- `build_ghostty()` -> `ghostty-specific.sh` -> `ghostty/build.sh`
- `install_ghostty()` -> `ghostty-specific.sh` -> `ghostty/install.sh`

### Sub-orchestrator: `lib/updates/ghostty-specific.sh` (141 lines)
**Role**: Coordinates Ghostty build and installation modules.
**Sources**:
- `lib/updates/ghostty/build.sh` (188 lines)
- `lib/updates/ghostty/install.sh` (209 lines)

**Function Mapping**:
| Function | Module |
|----------|--------|
| `get_ghostty_version()` | ghostty-specific.sh |
| `get_step_status()` | ghostty-specific.sh |
| `build_ghostty()` | ghostty/build.sh |
| `verify_critical_build_tools()` | ghostty/build.sh |
| `verify_gtk4_libadwaita()` | ghostty/build.sh |
| `install_ghostty()` | ghostty/install.sh |
| `kill_ghostty_processes()` | ghostty/install.sh |
| `backup_ghostty_config()` | ghostty/install.sh |
| `test_ghostty_config()` | ghostty/install.sh |

### Orchestrator: `lib/installers/common/manager-runner.sh`
**Role**: TUI wrapper for installation managers.
**Sources**:
- `lib/installers/common/tui-helpers.sh` (orchestrator)
- `lib/ui/tui.sh`
- `lib/ui/collapsible.sh`

**Function Calls**:
- `init_tui()` -> `tui.sh`
- `show_component_header()` -> `tui-helpers.sh` -> `tui/render.sh`
- `register_task()` -> `collapsible.sh`
- `show_component_footer()` -> `tui-helpers.sh` -> `tui/render.sh`

### Sub-orchestrator: `lib/installers/common/tui-helpers.sh` (67 lines)
**Role**: Coordinates TUI rendering and input modules.
**Sources**:
- `lib/ui/tui/render.sh` (225 lines)
- `lib/ui/tui/input.sh` (260 lines)

**Function Mapping**:
| Function | Module |
|----------|--------|
| `show_component_header()` | tui/render.sh |
| `show_component_footer()` | tui/render.sh |
| `show_progress_bar()` | tui/render.sh |
| `format_duration()` | tui/render.sh |
| `confirm_action()` | tui/input.sh |
| `select_option()` | tui/input.sh |
| `validate_step_format()` | tui/input.sh |

---

## 2. Documentation & Reporting

### Orchestrator: `scripts/docs/generate_dashboard.sh`
**Role**: Generates project status dashboard.
**Sources**:
- `lib/docs/dashboard.sh` (orchestrator)

**Function Calls**:
- `collect_spec_statistics()` -> `dashboard.sh`
- `calculate_aggregate_stats()` -> `dashboard.sh` -> `dashboard/stats.sh`
- `generate_markdown_dashboard()` -> `dashboard.sh` -> `dashboard/render.sh`

### Sub-orchestrator: `lib/docs/dashboard.sh` (141 lines)
**Role**: Coordinates dashboard statistics and rendering.
**Sources**:
- `lib/docs/dashboard/stats.sh` (234 lines)
- `lib/docs/dashboard/render.sh` (293 lines)

**Function Mapping**:
| Function | Module |
|----------|--------|
| `generate_markdown_dashboard()` | dashboard.sh |
| `generate_dashboard()` | dashboard.sh |
| `classify_status()` | dashboard/stats.sh |
| `get_status_emoji()` | dashboard/stats.sh |
| `calculate_aggregate_stats()` | dashboard/stats.sh |
| `generate_summary_metrics()` | dashboard/render.sh |
| `generate_status_distribution()` | dashboard/render.sh |
| `generate_json_format()` | dashboard/render.sh |
| `generate_csv_format()` | dashboard/render.sh |

### Orchestrator: `scripts/git/consolidate_todos.sh`
**Role**: Extracts and reports TODOs.
**Sources**:
- `lib/todos/extractors.sh`
- `lib/todos/report.sh` (orchestrator)

**Function Calls**:
- `extract_incomplete_tasks()` -> `extractors.sh`
- `generate_checklist_header()` -> `report.sh` -> `reporters/markdown.sh`
- `group_by_specification()` -> `report.sh` -> `reporters/markdown.sh`

### Sub-orchestrator: `lib/todos/report.sh` (179 lines)
**Role**: Coordinates markdown and JSON report generation.
**Sources**:
- `lib/todos/reporters/markdown.sh` (254 lines)
- `lib/todos/reporters/json.sh` (229 lines)

**Function Mapping**:
| Function | Module |
|----------|--------|
| `calculate_total_effort()` | report.sh |
| `find_spec_dir()` | report.sh |
| `sort_tasks()` | report.sh |
| `generate_checklist_header()` | reporters/markdown.sh |
| `generate_summary_stats()` | reporters/markdown.sh |
| `group_by_specification()` | reporters/markdown.sh |
| `group_by_priority()` | reporters/markdown.sh |
| `json_escape()` | reporters/json.sh |
| `generate_json_tasks()` | reporters/json.sh |

---

## 3. Core & Validation

### Orchestrator: `scripts/lib/common.sh`
**Role**: Backward compatibility layer for core utilities.
**Sources**:
- `lib/core/paths.sh`
- `lib/core/validation.sh` (orchestrator)

**Function Calls**:
- Re-exports all functions from sourced modules.

### Sub-orchestrator: `lib/core/validation.sh` (61 lines)
**Role**: Unified validation API.
**Sources**:
- `lib/core/validation/files.sh` (214 lines)
- `lib/core/validation/input.sh` (253 lines)

**Function Mapping**:
| Function | Module |
|----------|--------|
| `require_file()` | validation/files.sh |
| `require_dir()` | validation/files.sh |
| `ensure_dir()` | validation/files.sh |
| `is_writable()` | validation/files.sh |
| `validate_shell_syntax()` | validation/files.sh |
| `command_exists()` | validation/input.sh |
| `require_command()` | validation/input.sh |
| `validate_json()` | validation/input.sh |
| `validate_yaml()` | validation/input.sh |
| `is_valid_url()` | validation/input.sh |
| `is_valid_email()` | validation/input.sh |

---

## 4. Workflows & CI/CD

### Orchestrator: `.runners-local/workflows/gh-cli-integration.sh`
**Role**: GitHub CLI integration without Actions consumption.
**Sources**:
- `lib/workflows/gh-cli/auth.sh`
- `lib/workflows/gh-cli/api.sh`

**Function Calls**:
- `get_repo_status_summary()` -> `api.sh`
- `get_workflow_runs()` -> `api.sh`
- `create_constitutional_branch()` -> `api.sh`

### Orchestrator: `.runners-local/workflows/pre-commit-local.sh`
**Role**: Pre-commit validation.
**Sources**:
- `lib/workflows/pre-commit/validators.sh`
- `lib/workflows/pre-commit/formatters.sh`

**Function Calls**:
- `validate_file_by_extension()` -> `validators.sh`
- `validate_constitutional_compliance()` -> `validators.sh`
- `validate_commit_message()` -> `validators.sh`

---

## 5. Constitutional Testing

### Test Script: `tests/constitutional/test_script_line_limits.sh` (130 lines)
**Role**: Validates 300-line constitutional limit compliance.
**Outputs**:
- Console summary
- `logs/constitutional_check.log`

---

## Verification Status

**Phase 6 & 7 Completion Status**:
- [x] `lib/updates/ghostty-specific.sh`: 396 -> 141 lines
- [x] `lib/todos/report.sh`: 394 -> 179 lines
- [x] `lib/docs/dashboard.sh`: 386 -> 141 lines
- [x] `lib/installers/common/tui-helpers.sh`: 331 -> 67 lines
- [x] `lib/core/validation.sh`: 310 -> 61 lines

**New Modules Created**:
- [x] `lib/updates/ghostty/build.sh` (188 lines)
- [x] `lib/updates/ghostty/install.sh` (209 lines)
- [x] `lib/todos/reporters/markdown.sh` (254 lines)
- [x] `lib/todos/reporters/json.sh` (229 lines)
- [x] `lib/docs/dashboard/stats.sh` (234 lines)
- [x] `lib/docs/dashboard/render.sh` (293 lines)
- [x] `lib/ui/tui/render.sh` (225 lines)
- [x] `lib/ui/tui/input.sh` (260 lines)
- [x] `lib/core/validation/files.sh` (214 lines)
- [x] `lib/core/validation/input.sh` (253 lines)
- [x] `tests/constitutional/test_script_line_limits.sh` (130 lines)

**Constitutional Compliance**:
- Total Scripts: 233
- Passing (<300 lines): 200
- Failing (>300 lines): 33 (legacy violations in catalog)
- Compliance Rate: 85%

**All Modules Sourced**: Every new module in `lib/` is sourced by at least one orchestrator.
**All Functions Used**: Key exported functions are invoked by the orchestrators.
**No Orphans**: No scripts were found to be isolated or unused.
