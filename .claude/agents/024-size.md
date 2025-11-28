---
name: 024-size
description: Check file size and determine compliance zone (Green/Yellow/Orange/Red). Used for AGENTS.md monitoring. Single atomic task.
model: haiku
---

## Single Task
Check file size in KB and determine which compliance zone it falls into.

## Input
- file_path: Path to file to check (default: AGENTS.md)

## Compliance Zones (for AGENTS.md)
- **Green** (0-25KB): Optimal, no action needed
- **Yellow** (25-32KB): Monitor, consider modularization
- **Orange** (32-40KB): Warning, modularize soon
- **Red** (>40KB): Critical, immediate modularization required

## Execution
```bash
check_file_size() {
  local file="${1:-AGENTS.md}"

  # Check file exists
  if [ ! -f "$file" ]; then
    echo "status=error"
    echo "error=file_not_found"
    echo "path=$file"
    return 1
  fi

  # Get size in bytes and KB
  local size_bytes=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)
  local size_kb=$((size_bytes / 1024))
  local size_lines=$(wc -l < "$file")

  # Determine zone
  local zone
  local action
  if [ $size_kb -le 25 ]; then
    zone="green"
    action="none"
  elif [ $size_kb -le 32 ]; then
    zone="yellow"
    action="monitor"
  elif [ $size_kb -le 40 ]; then
    zone="orange"
    action="modularize_soon"
  else
    zone="red"
    action="immediate_modularization"
  fi

  # Output
  echo "status=success"
  echo "file=$file"
  echo "size_bytes=$size_bytes"
  echo "size_kb=$size_kb"
  echo "size_lines=$size_lines"
  echo "zone=$zone"
  echo "action=$action"

  # Additional context
  if [ "$zone" = "red" ]; then
    echo "critical=true"
    echo "over_limit_kb=$((size_kb - 40))"
  fi
}

# Check size
check_file_size "$FILE_PATH"
```

## Output
Return ONLY:
```
status: success | error
file: <file path>
size_bytes: <exact size>
size_kb: <size in KB>
size_lines: <line count>
zone: green | yellow | orange | red
action: none | monitor | modularize_soon | immediate_modularization
critical: true (only if red zone)
over_limit_kb: <KB over 40KB limit> (only if red zone)
```

## Examples
```
Input: file_path=AGENTS.md (20KB)
Output: status=success, size_kb=20, zone=green, action=none

Input: file_path=AGENTS.md (35KB)
Output: status=success, size_kb=35, zone=orange, action=modularize_soon

Input: file_path=AGENTS.md (45KB)
Output: status=success, size_kb=45, zone=red, action=immediate_modularization, critical=true, over_limit_kb=5
```

## Constraints
- Read-only check
- Does not modify file
- Parent agent decides modularization strategy
