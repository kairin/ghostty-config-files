# Data Model: Complete Terminal Development Infrastructure

**Feature**: 005-complete-terminal-infrastructure
**Created**: 2025-11-16
**Status**: Planning Phase

This document defines the core entities, their relationships, and state transitions for the complete terminal infrastructure system.

---

## Entity: Installation Configuration

**Purpose**: Represents the complete installation state and user choices for terminal environment setup.

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `installation_id` | string (UUID) | Yes | auto-generated | Unique identifier for installation session |
| `timestamp` | ISO 8601 datetime | Yes | current time | When installation started |
| `components` | object | Yes | {} | Component installation selections |
| `components.core` | array[string] | Yes | ["ghostty", "zsh", "node"] | Core components (always installed) |
| `components.optional` | array[string] | No | [] | Optional components selected by user |
| `components.ai_tools` | array[string] | No | [] | AI tools to install (claude, gemini, copilot, etc.) |
| `components.productivity` | array[string] | No | [] | Modern Unix tools (bat, exa, ripgrep, etc.) |
| `components.theming` | string | No | null | Theme choice (powerlevel10k, starship, none) |
| `components.web_stack` | boolean | No | true | Install modern web development stack |
| `user_options` | object | Yes | {} | User configuration options |
| `user_options.shell` | string | Yes | "zsh" | Default shell choice |
| `user_options.node_version` | string | Yes | "latest" | Node.js version policy |
| `user_options.preserve_existing` | boolean | Yes | true | Preserve existing configurations |
| `user_options.dry_run` | boolean | No | false | Dry run mode (validate only) |
| `state` | object | Yes | {} | Current installation state |
| `state.status` | enum | Yes | "pending" | Overall status (pending, in_progress, completed, failed, rolled_back) |
| `state.current_phase` | integer | No | null | Current installation phase (1-9) |
| `state.current_task` | string | No | null | Currently executing task |
| `state.completed_tasks` | array[string] | Yes | [] | List of completed task IDs |
| `state.failed_tasks` | array[object] | Yes | [] | Failed tasks with error details |
| `state.parallel_tasks` | array[object] | No | [] | Currently running parallel tasks |
| `backup_path` | string | No | null | Path to configuration backup |
| `logs` | object | Yes | {} | Installation logs |
| `logs.main_log` | string | Yes | `/tmp/ghostty-install-{timestamp}.log` | Main installation log |
| `logs.task_logs` | object | Yes | {} | Per-task log files (task_id -> path) |
| `logs.error_log` | string | Yes | `/tmp/ghostty-install-errors-{timestamp}.log` | Error log |
| `performance` | object | Yes | {} | Performance metrics |
| `performance.start_time` | timestamp | Yes | auto | Installation start timestamp |
| `performance.end_time` | timestamp | No | null | Installation end timestamp |
| `performance.total_duration` | float | No | null | Total installation time (seconds) |
| `performance.task_durations` | object | Yes | {} | Per-task execution times (task_id -> duration) |

### Validation Rules

1. `installation_id` must be unique across all installations
2. At least one core component must be selected
3. `components.optional` cannot include items already in `components.core`
4. `state.status` transitions must follow valid state machine (see State Transitions)
5. `user_options.shell` must be a valid installed shell (bash, zsh, fish)
6. `user_options.node_version` must be "latest" or valid semver pattern
7. `backup_path` must exist and be readable if `state.status` is "completed" or "rolled_back"
8. `logs.main_log` must exist and be writable
9. `performance.end_time` must be >= `performance.start_time`

### State Transitions

```
pending → in_progress → completed
           ↓
        failed → rolled_back
```

**Transition Rules**:
- `pending → in_progress`: When first task starts executing
- `in_progress → completed`: When all tasks succeed
- `in_progress → failed`: When any critical task fails
- `failed → rolled_back`: After successful rollback to backup
- `failed → completed`: After manual recovery and retry
- No transition from `completed` or `rolled_back` (terminal states)

### Relationships

- **HAS MANY** Task Executions (via `state.completed_tasks`, `state.failed_tasks`, `state.parallel_tasks`)
- **HAS ONE** Backup (via `backup_path`)
- **GENERATES** Performance Metrics (via `performance`)
- **CREATES** Log Files (via `logs`)

---

## Entity: Module Contract

