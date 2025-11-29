#!/bin/bash
# verify_deps_vhs.sh

if ! command -v curl &> /dev/null; then echo "curl missing"; exit 1; fi
if ! command -v gpg &> /dev/null; then echo "gpg missing"; exit 1; fi
# ttyd and ffmpeg are good to check too
if ! command -v ffmpeg &> /dev/null; then echo "ffmpeg missing"; exit 1; fi
echo "Dependencies verified."
