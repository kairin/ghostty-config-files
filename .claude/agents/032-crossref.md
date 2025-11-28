---
name: 032-crossref
description: Check if markdown cross-references are valid (links to files exist). Single atomic task.
model: haiku
---

## Single Task
Verify markdown links point to existing files.

## Input
- file_path: Markdown file to check
- base_dir: Base directory for relative links (default: file's directory)

## Execution
```bash
check_crossrefs() {
  local file="$1"
  local base_dir="${2:-$(dirname "$file")}"

  if [ -z "$file" ]; then
    echo "status=error"
    echo "error=file_path_required"
    return 1
  fi

  if [ ! -f "$file" ]; then
    echo "status=error"
    echo "error=file_not_found"
    return 1
  fi

  # Extract markdown links [text](path)
  local links=$(grep -oE '\[([^]]+)\]\(([^)]+)\)' "$file" 2>/dev/null | grep -oE '\(([^)]+)\)' | tr -d '()')

  local total=0
  local valid=0
  local broken=0
  local external=0
  local broken_list=""

  for link in $links; do
    # Skip external links
    if echo "$link" | grep -qE '^https?://'; then
      external=$((external + 1))
      continue
    fi

    # Skip anchors
    if echo "$link" | grep -qE '^#'; then
      continue
    fi

    total=$((total + 1))

    # Remove anchor from link
    local path=$(echo "$link" | cut -d'#' -f1)

    # Skip empty paths (anchor-only links)
    [ -z "$path" ] && continue

    # Resolve path
    local full_path
    if echo "$path" | grep -qE '^/'; then
      full_path="$path"
    else
      full_path="$base_dir/$path"
    fi

    # Check existence
    if [ -e "$full_path" ]; then
      valid=$((valid + 1))
    else
      broken=$((broken + 1))
      broken_list="${broken_list}${path};"
    fi
  done

  # Output results
  if [ $broken -eq 0 ]; then
    echo "status=all_valid"
  else
    echo "status=has_broken"
  fi

  echo "file=$file"
  echo "total_links=$total"
  echo "valid=$valid"
  echo "broken=$broken"
  echo "external_skipped=$external"
  [ -n "$broken_list" ] && echo "broken_links=${broken_list%%;}"
}

# Check cross-references
check_crossrefs "$FILE_PATH" "$BASE_DIR"
```

## Output
Return ONLY:
```
status: all_valid | has_broken | error
file: <file checked>
total_links: <number of internal links>
valid: <working links>
broken: <broken links count>
external_skipped: <external URLs not checked>
broken_links: <semicolon-separated list of broken>
```

## Examples
```
Input: file_path=README.md
Output: status=all_valid, total_links=15, valid=15, broken=0

Input: file_path=AGENTS.md (has broken links)
Output: status=has_broken, broken=2, broken_links=docs/old.md;missing.md

Input: file_path=docs/index.md
Output: status=all_valid, total_links=8, external_skipped=3
```

## Constraints
- Only checks internal file links
- Skips external URLs
- Reports specific broken paths
