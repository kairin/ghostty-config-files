---
name: 025-context7
description: Validate Context7 API key presence and configuration. Does NOT expose the key value. Single atomic task.
model: haiku
---

## Single Task
Check that Context7 MCP is properly configured without exposing sensitive values.

## Input
- env_file: Path to .env file (default: .env)

## Checks Performed
1. .env file exists
2. CONTEXT7_API_KEY is defined
3. Key format looks valid (has expected prefix/length)
4. .gitignore includes .env

## Execution
```bash
validate_context7() {
  local env_file="${1:-.env}"
  local issues=""

  # Check .env exists
  if [ ! -f "$env_file" ]; then
    echo "status=not_configured"
    echo "issue=env_file_missing"
    echo "hint=create .env with CONTEXT7_API_KEY"
    return 0
  fi

  # Check .gitignore includes .env
  if [ -f ".gitignore" ]; then
    if ! grep -qE '^\.env$|^\*\.env$' .gitignore; then
      issues="${issues}gitignore_missing_env;"
    fi
  else
    issues="${issues}no_gitignore;"
  fi

  # Check CONTEXT7_API_KEY exists (without exposing value)
  if grep -q '^CONTEXT7_API_KEY=' "$env_file"; then
    local key_length=$(grep '^CONTEXT7_API_KEY=' "$env_file" | cut -d= -f2 | wc -c)

    if [ "$key_length" -lt 10 ]; then
      issues="${issues}key_too_short;"
    fi

    # Check if key looks like placeholder
    if grep -qE '^CONTEXT7_API_KEY=(your_key|xxx|placeholder|CHANGEME)' "$env_file"; then
      issues="${issues}placeholder_key;"
    fi

    echo "key_present=true"
    echo "key_length=$key_length"
  else
    echo "key_present=false"
    issues="${issues}key_not_defined;"
  fi

  # Output
  if [ -z "$issues" ]; then
    echo "status=configured"
  else
    echo "status=issues_found"
  fi

  echo "env_file=$env_file"
  echo "issues=$issues"

  # Security reminder
  echo ""
  echo "# Security Note"
  echo "key_value=NEVER_EXPOSED"
  echo "gitignore_check=$(grep -q '^\.env$' .gitignore 2>/dev/null && echo 'protected' || echo 'not_protected')"
}

# Validate Context7
validate_context7 "$ENV_FILE"
```

## Output
Return ONLY:
```
status: configured | not_configured | issues_found
env_file: <path checked>
key_present: true | false
key_length: <length without exposing value>
issues: <semicolon-separated issues>

# Security Note
key_value: NEVER_EXPOSED
gitignore_check: protected | not_protected
```

## Examples
```
Input: env_file=.env (properly configured)
Output:
  status=configured
  key_present=true
  key_length=45
  gitignore_check=protected

Input: env_file=.env (placeholder key)
Output:
  status=issues_found
  issues=placeholder_key;
```

## Security
- NEVER outputs the actual API key value
- Only reports presence and format validity
- Checks .gitignore protection

## Constraints
- Read-only check
- Does not modify .env
- Does not expose secrets
