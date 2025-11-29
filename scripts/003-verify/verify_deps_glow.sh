#!/bin/bash
# verify_deps_glow.sh

if ! command -v curl &> /dev/null; then echo "curl missing"; exit 1; fi
if ! command -v gpg &> /dev/null; then echo "gpg missing"; exit 1; fi
echo "Dependencies verified."
