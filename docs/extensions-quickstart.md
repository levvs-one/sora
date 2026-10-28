# Your first Sora extension in 10 minutes

Build a panel extension with live connection stats. You need Go (to build
`sora-ext`), no Flutter, no app source.

Normative spec: [extensions.md](extensions.md). API reference:
[extensions-api.md](extensions-api.md). Recipes:
[extensions-cookbook.md](extensions-cookbook.md).

## 0:00, Get `sora-ext`

```sh
cd tools/sora-ext
go build -o sora-ext ./cmd/sora-ext
# put it on PATH, e.g. sudo install sora-ext /usr/local/bin
```

## 0:01, Scaffold

```sh
sora-ext scaffold com.example.stats --author "Jane Doe" --identity github:janedoe
cd stats
```

You get: `sora-extension.json` (manifest), `panel.html`, `sora-ext.d.ts`
(TypeScript definitions for `window.soraExt`), a README, and a fresh
signing keypair (`.sora/author.key` secret, keep offline, never commit;
`author.pub`).

## 0:02, Dev mode

```sh
sora-ext dev
```

This serves the project on `http://127.0.0.1:8377` (loopback only) with
live reload, and re-validates the manifest on every save. The app dev-server
connection flow is still a [specified contract](extensions-devmode.md).
For the current browser preview use `serve` below; for the real app build,
sign and install a package as described later.

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

## 0:05, Make it yours

`panel.html` already lists live connections and sends a test notification.
The only API is `window.soraExt` (see `sora-ext.d.ts`):

```js
const conns = await window.soraExt.call('getConnections');
await window.soraExt.call('notify', {title: 'Hi', body: '...'});
const settings = await window.soraExt.call('getSettings');
await window.soraExt.call('setSettings', {refresh_seconds: 10});
window.soraExt.onEvent((kind) => { /* session.connected … */ });
```

Calling a method without its permission rejects the promise, request only
what you need in `sora-extension.json` → `permissions`.

## 0:07, Validate

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

`validate` is the pre-publish gate, `publish` runs it too.

## 0:08, Pack, sign, publish

```sh
sora-ext pack . -o /tmp/stats.soraext
sora-ext sign --key .sora/author.key /tmp/stats.soraext
sora-ext publish /tmp/stats.soraext
```

`publish` checks: validation passes, the package is signed, dangerous
permissions are acknowledged (`--ack-dangerous`), then prints the artifact
hash and a catalog-entry snippet ready to submit.

## 0:10, Install

In the app: **Extensions → Install from file** → pick `/tmp/stats.soraext`.
The app verifies the archive and signature, stores grants and handles
install, update, rollback, enable, settings, catalog cache and revocations.
Review the permission prompt and enable. Widening permissions re-prompts.

## Next

- [API reference](extensions-api.md), every method, event and error code
- [Cookbook](extensions-cookbook.md), settings forms, themes, background
  workers, testing patterns
- [Dev mode & app contract](extensions-devmode.md), how the app side works
- `examples/hello-panel`: a minimal working panel to build, sign and
  sideload

Background workers, themes and routing rules also run in the app now. Start
from `sora-ext scaffold --template background`, `examples/theme-midnight` or
`examples/routing-split`. Workers use `window.soraExt.call` and `console.log`;
they run on the core scheduler while the app is open. Theme stylesheets are
ignored. Signed declarative bypass profiles require an explicit selection and a compatible native backend; arbitrary packet callbacks are not exposed. See the normative runtime contracts
in [extensions.md](extensions.md).
