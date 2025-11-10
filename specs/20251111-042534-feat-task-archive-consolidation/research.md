# Research: Task Archive and Consolidation System

**Feature**: 006-task-archive-consolidation
**Date**: 2025-11-11
**Status**: Complete

## Research Questions & Decisions

### 1. YAML Processing in Bash

**Question**: How to generate and validate YAML archives from bash scripts?

**Options Evaluated**:
- **Option A**: `yq` (YAML processor CLI tool)
  - Pros: Robust YAML validation, formatting, query support
  - Cons: External dependency, installation required

- **Option B**: Manual bash string manipulation
  - Pros: No dependencies, portable
  - Cons: Error-prone, no validation, maintenance burden

- **Option C**: Python/Ruby YAML libraries
  - Pros: Full language features, extensive libraries
  - Cons: Adds language dependency, over-engineered for simple transformation

**Decision**: **Hybrid approach - `yq` with bash fallback**

**Rationale**:
- Check for `yq` installation at runtime
- Use `yq` for validation and formatting if available
- Fall back to bash string templates for basic generation
- Prioritize reliability and maintainability over minimal dependencies

**Implementation Notes**:
- Detect `yq` with: `command -v yq`
- Use template-based generation with variable substitution
- Validate output with `yq eval` if available

---

### 2. Archive Schema Definition

**Question**: What schema should YAML archives follow?

**Options Evaluated**:
- **Option A**: Custom minimal schema
  - Pros: Lean, only essential fields
  - Cons: May miss important context, requires design time

- **Option B**: Extend existing 004-modern-web-development.yaml format
  - Pros: Already proven (93% size reduction), comprehensive
  - Cons: May include unused fields for some specs

- **Option C**: JSON Schema with YAML serialization
  - Pros: Formal validation, tooling support
  - Cons: Over-engineered, adds complexity

**Decision**: **Use existing 004-modern-web-development.yaml as template**

**Rationale**:
- Format already proven to preserve all critical information
- Achieved >90% size reduction target
- Includes all necessary sections: requirements, implementation, tasks, outcomes, lessons learned
- No need to reinvent - build on working solution

**Schema Structure** (from 004-modern-web-development.yaml):
```yaml
feature_id: "NNN-feature-name"
title: "Feature Title"
status: "completed" | "in-progress" | "questionable" | "abandoned"
completion_percentage: 0-100
requirements:
  functional: [...]
  non_functional: [...]
implementation:
  key_files: [...]
  phases: [...]
tasks:
  total: N
  completed: N
  key_tasks_completed: [...]
  key_tasks_remaining: [...]
outcomes:
  deliverables: [...]
  metrics: [...]
lessons_learned:
  successes: [...]
  challenges: [...]
  recommendations: [...]
```

---

### 3. Task Extraction Strategy

**Question**: How to reliably parse tasks from tasks.md files?

**Options Evaluated**:
- **Option A**: Regex-based grep/awk extraction
  - Pros: Fast, no dependencies, reliable for consistent format
  - Cons: Fragile if format changes

- **Option B**: Markdown parser library (e.g., `markdown-cli`)
  - Pros: Structured parsing, handles variations
  - Cons: External dependency, overkill for simple lists

- **Option C**: Custom parser in Python/Ruby
  - Pros: Full control, can handle complex cases
  - Cons: Adds language dependency, maintenance burden

**Decision**: **grep/awk pattern matching with format validation**

**Rationale**:
- tasks.md format is consistent: `- [x]` (complete), `- [ ]` (incomplete)
- Pattern matching is reliable for this use case
- Fast execution (<1 second for 100+ tasks)
- No external dependencies beyond coreutils

**Extraction Patterns**:
```bash
# Count total tasks
grep -cE '^\- \[[x ]\]' tasks.md

# Count completed tasks
grep -cE '^\- \[x\]' tasks.md

# Extract incomplete tasks with line numbers
grep -nE '^\- \[ \]' tasks.md

# Extract task ID (e.g., T001)
grep -oE 'T[0-9]{3}'

# Extract phase information
grep -B5 '^\- \[' tasks.md | grep '^## Phase'
```

---

### 4. File Existence Validation

**Question**: How to validate that files mentioned in completed tasks actually exist?

**Options Evaluated**:
- **Option A**: Extract paths from task descriptions, test with `[ -f path ]`
  - Pros: Direct validation, catches discrepancies immediately
  - Cons: Path extraction may be imperfect

- **Option B**: Git ls-files to list tracked files
  - Pros: Authoritative list of repository files
  - Cons: Misses uncommitted files, slower

- **Option C**: Skip validation, trust task markers
  - Pros: Simple, fast
  - Cons: Doesn't catch inaccurate markers (like 002 had)

**Decision**: **Extract paths and validate with filesystem checks**

**Rationale**:
- Directly addresses the problem discovered in 002 (11 tasks marked complete with missing files)
- Fast execution (filesystem stat calls)
- Provides immediate feedback on discrepancies

**Path Extraction Strategy**:
```bash
# Common patterns in task descriptions
grep -oE '(scripts|configs|tests|docs|local-infra)/[^ ,]+\.(sh|md|json|yaml|conf)' tasks.md
grep -oE '~/\.[a-z]+/[^ ,]+' tasks.md
```

**Validation Logic**:
```bash
while IFS= read -r path; do
  if [ -f "$path" ] || [ -d "$path" ]; then
    echo "✅ $path"
  else
    echo "❌ $path (MISSING)"
    validation_failed=true
  fi
done < extracted_paths.txt
```

---

### 5. Dependency Graph Visualization

