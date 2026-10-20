# Fix log — sora, round 3 (regression from round 1)

## R3-1. E2E handshake regression from the SORA-H2 authz fix

**Symptom.** `TestClientTalksToTheCoreOverTheTransport` (`core/control/e2e_test.go`)
failed 3/3 on the branch with
`Handshake() error = ... write unix @->.../core.sock: write: broken pipe`,
while passing on clean main.

**Root cause.** Interaction of two round-1 fixes, not a bad test:
- SORA-M1 wrapped every accepted connection in `*countedConn` (connection
  accounting) inside `Listener.Accept()`. `Accept` itself still called
  `peerOf` on the raw `*net.UnixConn`, so the accept-time check kept working.
- SORA-H2 added `peerCredentials.ServerHandshake` for the gRPC server, which
  re-derived the peer via `peerOf(rawConn)` — but by then the connection was
  already the `*countedConn` wrapper. The `connection.(*net.UnixConn)` type
  assertion in `peerOf` failed → `Peer{Verified: false}` → on Linux
  (`socketMode = 0o666`) `DefaultAuthorize` returned `AuthNone` → the server
  refused the handshake and closed the connection → client saw a broken pipe.
  The same latent break existed on Windows (`countedConn` does not promote
  `Fd()`, so `peerOf` would report "not a named pipe").

The test relied on legitimate behavior (same-user peer ⇒ AuthControl), so the
security fix was kept and the code was fixed instead.

**Fix** (commit `f0b45cb`):
- `core/ipc/ipc.go`: `countedConn` gained `UnderlyingConn() net.Conn`,
  exposing the wrapped transport connection for peer inspection.
- `core/ipc/authlevel.go`: new `unwrapConn` helper (+ `connUnwrapper`
  interface); `peerCredentials.ServerHandshake` now calls
  `peerOf(unwrapConn(rawConn))`. The wrapped connection is still returned to
  gRPC, so M1 connection accounting is untouched.
- `core/ipc/authlevel_test.go`: new regression test
  `TestServerHandshakeSeesThroughListenerWrapping` — runs `ServerHandshake`
  on a connection accepted through the real `Listener` (i.e. wrapped) and
  asserts admission, and `AuthControl` for the same-user peer on Linux.

**Verification.**
- `go test ./control/ -run TestClientTalksToTheCoreOverTheTransport -count=3` — green 3/3.
- `go test ./ipc/ -count=1` — green (incl. the new regression test).
- `go build ./...` and `go vet ./control/ ./ipc/` — clean.
- No push (branch `bugfix/audit-2026-10-19` stays local).
