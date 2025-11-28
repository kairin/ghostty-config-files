---
name: 022-validate
description: Validate Astro build output. Checks for index.html, _astro directory, and CRITICAL .nojekyll file. Single atomic task.
model: haiku
---

## Single Task
Validate build output exists and is complete, especially the CRITICAL .nojekyll file.

## Input
- output_dir: Build output directory (default: docs)

## Validation Checks
1. docs/index.html exists
2. docs/_astro/ directory exists (CSS/JS assets)
3. docs/.nojekyll exists (CRITICAL for GitHub Pages)
4. No empty HTML files

## Execution
```bash
validate_build_output() {
  local output_dir="${1:-docs}"
  local issues=""
  local critical=""

  # Check output directory exists
  if [ ! -d "$output_dir" ]; then
    echo "status=error"
    echo "error=output_dir_missing"
    echo "path=$output_dir"
    return 1
  fi

  # Check index.html
  if [ ! -f "$output_dir/index.html" ]; then
    issues="${issues}missing:index.html;"
  elif [ ! -s "$output_dir/index.html" ]; then
    issues="${issues}empty:index.html;"
  fi

  # Check _astro directory (Astro assets)
  if [ ! -d "$output_dir/_astro" ]; then
    issues="${issues}missing:_astro/;"
  else
    local asset_count=$(find "$output_dir/_astro" -type f | wc -l)
    if [ "$asset_count" -eq 0 ]; then
      issues="${issues}empty:_astro/;"
    fi
  fi

  # CRITICAL: Check .nojekyll
  if [ ! -f "$output_dir/.nojekyll" ]; then
    critical="CRITICAL:missing:.nojekyll"
    issues="${issues}${critical};"
  fi

  # Count files
  local html_count=$(find "$output_dir" -name "*.html" -type f | wc -l)
  local total_count=$(find "$output_dir" -type f | wc -l)

  # Output results
  if [ -n "$critical" ]; then
    echo "status=critical"
    echo "critical_issue=$critical"
    echo "issues=$issues"
  elif [ -n "$issues" ]; then
    echo "status=failed"
    echo "issues=$issues"
  else
    echo "status=valid"
  fi

  echo "output_dir=$output_dir"
  echo "html_count=$html_count"
  echo "total_count=$total_count"
  echo "nojekyll_present=$([ -f \"$output_dir/.nojekyll\" ] && echo 'true' || echo 'false')"
}

# Validate output
validate_build_output "$OUTPUT_DIR"
```

## Output
Return ONLY:
```
status: valid | failed | critical | error
output_dir: <output directory path>
html_count: <number of HTML files>
total_count: <total file count>
nojekyll_present: true | false
critical_issue: <CRITICAL issue if any>
issues: <semicolon-separated issues>
```

## Examples
```
Input: output_dir=docs
Output: status=valid, output_dir=docs, html_count=80, total_count=150, nojekyll_present=true

Input: output_dir=docs (missing .nojekyll)
Output: status=critical, critical_issue=CRITICAL:missing:.nojekyll, nojekyll_present=false

Input: output_dir=docs (missing index.html)
Output: status=failed, issues=missing:index.html;, html_count=79
```

## CRITICAL: .nojekyll
The `.nojekyll` file is **CRITICAL** for GitHub Pages:
- Without it, GitHub's Jekyll processor ignores `_astro/` directory
- This breaks ALL CSS and JavaScript on the live site
- If missing, use 022-nojekyll to create it immediately

## Constraints
- Read-only validation
- Does NOT create .nojekyll (use 022-nojekyll)
- Reports CRITICAL status for .nojekyll specifically
- Parent agent must handle critical issues