**Purpose**: Defines the interface, dependencies, and testing requirements for individual installation modules.

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `module_id` | string | Yes | - | Unique module identifier (e.g., "install_node") |
| `module_name` | string | Yes | - | Human-readable module name |
| `module_path` | string | Yes | - | Absolute path to module script |
| `version` | string | Yes | "1.0.0" | Module version (semver) |
| `contract_version` | string | Yes | "1.0.0" | Contract specification version |
| `description` | string | Yes | - | Brief module description |
| `interface` | object | Yes | {} | Module interface specification |
| `interface.functions` | array[object] | Yes | [] | Exported functions |
| `interface.functions[].name` | string | Yes | - | Function name |
| `interface.functions[].description` | string | Yes | - | Function description |
| `interface.functions[].parameters` | array[object] | Yes | [] | Function parameters |
| `interface.functions[].returns` | object | Yes | {} | Return value specification |
| `interface.functions[].exit_codes` | object | Yes | {} | Exit code meanings |
| `dependencies` | object | Yes | {} | Module dependencies |
| `dependencies.modules` | array[string] | Yes | [] | Required module IDs |
| `dependencies.binaries` | array[object] | Yes | [] | Required system binaries |
| `dependencies.binaries[].name` | string | Yes | - | Binary name |
| `dependencies.binaries[].min_version` | string | No | null | Minimum version required |
| `dependencies.binaries[].check_command` | string | Yes | - | Command to verify presence |
| `dependencies.packages` | array[object] | Yes | [] | Required system packages |
| `dependencies.env_vars` | array[string] | Yes | [] | Required environment variables |
| `testing` | object | Yes | {} | Testing requirements |
| `testing.test_file` | string | Yes | - | Path to test file |
| `testing.unit_tests` | array[object] | Yes | [] | Unit test specifications |
| `testing.integration_tests` | array[object] | No | [] | Integration test specifications |
| `testing.max_execution_time` | integer | Yes | 10 | Maximum test duration (seconds) |
| `testing.coverage_threshold` | float | No | 0.8 | Minimum test coverage (0.0-1.0) |
| `metadata` | object | Yes | {} | Module metadata |
| `metadata.author` | string | No | null | Module author |
| `metadata.created` | ISO 8601 date | Yes | - | Creation date |
| `metadata.updated` | ISO 8601 date | Yes | - | Last update date |
| `metadata.tags` | array[string] | No | [] | Categorization tags |
| `metadata.documentation_url` | string | No | null | Documentation link |

### Validation Rules

1. `module_id` must be unique across all modules
2. `module_id` must match filename (e.g., "install_node" → "install_node.sh")
3. `module_path` must point to existing, executable file
4. `version` and `contract_version` must be valid semver
5. All functions in `interface.functions` must exist in module
6. Dependency modules in `dependencies.modules` must exist
7. Required binaries in `dependencies.binaries` must be verifiable
8. `testing.test_file` must exist and contain specified tests
9. `testing.max_execution_time` must be <= 10 seconds (constitutional requirement)
10. No circular dependencies allowed (module A → B → A)

### State Transitions

Modules don't have runtime state, but contract validation has states:

```
unvalidated → validated → tested → approved
                ↓           ↓
              failed     failed
```

### Relationships

- **DEPENDS ON** Other Modules (via `dependencies.modules`)
- **REQUIRES** System Binaries (via `dependencies.binaries`)
- **REQUIRES** System Packages (via `dependencies.packages`)
- **HAS ONE** Test Suite (via `testing.test_file`)
- **USED BY** Installation Configuration (via component selection)

---

## Entity: CI/CD Workflow

