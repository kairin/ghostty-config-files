# Implementation Plan: Task Archive and Consolidation System

**Branch**: `20251111-042534-feat-task-archive-consolidation` | **Date**: 2025-11-11 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/home/kkk/Apps/ghostty-config-files/specs/20251111-042534-feat-task-archive-consolidation/spec.md`

## Summary

Primary requirement: Create a comprehensive system to consolidate completed specification tasks into concise YAML archives (>90% size reduction), extract all outstanding todos into a unified implementation checklist, and generate a status dashboard for evaluating application development progress across all specifications.

Technical approach: File-based analysis and transformation system using bash scripting for spec scanning, YAML generation for archives, and markdown generation for consolidated checklists and dashboards. Leverages existing YAML archive schema established in initial implementation (004-modern-web-development.yaml).

## Technical Context

**Language/Version**: Bash 5.x+ (primary scripting), YAML 1.2 (archive format), Markdown (checklists/dashboards)
**Primary Dependencies**: bash, yq/jq (YAML/JSON processing), grep/awk/sed (text processing), git (repository operations)
**Storage**: File-based YAML archives, markdown checklists, specification directories (tasks.md files)
**Testing**: Local validation scripts, file existence checks, YAML schema validation, constitutional compliance verification
**Target Platform**: Linux/macOS development environments with git repositories
**Project Type**: cli-tool - Command-line automation for documentation management
**Performance Goals**: Archive generation <30 seconds per spec, checklist consolidation <10 seconds, dashboard updates <10 seconds
**Constraints**: Must preserve original specification files, validate file existence before archiving, maintain constitutional compliance
**Scale/Scope**: Single repository with 5-10 specifications, 50-100 tasks per spec, multi-user development team context

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

✅ **I. Branch Preservation & Git Strategy**: Compliant - Archives preserve original specs, no branch deletion
✅ **II. GitHub Pages Infrastructure Protection**: Compliant - No .nojekyll impact, documentation-only changes
✅ **III. Local CI/CD First (MANDATORY)**: Compliant - All operations are local file transformations
✅ **IV. Agent File Integrity**: Compliant - No AGENTS.md modifications
✅ **V. LLM Conversation Logging**: Compliant - Archival process documents decisions
✅ **VI. Zero-Cost Operations**: Compliant - No GitHub Actions, purely local operations

**Result**: PASS - All constitutional principles satisfied, no violations detected

## Project Structure

### Documentation (this feature)
```
specs/20251111-042534-feat-task-archive-consolidation/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
/home/kkk/Apps/ghostty-config-files/
├── scripts/
│   ├── archive_spec.sh              # Archive generation script
│   ├── consolidate_todos.sh         # Todo consolidation script
│   └── generate_dashboard.sh       # Status dashboard generator
├── documentations/
│   ├── archive/
│   │   └── specifications/          # YAML archives + original directories
│   │       ├── 004-modern-web-development.yaml
│   │       ├── 004-modern-web-development-original/
│   │       └── [other archives]
│   └── specifications/              # Active specifications
│       ├── 001-repo-structure-refactor/
│       ├── 002-advanced-terminal-productivity/
│       └── 005-apt-snap-migration/
├── IMPLEMENTATION_CHECKLIST.md      # Consolidated todos output
└── PROJECT_STATUS_DASHBOARD.md      # Status dashboard output
```

## Phase 0: Research & Architecture Decisions

### Research Tasks

1. **YAML Processing in Bash**:
   - **Decision**: Use `yq` (YAML processor) with fallback to manual bash parsing
   - **Rationale**: `yq` provides robust YAML validation and formatting, bash parsing allows portability
   - **Alternatives considered**: Python scripts (adds dependency), jq for JSON (requires conversion)

2. **Archive Schema Validation**:
   - **Decision**: Use existing 004-modern-web-development.yaml as schema template
   - **Rationale**: Already proven format with ~93% size reduction, includes all necessary sections
   - **Alternatives considered**: Custom schema definition (over-engineering), JSON format (less human-readable)

3. **Task Extraction Strategy**:
   - **Decision**: Parse tasks.md files using grep/awk for checkbox markers `- [x]` and `- [ ]`
   - **Rationale**: Consistent format across all specs, reliable pattern matching, no external dependencies
   - **Alternatives considered**: Markdown parser libraries (heavyweight), regex in Python (adds dependency)

4. **File Existence Validation**:
   - **Decision**: Extract file paths from task descriptions, test with `[ -f path ]` or `[ -d path ]`
   - **Rationale**: Direct filesystem checks, catches discrepancies immediately
   - **Alternatives considered**: Git ls-files (misses uncommitted files), static path lists (maintenance burden)

5. **Dependency Graph Visualization**:
   - **Decision**: Text-based dependency lists in markdown with indentation for hierarchy
   - **Rationale**: Simple to generate, renders well in any viewer, no graphviz dependency
   - **Alternatives considered**: Graphviz DOT format (requires installation), Mermaid diagrams (render complexity)

6. **Status Dashboard Format**:
   - **Decision**: Markdown tables with badges/emojis for visual status indicators
   - **Rationale**: GitHub-flavored markdown renders beautifully, supports sorting, copy-pasteable
   - **Alternatives considered**: HTML dashboard (overkill), JSON output (not human-friendly), CSV (limited formatting)

7. **Archive Organization Strategy**:
   - **Decision**: Move original spec directory to `[spec-id]-original/`, place YAML archive at `[spec-id].yaml`
   - **Rationale**: Preserves complete history, clear naming convention, easy navigation
   - **Alternatives considered**: Delete originals (violates preservation principle), zip compression (less accessible)

**Output**: research.md with all technical decisions documented

## Phase 1: Design & Contracts

### Data Model

See [data-model.md](data-model.md) for complete entity definitions.

**Key Entities**:
- **SpecificationArchive**: Complete history in YAML format
- **TaskItem**: Individual todo with metadata
- **ConsolidatedChecklist**: Unified task list across specs
- **StatusMetrics**: Completion and effort statistics
- **DashboardView**: Rendered status overview

### Contracts

See [contracts/](contracts/) directory for complete interface definitions.

**Primary Interfaces**:
- **CLI Contract**: `archive_spec.sh`, `consolidate_todos.sh`, `generate_dashboard.sh` command-line interfaces
- **YAML Schema**: Archive format specification
- **Markdown Format**: Checklist and dashboard output formats

### Quickstart Guide

See [quickstart.md](quickstart.md) for implementation scenarios and workflow examples.

## Phase 2: Task Generation Strategy

**Task generation will be handled by the `/tasks` command** based on this plan.

### Task Categories

1. **Archive Generation** (User Story 1, Priority P1):
   - Scan specifications for 100% completion
   - Validate file existence for marked-complete tasks
   - Generate YAML archives from spec.md, plan.md, tasks.md
   - Calculate space savings metrics
   - Move original directories to archive location

2. **Todo Consolidation** (User Story 2, Priority P2):
   - Parse all tasks.md files for incomplete tasks `- [ ]`
   - Extract task metadata (ID, phase, description)
   - Detect dependency relationships from task descriptions
   - Generate unified checklist with priority sorting
   - Support checklist updates propagating to source files

3. **Status Dashboard** (User Story 3, Priority P3):
   - Calculate completion percentages across all specs
   - Aggregate remaining effort estimates
   - Generate markdown tables with status indicators
   - Separate archived vs. active work sections
   - Support real-time updates on spec changes

### Parallel Execution Strategy

- Archive generation tasks can run in parallel (different specs)
- Todo extraction can run concurrently per specification
- Dashboard generation requires consolidated data (sequential after consolidation)

### Dependency Order

```
Phase 1: Validation & Setup
  ├─ Verify yq/jq installation
  ├─ Create archive directory structure
  └─ Load YAML schema template

