---
description: "Synchronize repository with remote safely"
handoffs:
  - label: "Full Workflow"
    prompt: "Run /001-04-full-workflow for complete development cycle"
---

# Git Sync

Synchronize the local repository with remote safely, respecting constitutional requirements.

## Instructions

When the user invokes `/git-sync`, execute the synchronization steps below. Report progress and handle divergence safely.

## Constitutional Requirements

**CRITICAL - NEVER VIOLATE:**
- **NEVER delete branches** - All branches must be preserved
- **Branch naming**: Validate YYYYMMDD-HHMMSS-type-description format
- **No force push** - If push is rejected, alert user
- **Stop on divergence** - Always ask user for resolution strategy

## Workflow Steps

### Step 1: Pre-Flight Status Check

```bash
git status
git branch -vv
```

Report:
- Uncommitted changes
- Untracked files
- Current branch
- Tracking status

### Step 2: Fetch Remote

```bash
git fetch --all --prune
```

### Step 3: Analyze Sync Status

```bash
# Get current branch
BRANCH=$(git branch --show-current)

# Check if tracking remote
UPSTREAM=$(git rev-parse --abbrev-ref @{u} 2>/dev/null || echo "none")

# Count commits
if [ "$UPSTREAM" != "none" ]; then
  AHEAD=$(git rev-list --count @{u}..HEAD)
  BEHIND=$(git rev-list --count HEAD..@{u})
fi
```

Determine status:
- **up-to-date**: AHEAD=0 and BEHIND=0
- **ahead**: AHEAD>0 and BEHIND=0
- **behind**: AHEAD=0 and BEHIND>0
- **diverged**: AHEAD>0 and BEHIND>0

### Step 4: Handle Divergence (CRITICAL)

If diverged, **STOP IMMEDIATELY** and show:

```bash
echo "LOCAL COMMITS (not on remote):"
git log --oneline @{u}..HEAD

echo "REMOTE COMMITS (not in local):"
git log --oneline HEAD..@{u}
```

Ask user: "Local and remote have diverged. Choose resolution:"
- **Rebase**: `git pull --rebase`
- **Merge**: `git pull` (creates merge commit)
- **Manual**: Stop and let user resolve

**Do NOT proceed without user decision.**

### Step 5: Pull If Behind

```bash
git pull --rebase
```

Report any conflicts. If conflicts occur, stop and alert user.

### Step 6: Push If Ahead

```bash
git push -u origin $(git branch --show-current)
```

Verify push succeeded.

### Step 7: Validate Branch Name

Check if current branch follows constitutional naming:

```bash
BRANCH=$(git branch --show-current)

# Pattern: YYYYMMDD-HHMMSS-type-description
if [[ "$BRANCH" =~ ^[0-9]{8}-[0-9]{6}-(feat|fix|docs|refactor|test|chore)-[a-z0-9-]+$ ]]; then
  echo "PASS: Branch name follows constitutional format"
else
  echo "WARNING: Branch name does not follow YYYYMMDD-HHMMSS-type-description format"
  echo "Current: $BRANCH"
  echo "Example: 20260118-143052-feat-add-skills"
fi
```

## Output Format

```
=====================================
GIT SYNC REPORT
=====================================
Repository: ghostty-config-files
Branch: 004-claude-skills

Sync Status:
------------
| Metric          | Value           |
|-----------------|-----------------|
| Status          | UP-TO-DATE      |
| Local commits   | 0 ahead         |
| Remote commits  | 0 behind        |
| Upstream        | origin/004-...  |

Branch Validation:
------------------
| Check           | Status          |
|-----------------|-----------------|
| Name format     | WARNING         |
| Tracking        | PASS            |

Actions Taken:
--------------
- Fetched: Yes
- Pulled: Not needed
- Pushed: Already up-to-date

Result: SUCCESS
=====================================
```

## Error Handling

- **Push rejected**: Never force push. Alert user about rejected push.
- **Merge conflicts**: Stop and show conflicting files.
- **Auth failure**: Suggest `gh auth refresh` or credential check.
- **No upstream**: Set upstream with `-u` flag.

## Safety Rules

1. **Never force-push** - If push is rejected, alert user
2. **Never delete branches** - Constitutional requirement
3. **Stop on divergence** - Always ask user for resolution
4. **Preserve history** - Use --no-ff for merges (if merging)

## Next Steps

After successful sync:
- Suggest `/001-04-full-workflow` for complete development cycle
- Show sync summary

**Always include this in your output:**
```
Next Skill:
-----------
→ /001-04-full-workflow - Complete development cycle with validation
```
