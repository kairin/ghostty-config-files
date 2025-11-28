---
name: 023-scanscripts
description: Find migration, fix, cleanup, and test scripts by pattern. Identifies candidates for removal. Single atomic task.
model: haiku
---

## Single Task
Scan for scripts that may be cleanup candidates based on naming patterns.

## Input
- root_path: Root directory to scan (default: current directory)
- exclude_dirs: Directories to exclude (default: node_modules,.git)

## Script Categories
1. Migration scripts: `migration_*.sh`, `migrate_*.sh`
2. Emergency fix scripts: `fix_*.sh`, `hotfix_*.sh`
3. One-off cleanup scripts: `cleanup_*.sh`, `clean_*.sh`
4. Obsolete test scripts: `test_*.sh` (outside tests/)

## Execution
```bash
scan_scripts() {
  local root="${1:-.}"
  local exclude="${2:-node_modules,.git}"

  # Build find exclude pattern
  local exclude_pattern=""
  for dir in $(echo "$exclude" | tr ',' ' '); do
    exclude_pattern="$exclude_pattern -path '*/$dir' -prune -o"
  done

  # Find migration scripts
  local migrations=$(find "$root" $exclude_pattern -name "migration_*.sh" -o -name "migrate_*.sh" 2>/dev/null | grep -v "^-")

  # Find fix scripts
  local fixes=$(find "$root" $exclude_pattern -name "fix_*.sh" -o -name "hotfix_*.sh" 2>/dev/null | grep -v "^-")

  # Find cleanup scripts
  local cleanups=$(find "$root" $exclude_pattern -name "cleanup_*.sh" -o -name "clean_*.sh" 2>/dev/null | grep -v "^-")

  # Find test scripts outside tests/
  local orphan_tests=$(find "$root" $exclude_pattern -name "test_*.sh" 2>/dev/null | grep -v "/tests/" | grep -v "^-")

  # Count totals
  local migration_count=$(echo "$migrations" | grep -c . || echo 0)
  local fix_count=$(echo "$fixes" | grep -c . || echo 0)
  local cleanup_count=$(echo "$cleanups" | grep -c . || echo 0)
  local orphan_test_count=$(echo "$orphan_tests" | grep -c . || echo 0)

  # Output results
  echo "status=success"
  echo "root=$root"
  echo ""
  echo "# Script Counts"
  echo "migration_scripts=$migration_count"
  echo "fix_scripts=$fix_count"
  echo "cleanup_scripts=$cleanup_count"
  echo "orphan_test_scripts=$orphan_test_count"
  echo "total_candidates=$((migration_count + fix_count + cleanup_count + orphan_test_count))"
  echo ""
  echo "# Script Lists"
  echo "migrations=$(echo $migrations | tr '\n' ',')"
  echo "fixes=$(echo $fixes | tr '\n' ',')"
  echo "cleanups=$(echo $cleanups | tr '\n' ',')"
  echo "orphan_tests=$(echo $orphan_tests | tr '\n' ',')"
}

# Run scan
scan_scripts "$ROOT_PATH" "$EXCLUDE_DIRS"
```

## Output
Return ONLY:
```
status: success | error
root: <scanned path>

# Script Counts
migration_scripts: <count>
fix_scripts: <count>
cleanup_scripts: <count>
orphan_test_scripts: <count>
total_candidates: <total count>

# Script Lists
migrations: <comma-separated paths>
fixes: <comma-separated paths>
cleanups: <comma-separated paths>
orphan_tests: <comma-separated paths>
```

## Examples
```
Input: root_path=.
Output:
  migration_scripts=3
  fix_scripts=2
  total_candidates=7
  migrations=migration_docs.sh,migration_config.sh,...
```

## Script Proliferation Check
Per constitutional rules, scripts should be consolidated.
This agent identifies candidates - parent decides action.

## Constraints
- Read-only scan
- Does not delete scripts
- Excludes node_modules and .git by default
