---
name: 021-branch
description: Create a new git branch and optionally switch to it. Does not validate naming - use 034-branch-generate first. Single atomic task.
model: haiku
---

## Single Task
Create a new git branch from specified base and optionally switch to it.

## Input
- branch_name: Name for the new branch (pre-validated by 034-branch-generate)
- base_branch: Branch to create from (default: current branch)
- switch: Whether to switch to new branch (default: true)

## Execution
```bash
create_branch() {
  local branch_name="$1"
  local base_branch="${2:-$(git branch --show-current)}"
  local switch="${3:-true}"

  # Check if branch already exists
  if git show-ref --verify --quiet "refs/heads/$branch_name" 2>/dev/null; then
    echo "status=error"
    echo "error=branch_exists"
    echo "branch=$branch_name"
    return 1
  fi

  # Create branch
  if [ "$switch" = "true" ]; then
    git checkout -b "$branch_name" "$base_branch" 2>&1
  else
    git branch "$branch_name" "$base_branch" 2>&1
  fi

  if [ $? -eq 0 ]; then
    local sha=$(git rev-parse "$branch_name")
    echo "status=success"
    echo "branch=$branch_name"
    echo "base=$base_branch"
    echo "sha=$sha"
    echo "switched=$switch"
    echo "current=$(git branch --show-current)"
  else
    echo "status=error"
    echo "error=create_failed"
    echo "branch=$branch_name"
  fi
}

# Create the branch
create_branch "$BRANCH_NAME" "$BASE_BRANCH" "$SWITCH"
```

## Output
Return ONLY:
```
status: success | error
branch: <new branch name>
base: <base branch name>
sha: <commit SHA the branch points to>
switched: true | false
current: <current branch after operation>
error: <error type if failed>
```

## Examples
```
Input: branch_name=20251128-143052-feat-new-feature, base_branch=main, switch=true
Output: status=success, branch=20251128-143052-feat-new-feature, base=main, sha=abc1234, switched=true, current=20251128-143052-feat-new-feature

Input: branch_name=existing-branch
Output: status=error, error=branch_exists, branch=existing-branch

Input: branch_name=20251128-143052-docs-update, switch=false
Output: status=success, branch=20251128-143052-docs-update, base=main, sha=abc1234, switched=false, current=main
```

## Constraints
- Does NOT validate branch name format (use 034-branch-generate first)
- Does NOT delete branches
- Fails if branch already exists
- Parent agent responsible for naming compliance
