#!/bin/bash
# confirm_go.sh

export PATH=$PATH:/usr/local/go/bin

if command -v go &> /dev/null; then
    echo "Go is installed."
    go version
else
    echo "Go is NOT installed."
    exit 1
fi
