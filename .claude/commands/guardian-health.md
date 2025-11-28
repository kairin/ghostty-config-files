---
description: Comprehensive project health assessment - MCP servers, documentation, builds, Git status - FULLY AUTOMATIC
---

## Purpose

**HEALTH CHECK**: Diagnose all project systems in parallel, identify issues, provide actionable recommendations with zero manual intervention.

## User Input

```text
$ARGUMENTS
```

**Note**: User input is OPTIONAL. If tech stack mentioned, queries Context7 for latest best practices.

## Automatic Workflow

You **MUST** invoke the **001-orchestrator** agent to coordinate the health check workflow.

Pass the following instructions to 001-orchestrator:

### Phase 1: System Health Assessment (Parallel - 3 Agents)

**Agent 1: 002-health**

**Tasks**:
1. **Context7 MCP Status**:
   - Check .env for CONTEXT7_API_KEY
   - Verify .mcp.json configuration
   - Test MCP server connectivity
   - Validate tools available (resolve-library-id, get-library-docs)
   - Query Context7 for latest best practices if tech stack in $ARGUMENTS

2. **GitHub MCP Status**:
   - Verify gh CLI authentication (`gh auth status`)
   - Check .env for GITHUB_TOKEN
   - Test GitHub API access
   - Validate repository access

3. **Git Repository Health**:
   ```bash
   git status
   git fetch origin
   git log origin/main..main  # Check unpushed commits
   git branch -vv             # Check branch tracking
   ```

**Expected Output**:
- ✅/❌ Context7 MCP: Configured, connected, tools available
- ✅/❌ GitHub MCP: Authenticated, API accessible
- ✅/❌ Git Status: Clean working tree, main synced with origin

**Agent 2: 003-docs**

**Tasks**:
1. **Symlink Integrity**:
   ```bash
   test -L CLAUDE.md && readlink CLAUDE.md
   test -L GEMINI.md && readlink GEMINI.md
   ```
   - Verify both point to AGENTS.md
   - Check for broken symlinks

2. **Documentation Structure**:
   - Verify documentations/ exists with proper subdirectories
   - Check AGENTS.md size (must be < 40KB)
   - Validate README.md exists and links correctly
   - Verify .runners-local/README.md exists

3. **Single Source of Truth**:
   - No duplicate content between AGENTS.md and README.md
   - No scattered documentation outside documentations/
   - All quick links in AGENTS.md valid

**Expected Output**:
- ✅/❌ Symlinks: CLAUDE.md → AGENTS.md, GEMINI.md → AGENTS.md
- ✅/❌ AGENTS.md: Size within 40KB limit
- ✅/❌ Documentation: Properly organized, no duplicates

**Agent 3: 002-astro**

**Tasks**:
1. **Build Artifacts Verification**:
   ```bash
   # Check build output
   test -f docs/index.html
   test -d docs/_astro/
   test -f docs/.nojekyll  # CRITICAL

   # Count pages
   find docs -name "*.html" | wc -l

   # Check CSS bundle
   ls -lh docs/_astro/*.css
   ```

2. **GitHub Pages Status**:
   ```bash
   gh api repos/:owner/:repo/pages
   gh repo view --json homepageUrl,isPrivate
   ```

3. **Configuration Validation**:
   - Verify website/package.json exists
   - Check website/astro.config.mjs configuration
   - Validate Tailwind setup

**Expected Output**:
- ✅/❌ Build Artifacts: 18 HTML pages, .nojekyll present
- ✅/❌ GitHub Pages: Configured, deployed, accessible
- ✅/❌ Configuration: Astro config valid, dependencies current

### Phase 2: Issue Identification (Single Task)

**Consolidate all findings**:
- Categorize issues: CRITICAL / WARNING / INFO
- Generate actionable recommendations
- Prioritize fixes

