---
name: 021-commit
description: Execute a git commit with the provided message. Does not format the message - expects pre-formatted constitutional message from 034-commit-format. Single atomic task.
model: haiku
---

## Single Task
Execute `git commit` with the provided pre-formatted message.

## Input
- message: Pre-formatted commit message (from 034-commit-format)

## Execution
```bash
execute_commit() {
  local message="$1"

  # Verify there are staged changes
  if [ -z "$(git diff --cached --name-only)" ]; then
    echo "status=error"
    echo "error=nothing_to_commit"
    return 1
  fi

  # Execute commit using heredoc for proper formatting
  git commit -m "$message" 2>&1

  if [ $? -eq 0 ]; then
    local sha=$(git rev-parse HEAD)
    local short_sha=$(git rev-parse --short HEAD)
    echo "status=success"
    echo "commit_sha=$sha"
    echo "short_sha=$short_sha"
  else
    echo "status=error"
    echo "error=commit_failed"
  fi
}

# Execute the commit
execute_commit "$MESSAGE"
```

## Output
Return ONLY:
```
status: success | error
commit_sha: <full SHA of new commit>
short_sha: <short SHA (7 chars)>
error: <error message if status=error>
```

## Examples
```
Input: message="feat(agents): add Haiku sub-agents\n\n🤖 Generated with..."
Output: status=success, commit_sha=abc123def456..., short_sha=abc123d

Input: message="..." (nothing staged)
Output: status=error, error=nothing_to_commit

Input: message="..." (pre-commit hook fails)
Output: status=error, error=commit_failed
```

## Pre-Commit Hook Handling
If commit fails due to pre-commit hook modifications:
- Return status=error with error=pre_commit_modified
- Parent agent (002-git) decides whether to retry

## Constraints
- Does NOT format message - expects pre-formatted input
- Does NOT validate message format
- Parent should use 034-commit-format first
- Returns error if nothing staged
