# Data Model: Task Archive and Consolidation System

**Feature**: 006-task-archive-consolidation
**Date**: 2025-11-11

## Entity Definitions

### 1. Specification

Represents a feature specification with associated implementation artifacts.

**Attributes**:
- `id` (string): Unique identifier (e.g., "004-modern-web-development")
- `title` (string): Human-readable feature name
- `branch_name` (string): Git branch for this feature
- `status` (enum): One of ["completed", "in-progress", "questionable", "abandoned"]
- `completion_percentage` (integer): 0-100, calculated from tasks
- `total_tasks` (integer): Total number of tasks in tasks.md
- `completed_tasks` (integer): Number of tasks marked [x]
- `directory_path` (string): Absolute path to spec directory

**Relationships**:
- Has many `TaskItem` (via tasks.md file)
- Has one `SpecificationArchive` (after archiving)
- Contributes to `StatusDashboard` metrics

**Validation Rules**:
- ID must match directory name pattern: `NNN-feature-name` or `YYYYMMDD-HHMMSS-type-name`
- Completion percentage must be 0-100
- completed_tasks <= total_tasks
- Status "completed" requires completion_percentage = 100

**State Transitions**:
```
[Created] → [in-progress] → [completed] → [archived]
                ↓
          [questionable] → [abandoned]
```

---

### 2. TaskItem

Represents an individual todo item from a tasks.md file.

**Attributes**:
- `id` (string): Task identifier (e.g., "T001", "T047")
- `description` (string): Full task description
- `specification_id` (string): Foreign key to parent Specification
- `phase` (string): Phase name (e.g., "Phase 1: Setup")
- `priority` (enum): One of ["P1", "P2", "P3", "P4"]
- `completed` (boolean): True if marked [x], false if [ ]
- `parallel_allowed` (boolean): True if marked [P] for parallel execution
- `user_story` (string): User story label (e.g., "US1", "US2")
- `estimated_effort` (string): Effort estimate (e.g., "2-3 hours", "1 day")
- `dependencies` (array): List of task IDs this depends on
- `blocks` (array): List of task IDs blocked by this task
- `file_paths` (array): File paths mentioned in description
- `file_validation_status` (enum): One of ["not-checked", "valid", "missing-files"]

**Relationships**:
- Belongs to one `Specification`
- May depend on other `TaskItem` instances
- Appears in `ConsolidatedChecklist` if incomplete

**Validation Rules**:
- ID must match pattern: `T[0-9]{3}` (T001-T999)
- If completed=true, file_paths should be validated
- Dependencies must reference valid task IDs
- Circular dependencies should be flagged

**Extraction Pattern**:
```
Input line: "- [x] T047 [P] [US3] Create install_node.sh module (2 hours)"

Parsed:
- id: "T047"
- completed: true
- parallel_allowed: true
- user_story: "US3"
- description: "Create install_node.sh module"
- estimated_effort: "2 hours"
```

---

### 3. SpecificationArchive

YAML document representing a complete archived specification.

**Attributes**:
- `feature_id` (string): Specification ID
- `title` (string): Feature title
- `status` (enum): One of ["completed", "in-progress", "questionable", "abandoned"]
- `completion_date` (date): When feature was completed (null if incomplete)
- `completion_percentage` (integer): 0-100
- `original_spec_location` (string): Path to original spec directory
- `summary` (text): Brief feature summary with current status
- `requirements` (object): Functional and non-functional requirements with evidence
- `implementation` (object): Architecture, key files, phases
- `tasks` (object): Total, completed, key tasks, remaining tasks
- `outcomes` (object): Deliverables, metrics, artifacts
- `lessons_learned` (object): Successes, challenges, recommendations
- `constitutional_compliance` (object): Compliance verification flags
- `archive_metadata` (object): Archive date, reason, status marker

**Relationships**:
- Corresponds to one `Specification` (archived version)
- Generated from spec.md, plan.md, tasks.md files

**Validation Rules**:
- Must follow YAML 1.2 schema
- Required fields: feature_id, title, status, completion_percentage
- If status="completed", completion_percentage must be 100
- requirements.functional must have at least 1 entry
- All file paths in implementation.key_files should be relative or absolute consistently

**Schema Reference**: Based on `/tmp/004-modern-web-development.yaml`

---

### 4. ConsolidatedChecklist

Unified todo list aggregating all incomplete tasks across specifications.

**Attributes**:
- `generation_date` (datetime): When checklist was generated
- `total_specifications` (integer): Number of specs scanned
- `total_incomplete_tasks` (integer): Total tasks with [ ] marker
- `estimated_total_effort` (string): Aggregated effort estimate (e.g., "15-20 days")
- `tasks_by_specification` (array): Grouped incomplete tasks
- `tasks_by_priority` (array): Priority-sorted task list
- `tasks_by_effort` (array): Effort-sorted task list
- `dependency_warnings` (array): Circular dependency alerts

**Relationships**:
- Aggregates multiple `TaskItem` instances (incomplete only)
- Sources from multiple `Specification` instances

**Generation Logic**:
```bash
1. Scan all specifications
2. Extract incomplete tasks (- [ ])
3. Group by specification
4. Sort by priority within groups
5. Calculate aggregate metrics
6. Detect dependency issues
7. Generate markdown output
```

