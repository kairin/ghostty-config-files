# CLI Interface Contract: Task Archive and Consolidation System

**Feature**: 006-task-archive-consolidation
**Date**: 2025-11-11
**Version**: 1.0.0

## Overview

This contract defines the command-line interfaces for three primary scripts:
1. `archive_spec.sh` - Generate YAML archives for completed specifications
2. `consolidate_todos.sh` - Extract and consolidate outstanding todos
3. `generate_dashboard.sh` - Generate project status dashboard

## 1. archive_spec.sh

### Purpose
Generate concise YAML archives for completed specifications, validate file existence, calculate space savings, and move original directories to archive location.

### Usage
```bash
archive_spec.sh [OPTIONS] [SPEC_ID...]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--all` | Archive all 100% complete specifications | - |
| `--force` | Re-archive even if archive exists | false |
| `--dry-run` | Show what would be archived without making changes | false |
| `--validate-only` | Only validate file existence, don't archive | false |
| `--output-dir DIR` | Archive output directory | `documentations/archive/specifications/` |
| `--keep-original` | Don't move original directory | false |
| `--help` | Show help message | - |
| `--version` | Show version information | - |

### Arguments

- `SPEC_ID`: One or more specification IDs to archive (e.g., `004`, `005`)
- If no SPEC_ID provided and `--all` not specified, show available specifications

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success - all archives generated |
| 1 | General error (invalid arguments, missing dependencies) |
| 2 | Validation error (files missing for marked-complete tasks) |
| 3 | Archive already exists (without --force) |
| 4 | Specification not found |
| 5 | Specification incomplete (<100%) |

### Output

**Standard Output**:
```
🔍 Scanning specifications...
Found 4 specifications (1 complete, 3 incomplete)

📦 Archiving 004-modern-web-development...
  ✅ Validated file existence (15/15 files found)
  ✅ Generated YAML archive (355 lines)
  ✅ Moved original directory to archive
  📊 Space savings: 93% (1,572 → 355 lines)

✅ Archive complete: documentations/archive/specifications/004-modern-web-development.yaml
```

**Standard Error** (validation failures):
```
❌ Validation failed for 002-advanced-terminal-productivity:
  - T004: ~/.config/terminal-ai/providers.conf (MISSING)
  - T005: ~/.config/terminal-ai/setup-keys.sh (MISSING)
  - T006: ~/.oh-my-zsh/custom/plugins/zsh-codex/ (MISSING)

Use --validate-only to see all issues before archiving
```

### Examples

```bash
# Archive specific specification
./archive_spec.sh 004

# Archive all 100% complete specifications
./archive_spec.sh --all

# Dry run to see what would be archived
./archive_spec.sh --all --dry-run

# Validate files without archiving
./archive_spec.sh 002 --validate-only

# Force re-archive existing archive
./archive_spec.sh 004 --force

# Archive to custom location
./archive_spec.sh 005 --output-dir /tmp/archives/
```

### Dependencies

**Required**:
- bash >= 5.0
- grep, awk, sed (coreutils)
- git (for repository operations)

**Optional**:
- `yq` (YAML validation)
- `jq` (JSON processing)

---

## 2. consolidate_todos.sh

### Purpose
Extract all incomplete tasks from active specifications and consolidate into a unified, prioritized implementation checklist.

### Usage
```bash
consolidate_todos.sh [OPTIONS]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--output FILE` | Output checklist file | `IMPLEMENTATION_CHECKLIST.md` |
| `--sort-by FIELD` | Sort by: `spec`, `priority`, `effort`, `phase` | `spec` |
| `--filter-spec SPEC_ID` | Only include tasks from specific spec | - |
| `--filter-priority LEVEL` | Only include specific priority (P1/P2/P3/P4) | - |
| `--show-dependencies` | Include dependency graph visualization | false |
| `--estimate-effort` | Calculate total effort estimates | true |
| `--dry-run` | Show output without writing file | false |
| `--help` | Show help message | - |
| `--version` | Show version information | - |

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success - checklist generated |
| 1 | General error (invalid arguments, missing dependencies) |
| 4 | No incomplete tasks found |
| 6 | Circular dependencies detected (warning, continues) |

### Output

