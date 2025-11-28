---
name: 031-file
description: Check if a critical file exists and optionally verify content. Single atomic task.
model: haiku
---

## Single Task
Check that a critical file exists and is accessible.

## Input
- file_path: Path to file to check
- verify_non_empty: Check file is not empty (default: true)

## Execution
```bash
check_file() {
  local file="$1"
  local verify_content="${2:-true}"

  if [ -z "$file" ]; then
    echo "status=error"
    echo "error=path_required"
    return 1
  fi

  # Check existence
  if [ ! -e "$file" ]; then
    echo "status=missing"
    echo "path=$file"
    echo "exists=false"
    return 0
  fi

  # Check if it's a regular file (not directory, not symlink target check)
  if [ ! -f "$file" ] && [ ! -L "$file" ]; then
    echo "status=error"
    echo "path=$file"
    echo "error=not_a_file"
    return 1
  fi

  # Check if symlink
  local is_symlink="false"
  local symlink_target=""
  if [ -L "$file" ]; then
    is_symlink="true"
    symlink_target=$(readlink "$file")
  fi

  # Check readability
  if [ ! -r "$file" ]; then
    echo "status=not_readable"
    echo "path=$file"
    echo "exists=true"
    echo "readable=false"
    return 0
  fi

  # Check content if requested
  local size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo 0)
  local is_empty="false"
  if [ "$size" -eq 0 ]; then
    is_empty="true"
  fi

  # Line count for text files
  local line_count=0
  if file "$file" 2>/dev/null | grep -qi text; then
    line_count=$(wc -l < "$file" 2>/dev/null || echo 0)
  fi

  # Output
  if [ "$verify_content" = "true" ] && [ "$is_empty" = "true" ]; then
    echo "status=empty"
  else
    echo "status=ok"
  fi

  echo "path=$file"
  echo "exists=true"
  echo "readable=true"
  echo "is_symlink=$is_symlink"
  [ -n "$symlink_target" ] && echo "symlink_target=$symlink_target"
  echo "size_bytes=$size"
  echo "is_empty=$is_empty"
  echo "line_count=$line_count"
}

# Check file
check_file "$FILE_PATH" "$VERIFY_NON_EMPTY"
```

## Output
Return ONLY:
```
status: ok | missing | empty | not_readable | error
path: <file path>
exists: true | false
readable: true | false
is_symlink: true | false
symlink_target: <target path if symlink>
size_bytes: <file size>
is_empty: true | false
line_count: <lines if text file>
```

## Examples
```
Input: file_path=AGENTS.md
Output: status=ok, path=AGENTS.md, exists=true, readable=true, size_bytes=32000, line_count=800

Input: file_path=docs/.nojekyll
Output: status=ok, path=docs/.nojekyll, exists=true, is_empty=true (empty is OK for .nojekyll)

Input: file_path=CLAUDE.md (symlink)
Output: status=ok, is_symlink=true, symlink_target=AGENTS.md
```

## Constraints
- Read-only check
- Does not modify files
- Handles symlinks correctly
