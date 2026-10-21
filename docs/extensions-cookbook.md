# Extension cookbook

Copy-paste recipes. Each assumes a scaffolded panel project
(`sora-ext scaffold … --template panel`). Test every recipe with
`sora-ext serve` before installing in the app.

## 1. Refresh on a setting

Read the user's refresh interval from settings, clamp it, re-arm the
timer when settings change:

```js
let timer = null;
async function arm() {
  const s = await window.soraExt.call('getSettings');
  const secs = Math.min(60, Math.max(1, s.refresh_seconds | 0 || 5));
  clearInterval(timer);
  timer = setInterval(load, secs * 1000);
}
```

The scaffolded `panel.html` already does this, read it as the reference.

## 2. Notify when the VPN drops

```js
window.soraExt.onEvent(async (kind) => {
  if (kind === 'session.disconnected') {
    try {
      await window.soraExt.call('notify', {
        title: 'VPN disconnected',
        body: 'The session dropped. Tap to reconnect.',
      });
    } catch (e) {
      if (e.code === 'permission-denied') {
        console.warn('add "notifications" to permissions');
      }
    }
  }
});
```

Needs the `notifications` permission. Test it without the app:

```sh
curl -X POST http://127.0.0.1:8378/__soraext__/event -d '{"kind":"session.disconnected"}'
```

## 3. A settings form without writing one

Declare it; the app renders it:

```json
"settings_schema": {
  "type": "object",
  "properties": {
    "endpoint": {"type": "string", "minLength": 8, "default": "https://api.example.com"},
    "retries": {"type": "integer", "minimum": 0, "maximum": 10, "default": 3},
    "verbose": {"type": "boolean", "default": false}
  }
}
```

Read with `getSettings`, write with `setSettings`. Invalid values reject -
never trust the form alone; the host validates.

## 4. Guard every call

The mock and the real host reject identically. Centralize:

```js
async function api(method, args) {
  try {
    return await window.soraExt.call(method, args);
  } catch (e) {
    showError(humanize(e));
    throw e;
  }
}
function humanize(e) {
  return {
    'permission-denied': 'This needs a permission the extension was not granted.',
    'invalid-argument': 'Bad request: ' + e.message,
    'not-connected': 'No VPN session is up right now.',
    'internal': 'Something went wrong on the host side.',
  }[e.code] || String(e && e.message || e);
}
```

## 5. Background worker that polls an API

Scaffold with `--template background`, then in `worker.js`:

```js
const res = await worker.fetch('https://api.example.com/status');
if (res.status !== 200) throw new Error('HTTP ' + res.status);
worker.log('poll ok');
```

Manifest needs: capability `background` + permission `background`,
permission `net.fetch`, `background_task: {"interval_minutes": 60,
"entry": "worker.js"}`, `network_hosts: ["api.example.com"]`.

Remember: the declared interval is a wish, the runtime clamps it into
[15 min, 7 days]. `network_hosts` is strict: `api.example.com` matches
only itself; `*.example.com` matches subdomains, not the bare domain.

## 6. Test matrix for a panel

```sh
sora-ext serve --fixtures fixtures.json
```

`fixtures.json` shapes the mock:

```json
{
  "connections": [{"id": "c1", "process": "chrome", "host": "example.com",
                   "up_bytes": 10, "down_bytes": 20}],
  "servers": [{"id": "s1", "name": "DE-01", "country": "DE", "latency_ms": 42}]
}
```

Then:

1. Open the panel, does it render with fixtures?
2. Revoke a permission in a copy of the manifest, does the panel degrade
   gracefully (`permission-denied`)?
3. `POST /__soraext__/event` with each event kind, does state refresh?
4. `GET /__soraext__/calls`, is the call sequence what you expect?
5. `setSettings` with garbage, does validation reject?

## 7. Publish checklist

```sh
sora-ext validate   # gate: must pass
sora-ext publish    # gate + policy: must pass
```

`publish` enforces: signed package, no validation errors, dangerous
permissions acknowledged. It prints the sha256 and a catalog-entry
snippet. Before submitting, re-read the permission list and ask: does the
extension really need each one? Fewer permissions = faster user trust.

## 8. Theme / net-hook / routing extensions

These capabilities parse and validate today; the runtimes are contract v0
(proposed). Start from the examples, they are the contract:

- `examples/theme-midnight`, `theme.json` + `theme.css`
- `examples/net-hook-dpi`, `hook.json` strategies
- `examples/routing-split`, `rules.json`

Copy the shape, keep the `$comment` fields until the runtime lands, and
note the proposed status in your README like the examples do.
