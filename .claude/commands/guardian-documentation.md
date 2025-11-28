---
description: Verify documentation structure, fix broken links, restore symlinks, ensure single source of truth - FULLY AUTOMATIC
---

## Purpose

**DOCUMENTATION INTEGRITY**: Verify all documentation systems, fix broken links, restore symlinks, commit fixes with zero manual intervention.

## User Input

```text
$ARGUMENTS
```

**Note**: User input is OPTIONAL. Command automatically verifies all documentation.

## Automatic Workflow

You **MUST** invoke the **001-orchestrator** agent to coordinate the documentation verification workflow.

Pass the following instructions to 001-orchestrator:

### Phase 1: Symlink Verification (Single Agent)

**Agent**: **003-symlink**

**Tasks**:
1. **Verify Primary Symlinks**:
   ```bash
   test -L CLAUDE.md && readlink CLAUDE.md
   test -L GEMINI.md && readlink GEMINI.md
   ```
   - Both must point to AGENTS.md
   - Identify any broken symlinks

2. **Auto-Restore if Broken**:
   ```bash
   # If CLAUDE.md broken or missing
   rm -f CLAUDE.md
   ln -s AGENTS.md CLAUDE.md

   # If GEMINI.md broken or missing
   rm -f GEMINI.md
   ln -s AGENTS.md GEMINI.md
   ```

3. **Scan Repository**:
   ```bash
   find . -type l -xtype l  # Find all broken symlinks
   ```

**Expected Output**:
- ✅ CLAUDE.md → AGENTS.md (restored if needed)
- ✅ GEMINI.md → AGENTS.md (restored if needed)
- ✅ No broken symlinks in repository

### Phase 2: Documentation Structure Verification (Parallel - 2 Agents)

**Agent 1: 002-compliance**

**Tasks**:
1. **AGENTS.md Size Check**:
   ```bash
   du -h AGENTS.md
   ```
   - Must be < 40KB constitutional limit
   - If > 40KB: Split sections into referenced documents

2. **Quick Links Validation**:
   - Verify all linked files exist
   - Check paths are correct
   - Identify 404 links

3. **Agent Registry**:
   - Verify all 9 agents documented
   - Check agent descriptions match implementations
   - Validate delegation network accuracy

**Agent 2: 003-docs**

**Tasks**:
1. **Directory Structure Verification**:
   ```
   documentations/
   ├── user/ (exists, has content)
   ├── developer/ (exists, has content)
   ├── specifications/ (exists, has active specs)
   └── archive/ (exists, historical only)
   ```

2. **Website Documentation**:
   - Verify website/src/ structure
   - Check no duplicate content with documentations/
   - Validate build output in docs/

3. **Local CI/CD Documentation**:
   - Verify .runners-local/README.md exists
   - Check workflow scripts documented
   - Validate links from AGENTS.md work

**Expected Output**:
- ✅/❌ AGENTS.md: XX KB (under/over 40KB limit)
- ✅/❌ All agents documented (9/9)
- ✅/❌ Documentation structure: Properly organized
- ✅/❌ No duplicate content detected

### Phase 3: Cross-Reference Validation (Single Agent)

**Agent**: **003-docs**

**Tasks**:
1. **Scan for Broken Links**:
   ```bash
   # Find all markdown files
   find documentations/ .claude/ spec-kit/ -name "*.md"

   # Check for broken link patterns
   grep -r "website/src/" documentations/  # Should be website/src/
   grep -r ".runners-local/workflows/" documentations/      # Should be .runners-local/workflows/
   grep -r "\](.*)" --include="*.md"       # Extract all links
   ```

2. **Validate Link Targets**:
   - For each link, verify target file exists
   - Check relative paths resolve correctly
   - Identify moved/deleted file references

3. **Common Issues**:
   - ❌ `website/src/` → Fix to `website/src/`
   - ❌ `.runners-local/workflows/` → Fix to `.runners-local/workflows/`
   - ❌ `.runners-local/` → Fix to `.runners-local/`
   - ❌ Absolute paths → Convert to relative

**Expected Output**:
- List of broken links with file locations
- Suggested fixes for each broken link
- Count of legacy references needing updates

### Phase 4: Auto-Fix Broken Links (Conditional)

**Agent**: **003-docs**

**Tasks** (only if broken links found):
1. **Auto-Fix Common Patterns**:
   ```bash
   # Fix website/src/ references
   find documentations/ -name "*.md" -exec sed -i 's|website/src/|website/src/|g' {} \;

   # Fix .runners-local/workflows/ references
   find documentations/ -name "*.md" -exec sed -i 's|.runners-local/workflows/|.runners-local/workflows/|g' {} \;

   # Fix .runners-local/ references
   find documentations/ -name "*.md" -exec sed -i 's|.runners-local/|.runners-local/|g' {} \;
   ```

2. **Validate Fixes**:
   - Re-scan for broken links
   - Verify all auto-fixes successful
   - Report any remaining manual fixes needed

