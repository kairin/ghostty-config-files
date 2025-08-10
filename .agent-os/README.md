# Ghostty Configuration Agent-OS Documentation

This directory contains documentation related to the Ghostty configuration repository's mission, architecture, and development specifications.

- `product/`: Defines the mission and architectural principles.
- `specs/`: Contains current development specifications and guidelines.
- `scripts/`: Contains utility scripts for installation and updates.
- `docs/`: Contains general documentation for the Ghostty configuration.

This documentation ensures the Ghostty configuration remains compliant, modular, and usable. The provided scripts (`scripts/update_ghostty.sh`, `scripts/install_ghostty_config.sh`, `scripts/update_zig.sh`) have been enhanced for robustness with explicit error handling and comprehensive configuration protection mechanisms. It is recommended to always review their output for successful completion.

## Enhanced Script Features

The update scripts now include:

*   **Configuration Backup and Validation**: Automatic backup of working configurations before any changes, with validation testing and automatic restoration if issues are detected.
*   **Compatibility Testing**: Post-installation configuration testing against new Ghostty versions to catch breaking changes.
*   **Safe Recovery**: Automatic fallback to last known working configuration without manual intervention.

## Agent Guidelines

*   **Sudo Behavior**: The script should run normally, and the `sudo` password prompt should only appear after dependency checks, and only if `apt install` or other privileged operations are required.
*   **No New Scripts:** Do not create new scripts to fix issues. Resolve problems within existing scripts.
*   **To-Do List Confirmation:** Every task from now on must generate a to-do list that requires user confirmation before checking off anything from the to-do list.

*   **To-Do List Management:** The to-do list is maintained as part of the agent's internal state and is presented to the user for tracking and confirmation. It is not stored in a persistent file within the repository.