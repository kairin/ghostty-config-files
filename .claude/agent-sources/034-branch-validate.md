---
name: 034-branch-validate
description: Validate a git branch name against the constitutional YYYYMMDD-HHMMSS-type-description format. Returns valid/invalid with specific error details. Single atomic task - no decision making.
model: haiku
---

## Single Task
Validate a branch name matches the constitutional format: `YYYYMMDD-HHMMSS-type-description`

## Input
- branch_name: The branch name to validate

## Validation Rules
```bash
# Constitutional branch format regex
PATTERN='^[0-9]{8}-[0-9]{6}-(feat|fix|docs|refactor|test|chore)-.+$'

# Valid types: feat, fix, docs, refactor, test, chore
# Date format: YYYYMMDD (e.g., 20251128)
# Time format: HHMMSS (e.g., 143052)
# Description: kebab-case, non-empty
```

## Execution
```bash
validate_branch() {
  local branch="$1"

  # Check format with regex
  if echo "$branch" | grep -qE '^[0-9]{8}-[0-9]{6}-(feat|fix|docs|refactor|test|chore)-.+$'; then
    echo "valid"
    return 0
  else
    echo "invalid"
    return 1
  fi
}

# Run validation
validate_branch "$BRANCH_NAME"
```

## Output
Return ONLY:
```
status: valid | invalid
branch: <the branch name checked>
error: <specific error if invalid, e.g., "missing timestamp", "invalid type", "empty description">
```

## Error Categories
- `missing_timestamp`: No YYYYMMDD-HHMMSS prefix
- `invalid_date`: Date portion doesn't match YYYYMMDD
- `invalid_time`: Time portion doesn't match HHMMSS
- `invalid_type`: Type not in allowed list (feat|fix|docs|refactor|test|chore)
- `empty_description`: No description after type
- `invalid_format`: General format mismatch

## Examples
```
Input: "20251128-143052-feat-add-haiku-agents"
Output: status=valid, branch=20251128-143052-feat-add-haiku-agents

Input: "feature-branch"
Output: status=invalid, branch=feature-branch, error=missing_timestamp

Input: "20251128-143052-update-docs"
Output: status=invalid, branch=20251128-143052-update-docs, error=invalid_type
```
