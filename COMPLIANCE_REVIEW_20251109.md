# GitHub Workflow Compliance Review - November 9, 2025

## Executive Summary

**CRITICAL VIOLATION FOUND**: The spec-kit implementation in `.specify/scripts/bash/create-new-feature.sh` generates branch names using non-compliant format `NNN-branch-suffix` instead of the constitutional requirement `YYYYMMDD-HHMMSS-type-description`.

**Impact**: Current branch `005-apt-snap-migration` and all branches created by spec-kit tooling violate constitutional requirements defined in AGENTS.md.

**Severity**: HIGH - Constitutional violation affecting all future feature development.

---

## Detailed Findings

### 1. Branch Naming Violation

**Constitutional Requirement** (AGENTS.md, lines 26-58):
```
Format: YYYYMMDD-HHMMSS-type-description
Examples:
  - 20250919-143000-feat-context-menu-integration
  - 20250919-143515-fix-performance-optimization
  - 20250919-144030-docs-agents-enhancement
```

**Actual Implementation** (`.specify/scripts/bash/create-new-feature.sh`, lines 214):
```bash
FEATURE_NUM=$(printf "%03d" "$BRANCH_NUMBER")
BRANCH_NAME="${FEATURE_NUM}-${BRANCH_SUFFIX}"
# Results in: 005-apt-snap-migration (NON-COMPLIANT)
```

**Affected Branches**:
- `005-apt-snap-migration` (current branch)
- `002-advanced-terminal-productivity` (remote)
- `001-repo-structure-refactor` (referenced in specs/)
- All future branches created via `/speckit.specify` command

**Root Cause**: The spec-kit implementation was created before the constitutional datetime-based naming format was established.

---

### 2. Compliance Assessment Summary

**PASS - Symlink Integrity**:
- CLAUDE.md → AGENTS.md ✓ (symlink verified)
- GEMINI.md → AGENTS.md ✓ (symlink verified)
- AGENTS.md single source of truth ✓

**PASS - Commit Message Format**:
- Recent commits include proper co-authorship:
  ```
  🤖 Generated with [Claude Code](https://claude.com/claude-code)
  Co-Authored-By: Claude <noreply@anthropic.com>
  ```

**PASS - Merge Strategy**:
- All recent merges use --no-ff flag
- Branch preservation enforced ✓

**FAIL - Branch Naming Consistency**:
- Non-compliant branches:
  - `005-apt-snap-migration` (created via spec-kit)
  - `002-advanced-terminal-productivity` (created via spec-kit)
  - `001-repo-structure-refactor` (created via spec-kit)
- Compliant branches (manual creation):
  - `20251109-073418-docs-sync-current-reality`
  - `20251109-072455-feat-phase5-kickoff-install-node`
  - `20251109-070259-spec-001-constitution-update`

**Observation**: Manual branch creation follows constitutional format correctly. Problem is entirely in spec-kit automation.

---

### 3. Source Location

**File**: `.specify/scripts/bash/create-new-feature.sh`
**Lines**: 214-241
**Component**: Branch name generation and creation logic
**Issue**: Uses sequential numbering (001, 002, 005) instead of datetime prefix

---

## Remediation Actions Required

### Phase 1: Fix Spec-Kit Scripts (CRITICAL)

**File**: `.specify/scripts/bash/create-new-feature.sh`

**Required Changes**:
1. Replace lines 214-215 to generate datetime-based names:
   - Old: `FEATURE_NUM=$(printf "%03d" "$BRANCH_NUMBER")`
   - Old: `BRANCH_NAME="${FEATURE_NUM}-${BRANCH_SUFFIX}"`
   - New: Generate `DATETIME=$(date +"%Y%m%d-%H%M%S")` prefix
   - New: Add `TYPE="feat"` parameter
   - New: `BRANCH_NAME="${DATETIME}-${TYPE}-${BRANCH_SUFFIX}"`

2. Update help text to document new format

3. Test `/speckit.specify` command generates compliant names

### Phase 2: Update Documentation

**Files**:
1. `.specify/memory/constitution.md` - Document spec-kit branch naming compliance
2. `spec-kit/guides/` - Update all guides to reference proper naming format
3. `AGENTS.md` - Add note that spec-kit scripts enforce constitutional requirements

### Phase 3: Preserve Non-Compliant Branches

**Action**: Create properly-named branches for active work

**Current Branch**: `005-apt-snap-migration`
- Create: `20251109-HHMMSS-feat-apt-snap-migration` 
- Preserve: Rename old to `archive-20251109-005-apt-snap-migration`
- Migrate: All pending work to new branch
- Strategy: Use git branch -m to rename, push all branches

---

## Constitutional Requirements Summary

From AGENTS.md (single source of truth):

**Branch Naming Format (MANDATORY)**:
- Pattern: `YYYYMMDD-HHMMSS-type-short-description`
- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`
- Example: `20250919-143000-feat-context-menu-integration`

**Branch Preservation (MANDATORY)**:
- NEVER delete branches without explicit permission
- Use `git merge --no-ff` to preserve branch history
- Archive old branches with `archive-YYYYMMDD-` prefix

**Commit Messages (MANDATORY)**:
- Format: `<type>: <description>`
- Include: `🤖 Generated with [Claude Code](https://claude.com/claude-code)`
- Signature: `Co-Authored-By: Claude <noreply@anthropic.com>`

---

## Verification Checklist

- [x] Identified violation: spec-kit branch naming format
- [x] Confirmed constitutional requirements from AGENTS.md
- [x] Verified symlink integrity (CLAUDE.md → AGENTS.md)
- [x] Verified commit message format compliance
- [x] Verified merge strategy (--no-ff) compliance
- [ ] Fix spec-kit script (create-new-feature.sh)
- [ ] Update constitutional documentation references
- [ ] Test spec-kit command generates compliant names
- [ ] Handle migration of existing non-compliant branches

---

## Risk Assessment

**If NOT Fixed**:
- Ongoing violations as new features created
- Inconsistent branch naming (mixed old/new format)
- Multi-developer naming conflicts (sequential breaks)
- Historical ordering lost for branches

**If Fixed**:
- Full constitutional compliance achieved
- Consistent datetime-based naming for all branches
- Proper type classification for branches
- Chronological ordering preserved

---

**Status**: AWAITING REMEDIATION
**Severity**: HIGH (Constitutional violation)
**Priority**: BEFORE next spec-kit feature creation
