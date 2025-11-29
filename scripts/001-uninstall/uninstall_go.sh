#!/bin/bash
# uninstall_go.sh

if [ -d "/usr/local/go" ]; then
    echo "Uninstalling Go..."
    sudo rm -rf /usr/local/go
    sudo rm -f /usr/local/bin/go
    sudo rm -f /usr/local/bin/gofmt
    echo "Go uninstalled."
else
    echo "Go not installed in /usr/local/go."
fi
