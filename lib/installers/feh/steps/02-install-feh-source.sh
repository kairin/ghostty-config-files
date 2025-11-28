#!/usr/bin/env bash
#
# Module: Feh - Install Source Version
# Purpose: Install feh via source build
#
set -euo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"

# 2. Load Common Utils
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "${REPO_ROOT}/lib/tasks/feh.sh"

# 3. Main Logic
main() {
    # Environment Check
    run_environment_checks || exit 1

    # Execute the task defined in lib/tasks/feh.sh
    if task_install_feh; then
        exit 0
    else
        exit 1
    fi
}

main "$@"
