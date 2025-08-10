# Agent To-Do List

This document outlines the active tasks for the agent. Each task requires explicit user confirmation before being marked as complete.

*   [ ] **Address `sudo` password prompting behavior:** Ensure the script runs normally, and the `sudo` password prompt appears only after dependency checks, and only if `apt install` or other privileged operations are required.
*   [ ] **Address "Text file busy" error:** Implement logic in `scripts/update_ghostty.sh` to find and kill the process holding `/usr/bin/ghostty` busy.
*   [x] **Address "Incorrect installation path with `sudo`":** Modify `setup_ghostty.sh` to correctly determine the user's home directory even when run with `sudo`.
*   [x] **Address "Output formatting":** Improve the readability of the script's output by ensuring consistent formatting.
*   [x] **Address `get_ghostty_version` bug:** Modify the `get_ghostty_version` function in `scripts/update_ghostty.sh` to return a single line.
*   [x] **Address "Failed to pull Ghostty config changes" error:** Investigate and fix the `git pull` failure in `scripts/update_ghostty.sh`. (This now includes printing the git output for verbosity and stashing local changes).
