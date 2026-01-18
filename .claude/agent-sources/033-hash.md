---
name: 033-hash
description: Calculate content hash for file comparison. Single atomic task.
model: haiku
---

## Single Task
Calculate MD5 hash of file content for comparison.

## Input
- file_path: Path to file to hash
- follow_symlinks: Follow symlinks to hash target content (default: true)

## Execution
```bash
calculate_hash() {
  local file="$1"
  local follow="${2:-true}"

  if [ -z "$file" ]; then
    echo "status=error"
    echo "error=file_path_required"
    return 1
  fi

  echo "path=$file"

  # Check existence
  if [ ! -e "$file" ] && [ ! -L "$file" ]; then
    echo "status=missing"
    echo "exists=false"
    return 0
  fi

  # Handle symlinks
  if [ -L "$file" ]; then
    echo "is_symlink=true"
    echo "symlink_target=$(readlink "$file")"

    if [ "$follow" = "true" ]; then
      if [ ! -e "$file" ]; then
        echo "status=broken_symlink"
        return 0
      fi
      echo "hashing=target_content"
    else
      # Hash the symlink path itself
      local hash=$(echo "$(readlink "$file")" | md5sum | cut -d' ' -f1)
      echo "status=ok"
      echo "hash=$hash"
      echo "hashing=symlink_path"
      return 0
    fi
  else
    echo "is_symlink=false"
  fi

  # Check if it's a file
  if [ ! -f "$file" ]; then
    echo "status=not_a_file"
    return 0
  fi

  # Calculate hash
  local hash
  if command -v md5sum &>/dev/null; then
    hash=$(md5sum "$file" | cut -d' ' -f1)
  elif command -v md5 &>/dev/null; then
    hash=$(md5 -q "$file")
  else
    echo "status=error"
    echo "error=no_hash_tool"
    return 1
  fi

  local size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo 0)

  echo "status=ok"
  echo "hash=$hash"
  echo "size_bytes=$size"
  echo "algorithm=md5"
}

# Calculate hash
calculate_hash "$FILE_PATH" "$FOLLOW_SYMLINKS"
```

## Output
Return ONLY:
```
status: ok | missing | broken_symlink | not_a_file | error
path: <file path>
hash: <md5 hash>
is_symlink: true | false
symlink_target: <target if symlink>
hashing: target_content | symlink_path
size_bytes: <file size>
algorithm: md5
```

## Examples
```
Input: file_path=AGENTS.md
Output: status=ok, hash=abc123..., size_bytes=32000, algorithm=md5

Input: file_path=CLAUDE.md (symlink), follow_symlinks=true
Output: status=ok, is_symlink=true, hashing=target_content, hash=abc123...

Input: file_path=broken_link.md (broken)
Output: status=broken_symlink, symlink_target=missing.md
```

## Constraints
- Uses MD5 for speed (not cryptographic security)
- Can hash symlink path or target content
- Reports size alongside hash
