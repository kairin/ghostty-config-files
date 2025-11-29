#!/bin/bash
# install_deps_vhs.sh

echo "Installing dependencies for vhs..."
sudo apt-get update
sudo apt-get install -y curl gpg ttyd ffmpeg chromium-browser
# VHS needs ttyd and ffmpeg and a browser usually.
