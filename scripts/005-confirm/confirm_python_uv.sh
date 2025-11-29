#!/bin/bash
# confirm_python_uv.sh

# Source cargo env or local bin if needed
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

if command -v uv &> /dev/null; then
    echo "UV is installed."
    uv --version
else
    echo "UV is NOT installed."
    exit 1
fi
