---
name: 033-type
description: Determine file type - regular file, symlink, directory, or missing. Single atomic task.
model: haiku
---

## Single Task
Identify the type of a filesystem entry.

## Input
- path: Path to check

## Execution
```bash
check_type() {
  local path="$1"

  if [ -z "$path" ]; then
    echo "status=error"
    echo "error=path_required"
    return 1
  fi

  echo "path=$path"

  # Check if exists at all (including broken symlinks)
  if [ ! -e "$path" ] && [ ! -L "$path" ]; then
    echo "status=missing"
    echo "exists=false"
    echo "type=none"
    return 0
  fi

  echo "exists=true"

  # Check type in order of specificity
  if [ -L "$path" ]; then
    echo "type=symlink"
    local target=$(readlink "$path")
    echo "symlink_target=$target"

    # Check if target exists
    if [ -e "$path" ]; then
      echo "symlink_valid=true"

      # Check target type
      if [ -f "$path" ]; then
        echo "resolved_type=file"
      elif [ -d "$path" ]; then
        echo "resolved_type=directory"
      else
        echo "resolved_type=other"
      fi
    else
      echo "symlink_valid=false"
      echo "resolved_type=broken"
    fi
  elif [ -f "$path" ]; then
    echo "type=file"
    local size=$(stat -c%s "$path" 2>/dev/null || stat -f%z "$path" 2>/dev/null || echo 0)
    echo "size_bytes=$size"
  elif [ -d "$path" ]; then
    echo "type=directory"
    local count=$(find "$path" -maxdepth 1 2>/dev/null | wc -l)
    echo "entry_count=$((count - 1))"
  else
    echo "type=other"
  fi

  # Permissions
  [ -r "$path" ] && echo "readable=true" || echo "readable=false"
  [ -w "$path" ] && echo "writable=true" || echo "writable=false"

  echo "status=ok"
}

# Check type
check_type "$PATH_TO_CHECK"
```

## Output
Return ONLY:
```
status: ok | missing | error
path: <checked path>
exists: true | false
type: file | symlink | directory | other | none
symlink_target: <target path if symlink>
symlink_valid: true | false (if symlink)
resolved_type: file | directory | broken (if symlink)
size_bytes: <size if file>
readable: true | false
writable: true | false
```

## Examples
```
Input: path=CLAUDE.md (symlink)
Output: status=ok, type=symlink, symlink_target=AGENTS.md, symlink_valid=true

Input: path=README.md (file)
Output: status=ok, type=file, size_bytes=5000, readable=true

Input: path=missing.txt
Output: status=missing, exists=false, type=none
```

## Constraints
- Read-only check
- Handles broken symlinks
- Reports permissions
