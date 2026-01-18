---
name: 023-scandirs
description: Scan directory structure for duplicate purposes, obsolete directories, and candidates for consolidation. Single atomic task.
model: haiku
---

## Single Task
Scan repository directory structure and identify cleanup candidates.

## Input
- root_path: Root directory to scan (default: current directory)
- patterns: Optional directory patterns to check

## Scan Categories
1. Duplicate-purpose directories (e.g., multiple doc folders)
2. Obsolete/empty directories
3. Archive candidates (old versions, backups)
4. Temporary directories left behind

## Execution
```bash
scan_directories() {
  local root="${1:-.}"
  local duplicates=""
  local obsolete=""
  local archive_candidates=""
  local temp_dirs=""

  # Find documentation duplicates
  local doc_dirs=$(find "$root" -type d \( -name "docs" -o -name "documentation" -o -name "documentations" \) 2>/dev/null)
  if [ $(echo "$doc_dirs" | grep -c .) -gt 1 ]; then
    duplicates="${duplicates}documentation:$(echo $doc_dirs | tr '\n' ',');"
  fi

  # Find empty directories
  local empty_dirs=$(find "$root" -type d -empty 2>/dev/null | head -20)
  if [ -n "$empty_dirs" ]; then
    obsolete="${obsolete}empty:$(echo $empty_dirs | tr '\n' ',');"
  fi

  # Find archive/backup directories
  local archives=$(find "$root" -type d \( -name "*backup*" -o -name "*archive*" -o -name "*old*" -o -name "*deprecated*" \) 2>/dev/null)
  if [ -n "$archives" ]; then
    archive_candidates="${archive_candidates}$(echo $archives | tr '\n' ',');"
  fi

  # Find temp directories
  local temps=$(find "$root" -type d \( -name "tmp" -o -name "temp" -o -name ".tmp" -o -name "*.tmp" \) 2>/dev/null)
  if [ -n "$temps" ]; then
    temp_dirs="${temp_dirs}$(echo $temps | tr '\n' ',');"
  fi

  # Count directories
  local total_dirs=$(find "$root" -type d 2>/dev/null | wc -l)

  # Output results
  echo "status=success"
  echo "root=$root"
  echo "total_directories=$total_dirs"
  echo ""
  echo "# Findings"
  echo "duplicates=$duplicates"
  echo "obsolete=$obsolete"
  echo "archive_candidates=$archive_candidates"
  echo "temp_directories=$temp_dirs"
}

# Run scan
scan_directories "$ROOT_PATH"
```

## Output
Return ONLY:
```
status: success | error
root: <scanned root path>
total_directories: <count>

# Findings
duplicates: <duplicate-purpose dirs>
obsolete: <empty/obsolete dirs>
archive_candidates: <backup/archive dirs>
temp_directories: <temp dirs found>
```

## Examples
```
Input: root_path=.
Output:
  status=success
  total_directories=45
  duplicates=documentation:docs/,documentations/;
  obsolete=empty:old-config/;
  archive_candidates=backups/,archive/;
```

## Constraints
- Read-only scan, does not modify anything
- Returns findings for parent agent to decide
- Does not delete or move directories
