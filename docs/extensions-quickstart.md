# Your first Sora extension in 10 minutes

Build a panel extension with live connection stats. You need Go (to build
`sora-ext`) — no Flutter, no app source.

Normative spec: [extensions.md](extensions.md). API reference:
[extensions-api.md](extensions-api.md). Recipes:
[extensions-cookbook.md](extensions-cookbook.md).

## 0:00 — Get `sora-ext`

```sh
cd tools/sora-ext
go build -o sora-ext ./cmd/sora-ext
# put it on PATH, e.g. sudo install sora-ext /usr/local/bin
```

## 0:01 — Scaffold

```sh
sora-ext scaffold com.example.stats --author "Jane Doe" --identity github:janedoe
cd stats
```

You get: `sora-extension.json` (manifest), `panel.html`, `sora-ext.d.ts`
(TypeScript definitions for `window.soraExt`), a README, and a fresh
signing keypair (`author.key` secret — keep offline, never commit;
`author.pub`).

## 0:02 — Dev mode

```sh
sora-ext dev
```

This serves the project on `http://127.0.0.1:8377` (loopback only) with
live reload, and re-validates the manifest on every save. In the app:
**Extensions → Connect dev server** → paste the URL. The panel loads from
your machine; edit `panel.html`, save, watch it refresh.

No app at hand? Test in a desktop browser instead:

```sh
sora-ext serve   # injects a mocked window.soraExt
```

Open `http://127.0.0.1:8378/panel.html`. The mock enforces permissions
like the real host and logs every API call at
`/__soraext__/calls`. Fire events with:

```sh
curl -X POST http://127.0.0.1:8378/__soraext__/event -d '{"kind":"session.connected"}'
```

## 0:05 — Make it yours

`panel.html` already lists live connections and sends a test notification.
The only API is `window.soraExt` (see `sora-ext.d.ts`):

```js
const conns = await window.soraExt.call('getConnections');
await window.soraExt.call('notify', {title: 'Hi', body: '...'});
const settings = await window.soraExt.call('getSettings');
await window.soraExt.call('setSettings', {refresh_seconds: 10});
window.soraExt.onEvent((kind) => { /* session.connected … */ });
```

Calling a method without its permission rejects the promise — request only
what you need in `sora-extension.json` → `permissions`.

## 0:07 — Validate

```sh
sora-ext validate
```

Errors point at `file:line:col` with a fix hint, e.g.:

```
error[unknown-permission]: unknown permission "net.fech"
  --> sora-extension.json:17:5
 17 |     "net.fech"
   |     ^^^^^^^^^^ did you mean "net.fetch"?
```

`validate` is the pre-publish gate — `publish` runs it too.

## 0:08 — Pack, sign, publish

```sh
sora-ext pack . -o stats.soraext
sora-ext sign --key author.key stats.soraext
sora-ext publish stats.soraext
```

`publish` checks: validation passes, the package is signed, dangerous
permissions are acknowledged (`--ack-dangerous`), then prints the artifact
hash and a catalog-entry snippet ready to submit.

## 0:10 — Install

In the app: **Extensions → Install from file** → pick `stats.soraext`.
Review the permission prompt, enable, done. Updates are staged with
rollback; widening permissions re-prompts.

## Next

- [API reference](extensions-api.md) — every method, event and error code
- [Cookbook](extensions-cookbook.md) — settings forms, themes, background
  workers, testing patterns
- [Dev mode & app contract](extensions-devmode.md) — how the app side works
- `examples/` — `hello-panel`, `theme-midnight`, `net-hook-dpi`,
  `routing-split`: working, signed, minimal
