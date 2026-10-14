# Changelog

## 2026-10-15: Development tool checks

- Add the dotfiles doctor and installer stage before application updates.
- Document ownership, startup commands, sudo rules and the process diagram.
- Keep the full procedure in workspace and short guides in core READMEs.

## 2026-10-15: Updater 1.0.001

- Documented core repository sync before release and application checks.
- Documented local work restoration and the exception to commit/push delivery.
- Documented the updater release sequence through patch 999.


## [2026-10-15] — Updater maintenance

- Documented updater 1.0.0 (`update-v1.0.0`), its installed-file inventory,
  full vs command-only installation, release banner and `--version`.
- Documented runtime numeric-tag discovery, version evidence, per-tool failure
  isolation and the local updater freshness check owned by `000-0-ai`.

## [2026-10-11] — Agent pointer files and website artifact intent

### Changed

- `CLAUDE.md` and `GEMINI.md` are regular pointer files to `AGENTS.md`, not
  symlinks.
- Added `docs/website-artifact-intent.md` and
  `docs/website-artifact-remediation.md`. They do not change the
  configuration.

## [2026-10-11] — bash snippet renamed for ble.sh

### Changed

- Renamed `bashrc.d/ghostty.bash` to `bashrc.d/90-ghostty.sh`. bash replaces
  fish (000-0-dotfiles), and ble.sh attaches in `99-blesh-attach.sh`. The
  Ghostty snippet must load before that. Install it as
  `~/.bashrc.d/90-ghostty.sh` and remove the old `~/.bashrc.d/ghostty.bash`.

## [2026-10-11] — Flathub exception

### Changed

- README: Flathub is used only for the GNOME runtime and SDK of the Ghostty
  build. Other applications stay RPM packages. The owner confirmed this
  exception; the decision is in 000-0-dotfiles.

## [2026-10-11] — Core repository for Ghostty on RHEL 10

### Changed

- Renamed the repository from `000-222-ghostty-config-files` to
  `000-0-ghostty` and moved it to the core tier.
- Replaced the Ubuntu setup with the RHEL 10 setup. Ghostty is now the user
  Flatpak `com.mitchellh.ghostty`, built from the signed release with
  Ghostty's own manifest. The `update` command in 000-0-ai installs and
  rebuilds it.
- `config.ghostty`: the configuration for Ghostty 1.3 in the Flatpak. It uses
  the built-in `Catppuccin Mocha` theme and the `JetBrainsMono Nerd Font Mono`
  font from 000-0-dotfiles.

### Added

- `bashrc.d/ghostty.bash`: loads Ghostty's bash integration on the host,
  because the Flatpak cannot inject it.

### Removed

- The install and uninstall scripts, the font picker, the `dev` tmux
  function, and the fish, tmux and starship configuration. The shell is bash
  (000-0-dotfiles). The install command is in 000-0-ai.
- The old `.gitignore` rules for projects that are no longer in this
  repository.

Earlier history is in Git (`git log`).