**Purpose**: Represents local and remote CI/CD workflow execution state and results.

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `workflow_id` | string (UUID) | Yes | auto-generated | Unique workflow execution ID |
| `workflow_name` | string | Yes | - | Workflow name (e.g., "astro-build", "accessibility-check") |
| `workflow_type` | enum | Yes | - | Workflow type (local, github, hybrid) |
| `trigger` | object | Yes | {} | Workflow trigger information |
| `trigger.event` | string | Yes | - | Triggering event (push, pull_request, manual, schedule) |
| `trigger.actor` | string | Yes | - | User or system that triggered workflow |
| `trigger.timestamp` | ISO 8601 datetime | Yes | current time | When workflow was triggered |
| `stages` | array[object] | Yes | [] | Workflow stages |
| `stages[].stage_id` | string | Yes | - | Stage identifier |
| `stages[].stage_name` | string | Yes | - | Human-readable stage name |
| `stages[].status` | enum | Yes | "pending" | Stage status (pending, running, success, failure, skipped) |
| `stages[].start_time` | timestamp | No | null | Stage start time |
| `stages[].end_time` | timestamp | No | null | Stage end time |
| `stages[].duration` | float | No | null | Stage duration (seconds) |
| `stages[].jobs` | array[object] | Yes | [] | Jobs within stage |
| `stages[].artifacts` | array[object] | No | [] | Generated artifacts |
| `quality_gates` | array[object] | Yes | [] | Quality gate checks |
| `quality_gates[].gate_name` | string | Yes | - | Quality gate name |
| `quality_gates[].gate_type` | enum | Yes | - | Gate type (performance, accessibility, security, build, test) |
| `quality_gates[].status` | enum | Yes | "pending" | Gate status (pending, passed, failed, skipped) |
| `quality_gates[].threshold` | object | Yes | {} | Pass/fail threshold |
| `quality_gates[].actual_value` | any | No | null | Measured value |
| `quality_gates[].details` | object | No | {} | Additional gate details |
| `environment` | object | Yes | {} | Execution environment |
| `environment.runner` | string | Yes | - | Runner type (local, github-hosted, self-hosted) |
| `environment.os` | string | Yes | - | Operating system |
| `environment.arch` | string | Yes | - | CPU architecture |
| `environment.node_version` | string | No | null | Node.js version |
| `environment.uv_version` | string | No | null | uv version |
| `results` | object | Yes | {} | Workflow results |
| `results.status` | enum | Yes | "pending" | Overall status (pending, running, success, failure, cancelled) |
| `results.conclusion` | string | No | null | Human-readable conclusion |
| `results.start_time` | timestamp | Yes | auto | Workflow start time |
| `results.end_time` | timestamp | No | null | Workflow end time |
| `results.total_duration` | float | No | null | Total duration (seconds) |
| `results.logs_path` | string | Yes | - | Path to workflow logs |
| `results.artifacts_path` | string | No | null | Path to artifacts directory |
| `github_actions` | object | No | {} | GitHub Actions specific data |
| `github_actions.run_id` | integer | No | null | GitHub run ID |
| `github_actions.run_number` | integer | No | null | GitHub run number |
| `github_actions.minutes_consumed` | float | No | 0.0 | GitHub Actions minutes used |

### Validation Rules

1. `workflow_id` must be unique per execution
2. `workflow_type` must be one of: "local", "github", "hybrid"
3. `stages` must have at least one stage
4. Stage execution order must be preserved (stage[n].start_time <= stage[n+1].start_time)
5. Quality gates must all pass for workflow to succeed
6. `github_actions.minutes_consumed` must be 0.0 for `workflow_type: "local"` (constitutional requirement)
7. `results.end_time` must be >= `results.start_time`
8. All quality gate thresholds must be defined before execution

### State Transitions

**Workflow Status**:
```
pending → running → success
           ↓
        failure
           ↓
       cancelled
```

**Stage Status**:
```
pending → running → success
           ↓         ↓
        failure   skipped
```

**Quality Gate Status**:
```
pending → passed
   ↓
 failed
   ↓
 skipped
```

### Relationships

- **HAS MANY** Stages (via `stages`)
- **HAS MANY** Quality Gates (via `quality_gates`)
- **EXECUTES IN** Environment (via `environment`)
- **PRODUCES** Results (via `results`)
- **MAY LINK TO** GitHub Actions Run (via `github_actions`)
- **GENERATES** Logs (via `results.logs_path`)
- **GENERATES** Artifacts (via `results.artifacts_path`)

---

## Entity: Performance Metrics

