# Sora extensions, threat model

Companion to [the extension specification](../extensions.md). The app owns
extension storage and consent. The core executes workers delegated by that
app; the CLI shares manifest and package verification code with the core.

## 1. Assets and actors

| Asset | Location | Risk |
|---|---|---|
| Subscription credentials | Core secret store, opaque references in control messages | Account takeover if exposed |
| VPN traffic | Engines and session routing | Traffic exposure or redirection |
| Connection metadata | Core connection API, projected by the app bridge | Browsing and application usage profile |
| App settings | User profile | Configuration integrity |
| Extension code and grants | App store, installed.json and extracted packages | Supply chain compromise or excessive access |
| Author identity | Manifest author key, catalog pin and persisted app pin | Impersonation |

Authors, compromised author keys, malicious panel scripts and network
attackers are untrusted. The user decides consent; the app must show the
actual permissions and sideload identity. The Sora team signs the catalog
and revocation list. A compromised OS, core, app or build machine is outside
this permission model.

## 2. Trust boundaries

```text
untrusted .soraext / signed catalog / signed revocations
  -> app: verify signatures and checksums, pin author, store grants
     -> panels: WebView -> PanelBridge -> allowed app callbacks
     -> workers: control-authenticated ExtensionHost.RunWorker
        -> Scheduler -> disposable goja process
           -> permission-checked JSON bridge -> app PanelBridge
           -> net.fetch -> allowlist and limits -> live VPN proxy
```

The app is the only live extension store. It handles installation, update,
rollback, enable/disable, settings, catalog cache, rollout and revocations.
The core never reads that registry or maintains a second one.

RunWorker is the sole ExtensionHost RPC. The transport restricts it to
control peers, and the first message must pass the control-token check.
The app supplies verified source, the manifest with granted permissions and
resolved background configuration. JS receives neither the control token
nor arbitrary native callbacks. Closing or replacing the stream cancels
active work and unregisters its task. Disabling, uninstalling and worker
reconfiguration cancel streams through app lifecycle reconciliation.

The trusted app is responsible for grants and source integrity. The core
validates the manifest and configuration again; it does not independently
verify installation or ask an on-disk service registry for grants.

## 3. Permission enforcement

`core/ext/enforcement.go` supplies CLI status lookups. Its statuses are
pinned to `app/lib/src/ext/enforcement.dart`; behavior tests cover the
worker gates and the app bridge.

| Permission | Core worker gate | App gate |
|---|---|---|
| connections.read | workerBridgeCall | PanelBridge grant check, projected connection fields |
| servers.read | workerBridgeCall | PanelBridge grant check, projected server fields |
| notifications | workerBridgeCall | PanelBridge grant check, title/body limits of 120/500 characters |
| net.fetch | Fetcher constructed only with grant; HTTPS, allowlist and limits on each request | Unavailable to panels |
| background | Manifest capability and permission, scheduler registration | Enabled extension and background configuration |
| ui.panel | Manifest capability and permission validation | Install consent, declared panel loader |
| theme.apply | Manifest validation | Enabled grants, conflict winner, colors/contrast validation, reset on disable |
| routing.rules | Manifest validation | Enabled grants, shared match parser, ordered direct/proxy/block rules |
| settings.read / settings.write | No app-settings API | Inert; own extension settings are permissionless |
| tray | No consumer | Unimplemented |
| net.hooks | No consumer | Unimplemented, dangerous permission |

Unknown worker methods and unknown PanelBridge methods are rejected.
Worker calls to getConnections, getServers and notify are checked before
forwarding and again by the app bridge. Extension-local getSettings and
setSettings need no app-settings permission; values are schema-validated
by the app store. Granting settings.read/write exposes no app configuration.

Routing rules are dangerous: they can bypass or block matching traffic,
after user rules and before defaults. They cannot select a server. Network
hooks and DPI bypass remain out of scope.

## 4. Credential boundary

There is no extension permission for subscription credentials.
`core/ext` does not import `core/control` or reference the secret store.
The worker host exposes a closed set of JSON calls rather than core structs.

