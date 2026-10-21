# routing-split, example Sora extension

Contributes routing rules after user rules and before engine defaults. Enabled routing extensions merge by priority descending, installation time ascending, then ID ascending. The first matching rule wins. Proxy means the user-selected session proxy, never an extension-selected server.

## Build and sign

The manifest uses the same throwaway public key as hello-panel. Its secret
was discarded. Replace it with your own public key before signing.
Keep the new secret and output package outside the source directory:

```sh
sora-ext keygen -o /tmp/sora-example-author
# Paste the printed public key into author.public_key in sora-extension.json.
sora-ext validate
sora-ext pack . -o /tmp/routing-split.soraext
sora-ext sign --key /tmp/sora-example-author.key /tmp/routing-split.soraext
sora-ext validate /tmp/routing-split.soraext
```

Install the signed package with Extensions > Install from file. The key is
trusted on first use for sideloading, with continuity checks on updates.
Never commit secret keys or signed build output. See docs/extensions.md
for tokens, validation and lifecycle details.
