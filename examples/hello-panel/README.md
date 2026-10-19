# hello-panel — example Sora extension

A minimal extension: one panel showing live connections via the extension
API (`window.soraExt`). Install it from the Extensions section with
"Install from file".

Files:

- `sora-extension.json` — manifest v1 (see `docs/extensions.md`)
- `panel.html` — the panel; uses only `window.soraExt`, no network
- `checksums.txt` — sha256 of every content file
- `signature.minisig` — minisign signature over `checksums.txt`
- `hello-panel.soraext` — the distributable ZIP

The example is signed with a throwaway example key (seed in the packager
used at authoring time); it is **not** a trust anchor. Real extensions are
signed with the author's offline key, and catalog extensions are additionally
covered by the team catalog signature.
