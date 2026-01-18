---
name: 022-nojekyll
description: Create or verify .nojekyll file in output directory. CRITICAL for GitHub Pages to serve _astro/ assets. Single atomic task.
model: haiku
---

## Single Task
Ensure `.nojekyll` file exists in the build output directory.

## Why This Is CRITICAL
Without `.nojekyll`:
- GitHub Pages runs Jekyll processor
- Jekyll ignores directories starting with `_` (like `_astro/`)
- ALL CSS and JavaScript files are NOT served
- Website appears completely broken (no styling)

## Input
- output_dir: Build output directory (default: docs)

## Execution
```bash
ensure_nojekyll() {
  local output_dir="${1:-docs}"

  # Verify output directory exists
  if [ ! -d "$output_dir" ]; then
    echo "status=error"
    echo "error=output_dir_missing"
    echo "path=$output_dir"
    return 1
  fi

  local nojekyll_path="$output_dir/.nojekyll"

  # Check if already exists
  if [ -f "$nojekyll_path" ]; then
    echo "status=exists"
    echo "path=$nojekyll_path"
    echo "action=none"
    echo "size=$(stat -c%s \"$nojekyll_path\" 2>/dev/null || echo 0)"
    return 0
  fi

  # Create .nojekyll file (empty file is sufficient)
  touch "$nojekyll_path"

  if [ -f "$nojekyll_path" ]; then
    echo "status=created"
    echo "path=$nojekyll_path"
    echo "action=created_empty_file"

    # Verify it will be tracked by git
    if git check-ignore -q "$nojekyll_path" 2>/dev/null; then
      echo "warning=file_gitignored"
    fi
  else
    echo "status=error"
    echo "error=create_failed"
    echo "path=$nojekyll_path"
  fi
}

# Ensure .nojekyll exists
ensure_nojekyll "$OUTPUT_DIR"
```

## Output
Return ONLY:
```
status: exists | created | error
path: <full path to .nojekyll>
action: none | created_empty_file
warning: <warning if gitignored>
error: <error message if failed>
```

## Examples
```
Input: output_dir=docs (file exists)
Output: status=exists, path=docs/.nojekyll, action=none

Input: output_dir=docs (file missing)
Output: status=created, path=docs/.nojekyll, action=created_empty_file

Input: output_dir=nonexistent
Output: status=error, error=output_dir_missing, path=nonexistent
```

## Constitutional Requirement
From CLAUDE.md:
> **NEVER REMOVE `docs/.nojekyll`** - Breaks ALL CSS/JS on GitHub Pages

This agent:
- Creates .nojekyll if missing
- NEVER removes existing .nojekyll
- Warns if .nojekyll would be gitignored

## Constraints
- Only creates file, never removes
- Empty file is sufficient (no content needed)
- Critical for GitHub Pages deployment
- Must be committed with build output
