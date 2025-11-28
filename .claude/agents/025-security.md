---
name: 025-security
description: Scan for exposed secrets and sensitive patterns. Single atomic task.
model: haiku
---

## Single Task
Scan repository for potentially exposed secrets or sensitive files.

## Input
- root_path: Directory to scan (default: current directory)
- quick_scan: Only check common locations (default: true)

## Sensitive Patterns
- `.env` files (should be gitignored)
- `*credentials*`, `*secret*`, `*key*`, `*.pem`
- API keys in code (patterns like `API_KEY=`, `token=`)

## Execution
```bash
security_scan() {
  local root="${1:-.}"
  local quick="${2:-true}"

  local issues=""
  local warnings=""

  # Check for .env files (should be gitignored)
  local env_files=$(find "$root" -name ".env*" -type f ! -path "*/.git/*" ! -path "*/node_modules/*" 2>/dev/null)
  for env in $env_files; do
    if ! git check-ignore -q "$env" 2>/dev/null; then
      issues="${issues}exposed_env:$env;"
    fi
  done

  # Check for credential files
  local cred_files=$(find "$root" \( -name "*credential*" -o -name "*secret*" -o -name "*.pem" -o -name "*.key" \) -type f ! -path "*/.git/*" ! -path "*/node_modules/*" 2>/dev/null | head -20)
  for cred in $cred_files; do
    if ! git check-ignore -q "$cred" 2>/dev/null; then
      warnings="${warnings}potential_secret:$cred;"
    fi
  done

  # Quick scan for hardcoded secrets in common files
  if [ "$quick" = "true" ]; then
    local secret_patterns="API_KEY=|SECRET_KEY=|PASSWORD=|TOKEN=|PRIVATE_KEY="
    local suspicious=$(grep -rlE "$secret_patterns" "$root" --include="*.js" --include="*.ts" --include="*.sh" --include="*.json" 2>/dev/null | grep -v node_modules | head -10)
    for file in $suspicious; do
      # Check if it's a .env.example or similar
      if echo "$file" | grep -qE '\.example|\.sample|\.template'; then
        continue
      fi
      warnings="${warnings}hardcoded_secret:$file;"
    done
  fi

  # Check .gitignore coverage
  local gitignore_issues=""
  if [ -f ".gitignore" ]; then
    for pattern in ".env" "*.pem" "*.key" "credentials"; do
      if ! grep -qE "^${pattern}$|^\\*${pattern}$" .gitignore 2>/dev/null; then
        gitignore_issues="${gitignore_issues}missing:$pattern;"
      fi
    done
  else
    gitignore_issues="no_gitignore"
  fi

  # Count results
  local issue_count=$(echo "$issues" | tr ';' '\n' | grep -c ':' || echo 0)
  local warning_count=$(echo "$warnings" | tr ';' '\n' | grep -c ':' || echo 0)

  # Output
  if [ $issue_count -gt 0 ]; then
    echo "status=critical"
  elif [ $warning_count -gt 0 ]; then
    echo "status=warnings"
  else
    echo "status=clean"
  fi

  echo "root=$root"
  echo "issue_count=$issue_count"
  echo "warning_count=$warning_count"
  echo ""
  echo "issues=$issues"
  echo "warnings=$warnings"
  echo "gitignore_gaps=$gitignore_issues"
}

# Run scan
security_scan "$ROOT_PATH" "$QUICK_SCAN"
```

## Output
Return ONLY:
```
status: clean | warnings | critical
root: <scanned path>
issue_count: <critical issues>
warning_count: <warnings>

issues: <semicolon-separated critical issues>
warnings: <semicolon-separated warnings>
gitignore_gaps: <missing .gitignore patterns>
```

## Examples
```
Input: root_path=.
Output:
  status=clean
  issue_count=0
  warning_count=0

Input: root_path=. (with unignored .env)
Output:
  status=critical
  issue_count=1
  issues=exposed_env:.env;
```

## Issue Categories
- `exposed_env`: .env file not in .gitignore
- `potential_secret`: Credential-like filename
- `hardcoded_secret`: Secret pattern in code

## Constraints
- Read-only scan
- Does NOT expose secret values
- Reports locations only
