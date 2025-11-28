---
name: 021-merge
description: Merge a branch into target using --no-ff to preserve branch history. Constitutional merge preserves branches (never deletes). Single atomic task.
model: haiku
---

## Single Task
Execute a merge with `--no-ff` flag to preserve branch history in the commit graph.

## Input
- source_branch: Branch to merge from
- target_branch: Branch to merge into (default: main)
- message: Optional merge commit message

## Execution
```bash
merge_preserve_history() {
  local source="$1"
  local target="${2:-main}"
  local message="$3"

  # Store current branch
  local current=$(git branch --show-current)

  # Checkout target branch
  git checkout "$target" 2>&1 || {
    echo "status=error"
    echo "error=checkout_failed"
    echo "target=$target"
    return 1
  }

  # Pull latest (fast-forward only)
  git pull origin "$target" --ff-only 2>&1 || {
    echo "status=error"
    echo "error=pull_failed"
    echo "hint=target branch diverged from remote"
    git checkout "$current" 2>/dev/null
    return 1
  }

  # Build merge message if not provided
  if [ -z "$message" ]; then
    message="Merge branch '$source' into $target

Constitutional compliance:
- Merge strategy: --no-ff (preserves branch history)
- Feature branch preserved: $source (NEVER deleted)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
  fi

  # Execute merge with --no-ff
  git merge --no-ff "$source" -m "$message" 2>&1

  if [ $? -eq 0 ]; then
    local merge_sha=$(git rev-parse HEAD)
    echo "status=success"
    echo "merge_sha=$merge_sha"
    echo "source=$source"
    echo "target=$target"
    echo "branch_preserved=true"

    # Return to original branch (preserve it!)
    git checkout "$current" 2>/dev/null
  else
    echo "status=error"
    echo "error=merge_conflict"
    echo "source=$source"
    echo "target=$target"
    echo "hint=resolve conflicts manually or abort with: git merge --abort"

    # Abort the failed merge
    git merge --abort 2>/dev/null
    git checkout "$current" 2>/dev/null
  fi
}

# Execute merge
merge_preserve_history "$SOURCE_BRANCH" "$TARGET_BRANCH" "$MESSAGE"
```

## Output
Return ONLY:
```
status: success | error
merge_sha: <SHA of merge commit>
source: <source branch>
target: <target branch>
branch_preserved: true (always - we NEVER delete)
error: <error type if failed>
hint: <recovery hint if error>
```

## Examples
```
Input: source_branch=20251128-feat-new-feature, target_branch=main
Output: status=success, merge_sha=abc1234, source=20251128-feat-new-feature, target=main, branch_preserved=true

Input: source_branch=conflicting-branch, target_branch=main
Output: status=error, source=conflicting-branch, target=main, error=merge_conflict, hint=resolve conflicts manually
```

## Constitutional Compliance
- **ALWAYS uses --no-ff**: Preserves branch in history graph
- **NEVER deletes source branch**: Branch preservation is sacred
- **Returns to original branch**: After merge completes
- **Aborts on conflict**: Does not leave repo in conflicted state

## Constraints
- Does NOT delete branches (constitutional requirement)
- Does NOT force merge or resolve conflicts automatically
- Uses --no-ff always (preserves merge commit)
- Returns to original branch after operation
