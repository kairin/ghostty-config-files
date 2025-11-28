---
name: 022-build
description: Execute npm run build for Astro project. Times the build and captures output. Single atomic task - no validation.
model: haiku
---

## Single Task
Execute `npm run build` in the Astro project directory and capture results.

## Input
- project_path: Path to Astro project (default: astro-website)

## Execution
```bash
execute_astro_build() {
  local project="${1:-astro-website}"

  # Verify project exists
  if [ ! -d "$project" ]; then
    echo "status=error"
    echo "error=project_not_found"
    return 1
  fi

  cd "$project"

  # Record start time
  local start_time=$(date +%s)

  # Execute build
  local output
  output=$(npm run build 2>&1)
  local exit_code=$?

  # Record end time
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))

  if [ $exit_code -eq 0 ]; then
    echo "status=success"
    echo "duration_seconds=$duration"
    echo "project=$project"

    # Check output directory
    if [ -d "../docs" ]; then
      local file_count=$(find ../docs -type f | wc -l)
      echo "output_dir=docs"
      echo "file_count=$file_count"
    fi
  else
    echo "status=failed"
    echo "duration_seconds=$duration"
    echo "exit_code=$exit_code"

    # Extract error summary (last 10 lines)
    local error_summary=$(echo "$output" | tail -10)
    echo "error_summary=$error_summary"

    # Categorize common errors
    if echo "$output" | grep -q "Cannot find module"; then
      echo "error_type=missing_module"
    elif echo "$output" | grep -q "ENOENT"; then
      echo "error_type=file_not_found"
    elif echo "$output" | grep -q "SyntaxError"; then
      echo "error_type=syntax_error"
    else
      echo "error_type=build_failed"
    fi
  fi
}

# Execute build
execute_astro_build "$PROJECT_PATH"
```

## Output
Return ONLY:
```
status: success | failed | error
duration_seconds: <build time in seconds>
project: <project path>
output_dir: <output directory (usually docs)>
file_count: <number of files generated>
error_type: <categorized error if failed>
error_summary: <last few lines of error output>
```

## Examples
```
Input: project_path=astro-website
Output: status=success, duration_seconds=45, project=astro-website, output_dir=docs, file_count=80

Input: project_path=astro-website (with error)
Output: status=failed, duration_seconds=12, error_type=missing_module, error_summary=...

Input: project_path=nonexistent
Output: status=error, error=project_not_found
```

## Constraints
- Does NOT run precheck (use 022-precheck first)
- Does NOT validate output (use 022-validate after)
- Captures timing for performance tracking
- Categorizes errors for parent agent
