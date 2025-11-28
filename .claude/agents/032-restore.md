---
name: 032-restore
description: Restore or create a symlink to specified target. Single atomic task.
model: haiku
---

## Single Task
Create or restore a symlink pointing to specified target.

## Input
- symlink_path: Path where symlink should exist
- target_path: Path symlink should point to
- force: Overwrite existing file/symlink (default: false)

## Execution
```bash
restore_symlink() {
  local symlink="$1"
  local target="$2"
  local force="${3:-false}"

  if [ -z "$symlink" ] || [ -z "$target" ]; then
    echo "status=error"
    echo "error=path_and_target_required"
    return 1
  fi

  # Check if target exists
  if [ ! -e "$target" ]; then
    echo "status=error"
    echo "error=target_not_found"
    echo "target=$target"
    return 1
  fi

  # Check existing state
  if [ -L "$symlink" ]; then
    local current=$(readlink "$symlink")
    if [ "$current" = "$target" ]; then
      echo "status=already_correct"
      echo "path=$symlink"
      echo "target=$target"
      return 0
    fi
    if [ "$force" = "true" ]; then
      rm "$symlink"
      echo "removed_existing=symlink"
    else
      echo "status=exists_different"
      echo "current_target=$current"
      echo "hint=use force=true to overwrite"
      return 0
    fi
  elif [ -e "$symlink" ]; then
    if [ "$force" = "true" ]; then
      rm "$symlink"
      echo "removed_existing=file"
    else
      echo "status=blocked_by_file"
      echo "path=$symlink"
      echo "hint=use force=true to overwrite"
      return 0
    fi
  fi

  # Create symlink
  ln -s "$target" "$symlink"
  if [ -L "$symlink" ]; then
    echo "status=created"
    echo "path=$symlink"
    echo "target=$target"
  else
    echo "status=error"
    echo "error=create_failed"
  fi
}

# Restore symlink
restore_symlink "$SYMLINK_PATH" "$TARGET_PATH" "$FORCE"
```

## Output
Return ONLY:
```
status: created | already_correct | exists_different | blocked_by_file | error
path: <symlink path>
target: <target path>
removed_existing: symlink | file (if force used)
current_target: <existing target if different>
error: <error message if applicable>
```

## Examples
```
Input: symlink_path=CLAUDE.md, target_path=AGENTS.md
Output: status=created, path=CLAUDE.md, target=AGENTS.md

Input: symlink_path=CLAUDE.md (already correct)
Output: status=already_correct, target=AGENTS.md

Input: symlink_path=README.md (regular file exists), force=false
Output: status=blocked_by_file, hint=use force=true to overwrite
```

## Constraints
- Creates relative symlinks
- Requires target to exist
- Respects force flag
