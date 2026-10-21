# theme-midnight, example Sora extension

Applies a dark palette after validating text contrast. The connection glow keeps its default spectrum because no accent token is set. CSS stylesheets are ignored by Flutter. Disable or uninstall to restore the app theme immediately.

## Build and sign

The manifest uses the same throwaway public key as hello-panel. Its secret
was discarded. Replace it with your own public key before signing.
Keep the new secret and output package outside the source directory:

```sh
sora-ext keygen -o /tmp/sora-example-author
# Paste the printed public key into author.public_key in sora-extension.json.
sora-ext validate
sora-ext pack . -o /tmp/theme-midnight.soraext
sora-ext sign --key /tmp/sora-example-author.key /tmp/theme-midnight.soraext
sora-ext validate /tmp/theme-midnight.soraext
```

Install the signed package with Extensions > Install from file. The key is
trusted on first use for sideloading, with continuity checks on updates.
Never commit secret keys or signed build output. See docs/extensions.md
for tokens, validation and lifecycle details.
