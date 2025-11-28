---
name: 021-push
description: Push current branch to remote with upstream tracking. Verifies push succeeded on remote. Single atomic task - no decision making.
model: haiku
---

## Single Task
Push the current branch to remote origin with upstream tracking enabled.

## Input
- remote: Remote name (default: origin)
- branch: Branch to push (default: current branch)
- set_upstream: Set upstream tracking (default: true)

## Execution
```bash
push_to_remote() {
  local remote="${1:-origin}"
  local branch="${2:-$(git branch --show-current)}"
  local set_upstream="${3:-true}"

  # Build push command
  local push_cmd="git push"
  if [ "$set_upstream" = "true" ]; then
    push_cmd="$push_cmd -u"
  fi
  push_cmd="$push_cmd $remote $branch"

  # Execute push
  local output
  output=$($push_cmd 2>&1)
  local exit_code=$?

  if [ $exit_code -eq 0 ]; then
    # Verify on remote
    local local_sha=$(git rev-parse HEAD)
    local remote_sha=$(git ls-remote $remote $branch 2>/dev/null | cut -f1)

    if [ "$local_sha" = "$remote_sha" ]; then
      echo "status=success"
      echo "sha=$local_sha"
      echo "remote=$remote"
      echo "branch=$branch"
      echo "verified=true"
    else
      echo "status=success"
      echo "sha=$local_sha"
      echo "remote=$remote"
      echo "branch=$branch"
      echo "verified=false"
      echo "warning=remote_sha_mismatch"
    fi
  else
    echo "status=error"
    echo "remote=$remote"
    echo "branch=$branch"

    # Categorize error
    if echo "$output" | grep -q "non-fast-forward"; then
      echo "error=non_fast_forward"
      echo "hint=remote has changes not in local"
    elif echo "$output" | grep -q "protected branch"; then
      echo "error=branch_protected"
      echo "hint=create pull request instead"
    elif echo "$output" | grep -q "Permission denied"; then
      echo "error=permission_denied"
    else
      echo "error=push_failed"
      echo "output=$output"
    fi
  fi
}

# Execute push
push_to_remote "$REMOTE" "$BRANCH" "$SET_UPSTREAM"
```

## Output
Return ONLY:
```
status: success | error
sha: <commit SHA pushed>
remote: <remote name>
branch: <branch name>
verified: true | false
error: <error type if failed>
hint: <recovery hint if error>
```

## Examples
```
Input: remote=origin, branch=20251128-feat-new-feature
Output: status=success, sha=abc1234, remote=origin, branch=20251128-feat-new-feature, verified=true

Input: remote=origin (remote has diverged)
Output: status=error, remote=origin, branch=main, error=non_fast_forward, hint=remote has changes not in local

Input: remote=origin, branch=main (protected)
Output: status=error, remote=origin, branch=main, error=branch_protected, hint=create pull request instead
```

## Constraints
- Does NOT force push (--force is forbidden)
- Does NOT resolve divergence (parent agent decides)
- Verifies push succeeded on remote
- Returns specific error types for parent to handle
