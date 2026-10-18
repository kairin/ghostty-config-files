# Ghostty implementation handoff and acceptance gate

Date: 2026-10-18. This document records the round 2 follow-up checklist for the Ghostty
implementation handoff. It does not authorize installation, activation, or
software release on other computers.

> **Round 2 review (2026-10-18).** A verified review found two P0 deletion
> defects in `local-bin/ghostty-build.py` and ruled GH-01 `tested`, not
> `accepted`. Read the `000-0-ghostty` section of the
> [round 2 review](../../000-0-workspace/docs/core-agy-review-round2-2026-10-18.md)
> before you continue. Do items GH-01.R1 and GH-01.R2 first.

## agy round 2 checklist (2026-10-18)

This checklist is the working copy of the round 2 tasks for `000-0-ghostty`. The [round 2 review](../../000-0-workspace/docs/core-agy-review-round2-2026-10-18.md#000-0-ghostty) gives the evidence, and the [decision record](../../000-0-workspace/docs/core-agy-decisions-2026-10-18.md) gives the reasons for the decided items. Where an earlier status in this file disagrees with this section, use this section.

### Status

"Ruled now" is the verified status. "Target" is the status after every task below passes on this host, before any delivery.

| Task | Ruled now | Target |
|---|---|---|
| GH-01 | tested | accepted |
| GH-02 | tested | tested (unchanged) |
| GH-03 | accepted | accepted (unchanged) |

### Why round 1 failed here

**GH-01 (accepted -> tested, PARTIAL).** Created: local-bin/ghostty-build.py (1235 lines), tests/test_ghostty_build.py (19 tests), AGENTS.md amendment. Met: timeout tree-kill (T1/T2 PASS), tar path containment (T7), receipt durability (T8a), falsy failures (T10), no competing framework, no consumer switch. Defects (P0 class, reproduced with appendix script `ghostty_extra_tests.py`): T5: `staging_prefix` pointing at an arbitrary directory is deleted when download fails (`cleanup_transient` :917-920 rmtree's it without any validation); T5b: with `install_prefix="/"` rejected as unsafe, :895-896 still rmtree's the arbitrary `staging_prefix` before any path validation of it; `verify_candidate_binary` :569/:580/:589/:594 rmtree's staging on every failure without validation; T9: `promote_staged_install` :648-649 `finally: rmtree(backup_path)` runs after a failed `shutil.move` even when the restore at :642-646 did not happen (install_path exists partially), leaving `install_prefix` with only `partial` and the previous install gone. No production caller passes `staging_prefix` today, but it is the exact "unsafe deletion / failure damages prior state" class the gate names, in new code. Plan 993 "copy from exact AI input without behavior changes": extraction deliberately changed return types, dry-run path, manifest path handling, cleanup scope, receipt/rollback; the gate (step 3) requires intentional changes recorded separately; no parity table exists. Ledger consumer_check "embeds ... with behavioral parity" is false (AI-03). `incomplete: []` wrong.

**GH-02 (tested, PARTIAL).** Synthetic coverage and honest aarch64 `incomplete` confirmed. Defects in the record: consumer_check "update_ghostty writes and validates ~/.local/share/update/ghostty-provenance.json" names a file that no code writes (grep 0 hits in 000-0-ai; module default is `~/.local/share/ghostty-build/provenance-receipt.json` :766); the active updater writes no receipt. `incomplete` must also state that no real x86_64 signed build was performed with this module (installed 1.3.1 predates it; no receipt exists). Production path runs `flatpak-builder --install` directly; the candidate gate is reachable only with `staging_prefix` (document or wire). `expected_sha256` is never supplied by the update path.

**GH-03 (accepted, PARTIAL).** AGENTS.md:186 says the default receipt path is `~/.local/share/update/receipts/ghostty.json`; code :766 uses `~/.local/share/ghostty-build/provenance-receipt.json`. README:255-273 says the builder persists a receipt "on successful updates" while the active updater does not (README:204-206 partly mitigates). docs/agy-handoff.md GH-03b itself records fresh-window GUI checks and secondary computers as blocked/incomplete; the ledger has `incomplete: []`.

### Do not delete or overwrite

- In every repository: Git branches, tags, stashes, reflog, untracked and ignored files. Do not run `git reset --hard`, `git clean`, a force push or a branch delete. Do not delete a dated receipt or a historical document.
- In `000-0-ghostty`: The previous Ghostty install at `install_prefix` until the new install is verified. The backup until the promotion succeeds. A caller-supplied `staging_prefix` that is outside the build cache. `~/.config/ghostty/`, `~/.bashrc.d/90-ghostty.sh`, provenance receipts and installed Flatpak apps other than unused runtimes.
- Allowed deletion in `000-0-ghostty`: The work directory and staging directory that this run created under the build cache. The cache entry of the version that this run built, after a verified install.

Apply the six delete rules of the [preservation contract](../../000-0-workspace/docs/core-agy-review-round2-2026-10-18.md#preservation-contract-what-you-must-not-delete-or-overwrite) to every delete, move or replace operation.

### Tasks

Do the tasks from top to bottom. Each line gives: ID | parent or source | priority | files | what to do | acceptance check with its negative case | depends on. Tick a box only after its acceptance check passes and you have recorded the real command and exit code.

- [ ] **GH-01.R1** | GH-01 | P0 | local-bin/ghostty-build.py:844-920 (build_ghostty), :564-601 (verify_candidate_binary) | Validate `staging_prefix` before any deletion: it must be a non-symlink directory (or nonexistent) whose resolved parent is `cache_resolved` (or an explicit `build_root`), not `/`, `$HOME`, `APPS_ROOT` or an ancestor; run this validation at the top of `build_ghostty` and in `verify_candidate_binary`; never rmtree a path that failed validation (return the error instead). Remove the rmtree at :895-896. | Rerun appendix script `ghostty_extra_tests.py`: T5 and T5b PASS (victim dir survives); new unit tests: staging_prefix = sentinel dir outside cache -> BuildResult(False, "unsafe staging_prefix") and sentinel intact; staging_prefix under cache -> cleaned on failure. T1/T2/T6/T7/T8 still PASS. | none
- [ ] **GH-01.R2** | GH-01 | P0 | ghostty-build.py:632-651 promote_staged_install | Only delete `backup_path` after a successful move; on failure restore from backup whenever `backup_path` exists (remove partial `install_path` first), and if restore fails keep the backup and say so in the message ("backup retained at ..."). Drop the `finally` rmtree. | T9 PASS: after a mid-move failure the previous install is intact (or the backup exists and the message names it); positive promote test still passes. | none
- [ ] **GH-01.R3** | GH-01 | P1 | docs/agy-handoff.md (or AGENTS.md section) + ledger GH-01 | Write the extraction parity table: baseline `update` d5a7d00 build_ghostty/update_ghostty (168-239) vs module, listing each intentional difference (return types, dry-run, manifest path/cwd, manifest regex, cleanup scope, arch gate, authenticated metadata, receipt, rollback). Gate step 3. | Table present; every verifier item in GH report #1 appears; ledger `incomplete` no longer empty until R1/R2 land. | none
- [ ] **GH-01.R4** | GH-01 | P1 | ghostty-build.py helper names (`run`, `fetch`, `gh_json`, `github_metadata`, `parse_version`, `show`, `ERROR`, `main`) | Coordinate with AI-01.R1: either accept namespacing by the builder or rename payload helpers with a `gb_` prefix so the payload cannot shadow core names. | Rebuilt artifact has no duplicate top-level names; module tests still 19 OK. | AI-01.R1 decision
- [ ] **GH-02.R5'** | decision record (replaces the OWNER mark) | driver script in the scratchpad (not committed), `docs/agy-handoff.md` receipt section, ledger GH-02 | Run the disposable x86_64 build with the current module (after GH-01.R1/R2), read the receipt in a new process, record tag/archive sha256/signature/build flags/Flatpak commit/architecture; remove the scratch installation. | Receipt fields present; `flatpak list --app` unchanged before/after; `du` of scratch removed. aarch64 row `incomplete (office host)`. | GH-01.R1, GH-01.R2.
- [ ] **GH-01.R5** | GH-01 | P2 | ledger GH-01 | Correct consumer_check (no behavioral-parity proof exists; builder accepts the file shape only); re-pin identities (HEAD 1f30d3bd + dirty: AGENTS.md, CHANGELOG.md, README.md; untracked docs/agy-handoff.md, local-bin/ghostty-build.py, tests/test_ghostty_build.py); `incomplete` lists R1-R4. | Entry consistent. | none
- [ ] **GH-02.R1** | GH-02 | P2 | ledger GH-02 | Remove the `ghostty-provenance.json` consumer_check; state that the active updater writes no receipt; add to `incomplete`: "no real x86_64 signed build with this module; aarch64 pending". | Entry consistent. | none
- [ ] **GH-02.R2** | GH-02 | P2 | tests/test_ghostty_build.py | Add a real-minisign negative test (junk `.minisig` -> rejected) and a positive with a generated test key (verifier T3/T4 as template); skip only if `minisign` missing and record as incomplete. | Tests pass with real binary. | none
- [ ] **GH-02.R3** | GH-02 | P2 | ghostty-build.py build_ghostty / README | Either wire the candidate gate into the production path or document plainly that `flatpak-builder --install` installs directly and the gate is caller-only; supply `expected_sha256` from release metadata when available or document why not. | Doc/test consistent with code. | none
- [ ] **GH-03.R1** | GH-03 | P2 | AGENTS.md:186 | Fix default receipt path to `~/.local/share/ghostty-build/provenance-receipt.json` (or `$XDG_DATA_HOME/ghostty-build/...`, or `GHOSTTY_PROVENANCE_RECEIPT_PATH`). | Text equals ghostty-build.py:753-766. | none
- [ ] **GH-03.R2** | GH-03 | P2 | README.md:255-273; ledger GH-03 | Qualify the receipt claim as module-only until cutover; ledger `incomplete`: fresh-window GUI checks on this host, other computers, per docs/agy-handoff.md GH-03b. | Consistent with handoff. | none
- [ ] **GH-02.R4** | GH-02 | P3 | receipt fields | Record manifest sha256 and signature-file digest; tighten flatpak_commit regex to hex; require architecture. | Tests for each. | none

### Physical constraints (not agy work on this host)

- GH-02 aarch64 signed build on the office host (Fedora Asahi, aarch64, 16 KiB pages).

