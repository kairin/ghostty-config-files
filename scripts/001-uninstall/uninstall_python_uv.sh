#!/bin/bash
# uninstall_python_uv.sh

if command -v uv &> /dev/null; then
    echo "Uninstalling uv..."
    # UV is usually in ~/.local/bin/uv or ~/.cargo/bin/uv
    LOCATION=$(command -v uv)
    rm -f "$LOCATION"
    # Also remove ~/.local/share/uv if it exists?
    rm -rf "$HOME/.local/share/uv"
    echo "UV uninstalled."
else
    echo "UV not installed."
fi
