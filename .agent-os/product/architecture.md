# Ghostty Configuration Architecture

This repository's architecture is centered around a **single, consolidated Ghostty configuration file (`config`)** located at the root of the repository. This approach simplifies management, enhances maintainability, and ensures compliance with official Ghostty documentation.

## Core Principles:

1.  **Centralized Configuration:** All Ghostty settings, including font, theme, keybindings, and scroll behavior, are unified within the `config` file. This eliminates the need for multiple scattered configuration files and reduces redundancy.

2.  **Documentation Compliance:** The configuration is meticulously crafted to align with the official Ghostty documentation (https://ghostty.org/docs/config). This ensures forward compatibility and leverages the full capabilities of Ghostty.

3.  **Usability-Driven Design:** The configuration is structured to directly support the repository's mission of enhancing Ghostty's usability. This includes:
    -   **Clear Scrollback:** Settings for `scrollback-limit`, `scrollbar`, and `scrollbar-auto-hide` are explicitly defined to provide a large, easily navigable scrollback buffer with a consistently visible scrollbar.
    -   **Optimized Keybindings:** Keybindings are integrated directly into the `config` file, providing a comprehensive and productivity-focused set of shortcuts.
    -   **Consistent Theming:** Theme settings are applied globally from the `config` file, ensuring a unified visual experience.

4.  **Simplified Maintenance:** By consolidating settings, updates and debugging become more straightforward. Changes can be made in a single location, reducing the risk of inconsistencies.

## Configuration Application:

Ghostty directly consumes this `config` file upon startup. Any modifications to the `config` file can be reloaded within Ghostty using the `reload_config` action (e.g., `cmd+s>r` as defined in the keybindings).

This architectural approach ensures a robust, efficient, and user-friendly Ghostty experience.
