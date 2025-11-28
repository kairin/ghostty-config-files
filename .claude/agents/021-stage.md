---
name: 021-stage
description: Pre-commit security scan and staging. Checks for sensitive files, validates .gitignore, scans for large files. Single atomic task - no decision making.
model: haiku
---

## Single Task
Perform security validation on files before staging, then stage all changes.

## Input
- stage_all: Whether to stage all files (default: true)
- files: Specific files to stage (if stage_all=false)

## Security Checks
1. Sensitive file patterns: `.env`, `.eml`, `*credentials*`, `*secret*`, `*key*`, `*.pem`
2. Large files: Warn >10MB, Halt >100MB
3. .gitignore coverage for sensitive patterns

## Execution
```bash
pre_commit_security_scan() {
  local has_issues="false"
  local issues=""

  # Check for sensitive files in staging area
  local sensitive_patterns='\.(env|eml|key|pem)$|credentials|secret'
  local sensitive_files=$(git diff --cached --name-only 2>/dev/null | grep -E "$sensitive_patterns" || true)

  if [ -n "$sensitive_files" ]; then
    has_issues="true"
    issues="${issues}sensitive_files:${sensitive_files};"
  fi

  # Check for large files
  for file in $(git diff --cached --name-only 2>/dev/null); do
    if [ -f "$file" ]; then
      local size_mb=$(du -m "$file" 2>/dev/null | cut -f1)
      if [ "$size_mb" -gt 100 ]; then
        has_issues="true"
        issues="${issues}large_file_halt:${file}(${size_mb}MB);"
      elif [ "$size_mb" -gt 10 ]; then
        issues="${issues}large_file_warn:${file}(${size_mb}MB);"
      fi
    fi
  done

  # Check .gitignore coverage
  if ! git check-ignore -q .env 2>/dev/null; then
    issues="${issues}gitignore_warning:.env not in .gitignore;"
  fi

  if [ "$has_issues" = "true" ]; then
    echo "status=blocked"
    echo "issues=$issues"
  else
    echo "status=clean"
    echo "issues=$issues"
  fi
}

stage_files() {
  local stage_all="${1:-true}"

  if [ "$stage_all" = "true" ]; then
    git add -A
  else
    git add $FILES
  fi

  # Report what was staged
  local staged_count=$(git diff --cached --name-only | wc -l)
  echo "staged_count=$staged_count"
  echo "staged_files=$(git diff --cached --name-only | tr '\n' ',')"
}

# Run security scan
pre_commit_security_scan

# Stage if clean (or warnings only)
if [ "$status" != "blocked" ]; then
  stage_files "$STAGE_ALL"
fi
```

## Output
Return ONLY:
```
status: clean | blocked | warning
staged_count: <number of files staged>
staged_files: <comma-separated list>
issues: <semicolon-separated issues if any>
```

## Examples
```
Input: stage_all=true
Output: status=clean, staged_count=5, staged_files=file1.md,file2.sh,file3.ts

Input: stage_all=true (with .env in staging)
Output: status=blocked, issues=sensitive_files:.env;, staged_count=0

Input: stage_all=true (with large file warning)
Output: status=warning, staged_count=3, issues=large_file_warn:video.mp4(15MB);
```

## Constraints
- Blocks on sensitive files (security first)
- Warns but allows large files 10-100MB
- Blocks on files >100MB
- Does not commit - staging only
