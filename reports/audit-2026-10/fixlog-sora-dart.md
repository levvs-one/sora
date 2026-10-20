# Fix log — sora Dart/UI (audit round 1)

Branch: `bugfix/audit-2026-10-19` in `~/workspace/bug-hunt/sora`.
Scope: `sora/app` (+ `sora/docs` untouched — no doc fixes among my items).
Env: no Flutter SDK / no Linux build tools — build, `flutter analyze` and tests
could NOT be run. Every change was re-read twice; fixes are conservative.

## Fixed (13/13)

- **SORA-H8** (P1) — `app/linux/runner/my_application.cc`, `app/lib/src/desktop/desktop.dart`:
  implemented `GApplication::command_line` + `open` vfuncs in the runner; the
  link is forwarded to Dart over a new `sora.linux/deep_link` MethodChannel
  (queued as `pending_link` if the Flutter view is not up yet). Secondary
  instances no longer build a throwaway window (skip `activate` when remote).
  Dart dedups against the app_links plugin stream (same link within 5s opens
  one dialog). Covers the `open`-signal path the plugin ignores and the
  startup race before the plugin registers.
- **SORA-M17** (P2) — `app/lib/src/sora.dart`: removed the 1s `getStats` polling
  timer (no UI consumer; burned IPC + battery and toasted on unused data).
  `readStats()` kept as a documented on-demand API.
- **SORA-M18** (P2) — `app/lib/src/ui/logs.dart`: added `Set<Int64> _known` for
  O(1) duplicate detection; the per-event linear `indexWhere` now runs only on
  the rare repeat-update path. Kept in sync in `_reload`/`_older`/`_arrive`/`_clear`.
- **SORA-M19** (P2) — `app/lib/src/ui/about.dart`: `confirmDrop` now asks on the
  app-wide navigator (`desktop.navigator.currentContext`) instead of the About
  screen's context, so leaving About mid-download no longer silently discards
  the verified update. `install()` signature untouched — explicit decline still
  returns silently (covered by `updates_test.dart` 'cancel' scenario).
- **SORA-M20** (P2) — `app/lib/src/sora.dart`: `probe()` throttles
  `notifyListeners()` to one per 300ms (final `finally` still notifies);
  tray tooltip updates batch along with it.
- **SORA-L22** (P2) — `app/lib/src/ui/settings_screen.dart`: generation token
  (`_copiedStamp`) so a second tap's timer can't hide the first tap's
  "copied" indicator early.
- **SORA-L23** (P2) — `app/lib/src/sora.dart`: `connect()` with `_link == null`
  now sets `failure = CoreFailure.unavailable` + `notifyListeners()` instead of
  a silent no-op (home screen shows "core missing"; cleared on core connect).
- **SORA-L24** (P2) — `app/lib/src/sora.dart`: orb tap during
  `Phase.disconnecting` sets `_connectQueued`; `connect()` runs once the
  in-flight disconnect lands (phase==off). A redundant `disconnect()` while one
  is in flight clears the queue (latest explicit intent wins — covers quit()).
- **SORA-L25** (P2) — `app/lib/src/sora.dart`: `_saveHistory` chain gets
  `.catchError` so one failed write can't poison all subsequent history saves.
- **SORA-L26** (P2) — `app/lib/src/core/pipe.dart`: `done` is now
  `_pipe?.closed ?? Future.value()` instead of force-unwrapping `_pipe!`.
- **SORA-L27** (P2) — `app/lib/src/desktop/desktop.dart`: `_tell()` wraps
  `_notifications.show()` in try/catch — a failing backend no longer escapes
  as an unhandled async error.
- **SORA-L28** (P2) — `app/lib/src/desktop/desktop.dart`: `restartAfterUpdate()`
  relaunches `Platform.resolvedExecutable` instead of hardcoded `/usr/bin/sora`.
- **SORA-L29** (P2) — `app/windows/runner/main.cpp`: second instance retries
  `SendAppLinkToInstance()` (40×100ms) while the first instance has no window
  yet, instead of silently exiting and dropping the link; stops retrying once
  a window exists (failed send then means e.g. elevated target). Mutex is now
  created before the first send attempt, so cold start has no added delay.

## Skipped

- None. (Note, out of scope: SORA-L18 DoH docs live in `sora/docs` but were not
  among the assigned 13 items; left for the docs pass.)

## Verification notes for the owner

- `flutter analyze` / `flutter test` / Linux & Windows builds were impossible
  here — please run them on a dev machine before merging.
- H8/L29 need manual tests: click `sora://add/...` with the app running,
  during startup, and on Windows while the first instance is still starting.
- M19: start an update download, leave the About screen, wait for completion —
  the drop-connection dialog should appear over the current screen.
