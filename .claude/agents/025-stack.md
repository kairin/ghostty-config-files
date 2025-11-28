---
name: 025-stack
description: Extract technology stack versions from package.json. Single atomic task.
model: haiku
---

## Single Task
Parse package.json and report dependency versions.

## Input
- package_path: Path to package.json (default: astro-website/package.json)

## Key Dependencies Tracked
- astro
- tailwindcss
- @tailwindcss/vite
- daisyui

## Execution
```bash
extract_stack_versions() {
  local pkg="${1:-astro-website/package.json}"

  if [ ! -f "$pkg" ]; then
    echo "status=error"
    echo "error=package_json_not_found"
    echo "path=$pkg"
    return 1
  fi

  # Extract versions using grep/sed (no jq dependency)
  local astro=$(grep -o '"astro"[[:space:]]*:[[:space:]]*"[^"]*"' "$pkg" | grep -o '"[0-9^~]*[0-9.]*"' | tr -d '"')
  local tailwind=$(grep -o '"tailwindcss"[[:space:]]*:[[:space:]]*"[^"]*"' "$pkg" | grep -o '"[0-9^~]*[0-9.]*"' | tr -d '"')
  local tailwind_vite=$(grep -o '"@tailwindcss/vite"[[:space:]]*:[[:space:]]*"[^"]*"' "$pkg" | grep -o '"[0-9^~]*[0-9.]*"' | tr -d '"')
  local daisyui=$(grep -o '"daisyui"[[:space:]]*:[[:space:]]*"[^"]*"' "$pkg" | grep -o '"[0-9^~]*[0-9.]*"' | tr -d '"')

  # Count all dependencies
  local dep_count=$(grep -c '"[^"]*"[[:space:]]*:[[:space:]]*"[0-9^~]' "$pkg" 2>/dev/null || echo 0)

  # Output
  echo "status=success"
  echo "package=$pkg"
  echo "total_dependencies=$dep_count"
  echo ""
  echo "# Key Versions"
  echo "astro=${astro:-not_found}"
  echo "tailwindcss=${tailwind:-not_found}"
  echo "tailwindcss_vite=${tailwind_vite:-not_found}"
  echo "daisyui=${daisyui:-not_found}"

  # Check for recommended versions
  echo ""
  echo "# Version Notes"
  if [ -n "$tailwind" ]; then
    local tw_major=$(echo "$tailwind" | grep -oE '^[0-9]+')
    if [ "$tw_major" = "4" ]; then
      echo "tailwind_v4=true"
    else
      echo "tailwind_v4=false"
      echo "note=consider upgrading to Tailwind v4"
    fi
  fi
}

# Extract versions
extract_stack_versions "$PACKAGE_PATH"
```

## Output
Return ONLY:
```
status: success | error
package: <package.json path>
total_dependencies: <count>

# Key Versions
astro: <version or not_found>
tailwindcss: <version or not_found>
tailwindcss_vite: <version or not_found>
daisyui: <version or not_found>

# Version Notes
tailwind_v4: true | false
note: <upgrade suggestions if any>
```

## Examples
```
Input: package_path=astro-website/package.json
Output:
  status=success
  total_dependencies=15
  astro=5.0.0
  tailwindcss=4.1.17
  tailwindcss_vite=4.1.17
  daisyui=5.0.0
  tailwind_v4=true
```

## Constraints
- Read-only parsing
- Does not require jq
- Does not modify package.json