**Output Format** (Markdown):
```markdown
# Implementation Checklist

**Generated**: 2025-11-11 04:25:34
**Total Incomplete Tasks**: 149
**Estimated Effort**: 15-20 days

## By Specification

### 005-apt-snap-migration (17 tasks remaining, 2-3 days)
- [ ] T054 (P1) Implement batch migration orchestration (4 hours)
- [ ] T055 (P1) Add dependency-safe ordering (2 hours)
...

### 001-repo-structure-refactor (73 tasks remaining, 5-7 days)
- [ ] T048 (P3) Extract install_zig.sh module (1 hour)
...
```

---

### 5. StatusDashboard

Comprehensive view of repository health and progress metrics.

**Attributes**:
- `generation_date` (datetime): When dashboard was generated
- `total_specifications` (integer): All specs in repository
- `overall_completion_percentage` (integer): Weighted average across all specs
- `completed_specifications` (integer): Count with 100% completion
- `in_progress_specifications` (integer): Count with 1-99% completion
- `questionable_specifications` (integer): Count needing reassessment
- `total_tasks_overall` (integer): Sum of all tasks
- `total_completed_overall` (integer): Sum of completed tasks
- `estimated_remaining_effort` (string): Total work left (e.g., "12-15 days")
- `archive_statistics` (object): Archive count, space savings
- `specification_details` (array): Per-spec metrics

**Relationships**:
- Aggregates metrics from all `Specification` instances
- Includes `SpecificationArchive` statistics

**Generation Logic**:
```bash
1. Scan all active specifications
2. Scan archived specifications
3. Calculate aggregate metrics
4. Compute weighted averages
5. Generate summary statistics
6. Create markdown tables
7. Add status indicators (✅🔄⚠️❌)
```

**Output Format** (Markdown):
```markdown
# Project Status Dashboard

**Generated**: 2025-11-11 04:25:34

## Summary
- Total Specifications: 4
- Overall Completion: 51% (207/404 tasks)
- Estimated Remaining: 12-15 days

## Status Distribution
- ✅ Completed: 1/4 (25%)
- 🔄 In Progress: 2/4 (50%)
- ⚠️ Questionable: 1/4 (25%)

## Detailed Status
| Spec | Title | Status | Progress | Remaining | Effort |
|------|-------|--------|----------|-----------|--------|
| 004 | Modern Web Dev | ✅ | 69/69 (100%) | 0 | 0 days |
...
```

---

### 6. TaskMetadata

Extracted metadata about a task for analysis and reporting.

**Attributes**:
- `task_id` (string): Task identifier
- `specification_id` (string): Parent specification
- `phase_name` (string): Phase this task belongs to
- `phase_number` (integer): Numeric phase identifier
- `priority_level` (string): Priority (P1-P4)
- `user_story_label` (string): User story reference
- `parallel_execution` (boolean): Can run in parallel
- `estimated_hours` (float): Effort in hours (null if not specified)
- `file_references` (array): Files mentioned in description
- `dependency_ids` (array): Tasks this depends on
- `blocking_ids` (array): Tasks this blocks
- `validation_result` (object): File existence check results

**Relationships**:
- Extracted from `TaskItem`
- Used by `ConsolidatedChecklist` and `StatusDashboard`

**Usage**: Intermediate data structure for analysis and aggregation

---

## Entity Relationships Diagram (Text)

```
Specification
  ├─ has many TaskItem
  │    ├─ depends on TaskItem (dependency)
  │    └─ blocks TaskItem (inverse dependency)
  ├─ generates SpecificationArchive (when complete)
  └─ contributes to StatusDashboard (metrics)

ConsolidatedChecklist
  └─ aggregates TaskItem (incomplete only)

StatusDashboard
  ├─ aggregates Specification (all)
  └─ includes SpecificationArchive (statistics)

TaskMetadata
  └─ extracted from TaskItem (for analysis)
```

---

## File Storage Mapping

**Specification**:
- Source: `documentations/specifications/[spec-id]/` or `specs/[spec-id]/`
- Files: `spec.md`, `plan.md`, `tasks.md`, etc.

**TaskItem**:
- Source: `tasks.md` files (markdown list format)
- Parsed at runtime, not persisted separately

**SpecificationArchive**:
- Output: `documentations/archive/specifications/[spec-id].yaml`
- Original: `documentations/archive/specifications/[spec-id]-original/`

**ConsolidatedChecklist**:
- Output: `IMPLEMENTATION_CHECKLIST.md` (repository root)

**StatusDashboard**:
- Output: `PROJECT_STATUS_DASHBOARD.md` (repository root)

**TaskMetadata**:
- Runtime only, not persisted to disk

---

## Data Validation Summary

**Specification**:
- ✅ ID format matches directory name
- ✅ Completion percentage in 0-100 range
- ✅ completed_tasks ≤ total_tasks
- ✅ Status="completed" requires 100% completion

**TaskItem**:
- ✅ ID matches T[0-9]{3} pattern
- ✅ File paths exist if task marked complete
- ✅ Dependencies reference valid task IDs
- ⚠️ Circular dependencies flagged as warnings

**SpecificationArchive**:
- ✅ Valid YAML 1.2 syntax
- ✅ Required fields present
- ✅ Status matches completion percentage
- ✅ At least 1 functional requirement

**ConsolidatedChecklist**:
- ✅ Only includes incomplete tasks ([ ])
- ✅ All tasks link back to valid specifications
- ✅ Dependency graph detects cycles

**StatusDashboard**:
- ✅ Metrics sum correctly across specifications
- ✅ Percentages calculated accurately
- ✅ Archive statistics match actual archive count

---

## Data Model Complete

All entities defined with attributes, relationships, validation rules, and file mappings. Ready for contract definitions and implementation.
