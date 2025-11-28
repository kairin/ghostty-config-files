---
name: 033-final
description: Final verification after symlink operations. Single atomic task.
model: haiku
---

## Single Task
Perform final verification that symlink operation succeeded.

## Input
- symlink_path: Path that should be a symlink
- expected_target: Expected target of symlink
- verify_content: Also verify content matches source (default: false)

## Execution
```bash
final_verify() {
  local symlink="$1"
  local expected="$2"
  local verify_content="${3:-false}"

  if [ -z "$symlink" ] || [ -z "$expected" ]; then
    echo "status=error"
    echo "error=symlink_and_target_required"
    return 1
  fi

  echo "symlink=$symlink"
  echo "expected_target=$expected"

  # Check symlink exists
  if [ ! -L "$symlink" ]; then
    if [ -e "$symlink" ]; then
      echo "status=not_symlink"
      echo "actual_type=regular_file"
    else
      echo "status=missing"
    fi
    return 0
  fi

  # Check target
  local actual=$(readlink "$symlink")
  echo "actual_target=$actual"

  if [ "$actual" != "$expected" ]; then
    echo "status=wrong_target"
    return 0
  fi

  # Check target exists
  if [ ! -e "$symlink" ]; then
    echo "status=broken"
    echo "target_exists=false"
    return 0
  fi

  echo "target_exists=true"

  # Content verification if requested
  if [ "$verify_content" = "true" ]; then
    # Hash the resolved content
    local hash
    if command -v md5sum &>/dev/null; then
      hash=$(md5sum "$symlink" | cut -d' ' -f1)
    elif command -v md5 &>/dev/null; then
      hash=$(md5 -q "$symlink")
    fi
    echo "content_hash=$hash"
  fi

  # Git tracking status
  if git ls-files --error-unmatch "$symlink" &>/dev/null; then
    echo "git_tracked=true"
    local mode=$(git ls-files -s "$symlink" 2>/dev/null | awk '{print $1}')
    echo "git_mode=$mode"
    if [ "$mode" = "120000" ]; then
      echo "git_type=symlink"
    else
      echo "git_type=regular"
    fi
  else
    echo "git_tracked=false"
  fi

  echo "status=verified"
}

# Final verification
final_verify "$SYMLINK_PATH" "$EXPECTED_TARGET" "$VERIFY_CONTENT"
```

## Output
Return ONLY:
```
status: verified | wrong_target | broken | not_symlink | missing | error
symlink: <symlink path>
expected_target: <expected target>
actual_target: <actual target>
target_exists: true | false
content_hash: <md5 if verify_content>
git_tracked: true | false
git_mode: <git mode number>
git_type: symlink | regular
```

## Examples
```
Input: symlink_path=CLAUDE.md, expected_target=AGENTS.md
Output: status=verified, actual_target=AGENTS.md, target_exists=true, git_tracked=true

Input: symlink_path=GEMINI.md, expected_target=AGENTS.md (wrong)
Output: status=wrong_target, actual_target=OLD.md

Input: symlink_path=broken.md
Output: status=broken, target_exists=false
```

## Constraints
- Read-only verification
- Optional content hash
- Reports git tracking status