**Standard Output**:
```
🔍 Scanning specifications for incomplete tasks...

📋 Found incomplete tasks:
  - 005-apt-snap-migration: 17 tasks (2-3 days)
  - 001-repo-structure-refactor: 73 tasks (5-7 days)
  - 002-advanced-terminal-productivity: 59 tasks (15-20 days)

📊 Total: 149 tasks, estimated 22-30 days

✅ Checklist generated: IMPLEMENTATION_CHECKLIST.md
```

**Checklist Output** (`IMPLEMENTATION_CHECKLIST.md`):
````markdown
# Implementation Checklist

**Generated**: 2025-11-11 04:25:34
**Total Incomplete Tasks**: 149
**Estimated Effort**: 22-30 days
**Specifications Scanned**: 3 active

## Summary by Specification

| Spec ID | Title | Incomplete | Est. Effort |
|---------|-------|------------|-------------|
| 005 | Apt/Snap Migration | 17 | 2-3 days |
| 001 | Repo Structure Refactor | 73 | 5-7 days |
| 002 | Advanced Terminal Productivity | 59 | 15-20 days |

## Tasks by Specification

### 005-apt-snap-migration (17 tasks, 2-3 days)

**Phase 5: System-Wide Migration** (10 tasks):
- [ ] T054 (P1) Implement batch migration orchestration (4 hours)
- [ ] T055 (P1) Add dependency-safe ordering (2 hours)
...

### 001-repo-structure-refactor (73 tasks, 5-7 days)

**Phase 5: Modular Scripts** (20 tasks):
- [ ] T048 (P3) Extract install_zig.sh module (1 hour)
...
````

### Examples

```bash
# Generate consolidated checklist
./consolidate_todos.sh

# Sort by priority instead of specification
./consolidate_todos.sh --sort-by priority

# Only show P1 tasks
./consolidate_todos.sh --filter-priority P1

# Only tasks from specific spec
./consolidate_todos.sh --filter-spec 005

# Include dependency graph
./consolidate_todos.sh --show-dependencies

# Output to custom file
./consolidate_todos.sh --output /tmp/todos.md

# Preview without writing
./consolidate_todos.sh --dry-run
```

### Dependencies

**Required**:
- bash >= 5.0
- grep, awk, sed (coreutils)

**Optional**:
- `jq` (JSON processing for structured output)

---

## 3. generate_dashboard.sh

### Purpose
Generate comprehensive status dashboard showing completion metrics, remaining work estimates, and archive statistics for all specifications.

### Usage
```bash
generate_dashboard.sh [OPTIONS]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--output FILE` | Output dashboard file | `PROJECT_STATUS_DASHBOARD.md` |
| `--include-archived` | Include archived specs in stats | true |
| `--show-details` | Include per-phase breakdown | false |
| `--format FORMAT` | Output format: `markdown`, `json`, `csv` | `markdown` |
| `--dry-run` | Show output without writing file | false |
| `--help` | Show help message | - |
| `--version` | Show version information | - |

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success - dashboard generated |
| 1 | General error (invalid arguments, missing dependencies) |
| 4 | No specifications found |

### Output

**Standard Output**:
```
🔍 Scanning repository...

📊 Found:
  - 4 specifications total
  - 1 completed (archived)
  - 2 in-progress
  - 1 questionable

💾 Archive statistics:
  - 1 YAML archive
  - Space savings: 93% (1,572 → 355 lines)

✅ Dashboard generated: PROJECT_STATUS_DASHBOARD.md
```

**Dashboard Output** (`PROJECT_STATUS_DASHBOARD.md`):
````markdown
# Project Status Dashboard

**Generated**: 2025-11-11 04:25:34
**Repository**: ghostty-config-files
**Branch**: main

## Summary Metrics

| Metric | Value |
|--------|-------|
| Total Specifications | 4 |
| Overall Completion | 51% (207/404 tasks) |
| Completed Specs | 1/4 (25%) |
| In Progress Specs | 2/4 (50%) |
| Questionable Specs | 1/4 (25%) |
| Estimated Remaining Work | 12-15 days |

## Status Distribution

| Status | Count | Percentage |
|--------|-------|------------|
| ✅ Completed | 1 | 25% |
| 🔄 In Progress | 2 | 50% |
| ⚠️ Questionable | 1 | 25% |
| ❌ Abandoned | 0 | 0% |

## Specification Details

