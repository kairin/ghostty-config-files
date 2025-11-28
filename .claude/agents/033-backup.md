---
name: 033-backup
description: Create timestamped backup before symlink operations. Single atomic task.
model: haiku
---

## Single Task
Create backup of file/symlink before modification.

## Input
- path: Path to backup
- backup_suffix: Custom suffix (default: timestamp)

## Execution
```bash
create_backup() {
  local path="$1"
  local suffix="${2:-$(date +%Y%m%d-%H%M%S)}"

  if [ -z "$path" ]; then
    echo "status=error"
    echo "error=path_required"
    return 1
  fi

  echo "original=$path"

  # Check if exists
  if [ ! -e "$path" ] && [ ! -L "$path" ]; then
    echo "status=nothing_to_backup"
    echo "exists=false"
    return 0
  fi

  # Determine backup path
  local backup_path="${path}.backup-${suffix}"

  # Avoid overwriting existing backup
  if [ -e "$backup_path" ]; then
    backup_path="${path}.backup-${suffix}-$$"
  fi

  # Handle based on type
  if [ -L "$path" ]; then
    echo "type=symlink"
    local target=$(readlink "$path")
    echo "symlink_target=$target"

    # For symlinks, save the link target, not content
    echo "$target" > "$backup_path"
    echo "backup_contains=symlink_target"
  else
    echo "type=file"

    # Copy file content
    cp -p "$path" "$backup_path" 2>/dev/null
    echo "backup_contains=file_content"
  fi

  # Verify backup
  if [ -e "$backup_path" ]; then
    local backup_size=$(stat -c%s "$backup_path" 2>/dev/null || stat -f%z "$backup_path" 2>/dev/null || echo 0)
    echo "status=created"
    echo "backup=$backup_path"
    echo "backup_size=$backup_size"
  else
    echo "status=error"
    echo "error=backup_failed"
  fi
}

# Create backup
create_backup "$PATH_TO_BACKUP" "$BACKUP_SUFFIX"
```

## Output
Return ONLY:
```
status: created | nothing_to_backup | error
original: <original path>
type: file | symlink
symlink_target: <target if symlink>
backup: <backup file path>
backup_contains: file_content | symlink_target
backup_size: <bytes>
error: <error message if applicable>
```

## Examples
```
Input: path=CLAUDE.md (symlink)
Output: status=created, type=symlink, backup=CLAUDE.md.backup-20251128-170000

Input: path=AGENTS.md (file)
Output: status=created, type=file, backup_size=32000

Input: path=missing.txt
Output: status=nothing_to_backup, exists=false
```

## Constraints
- Preserves file permissions
- Stores symlink targets differently than content
- Unique backup names (no overwrites)
