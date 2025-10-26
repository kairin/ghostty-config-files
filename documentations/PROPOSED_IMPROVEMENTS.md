# Proposed Improvements for Repository Structure and Tooling

This document outlines a series of proposed improvements to the repository's structure, scripting, and documentation. The goal of these proposals is to enhance maintainability, reduce redundancy, and create a more modular and intuitive developer experience.

## 1. Script Consolidation

### Current State

The repository currently contains several shell scripts with overlapping functionalities:

-   `start.sh`: A monolithic script that handles the entire installation process, including dependency management, application building, and documentation generation.
-   `scripts/generate_docs_website.sh`: A script dedicated to creating and managing the Astro-based documentation website.
-   `scripts/svg_screenshot_capture.sh`: A script for capturing, managing, and embedding SVG screenshots into the documentation.

This separation of concerns is not clean, as `start.sh` often calls the other scripts, and there is a high degree of coupling between them.

### Proposed Solution

I propose consolidating these scripts into a single, more powerful `manage.sh` script with a clear subcommand structure. This approach, inspired by frameworks like Django's `manage.py`, would provide a single entry point for all development and management tasks.

**Proposed `manage.sh` structure:**

```bash
./manage.sh <command> [options]
```

**Proposed commands:**

-   `install`: Handles the initial setup and installation of the terminal environment.
    -   `--skip-deps`: Skips system dependency installation.
    -   `--skip-node`: Skips Node.js/NVM installation.
-   `docs`: Manages the documentation website.
    -   `generate`: Generates the Astro site from scratch.
    -   `build`: Builds the production version of the site.
    -   `dev`: Starts the local development server.
-   `screenshots`: Manages screenshot capture and integration.
    -   `capture <stage> [description]`: Captures a screenshot for a specific stage.
    -   `generate-gallery`: Regenerates the screenshot gallery page.
-   `update`: Handles intelligent updates of the terminal environment.
-   `validate`: Runs all validation and testing checks.

This consolidated approach would reduce code duplication, improve clarity, and make the entire system easier to maintain and extend.

## 2. Documentation Restructuring

### Current State

The documentation is currently scattered across several locations with a mix of source files and generated content:

-   `README.md`: The main entry point for users.
-   `AGENTS.md`: A large, monolithic file with instructions for AI assistants.
-   `spec-kit/`: Contains what appears to be a templating system for project specifications, with duplicated content.
-   `documentations/`: Contains a generated Astro site, not source documentation.
-   `docs/`: The output directory for the generated Astro site, which is also tracked by git.

This structure is confusing and leads to a number of issues, including redundancy, difficulty in finding information, and the commingling of source and generated files.

### Proposed Solution

I propose a more logical and centralized documentation structure:

-   **/docs (source):** This directory would become the single source of truth for all documentation. It would contain Markdown files that are then used to generate the static site.
    -   `/docs/index.md`: The main landing page for the documentation.
    -   `/docs/installation.md`: The installation guide.
    -   `/docs/usage.md`: A guide to using the terminal environment.
    -   `/docs/development/`: A section for developer-focused documentation.
        -   `/docs/development/contributing.md`: Contribution guidelines.
        -   `/docs/development/architecture.md`: An overview of the project's architecture.
        -   `/docs/development/ai-guidelines.md`: A dedicated, modular home for the content currently in `AGENTS.MD`.
-   **/docs-dist (generated):** A new directory, which should be added to `.gitignore`, to hold the generated Astro site. The `docs` directory should no longer be used for this purpose.
-   **spec-kit:** The contents of this directory should be moved to a more appropriate location, such as a `/templates` or `/prototypes` directory, to make its purpose clearer.

This new structure would be more intuitive, easier to navigate, and would cleanly separate source documentation from generated build artifacts.

## 3. Modularity Improvements

### Current State

The repository suffers from a lack of modularity in several key areas:

-   `start.sh`: As mentioned, this is a monolithic script that is difficult to read, maintain, and extend.
-   `AGENTS.md`: This file is a massive "wall of text" that combines project overviews, strict technical requirements, CI/CD instructions, and AI conversation logging rules.

### Proposed Solution

-   **`start.sh` Refactoring:** The functionality of `start.sh` should be broken down into smaller, more focused shell scripts, perhaps organized into a `/scripts/modules` directory. The main `manage.sh` script would then source and call these modules as needed. For example, there could be separate modules for `install_dependencies.sh`, `build_ghostty.sh`, and `setup_zsh.sh`.

-   **`AGENTS.md` Refactoring:** The content of `AGENTS.md` should be broken down into smaller, more targeted Markdown files within the `/docs/development/ai-guidelines/` directory. This would allow for a more organized and readable presentation of the rules and guidelines. For example:
    -   `/docs/development/ai-guidelines/overview.md`: A high-level overview of the project for AI assistants.
    -   `/docs/development/ai-guidelines/git-strategy.md`: The mandatory branch management and commit workflow.
    -   `/docs/development/ai-guidelines/local-ci-cd.md`: The local CI/CD requirements.
    -   `/docs/development/ai-guidelines/documentation.md`: The rules for documentation and logging.

By breaking down these monolithic files, we can significantly improve the modularity, readability, and maintainability of the entire repository.
