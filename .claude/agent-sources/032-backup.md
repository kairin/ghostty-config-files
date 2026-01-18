---
name: 032-backup
description: Create timestamped backup of file before modifications. Single atomic task.
model: haiku
---

## Single Task
Create a backup copy of a file with timestamp suffix.

## Input
- file_path: Path to file to backup
- backup_dir: Directory for backup (default: same directory)

## Execution
```bash
create_backup() {
  local file="$1"
  local backup_dir="${2:-$(dirname "$file")}"

  if [ -z "$file" ]; then
    echo "status=error"
    echo "error=file_path_required"
    return 1
  fi

  # Check if file exists
  if [ ! -e "$file" ]; then
    echo "status=error"
    echo "error=file_not_found"
    echo "file=$file"
    return 1
  fi

  # Create backup directory if needed
  mkdir -p "$backup_dir" 2>/dev/null

  # Generate backup name
  local filename=$(basename "$file")
  local timestamp=$(date +%Y%m%d-%H%M%S)
  local backup_path="$backup_dir/${filename}.backup-${timestamp}"

  # Handle symlinks - copy target content
  if [ -L "$file" ]; then
    local target=$(readlink "$file")
    echo "source_type=symlink"
    echo "symlink_target=$target"
    # Copy the actual content, not the symlink
    cp -L "$file" "$backup_path" 2>/dev/null
  else
    echo "source_type=file"
    cp "$file" "$backup_path" 2>/dev/null
  fi

  # Verify backup
  if [ -f "$backup_path" ]; then
    local original_size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo 0)
    local backup_size=$(stat -c%s "$backup_path" 2>/dev/null || stat -f%z "$backup_path" 2>/dev/null || echo 0)

    echo "status=created"
    echo "original=$file"
    echo "backup=$backup_path"
    echo "original_size=$original_size"
    echo "backup_size=$backup_size"
  else
    echo "status=error"
    echo "error=backup_failed"
  fi
}

# Create backup
create_backup "$FILE_PATH" "$BACKUP_DIR"
```

## Output
Return ONLY:
```
status: created | error
original: <original file path>
backup: <backup file path>
source_type: file | symlink
symlink_target: <target if symlink>
original_size: <bytes>
backup_size: <bytes>
error: <error message if applicable>
```

## Examples
```
Input: file_path=AGENTS.md
Output: status=created, backup=AGENTS.md.backup-20251128-170000, backup_size=32000

Input: file_path=CLAUDE.md (symlink)
Output: status=created, source_type=symlink, symlink_target=AGENTS.md

Input: file_path=missing.txt
Output: status=error, error=file_not_found
```

## Constraints
- Creates unique timestamped backups
- Preserves content (follows symlinks)
- Does not delete original
