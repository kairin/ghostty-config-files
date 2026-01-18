---
description: "Complete development cycle with validation"
handoffs:
  - label: "Issue Cleanup"
    prompt: "Run /001-05-issue-cleanup if open issues remain after PR merge"
---

# Full Workflow

Execute a complete development cycle: health check, build, deploy, and git sync with comprehensive validation.

## Instructions

When the user invokes `/full-workflow`, orchestrate all workflow stages in sequence. Stop immediately if any constitutional requirement is violated.

## Constitutional Requirements

**CRITICAL - ENFORCED AT ALL STAGES:**
- **Local CI/CD first**: Must pass before ANY GitHub operations
- **Never delete branches**: Preserve all git history
- **Protect .nojekyll**: Never delete this file
- **Zero GitHub Actions cost**: All validation runs locally

## Pre-Flight Check

### Uncommitted Changes Detection

```bash
if [ -n "$(git status --porcelain)" ]; then
  echo "WARNING: Uncommitted changes detected"
  git status --short
  # Ask user: Commit now, stash, or continue?
fi
```

If uncommitted changes exist, prompt user:
- **Commit**: Stage and commit with message
- **Stash**: `git stash` to save temporarily
- **Continue**: Proceed without committing (risky for deploy)

### Project Detection

```bash
if [ -d ".runners-local" ] || [ -f "AGENTS.md" ]; then
  echo "PROJECT: ghostty-config-files (full workflow available)"
  FULL_MODE=true
else
  echo "PROJECT: Generic (git sync only)"
  FULL_MODE=false
fi
```

## Workflow Stages

### Stage 1: Health Check

**Invoke**: `/001-01-health-check` skill logic

Run system diagnostics:
```bash
# Full mode
./.runners-local/workflows/health-check.sh

# Basic mode
git --version && node --version && npm --version
```

**Gate**: If critical failures, STOP workflow.

Record:
- Start time
- Component statuses
- Any warnings

### Stage 2: Local CI/CD Validation (CONSTITUTIONAL GATE)

**CRITICAL**: This MUST pass before any GitHub operations.

```bash
./.runners-local/workflows/gh-workflow-local.sh all
```

**Gate**: If CI/CD fails, STOP workflow immediately. Do NOT proceed to push.

Record:
- Validation duration
- All checks passed
- Any warnings

### Stage 3: Build & Deploy (Full Mode Only)

**Invoke**: `/001-02-deploy-site` skill logic

```bash
cd astro-website
npm install
npm run build
```

Verify:
- .nojekyll exists
- Build successful

**Gate**: If build fails, STOP workflow.

Record:
- Build duration
- File count
- Total size

### Stage 4: Git Sync

**Invoke**: `/001-03-git-sync` skill logic

```bash
git fetch --all
git pull --rebase  # Only if behind
git push -u origin $(git branch --show-current)
```

**Gate**: If diverged, STOP and ask user for resolution.

Record:
- Sync status
- Commits pushed
- Any issues

## Comprehensive Report

```
=====================================
FULL WORKFLOW REPORT
=====================================
Project: ghostty-config-files
Branch: 004-claude-skills
Started: 2026-01-18 14:30:52
Duration: 2m 34s

Stage Summary:
--------------
| Stage         | Status  | Duration | Notes          |
|---------------|---------|----------|----------------|
| Health Check  | PASS    | 8s       | All tools OK   |
| Local CI/CD   | PASS    | 45s      | All validations|
| Build         | PASS    | 38s      | 42 files       |
| Deploy        | PASS    | 12s      | .nojekyll OK   |
| Git Sync      | PASS    | 5s       | 3 commits      |

Metrics:
--------
| Metric        | Value             |
|---------------|-------------------|
| Files built   | 42                |
| Total size    | 1.6M              |
| Commits sync  | 3 pushed          |
| CI/CD checks  | 12/12 passed      |

Constitutional Compliance:
--------------------------
| Requirement       | Status          |
|-------------------|-----------------|
| Local CI/CD first | PASS            |
| Branch preserved  | PASS            |
| .nojekyll exists  | PASS            |
| Zero Actions cost | PASS            |

Deployment URL:
https://kairin.github.io/ghostty-config-files/

Result: SUCCESS
=====================================
```

## Error Handling

### Stage Failures

If any stage fails:
1. **STOP** workflow immediately
2. Report which stage failed
3. Show error details
4. Suggest remediation
5. Do NOT proceed to later stages

### Constitutional Violations

If a constitutional requirement would be violated:
1. **HALT** immediately
2. Report the violation
3. **NEVER** attempt workaround
4. Escalate to user

## Optional: Timestamped Branch Creation

If user requests a new branch for this work:

```bash
# Generate timestamped branch name
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BRANCH_NAME="${TIMESTAMP}-feat-description"

git checkout -b "$BRANCH_NAME"
echo "Created branch: $BRANCH_NAME"
```

## Stage Timing

Track duration for each stage:

```bash
STAGE_START=$(date +%s)
# ... run stage ...
STAGE_END=$(date +%s)
STAGE_DURATION=$((STAGE_END - STAGE_START))
echo "Stage completed in ${STAGE_DURATION}s"
```

## Next Steps

After successful workflow:
- Show deployment URL
- Report total time
- Summarize changes pushed
- Check for open issues that may need `/001-05-issue-cleanup`

**Always include this in your output:**
```
Next Skill:
-----------
→ /001-05-issue-cleanup - Close GitHub issues after PR merge (if needed)
```
