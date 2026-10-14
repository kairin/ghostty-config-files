# 000-0-ghostty — AI Agent Guidelines

Single source of truth for AI agents in this repository. `CLAUDE.md` and `GEMINI.md` are regular pointer files to this file, not symlinks. Do not edit them. Update instructions here only. See `~/Apps/000-0-workspace/docs/agent-instruction-files.md`.

## Security and secrets

- Never expose, print, log, commit, or include in diffs, prompts, fixtures, screenshots, or generated files any API key, token, password, credential, private key, session cookie, or other secret. Redact with `<REDACTED>`.
- Never ask the user to paste a secret into chat. Do not read or display secret-file contents. If a credential is missing, stop and explain how to provide it securely.
- Secrets live in the owner's `pass` password store. A command gets a secret only through `with-secret <service>/<name> -- <command>`. Never put a secret in `.env`, `.envrc`, `.envrc.local`, source code, config or documentation.
- These rules apply only to real secret values: a real key, token, password or credential. Documentation that tells how to make, store or use a credential is not a secret. A placeholder such as `<REDACTED>` or `PASTE-TOKEN-HERE` is not a secret. Report a secret problem only when you find a real value. Do not report placeholders or setup steps as secret problems.
- Do not send personal or sensitive data to an external service unless the user explicitly authorizes it.
- This repository is public. Do not add local absolute paths (use `~`), personal email addresses or phone numbers.

## Project overview

This repository holds the Ghostty terminal configuration for RHEL 10 and the
facts about how Ghostty is installed. Ghostty is the user Flatpak
`com.mitchellh.ghostty`, built from the signed release with Ghostty's own
Flatpak manifest. The README explains why.

This repository has no install script, hook or skill. Do not add them here.
They are in other core repositories:

| Part | Repository |
|---|---|
| `update` command that installs and rebuilds Ghostty, its installer, skill, Claude hook and tests | `000-0-ai` (`local-bin/update`, `local-bin/install-update.py`, `skills/update/`, `hooks/claude/update_reminder.py`, `tests/test_update.py`) |
| Nerd Fonts, bash and `~/.bashrc.d` setup | `000-0-dotfiles` |
| Routine maintenance | `000-0-workspace` |

A change to how Ghostty is built or updated goes into `000-0-ai`. Then update
the README of this repository if a fact here changes. The updater discovers
numeric release tags at run time and reports version evidence; its
`--check-self` local freshness check and installer `--command-only` mode also
belong to `000-0-ai`. Do not duplicate the updater here.

## Contents

- `config.ghostty`: the Ghostty configuration. Installed to
  `~/.var/app/com.mitchellh.ghostty/config/ghostty/config.ghostty`.
- `bashrc.d/90-ghostty.sh`: loads Ghostty's bash integration on the host.
  Installed to `~/.bashrc.d/90-ghostty.sh`.

## Rules for config.ghostty

- Keep one file. Do not split it into included files.
- Do not add `background-blur`. It causes crashes on Linux.
- Keep `scrollback-limit` at 50000 or lower.
- Use a font that `fc-list : family | grep 'Nerd Font Mono'` shows. The font
  must match `000-0-dotfiles/docs/nerd-fonts.md`.
- Ghostty in the Flatpak cannot inject shell integration. Keep
  `bashrc.d/90-ghostty.sh` when you change `shell-integration-features`.
- Keep the `90-` prefix. The snippet must load before
  `~/.bashrc.d/99-blesh-attach.sh` (000-0-dotfiles).

## Development workflow

Check both files before you commit:

```bash
flatpak run com.mitchellh.ghostty +validate-config --config-file="$PWD/config.ghostty"
bash -n bashrc.d/90-ghostty.sh
```

The first command must exit 0 with no output. The Flatpak can read files in
the home folder, so the repository must be in the home folder.

Then run the shared local baseline from
`000-0-workspace/docs/project-quality-checks.md`.

A task is done only when you show evidence: command output, a log line or a screenshot.

## Branches and pull requests

- Follow the `commit-push-merge` skill. Branch names are `YYYYMMDD-HHMMSS-short-name`. Never delete a branch.
- Never push to `main` directly. Make a branch, push it, and open a pull request.
- Keep `CHANGELOG.md` up to date.

## Documentation

- `README.md`: for users.
- `AGENTS.md` (this file): for agents. Update it when a tool, a command or a rule changes.

## Owner decisions and unchecked claims

- The owner's stated decision beats a general rule. Before you flag
  something, check whether the owner already decided on it (repository
  docs, AGENTS.md, earlier instructions). If they did, do not flag it again.
- Check a claim yourself before acting on it, above all a claim from an
  earlier session, a subagent or a report. Look at the file, image or data.
- Do only what was asked. Do not add new "outstanding issues" to a task, and
  do not raise again one the owner dismissed.
- Never propose deleting, purging or unpublishing anything because of a claim
  you have not checked yourself.

## Git identity

Commit as `Mister K <678459+kairin@users.noreply.github.com>`. This is the
public GitHub name and the GitHub noreply email. Do not commit with another
name or with a personal email address. Check with `git config user.name` and
`git config user.email` before you commit.

## Routine core sync

The owner requires `update` to sync all nine core repositories before release
and application checks. It must save and restore unfinished local work and
the original branch. Routine sync does not commit or push that work. A failed
sync or restoration blocks updater replacement and application updates.
See `../000-0-workspace/docs/repository-protection.md` for this exception to
the delivery workflow. The implementation belongs to `000-0-ai`.
