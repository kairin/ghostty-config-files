# Quickstart Guide: Task Archive and Consolidation System

**Feature**: 006-task-archive-consolidation
**Date**: 2025-11-11
**Version**: 1.0.0

## Overview

This guide provides practical scenarios for implementing and using the task archive and consolidation system. The system enables efficient management of completed specification archives, consolidated todo checklists, and project status dashboards.

## Prerequisites

**Required**:
- Bash 5.x+ shell environment
- Git repository with specification directories
- Standard coreutils (grep, awk, sed, wc, find)

**Optional**:
- `yq` (YAML processor) - Enhanced validation and formatting
- `jq` (JSON processor) - Structured data processing

**Verification**:
```bash
# Check bash version
bash --version | head -1

# Check for yq (optional)
command -v yq && yq --version

# Check for jq (optional)
command -v jq && jq --version

# Verify git repository
git rev-parse --git-dir
```

---

## Scenario 1: Archive a Single Completed Specification

**Use Case**: You've completed spec 004-modern-web-development and want to archive it to reduce clutter.

**Steps**:
```bash
# 1. Navigate to repository root
cd /home/kkk/Apps/ghostty-config-files

# 2. Verify specification is 100% complete
./scripts/archive_spec.sh 004 --validate-only

# 3. Generate YAML archive (dry run first)
./scripts/archive_spec.sh 004 --dry-run

# 4. Generate actual archive
./scripts/archive_spec.sh 004

# 5. Verify archive was created
ls -lh documentations/archive/specifications/004-modern-web-development.yaml
ls -lh documentations/archive/specifications/004-modern-web-development-original/
```

**Expected Output**:
```
🔍 Validating 004-modern-web-development...
  ✅ Completion: 69/69 tasks (100%)
  ✅ All files validated (15/15 files found)

📦 Archiving 004-modern-web-development...
  ✅ Generated YAML archive (355 lines)
  ✅ Moved original directory to archive
  📊 Space savings: 93% (1,572 → 355 lines)

✅ Archive complete: documentations/archive/specifications/004-modern-web-development.yaml
```

---

## Scenario 2: Archive All Completed Specifications

**Use Case**: Batch archive all 100% complete specifications to clean up repository.

**Steps**:
```bash
# 1. See what would be archived
./scripts/archive_spec.sh --all --dry-run

# 2. Archive all complete specs
./scripts/archive_spec.sh --all

# 3. Review archive statistics
ls -lh documentations/archive/specifications/*.yaml
```

**Expected Output**:
```
🔍 Scanning specifications...
Found 4 specifications (1 complete, 3 incomplete)

📦 Archiving 004-modern-web-development...
  ✅ Generated YAML archive (355 lines)
  ✅ Moved original directory to archive
  📊 Space savings: 93% (1,572 → 355 lines)

✅ Successfully archived 1 specification
⏭️  Skipped 3 incomplete specifications
```

---

## Scenario 3: Validate Files Before Archiving

**Use Case**: Check spec 002 for file existence discrepancies without archiving.

**Steps**:
```bash
# Validate spec 002 without making changes
./scripts/archive_spec.sh 002 --validate-only
```

**Expected Output**:
```
🔍 Validating 002-advanced-terminal-productivity...
  ⚠️  Completion: 13/72 tasks (18%) - INCOMPLETE

❌ Validation failed for 002-advanced-terminal-productivity:
  - T004: ~/.config/terminal-ai/providers.conf (MISSING)
  - T005: ~/.config/terminal-ai/setup-keys.sh (MISSING)
  - T006: ~/.oh-my-zsh/custom/plugins/zsh-codex/ (MISSING)
  - T007: scripts/advanced-terminal/environment-detection.sh (MISSING)
  - T008: ~/.config/starship.toml (MISSING)
  - T009: ~/.config/theme-switcher.sh (MISSING)
  - T010: tests/advanced-terminal/test_foundation_preservation.sh (MISSING)
  - T011: tests/advanced-terminal/test_modern_tools.sh (MISSING)
  - T012: tests/advanced-terminal/test_constitutional_compliance.sh (MISSING)

📋 Summary: 9 missing files for 9 tasks marked complete
```

---

## Scenario 4: Generate Consolidated Todo Checklist

**Use Case**: Extract all incomplete tasks across all specifications into a unified implementation checklist.

**Steps**:
```bash
# 1. Generate checklist with default settings
./scripts/consolidate_todos.sh

# 2. View generated checklist
cat IMPLEMENTATION_CHECKLIST.md

# 3. Generate checklist sorted by priority
./scripts/consolidate_todos.sh --sort-by priority

# 4. Filter to only P1 tasks
./scripts/consolidate_todos.sh --filter-priority P1
```

