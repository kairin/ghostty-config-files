---
name: 034-merge-dryrun
description: Test if a merge would succeed without actually merging. Detects conflicts before committing. Single atomic task - no decision making.
model: haiku
---

## Single Task
Perform a dry-run merge to detect conflicts without actually merging.

## Input
- source_branch: Branch to merge from
- target_branch: Branch to merge into (default: current branch)

## Execution
```bash
merge_dryrun() {
  local source="$1"
  local target="${2:-$(git branch --show-current)}"

  # Store current branch
  local current=$(git branch --show-current)

  # Checkout target if different
  if [ "$current" != "$target" ]; then
    git checkout "$target" 2>/dev/null || {
      echo "status=error"
      echo "error=cannot_checkout_target"
      return 1
    }
  fi

  # Attempt dry-run merge
  if git merge --no-commit --no-ff "$source" 2>/dev/null; then
    # Merge would succeed - abort it
    git merge --abort 2>/dev/null
    echo "status=clean"
    echo "conflicts=none"
  else
    # Merge has conflicts - get list
    local conflicts=$(git diff --name-only --diff-filter=U 2>/dev/null | tr '\n' ',')
    git merge --abort 2>/dev/null
    echo "status=conflicts"
    echo "conflicts=$conflicts"
  fi

  # Return to original branch
  if [ "$current" != "$target" ]; then
    git checkout "$current" 2>/dev/null
  fi
}

# Run dry-run
merge_dryrun "$SOURCE_BRANCH" "$TARGET_BRANCH"
```

## Output
Return ONLY:
```
source: <source branch>
target: <target branch>
status: clean | conflicts | error
conflicts: <comma-separated list of conflicting files, or "none">
error: <error message if status=error>
```

## Examples
```
Input: source_branch=20251128-143052-feat-new-feature, target_branch=main
Output: source=20251128-143052-feat-new-feature, target=main, status=clean, conflicts=none

Input: source_branch=conflicting-branch, target_branch=main
Output: source=conflicting-branch, target=main, status=conflicts, conflicts=AGENTS.md,README.md

Input: source_branch=nonexistent-branch
Output: status=error, error=source_branch_not_found
```

## Constraints
- Does NOT actually merge - dry-run only
- Aborts merge after testing
- Returns to original branch after check
- Requires clean working directory
