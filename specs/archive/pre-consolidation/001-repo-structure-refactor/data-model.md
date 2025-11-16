# Data Model: Repository Structure Refactoring

**Phase**: Phase 1 - Design
**Feature**: Repository Structure Refactoring (001-repo-structure-refactor)
**Date**: 2025-10-27

## Overview

This document defines the entities (configuration artifacts, scripts, and documentation structures) involved in the repository structure refactoring. These are not database entities but rather file system structures and script modules that form the architecture of the project.

---

## Entity 1: Bash Module

**Purpose**: Represents a single-responsibility bash script that performs one specific sub-task.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
|-----------|------|----------|------------------|-------------|
| module_name | string | Yes | Pattern: `[a-z_]+\.sh` | Module filename (e.g., `install_node.sh`) |
| purpose | string | Yes | Max 100 chars, one sentence | Brief description of module's single responsibility |
| dependencies | array[string] | No | List of system commands | External commands required (e.g., `["curl", "git"]`) |
| modules_required | array[string] | No | References to other modules | Other bash modules this depends on |
| exit_codes | map[int, string] | Yes | Keys: 0-255 | Maps exit codes to meanings (0=success, 1=failure, 2=missing dep) |
| functions | array[Function] | Yes | Min 1 function | Public functions exposed by module |
| test_time | integer | No | <10000 (10 seconds) | Maximum test execution time in milliseconds |
| sourceable | boolean | Yes | Always true | Must support sourcing without side effects |

### Relationships

- **Depends On**: Other Bash Modules (via `modules_required`)
- **Contains**: Multiple Functions (1-3 per module)
- **Tested By**: Unit Test (1:1 relationship)
- **Orchestrated By**: manage.sh (many-to-one)

### State Transitions

```
[Created] → [Validated] → [Tested] → [Integrated] → [Deployed]
    ↓           ↓            ↓            ↓             ↓
[Invalid] ← [Failed] ← [Regression] ← [Deprecated]
```

**Valid Transitions**:
- Created → Validated: ShellCheck passes, syntax valid, dependencies declared
- Validated → Tested: Unit tests written and passing
- Tested → Integrated: Integrated into manage.sh orchestration
- Integrated → Deployed: Merged to main branch
- Any state → Deprecated: Module no longer needed, marked for removal

### Validation Rules

1. **Single Responsibility**: Module must handle exactly one sub-task (e.g., "Install Node.js")
2. **Sourceable**: Must have `BASH_SOURCE` guard to allow sourcing without execution
3. **Fast Testing**: Independent test execution must complete in <10 seconds
4. **Header Complete**: Must include Purpose, Dependencies, Modules Required, Exit Codes
5. **No Circular Deps**: Cannot depend on module that depends on it (transitively)
6. **ShellCheck Clean**: No ShellCheck warnings or errors
7. **Function Documentation**: All non-obvious functions must have header comments

### Example

```json
{
  "module_name": "install_node.sh",
  "purpose": "Install Node.js via NVM to specified version",
  "dependencies": ["curl", "git"],
  "modules_required": [],
  "exit_codes": {
    "0": "success",
    "1": "installation failed",
    "2": "curl not found"
  },
  "functions": [
    {
      "name": "install_node_version",
      "args": ["version (default: lts)"],
      "returns": "0 on success, 1 on failure"
    },
    {
      "name": "validate_node_installation",
      "args": [],
      "returns": "0 if valid, 1 if invalid"
    }
  ],
  "test_time": 4500,
  "sourceable": true
}
```

---

## Entity 2: Documentation Artifact

**Purpose**: Represents a documentation file (source or generated) in the repository.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
|-----------|------|----------|------------------|-------------|
| file_path | string | Yes | Absolute path | Full path to documentation file |
| artifact_type | enum | Yes | `source | generated` | Whether this is editable source or build output |
| format | enum | Yes | `markdown | html | json | mdx` | File format |
| source_location | string | Conditional | Path if artifact_type=generated | Original source file if this is generated |
| build_tool | string | Conditional | Required if artifact_type=generated | Tool that generates this (e.g., "Astro", "pandoc") |
| git_tracked | boolean | Yes | - | Whether file should be committed to git |
| category | enum | Yes | `user-guide | ai-guidelines | developer | api` | Documentation category |
| updated_at | datetime | No | ISO 8601 | Last modification timestamp |

### Relationships

- **Generated From**: Source Artifact (if artifact_type=generated)
- **Organized In**: Documentation Directory (docs-source/ or docs-dist/)
- **References**: Other Documentation Artifacts (via hyperlinks)

