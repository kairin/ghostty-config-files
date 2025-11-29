#!/bin/bash
# verify_deps_fastfetch.sh

if ! command -v curl &> /dev/null; then
    echo "curl is missing."
    exit 1
fi
echo "Dependencies verified."
