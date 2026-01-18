---
name: 022-precheck
description: Verify Astro project structure before build. Checks for required files, directories, Node.js version, and npm packages. Single atomic task.
model: haiku
---

## Single Task
Validate Astro project prerequisites before running build.

## Input
- project_path: Path to Astro project (default: astro-website)

## Checks Performed
1. Project structure (astro.config.mjs, package.json, src/)
2. Node.js version (requires 18+)
3. npm packages installed (node_modules exists)
4. Required dependencies present

## Execution
```bash
precheck_astro_project() {
  local project="${1:-astro-website}"
  local issues=""
  local warnings=""

  # Check project directory exists
  if [ ! -d "$project" ]; then
    echo "status=error"
    echo "error=project_not_found"
    echo "path=$project"
    return 1
  fi

  cd "$project"

  # Check required files
  [ ! -f "astro.config.mjs" ] && issues="${issues}missing:astro.config.mjs;"
  [ ! -f "package.json" ] && issues="${issues}missing:package.json;"
  [ ! -d "src" ] && issues="${issues}missing:src/;"

  # Check node_modules
  if [ ! -d "node_modules" ]; then
    issues="${issues}missing:node_modules(run npm install);"
  fi

  # Check Node.js version
  local node_version=$(node -v 2>/dev/null | sed 's/v//' | cut -d. -f1)
  if [ -z "$node_version" ]; then
    issues="${issues}node_not_installed;"
  elif [ "$node_version" -lt 18 ]; then
    issues="${issues}node_version_too_old(need 18+, have $node_version);"
  fi

  # Check npm available
  if ! command -v npm &>/dev/null; then
    issues="${issues}npm_not_installed;"
  fi

  # Check astro.config.mjs size (should be <30 lines per standards)
  if [ -f "astro.config.mjs" ]; then
    local config_lines=$(wc -l < astro.config.mjs)
    if [ "$config_lines" -gt 30 ]; then
      warnings="${warnings}astro_config_large(${config_lines} lines, target <30);"
    fi
  fi

  # Output results
  if [ -n "$issues" ]; then
    echo "status=failed"
    echo "issues=$issues"
    echo "warnings=$warnings"
  else
    echo "status=ready"
    echo "project=$project"
    echo "node_version=$node_version"
    echo "warnings=$warnings"
  fi
}

# Run precheck
precheck_astro_project "$PROJECT_PATH"
```

## Output
Return ONLY:
```
status: ready | failed | error
project: <project path>
node_version: <Node.js major version>
issues: <semicolon-separated blocking issues>
warnings: <semicolon-separated non-blocking warnings>
error: <error message if status=error>
```

## Examples
```
Input: project_path=astro-website
Output: status=ready, project=astro-website, node_version=22, warnings=

Input: project_path=astro-website (missing node_modules)
Output: status=failed, issues=missing:node_modules(run npm install);

Input: project_path=nonexistent
Output: status=error, error=project_not_found, path=nonexistent
```

## Constraints
- Read-only checks, does not modify anything
- Does not run npm install (parent decides)
- Reports all issues, not just first one
