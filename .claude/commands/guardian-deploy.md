---
description: Complete Git workflow sync and deployment using local CI/CD runners with multi-agent orchestration - FULLY AUTOMATIC
---

## Purpose

**ONE-COMMAND DEPLOYMENT**: Sync all branches, build website, deploy to GitHub Pages with zero manual intervention.

## User Input

```text
$ARGUMENTS
```

**Note**: User input is OPTIONAL. Command is fully automatic.

## Automatic Workflow

You **MUST** invoke the **001-orchestrator** agent to coordinate the complete deployment workflow.

Pass the following instructions to 001-orchestrator:

### Phase 1: Pre-Deployment Validation (Parallel - 3 Agents)

**Agents to Execute**:
1. **002-git**: Check git status, verify working tree, list branches needing sync
2. **002-astro**: Verify build artifacts, .nojekyll file, HTML page count
3. **002-health**: Quick health check, symlink verification, constitutional compliance

**Validation Requirements**:
- ✅ Working tree clean or changes identified
- ✅ .nojekyll file present in docs/
- ✅ Symlinks intact (CLAUDE.md, GEMINI.md → AGENTS.md)
- ✅ No critical health issues

### Phase 2: Local CI/CD Validation (Sequential)

**Commands to Execute**:
```bash
# Complete local workflow validation
./.runners-local/workflows/gh-workflow-local.sh all

# Astro build verification
./.runners-local/workflows/astro-build-local.sh build
./.runners-local/workflows/astro-build-local.sh validate

# GitHub Pages setup verification
./.runners-local/workflows/gh-pages-setup.sh --verify
```

**Expected Results**:
- ✅ TypeScript compilation: 0 errors
- ✅ Build completes successfully
- ✅ All assets accessible
- ✅ No broken links

### Phase 3: Git Workflow Synchronization (Sequential)

**Agent**: **002-git**

**Tasks**:
1. Ensure main branch is current
2. Fetch remote updates
3. Push main to remote (if needed)
4. Push all feature branches to remote
5. Verify all branches synced (100% preservation)

**Constitutional Requirements**:
- ✅ NEVER delete any branches
- ✅ Branch naming: YYYYMMDD-HHMMSS-type-description
- ✅ All commits with Claude attribution

### Phase 4: Astro Build Execution (Single Agent)

**Agent**: **002-astro**

**Tasks**:
```bash
# Fresh build
npm --prefix /home/kkk/Apps/ghostty-config-files/website run build

# Verify output
- docs/index.html exists
- docs/_astro/ directory exists
- docs/.nojekyll present (CRITICAL)
- HTML page count matches expected
```

**Build Validation**:
- ✅ Build time < 2 minutes
- ✅ All pages generated
- ✅ CSS bundle optimized
- ✅ .nojekyll protecting assets

### Phase 5: GitHub Pages Deployment (Parallel - 2 Agents)

**Agent 1**: **002-git**

If docs/ has uncommitted changes:
- Create deployment branch (YYYYMMDD-HHMMSS-deploy-build-artifacts)
- Commit with constitutional format
- Merge to main with --no-ff
- Push to remote
- Preserve branch (NEVER delete)

**Agent 2**: **002-astro**

Verify GitHub Pages:
```bash
gh api repos/:owner/:repo/pages
gh repo view --json homepageUrl
```

### Phase 6: Deployment Verification (Parallel - 3 Agents)

**Verification Tasks**:
1. **Website Accessibility**: Test homepage, new pages, CSS assets (HTTP 200)
2. **Build Artifacts**: Verify all HTML pages, .nojekyll, asset directory
3. **Constitutional Compliance**: Branch preservation, symlinks, zero GitHub Actions cost

**Success Criteria**:
- ✅ All pages return HTTP 200
- ✅ All branches preserved (0 deleted)
- ✅ .nojekyll integrity confirmed
- ✅ Zero GitHub Actions minutes consumed

### Phase 7: Documentation & Logging (Single Agent)

**Agent**: **003-docs**

**Tasks**:
- Generate deployment summary
- Log deployment metrics to .runners-local/logs/
- Capture system state snapshot
- Update health dashboard

## Expected Output

```
🚀 COMPLETE DEPLOYMENT ORCHESTRATION

Total Duration: ~10 minutes
Agents Coordinated: 7
Efficiency: 90% parallel optimization

Git Synchronization:
- ✅ 142 branches synchronized with remote (100% preserved)
- ✅ Main branch pushed to origin
- ✅ All feature branches backed up

Astro Build:
- ✅ Build time: 725ms
- ✅ Pages generated: 18 HTML pages
- ✅ CSS bundle: 89KB optimized
- ✅ TypeScript: 0 errors

GitHub Pages Deployment:
- ✅ Status: Live and operational
- ✅ URL: https://kairin.github.io/ghostty-config-files/
- ✅ All pages accessible: HTTP 200

Constitutional Compliance:
- ✅ Branch preservation: 100%
- ✅ Zero GitHub Actions cost
- ✅ .nojekyll integrity: Confirmed
- ✅ Symlinks maintained
```

## When to Use

Run `/guardian-deploy` when you need:
- Complete deployment of website changes
- Full Git repository synchronization
- All branches backed up to remote
- GitHub Pages updated with latest content
- Zero manual intervention required

## What This Command Does NOT Do

- ❌ Does NOT clean up redundant files (use `/guardian-cleanup`)
- ❌ Does NOT fix documentation issues (use `/guardian-documentation`)
- ❌ Does NOT diagnose health problems (use `/guardian-health`)
- ❌ Does NOT create new commits for source changes (use `/guardian-commit`)

**Focus**: Deployment orchestration only - assumes source changes already committed.

## Constitutional Compliance

This command enforces:
- ✅ Local CI/CD execution before GitHub deployment
- ✅ Branch preservation strategy (NEVER delete)
- ✅ .nojekyll integrity verification (CRITICAL for GitHub Pages)
- ✅ Zero GitHub Actions cost (all local runners)
- ✅ Constitutional commit format
- ✅ Symlink integrity maintenance