The app's panel and worker adapters project connection data to id, process
name, host and byte counters. Server data is projected to id, display name,
country and latency. Endpoint configuration and credential references are
not forwarded. Settings methods access only that extension's settings.
RunWorker carries worker configuration, bridge calls/replies, logs and
failure notices; it has no credential response type.

Fetcher audit lines strip query, fragment and userinfo. An extension can
log its own data, so log redaction does not make arbitrary extension text
safe. A renderer exploit or a compromised app can cross this boundary;
permissions constrain scripts using the supported bridge.

## 5. Integrity and author identity

The app verifies every content file against checksums.txt and verifies its
minisign signature. The trusted comment binds the signature to the payload
role and hash. The CLI uses Package.Verify/VerifyWithKey and VerifyPayload
for the same archive and signature contract.

Paths reject traversal, absolute or noncanonical names, backslashes,
Windows alternate-stream colons and duplicates. Archive/file/count limits
bound decompression. Declared panel, worker and asset entries must exist.
The app injects CSP into extracted panel copies; signed bytes stay intact.

Catalog installs verify the download hash and the catalog-pinned author
key. Sideload signatures are self-attested: they prove byte integrity,
not the author's identity. App consent shows the author and fingerprint.
The app persists the author pin and refuses a key-changing update. A
newer version is required for updates; explicit rollback re-verifies the
previous version with the pinned key before restoring it.

The app verifies catalog and revocation signatures against its compiled
team key. Core startup does not fetch or enforce these documents. The
private team key stays outside the repository.

## 6. Revocations and offline behavior

The app fetches revocations.json and its minisign signature, verifies and
caches them, loads the cache on startup and rechecks installed versions.
The constraint language is *, =x.y.z, <x.y.z and <=x.y.z.
Matching enabled extensions are disabled; installing, updating, enabling
or rolling back to a revoked version is refused.

With no cached list installs proceed. An expired cached list blocks new
installs and updates; already installed extensions can continue running.
A failed download falls back to the verified cache. A modified cache fails
signature verification. An offline device cannot receive a new kill order.
When a match disables an extension, panels close and worker streams cancel.

This policy lives in app/lib/src/ext/revocations.dart and store.dart.
There is no service-side cache or revocation arm.

## 7. Worker and network limits

Scheduler clamps intervals to 15 minutes through 7 days, prevents overlap,
stops tasks after ten consecutive failures, and pauses/cancels runs with
the kill switch. Work exists only while the app lifecycle stream is open.
Each run gets a new goja process: 2 CPU seconds, 128 MiB live heap,
30 seconds wall time, 1 MiB source, 256 host calls and stack depth 256.
The parent kills and reaps on cancellation or timeout. No Node, filesystem,
process, raw socket, global fetch or timer API is exposed; source maps are
disabled. This bounds resource exhaustion, not native-runtime exploits.

net.fetch permits HTTPS DNS hosts from the manifest allowlist, rejects
userinfo, literal IPs and explicit ports, rechecks redirects, and caps
request/response bytes and rate. Production always uses TunnelTransport,
which resolves the current loopback VPN proxy on each request. Without a
live proxy, including pure TUN without a local listener, it fails closed.
A nil transport is used only in tests/development. Allowlisted hosts can
still turn malicious; an allowlist is not an assessment of their content.

## 8. Verification and residual risks

Go tests cover worker stream authentication/replacement/cancellation,
scheduler and kill-switch behavior, JS budgets, tunnel transport, package
integrity and manifest validation. Fuzz targets cover manifest core fields,
full background/asset declarations, checksums and URL policy. App tests
cover store lifecycle, grants, published signatures, revocations, panel
bridge and declarative assets. CLI schema and TypeScript parity tests keep
authoring contracts aligned.

Remaining risks include WebView renderer vulnerabilities, Go/goja native
vulnerabilities, author or team key compromise, malicious allowlisted
hosts, routing consent mistakes and delayed offline revocations. Updating
a public key requires an app release; pinning does not recover a stolen
private key. Network hooks remain unapplied.
