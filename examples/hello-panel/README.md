# hello-panel, example Sora extension

A minimal extension: one panel showing live connections via the extension
API (`window.soraExt`). Install it from the Extensions section with
"Install from file".

Files:

- `sora-extension.json`, manifest v1 (see `docs/extensions.md`)
- `panel.html`, the panel; uses only `window.soraExt`, no network

## Build and sign

This is the official package in the team catalog (extensions/), so the
manifest carries the Sora team key. To build your own copy, put your key
there instead before signing:

```sh
sora-ext keygen -o author        # author.key stays offline, never commit it
# paste the printed public key line into author.public_key
sora-ext validate
sora-ext pack . -o hello-panel.soraext
sora-ext sign --key author.key hello-panel.soraext
```

Then install `hello-panel.soraext` with "Install from file". A sideloaded
package is trusted on first use by the key in its manifest; it is not a
catalog extension.


The 1.0.1 source keeps descriptions behind the info button, uses the native
HTML dialog for focus/Escape handling, and reports explicit refresh failures
through the granted notification API. Automatic disconnected refreshes are
quiet. The bundled Inter font and its original OFL licence are served locally;
the panel makes no external font or data requests.

Version 1.0.1 requires Sora 1.1.3 and is published in
`extensions/catalog-1.1.3.json`. The signed 1.0.0 package stays in the legacy
`catalog.json` for v1.1.2 clients.
