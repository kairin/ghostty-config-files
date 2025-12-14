#!/bin/bash
# verify_deps_go.sh

if ! command -v curl &> /dev/null; then echo "curl missing"; exit 1; fi
if ! command -v wget &> /dev/null; then echo "wget missing"; exit 1; fi
if ! command -v tar &> /dev/null; then echo "tar missing"; exit 1; fi
echo "Dependencies verified."