**Purpose**: Tracks system performance measurements for shell startup, build times, and quality benchmarks.

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `metric_id` | string (UUID) | Yes | auto-generated | Unique metric measurement ID |
| `metric_type` | enum | Yes | - | Metric category (shell_startup, build, lighthouse, bundle_size, test_execution) |
| `timestamp` | ISO 8601 datetime | Yes | current time | When metric was measured |
| `environment` | object | Yes | {} | Measurement environment |
| `environment.hostname` | string | Yes | - | System hostname |
| `environment.os_version` | string | Yes | - | OS version |
| `environment.kernel_version` | string | Yes | - | Kernel version |
| `environment.cpu_model` | string | Yes | - | CPU model |
| `environment.memory_total` | integer | Yes | - | Total system memory (MB) |
| `measurements` | object | Yes | {} | Metric measurements |
| `measurements.shell_startup` | object | No | {} | Shell startup metrics |
| `measurements.shell_startup.total_time` | float | No | null | Total startup time (ms) |
| `measurements.shell_startup.config_load_time` | float | No | null | Config load time (ms) |
| `measurements.shell_startup.plugin_load_time` | float | No | null | Plugin load time (ms) |
| `measurements.shell_startup.theme_render_time` | float | No | null | Theme render time (ms) |
| `measurements.build` | object | No | {} | Build metrics |
| `measurements.build.total_time` | float | No | null | Total build time (seconds) |
| `measurements.build.typescript_check_time` | float | No | null | TypeScript check time (seconds) |
| `measurements.build.bundle_time` | float | No | null | Bundle generation time (seconds) |
| `measurements.build.optimization_time` | float | No | null | Optimization time (seconds) |
| `measurements.lighthouse` | object | No | {} | Lighthouse scores |
| `measurements.lighthouse.performance` | integer | No | null | Performance score (0-100) |
| `measurements.lighthouse.accessibility` | integer | No | null | Accessibility score (0-100) |
| `measurements.lighthouse.best_practices` | integer | No | null | Best practices score (0-100) |
| `measurements.lighthouse.seo` | integer | No | null | SEO score (0-100) |
| `measurements.bundle_size` | object | No | {} | Bundle size metrics |
| `measurements.bundle_size.total_js` | integer | No | null | Total JS size (bytes) |
| `measurements.bundle_size.total_css` | integer | No | null | Total CSS size (bytes) |
| `measurements.bundle_size.initial_load` | integer | No | null | Initial load size (bytes) |
| `thresholds` | object | Yes | {} | Performance thresholds |
| `thresholds.shell_startup_max` | float | Yes | 50.0 | Max shell startup time (ms) |
| `thresholds.build_time_max` | float | Yes | 120.0 | Max build time (seconds) |
| `thresholds.lighthouse_min` | integer | Yes | 95 | Min Lighthouse score |
| `thresholds.bundle_size_max` | integer | Yes | 102400 | Max initial load (bytes, 100KB) |
| `status` | enum | Yes | - | Threshold check status (passed, failed, warning) |
| `violations` | array[object] | Yes | [] | Threshold violations |
| `violations[].threshold_name` | string | Yes | - | Violated threshold name |
| `violations[].expected` | any | Yes | - | Expected value/threshold |
| `violations[].actual` | any | Yes | - | Actual measured value |
| `violations[].severity` | enum | Yes | - | Violation severity (error, warning) |
| `baseline` | object | No | {} | Baseline comparison |
| `baseline.metric_id` | string | No | null | Baseline metric ID for comparison |
| `baseline.delta` | object | No | {} | Delta from baseline (field -> change) |
| `baseline.regression` | boolean | No | false | Whether this is a performance regression |

### Validation Rules

1. `metric_id` must be unique per measurement
2. `metric_type` must match populated `measurements` fields
3. All `measurements` values must be non-negative
4. Lighthouse scores must be 0-100 inclusive
5. `status` must be "passed" if no violations
6. `status` must be "failed" if any error-severity violations
7. Shell startup time must be < 50ms for "passed" status (constitutional requirement)
8. Lighthouse scores must be >= 95 for "passed" status (constitutional requirement)
9. Bundle size must be <= 100KB for "passed" status (constitutional requirement)
10. If `baseline.metric_id` provided, it must reference existing metric

### State Transitions

Metrics are immutable once recorded, but status can be:
```
passed  (all thresholds met)
warning (non-critical thresholds exceeded)
failed  (critical thresholds exceeded)
```

### Relationships

- **MEASURED IN** Environment (via `environment`)
- **COMPARED TO** Baseline Metric (via `baseline.metric_id`)
- **GENERATED BY** CI/CD Workflow (workflow generates metrics)
- **INFORMS** Quality Gates (metrics determine gate status)

---

## Entity: Quality Gate Results

