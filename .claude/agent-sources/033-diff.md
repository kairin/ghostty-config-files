---
name: 033-diff
description: Compare two files for content differences. Single atomic task.
model: haiku
---

## Single Task
Compare two files and report if they differ.

## Input
- file_a: First file path
- file_b: Second file path
- show_diff: Include diff output (default: false)

## Execution
```bash
compare_files() {
  local file_a="$1"
  local file_b="$2"
  local show="${3:-false}"

  if [ -z "$file_a" ] || [ -z "$file_b" ]; then
    echo "status=error"
    echo "error=two_paths_required"
    return 1
  fi

  echo "file_a=$file_a"
  echo "file_b=$file_b"

  # Check existence
  if [ ! -e "$file_a" ]; then
    echo "status=error"
    echo "error=file_a_missing"
    return 1
  fi

  if [ ! -e "$file_b" ]; then
    echo "status=error"
    echo "error=file_b_missing"
    return 1
  fi

  # Get sizes
  local size_a=$(stat -c%s "$file_a" 2>/dev/null || stat -f%z "$file_a" 2>/dev/null || echo 0)
  local size_b=$(stat -c%s "$file_b" 2>/dev/null || stat -f%z "$file_b" 2>/dev/null || echo 0)
  echo "size_a=$size_a"
  echo "size_b=$size_b"

  # Quick size check
  if [ "$size_a" != "$size_b" ]; then
    echo "status=different"
    echo "reason=size_mismatch"
    echo "size_diff=$((size_b - size_a))"
    return 0
  fi

  # Content comparison
  if cmp -s "$file_a" "$file_b"; then
    echo "status=identical"
    return 0
  fi

  echo "status=different"
  echo "reason=content_mismatch"

  # Line-level diff stats
  local diff_lines=$(diff "$file_a" "$file_b" 2>/dev/null | grep -c '^[<>]' || echo 0)
  echo "changed_lines=$diff_lines"

  # Show diff if requested (limited)
  if [ "$show" = "true" ]; then
    echo "diff_preview="
    diff -u "$file_a" "$file_b" 2>/dev/null | head -20
    echo "..."
  fi
}

# Compare files
compare_files "$FILE_A" "$FILE_B" "$SHOW_DIFF"
```

## Output
Return ONLY:
```
status: identical | different | error
file_a: <first file path>
file_b: <second file path>
size_a: <bytes>
size_b: <bytes>
reason: size_mismatch | content_mismatch (if different)
size_diff: <byte difference if size mismatch>
changed_lines: <approximate lines changed>
diff_preview: <first 20 lines if show_diff=true>
```

## Examples
```
Input: file_a=AGENTS.md, file_b=AGENTS.md.backup
Output: status=identical, size_a=32000, size_b=32000

Input: file_a=old.md, file_b=new.md
Output: status=different, reason=content_mismatch, changed_lines=15

Input: file_a=small.txt, file_b=large.txt
Output: status=different, reason=size_mismatch, size_diff=5000
```

## Constraints
- Binary-safe comparison
- Limited diff preview for large files
- Reports size and content differences separately
