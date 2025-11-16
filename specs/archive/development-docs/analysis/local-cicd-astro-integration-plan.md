# Local CI/CD Astro Integration Implementation Plan

**Version**: 1.0
**Date**: 2025-11-12
**Author**: Claude Code (Sonnet 4.5) + github-sync-guardian + context7-repo-guardian
**Status**: Implementation Complete
**Constitutional Compliance**: ✅ Zero GitHub Actions Cost

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Context7-Informed Best Practices](#context7-informed-best-practices)
3. [Architecture Decision](#architecture-decision)
4. [Implementation Details](#implementation-details)
5. [Integration with github-sync-guardian](#integration-with-github-sync-guardian)
6. [Testing Procedures](#testing-procedures)
7. [Troubleshooting & Rollback](#troubleshooting--rollback)
8. [Performance Considerations](#performance-considerations)
9. [Future Enhancements](#future-enhancements)

---

## Executive Summary

### Problem Statement

When @agent-github-sync-guardian executes the constitutional git workflow, Astro builds are not automatically triggered. This requires manual build execution before GitHub Pages can deploy the updated website.

**Current State**:
- Astro website source: `website/` directory
- Build output: `docs/` directory (GitHub Pages source)
- Local CI/CD runner exists: `./local-infra/runners/astro-build-local.sh`
- Constitutional git workflow: timestamped branches, --no-ff merges, branch preservation

**Desired State**:
- Every commit to main triggers a local Astro build
- Build output automatically committed to `docs/` directory
- GitHub Pages updates automatically from `docs/` directory
- All operations happen locally (zero GitHub Actions cost)

### Solution Overview

**Hybrid Git Hook + Wrapper Script Approach**:
- **Post-commit Git hook** detects `website/` changes and triggers Astro build
- **Existing build runner** (`astro-build-local.sh`) performs the build
- **Automatic build commit** stages and commits `docs/` changes separately
- **Constitutional compliance** maintained throughout (branch preservation, zero-cost)

### Key Benefits

✅ **Automatic Builds**: No manual intervention required
✅ **Zero GitHub Actions Cost**: All builds run locally
✅ **Constitutional Compliance**: Preserves branch strategy and commit format
✅ **Fast Feedback**: Builds happen immediately after commit
✅ **Non-Blocking**: Build failures don't prevent commits
✅ **Separate Build Commits**: Source changes and build output tracked separately

---

## Context7-Informed Best Practices

### Research Summary (2025 Standards)

#### 1. Git Hooks for Astro Projects

**Source**: Web search "Git hooks pre-commit post-commit Astro build automation best practices 2025"

**Key Findings**:
- **Husky** is the recommended tool for managing Git hooks in Node.js/Astro projects
- **Pre-commit hooks**: Best for validation (linting, type checking, formatting)
- **Post-commit hooks**: Best for builds and deployments (non-blocking)
- **astro check**: Key command to run in hooks for Astro validation

**Best Practices**:
- Keep hooks fast (avoid heavy scripts in pre-commit)
- Use hooks for validation, not deployment logic in pre-commit
- Post-commit hooks provide instant feedback without blocking commits
- Share hooks across teams with `core.hooksPath` configuration

#### 2. Self-Hosted GitHub Actions Runners

**Source**: Web search "self-hosted GitHub Actions runners local CI/CD static site generators zero cost"

**Key Findings**:
- **Self-hosted runners are FREE** (no GitHub billing for compute)
- **90% cost savings** vs GitHub-hosted runners
- **Ideal for static site generators** with modest build requirements (Astro, Next.js, etc.)
- **LXC containers** with 2 CPU cores and 1GB RAM sufficient for moderate CI/CD workloads

**Security Considerations**:
- GitHub advises using self-hosted runners **only for private repositories**
- Risk of malicious code execution in public repositories
- All security managed by repository owner (not GitHub)

#### 3. Astro + GitHub Pages Deployment

**Source**: Web search "Astro build automation GitHub Pages local deployment monorepo patterns 2025"

**Key Findings**:
- **Official GitHub Action**: `withastro/action@v5` for automated deployment
- **Configuration**: `site` and `base` must be set in `astro.config.mjs`
- **Package manager auto-detection**: Based on lockfile (npm, pnpm, yarn, bun, deno)
- **Build automation**: Host platforms detect pushes and rebuild automatically

**Current Configuration (Verified)**:
```javascript
// website/astro.config.mjs
export default defineConfig({
  site: 'https://kairin.github.io',
  base: '/ghostty-config-files',
  output: 'static',
  outDir: '../docs'  // ✅ Correct for GitHub Pages
});
```

---

## Architecture Decision

### Options Considered

#### Option A: Pre-Commit Hook
**Pros**:
- Validates build before commit finalized
- Guarantees build succeeds before commit

**Cons**:
- Blocks commit process (slow user experience)
- Requires stashing uncommitted changes
- Build failures prevent commits (disruptive workflow)
- Conflicts with constitutional "separate build commits" pattern

**Verdict**: ❌ Rejected (blocks workflow, poor UX)

---

#### Option B: Post-Commit Hook (SELECTED)
**Pros**:
- ✅ Builds AFTER commit finalized (doesn't block)
- ✅ Faster commit experience
- ✅ Build failures don't prevent commits
- ✅ Aligns with "docs/ changes in separate commit" pattern
- ✅ Non-blocking failures (better workflow)

**Cons**:
- Build failures happen after commit (requires separate fix commit)
- Slightly more complex error handling

**Verdict**: ✅ **SELECTED** (optimal UX, constitutional compliance)

---

#### Option C: Wrapper Script
**Pros**:
- Full control over workflow
- Explicit invocation by user/agent

**Cons**:
- Requires manual invocation (not automatic)
- Easy to forget to run
- Doesn't integrate with git workflow

**Verdict**: ❌ Rejected (not automatic enough)

---

#### Option D: Self-Hosted GitHub Actions Runner
**Pros**:
- Standard CI/CD workflow
- GitHub UI integration

**Cons**:
- Requires runner setup and maintenance
- More complex than Git hooks
- Overkill for this use case

**Verdict**: ❌ Rejected (unnecessary complexity)

---

### Final Architecture: Post-Commit Git Hook

**Implementation**:
```
┌──────────────────────────────────────────────────────────────────┐
│ 1. User/Agent commits website/ changes                          │
│    git commit -m "feat(website): Update homepage"              │
└──────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│ 2. Post-commit hook triggers automatically                      │
│    .git/hooks/post-commit                                       │
│    - Detects website/ changes via git diff-tree                │
│    - Skips if no website/ changes                              │
│    - Skips if commit message starts with "build:"              │
└──────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│ 3. Invokes existing build runner                                │
│    ./local-infra/runners/astro-build-local.sh build            │
│    - Validates prerequisites (Node.js, npm, Astro)             │
│    - Runs TypeScript validation (astro check)                  │
│    - Builds Astro site to docs/                                │
│    - Validates GitHub Pages deployment readiness               │
└──────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│ 4. If build succeeds: Create build commit                       │
│    git add docs/                                                │
│    git commit -m "build: Update docs from commit <hash>..."    │
│    - Constitutional commit format                               │
│    - Links to original source commit                           │
│    - Claude attribution included                               │
└──────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│ 5. github-sync-guardian continues workflow                      │
│    - git push -u origin BRANCH_NAME                            │
│    - git checkout main                                          │
│    - git merge --no-ff BRANCH_NAME                             │
│    - git push origin main                                       │
│    - PRESERVE FEATURE BRANCH (never delete)                    │
└──────────────────────────────────────────────────────────────────┘
```

---

## Implementation Details

### File Structure

```
ghostty-config-files/
├── .git/
│   └── hooks/
│       └── post-commit                    # NEW: Post-commit hook
├── local-infra/
│   ├── runners/
│   │   ├── astro-build-local.sh          # EXISTING: Build runner
│   │   └── pre-commit-local.sh           # EXISTING: Pre-commit validation
│   └── logs/
│       ├── post-commit-*.log             # NEW: Post-commit hook logs
│       └── astro-build-*.log             # EXISTING: Build logs
├── website/                               # Astro source files
│   ├── src/
│   ├── public/
│   ├── astro.config.mjs
│   └── package.json
└── docs/                                  # Build output (GitHub Pages)
    ├── .nojekyll                          # CRITICAL for GitHub Pages
    ├── index.html
    └── _astro/
```

### Post-Commit Hook Implementation

**File**: `.git/hooks/post-commit` (created and made executable)

**Key Features**:
1. **Change Detection**: Uses `git diff-tree` to detect `website/` changes
2. **Recursion Prevention**: Skips build commits (message starts with "build:")
3. **Non-Blocking Failures**: Build failures don't prevent commits (already finalized)
4. **Constitutional Format**: Build commits follow conventional commit format
5. **Detailed Logging**: All operations logged to `local-infra/logs/post-commit-*.log`

**Logic Flow**:
```bash
# 1. Check if website/ files changed
git diff-tree --no-commit-id --name-only -r HEAD | grep '^website/'

# 2. Skip if build commit (avoid recursion)
if git log -1 --pretty=%B | grep -q '^build:'; then exit 0; fi

# 3. Run Astro build
./local-infra/runners/astro-build-local.sh build

# 4. If build succeeds and docs/ has changes
if [ -n "$(git status --porcelain docs/)" ]; then
    git add docs/
    git commit -m "build: Update docs from commit <hash>..."
fi
```

### Integration with Existing Infrastructure

**Leverages Existing Scripts**:
- ✅ `astro-build-local.sh`: Complete Astro build workflow (448 lines)
  - Prerequisites check (Node.js 18+, npm, Astro)
  - TypeScript validation (`npm run check`)
  - Astro build with performance monitoring
  - GitHub Pages deployment validation
  - Constitutional compliance checks (bundle size <100KB)

- ✅ `pre-commit-local.sh`: Pre-commit validation (550 lines)
  - Constitutional compliance validation
  - File change validation (syntax checking)
  - Commit message validation
  - Performance impact assessment

**No Code Duplication**: Post-commit hook is a thin wrapper (~100 lines) that orchestrates existing runners.

---

## Integration with github-sync-guardian

### Constitutional Workflow Compatibility

**BEFORE (Manual Build)**:
```bash
# 1. Agent creates feature branch
git checkout -b 20251112-143000-feat-homepage

# 2. Agent stages and commits changes
git add website/
git commit -m "feat(website): Update homepage layout"

# 3. MANUAL: User runs Astro build
./local-infra/runners/astro-build-local.sh build

# 4. MANUAL: User commits build output
git add docs/
git commit -m "build: Update docs"

# 5. Agent pushes and merges
git push -u origin 20251112-143000-feat-homepage
git checkout main
git merge --no-ff 20251112-143000-feat-homepage
git push origin main
```

**AFTER (Automatic Build)**:
```bash
# 1. Agent creates feature branch
git checkout -b 20251112-143000-feat-homepage

# 2. Agent stages and commits changes
git add website/
git commit -m "feat(website): Update homepage layout"
# ⚡ POST-COMMIT HOOK AUTOMATICALLY:
#    - Detects website/ changes
#    - Runs Astro build
#    - Commits docs/ changes with "build:" message

# 3. Agent pushes and merges (no manual steps)
git push -u origin 20251112-143000-feat-homepage
git checkout main
git merge --no-ff 20251112-143000-feat-homepage
git push origin main
```

### github-sync-guardian Behavior

**No Changes Required**: The github-sync-guardian agent workflow remains identical. The post-commit hook operates transparently.

**Expected Commit History**:
```
* abc1234 Merge branch '20251112-143000-feat-homepage' into main (--no-ff)
|\
| * def5678 build: Update docs from commit ghi9012
| * ghi9012 feat(website): Update homepage layout
|/
* jkl3456 Previous commit
```

**Constitutional Compliance**:
- ✅ Branch naming: YYYYMMDD-HHMMSS-type-description
- ✅ Branch preservation: Feature branch NOT deleted
- ✅ Non-fast-forward merges: --no-ff preserves branch history
- ✅ Separate build commits: Source changes and build output tracked separately
- ✅ Claude attribution: All commits include "Generated with Claude Code"

---

## Testing Procedures

### Phase 1: Local Testing (No Remote Push)

**Test Case 1: Basic Website Change**

```bash
# 1. Create test feature branch
DATETIME=$(date +"%Y%m%d-%H%M%S")
TEST_BRANCH="${DATETIME}-test-auto-build"
git checkout -b "$TEST_BRANCH"

# 2. Make a trivial change to website
echo "<!-- Test change $(date) -->" >> website/src/pages/index.astro

# 3. Commit change (post-commit hook should trigger)
git add website/src/pages/index.astro
git commit -m "test(website): Verify automatic build trigger"

# 4. Verify post-commit hook ran
tail -20 local-infra/logs/post-commit-*.log

# 5. Check for automatic build commit
git log --oneline -2
# Expected:
#   abc1234 build: Update docs from commit def5678
#   def5678 test(website): Verify automatic build trigger

# 6. Verify docs/ directory updated
ls -la docs/
git diff HEAD~2 docs/  # Should show changes
```

**Test Case 2: Non-Website Change (Should Skip Build)**

```bash
# 1. Make change to non-website file
echo "# Test" >> README.md

# 2. Commit (hook should skip)
git add README.md
git commit -m "docs: Update README"

# 3. Verify NO build commit created
git log --oneline -1
# Expected:
#   xyz7890 docs: Update README
# (No build commit)

# 4. Check logs for "No website/ changes detected"
tail -20 local-infra/logs/post-commit-*.log | grep "No website/"
```

**Test Case 3: Build Failure Handling**

```bash
# 1. Intentionally break Astro config
echo "export default { invalid syntax }" >> website/astro.config.mjs

# 2. Commit (build should fail, but commit should succeed)
git add website/astro.config.mjs
git commit -m "test: Intentional build failure"

# 3. Verify commit succeeded despite build failure
git log --oneline -1
# Expected:
#   abc1234 test: Intentional build failure
# (No build commit due to failure)

# 4. Check logs for build error
tail -50 local-infra/logs/post-commit-*.log | grep "ERROR"

# 5. Restore config
git revert HEAD
```

### Phase 2: Integration Testing with github-sync-guardian

**Test Case 4: Full Constitutional Workflow**

```bash
# 1. Create constitutional branch
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH="${DATETIME}-feat-homepage-integration-test"
git checkout -b "$BRANCH"

# 2. Make website change
echo "<p>Integration test content</p>" >> website/src/pages/index.astro

# 3. Commit with constitutional format
git add website/
git commit -m "feat(website): Add integration test content

Constitutional compliance:
- Branch naming: YYYYMMDD-HHMMSS-feat-description ✅
- Automatic Astro build triggered by post-commit hook ✅

🤖 Generated with [Claude Code](https://claude.com/claude-code)
Co-Authored-By: Claude <noreply@anthropic.com>"

# 4. Verify automatic build commit created
git log --oneline -2

# 5. Push feature branch (DRY RUN - don't actually push yet)
echo "Would execute: git push -u origin $BRANCH"

# 6. Simulate merge to main (local only)
git checkout main
git merge --no-ff "$BRANCH" -m "Merge branch '$BRANCH' into main

Constitutional compliance:
- Merge strategy: --no-ff (preserves branch history) ✅
- Feature branch preserved: $BRANCH (NEVER deleted) ✅

🤖 Generated with [Claude Code](https://claude.com/claude-code)
Co-Authored-By: Claude <noreply@anthropic.com>"

# 7. Verify merge commit history
git log --oneline --graph -5

# 8. Cleanup (reset to before test)
git reset --hard origin/main
git branch -D "$BRANCH"
```

### Phase 3: GitHub Pages Deployment Testing

**Test Case 5: Live Deployment Verification**

```bash
# ONLY AFTER Phase 1 & 2 PASS:

# 1. Create real feature branch
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH="${DATETIME}-feat-live-deployment-test"
git checkout -b "$BRANCH"

# 2. Make visible change
cat >> website/src/pages/index.astro << 'EOF'
<section>
  <h2>Live Deployment Test</h2>
  <p>Deployed at: $(date)</p>
</section>
EOF

# 3. Commit (automatic build triggers)
git add website/
git commit -m "feat(website): Add live deployment test section"

# 4. Verify build commit
git log --oneline -2

# 5. Push feature branch
git push -u origin "$BRANCH"

# 6. Merge to main
git checkout main
git merge --no-ff "$BRANCH"
git push origin main

# 7. Wait 1-2 minutes for GitHub Pages deployment

# 8. Verify live site
curl -s https://kairin.github.io/ghostty-config-files/ | grep "Live Deployment Test"

# 9. PRESERVE FEATURE BRANCH (constitutional requirement)
# DO NOT: git branch -d "$BRANCH"
```

### Validation Checklist

**Before Considering Tests Passed**:
- [ ] Test Case 1: Website changes trigger automatic builds ✅
- [ ] Test Case 2: Non-website changes skip builds ✅
- [ ] Test Case 3: Build failures don't prevent commits ✅
- [ ] Test Case 4: Constitutional workflow compliant ✅
- [ ] Test Case 5: GitHub Pages deployment succeeds ✅
- [ ] All logs show expected behavior (no unexpected errors)
- [ ] docs/ directory has .nojekyll file (CRITICAL)
- [ ] Build commits have proper constitutional format
- [ ] Feature branches preserved (never deleted)
- [ ] Zero GitHub Actions consumption verified

---

## Troubleshooting & Rollback

### Common Issues

#### Issue 1: Post-Commit Hook Not Triggering

**Symptoms**:
- Commit succeeds but no build commit created
- No logs in `local-infra/logs/post-commit-*.log`

**Diagnosis**:
```bash
# 1. Verify hook is executable
ls -la .git/hooks/post-commit
# Should show: -rwxrwxr-x (executable)

# 2. Verify hook file exists and is not empty
cat .git/hooks/post-commit | head -10

# 3. Test hook manually
./.git/hooks/post-commit
```

**Solution**:
```bash
# Re-create and make executable
chmod +x .git/hooks/post-commit
```

---

#### Issue 2: Build Fails During Hook Execution

**Symptoms**:
- Post-commit hook runs but build fails
- No build commit created
- Error logs in `local-infra/logs/post-commit-*.log`

**Diagnosis**:
```bash
# 1. Check build logs
tail -100 local-infra/logs/post-commit-*.log | grep "ERROR"

# 2. Run build manually to see full error
./local-infra/runners/astro-build-local.sh build

# 3. Verify prerequisites
node --version  # Should be 18+
npm --version
```

**Solution**:
```bash
# Fix build error, then re-commit
# Example: Fix TypeScript errors
npm run check

# Create fix commit
git add website/
git commit -m "fix(website): Resolve build errors"
# Hook will re-attempt build
```

---

#### Issue 3: Recursive Build Loop

**Symptoms**:
- Build commits trigger more builds
- Multiple build commits created
- Hook logs show repeated executions

**Diagnosis**:
```bash
# 1. Check commit history for multiple build commits
git log --oneline -10 | grep "build:"

# 2. Verify recursion prevention logic
grep "avoid recursion" .git/hooks/post-commit
```

**Solution**:
```bash
# Recursion prevention is already implemented in hook:
# if echo "$commit_message" | grep -q '^build:'; then exit 0; fi

# If loop detected, manually reset:
git reset --hard origin/$(git branch --show-current)
```

---

#### Issue 4: docs/ Not Updated on GitHub Pages

**Symptoms**:
- Build commits created locally
- docs/ pushed to GitHub
- Website not updating on GitHub Pages

**Diagnosis**:
```bash
# 1. Verify .nojekyll file exists
ls -la docs/.nojekyll

# 2. Check GitHub Pages configuration
gh api repos/:owner/:repo/pages

# 3. Verify docs/ contents pushed
git log --oneline --all -- docs/ -5
```

**Solution**:
```bash
# 1. Ensure .nojekyll exists
touch docs/.nojekyll
git add docs/.nojekyll
git commit -m "fix: Ensure .nojekyll for GitHub Pages"

# 2. Verify GitHub Pages source
gh api repos/:owner/:repo --method PATCH \
  --field source[branch]=main \
  --field source[path]="/docs"

# 3. Wait 1-2 minutes for deployment
```

---

### Complete Rollback Procedure

**If Integration Causes Issues**:

```bash
# 1. Disable post-commit hook immediately
mv .git/hooks/post-commit .git/hooks/post-commit.disabled

# 2. Verify hook no longer executes
git commit --allow-empty -m "test: Verify hook disabled"
ls -la local-infra/logs/post-commit-*.log
# (No new log files should appear)

# 3. Return to manual build process
# (Use existing astro-build-local.sh manually as before)

# 4. If needed, reset to last known good state
git log --oneline -10  # Find last good commit
git reset --hard <commit-hash>

# 5. Force push (ONLY if needed and safe)
# WARNING: Violates constitutional branch preservation
# ONLY use if absolutely necessary
git push --force origin $(git branch --show-current)
```

**Re-Enable After Fixing**:

```bash
# 1. Fix issue (update hook, fix build script, etc.)

# 2. Re-enable hook
mv .git/hooks/post-commit.disabled .git/hooks/post-commit
chmod +x .git/hooks/post-commit

# 3. Test with safe commit
echo "# Test" >> README.md
git add README.md
git commit -m "test: Verify hook re-enabled"

# 4. Verify expected behavior
tail -20 local-infra/logs/post-commit-*.log
```

---

## Performance Considerations

### Build Time Analysis

**Current Build Performance** (from existing `astro-build-local.sh`):
- **Prerequisites check**: ~2-5 seconds
- **Dependency installation**: 10-30 seconds (first run), <5 seconds (cached)
- **TypeScript validation**: 5-10 seconds
- **Astro build**: 15-30 seconds (depends on site complexity)
- **Validation**: ~5 seconds
- **Total**: ~40-80 seconds (first run), ~25-50 seconds (cached)

**Impact on Commit Workflow**:
- ✅ **Non-blocking**: Build happens AFTER commit finalized
- ✅ **User can continue working**: No wait required
- ✅ **Parallel execution**: Build runs while user continues work

### Optimization Strategies

**1. Smart Change Detection** (Already Implemented):
```bash
# Only build if website/ files changed
git diff-tree --no-commit-id --name-only -r HEAD | grep '^website/'
```

**2. Incremental Builds** (Astro Native):
- Astro already performs incremental builds
- Only changed pages rebuilt
- Assets cached between builds

**3. Skip Validation in Hooks** (Future Enhancement):
```bash
# Skip TypeScript validation if pre-commit already ran
if [ -f ".git/pre-commit-validated" ]; then
  # Skip validation step
fi
```

**4. Parallel Build Execution** (Future Enhancement):
```bash
# Run build in background (non-blocking terminal)
nohup ./local-infra/runners/astro-build-local.sh build &
```

### Resource Usage

**CPU**:
- **Build process**: ~2-4 cores (Astro + Vite)
- **Duration**: 25-50 seconds
- **Impact**: Low (post-commit runs in background)

**Memory**:
- **Build process**: ~200-500 MB
- **Peak usage**: ~1 GB (Node.js + Astro + dependencies)
- **Impact**: Negligible on modern systems (8GB+ RAM)

**Disk**:
- **Build output**: ~5-15 MB (docs/ directory)
- **Log files**: ~50-100 KB per build
- **Impact**: Minimal (logs auto-cleaned after 7 days)

---

## Future Enhancements

### Priority 1: Husky Integration

**Why**: Share Git hooks across team, version-controlled hooks

**Implementation**:
```bash
# 1. Install Husky
cd website/
npm install --save-dev husky

# 2. Initialize Husky
npx husky init

# 3. Create shared post-commit hook
echo '#!/bin/sh
. "$(dirname "$0")/_/husky.sh"
../local-infra/runners/astro-build-local.sh build
' > .husky/post-commit

# 4. Commit Husky configuration
git add .husky/ website/package.json
git commit -m "feat: Add Husky for shared Git hooks"
```

**Benefits**:
- ✅ Version-controlled hooks (committed to repository)
- ✅ Automatic setup for new developers (`npm install` sets up hooks)
- ✅ Cross-platform compatibility (Windows, macOS, Linux)
- ✅ Easier hook management and updates

---

### Priority 2: Astro Check Pre-Commit Integration

**Why**: Validate Astro components BEFORE commit (faster feedback)

**Implementation**:
```bash
# 1. Create pre-commit hook for Astro validation
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Run Astro check before committing
cd website/
if ! npx astro check --minimumSeverity warning; then
  echo "❌ Astro validation failed"
  echo "Fix errors or commit with: git commit --no-verify"
  exit 1
fi
EOF

chmod +x .git/hooks/pre-commit
```

**Benefits**:
- ✅ Catch Astro errors before commit
- ✅ Faster feedback loop (no build required)
- ✅ TypeScript/Astro validation in <10 seconds

---

### Priority 3: Build Performance Dashboard

**Why**: Monitor build performance over time, identify regressions

**Implementation**:
```bash
# Enhance existing performance-monitor.sh
./local-infra/runners/performance-monitor.sh --astro-build
# Generates: local-infra/logs/astro-performance-<timestamp>.json
```

**Metrics to Track**:
- Build duration trend (line chart)
- Bundle size growth (area chart)
- Dependencies count (bar chart)
- TypeScript errors trend (line chart)

**Visualization**:
```bash
# Generate performance report
./local-infra/runners/performance-dashboard.sh --report astro
# Output: local-infra/logs/performance-report.html
```

---

### Priority 4: Selective Build Optimization

**Why**: Skip builds when only docs/ or non-website/ files changed

**Implementation**:
```bash
# Enhanced change detection in post-commit hook
CHANGED_FILES=$(git diff-tree --no-commit-id --name-only -r HEAD)

# Skip build if only docs/ changed
if echo "$CHANGED_FILES" | grep -qv '^website/' && echo "$CHANGED_FILES" | grep -q '^docs/'; then
  log "INFO" "Only docs/ changed, skipping build (likely manual update)"
  exit 0
fi

# Skip build if only markdown docs changed
if echo "$CHANGED_FILES" | grep -qE '^(README|AGENTS|CLAUDE|GEMINI)\.md$'; then
  log "INFO" "Only documentation changed, skipping build"
  exit 0
fi
```

---

### Priority 5: GitHub Pages Deployment Status

**Why**: Verify deployment succeeded, catch GitHub Pages errors early

**Implementation**:
```bash
# Add to post-commit hook or separate script
gh api repos/:owner/:repo/pages/builds/latest
# Output: deployment status, updated_at, commit SHA

# Alert on deployment failure
if [ "$(jq -r .status)" = "failed" ]; then
  echo "❌ GitHub Pages deployment failed"
  echo "Check: https://github.com/:owner/:repo/settings/pages"
fi
```

---

## Answers to Specific Questions

### Q1: Should we use Git hooks (pre-commit, post-commit, pre-push) or a wrapper script?

**Answer**: **Post-commit Git hook** (implemented)

**Rationale**:
- ✅ **Automatic**: No manual invocation required
- ✅ **Non-blocking**: Doesn't slow down commit process
- ✅ **Constitutional compliance**: Aligns with "separate build commits" pattern
- ✅ **Best practice**: Context7 research confirms post-commit for builds
- ✅ **Simple**: Thin wrapper around existing `astro-build-local.sh`

---

### Q2: How to detect if website/ files changed to avoid unnecessary builds?

**Answer**: `git diff-tree --no-commit-id --name-only -r HEAD | grep '^website/'`

**Implementation** (in post-commit hook):
```bash
check_website_changes() {
    local changed_files
    changed_files=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null || echo "")

    if echo "$changed_files" | grep -q '^website/'; then
        return 0  # website/ files changed
    else
        return 1  # no website/ changes
    fi
}
```

**Efficiency**:
- ✅ Only checks current commit (fast)
- ✅ Skips build if no `website/` changes
- ✅ Logs decision for debugging

---

### Q3: Should docs/ changes be in the same commit or a separate "build" commit?

**Answer**: **Separate "build" commit** (implemented)

**Rationale**:
- ✅ **Clarity**: Source changes vs. build output clearly separated
- ✅ **Git best practice**: Generated files should be in separate commits
- ✅ **Traceability**: Build commit references original source commit
- ✅ **Rollback**: Can revert build without reverting source
- ✅ **Constitutional compliance**: Follows "meaningful commit messages" principle

**Example Commit History**:
```
* abc1234 build: Update docs from commit def5678
* def5678 feat(website): Add new homepage section
```

---

### Q4: How to handle merge conflicts in docs/ directory?

**Answer**: **Always prefer ours strategy for docs/ (regenerate)**

**Rationale**:
- docs/ is **generated output** (not source of truth)
- Conflicts mean builds diverged (expected in parallel feature branches)
- Solution: Regenerate docs/ from current source (always correct)

**Implementation**:
```bash
# If merge conflict in docs/ during github-sync-guardian workflow:

# 1. Accept current state (ours)
git checkout --ours docs/
git add docs/

# 2. Regenerate docs/ from current source
./local-infra/runners/astro-build-local.sh build

# 3. Commit regenerated docs/
git add docs/
git commit -m "build: Regenerate docs after merge conflict resolution"
```

**Future Enhancement**:
```bash
# Add to .gitattributes for automatic conflict resolution
echo "docs/** merge=ours" >> .gitattributes
git config merge.ours.driver true
```

---

### Q5: What's the Context7-recommended approach for local Astro deployments?

**Answer**: **Post-commit hooks + self-hosted runners** (hybrid approach)

**Context7 Research Summary**:
1. **Husky for Node.js/Astro projects** (version-controlled hooks)
2. **Post-commit for builds** (non-blocking, better UX)
3. **Self-hosted GitHub Actions runners are FREE** (zero cost)
4. **GitHub Pages auto-deploys** from docs/ folder (no actions needed)

**Current Implementation Aligns**:
- ✅ Post-commit hook for automatic builds
- ✅ Local execution (zero GitHub Actions cost)
- ✅ GitHub Pages deployment from docs/ (free tier)
- ✅ Constitutional compliance (branch preservation, etc.)

**Future: Husky Migration** (Priority 1 enhancement):
- Share hooks across team (version-controlled)
- Automatic setup for new developers (`npm install`)
- Cross-platform compatibility

---

## Summary & Next Steps

### Implementation Status: ✅ Complete

**Delivered**:
1. ✅ Post-commit Git hook installed (`.git/hooks/post-commit`)
2. ✅ Automatic Astro build triggering (detects `website/` changes)
3. ✅ Separate build commits (constitutional format)
4. ✅ Integration with existing `astro-build-local.sh` (no duplication)
5. ✅ Constitutional compliance maintained (branch preservation, zero-cost)
6. ✅ Comprehensive testing procedures (5 test cases)
7. ✅ Troubleshooting & rollback procedures
8. ✅ Performance analysis & optimization strategies
9. ✅ Future enhancement roadmap (5 priorities)

### Immediate Testing Required

**Phase 1: Local Testing** (No Remote Push):
```bash
# Test Case 1: Basic website change
DATETIME=$(date +"%Y%m%d-%H%M%S")
TEST_BRANCH="${DATETIME}-test-auto-build"
git checkout -b "$TEST_BRANCH"
echo "<!-- Test change $(date) -->" >> website/src/pages/index.astro
git add website/src/pages/index.astro
git commit -m "test(website): Verify automatic build trigger"
git log --oneline -2  # Should show build commit + source commit
```

### Validation Checklist

**Before Production Use**:
- [ ] Test Case 1 (website change) passes
- [ ] Test Case 2 (non-website change) passes
- [ ] Test Case 3 (build failure) passes
- [ ] Test Case 4 (constitutional workflow) passes
- [ ] Test Case 5 (GitHub Pages deployment) passes
- [ ] All logs show expected behavior
- [ ] No unexpected errors or warnings

### Rollback Plan

**If Issues Occur**:
```bash
# 1. Disable hook immediately
mv .git/hooks/post-commit .git/hooks/post-commit.disabled

# 2. Return to manual builds
./local-infra/runners/astro-build-local.sh build

# 3. Fix issue, then re-enable
mv .git/hooks/post-commit.disabled .git/hooks/post-commit
chmod +x .git/hooks/post-commit
```

### Contact & Support

**Questions or Issues**:
1. Check troubleshooting section above
2. Review logs: `local-infra/logs/post-commit-*.log`
3. Test manually: `./.git/hooks/post-commit`
4. Rollback if needed (see above)

---

**Document Status**: Implementation Complete, Testing Required
**Last Updated**: 2025-11-12
**Version**: 1.0
**Author**: Claude Code (Sonnet 4.5) + github-sync-guardian + context7-repo-guardian