**Expected Output**:
```
🔍 Scanning specifications for incomplete tasks...

📋 Found incomplete tasks:
  - 005-apt-snap-migration: 17 tasks (2-3 days)
  - 001-repo-structure-refactor: 73 tasks (5-7 days)
  - 002-advanced-terminal-productivity: 59 tasks (15-20 days)

📊 Total: 149 tasks, estimated 22-30 days

✅ Checklist generated: IMPLEMENTATION_CHECKLIST.md
```

---

## Scenario 5: Generate Project Status Dashboard

**Use Case**: Get a comprehensive overview of all specifications and their completion status.

**Steps**:
```bash
# 1. Generate dashboard
./scripts/generate_dashboard.sh

# 2. View dashboard
cat PROJECT_STATUS_DASHBOARD.md

# 3. Generate dashboard with per-phase details
./scripts/generate_dashboard.sh --show-details

# 4. Export dashboard as JSON for external tools
./scripts/generate_dashboard.sh --format json --output /tmp/status.json
```

**Expected Output**:
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

---

## Scenario 6: Filter Todos for Specific Specification

**Use Case**: Focus implementation work on a single specification.

**Steps**:
```bash
# Generate checklist for only spec 005
./scripts/consolidate_todos.sh --filter-spec 005 --output /tmp/005-todos.md

# View focused checklist
cat /tmp/005-todos.md
```

**Expected Output**:
```
🔍 Scanning specifications for incomplete tasks...

📋 Found incomplete tasks:
  - 005-apt-snap-migration: 17 tasks (2-3 days)

📊 Total: 17 tasks, estimated 2-3 days

✅ Checklist generated: /tmp/005-todos.md
```

---

## Scenario 7: Re-Archive with Force Flag

**Use Case**: Regenerate archive for a spec that was already archived.

**Steps**:
```bash
# Re-archive spec 004 with updated information
./scripts/archive_spec.sh 004 --force

# Keep original directory when re-archiving
./scripts/archive_spec.sh 004 --force --keep-original
```

**Expected Output**:
```
⚠️  Archive already exists: 004-modern-web-development.yaml
🔄 Re-archiving due to --force flag...

📦 Archiving 004-modern-web-development...
  ✅ Generated YAML archive (355 lines)
  ✅ Moved original directory to archive
  📊 Space savings: 93% (1,572 → 355 lines)

✅ Archive updated: documentations/archive/specifications/004-modern-web-development.yaml
```

---

## Scenario 8: Include Dependency Graph in Checklist

**Use Case**: Visualize task dependencies to plan implementation order.

**Steps**:
```bash
# Generate checklist with dependency visualization
./scripts/consolidate_todos.sh --show-dependencies
```

**Expected Output** (excerpt from IMPLEMENTATION_CHECKLIST.md):
````markdown
# Implementation Checklist

**Generated**: 2025-11-11 04:25:34
**Total Incomplete Tasks**: 149
**Estimated Effort**: 22-30 days

## Task Dependencies

### 001-repo-structure-refactor
- T047: Extract install_node.sh module
  - Depends on: T001-T016 (templates and utilities)
- T048: Extract install_zig.sh module
  - Depends on: T047 (Node.js must be available first)
  - Blocks: T049 (Ghostty build needs Zig)

⚠️ Circular dependency detected: T063 ↔ T064
````

---

## Scenario 9: Custom Output Locations

**Use Case**: Store generated files in non-default locations for CI/CD integration.

**Steps**:
```bash
# Archive to custom directory
./scripts/archive_spec.sh 004 --output-dir /tmp/archives/

# Generate checklist to custom file
./scripts/consolidate_todos.sh --output /tmp/current-sprint.md

# Generate dashboard to docs directory
./scripts/generate_dashboard.sh --output docs/project-status.md
```

---

## Scenario 10: Dry Run for Preview

**Use Case**: Preview what would happen without making any changes.

**Steps**:
```bash
# Preview archive operation
./scripts/archive_spec.sh --all --dry-run

# Preview checklist generation
./scripts/consolidate_todos.sh --dry-run

# Preview dashboard generation
./scripts/generate_dashboard.sh --dry-run
```

---

## Common Workflows

### Weekly Status Update Workflow
```bash
# 1. Update consolidated checklist
./scripts/consolidate_todos.sh

# 2. Generate status dashboard
./scripts/generate_dashboard.sh

# 3. Review and commit
git add IMPLEMENTATION_CHECKLIST.md PROJECT_STATUS_DASHBOARD.md
git commit -m "chore: Weekly status update"
```

