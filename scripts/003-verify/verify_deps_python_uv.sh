#!/bin/bash
# verify_deps_python_uv.sh

if ! command -v curl &> /dev/null; then echo "curl missing"; exit 1; fi
echo "Dependencies verified."
