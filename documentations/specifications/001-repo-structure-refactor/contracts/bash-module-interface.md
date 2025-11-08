# Contract: Bash Module Interface

**Version**: 1.0.0
**Type**: Bash Function API
**Stability**: Stable (once released)

## Overview

This contract defines the interface requirements for all bash modules in the `scripts/` directory. Every module must conform to this interface to ensure consistency, testability, and integration with the `manage.sh` orchestrator.

---

## Module Structure Contract

### Required Header

Every module MUST include a header with the following format:

```bash
#!/bin/bash
# Module: <filename>.sh
# Purpose: <One-sentence description of single responsibility>
# Dependencies: <comma-separated list of system commands> or "None"
# Modules Required: <comma-separated list of bash modules> or "None"
# Exit Codes: <code>=<meaning>, <code>=<meaning>, ...
```

**Example**:
```bash
#!/bin/bash
# Module: install_node.sh
# Purpose: Install Node.js via NVM to specified version
# Dependencies: curl, git
# Modules Required: None
# Exit Codes: 0=success, 1=installation failed, 2=curl not found
```

### Required Sections

Every module MUST include these sections in order:

1. **Shebang and Header** (documented above)
2. **Strict Mode** (`set -euo pipefail`)
3. **Sourcing Guard** (BASH_SOURCE check)
4. **Public Functions** (module's API)
5. **Private Functions** (internal helpers, prefixed with `_`)
6. **Main Execution** (skipped when sourced)

**Complete Template**:
```bash
#!/bin/bash
# Module: example_module.sh
# Purpose: Example module demonstrating required structure
# Dependencies: None
# Modules Required: None
# Exit Codes: 0=success, 1=failure

set -euo pipefail

# Module-level guard: Allow sourcing for testing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    SOURCED_FOR_TESTING=1
else
    SOURCED_FOR_TESTING=0
fi

# ============================================================
# PUBLIC FUNCTIONS (Module API)
# ============================================================

# Function: public_function_name
# Purpose: <What this function does>
# Args: $1=<description>, $2=<description> (optional)
# Returns: 0 on success, non-zero on failure
# Side Effects: <Files modified, services started, etc.>
public_function_name() {
    local arg1="$1"
    local arg2="${2:-default_value}"

    # Implementation
    return 0
}

# ============================================================
# PRIVATE FUNCTIONS (Internal helpers)
# ============================================================

# Function: _private_helper
# Purpose: Internal helper function (not part of public API)
# Args: $1=<description>
# Returns: 0 on success, non-zero on failure
_private_helper() {
    local arg="$1"

    # Implementation
    return 0
}

# ============================================================
# MAIN EXECUTION (Skipped when sourced)
# ============================================================

if [[ "${SOURCED_FOR_TESTING}" -eq 0 ]]; then
    # Execute when run directly, not when sourced
    public_function_name "$@"
    exit $?
fi
```

---

## Function Naming Contract

### Public Functions

**Format**: `<verb>_<noun>[_<qualifier>]`

**Rules**:
- MUST start with a verb (e.g., `install`, `validate`, `configure`, `check`)
- MUST be descriptive and self-documenting
- MUST NOT include module name (redundant)
- SHOULD be under 30 characters

**Examples**:
- ✅ `install_node_version`
- ✅ `validate_ghostty_config`
- ✅ `check_system_dependencies`
- ❌ `install_node_install_node` (redundant)
- ❌ `do_stuff` (not descriptive)
- ❌ `a` (too short)

### Private Functions

**Format**: `_<verb>_<noun>[_<qualifier>]`

**Rules**:
- MUST start with underscore (indicates private/internal)
- MUST follow same naming conventions as public functions
- MUST NOT be called from outside the module

**Examples**:
- ✅ `_download_zig_tarball`
- ✅ `_extract_version_number`
- ✅ `_cleanup_temp_files`
- ❌ `_helper` (not descriptive)

---

## Function Documentation Contract

### Required Documentation

Every public function MUST have header comment with:
- **Purpose**: One sentence describing what function does
- **Args**: Each argument with type and description
- **Returns**: Exit codes and their meanings
- **Side Effects**: Files modified, services started, environment variables set

**Example**:
```bash
# Function: install_node_version
# Purpose: Install specified Node.js version using NVM
# Args:
#   $1 (string): Node.js version to install (e.g., "20.10.0", "lts")
#   $2 (boolean, optional): Skip validation after install (default: false)
# Returns:
#   0: Installation successful and validated
#   1: Installation failed (NVM error, download failure)
#   2: Missing dependency (curl or git not found)
#   3: Installation succeeded but validation failed
# Side Effects:
#   - Downloads Node.js binary to ~/.nvm/versions/
#   - Modifies ~/.bashrc to source NVM
#   - Sets NVM_DIR environment variable
install_node_version() {
    # Implementation
}
```

### Optional Documentation

Private functions SHOULD have documentation but MAY omit if:
- Function is obvious from name and implementation (<10 lines)
- Function is only called once within same file
- Function is purely a utility wrapper

---

## Argument Handling Contract

### Positional Arguments

**Rules**:
- MUST validate all required arguments exist
- MUST provide defaults for optional arguments
- MUST use descriptive local variable names
- SHOULD limit to 5 or fewer positional arguments

**Example**:
```bash
install_node_version() {
    # Validate required arguments
    if [[ $# -lt 1 ]]; then
        echo "ERROR: Missing required argument: version" >&2
        echo "Usage: install_node_version <version> [skip_validation]" >&2
        return 1
    fi

    # Assign to descriptive local variables
    local version="$1"
    local skip_validation="${2:-false}"

    # Implementation
}
```

### Named Options (Optional)

For complex functions, MAY use named options:

**Example**:
```bash
configure_theme() {
    local theme=""
    local mode=""
    local apply_now=false

    # Parse named options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --theme) theme="$2"; shift 2 ;;
            --mode) mode="$2"; shift 2 ;;
            --apply-now) apply_now=true; shift ;;
            *) echo "ERROR: Unknown option: $1" >&2; return 1 ;;
        esac
    done

    # Validate required options
    if [[ -z "$theme" ]]; then
        echo "ERROR: --theme is required" >&2
        return 1
    fi

    # Implementation
}
```

---

## Return Code Contract

### Standard Exit Codes

| Code | Meaning | When to Use |
|------|---------|-------------|
| 0 | Success | Operation completed successfully |
| 1 | General failure | Operation failed for unspecified reason |
| 2 | Missing dependency | Required system command or module not found |
| 3 | Validation failure | Operation succeeded but validation failed |
| 4 | Configuration error | Invalid configuration detected |
| 5 | Permission denied | Insufficient permissions for operation |
| 6 | Network error | Download or network operation failed |
| 7 | User cancellation | User aborted operation (SIGINT) |

### Return Code Usage

**Rules**:
- MUST return 0 for success
- MUST return non-zero for any failure
- SHOULD use standard exit codes when applicable
- MUST document custom exit codes in function header
- MUST NOT use `exit` inside functions (breaks sourcing)

**Correct**:
```bash
install_node_version() {
    if ! command -v curl >/dev/null 2>&1; then
        echo "ERROR: curl is required" >&2
        return 2  # Missing dependency
    fi

    if ! nvm install "$version"; then
        echo "ERROR: Installation failed" >&2
        return 1  # General failure
    fi

    return 0  # Success
}
```

**Incorrect**:
```bash
install_node_version() {
    command -v curl || exit 2  # ❌ exit breaks sourcing
    nvm install "$version"      # ❌ no error handling
}
```

---

## Error Handling Contract

### Required Error Handling

Every module MUST:
- Use `set -euo pipefail` at module level
- Check command existence before use with `command -v`
- Validate file/directory existence before access
- Provide meaningful error messages to stderr
- Return appropriate exit codes

**Example**:
```bash
build_ghostty() {
    # Check dependencies
    if ! command -v zig >/dev/null 2>&1; then
        echo "ERROR: Zig compiler not found" >&2
        echo "Install with: manage.sh update --component zig" >&2
        return 2
    fi

    # Validate source directory
    if [[ ! -d "$GHOSTTY_SRC" ]]; then
        echo "ERROR: Ghostty source directory not found: $GHOSTTY_SRC" >&2
        return 4
    fi

    # Attempt build with error handling
    if ! (cd "$GHOSTTY_SRC" && zig build -Doptimize=ReleaseFast); then
        echo "ERROR: Ghostty build failed" >&2
        echo "Check build logs for details" >&2
        return 1
    fi

    return 0
}
```

### Error Message Format

Error messages MUST follow this format:

```
ERROR: <Brief description of what failed>
<Optional: Additional context>
<Optional: Suggested fix>
```

**Examples**:
```bash
echo "ERROR: Node.js installation failed" >&2
echo "Reason: Download timeout (60s limit exceeded)" >&2
echo "Fix: Check internet connection and retry" >&2
```

---

## Side Effects Contract

### Declaration

Functions with side effects MUST document them in header:

**Side Effects Categories**:
- File system modifications (create, delete, modify files/directories)
- Environment variables (set, unset, modify)
- System state changes (start/stop services, modify system packages)
- Network operations (downloads, API calls)
- User interaction (prompts, input required)

**Example**:
```bash
# Function: configure_zsh_plugins
# Purpose: Install and configure Oh My ZSH plugins
# Args: $1 (array): List of plugin names
# Returns: 0 on success, 1 on failure
# Side Effects:
#   - Modifies ~/.zshrc (adds plugin configuration)
#   - Downloads plugins to ~/.oh-my-zsh/custom/plugins/
#   - Sets ZSH_CUSTOM environment variable
#   - May prompt user for confirmation if --interactive flag present
configure_zsh_plugins() {
    # Implementation
}
```

### Idempotency

Functions SHOULD be idempotent when possible:
- Check current state before making changes
- Skip operations if already complete
- Document non-idempotent operations clearly

**Example**:
```bash
install_node_version() {
    local version="$1"

    # Check if already installed (idempotency)
    if command -v node >/dev/null 2>&1; then
        local current_version
        current_version=$(node --version | tr -d 'v')

        if [[ "$current_version" == "$version" ]]; then
            echo "Node.js $version already installed" >&2
            return 0  # Skip installation
        fi
    fi

    # Proceed with installation
    nvm install "$version"
}
```

---

## Testing Contract

### Sourcing Support

Every module MUST support sourcing for testing:

**Required Guard**:
```bash
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    SOURCED_FOR_TESTING=1
else
    SOURCED_FOR_TESTING=0
fi

# ... functions ...

if [[ "${SOURCED_FOR_TESTING}" -eq 0 ]]; then
    # Main execution (only when not sourced)
    main_function "$@"
fi
```

### Test Mode Support

Modules SHOULD support test mode via environment variable:

**Example**:
```bash
install_node_version() {
    local version="$1"

    # Test mode: Skip actual installation
    if [[ "${TEST_MODE:-0}" == "1" ]]; then
        echo "TEST MODE: Would install Node.js $version"
        return 0
    fi

    # Normal execution
    nvm install "$version"
}
```

### Mocking Support

Modules SHOULD allow mocking of external commands:

**Example**:
```bash
_download_file() {
    local url="$1"
    local output="$2"

    # Allow test mocking via function override
    if declare -f curl >/dev/null 2>&1; then
        curl -L "$url" -o "$output"
    else
        # Fallback to real curl
        command curl -L "$url" -o "$output"
    fi
}
```

---

## Performance Contract

### Execution Time

Functions MUST:
- Complete in reasonable time (<60 seconds for most operations)
- Provide progress feedback for operations >10 seconds
- Be independently testable in <10 seconds

**Progress Feedback Example**:
```bash
build_ghostty() {
    echo "🔄 Building Ghostty (this may take 2-3 minutes)..." >&2

    local start_time
    start_time=$(date +%s)

    (cd "$GHOSTTY_SRC" && zig build -Doptimize=ReleaseFast)

    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo "✅ Build completed in ${duration}s" >&2
}
```

### Resource Usage

Functions SHOULD:
- Minimize disk I/O (batch operations when possible)
- Clean up temporary files on exit
- Avoid spawning excessive subprocesses

---

## Dependency Management Contract

### System Dependencies

Modules MUST:
- Declare all system command dependencies in header
- Check for command existence before use
- Provide helpful error messages when missing

**Example**:
```bash
#!/bin/bash
# Module: install_zig.sh
# Dependencies: curl, tar, sha256sum

check_dependencies() {
    local missing=()

    command -v curl >/dev/null 2>&1 || missing+=("curl")
    command -v tar >/dev/null 2>&1 || missing+=("tar")
    command -v sha256sum >/dev/null 2>&1 || missing+=("sha256sum")

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "ERROR: Missing required dependencies: ${missing[*]}" >&2
        echo "Install with: sudo apt install ${missing[*]}" >&2
        return 2
    fi

    return 0
}
```

### Module Dependencies

Modules MUST:
- Declare bash module dependencies in header
- Use relative sourcing from same directory
- Avoid circular dependencies

**Example**:
```bash
#!/bin/bash
# Module: build_ghostty.sh
# Modules Required: install_zig.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required module
source "$SCRIPT_DIR/install_zig.sh"

build_ghostty() {
    # Use function from install_zig.sh
    if ! validate_zig_installation; then
        echo "ERROR: Zig not installed" >&2
        return 2
    fi

    # Build Ghostty
    zig build -Doptimize=ReleaseFast
}
```

---

## Output Contract

### Standard Output (stdout)

Use stdout ONLY for:
- Function return values (when using command substitution)
- Structured data output (JSON, CSV, etc.)
- Primary command result

**Example**:
```bash
get_node_version() {
    # Output to stdout for command substitution
    node --version | tr -d 'v'
}

# Usage:
version=$(get_node_version)
```

### Error Output (stderr)

Use stderr for:
- Error messages
- Warning messages
- Progress indicators
- Diagnostic information
- User-facing messages

**Example**:
```bash
install_node_version() {
    echo "🔄 Installing Node.js $version..." >&2  # Progress to stderr

    if ! nvm install "$version"; then
        echo "ERROR: Installation failed" >&2  # Error to stderr
        return 1
    fi

    echo "✅ Node.js $version installed" >&2  # Success to stderr
    return 0
}
```

---

## Versioning Contract

### Semantic Versioning

Modules follow semantic versioning:
- **MAJOR**: Breaking changes to public function signatures
- **MINOR**: New public functions (backward compatible)
- **PATCH**: Bug fixes, internal refactoring

**Version Declaration** (in module header):
```bash
#!/bin/bash
# Module: install_node.sh
# Version: 1.2.0
```

### Compatibility

Modules MUST:
- Maintain backward compatibility within same MAJOR version
- Document breaking changes in module header
- Provide migration guidance for breaking changes

---

## Contract Validation

### ShellCheck Compliance

All modules MUST pass ShellCheck with zero errors:

```bash
shellcheck -x scripts/*.sh
```

### Syntax Validation

All modules MUST pass bash syntax validation:

```bash
bash -n scripts/*.sh
```

### Dependency Validation

All modules MUST pass dependency cycle detection:

```bash
./scripts/validate_module_deps.sh
```

### Test Coverage

All public functions MUST have unit tests:
- Minimum 1 test per public function
- Test happy path and error cases
- Tests must complete in <10 seconds per module

---

## Contract Examples

### Minimal Valid Module

```bash
#!/bin/bash
# Module: example.sh
# Purpose: Example minimal valid module
# Dependencies: None
# Modules Required: None
# Exit Codes: 0=success

set -euo pipefail

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    SOURCED_FOR_TESTING=1
else
    SOURCED_FOR_TESTING=0
fi

# Function: say_hello
# Purpose: Print greeting message
# Args: None
# Returns: Always 0
say_hello() {
    echo "Hello from minimal module!" >&2
    return 0
}

if [[ "${SOURCED_FOR_TESTING}" -eq 0 ]]; then
    say_hello
fi
```

### Complex Module Example

See `/scripts/install_node.sh` (to be created during implementation) for a complete real-world example demonstrating all contract requirements.

---

## Contract Enforcement

### Pre-Commit Validation

Before committing, all modules must pass:
```bash
./local-infra/runners/validate-modules.sh
```

This checks:
- ShellCheck compliance
- Header completeness
- Dependency declarations
- Function documentation
- Test coverage

### CI/CD Validation

Local CI/CD pipeline enforces:
- All modules pass contract validation
- All unit tests pass (<10s per module)
- No circular dependencies detected
- Performance targets met

---

## References

- **Google Bash Style Guide**: https://google.github.io/styleguide/shellguide.html
- **ShellCheck**: https://www.shellcheck.net/
- **Bash Best Practices**: https://bertvv.github.io/cheat-sheets/Bash.html
- **Module Template**: `/scripts/.module-template.sh` (to be created)

---

## Contract Versioning

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-10-27 | Initial contract definition |
