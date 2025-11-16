# Box Drawing Fix - Implementation Guide

## Quick Summary

**Problem**: `printf "%-${width}s"` counts bytes, not display width. ANSI color codes add invisible bytes, causing right border misalignment.

**Solution**: Calculate display width, print string with colors intact, then manually add exact padding.

## Code Changes Required

### File: `/home/kkk/Apps/ghostty-config-files/start.sh`

#### 1. Function: `draw_box()` (Lines 182-228)

**Current (BROKEN)**:
```bash
for line in "${content[@]}"; do
    printf "${CYAN}║${NC}    %-${content_width}s    ${CYAN}║${NC}\n" "$line"
done
```

**Fixed**:
```bash
for line in "${content[@]}"; do
    local line_display=$(get_string_width "$line")
    local line_padding=$((content_width - line_display))
    printf "${CYAN}║${NC}    "
    echo -ne "$line"
    printf '%*s' "$((line_padding + 4))" ''
    printf "${CYAN}║${NC}\n"
done
```

**Also fix title line (Line 206)**:

**Current**:
```bash
printf "${CYAN}║${NC}    %-${content_width}s    ${CYAN}║${NC}\n" "$title"
```

**Fixed**:
```bash
local title_display=$(get_string_width "$title")
local title_padding=$((content_width - title_display))
printf "${CYAN}║${NC}    "
echo -ne "$title"
printf '%*s' "$((title_padding + 4))" ''
printf "${CYAN}║${NC}\n"
```

**Also fix empty lines (Lines 214, 222)**:

**Current**:
```bash
printf "${CYAN}║${NC}    %-${content_width}s    ${CYAN}║${NC}\n" ""
```

**Fixed**:
```bash
printf "${CYAN}║${NC}    "
printf '%*s' "$((content_width + 4))" ''
printf "${CYAN}║${NC}\n"
```

#### 2. Function: `draw_colored_box()` (Lines 232-279)

Apply same changes as `draw_box()` but use `${color}` instead of `${CYAN}`.

**Content lines (Line 269)**:

**Current**:
```bash
for line in "${content[@]}"; do
    printf "${color}║${NC}    %-${content_width}s    ${color}║${NC}\n" "$line"
done
```

**Fixed**:
```bash
for line in "${content[@]}"; do
    local line_display=$(get_string_width "$line")
    local line_padding=$((content_width - line_display))
    printf "${color}║${NC}    "
    echo -ne "$line"
    printf '%*s' "$((line_padding + 4))" ''
    printf "${color}║${NC}\n"
done
```

**Title line (Line 257)**:

**Current**:
```bash
printf "${color}║${NC}    %-${content_width}s    ${color}║${NC}\n" "$title"
```

**Fixed**:
```bash
local title_display=$(get_string_width "$title")
local title_padding=$((content_width - title_display))
printf "${color}║${NC}    "
echo -ne "$title"
printf '%*s' "$((title_padding + 4))" ''
printf "${color}║${NC}\n"
```

**Empty lines (Lines 265, 273)**:

**Current**:
```bash
printf "${color}║${NC}    %-${content_width}s    ${color}║${NC}\n" ""
```

**Fixed**:
```bash
printf "${color}║${NC}    "
printf '%*s' "$((content_width + 4))" ''
printf "${color}║${NC}\n"
```

#### 3. Function: `draw_header()` (Lines 281-301)

**Title line (Line 294)**:

**Current**:
```bash
printf "${CYAN}║${NC}    %-${title_width}s    ${CYAN}║${NC}\n" "$title"
```

**Fixed**:
```bash
local title_display=$(get_string_width "$title")
local title_padding=$((title_width - title_display))
printf "${CYAN}║${NC}    "
echo -ne "$title"
printf '%*s' "$((title_padding + 4))" ''
printf "${CYAN}║${NC}\n"
```

Note: In `draw_header()`, `title_width` is already calculated from `get_string_width()`, so we can reuse it.

## Testing Procedure

### 1. Run Test Suite
```bash
./test-box-color-rendering.sh
```

**Expected**: All 15 tests show perfectly aligned right borders.

### 2. Visual Inspection Checklist
- ✅ All right borders (`║`) perfectly aligned
- ✅ Colors display correctly
- ✅ Emoji don't break alignment severely
- ✅ Mixed-length content pads correctly
- ✅ Empty lines render correctly

### 3. Run Full Installation
```bash
./start.sh
```

**Expected**: All boxes throughout installation render correctly.

## Why This Works

### The Algorithm

```
Step 1: Strip ANSI codes
  Input:  "\033[0;32m✅ Success\033[0m" (24 bytes)
  Output: "✅ Success" (10 characters)

Step 2: Calculate padding
  Desired width:  30 characters
  Display width:  10 characters
  Padding needed: 20 spaces

Step 3: Print string with colors
  echo -ne "\033[0;32m✅ Success\033[0m"
  Colors preserved, displays as 10 characters

Step 4: Add exact padding
  printf '%*s' 20 ''
  Adds exactly 20 spaces

Result: Total display width = 10 + 20 = 30 characters ✅
```

### Key Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `get_string_width "$str"` | Get display width | `10` (for "✅ Success") |
| `echo -ne "$str"` | Print with colors | Displays colored text |
| `printf '%*s' $n ''` | Print N spaces | `printf '%*s' 20 ''` = 20 spaces |

## Performance Impact

**Negligible** - adds ~2ms per line:
- 1 additional `get_string_width()` call per line
- 1 subshell + 1 sed process = ~2ms
- Human perception threshold: 100ms

**Example**: Box with 10 lines = 10 × 2ms = 20ms overhead (imperceptible)

## Common Pitfalls to Avoid

### ❌ Don't Do This
```bash
# Using printf %-${width}s with ANSI codes
printf "%-30s" "${GREEN}✅ Success${NC}"
# Result: Misaligned (printf counts bytes)
```

### ✅ Do This Instead
```bash
# Calculate display width, then manual padding
display=$(get_string_width "${GREEN}✅ Success${NC}")
padding=$((30 - display))
echo -ne "${GREEN}✅ Success${NC}"
printf '%*s' "$padding" ''
# Result: Perfect alignment
```

## Verification Commands

```bash
# Check syntax
bash -n start.sh

# Run test suite
./test-box-color-rendering.sh

# Test specific function
source start.sh
draw_box "Test" "${GREEN}✅ With color${NC}" "Plain text"
```

## Rollback Plan

If issues occur:
```bash
# Restore from git
git checkout start.sh

# Or restore from backup
cp ~/.config/ghostty/start.sh.backup-TIMESTAMP start.sh
```

## Success Criteria

✅ All test cases pass
✅ Visual inspection confirms alignment
✅ Full installation completes without errors
✅ All boxes render correctly in production
✅ No performance degradation

---

**Implementation Time**: ~30 minutes
**Risk Level**: Low (non-breaking change, easy rollback)
**Testing Required**: High (visual verification critical)