**Purpose**: Records automated quality validation results for accessibility, security, and best practices.

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `gate_id` | string (UUID) | Yes | auto-generated | Unique quality gate execution ID |
| `gate_type` | enum | Yes | - | Gate type (accessibility, security, performance, build) |
| `gate_name` | string | Yes | - | Human-readable gate name |
| `timestamp` | ISO 8601 datetime | Yes | current time | When gate was executed |
| `workflow_id` | string | No | null | Associated workflow ID |
| `configuration` | object | Yes | {} | Gate configuration |
| `configuration.tool` | string | Yes | - | Tool used (axe-core, lighthouse, npm-audit, etc.) |
| `configuration.tool_version` | string | Yes | - | Tool version |
| `configuration.rules` | array[string] | Yes | [] | Enabled rules/checks |
| `configuration.thresholds` | object | Yes | {} | Pass/fail thresholds |
| `results` | object | Yes | {} | Gate results |
| `results.status` | enum | Yes | - | Overall status (passed, failed, warning, error) |
| `results.summary` | object | Yes | {} | Results summary |
| `results.summary.total_checks` | integer | Yes | 0 | Total checks performed |
| `results.summary.passed` | integer | Yes | 0 | Checks passed |
| `results.summary.failed` | integer | Yes | 0 | Checks failed |
| `results.summary.warnings` | integer | Yes | 0 | Checks with warnings |
| `results.summary.skipped` | integer | Yes | 0 | Checks skipped |
| `violations` | array[object] | Yes | [] | Detected violations |
| `violations[].rule_id` | string | Yes | - | Violated rule ID |
| `violations[].severity` | enum | Yes | - | Violation severity (critical, high, moderate, low, info) |
| `violations[].description` | string | Yes | - | Violation description |
| `violations[].location` | object | No | {} | Violation location (file, line, selector, etc.) |
| `violations[].remediation` | string | No | null | How to fix violation |
| `violations[].documentation_url` | string | No | null | Rule documentation link |
| `accessibility` | object | No | {} | Accessibility-specific results |
| `accessibility.wcag_violations` | array[object] | No | [] | WCAG violations |
| `accessibility.wcag_violations[].criterion` | string | Yes | - | WCAG criterion (e.g., "1.4.3") |
| `accessibility.wcag_violations[].level` | enum | Yes | - | WCAG level (A, AA, AAA) |
| `accessibility.wcag_violations[].impact` | enum | Yes | - | Impact (critical, serious, moderate, minor) |
| `accessibility.wcag_violations[].affected_elements` | array[object] | Yes | [] | Affected DOM elements |
| `accessibility.incomplete_checks` | array[object] | No | [] | Checks requiring manual review |
| `security` | object | No | {} | Security-specific results |
| `security.vulnerabilities` | array[object] | No | [] | Security vulnerabilities |
| `security.vulnerabilities[].package` | string | Yes | - | Affected package |
| `security.vulnerabilities[].version` | string | Yes | - | Vulnerable version |
| `security.vulnerabilities[].severity` | enum | Yes | - | Vulnerability severity (critical, high, moderate, low) |
| `security.vulnerabilities[].cve_id` | string | No | null | CVE identifier |
| `security.vulnerabilities[].fixed_in` | string | No | null | Version with fix |
| `security.vulnerabilities[].recommendation` | string | Yes | - | Remediation recommendation |
| `reports` | object | Yes | {} | Generated reports |
| `reports.json_path` | string | Yes | - | Path to JSON report |
| `reports.html_path` | string | No | null | Path to HTML report |
| `reports.summary_path` | string | No | null | Path to summary report |
| `execution` | object | Yes | {} | Execution details |
| `execution.start_time` | timestamp | Yes | - | Gate start time |
| `execution.end_time` | timestamp | Yes | - | Gate end time |
| `execution.duration` | float | Yes | - | Execution duration (seconds) |
| `execution.exit_code` | integer | Yes | - | Tool exit code |

### Validation Rules

1. `gate_id` must be unique per execution
2. `gate_type` must match populated type-specific fields (accessibility, security, etc.)
3. `configuration.tool` must be a valid supported tool
4. `results.status` must be "passed" if `results.summary.failed == 0`
5. `results.status` must be "failed" if any critical/high severity violations
6. For accessibility gates:
   - All WCAG 2.1 Level AA violations must be "failed" status
   - Incomplete checks require manual review flag
7. For security gates:
   - Critical/high vulnerabilities must be "failed" status
   - Moderate vulnerabilities may be "warning" status
8. `execution.end_time` must be >= `execution.start_time`
9. Sum of summary counts must equal `total_checks`: `passed + failed + warnings + skipped`
10. `workflow_id` if provided must reference valid workflow

