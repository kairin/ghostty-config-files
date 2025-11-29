---
name: 025-astro-check
description: Verify astro.config.mjs compliance. Checks size (<30 lines) and required integrations. Single atomic task.
model: haiku
---

## Single Task
Check that Astro configuration follows project standards.

## Tailwind CSS Rules Reference
For Tailwind CSS v4 best practices, see: `.claude/rules-tailwindcss/tailwind.md`

## Input
- config_path: Path to astro.config.mjs (default: astro-website/astro.config.mjs)

## Compliance Checks
1. File size under 30 lines (simplicity requirement)
2. Uses @tailwindcss/vite plugin
3. Output directory is '../docs'
4. Base path configured for GitHub Pages

## Execution
```bash
check_astro_config() {
  local config="${1:-astro-website/astro.config.mjs}"

  if [ ! -f "$config" ]; then
    echo "status=error"
    echo "error=config_not_found"
    echo "path=$config"
    return 1
  fi

  local issues=""
  local compliant=""

  # Check line count
  local line_count=$(wc -l < "$config")
  if [ "$line_count" -gt 30 ]; then
    issues="${issues}too_many_lines:$line_count(max 30);"
  else
    compliant="${compliant}line_count:$line_count;"
  fi

  # Check for @tailwindcss/vite
  if grep -q "@tailwindcss/vite" "$config"; then
    compliant="${compliant}tailwind_vite:present;"
  else
    issues="${issues}missing:@tailwindcss/vite;"
  fi

  # Check output directory
  if grep -qE "outDir.*['\"]\.\.\/docs['\"]" "$config"; then
    compliant="${compliant}outDir:../docs;"
  else
    issues="${issues}wrong_outDir;"
  fi

  # Check for site/base configuration (GitHub Pages)
  if grep -q "site:" "$config" || grep -q "base:" "$config"; then
    compliant="${compliant}gh_pages_config:present;"
  else
    issues="${issues}missing:site/base config;"
  fi

  # Check for legacy packages that should be removed
  local legacy=""
  for pkg in "@astrojs/tailwind" "autoprefixer" "postcss"; do
    if grep -q "\"$pkg\"" "$config" 2>/dev/null; then
      legacy="${legacy}$pkg;"
    fi
  done
  if [ -n "$legacy" ]; then
    issues="${issues}legacy_packages:$legacy;"
  fi

  # Output
  local issue_count=$(echo "$issues" | tr ';' '\n' | grep -c ':' || echo 0)

  if [ $issue_count -eq 0 ]; then
    echo "status=compliant"
  else
    echo "status=non_compliant"
  fi

  echo "config=$config"
  echo "line_count=$line_count"
  echo "issue_count=$issue_count"
  echo ""
  echo "compliant=$compliant"
  echo "issues=$issues"
}

# Check config
check_astro_config "$CONFIG_PATH"
```

## Output
Return ONLY:
```
status: compliant | non_compliant | error
config: <config file path>
line_count: <number of lines>
issue_count: <issues found>

compliant: <semicolon-separated compliant items>
issues: <semicolon-separated issues>
```

## Examples
```
Input: config_path=astro-website/astro.config.mjs (26 lines, correct setup)
Output:
  status=compliant
  line_count=26
  compliant=line_count:26;tailwind_vite:present;outDir:../docs;

Input: config_path=astro-website/astro.config.mjs (115 lines, old setup)
Output:
  status=non_compliant
  line_count=115
  issues=too_many_lines:115(max 30);legacy_packages:@astrojs/tailwind;autoprefixer;
```

## Project Standards
- Astro config should be minimal (<30 lines)
- Use Tailwind v4 with @tailwindcss/vite
- Remove legacy packages (autoprefixer, postcss, @astrojs/tailwind)

## Constraints
- Read-only check
- Does not modify config
- Reports for parent to act on
