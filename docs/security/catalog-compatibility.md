# Catalog delivery and preflight requirements

The signed HTTPS catalog is fetched when the section opens or refreshes.
Application binaries are not the catalog index. Compatible additions therefore
appear without an application rebuild. New native APIs/backends still require
a host implementing them; this change does not turn old clients into such hosts.

Catalog entries may restrict OS via platforms. The optional field preserves
older entries and unknown future OS identifiers remain visible. Bad types,
duplicates, unsafe identifiers and excessive lists reject malformed metadata.
The catalog requirement is display/install policy, not native compatibility
attestation: architectures, editions, drivers, API availability, signatures and
runtime backend readiness still need their own checks.

The list and detail replace an incompatible install/update action with the
existing info dialog in ink text. Installed versions stay enabled; a newer
incompatible version is excluded from Update all. The action handler checks
again before creating the HTTP client/progress window, so a queued old callback
cannot download it. The already existing signed-package/manifest minimum-version
and descriptor checks remain after download; catalog metadata cannot weaken them.
Dev builds without a comparable release version retain their documented version
gate behavior. OS restrictions still apply.

Tests use the real published catalog bytes and team signature to replace an old
empty test cache and make a listing appear. A tampered fetched document retains
the previous verified catalog. UI compatibility fixtures seed a local cache as
existing UI tests do: modified bytes are never accepted by the network signature
gate and production keys/roots are unchanged.

Seven cases cover typed/immutable metadata, unknown future OS, release/dev
version decisions, actual signed refresh/tampering, visible incompatible entries,
both install and installed-update views, Update all exclusion, and a stale callback
with zero package requests and retained installed bytes/version.
The suite is also run with SORA_VERSION=1.1.2, exercising the actual release gate.
Info dialogs at 320px and text scale 1.6 are rendered with actual app/icon fonts.

Publication is separate. No new production catalog entries, signed packages,
software releases or root-key changes are made here. Before publishing bypass
sources, set the actual first supported host version and accurately restrict
their OS. The subsequent Windows Winws integration is described in
[the bypass boundary](extension-bypass-profiles.md#windows-winws-adapter);
this catalog preflight alone does not implement that native adapter.

Validation: full Flutter 554 passed / 71 prerequisite skips, analyze 0;
seven cases passed with SORA_VERSION=1.1.2; final catalog/UI/revocation slice
24 passed in the ordinary dev configuration. Actual 320px / 1.6 text-scale
info PNGs were inspected. The installed-update dialog uses the Update title;
the test loads the actual Cupertino font as well as the app and symbol fonts.
Native Windows on the resulting commit is still awaiting hosted CI.