| Spec ID | Title | Status | Progress | Remaining | Est. Effort |
|---------|-------|--------|----------|-----------|-------------|
| 004 | Modern Web Development Stack | ✅ Complete | 69/69 (100%) | 0 tasks | 0 days |
| 005 | Apt/Snap Package Migration | 🔄 In Progress | 53/70 (76%) | 17 tasks | 2-3 days |
| 001 | Repository Structure Refactor | 🔄 In Progress | 23/96 (24%) | 73 tasks | 5-7 days |
| 002 | Advanced Terminal Productivity | ⚠️ Questionable | 13/72 (18%) | 59 tasks | Needs reassessment |

## Archive Statistics

| Metric | Value |
|--------|-------|
| Archived Specifications | 1 |
| Total Original Lines | 1,572 |
| Total Archive Lines | 355 |
| Space Savings | 93% reduction |

## Notes

### 005-apt-snap-migration
- **Status**: Nearly complete (76%)
- **Next Steps**: Complete Phases 5-6 (17 tasks, 2-3 days)
- **Recommendation**: High-quality work, worth completing

### 001-repo-structure-refactor
- **Status**: Infrastructure complete, modules incomplete (45% actual)
- **Next Steps**: Complete Phase 5 module extraction (20 modules)
- **Recommendation**: Either complete Phase 5 (5-7 days) OR archive as "PARTIAL"

### 002-advanced-terminal-productivity
- **Status**: Early stage with inaccurate task markers (18%)
- **Next Steps**: Reassess scope, reduce or abandon
- **Recommendation**: Re-evaluate whether AI integration is needed
````

### Examples

```bash
# Generate status dashboard
./generate_dashboard.sh

# Exclude archived specs from calculations
./generate_dashboard.sh --include-archived=false

# Show per-phase breakdown
./generate_dashboard.sh --show-details

# Output as JSON
./generate_dashboard.sh --format json

# Preview without writing
./generate_dashboard.sh --dry-run

# Custom output location
./generate_dashboard.sh --output docs/status.md
```

### Dependencies

**Required**:
- bash >= 5.0
- grep, awk, sed (coreutils)
- date (for timestamps)

**Optional**:
- `jq` (JSON output format)

---

## Common Conventions

### Error Handling

All scripts follow consistent error handling:
```bash
# Print error to stderr
echo "❌ Error: Description" >&2

# Exit with appropriate code
exit CODE
```

### Progress Output

All scripts use emoji indicators for visual clarity:
- 🔍 Scanning/searching
- ✅ Success/complete
- ❌ Error/failure
- ⚠️ Warning/questionable
- 📦 Archiving
- 📋 Checklist
- 📊 Statistics/metrics
- 💾 Storage/files

### Dry Run Behavior

All scripts support `--dry-run` which:
1. Performs all analysis and validation
2. Shows what would be done
3. Does NOT write any files
4. Does NOT modify the repository

### Help Output Format

```bash
Usage: script_name.sh [OPTIONS] [ARGUMENTS]

Description of what the script does.

Options:
  --option1 VALUE    Description of option1
  --flag             Description of boolean flag
  --help             Show this help message
  --version          Show version information

Examples:
  script_name.sh --option1 value
  script_name.sh --dry-run
```

### Version Output Format

```bash
script_name.sh version 1.0.0
Feature: 006-task-archive-consolidation
```

---

## Contract Validation

Scripts implementing this contract MUST:
- ✅ Accept all specified options
- ✅ Use specified exit codes consistently
- ✅ Output format matches specifications
- ✅ Handle errors gracefully with clear messages
- ✅ Support `--help` and `--version` flags
- ✅ Support `--dry-run` mode
- ✅ Validate inputs before processing
- ✅ Provide progress feedback for long operations

Scripts implementing this contract SHOULD:
- 📊 Use emoji indicators for visual clarity
- 🎨 Use color output when terminal supports it (detect with `tput colors`)
- ⚡ Process specifications in parallel when possible
- 💾 Use atomic file writes (write to temp, then move)
- 🔒 Validate file permissions before writing
- 📝 Log operations to stderr, results to stdout

---

## Contract Version

**Version**: 1.0.0
**Date**: 2025-11-11
**Status**: Active

**Compatibility**: Scripts implementing this contract are compatible with bash 5.x+ on Linux/macOS systems with standard coreutils installed.
