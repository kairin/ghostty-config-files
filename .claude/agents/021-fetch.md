---
name: 021-fetch
description: Fetch remote state and analyze divergence between local and remote branches. Returns sync status (up_to_date/behind/ahead/diverged). Single atomic task - no decision making.
model: haiku
---

## Single Task
Fetch from remote and determine the synchronization status between local and remote branches.

## Input
- remote: Remote name (default: origin)
- branch: Branch to check (default: current branch)

## Execution
```bash
fetch_and_analyze() {
  local remote="${1:-origin}"
  local branch="${2:-$(git branch --show-current)}"

  # Fetch all remotes with tags and prune
  git fetch --all --tags --prune 2>&1 || {
    echo "status=error"
    echo "error=fetch_failed"
    return 1
  }

  # Get commit hashes
  local LOCAL=$(git rev-parse @ 2>/dev/null)
  local REMOTE=$(git rev-parse "@{u}" 2>/dev/null || echo "no_upstream")
  local BASE=$(git merge-base @ "@{u}" 2>/dev/null || echo "no_base")

  # Determine scenario
  if [ "$REMOTE" = "no_upstream" ]; then
    echo "scenario=no_upstream"
    echo "local_sha=$LOCAL"
  elif [ "$LOCAL" = "$REMOTE" ]; then
    echo "scenario=up_to_date"
    echo "sha=$LOCAL"
  elif [ "$LOCAL" = "$BASE" ]; then
    echo "scenario=behind"
    echo "local_sha=$LOCAL"
    echo "remote_sha=$REMOTE"
    echo "commits_behind=$(git rev-list --count @..@{u})"
  elif [ "$REMOTE" = "$BASE" ]; then
    echo "scenario=ahead"
    echo "local_sha=$LOCAL"
    echo "remote_sha=$REMOTE"
    echo "commits_ahead=$(git rev-list --count @{u}..@)"
  else
    echo "scenario=diverged"
    echo "local_sha=$LOCAL"
    echo "remote_sha=$REMOTE"
    echo "base_sha=$BASE"
  fi

  echo "status=success"
}

# Run fetch and analysis
fetch_and_analyze "$REMOTE" "$BRANCH"
```

## Output
Return ONLY:
```
status: success | error
scenario: up_to_date | behind | ahead | diverged | no_upstream
local_sha: <local commit SHA>
remote_sha: <remote commit SHA>
commits_ahead: <number if ahead>
commits_behind: <number if behind>
error: <error message if status=error>
```

## Examples
```
Input: remote=origin, branch=main
Output: status=success, scenario=up_to_date, sha=abc1234

Input: remote=origin, branch=feature-branch
Output: status=success, scenario=ahead, local_sha=abc1234, remote_sha=def5678, commits_ahead=3

Input: remote=origin
Output: status=success, scenario=diverged, local_sha=abc1234, remote_sha=def5678, base_sha=ghi9012
```

## Constraints
- Read-only operation (fetch only, no pull)
- Does not modify local branches
- Parent agent decides action based on scenario