### State Transitions

Quality gates are immutable once executed, but status follows:

```
passed   (all checks passed, no violations)
warning  (minor violations, non-blocking)
failed   (critical violations, blocking)
error    (gate execution failed)
```

### Relationships

- **EXECUTES WITH** Tool Configuration (via `configuration`)
- **PRODUCES** Violation Reports (via `violations`, `accessibility`, `security`)
- **GENERATES** Report Files (via `reports`)
- **BELONGS TO** CI/CD Workflow (via `workflow_id`)
- **BLOCKS** Deployment (if status is "failed")

---

## Entity: Task Display State

**Purpose**: Manages the real-time display state of parallel task execution during installation.

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `display_id` | string (UUID) | Yes | auto-generated | Unique display session ID |
| `session_type` | enum | Yes | - | Session type (installation, update, validation, build) |
| `active_tasks` | array[object] | Yes | [] | Currently active tasks |
| `active_tasks[].task_id` | string | Yes | - | Task identifier |
| `active_tasks[].task_name` | string | Yes | - | Human-readable task name |
| `active_tasks[].status` | enum | Yes | "queued" | Task status (queued, running, completed, failed) |
| `active_tasks[].start_time` | timestamp | No | null | Task start time |
| `active_tasks[].end_time` | timestamp | No | null | Task end time |
| `active_tasks[].duration` | float | No | null | Task duration (seconds) |
| `active_tasks[].progress` | object | No | {} | Task progress information |
| `active_tasks[].progress.current` | integer | No | 0 | Current progress value |
| `active_tasks[].progress.total` | integer | No | 100 | Total progress value |
| `active_tasks[].progress.percentage` | float | No | 0.0 | Progress percentage (0.0-100.0) |
| `active_tasks[].subtasks` | array[object] | No | [] | Subtask hierarchy |
| `active_tasks[].subtasks[].subtask_id` | string | Yes | - | Subtask identifier |
| `active_tasks[].subtasks[].subtask_name` | string | Yes | - | Subtask name |
| `active_tasks[].subtasks[].status` | enum | Yes | "pending" | Subtask status |
| `active_tasks[].output_buffer` | string | No | "" | Captured verbose output |
| `active_tasks[].output_path` | string | No | null | Path to full output log |
| `active_tasks[].expanded` | boolean | Yes | false | Whether verbose output is shown |
| `display_config` | object | Yes | {} | Display configuration |
| `display_config.max_visible_tasks` | integer | Yes | 10 | Maximum tasks shown simultaneously |
| `display_config.auto_collapse_completed` | boolean | Yes | true | Auto-collapse completed tasks |
| `display_config.collapse_delay` | float | Yes | 2.0 | Delay before auto-collapse (seconds) |
| `display_config.refresh_rate` | float | Yes | 0.1 | Display refresh rate (seconds) |
| `display_config.terminal_width` | integer | Yes | 80 | Terminal width (columns) |
| `display_config.terminal_height` | integer | Yes | 24 | Terminal height (rows) |
| `layout` | object | Yes | {} | Current display layout |
| `layout.header_lines` | integer | Yes | 3 | Lines reserved for header |
| `layout.footer_lines` | integer | Yes | 2 | Lines reserved for footer |
| `layout.task_lines` | integer | Yes | - | Lines available for tasks |
| `layout.scroll_position` | integer | Yes | 0 | Current scroll position |
| `layout.needs_refresh` | boolean | Yes | true | Whether display needs refresh |
| `statistics` | object | Yes | {} | Display statistics |
| `statistics.total_tasks` | integer | Yes | 0 | Total tasks in session |
| `statistics.queued_tasks` | integer | Yes | 0 | Tasks queued |
| `statistics.running_tasks` | integer | Yes | 0 | Tasks currently running |
| `statistics.completed_tasks` | integer | Yes | 0 | Tasks completed |
| `statistics.failed_tasks` | integer | Yes | 0 | Tasks failed |
| `statistics.parallel_limit` | integer | Yes | 4 | Max parallel tasks |

### Validation Rules

1. `display_id` must be unique per session
2. `statistics.running_tasks` must be <= `statistics.parallel_limit`
3. Sum of statistics must equal total: `queued + running + completed + failed == total_tasks`
4. `active_tasks[].status` must transition in valid order (queued → running → completed/failed)
5. `active_tasks[].expanded` can only be true for running or failed tasks
6. `layout.task_lines` must be >= `display_config.max_visible_tasks`
7. `display_config.refresh_rate` must be > 0.0
8. `active_tasks[].end_time` must be >= `active_tasks[].start_time` if both set
9. No more than `statistics.parallel_limit` tasks can have status "running"

