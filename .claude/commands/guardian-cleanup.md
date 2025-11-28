---
description: Identify and remove redundant files/scripts with constitutional Git workflow - FULLY AUTOMATIC
---

## Purpose

**REPOSITORY CLEANUP**: Scan for obsolete files, remove redundancies, commit cleanly with zero manual intervention.

## User Input

```text
$ARGUMENTS
```

**Note**: User input is OPTIONAL. Command automatically identifies cleanup targets.

## Automatic Workflow

You **MUST** invoke the **001-orchestrator** agent to coordinate the cleanup workflow.

Pass the following instructions to 001-orchestrator:

### Phase 1: Cleanup Analysis (Single Agent)

**Agent**: **002-cleanup**

**Tasks**:
1. Scan entire repository for:
   - Test scripts in root directory (test-*.sh, *_test.sh)
   - Obsolete configuration files (*.bak, *.old, *~)
   - Duplicate scripts with similar functionality
   - Unused scripts (no references in git history or codebase)
   - Empty directories

2. Identify proper locations:
   - Root directory: ONLY start.sh, manage.sh, README.md, docs
   - Scripts: scripts/ directory
   - Tests: .runners-local/tests/
   - Temporary: /tmp/ (should not be in repo)

3. Generate cleanup plan with justification for each file

**Cleanup Targets**:
```
REMOVE:
- Root directory: test-*.sh, debugging scripts
- Duplicate functionality: consolidate into modular libraries
- Obsolete configs: *.bak, *.old files

RELOCATE (if needed):
- Active test scripts → .runners-local/tests/
- Utility scripts → scripts/
```

### Phase 2: Execute Cleanup (Single Agent)

**Agent**: **002-cleanup**

**Automatic Actions**:
```bash
# Remove identified files
git rm <file1> <file2> <file3>

# Relocate files if needed
git mv <source> <destination>

# Show summary
echo "Removed: X files (Y lines)"
echo "Relocated: Z files"
```

**Safety Requirements**:
- ✅ NEVER remove: start.sh, manage.sh, README.md, AGENTS.md
- ✅ NEVER remove: scripts/, .runners-local/, docs/, website/
- ✅ ALWAYS preserve: .nojekyll file
- ✅ Log all removals for audit trail

### Phase 3: Verify Documentation Impact (Conditional)

**Agent**: **003-docs**

**Tasks** (only if documentation files were modified):
1. Verify AGENTS.md symlinks:
   - CLAUDE.md → AGENTS.md
   - GEMINI.md → AGENTS.md
2. Check for broken links caused by file removals
3. Update references if needed

**Skip if**: Only test scripts or non-documentation files removed

### Phase 4: Constitutional Commit (Single Agent)

**Agent**: **002-git**

**Tasks**:
```bash
# Create cleanup branch
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH="$DATETIME-chore-cleanup-redundant-files"

git checkout -b "$BRANCH"
git add .
git commit -m "chore: Remove obsolete test scripts and redundant files

Cleanup Summary:
- Removed X obsolete test scripts (Y lines)
- Removed Z duplicate/unused files
- Relocated N files to proper locations

Files removed:
- test-box-*.sh (debugging scripts)
- test_*.sh (temporary test files)
- [list all removed files]

Rationale:
- Root directory should only contain start.sh, manage.sh, README.md
- Test scripts belong in .runners-local/tests/
- Reduces repository clutter and improves maintainability

Constitutional Compliance:
- ✅ No critical files removed
- ✅ .nojekyll preserved
- ✅ Branch preservation strategy

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

git push -u origin "$BRANCH"
git checkout main
git merge "$BRANCH" --no-ff
git push origin main
```

**Branch Preservation**: NEVER delete cleanup branch

## Expected Output

```
🧹 REPOSITORY CLEANUP COMPLETE

Cleanup Analysis:
- Files scanned: 1,247
- Obsolete files found: 5
- Redundant files found: 2
- Total removal candidates: 7

Files Removed:
- test-box-color-rendering.sh (350 lines)
- test-box-fix.sh (69 lines)
- test-box-rendering.sh (194 lines)
- test-box-simple.sh (137 lines)
- test_idempotent_start.sh (369 lines)

Total: 1,119 lines removed

Documentation Impact:
- ✅ No documentation changes needed
- ✅ Symlinks intact

Git Workflow:
- ✅ Branch: 20251115-115247-chore-cleanup-redundant-files
- ✅ Commit: 2156ee4
- ✅ Merged to main
- ✅ Pushed to remote
- ✅ Branch preserved

Constitutional Compliance: ✅ 100%
```

## When to Use

Run `/guardian-cleanup` when you:
- Notice test scripts accumulating in root directory
- Want to remove debugging files left from problem-solving
- Need to consolidate duplicate functionality
- Want to maintain clean repository structure

## What This Command Does NOT Do

- ❌ Does NOT deploy to GitHub Pages (use `/guardian-deploy`)
- ❌ Does NOT build Astro website (use `/guardian-deploy`)
- ❌ Does NOT commit source code changes (use `/guardian-commit`)
- ❌ Does NOT diagnose health issues (use `/guardian-health`)

**Focus**: Cleanup only - removes obsolete files, commits cleanup changes.

## Constitutional Compliance

This command enforces:
- ✅ Root directory cleanliness (only essential files)
- ✅ Proper script organization (scripts/, .runners-local/tests/)
- ✅ Constitutional commit format
- ✅ Branch preservation (cleanup branches never deleted)
- ✅ Audit trail (all removals logged)
