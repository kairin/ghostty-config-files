# Current Ghostty Configuration Specification

## Active: Modular and Compliant Ghostty Configuration

### Status
- [x] Modularized configurations into separate files (e.g., `theme.conf`, `scroll.conf`, `layout.conf`, `keybindings.conf`), included by the main `config` file.
- [x] Ensured `config` and included files adhere to official Ghostty documentation.
- [x] Implemented clear scrollback with visible scrollbar.
- [x] Integrated productivity-focused keybindings.
- [x] Applied a consistent theme.
- [x] Updated all related documentation (`docs/CLAUDE.md`, `docs/GEMINI.md`, `.agent-os/README.md`, `.agent-os/product/mission.md`, `.agent-os/product/architecture.md`).
- [x] Enhanced all update scripts (`scripts/update_ghostty.sh`, `scripts/install_ghostty_config.sh`, `scripts/update_zig.sh`) for robustness with explicit error handling.
- [x] Implemented comprehensive configuration protection in update scripts with automatic backup, validation testing, and safe recovery mechanisms.
- [x] Tidied up the root folder by moving scripts to `scripts/` and documentation to `docs/`.
- [x] Added a root-level `setup_ghostty.sh` launcher script for simplified installation and updates on new systems.
- [ ] **Sudo Behavior**: The script should run normally, and the `sudo` password prompt should only appear after dependency checks, and only if `apt install` or other privileged operations are required.
- [ ] **No New Scripts:** Do not create new scripts to fix issues. Resolve problems within existing scripts.
- [ ] **To-Do List Confirmation:** Every task from now on must generate a to-do list that requires user confirmation before checking off anything from the to-do list.

### Next Steps
1.  **Active To-Do List:** Refer to `agent-todo.md` for the current active tasks.
2.  **Refine `config`:** Optimize and integrate new Ghostty features.
3.  **Automate Validation:** Develop scripts to validate the `config` file.
4.  **Integrate User Feedback:** Incorporate feedback for usability enhancements.
5.  **Explore Advanced Features:** Investigate and integrate advanced Ghostty features.
