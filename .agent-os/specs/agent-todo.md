# Agent To-Do List

This document outlines the active tasks for the agent. Each task requires explicit user confirmation before being marked as complete.

*   [x] **Address `sudo` password prompting behavior:** Ensure the script runs normally, and the `sudo` password prompt appears only after dependency checks, and only if `apt install` or other privileged operations are required. (FIXED: Removed upfront sudo check from setup_ghostty.sh, sudo now only prompted when actually needed)
*   [x] **Address "Text file busy" error:** Implement logic in `scripts/update_ghostty.sh` to find and kill the process holding `/usr/bin/ghostty` busy. (IMPLEMENTED: Lines 138-148 check for and kill processes)
*   [x] **Address "Incorrect installation path with `sudo`":** Modify `setup_ghostty.sh` to correctly determine the user's home directory even when run with `sudo`.
*   [x] **Address "Output formatting":** Improve the readability of the script's output by ensuring consistent formatting.
*   [x] **Address `get_ghostty_version` bug:** Modify the `get_ghostty_version` function in `scripts/update_ghostty.sh` to return a single line.
*   [x] **Address "Failed to pull Ghostty config changes" error:** Investigate and fix the `git pull` failure in `scripts/update_ghostty.sh`. (This now includes printing the git output for verbosity and stashing local changes).
*   [x] **Resolve merge conflict in `scripts/update_ghostty.sh`:** Manually resolve the conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`) in the file.
*   [x] **Implement Zig installation:** Added automatic Zig installation with fallback to source installation in ~/Apps/zig directory. Includes apt check first, then source download/extraction with system-wide symlink creation.
*   [x] **Update Zig version to 0.14.0:** Fixed Ghostty build compatibility by updating from Zig 0.13.0 to required Zig 0.14.0 version as specified in build.zig.
*   [x] **Resolve missing build tools and dependencies:** Comprehensive solution implemented including:
    - Added essential build tools: build-essential, pkg-config, gettext, libxml2-utils
    - Added complete GTK4 development libraries: libgtk-4-dev, libadwaita-1-dev, blueprint-compiler
    - Added graphics and font libraries: freetype, harfbuzz, fontconfig, vulkan, cairo
    - Added system integration libraries: X11, Wayland, glib, oniguruma
    - Implemented intelligent dependency detection and installation with fallback options
    - Added comprehensive manual installation guide with verification steps
*   [x] **Fix library linking issues:** Identified and documented Zig library linking behavior where linkSystemLibrary2("gtk4") looks for libgtk4.so instead of libgtk-4.so, requiring proper pkg-config setup.
*   [x] **Update documentation for comprehensive build requirements:** Updated both CLAUDE.md and GEMINI.md to document:
    - Complete dependency lists and installation procedures
    - Manual installation commands for troubleshooting
    - Verification steps for GTK4 and libadwaita
    - Tool requirements for source compilation