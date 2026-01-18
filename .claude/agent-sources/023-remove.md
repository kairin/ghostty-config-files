---
name: 023-remove
description: Execute file/directory removal with safety checks. Requires explicit file list. Single atomic task.
model: haiku
---

## Single Task
Remove specified files or directories with safety verification.

## Input
- targets: Comma-separated list of files/directories to remove
- dry_run: Preview only, don't actually delete (default: false)

## Safety Checks
1. Never remove protected paths (.git, node_modules with content, etc.)
2. Verify targets exist before attempting removal
3. Track what was actually removed

## Execution
```bash
safe_remove() {
  local targets="$1"
  local dry_run="${2:-false}"

  local protected=".git .github AGENTS.md README.md start.sh"
  local removed=""
  local skipped=""
  local errors=""

  for target in $(echo "$targets" | tr ',' ' '); do
    # Skip empty
    [ -z "$target" ] && continue

    # Check protected
    local basename=$(basename "$target")
    if echo "$protected" | grep -qw "$basename"; then
      skipped="${skipped}protected:$target;"
      continue
    fi

    # Check exists
    if [ ! -e "$target" ]; then
      skipped="${skipped}not_found:$target;"
      continue
    fi

    # Dry run or actual removal
    if [ "$dry_run" = "true" ]; then
      removed="${removed}would_remove:$target;"
    else
      if [ -d "$target" ]; then
        rm -rf "$target" 2>&1 && removed="${removed}$target;" || errors="${errors}$target;"
      else
        rm -f "$target" 2>&1 && removed="${removed}$target;" || errors="${errors}$target;"
      fi
    fi
  done

  # Count results
  local removed_count=$(echo "$removed" | tr ';' '\n' | grep -c . || echo 0)
  local skipped_count=$(echo "$skipped" | tr ';' '\n' | grep -c . || echo 0)
  local error_count=$(echo "$errors" | tr ';' '\n' | grep -c . || echo 0)

  # Output results
  if [ -n "$errors" ]; then
    echo "status=partial"
  elif [ "$removed_count" -gt 0 ]; then
    echo "status=success"
  else
    echo "status=no_action"
  fi

  echo "dry_run=$dry_run"
  echo "removed_count=$removed_count"
  echo "skipped_count=$skipped_count"
  echo "error_count=$error_count"
  echo ""
  echo "removed=$removed"
  echo "skipped=$skipped"
  echo "errors=$errors"
}

# Execute removal
safe_remove "$TARGETS" "$DRY_RUN"
```

## Output
Return ONLY:
```
status: success | partial | no_action | error
dry_run: true | false
removed_count: <number removed>
skipped_count: <number skipped>
error_count: <number of errors>

removed: <semicolon-separated removed items>
skipped: <semicolon-separated skipped items with reason>
errors: <semicolon-separated failed items>
```

## Examples
```
Input: targets=old_script.sh,temp/, dry_run=false
Output: status=success, removed_count=2, removed=old_script.sh;temp/;

Input: targets=.git,README.md
Output: status=no_action, skipped_count=2, skipped=protected:.git;protected:README.md;

Input: targets=file.txt, dry_run=true
Output: status=success, dry_run=true, removed=would_remove:file.txt;
```

## Protected Paths (Never Remove)
- `.git` - Git repository
- `.github` - GitHub workflows
- `AGENTS.md` - Documentation source
- `README.md` - Project documentation
- `start.sh` - Installation script

## Constraints
- NEVER removes protected paths
- Requires explicit target list (no wildcards in this agent)
- Supports dry_run for preview
- Parent agent decides what to remove
