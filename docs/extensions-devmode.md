# Dev mode

Hot-reload extension development without repackaging. Two halves: the CLI
server (implemented, `sora-ext dev`) and the app side (contract specified
below, implementation pending — no Dart SDK in this environment).

## The CLI half: `sora-ext dev`

```sh
cd my-extension
sora-ext dev            # http://127.0.0.1:8377, live reload on
sora-ext dev --port 9000
```

What it does:

1. Validates the project once at startup and prints the result.
2. Serves the project dir on **127.0.0.1 only** — nothing ever leaves the
   device.
3. Watches files (500 ms poll, stdlib-only — no native watcher
   dependency) and on change: re-validates, prints the result, and pushes
   a reload to connected pages via server-sent events.
4. Injects a tiny live-reload snippet into served HTML. Your sources stay
   clean: nothing is written to the project.

Validation errors don't kill the server — fix the manifest, save, watch it
go green. The panel URL it prints is what the app connects to.

### `sora-ext serve` vs `sora-ext dev`

| | `dev` | `serve` |
|---|---|---|
| Serves on loopback | ✓ | ✓ |
| Live reload + re-validate | ✓ | — |
| Injects `window.soraExt` mock | — | ✓ |
| For | the real app | a desktop browser, no app |

Use `dev` with the app, `serve` without it.

## The app half: contract (spec)

The app needs an **Extensions → Connect dev server** flow implementing
this contract:

1. **Input.** A dialog accepting an `http://127.0.0.1:<port>/<entry>`
   URL. The host part MUST be a loopback literal (`127.0.0.1` or
   `::1`); anything else is rejected with "dev servers must be loopback".
   `https` is unnecessary on loopback and not required.

2. **Manifest fetch.** The app fetches `<server>/sora-extension.json`
   (the dev server exposes it at `/__soraext__/manifest.json`; the
   canonical path is the project root) and parses it with the same
   `ExtManifest.parse` used for installs. Invalid → show the error, load
   nothing.

3. **Permissions.** The permission prompt shows exactly the manifest's
   list, same as a sideload. Granting mints a token scoped to those
   permissions — identical to the installed flow (`MintToken`). No
   elevation: a dev extension gets nothing an installed one wouldn't.

4. **Panel loading.** The WebView loads the entry URL instead of the
   installed package file. The real `window.soraExt` bridge is injected —
   the mock is never used here. Mixed content: the page is http-on-
   loopback; the bridge is native, unaffected.

5. **Dev badge.** Every dev-loaded extension shows a persistent "DEV"
   badge in the Extensions list and on its panels, with the server URL.
   Tapping it offers Disconnect.

6. **Lifecycle.** Disconnect revokes the token (`RevokeToken`) and tears
   down the panels, like disabling. Dev extensions never auto-start with
   the app and are forgotten on app restart (reconnect explicitly).

7. **Release builds.** The Connect dev server entry point is compiled out
   of release builds (or behind a developer-mode toggle that is off by
   default and warns). A release app never loads code from a dev server.

### Security rationale

- Loopback-only kills the obvious attack (a LAN/Internet page pointing
  the app at evil JS).
- Same-manifest, same-prompt, same-token rules mean dev mode grants no
  extra power — it only skips packaging.
- The DEV badge + no-auto-start make it impossible to mistake a dev
  extension for an installed one, or to persist one silently.

### Out of scope (rejected)

- **Remote dev servers** (non-loopback): rejected — the threat model
  (app executing remote JS with extension permissions) is not worth the
  convenience; use `sora-ext serve` + port forwarding on your own device
  if you must.
- **Auto-reconnect on restart**: rejected — explicit reconnect keeps dev
  extensions from silently surviving into daily use.
- **Hot-swapping the manifest's permission list without re-prompt**:
  rejected — narrowing is fine silently, widening re-prompts, exactly
  like updates.
