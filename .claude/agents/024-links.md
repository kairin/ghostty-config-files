---
name: 024-links
description: Verify markdown links exist. Checks internal file references. Single atomic task.
model: haiku
---

## Single Task
Extract markdown links and verify referenced files exist.

## Input
- file_path: Path to markdown file to check (default: AGENTS.md)
- check_external: Also check external URLs (default: false)

## Execution
```bash
verify_links() {
  local file="${1:-AGENTS.md}"
  local check_external="${2:-false}"

  if [ ! -f "$file" ]; then
    echo "status=error"
    echo "error=file_not_found"
    return 1
  fi

  local valid=""
  local broken=""
  local external=""
  local total=0

  # Extract markdown links [text](path)
  while IFS= read -r link; do
    [ -z "$link" ] && continue
    total=$((total + 1))

    # Check if external URL
    if echo "$link" | grep -qE '^https?://'; then
      if [ "$check_external" = "true" ]; then
        # Basic URL check (just verify format, not availability)
        external="${external}$link;"
      else
        external="${external}skipped:$link;"
      fi
      continue
    fi

    # Internal link - check file exists
    # Handle relative paths from file location
    local file_dir=$(dirname "$file")
    local target_path

    if echo "$link" | grep -q '^/'; then
      # Absolute path from repo root
      target_path="${link#/}"
    else
      # Relative path
      target_path="$file_dir/$link"
    fi

    # Remove anchor if present
    target_path=$(echo "$target_path" | sed 's/#.*//')

    if [ -e "$target_path" ]; then
      valid="${valid}$link;"
    else
      broken="${broken}$link->$target_path;"
    fi
  done < <(grep -oE '\[([^]]*)\]\(([^)]+)\)' "$file" | sed 's/\[.*\](\(.*\))/\1/')

  local valid_count=$(echo "$valid" | tr ';' '\n' | grep -c . || echo 0)
  local broken_count=$(echo "$broken" | tr ';' '\n' | grep -c . || echo 0)
  local external_count=$(echo "$external" | tr ';' '\n' | grep -c . || echo 0)

  # Output
  if [ $broken_count -gt 0 ]; then
    echo "status=has_broken"
  else
    echo "status=all_valid"
  fi

  echo "file=$file"
  echo "total_links=$total"
  echo "valid_count=$valid_count"
  echo "broken_count=$broken_count"
  echo "external_count=$external_count"
  echo ""
  echo "valid=$valid"
  echo "broken=$broken"
  echo "external=$external"
}

# Verify links
verify_links "$FILE_PATH" "$CHECK_EXTERNAL"
```

## Output
Return ONLY:
```
status: all_valid | has_broken | error
file: <file path>
total_links: <total link count>
valid_count: <working internal links>
broken_count: <broken internal links>
external_count: <external URLs found>

valid: <semicolon-separated valid links>
broken: <semicolon-separated broken links with target>
external: <semicolon-separated external URLs>
```

## Examples
```
Input: file_path=AGENTS.md
Output:
  status=all_valid
  total_links=25
  valid_count=20
  broken_count=0
  external_count=5

Input: file_path=README.md (with broken link)
Output:
  status=has_broken
  broken_count=2
  broken=docs/missing.md->docs/missing.md;old/file.md->old/file.md;
```

## Link Types Checked
- `[text](relative/path.md)` - Relative paths
- `[text](/absolute/path.md)` - Absolute paths from root
- `[text](file.md#anchor)` - Anchors (file part only)

## Constraints
- Read-only check
- Does not fix broken links
- External URLs skipped by default
