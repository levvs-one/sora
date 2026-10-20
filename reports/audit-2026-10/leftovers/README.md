# Leftovers — local working state preserved for completeness

These files never became commits during the program. They are preserved
here so that the repository holds literally all of the work; each item's
status is stated honestly. None of them needs to be applied: in every case
the final result reached the branch through later commits.

- `stash0-l10n-wip.patch`, `stash1-l10n-wip.patch` — the two git stashes
  left in the sora clone by detail-fix agents (l10n work-in-progress
  snapshots, 2026-10-20). Stashes do not travel with a branch push, so they
  are exported as patches. The l10n work itself was completed and committed
  through later repair commits and the passes (F3 keys verified in all 32
  locales in pass 3); these snapshots are mid-work state, kept for the
  record.
- `d17-dns-tests.patch` — the D17 DNS test patch from the detail-fix
  department, delivered as a patch file rather than a commit.
- `d35-chains-profiles_worktree.patch` — the D35 worktree patch. Verified
  superseded: its functional hunk (`chainHopMissing` validation in
  `app/lib/src/chains.dart`, `FeatureChains` in the engine catalog) is in
  the branch.
- `d7-engine-backup/` — the D07 agent's uncommitted engine files backup.
  The work landed later (`singBoxFloor` is in `core/engine/catalog.go`,
  the ECH `query_server_name` handling in `core/engine`); the backup is
  stale.
- `754ebca-perf-nit.patch` — the 10-line perf commit the final audit
  found orphaned by a branch reset, exported from the git object store.
  Performance work of the optimizer departments supersedes it.