### Specification Completion Workflow
```bash
# 1. Validate all files exist
./scripts/archive_spec.sh 004 --validate-only

# 2. Archive completed spec
./scripts/archive_spec.sh 004

# 3. Update consolidated checklist (remove completed tasks)
./scripts/consolidate_todos.sh

# 4. Update dashboard
./scripts/generate_dashboard.sh

# 5. Commit archive and updates
git add documentations/archive/ IMPLEMENTATION_CHECKLIST.md PROJECT_STATUS_DASHBOARD.md
git commit -m "feat: Archive completed specification 004"
```

### Sprint Planning Workflow
```bash
# 1. Generate current status
./scripts/generate_dashboard.sh

# 2. Extract P1 tasks for this sprint
./scripts/consolidate_todos.sh --filter-priority P1 --output /tmp/sprint-todos.md

# 3. Review effort estimates
grep -E '\([0-9]+ (hours?|days?)\)' /tmp/sprint-todos.md

# 4. Copy selected tasks to sprint board
```

---

## Troubleshooting

### Issue: "Validation failed" errors
**Symptom**: Archive script reports missing files for completed tasks

**Solution**:
```bash
# Use --validate-only to see all issues
./scripts/archive_spec.sh 002 --validate-only

# Either:
# A) Fix file paths and create missing files
# B) Update tasks.md to mark tasks incomplete: - [ ]
# C) Accept validation warnings for questionable specs
```

### Issue: "No incomplete tasks found"
**Symptom**: Checklist generation reports no tasks

**Solution**:
```bash
# Verify tasks exist
find documentations/specifications -name tasks.md -exec grep -l '\- \[ \]' {} \;

# Check file format
grep -E '^\- \[(x| )\]' documentations/specifications/*/tasks.md | head
```

### Issue: Archive already exists
**Symptom**: "Archive already exists" error without --force

**Solution**:
```bash
# Either use --force to overwrite
./scripts/archive_spec.sh 004 --force

# Or manually remove old archive first
rm documentations/archive/specifications/004-modern-web-development.yaml
./scripts/archive_spec.sh 004
```

### Issue: Performance slow for large repositories
**Symptom**: Scripts take >30 seconds to execute

**Solution**:
```bash
# Process single spec instead of --all
./scripts/archive_spec.sh 004

# Filter checklist to single spec
./scripts/consolidate_todos.sh --filter-spec 005

# Use --no-dependencies to skip dependency graph generation
./scripts/consolidate_todos.sh --no-dependencies
```

---

## Best Practices

1. **Always validate before archiving**: Use `--validate-only` to catch file existence issues
2. **Use dry-run mode first**: Preview changes with `--dry-run` before actual execution
3. **Regular dashboard updates**: Generate dashboard weekly to track progress
4. **Keep checklists updated**: Regenerate after completing tasks or adding new specs
5. **Archive immediately when complete**: Don't let 100% complete specs sit unarchived
6. **Preserve originals initially**: Use `--keep-original` until confident in archive quality
7. **Version control archives**: Commit YAML archives to git for history preservation

---

## Integration with Other Tools

### Git Hooks
```bash
# .git/hooks/pre-commit
#!/bin/bash
# Regenerate checklist and dashboard before commit
./scripts/consolidate_todos.sh
./scripts/generate_dashboard.sh
git add IMPLEMENTATION_CHECKLIST.md PROJECT_STATUS_DASHBOARD.md
```

### CI/CD Integration
```bash
# .github/workflows/status-update.yml (or local-infra equivalent)
- name: Generate status reports
  run: |
    ./scripts/consolidate_todos.sh
    ./scripts/generate_dashboard.sh
    git diff --exit-code || (git add . && git commit -m "chore: Auto-update status")
```

### Makefile Integration
```makefile
.PHONY: status archive checklist dashboard

status: checklist dashboard

archive:
	./scripts/archive_spec.sh --all

checklist:
	./scripts/consolidate_todos.sh

dashboard:
	./scripts/generate_dashboard.sh
```

---

## Next Steps

After completing this quickstart guide, proceed with:

1. **Run `/speckit.tasks`**: Generate implementation tasks for this feature
2. **Implement scripts**: Build the 3 CLI tools (archive_spec.sh, consolidate_todos.sh, generate_dashboard.sh)
3. **Test workflows**: Execute all scenarios above to validate implementation
4. **Document learnings**: Update lessons_learned section as implementation progresses

---

**Guide Version**: 1.0.0
**Last Updated**: 2025-11-11
**Status**: Complete - Ready for implementation
