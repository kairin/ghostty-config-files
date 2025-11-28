---
name: 034-branch-exists
description: Check if a git branch exists locally or remotely. Returns exists/missing with location details. Single atomic task - no decision making.
model: haiku
---

## Single Task
Check if a specified git branch exists in the repository.

## Input
- branch_name: The branch name to check
- check_remote: Optional, default true - also check remote

## Execution
```bash
check_branch_exists() {
  local branch="$1"
  local check_remote="${2:-true}"

  local local_exists="false"
  local remote_exists="false"

  # Check local branches
  if git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
    local_exists="true"
  fi

  # Check remote branches (if requested)
  if [ "$check_remote" = "true" ]; then
    if git show-ref --verify --quiet "refs/remotes/origin/$branch" 2>/dev/null; then
      remote_exists="true"
    fi
  fi

  # Output results
  echo "local_exists=$local_exists"
  echo "remote_exists=$remote_exists"

  if [ "$local_exists" = "true" ] || [ "$remote_exists" = "true" ]; then
    echo "status=exists"
  else
    echo "status=missing"
  fi
}

# Run check
check_branch_exists "$BRANCH_NAME" "$CHECK_REMOTE"
```

## Output
Return ONLY:
```
branch: <branch name checked>
status: exists | missing
local_exists: true | false
remote_exists: true | false
sha: <commit SHA if exists locally>
```

## Examples
```
Input: branch_name=main
Output: branch=main, status=exists, local_exists=true, remote_exists=true, sha=abc1234

Input: branch_name=20251128-143052-feat-new-feature
Output: branch=20251128-143052-feat-new-feature, status=missing, local_exists=false, remote_exists=false

Input: branch_name=origin-only-branch, check_remote=true
Output: branch=origin-only-branch, status=exists, local_exists=false, remote_exists=true
```

## Constraints
- Does not create or modify branches
- Read-only operation
- Requires git repository context