### State Transitions

```
[Draft] → [Review] → [Approved] → [Published]
   ↓         ↓           ↓            ↓
[Deprecated] ← [Outdated] ← [Superseded]
```

**Valid Transitions**:
- Draft → Review: Documentation complete and ready for review
- Review → Approved: Technical accuracy verified
- Approved → Published: Built and deployed to docs-dist/
- Published → Outdated: Source changed but build not updated
- Any state → Deprecated: Content no longer relevant

### Validation Rules

1. **Source Separation**: Source artifacts must be in docs-source/, generated in docs-dist/
2. **Git Tracking**: Source artifacts tracked in git, generated artifacts gitignored
3. **Build Verification**: Generated artifacts must have valid source reference
4. **Link Validation**: Internal links must resolve to existing artifacts
5. **Format Consistency**: All user-facing docs must use consistent markdown format

### Example

```json
{
  "file_path": "/home/kkk/Apps/ghostty-config-files/docs-source/user-guide/installation.md",
  "artifact_type": "source",
  "format": "markdown",
  "source_location": null,
  "build_tool": null,
  "git_tracked": true,
  "category": "user-guide",
  "updated_at": "2025-10-27T00:00:00Z"
}
```

```json
{
  "file_path": "/home/kkk/Apps/ghostty-config-files/docs-dist/installation/index.html",
  "artifact_type": "generated",
  "format": "html",
  "source_location": "docs-source/user-guide/installation.md",
  "build_tool": "Astro",
  "git_tracked": false,
  "category": "user-guide",
  "updated_at": "2025-10-27T00:15:30Z"
}
```

---

## Entity 3: Management Command

**Purpose**: Represents a top-level command exposed by manage.sh to users.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
|-----------|------|----------|------------------|-------------|
| command_name | string | Yes | Pattern: `[a-z-]+` | Primary command name (e.g., "install", "validate") |
| subcommands | array[string] | No | - | Optional subcommands (e.g., "docs build", "docs dev") |
| description | string | Yes | Max 200 chars | Brief description for help output |
| modules_invoked | array[string] | Yes | Min 1 module | Bash modules called by this command |
| execution_order | array[string] | Yes | - | Ordered list of module functions to execute |
| estimated_time | integer | No | Seconds | Expected execution duration |
| requires_sudo | boolean | No | Default: false | Whether command needs elevated privileges |
| idempotent | boolean | Yes | - | Whether safe to run multiple times |

### Relationships

- **Invokes**: Bash Modules (many-to-many)
- **Documented In**: Documentation Artifact (help text, quickstart guide)
- **Tested By**: Integration Tests (pytest contract tests)

### State Transitions

```
[Planned] → [Implemented] → [Tested] → [Documented] → [Released]
    ↓          ↓              ↓             ↓             ↓
[Deprecated] ← [Breaking] ← [Failing]
```

**Valid Transitions**:
- Planned → Implemented: Bash modules integrated into manage.sh
- Implemented → Tested: Integration tests pass
- Tested → Documented: Help text and quickstart updated
- Documented → Released: Merged to main branch
- Any state → Deprecated: Command no longer needed

### Validation Rules

1. **Module Availability**: All modules in `modules_invoked` must exist
2. **Dependency Order**: Modules must be sourced in dependency order
3. **Help Text**: Must provide `--help` output with usage examples
4. **Error Handling**: Must handle module failures gracefully
5. **Progress Display**: Must show progress for operations >10 seconds
6. **Idempotency Check**: If idempotent=true, must verify state before executing

### Example

```json
{
  "command_name": "install",
  "subcommands": [],
  "description": "Install complete Ghostty terminal environment",
  "modules_invoked": [
    "install_node.sh",
    "install_zig.sh",
    "build_ghostty.sh",
    "setup_zsh.sh",
    "configure_theme.sh",
    "install_context_menu.sh"
  ],
  "execution_order": [
    "install_node_version",
    "install_zig_compiler",
    "build_ghostty",
    "setup_zsh_environment",
    "configure_theme_catppuccin",
    "install_context_menu_nautilus"
  ],
  "estimated_time": 300,
  "requires_sudo": false,
  "idempotent": true
}
```

---

## Entity 4: Test Suite

