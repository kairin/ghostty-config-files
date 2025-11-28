---
name: 032-verify
description: Verify symlink integrity - check target exists and points correctly. Single atomic task.
model: haiku
---

## Single Task
Verify a symlink is valid and points to correct target.

## Input
- symlink_path: Path to symlink to verify
- expected_target: Expected target path (optional)

## Execution
```bash
verify_symlink() {
  local symlink="$1"
  local expected="$2"

  if [ -z "$symlink" ]; then
    echo "status=error"
    echo "error=path_required"
    return 1
  fi

  # Check if path exists
  if [ ! -e "$symlink" ] && [ ! -L "$symlink" ]; then
    echo "status=missing"
    echo "path=$symlink"
    echo "exists=false"
    return 0
  fi

  # Check if it's a symlink
  if [ ! -L "$symlink" ]; then
    echo "status=not_symlink"
    echo "path=$symlink"
    echo "type=regular_file"
    return 0
  fi

  # Get actual target
  local actual_target=$(readlink "$symlink")
  echo "path=$symlink"
  echo "is_symlink=true"
  echo "target=$actual_target"

  # Check if target exists
  if [ ! -e "$symlink" ]; then
    echo "status=broken"
    echo "target_exists=false"
    return 0
  fi

  echo "target_exists=true"

  # Compare with expected if provided
  if [ -n "$expected" ]; then
    if [ "$actual_target" = "$expected" ]; then
      echo "status=valid"
      echo "matches_expected=true"
    else
      echo "status=wrong_target"
      echo "matches_expected=false"
      echo "expected_target=$expected"
    fi
  else
    echo "status=valid"
  fi
}

# Verify symlink
verify_symlink "$SYMLINK_PATH" "$EXPECTED_TARGET"
```

## Output
Return ONLY:
```
status: valid | broken | wrong_target | not_symlink | missing | error
path: <symlink path>
is_symlink: true | false
target: <actual target path>
target_exists: true | false
matches_expected: true | false (if expected provided)
expected_target: <expected path if mismatch>
```

## Examples
```
Input: symlink_path=CLAUDE.md, expected_target=AGENTS.md
Output: status=valid, is_symlink=true, target=AGENTS.md, matches_expected=true

Input: symlink_path=GEMINI.md (broken)
Output: status=broken, target=OLD_FILE.md, target_exists=false

Input: symlink_path=README.md (regular file)
Output: status=not_symlink, type=regular_file
```

## Constraints
- Read-only verification
- Does not modify symlinks
- Reports exact state
