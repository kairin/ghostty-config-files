---
name: 025-structure
description: Verify critical project directories and files exist. Single atomic task.
model: haiku
---

## Single Task
Check that required project structure elements exist.

## Input
- root_path: Project root (default: current directory)

## Required Structure
- Directories: configs/ghostty, astro-website, .claude/agents, .github/workflows
- Files: AGENTS.md, README.md, start.sh, package.json

## Execution
```bash
verify_structure() {
  local root="${1:-.}"
  local missing_dirs=""
  local missing_files=""
  local present_dirs=""
  local present_files=""

  # Required directories
  local req_dirs="configs/ghostty astro-website .claude/agents .github/workflows .runners-local/workflows documentations"

  for dir in $req_dirs; do
    if [ -d "$root/$dir" ]; then
      present_dirs="${present_dirs}$dir;"
    else
      missing_dirs="${missing_dirs}$dir;"
    fi
  done

  # Required files
  local req_files="AGENTS.md README.md start.sh"

  for file in $req_files; do
    if [ -f "$root/$file" ]; then
      present_files="${present_files}$file;"
    else
      missing_files="${missing_files}$file;"
    fi
  done

  # Count results
  local missing_dir_count=$(echo "$missing_dirs" | tr ';' '\n' | grep -c . || echo 0)
  local missing_file_count=$(echo "$missing_files" | tr ';' '\n' | grep -c . || echo 0)
  local total_missing=$((missing_dir_count + missing_file_count))

  # Output
  if [ $total_missing -eq 0 ]; then
    echo "status=complete"
  else
    echo "status=incomplete"
  fi

  echo "root=$root"
  echo "missing_dir_count=$missing_dir_count"
  echo "missing_file_count=$missing_file_count"
  echo ""
  echo "present_dirs=$present_dirs"
  echo "present_files=$present_files"
  echo "missing_dirs=$missing_dirs"
  echo "missing_files=$missing_files"
}

# Verify structure
verify_structure "$ROOT_PATH"
```

## Output
Return ONLY:
```
status: complete | incomplete
root: <project root>
missing_dir_count: <count>
missing_file_count: <count>

present_dirs: <semicolon-separated present directories>
present_files: <semicolon-separated present files>
missing_dirs: <semicolon-separated missing directories>
missing_files: <semicolon-separated missing files>
```

## Examples
```
Input: root_path=.
Output:
  status=complete
  missing_dir_count=0
  missing_file_count=0
  present_dirs=configs/ghostty;astro-website;.claude/agents;...

Input: root_path=. (missing .github/workflows)
Output:
  status=incomplete
  missing_dir_count=1
  missing_dirs=.github/workflows;
```

## Constraints
- Read-only verification
- Does not create missing items
- Parent decides recovery action