**Purpose**: Represents a collection of tests for a bash module or management command.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
|-----------|------|----------|------------------|-------------|
| suite_name | string | Yes | Pattern: `test_[a-z_]+\.sh` | Test file name |
| target_module | string | Yes | Must exist in scripts/ | Module being tested |
| test_type | enum | Yes | `unit | integration | validation` | Type of test |
| test_count | integer | Yes | Min 1 | Number of test cases in suite |
| execution_time | integer | No | <10000 for unit tests | Actual execution time in milliseconds |
| coverage_percentage | float | No | 0.0-100.0 | Code coverage if measured |
| last_run | datetime | No | ISO 8601 | Timestamp of last test execution |
| status | enum | Yes | `passing | failing | skipped` | Current test status |

### Relationships

- **Tests**: Bash Module or Management Command (many-to-one)
- **Executed By**: test-runner-local.sh (orchestrated testing)
- **Reports To**: Performance metrics JSON

### State Transitions

```
[Created] → [Passing] ⇄ [Failing]
              ↓           ↓
          [Skipped] ← [Disabled]
```

**Valid Transitions**:
- Created → Passing: New test written and all cases pass
- Passing ⇄ Failing: Test results change based on code changes
- Passing/Failing → Skipped: Test temporarily disabled (e.g., known issue)
- Any state → Disabled: Test permanently disabled (deprecated module)

### Validation Rules

1. **Performance Target**: Unit tests must complete in <10 seconds
2. **Isolation**: Tests must not interfere with each other (use subshells)
3. **Cleanup**: Must restore system state after execution
4. **Mocking**: External dependencies must be mocked for unit tests
5. **Assertion Coverage**: All public functions must have test cases
6. **CI/CD Integration**: Must be executable by test-runner-local.sh

### Example

```json
{
  "suite_name": "test_install_node.sh",
  "target_module": "install_node.sh",
  "test_type": "unit",
  "test_count": 5,
  "execution_time": 4500,
  "coverage_percentage": 87.5,
  "last_run": "2025-10-27T00:20:15Z",
  "status": "passing"
}
```

---

## Entity 5: Directory Structure

**Purpose**: Represents the organizational hierarchy of the repository.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
|-----------|------|----------|------------------|-------------|
| path | string | Yes | Absolute path | Full directory path |
| structure_type | enum | Yes | `top-level | feature | generated` | Type of directory |
| nesting_level | integer | Yes | 0-2 | Depth from parent directory: 0=parent dir itself, 1=first subdirectory level, 2=second subdirectory level (constitutional limit: maximum 2 levels deep per FR-005) |
| purpose | string | Yes | Max 200 chars | What this directory contains |
| git_tracked | boolean | Yes | - | Whether contents should be in git |
| protected | boolean | Yes | - | Whether can be modified during refactoring |

### Relationships

- **Contains**: Bash Modules, Documentation Artifacts, or other Directories
- **Part Of**: Parent Directory (tree structure)
- **Specified By**: Constitutional requirements (CLAUDE.md)

### Validation Rules

1. **Nesting Limit**: Maximum 2 levels deep from repository root
2. **Top-Level Count**: Maximum 4-5 top-level directories
3. **Protected Preservation**: Protected directories (spec-kit/, .runners-local/, .specify/) never modified
4. **Git Tracking**: Generated directories (docs-dist/) must be gitignored
5. **Purpose Clarity**: Each directory must have single, clear purpose

### Example

```json
{
  "path": "/home/kkk/Apps/ghostty-config-files/scripts",
  "structure_type": "top-level",
  "nesting_level": 1,
  "purpose": "Contains all modular bash scripts for system automation",
  "git_tracked": true,
  "protected": false
}
```

```json
{
  "path": "/home/kkk/Apps/ghostty-config-files/docs-dist",
  "structure_type": "generated",
  "nesting_level": 1,
  "purpose": "Astro build output for GitHub Pages deployment",
  "git_tracked": false,
  "protected": false
}
```

---

## Entity Relationships Diagram

```
                         ┌─────────────────┐
                         │   manage.sh     │
                         │  (Orchestrator) │
                         └────────┬────────┘
                                  │ invokes
                                  ▼
                    ┌─────────────────────────┐
                    │  Management Command     │
                    │  (install, docs, etc.)  │
                    └─────────┬───────────────┘
                              │ executes
                              ▼
                    ┌─────────────────┐
            ┌───────│   Bash Module   │───────┐
            │       │ (install_node)  │       │
            │       └─────────────────┘       │
            │                                  │
        contains                           tested by
            │                                  │
            ▼                                  ▼
    ┌───────────────┐                ┌──────────────┐
    │   Function    │                │  Test Suite  │
    │ (public API)  │                │  (unit tests)│
    └───────────────┘                └──────────────┘

    ┌──────────────────┐             ┌──────────────────┐
    │ Documentation    │  generated  │ Documentation    │
    │ Artifact (source)│ ───────────>│ Artifact (built) │
    └──────────────────┘             └──────────────────┘
            │                                  │
         stored in                         stored in
            │                                  │
            ▼                                  ▼
    ┌──────────────┐                  ┌──────────────┐
    │docs-source/  │                  │ docs-dist/   │
    │ (git tracked)│                  │ (gitignored) │
    └──────────────┘                  └──────────────┘
```