**Example**:
```
CRITICAL:
- .nojekyll file missing → Website CSS will not load

WARNING:
- Context7 MCP not configured → Best practices queries unavailable
- 5 branches not pushed to remote → Risk of data loss

INFO:
- AGENTS.md at 35KB (under 40KB limit)
- Build time: 725ms (excellent)
```

### Phase 3: Recommendations Generation (Single Task)

**For each issue, provide**:
1. **Problem**: What's wrong
2. **Impact**: What will break / risk level
3. **Fix**: Exact command or action to resolve
4. **Prevention**: How to avoid in future

**Example Recommendations**:
```
Issue: GitHub MCP not in .mcp.json
Impact: GitHub operations via MCP unavailable
Fix: Add GitHub MCP server configuration to .mcp.json
Prevention: Run /guardian-health after .mcp.json changes

Issue: 5 unpushed branches
Impact: Risk of losing work if local repository corrupted
Fix: Run /guardian-deploy to sync all branches
Prevention: Enable git push hooks in .git/hooks/
```

## Expected Output

```
🏥 COMPREHENSIVE HEALTH REPORT
==============================

MCP SERVERS STATUS
==================
✅ Context7 MCP: Configured and connected
   - API Key: ctx7sk-a2796...e2e6 (secure)
   - Tools: resolve-library-id, get-library-docs
   - Configuration: .mcp.json (project-level)

⚠️  GitHub MCP: Partially configured
   - GitHub CLI: Authenticated (user: kairin)
   - Token: Configured in .env
   - Issue: MCP server not in .mcp.json (non-critical)

DOCUMENTATION STATUS
====================
✅ Symlinks: All intact
   - CLAUDE.md → AGENTS.md ✅
   - GEMINI.md → AGENTS.md ✅
   - No broken symlinks

✅ AGENTS.md: 35.2 KB (under 40KB limit)
✅ Documentation Structure: Properly organized
   - user/setup/ ✅
   - developer/architecture/ ✅
   - specifications/ ✅

BUILD & DEPLOYMENT STATUS
=========================
✅ Astro Build: 18 pages generated
   - Build time: 725ms (excellent)
   - Bundle size: 89KB (optimized)
   - TypeScript: 0 errors

✅ .nojekyll: PRESENT (CRITICAL for GitHub Pages)
✅ GitHub Pages: Live and operational
   - URL: https://kairin.github.io/ghostty-config-files/
   - Status: Built and deployed
   - Last updated: 2025-11-15 03:53:25 UTC

GIT REPOSITORY STATUS
=====================
✅ Working Tree: Clean
✅ Main Branch: Synced with origin/main
✅ Branch Preservation: 142 branches maintained

ISSUES FOUND
============
None - All systems operational

RECOMMENDATIONS
===============
1. Add GitHub MCP to .mcp.json for enhanced GitHub operations
2. Consider setting up automated Context7 health checks
3. Monitor AGENTS.md size (currently 87% of 40KB limit)

Overall Health: ✅ EXCELLENT
All critical systems operational. Minor optimizations recommended.
```

## When to Use

Run `/guardian-health` when you need to:
- Diagnose project health before major changes
- Verify all systems operational
- Check MCP server connectivity
- Validate build and deployment status
- Identify potential issues proactively

**Best Practice**: Run weekly or before major deployments

## What This Command Does NOT Do

- ❌ Does NOT fix issues (only diagnoses)
- ❌ Does NOT deploy to GitHub Pages (use `/guardian-deploy`)
- ❌ Does NOT commit changes (use `/guardian-commit`)
- ❌ Does NOT clean up files (use `/guardian-cleanup`)

**Focus**: Diagnostic only - identifies issues, provides fix recommendations.

## Constitutional Compliance

This command verifies:
- ✅ Context7 MCP configuration for best practices sync
- ✅ GitHub MCP authentication for repository operations
- ✅ Documentation symlink integrity (single source of truth)
- ✅ AGENTS.md size compliance (< 40KB)
- ✅ .nojekyll file presence (CRITICAL for GitHub Pages)
- ✅ Branch preservation status
- ✅ Build system health
