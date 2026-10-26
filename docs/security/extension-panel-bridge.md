# Extension panel bootstrap and native channel

The panel host and the signed panel package use the same public `window.soraExt`
API. The host now registers a separate internal native channel, `SoraExtHost`, and
the bootstrap captures that object before exposing the public API. This name is
not an authorization boundary: `PanelBridge.handle` still checks every method and
the installed extension grants. CSP and navigation restrictions remain unchanged.

## Reproduction

Executing the previous shipped Dart bootstrap with Node 26.11.1 failed with a
JavaScript syntax error: the invalid-callback branch and unsubscribe function
were missing arrow syntax. Correcting only that syntax exposed a second failure:
assigning the public API to `window.soraExt` overwrote the native channel of the
same name, so the first call failed with `soraExt.postMessage is not a function`
and no native message was sent. Both desktop platform adapters inject their
channel as a `window` property, so this collision is part of the actual adapter
contract, not a hypothetical browser global.

The existing Flutter/WebView dependencies already provide native channels and
JavaScript execution; no bridge framework or runtime dependency is added.
`panel_bootstrap_js_test.dart` sends the exact compiled Dart constant to Node's
built-in `vm`. It checks successful and refused replies, Unicode and quotes,
events and unsubscription, a stable captured native object, and a missing host.
A missing native object rejects with the existing `internal` error code.
The public API and permission list are unchanged.

## Native regression

`integration_test/extension_panel_test.dart` installs the committed Hello Panel
package through the normal package-signature verification path with its committed
catalog author pin. In a temporary extension store it opens the real native panel
twice, requires the initial `not-connected` response to replace Loading, exchanges
settings through the native channel, rejects the ungranted `getServers` method,
and records a synthetic notification. No core, VPN session, driver or service is
started. The test runs in disposable Windows WebView2 and Linux WebKitGTK CI;
Linux uses Xvfb instead of an owner's desktop. Native CI results must be checked
before claiming platform execution. The local pure/widget suite is not native
browser proof.

This fixes host bootstrap execution without changing the signed Hello Panel
archive or catalog. Its current disconnected-state copy and styling remain in
that separately signed package. Source/package improvements need their normal
author and catalog signatures before publication; the host does not bypass that
trust contract. This is not a general browser-security or native-driver audit.