**Question**: How to visualize task dependencies in consolidated checklist?

**Options Evaluated**:
- **Option A**: Text-based indented lists
  - Pros: Simple, renders everywhere, no dependencies
  - Cons: Limited for complex graphs

- **Option B**: Graphviz DOT format
  - Pros: Professional visualization, automatic layout
  - Cons: Requires Graphviz installation, not inline-readable

- **Option C**: Mermaid diagram syntax
  - Pros: Renders in GitHub markdown, declarative
  - Cons: Requires rendering support, complex to generate

**Decision**: **Text-based hierarchical lists with dependency annotations**

**Rationale**:
- Most tasks have simple linear or tree-like dependencies
- Markdown-native format works everywhere
- Easy to generate with bash
- Circular dependencies can be flagged with warnings

**Format Example**:
```markdown
## Task Dependencies

### 001-repo-structure-refactor
- T047: Extract install_node.sh module
  - Depends on: T001-T016 (templates and utilities)
- T048: Extract install_zig.sh module
  - Depends on: T047 (Node.js must be available first)
  - Blocks: T049 (Ghostty build needs Zig)

⚠️ Circular dependency detected: T063 ↔ T064
```

---

### 6. Status Dashboard Format

**Question**: What format should the status dashboard use?

**Options Evaluated**:
- **Option A**: Markdown tables with emojis
  - Pros: GitHub-native, sortable, copy-pasteable
  - Cons: Limited interactivity

- **Option B**: HTML dashboard with JavaScript
  - Pros: Interactive, charts, filtering
  - Cons: Requires build step, not viewable in terminal

- **Option C**: JSON output for external tools
  - Pros: Machine-readable, flexible consumption
  - Cons: Not human-friendly, requires viewer

**Decision**: **Markdown tables with status emojis and summary metrics**

**Rationale**:
- Aligns with repository's markdown-centric approach
- Renders beautifully in GitHub
- Viewable in any text editor
- Supports basic sorting (copy to spreadsheet if needed)

**Dashboard Structure**:
```markdown
# Project Status Dashboard

**Generated**: 2025-11-11 04:25:34
**Total Specifications**: 4
**Completion**: 51% overall (207/404 tasks)

## Summary Metrics

| Metric | Value |
|--------|-------|
| Completed Specs | 1/4 (25%) |
| In Progress Specs | 2/4 (50%) |
| Questionable Specs | 1/4 (25%) |
| Total Remaining Work | ~12-15 days |

## Specification Status

| Spec ID | Title | Status | Complete | Remaining | Est. Effort |
|---------|-------|--------|----------|-----------|-------------|
| 004 | Modern Web Development | ✅ Complete | 69/69 (100%) | 0 tasks | 0 days |
| 005 | Apt/Snap Migration | 🔄 In Progress | 53/70 (76%) | 17 tasks | 2-3 days |
| 001 | Repo Structure Refactor | 🔄 In Progress | 23/96 (24%) | 73 tasks | 5-7 days |
| 002 | Advanced Terminal Productivity | ⚠️ Questionable | 13/72 (18%) | 59 tasks | See notes |
```

---

### 7. Archive Organization Strategy

**Question**: How to organize archived specifications while preserving originals?

**Options Evaluated**:
- **Option A**: Move originals to `[spec-id]-original/`, place YAML at `[spec-id].yaml`
  - Pros: Clear naming, preserves everything, easy navigation
  - Cons: Slightly verbose

- **Option B**: Delete originals, keep only YAML
  - Pros: Maximum space savings
  - Cons: Violates constitutional preservation principle

- **Option C**: Zip compress originals
  - Pros: Space efficient, preserves everything
  - Cons: Less accessible, requires extraction

**Decision**: **Move to `[spec-id]-original/` directory, YAML in parent**

**Rationale**:
- Maintains constitutional compliance (preservation)
- Clear distinction between archive and original
- Originals remain easily accessible for reference
- Consistent with existing archive structure

**Directory Structure**:
```
documentations/archive/specifications/
├── 004-modern-web-development.yaml        # Concise archive
├── 004-modern-web-development-original/   # Complete original
│   ├── spec.md
│   ├── plan.md
│   ├── tasks.md
│   └── [all other files]
├── 005-apt-snap-migration.yaml
├── 005-apt-snap-migration-original/
└── ARCHIVE_INDEX.md                       # Master index
```

---

## Technology Stack Summary

**Core Technologies**:
- Bash 5.x+ (scripting language)
- YAML 1.2 (archive format)
- Markdown (checklists, dashboards)
- grep/awk/sed (text processing)
- git (repository operations)

**Optional Dependencies**:
- `yq` (YAML processor - enhanced validation)
- `jq` (JSON processor - optional for structured data)

**No Dependencies**:
- Python/Ruby/Node.js (avoided to keep minimal)
- Graphviz (avoided - text-based visualization sufficient)
- Database (file-based approach)

---

## Implementation Patterns

**Pattern 1: Template-Based Generation**
- Store YAML template with placeholders
- Substitute variables with actual values
- Validate with `yq` if available

**Pattern 2: Incremental Processing**
- Process one specification at a time
- Report progress for user feedback
- Continue on errors, report at end

**Pattern 3: Idempotent Operations**
- Check if archive already exists before generating
- Skip already-archived specifications
- Allow re-archiving with --force flag

**Pattern 4: Validation First**
- Validate inputs before transformation
- Report all errors before proceeding
- Provide clear remediation guidance

---

## Research Complete

All technical decisions documented. Ready for Phase 1 (design artifacts) and Phase 2 (task generation).
