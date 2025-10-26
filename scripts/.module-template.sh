#!/bin/bash
# Module: [MODULE_NAME].sh
# Purpose: [Brief description of module's purpose]
# Dependencies: [List external dependencies: ghostty, node, etc. or "None"]
# Modules Required: [List required bash modules or "None"]
# Exit Codes: 0=success, 1=general failure, 2=[specific error if needed]

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

# Function: [function_name]
# Purpose: [What this function does]
# Args: $1=[description], $2=[description] (optional)
# Returns: 0 on success, non-zero on failure
# Side Effects: [Files modified, services started, environment variables set, etc.]
[function_name]() {
    local arg1="$1"
    local arg2="${2:-default_value}"

    # Validation
    if [[ -z "$arg1" ]]; then
        echo "ERROR: arg1 is required" >&2
        return 1
    fi

    # Implementation
    echo "INFO: Executing [function_name] with arg1=$arg1, arg2=$arg2"

    # Call private helper if needed
    _private_helper "$arg1"

    return 0
}

# ============================================================
# PRIVATE FUNCTIONS (Internal helpers)
# ============================================================

# Function: _private_helper
# Purpose: Internal helper function (not part of public API)
# Args: $1=[description]
# Returns: 0 on success, non-zero on failure
_private_helper() {
    local arg="$1"

    # Implementation
    echo "DEBUG: Internal helper processing: $arg" >&2

    return 0
}

# ============================================================
# MAIN EXECUTION (Skipped when sourced)
# ============================================================

if [[ "${SOURCED_FOR_TESTING}" -eq 0 ]]; then
    # Execute when run directly, not when sourced
    # Parse command-line arguments if needed
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 <arg1> [arg2]" >&2
        exit 1
    fi

    # Call main public function
    [function_name] "$@"
    exit $?
fi