Phase 2: Archive Generation (US1 - P1)
  ├─ Scan for 100% complete specs
  ├─ Validate file existence
  ├─ Generate YAML archives
  └─ Move original directories

Phase 3: Todo Consolidation (US2 - P2)
  ├─ Parse all tasks.md files
  ├─ Extract incomplete tasks
  ├─ Detect dependencies
  └─ Generate unified checklist

Phase 4: Dashboard Generation (US3 - P3)
  ├─ Aggregate metrics from all specs
  ├─ Calculate remaining effort
  └─ Generate markdown dashboard

Phase 5: Integration & Validation
  ├─ Verify constitutional compliance
  ├─ Test archive accessibility
  └─ Validate checklist accuracy
```

## Constitutional Compliance Re-Check

After Phase 1 design, re-validating constitutional principles:

✅ **Branch Preservation**: Archive strategy explicitly preserves original directories
✅ **Local CI/CD**: All operations are local bash scripts, no GitHub Actions
✅ **Zero-Cost**: No external services, purely filesystem operations
✅ **Agent Integrity**: No modifications to AGENTS.md or symlinks
✅ **Documentation**: Archival process itself serves as conversation log

**Result**: PASS - Design maintains constitutional compliance

## Next Steps

1. **Complete Phase 0**: Finalize research.md with technical decisions (DONE above)
2. **Complete Phase 1**: Create data-model.md, contracts/, quickstart.md (NEXT)
3. **Run /tasks**: Generate tasks.md with implementation task list
4. **Run /implement**: Execute implementation based on tasks

**Ready for**: Phase 1 artifact generation

---

**Note**: This plan stops here per spec-kit workflow. Run `/tasks` command to generate the implementation task list.
