---
name: 024-script-check
description: Check for script proliferation violations. Validates new scripts against constitutional rules. Single atomic task.
model: haiku
---

## Single Task
Check if newly added scripts violate the script proliferation prevention principle.

## Input
- check_staged: Check git staged files (default: true)
- files: Specific files to check (if not using staged)

## Constitutional Rule
> **MANDATORY**: Enhance existing scripts, DO NOT create new wrapper/helper scripts.

## Checklist Applied
1. Can this be added to existing script? (If YES → VIOLATION)
2. Is this a test file in tests/? (If YES → ALLOWED)
3. Does this duplicate existing functionality? (If YES → VIOLATION)

## Execution
```bash
check_script_proliferation() {
  local check_staged="${1:-true}"
  local files="$2"

  local violations=""
  local warnings=""
  local allowed=""

  # Get new script files
  local new_scripts
  if [ "$check_staged" = "true" ]; then
    new_scripts=$(git diff --cached --name-only --diff-filter=A 2>/dev/null | grep '\.sh$' || true)
  else
    new_scripts="$files"
  fi

  if [ -z "$new_scripts" ]; then
    echo "status=clean"
    echo "message=no_new_scripts"
    return 0
  fi

  for script in $new_scripts; do
    local basename=$(basename "$script")
    local dirname=$(dirname "$script")

    # Check 1: Is it in tests/ directory?
    if echo "$dirname" | grep -qE '(^|/)tests(/|$)'; then
      allowed="${allowed}test_file:$script;"
      continue
    fi

    # Check 2: Is it a migration/fix/cleanup script?
    if echo "$basename" | grep -qE '^(migration_|fix_|cleanup_|hotfix_)'; then
      violations="${violations}prohibited_pattern:$script:$basename;"
      continue
    fi

    # Check 3: Is it a wrapper/helper?
    if echo "$basename" | grep -qE '(wrapper|helper|util)'; then
      violations="${violations}wrapper_script:$script;"
      continue
    fi

    # Check 4: Does similar functionality exist?
    local similar=$(find . -name "*.sh" -type f ! -path "*/node_modules/*" ! -path "*/.git/*" | head -20)
    if echo "$similar" | grep -qi "$(echo $basename | sed 's/[_-]/ /g' | cut -d' ' -f1)"; then
      warnings="${warnings}possible_duplicate:$script;"
    else
      allowed="${allowed}new_script:$script;"
    fi
  done

  local violation_count=$(echo "$violations" | tr ';' '\n' | grep -c ':' || echo 0)
  local warning_count=$(echo "$warnings" | tr ';' '\n' | grep -c ':' || echo 0)
  local allowed_count=$(echo "$allowed" | tr ';' '\n' | grep -c ':' || echo 0)

  # Output
  if [ $violation_count -gt 0 ]; then
    echo "status=violations"
    echo "action=block_commit"
  elif [ $warning_count -gt 0 ]; then
    echo "status=warnings"
    echo "action=review_required"
  else
    echo "status=clean"
    echo "action=allowed"
  fi

  echo "violation_count=$violation_count"
  echo "warning_count=$warning_count"
  echo "allowed_count=$allowed_count"
  echo ""
  echo "violations=$violations"
  echo "warnings=$warnings"
  echo "allowed=$allowed"
}

# Check proliferation
check_script_proliferation "$CHECK_STAGED" "$FILES"
```

## Output
Return ONLY:
```
status: clean | warnings | violations
action: allowed | review_required | block_commit
violation_count: <count>
warning_count: <count>
allowed_count: <count>

violations: <semicolon-separated violation details>
warnings: <semicolon-separated warnings>
allowed: <semicolon-separated allowed scripts>
```

## Examples
```
Input: check_staged=true (no new scripts)
Output: status=clean, message=no_new_scripts

Input: check_staged=true (new migration_fix.sh)
Output: status=violations, action=block_commit, violations=prohibited_pattern:migration_fix.sh:migration_fix.sh;

Input: check_staged=true (new test in tests/)
Output: status=clean, allowed_count=1, allowed=test_file:tests/new_test.sh;
```

## Violation Categories
- `prohibited_pattern`: migration_, fix_, cleanup_, hotfix_ prefixes
- `wrapper_script`: wrapper, helper, util in name
- `possible_duplicate`: Similar script name exists

## Allowed Exceptions
- Scripts in `tests/` directory
- Genuinely new functionality

## Constraints
- Read-only check
- Does not block commit directly (parent decides)
- Reports for human/parent review
