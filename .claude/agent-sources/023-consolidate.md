---
name: 023-consolidate
description: Merge duplicate directories by moving contents to target. Single atomic task.
model: haiku
---

## Single Task
Consolidate multiple directories into a single target directory.

## Input
- source_dirs: Comma-separated source directories
- target_dir: Destination directory
- dry_run: Preview only (default: false)

## Execution
```bash
consolidate_directories() {
  local sources="$1"
  local target="$2"
  local dry_run="${3:-false}"

  local moved=""
  local conflicts=""
  local errors=""

  # Create target if doesn't exist
  if [ ! -d "$target" ]; then
    if [ "$dry_run" = "true" ]; then
      echo "would_create=$target"
    else
      mkdir -p "$target"
    fi
  fi

  for source in $(echo "$sources" | tr ',' ' '); do
    [ -z "$source" ] && continue
    [ ! -d "$source" ] && { errors="${errors}not_found:$source;"; continue; }
    [ "$source" = "$target" ] && continue

    # Process each file in source
    for file in $(find "$source" -type f 2>/dev/null); do
      local relative="${file#$source/}"
      local dest="$target/$relative"

      if [ -f "$dest" ]; then
        # Conflict - file exists in target
        conflicts="${conflicts}$relative;"
      else
        if [ "$dry_run" = "true" ]; then
          moved="${moved}would_move:$file->$dest;"
        else
          mkdir -p "$(dirname \"$dest\")"
          mv "$file" "$dest" 2>&1 && moved="${moved}$file->$dest;" || errors="${errors}$file;"
        fi
      fi
    done

    # Remove empty source directory after moving
    if [ "$dry_run" = "false" ]; then
      rmdir "$source" 2>/dev/null && moved="${moved}removed_empty:$source;"
    fi
  done

  # Count results
  local moved_count=$(echo "$moved" | tr ';' '\n' | grep -c ">" || echo 0)
  local conflict_count=$(echo "$conflicts" | tr ';' '\n' | grep -c . || echo 0)
  local error_count=$(echo "$errors" | tr ';' '\n' | grep -c . || echo 0)

  # Output
  echo "status=$([ $error_count -gt 0 ] && echo 'partial' || echo 'success')"
  echo "dry_run=$dry_run"
  echo "target=$target"
  echo "moved_count=$moved_count"
  echo "conflict_count=$conflict_count"
  echo "error_count=$error_count"
  echo ""
  echo "moved=$moved"
  echo "conflicts=$conflicts"
  echo "errors=$errors"
}

# Execute consolidation
consolidate_directories "$SOURCE_DIRS" "$TARGET_DIR" "$DRY_RUN"
```

## Output
Return ONLY:
```
status: success | partial | error
dry_run: true | false
target: <target directory>
moved_count: <files moved>
conflict_count: <conflicts found>
error_count: <errors>

moved: <semicolon-separated moves>
conflicts: <files that exist in both>
errors: <failed operations>
```

## Examples
```
Input: source_dirs=docs/,documentation/, target_dir=documentations/, dry_run=false
Output: status=success, moved_count=15, conflicts=, target=documentations/

Input: source_dirs=old/,new/, target_dir=merged/, dry_run=true
Output: status=success, dry_run=true, moved=would_move:old/file.md->merged/file.md;
```

## Conflict Handling
- Does NOT overwrite existing files
- Reports conflicts for parent to decide
- Parent may need to manually resolve

## Constraints
- Does not overwrite (reports conflicts)
- Removes empty source dirs after consolidation
- Creates target directory if needed
- Supports dry_run for preview
