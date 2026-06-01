# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Fixed
- `clipboard-trim-trailing-spaces` set to `false` — was silently dropping the last character when copied text ended with a space (nushell output, etc.)

## [2026-05-31]

### Fixed
- tmux: enable `set-clipboard on` for system clipboard pass-through via OSC 52 (#242)

### Added
- tmux dev layout via `dev.fish` — launches claude (left) + nushell (right) split (#240)

### Changed
- `.envrc.local` added to `.gitignore` to avoid committing local PAT overrides (#241)
- Docs aligned across CLAUDE.md / AGENTS.md / GEMINI.md after Opus review (#243)

## [2026-05-28]

### Changed
- Clean rebuild: single consolidated Ghostty config (no modular includes), font-picker script, install/uninstall scripts (#239)
