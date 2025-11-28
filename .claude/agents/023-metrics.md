---
name: 023-metrics
description: Calculate cleanup impact metrics - deleted files, lines removed, size reduction. Single atomic task.
model: haiku
---

## Single Task
Calculate and report metrics from cleanup operations.

## Input
- before_snapshot: Path to before state (or use git)
- use_git: Use git diff for metrics (default: true)

## Metrics Calculated
- Files deleted
- Lines removed
- Size reduction (KB)
- Script count reduction

## Execution
```bash
calculate_cleanup_metrics() {
  local use_git="${1:-true}"

  if [ "$use_git" = "true" ]; then
    # Use git to calculate changes
    local files_deleted=$(git diff --cached --name-only --diff-filter=D 2>/dev/null | wc -l)
    local files_added=$(git diff --cached --name-only --diff-filter=A 2>/dev/null | wc -l)
    local files_modified=$(git diff --cached --name-only --diff-filter=M 2>/dev/null | wc -l)

    # Lines added/removed
    local lines_added=$(git diff --cached --numstat 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    local lines_removed=$(git diff --cached --numstat 2>/dev/null | awk '{sum+=$2} END {print sum+0}')
    local net_lines=$((lines_removed - lines_added))

    # Script-specific metrics
    local scripts_deleted=$(git diff --cached --name-only --diff-filter=D 2>/dev/null | grep '\.sh$' | wc -l)
    local scripts_remaining=$(find . -name "*.sh" -type f | wc -l)

    # Output
    echo "status=success"
    echo "source=git_staged"
    echo ""
    echo "# File Changes"
    echo "files_deleted=$files_deleted"
    echo "files_added=$files_added"
    echo "files_modified=$files_modified"
    echo ""
    echo "# Line Changes"
    echo "lines_added=$lines_added"
    echo "lines_removed=$lines_removed"
    echo "net_lines_removed=$net_lines"
    echo ""
    echo "# Script Impact"
    echo "scripts_deleted=$scripts_deleted"
    echo "scripts_remaining=$scripts_remaining"
    echo ""
    echo "# Summary"
    if [ $net_lines -gt 0 ]; then
      echo "impact=reduction"
      echo "reduction_lines=$net_lines"
    else
      echo "impact=growth"
      echo "growth_lines=$((-net_lines))"
    fi

  else
    echo "status=error"
    echo "error=snapshot_mode_not_implemented"
  fi
}

# Calculate metrics
calculate_cleanup_metrics "$USE_GIT"
```

## Output
Return ONLY:
```
status: success | error
source: git_staged | snapshot

# File Changes
files_deleted: <count>
files_added: <count>
files_modified: <count>

# Line Changes
lines_added: <count>
lines_removed: <count>
net_lines_removed: <net reduction>

# Script Impact
scripts_deleted: <count>
scripts_remaining: <count>

# Summary
impact: reduction | growth
reduction_lines: <if reduction>
```

## Examples
```
Input: use_git=true (after cleanup staged)
Output:
  files_deleted=15
  lines_removed=1200
  net_lines_removed=950
  scripts_deleted=8
  impact=reduction
```

## Constitutional Compliance
Tracks script proliferation prevention:
- Reports scripts deleted
- Shows remaining script count
- Helps verify cleanup effectiveness

## Constraints
- Read-only metrics calculation
- Primarily uses git staged changes
- Does not modify any files
