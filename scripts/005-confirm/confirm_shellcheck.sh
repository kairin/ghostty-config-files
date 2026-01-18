#!/bin/bash
# Confirm ShellCheck installation

if command -v shellcheck &>/dev/null; then
    echo "ShellCheck is installed:"
    shellcheck --version
    exit 0
else
    echo "ERROR: ShellCheck is not installed"
    exit 1
fi
