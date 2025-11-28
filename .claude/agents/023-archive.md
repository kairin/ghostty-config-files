---
name: 023-archive
description: Move files/directories to archive location with timestamp. Single atomic task.
model: haiku
---

## Single Task
Archive files or directories by moving them to a designated archive location.

## Input
- targets: Comma-separated files/directories to archive
- archive_dir: Archive destination (default: documentations/archive)
- add_timestamp: Add timestamp to archived items (default: true)

## Execution
```bash
archive_items() {
  local targets="$1"
  local archive_dir="${2:-documentations/archive}"
  local add_timestamp="${3:-true}"

  local archived=""
  local errors=""
  local timestamp=$(date +"%Y%m%d-%H%M%S")

  # Create archive directory if needed
  if [ ! -d "$archive_dir" ]; then
    mkdir -p "$archive_dir"
  fi

  for target in $(echo "$targets" | tr ',' ' '); do
    [ -z "$target" ] && continue

    if [ ! -e "$target" ]; then
      errors="${errors}not_found:$target;"
      continue
    fi

    local basename=$(basename "$target")

    # Build destination name
    local dest_name
    if [ "$add_timestamp" = "true" ]; then
      dest_name="${timestamp}-${basename}"
    else
      dest_name="$basename"
    fi

    local dest_path="$archive_dir/$dest_name"

    # Handle existing destination
    if [ -e "$dest_path" ]; then
      dest_name="${timestamp}-${RANDOM}-${basename}"
      dest_path="$archive_dir/$dest_name"
    fi

    # Move to archive
    mv "$target" "$dest_path" 2>&1
    if [ $? -eq 0 ]; then
      archived="${archived}$target->$dest_path;"
    else
      errors="${errors}move_failed:$target;"
    fi
  done

  # Count results
  local archived_count=$(echo "$archived" | tr ';' '\n' | grep -c ">" || echo 0)
  local error_count=$(echo "$errors" | tr ';' '\n' | grep -c . || echo 0)

  # Output
  if [ $error_count -gt 0 ] && [ $archived_count -gt 0 ]; then
    echo "status=partial"
  elif [ $archived_count -gt 0 ]; then
    echo "status=success"
  else
    echo "status=error"
  fi

  echo "archive_dir=$archive_dir"
  echo "archived_count=$archived_count"
  echo "error_count=$error_count"
  echo ""
  echo "archived=$archived"
  echo "errors=$errors"
}

# Execute archive
archive_items "$TARGETS" "$ARCHIVE_DIR" "$ADD_TIMESTAMP"
```

## Output
Return ONLY:
```
status: success | partial | error
archive_dir: <archive destination>
archived_count: <items archived>
error_count: <errors>

archived: <semicolon-separated source->dest>
errors: <failed items>
```

## Examples
```
Input: targets=old_config.sh,backup/, archive_dir=documentations/archive
Output: status=success, archived_count=2, archived=old_config.sh->documentations/archive/20251128-143052-old_config.sh;

Input: targets=missing.txt
Output: status=error, error_count=1, errors=not_found:missing.txt;
```

## Archive Naming
With `add_timestamp=true`:
- `file.sh` → `20251128-143052-file.sh`
- `dir/` → `20251128-143052-dir/`

## Constraints
- Moves (not copies) to archive
- Adds timestamp prefix by default
- Creates archive directory if needed
- Does not overwrite existing archives
