---
name: 032-git-mode
description: Check git tracking mode for symlinks (follow vs preserve). Single atomic task.
model: haiku
---

## Single Task
Check how git is configured to handle symlinks for a file.

## Input
- file_path: Path to check git tracking for
- repo_root: Repository root (default: current directory)

## Execution
```bash
check_git_mode() {
  local file="$1"
  local repo="${2:-.}"

  if [ -z "$file" ]; then
    echo "status=error"
    echo "error=file_path_required"
    return 1
  fi

  # Check if in git repo
  if ! git -C "$repo" rev-parse --is-inside-work-tree &>/dev/null; then
    echo "status=error"
    echo "error=not_a_git_repo"
    return 1
  fi

  # Check if file is tracked
  if ! git -C "$repo" ls-files --error-unmatch "$file" &>/dev/null; then
    echo "status=untracked"
    echo "file=$file"
    echo "in_git=false"
    return 0
  fi

  echo "file=$file"
  echo "in_git=true"

  # Check if it's a symlink on disk
  if [ -L "$file" ]; then
    echo "disk_type=symlink"
    echo "symlink_target=$(readlink "$file")"
  else
    echo "disk_type=regular"
  fi

  # Check what git thinks it is
  local git_mode=$(git -C "$repo" ls-files -s "$file" 2>/dev/null | awk '{print $1}')

  case "$git_mode" in
    120000)
      echo "git_type=symlink"
      echo "mode=$git_mode"
      echo "status=ok"
      ;;
    100644|100755)
      echo "git_type=regular_file"
      echo "mode=$git_mode"
      if [ -L "$file" ]; then
        echo "status=mismatch"
        echo "note=disk is symlink but git tracks as file"
      else
        echo "status=ok"
      fi
      ;;
    *)
      echo "git_type=unknown"
      echo "mode=$git_mode"
      echo "status=unknown"
      ;;
  esac

  # Check core.symlinks config
  local symlinks_config=$(git -C "$repo" config --get core.symlinks 2>/dev/null || echo "true")
  echo "core_symlinks=$symlinks_config"
}

# Check git mode
check_git_mode "$FILE_PATH" "$REPO_ROOT"
```

## Output
Return ONLY:
```
status: ok | mismatch | untracked | error
file: <file path>
in_git: true | false
disk_type: symlink | regular
git_type: symlink | regular_file | unknown
mode: <git mode number>
symlink_target: <target if symlink>
core_symlinks: true | false
note: <explanation if mismatch>
```

## Examples
```
Input: file_path=CLAUDE.md
Output: status=ok, disk_type=symlink, git_type=symlink, mode=120000

Input: file_path=README.md
Output: status=ok, disk_type=regular, git_type=regular_file, mode=100644

Input: file_path=untracked.txt
Output: status=untracked, in_git=false
```

## Constraints
- Read-only git operations
- Does not modify tracking
- Reports mode numbers
