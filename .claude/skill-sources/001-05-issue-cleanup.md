---
description: "Close GitHub issues after PR merge when auto-close fails"
handoffs:
  - label: "Full Workflow"
    prompt: "Run /001-04-full-workflow for complete development cycle"
---

# Issue Cleanup

Close GitHub issues that should have been auto-closed by a PR merge but weren't due to GitHub's limit on auto-closing.

## When to Use

- After merging a PR that references multiple issues (GitHub limits auto-close to ~6 issues)
- When `gh issue list --state open` shows issues that should be closed
- After `/001-04-full-workflow` or `/001-03-git-sync` when open issues remain
- After `/speckit.taskstoissues` tasks are complete and merged

## Instructions

When the user invokes `/001-issue-cleanup`, execute the following steps to ensure the repository has no stale open issues.

### Step 1: Check Repository Status

```bash
# Get repo info from git remote
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

# Count open issues
OPEN_COUNT=$(gh issue list --state open --json number | jq 'length')

# Count open PRs
PR_COUNT=$(gh pr list --state open --json number | jq 'length')
```

Report current state:
- If 0 open issues AND 0 open PRs: Report "Repository clean" and exit early
- Otherwise: Continue to identification

### Step 2: List Open Issues

```bash
# List all open issues with details
gh issue list --state open --json number,title,labels --jq '.[] | "\(.number)|\(.title[0:60])|\(.labels | map(.name) | join(","))"'
```

Display issues grouped by:
- **Feature label** (e.g., `006-tui-detail-views`)
- **Title pattern** (e.g., `[T0xx]` for task issues)
- **Other** (unrelated issues)

### Step 3: Find Related PR

```bash
# List recent merged PRs
gh pr list --state merged --limit 10 --json number,title,mergeCommit --jq '.[] | "\(.number)|\(.title[0:50])|\(.mergeCommit.oid[0:8])"'
```

Ask user which PR the issues relate to, or auto-detect if issues have a feature label matching a PR title.

### Step 4: Get Merge Commit

```bash
# Get merge commit SHA for the PR
MERGE_SHA=$(gh pr view PR_NUMBER --json mergeCommit --jq '.mergeCommit.oid')
```

### Step 5: User Confirmation

Ask user how to handle the open issues:

- **Close all**: Bulk close all identified issues with a comment
- **Close via comment**: Add explanatory comment linking to merge, then close
- **Review each**: Show each issue and ask individually
- **Leave open**: Skip closing, just report status

### Step 6: Close Issues

For each issue to close:

```bash
MERGE_SHA="<merge-commit-sha>"
PR_NUMBER="<pr-number>"
COMMENT="Completed via PR #${PR_NUMBER} (merge commit: ${MERGE_SHA})

All tasks were implemented and merged to main on $(date +%Y-%m-%d)."

# Close with comment
gh issue close ISSUE_NUMBER --comment "$COMMENT"
```

**Rate limiting**: If closing many issues, pause briefly between closures to avoid rate limits.

### Step 7: Verification

```bash
# Confirm all closed
echo "=== Open Issues ==="
gh issue list --state open --json number | jq 'length'

echo "=== Open PRs ==="
gh pr list --state open --json number | jq 'length'
```

## Output Format

```
=====================================
ISSUE CLEANUP REPORT
=====================================
Repository: kairin/ghostty-config-files
Branch: main

Initial State:
--------------
Open Issues: 38
Open PRs: 0

Related PR: #63 (feat(tui): implement ViewToolDetail)
Merge Commit: 77762bbb14f25f96e822dbcf9475c7f4cf20447c

Issues Identified:
------------------
- By label (006-tui-detail-views): 30
- By pattern ([T0xx]): 8
- Other: 0

Issues Processed:
-----------------
| Action  | Count | Details              |
|---------|-------|----------------------|
| Closed  | 38    | #20-#28, #29-#62     |
| Skipped | 6     | Already closed by PR |
| Errors  | 0     | -                    |

Comment Added:
--------------
"Completed via PR #63 (merge: 77762bbb...)
All tasks were implemented and merged to main."

Final State:
------------
Open Issues: 0
Open PRs: 0

Result: REPOSITORY CLEAN
=====================================
```

## Error Handling

| Error | Response |
|-------|----------|
| No open issues | Report "Repository already clean", exit |
| PR not merged | Warn user, confirm before proceeding |
| gh CLI not authenticated | Suggest `gh auth login` |
| Issue close fails | Report error, continue with others |
| Rate limited | Wait and retry |

## Constitutional Compliance

- **Read-only first**: Always list issues before taking action
- **User confirmation**: Never bulk-close without explicit approval
- **Audit trail**: Every closed issue gets a comment with merge reference
- **Non-destructive**: Closing issues is reversible (can reopen)

## Integration with Other Skills

This skill complements the workflow:

```
/001-04-full-workflow
       │
       ├── Health Check
       ├── Build & Deploy
       ├── Git Sync
       │
       └── (manual) /001-05-issue-cleanup  ← Run if open issues remain
```

**Recommended workflow after PR merge:**
1. Run `/001-04-full-workflow` or `/001-03-git-sync`
2. Check for open issues: `gh issue list --state open`
3. If issues remain, run `/001-05-issue-cleanup`

**Always include this in your output:**
```
Next Skill:
-----------
→ /001-04-full-workflow - Complete development cycle (for next iteration)
```