**Skip if**: No broken links found

### Phase 5: Agent Documentation Validation (Single Agent)

**Agent**: **002-compliance**

**Tasks**:
1. **Verify Each Agent File**:
   ```bash
   for file in .claude/agents/*.md; do
     # Check frontmatter
     grep "^name:" "$file"
     grep "^description:" "$file"

     # Check invocation examples
     grep -A5 "## When to Invoke" "$file"
   done
   ```

2. **Validate AGENT_REGISTRY.md**:
   - Verify all 9 agents listed
   - Check capabilities descriptions accurate
   - Validate delegation patterns documented

3. **Slash Command Documentation**:
   - Verify all guardian-* commands consistent
   - Check agent references correct
   - Validate output formats documented

**Expected Output**:
- ✅/❌ All agents have proper frontmatter (9/9)
- ✅/❌ Invocation examples complete
- ✅/❌ AGENT_REGISTRY.md synchronized

### Phase 6: Constitutional Commit (Conditional)

**Agent**: **002-git**

**Tasks** (only if changes made):
```bash
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH="$DATETIME-docs-fix-documentation-integrity"

git checkout -b "$BRANCH"
git add .
git commit -m "docs: Fix documentation integrity and broken links

Problems Fixed:
- Restored X broken symlinks (CLAUDE.md, GEMINI.md)
- Fixed Y broken links (website/src/ → website/src/)
- Updated Z legacy path references
- Verified AGENTS.md size compliance

Changes:
- Symlinks: CLAUDE.md, GEMINI.md → AGENTS.md
- Path fixes: website/src/ → website/src/
- Path fixes: .runners-local/workflows/ → .runners-local/workflows/
- Verified all 9 agents documented

Validation:
- All symlinks intact and pointing correctly
- All internal links validated
- No broken cross-references
- AGENTS.md under 40KB limit

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

git push -u origin "$BRANCH"
git checkout main
git merge "$BRANCH" --no-ff
git push origin main
```

**Skip if**: No issues found, all documentation clean

## Expected Output

```
📚 DOCUMENTATION INTEGRITY REPORT
==================================

SYMLINK STATUS
==============
✅ CLAUDE.md → AGENTS.md (verified)
✅ GEMINI.md → AGENTS.md (verified)
✅ No broken symlinks in repository

DOCUMENTATION STRUCTURE
=======================
✅ AGENTS.md: 35.2 KB (under 40KB limit)
✅ All 9 agents documented in AGENT_REGISTRY.md
✅ Documentation organized:
   - user/setup/ ✅
   - developer/architecture/ ✅
   - specifications/ ✅ (3 active specs)
   - archive/ ✅ (historical only)

CROSS-REFERENCE INTEGRITY
=========================
⚠️  Broken links found: 5
   - documentations/user/setup/context7.md:42 → website/src/ (fixed)
   - documentations/developer/workflows.md:18 → .runners-local/workflows/ (fixed)
   - AGENTS.md:156 → .runners-local/ (fixed)

Auto-Fixed:
- 3 website/src/ → website/src/
- 2 .runners-local/workflows/ → .runners-local/workflows/

Remaining Issues: 0

AGENT DOCUMENTATION
===================
✅ All agents have proper frontmatter (9/9)
✅ Invocation examples complete
✅ AGENT_REGISTRY.md synchronized
✅ All guardian-* commands consistent

ACTIONS TAKEN
=============
✅ Restored symlinks: 0 (all intact)
✅ Fixed broken links: 5
✅ Updated legacy paths: 5

Git Workflow:
- ✅ Branch: 20251115-150000-docs-fix-documentation-integrity
- ✅ Commit: abc1234
- ✅ Merged to main
- ✅ Pushed to remote
- ✅ Branch preserved

Overall Status: ✅ EXCELLENT
All documentation systems verified and fixed.
```

## When to Use

Run `/guardian-documentation` when you need to:
- Verify documentation integrity after major changes
- Fix broken links automatically
- Restore broken symlinks
- Validate agent system documentation
- Ensure single source of truth compliance

**Best Practice**: Run after file moves, renames, or directory restructuring

## What This Command Does NOT Do

- ❌ Does NOT deploy to GitHub Pages (use `/guardian-deploy`)
- ❌ Does NOT clean up redundant files (use `/guardian-cleanup`)
- ❌ Does NOT commit source code changes (use `/guardian-commit`)
- ❌ Does NOT diagnose system health (use `/guardian-health`)

**Focus**: Documentation verification and fixes only.

## Constitutional Compliance

This command enforces:
- ✅ Single source of truth (AGENTS.md)
- ✅ Symlink integrity (CLAUDE.md, GEMINI.md → AGENTS.md)
- ✅ AGENTS.md size limit (< 40KB)
- ✅ Proper documentation organization
- ✅ No broken cross-references
- ✅ Agent system documentation completeness