---

## Key Design Principles

### 1. Single Responsibility
Each Bash Module handles exactly one sub-task. No modules with multiple unrelated responsibilities.

### 2. Dependency Transparency
All dependencies (system commands, other modules) declared explicitly in module headers.

### 3. Testability First
All modules designed with `BASH_SOURCE` guards to enable sourcing and testing without execution.

### 4. Constitutional Compliance
- Maximum 2 levels of nesting in directory structures
- Zero GitHub Actions consumption (all testing local)
- Branch preservation (no automatic deletion)
- Documentation source/build separation

### 5. Fail Fast, Recover Gracefully
Modules return meaningful exit codes, orchestrator handles errors and provides rollback.

### 6. Progress Visibility
All long-running operations (>10s) provide progress feedback to users.

---

## Migration Impact

### Entities Created
- **10-15 Bash Modules**: New modular scripts in scripts/
- **2 Directory Structures**: docs-source/ and docs-dist/
- **5-7 Management Commands**: Unified interface via manage.sh
- **10-15 Test Suites**: Unit tests for each module
- **10-15 Documentation Artifacts**: Modularized AI guidelines and user docs

### Entities Modified
- **start.sh**: Becomes wrapper calling manage.sh
- **README.md**: Updated to reference manage.sh commands
- **CLAUDE.md**: Updated with new structure documentation
- **.gitignore**: Add docs-dist/ to exclusions

### Entities Preserved
- **All existing scripts/**: Current scripts remain functional
- **configs/**: No changes to Ghostty configuration
- **spec-kit/**: Preserved unchanged (constitutional requirement)
- **.runners-local/**: Preserved unchanged (constitutional requirement)
- **.specify/**: Preserved unchanged (constitutional requirement)

---

## Validation Queries

These queries would validate the data model in a real implementation:

```sql
-- Check for circular dependencies in bash modules
WITH RECURSIVE module_deps AS (
  SELECT module_name, modules_required FROM bash_modules
  UNION ALL
  SELECT md.module_name, bm.modules_required
  FROM module_deps md
  JOIN bash_modules bm ON bm.module_name = ANY(md.modules_required)
)
SELECT DISTINCT module_name
FROM module_deps
WHERE module_name = ANY(modules_required);
-- Should return 0 rows (no circular dependencies)

-- Verify all management commands have valid modules
SELECT mc.command_name, m.module_name
FROM management_commands mc
CROSS JOIN UNNEST(mc.modules_invoked) AS m(module_name)
LEFT JOIN bash_modules bm ON bm.module_name = m.module_name
WHERE bm.module_name IS NULL;
-- Should return 0 rows (all modules exist)

-- Check nesting depth violations
SELECT path, nesting_level
FROM directory_structures
WHERE nesting_level > 2;
-- Should return 0 rows (constitutional limit: 2 levels)

-- Verify test performance targets
SELECT suite_name, execution_time
FROM test_suites
WHERE test_type = 'unit' AND execution_time > 10000;
-- Should return 0 rows (all unit tests <10s)
```

---

## Appendix: Entity Counts

| Entity Type | Current (Before) | Target (After) | Change |
|-------------|------------------|----------------|--------|
| Bash Modules | 5 (existing scripts) | 15-20 (modularized) | +10-15 |
| Documentation Artifacts (source) | ~10 (mixed in docs/) | ~20 (separated in docs-source/) | +10 |
| Documentation Artifacts (generated) | ~100 (HTML files in docs/) | ~100 (moved to docs-dist/) | ±0 |
| Management Commands | 1 (start.sh) | 5-7 (manage.sh subcommands) | +4-6 |
| Test Suites | 2 (contract tests) | 15-17 (unit + integration) | +13-15 |
| Directory Structures (top-level) | 8 | 9 (+docs-source/) | +1 |

**Total Complexity**: Moderate increase in file count (modularization), significant increase in testability and maintainability.