### State Transitions

**Task Status**:
```
queued → running → completed
          ↓
        failed
```

**Display State**:
```
Active display updates (needs_refresh: true)
↓
Render current state
↓
Display refreshed (needs_refresh: false)
↓
Task state changes (needs_refresh: true)
```

### Relationships

- **DISPLAYS** Active Tasks (via `active_tasks`)
- **TRACKS** Subtasks (via `active_tasks[].subtasks`)
- **BUFFERS** Task Output (via `active_tasks[].output_buffer`)
- **CONFIGURES** Display (via `display_config`)
- **MANAGES** Layout (via `layout`)
- **REPORTS** Statistics (via `statistics`)

---

## Relationships Summary

### Entity Relationship Diagram

```
Installation Configuration
  ├─ HAS MANY → Task Executions
  ├─ HAS ONE → Backup
  ├─ GENERATES → Performance Metrics
  └─ CREATES → Log Files

Module Contract
  ├─ DEPENDS ON → Other Modules
  ├─ REQUIRES → System Binaries
  ├─ REQUIRES → System Packages
  ├─ HAS ONE → Test Suite
  └─ USED BY → Installation Configuration

CI/CD Workflow
  ├─ HAS MANY → Stages
  ├─ HAS MANY → Quality Gates
  ├─ EXECUTES IN → Environment
  ├─ PRODUCES → Results
  ├─ MAY LINK TO → GitHub Actions Run
  ├─ GENERATES → Logs
  └─ GENERATES → Artifacts

Performance Metrics
  ├─ MEASURED IN → Environment
  ├─ COMPARED TO → Baseline Metric
  ├─ GENERATED BY → CI/CD Workflow
  └─ INFORMS → Quality Gates

Quality Gate Results
  ├─ EXECUTES WITH → Tool Configuration
  ├─ PRODUCES → Violation Reports
  ├─ GENERATES → Report Files
  ├─ BELONGS TO → CI/CD Workflow
  └─ BLOCKS → Deployment

Task Display State
  ├─ DISPLAYS → Active Tasks
  ├─ TRACKS → Subtasks
  ├─ BUFFERS → Task Output
  ├─ CONFIGURES → Display
  ├─ MANAGES → Layout
  └─ REPORTS → Statistics
```

### Cross-Entity Workflows

1. **Installation Workflow**:
   ```
   Installation Configuration
   → spawns Task Display State
   → executes Module Contracts
   → generates Performance Metrics
   → creates Backup
   → produces Log Files
   ```

2. **CI/CD Workflow**:
   ```
   CI/CD Workflow
   → runs Quality Gate Results
   → generates Performance Metrics
   → produces Artifacts
   → blocks Deployment if gates fail
   ```

3. **Module Execution**:
   ```
   Module Contract
   → validates dependencies
   → runs tests
   → executes in Installation Configuration
   → reports to Task Display State
   ```

---

## Implementation Notes

### Storage

All entities are stored as JSON files for this implementation (constitutional requirement: file-based, no database):

```
~/.config/ghostty-install/
├── installations/
│   └── {installation_id}.json
├── modules/
│   └── {module_id}.contract.json
├── workflows/
│   └── {workflow_id}.json
├── metrics/
│   └── {metric_id}.json
├── quality-gates/
│   └── {gate_id}.json
└── task-displays/
    └── {display_id}.json
```

### Concurrency

Task Display State uses file locking for concurrent updates:
- Lock file: `{display_id}.lock`
- Lock timeout: 5 seconds
- Refresh rate: 100ms (10 updates/second max)

### Performance Considerations

- Metrics are archived after 90 days to prevent excessive file growth
- Quality gate reports are compressed after workflow completion
- Task display buffers are truncated at 10KB per task
- Installation logs rotated at 100MB

### Backward Compatibility

All entities include version fields for schema evolution:
- `contract_version` for Module Contracts
- Schema migrations handled via transformation scripts
- Legacy installations readable via version-specific parsers

---

**Next Steps**:
1. Create contract specifications for new components
2. Implement data model validation functions
3. Generate implementation plan referencing these entities
