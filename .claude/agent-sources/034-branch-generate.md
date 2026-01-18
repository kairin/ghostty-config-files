---
name: 034-branch-generate
description: Generate a constitutional branch name with current timestamp. Takes type and description, returns formatted YYYYMMDD-HHMMSS-type-description. Single atomic task - no decision making.
model: haiku
---

## Single Task
Generate a constitutional branch name using current timestamp and provided type/description.

## Input
- type: One of feat|fix|docs|refactor|test|chore
- description: Kebab-case description (e.g., "add-haiku-agents")

## Execution
```bash
generate_branch_name() {
  local type="$1"
  local description="$2"

  # Validate type
  case "$type" in
    feat|fix|docs|refactor|test|chore) ;;
    *) echo "error: invalid_type"; return 1 ;;
  esac

  # Validate description non-empty
  if [ -z "$description" ]; then
    echo "error: empty_description"
    return 1
  fi

  # Generate timestamp
  local timestamp=$(date +"%Y%m%d-%H%M%S")

  # Format branch name
  echo "${timestamp}-${type}-${description}"
}

# Generate and output
generate_branch_name "$TYPE" "$DESCRIPTION"
```

## Output
Return ONLY:
```
branch_name: <generated branch name>
status: success | error
error: <error message if status=error>
```

## Examples
```
Input: type=feat, description=add-haiku-agents
Output: branch_name=20251128-143052-feat-add-haiku-agents, status=success

Input: type=fix, description=symlink-restore
Output: branch_name=20251128-143053-fix-symlink-restore, status=success

Input: type=update, description=docs
Output: status=error, error=invalid_type (must be feat|fix|docs|refactor|test|chore)
```

## Constraints
- Always uses current system time for timestamp
- Description must be non-empty
- Type must be from allowed list
- No spaces in description (use kebab-case)
