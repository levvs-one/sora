# Sora extensions, threat model

Companion to `docs/extensions.md` (the normative spec) and
`reports/EXTENSIONS-VISION.md` (the product vision). This document is the
honest security accounting for the extension system: what we protect, how,
and what we deliberately do **not** claim. Where a protection is missing,
it says so.

## 1. Assets

| # | Asset | Where it lives | Why it matters |
|---|-------|----------------|----------------|
| A1 | Subscription credentials (proxy UUIDs, passwords, private keys) | `srv.secrets` secret store in `core/control`; referenced by `CredentialsRef`, never inlined | Full account takeover / traffic decryption if leaked |
| A2 | Live VPN traffic (what the user sends through the tunnel) | Engine + `routing.rules` / `net.hooks` consumers (when implemented) | Confidentiality of everything the user does |
| A3 | Connection metadata (which apps contact which hosts) | `core/control` session journal | Browsing/app-usage profile |
| A4 | App settings | App (Dart) side | Integrity of the user's configuration |
| A5 | Extension code integrity (what the author shipped) | `.soraext` on disk, `installed.json` registry | Supply-chain: a modified extension is the author's malware |
| A6 | Author identity binding (this key ⇒ this author) | Manifest `author.public_key`, catalog pinning | Impersonation of trusted authors |

## 2. Actors

- **Benign author**, ships useful extensions, signs with their own key.
- **Malicious author**, ships a trojaned extension, possibly sideloaded,
  possibly via a compromised catalog entry; wants A1–A4.
- **Compromised author key**, the author's signing key leaks; the attacker
  ships "updates" the user trusts.
- **Compromised panel**, XSS or a bug in the extension's own HTML/JS, or a
  renderer exploit; the panel process holds a valid token.
- **Network attacker**, observes or tampers with extension downloads,
  catalog fetches, `net.fetch` traffic.
- **The user**, trusted to make consent decisions, but must be told the
  truth in plain language, not security jargon.
- **Sora team**, holds the catalog/revocation signing key (ceremony
  pending; see §6).

Out of scope: a compromised OS, a compromised build machine of the Sora
team itself, physical device access.

## 3. Trust boundaries

```
┌─────────────┐   minisign    ┌──────────────────┐
│ .soraext    │──────────────▶│ core/ext package │
│ (untrusted  │  checksums +  │ (verification,   │
│  bytes)     │  signature    │  never trusts)    │
└─────────────┘               └────────┬─────────┘
                                       │ per-extension token + permission
                                       │ check on EVERY call
                              ┌────────▼─────────┐
                              │ ExtensionHost    │◀── control token
                              │ (gRPC, core)     │    (app-only Mint/Revoke)
                              └────────┬─────────┘
                                       │ Deps adapters (projection!)
                              ┌────────▼─────────┐
                              │ core/control     │
                              │ sessions, secrets│  ← extensions NEVER cross
                              │ (A1 lives here)  │    this line
                              └──────────────────┘
```

The dependency arrow is one-way: `core/control` imports `core/ext`; `ext`
never imports `control` and never references the secret store. The two
`Deps` adapters (`ListConnections`, `ListServers` in
`core/control/exthost.go`) **project** rich internal structs down to
credential-free shapes before anything crosses the boundary.

## 4. Permission enforcement matrix (WS1 audit result)

"Real check in code on every call path, not a declaration." Audited
2026-10-20 against `core/ext`, `core/control/exthost.go`, `proto/.../ext_host.proto`
and the Dart mirror `app/lib/src/ext`. The machine-readable, test-pinned
version of this matrix lives in `core/ext/enforcement.go`
(`EnforcementTable`, with a Dart mirror in `app/lib/src/ext/enforcement.dart`);
this section is its prose rendering, when they disagree, the code wins.

| Permission | Go core enforcement | Dart app enforcement | Verdict |
|---|---|---|---|
| `connections.read` | `Host.check()` → `rpcPermissions["GetConnections"]`, every call | `bridge.dart` `_methodPermission` | ✅ enforced both layers |
| `servers.read` | `Host.check()` → `GetServers` | `bridge.dart` | ✅ enforced both layers |
| `notifications` | `Host.check()` → `Notify` (+120/500 char caps) | `bridge.dart` | ✅ enforced both layers |
| `net.fetch` | `Fetcher` built only when granted (`Scheduler.RegisterConfig`); allowlist + https/IP/port/redirect/rate/size checks per request; transport is `ext.TunnelTransport`, every request rides the tunnel's loopback proxy and **fails closed** (`ext.netfetch.no-tunnel`) when no tunnel proxy is live, instead of dialing direct | no panel-side fetch (CSP `connect-src 'none'`) | ✅ enforced at construction, per request, and at the tunnel |
| `background` | `Scheduler.RegisterConfig` requires capability **and** permission; interval clamped [15m, 7d]; overlap guard + circuit breaker; scheduler is created/started in sora-core with the kill switch wired through the control plane | background config UI (`<id>.background.json`) | ✅ enforced; **no worker executor is wired yet, so no extension code runs** |
| `settings.read` |, none, |, none, | ⚠️ **no enforcement point; inert** (see below) |
| `settings.write` |, none, |, none, | ⚠️ **no enforcement point; inert** |
| `tray` |, none, |, none, | ⚠️ declared only (runtime v2) |
| `ui.panel` | **gated at validation**: declared panels require the `ui-panel` capability **and** the `ui.panel` permission (`core/ext/manifest.go` + Dart mirror), the install prompt always consents to UI embedding | panel loader serves only declared panels; bridge methods individually gated | ✅ install-time, now a real gate (pass 1) |
| `theme.apply` |, none, |, none, | ⚠️ declared only |
| `routing.rules` |, none, |, none, | ⚠️ **declared only, RiskDangerous** |
| `net.hooks` |, none, |, none, | ⚠️ **declared only, RiskDangerous** |

Honest reading of the ⚠️ rows:

- `settings.read` / `settings.write` refer to **app** settings. No API -
  gRPC or bridge, exposes app settings to extensions at all.
  `getSettings`/`setSettings` are the extension's **own** settings
  (permissionless by design). So these permissions are currently inert:
  granting them changes nothing. If an app-settings API is ever added,
  its adapter must project exactly like §5 and must exclude the secret
  store; the permission prompt text must say what "settings" means.
- `routing.rules` and `net.hooks` are `RiskDangerous` **with zero
  enforcement code**. Today granting them is inert. The day the first
  enforcement point lands, these permissions become "game over for A2"
  by design (a routing-rules contributor chooses where traffic goes; a
  net-hook reshapes it). The install prompt must not present them as
  ordinary toggles then, they need the strongest consent language we
  have, plus catalog review for catalog extensions.
- The closed `rpcPermissions` map (`host.go`) denies unknown RPC names,
  so a future RPC cannot silently inherit token-only access
  (`TestCheckRejectsUnknownRPC`). `TestRpcPermissionsCoverRegistry`
  pins map ⊆ registry.

Token model (defense in depth, all enforced in `core/ext`):

- 32-byte CSPRNG, opaque, server-side grant map; constant-time lookup.
- Scoped to exactly the granted permissions; `MintToken` additionally
  checks `Deps.GrantedPermissions` (wired to the store in
  `core/cmd/sora-core/main.go`): unknown/disabled extensions and
  ungranted permissions are refused even if the app's control plane is
  confused (`TestMintTokenEnforcesGranted`).
- TTL 24 h (`TokenTTL`); expired tokens are rejected and dropped.
- In-memory only: a core restart invalidates everything; the app
  re-mints at startup. Disable/uninstall/rollback revoke immediately
  (`RevokeByExtension`), one tap cuts core access.

## 5. Secrets audit (WS5 result), the proof

Claim: *an extension can never see subscription credentials (A1).*

1. **Storage**: credentials live in `srv.secrets` (`core/control`),
   keyed by opaque refs (`u1_<id>_rec`). `OutboundSpec` carries only a
   `CredentialsRef{reference}`, not the bytes.
2. **No import path**: `core/ext` does not import `core/control`
   (verified by grep; only comments mention it) and contains zero
   references to the secret store. The dependency arrow is strictly
   `control → ext`.
3. **Projection at the boundary**: `ExthostDeps.ListServers` maps
   `OutboundSpec` → `ext.Server{ID, Name}`, endpoint host/port and the
   credentials *reference* are dropped, not just the bytes.
   `ListConnections` → `{ID, Process, Host, Up, Down}`, no PIDs, no
   paths, no tokens. The proto (`ext_host.proto`) has no secret-shaped
   field on any response or event; `WatchExtensionEvents` deliberately
   sends `detail: ""`.
4. **Logs**: `net.fetch` audit lines strip query, fragment and userinfo
   (`safeMethodURL`); worker/fetcher logs never receive credential
   material from the core.
5. **Dart mirror**: `app/lib/src/ext/*.dart` contains no secret/
   credential/password references outside the two token fields
   (`extension_token`, `control_token`), which are the auth mechanism
   itself.
6. **Registry guard**: `TestRpcPermissionsCoverRegistry` fails the build
   if a future RPC/permission pair drifts; the closed map denies
   unknown RPCs.

What this does **not** prove: that a future contributor won't add a
leaky adapter. The guardrails are the projection discipline (§3), the
closed permission map, and this section as the review checklist.

**Explicit credential permission? Rejected.** There is no permission
that exposes A1, and none is planned. If a legitimate need ever appears
(e.g. an extension that rotates the user's own subscription), it must
arrive as a new `RiskDangerous` permission with its own consent screen,
its own audit, and owner approval, not as an extension of an existing
one. Until then, "extensions can never read subscription credentials"
is a load-bearing invariant, stated in `docs/extensions.md` §3.

## 6. Package integrity & signing (WS3)

- `.soraext` = zip + `checksums.txt` (sha256 of every content file) +
  `signature.minisig` (minisign over `checksums.txt`, author's key).
  Verification: parse → trusted comment names `checksums.txt` with its
  sha256 → payload hash matches (constant time) → ed25519 verifies.
  Flipping any byte breaks step 2 or 3.
- **Checksum coverage**: every file except `signature.minisig` and
  `checksums.txt` must be listed exactly once (no extras, no missing);
  those two are authenticated by the trusted comment's sha256.
- **Zip-slip**: `isSafeArchivePath` rejects `..`, absolute paths,
  overlong names, duplicates, and since 2026-10-20 also `\` and `:`
  anywhere, because on the Windows/Dart extractor a backslash is a
  separator (`..\..\evil`) and a colon is an ADS (`panel.html:evil`).
  The Dart mirror must replicate this byte-for-byte. Pass 2 additionally
  requires the canonical name (`name == path.Clean(name)`): aliases like
  `./panel.html` or `a//b` made the panel CSP injector miss the file and
  rollback re-verification fail against the canonical on-disk name.
- **Declared entries**: `Verify` refuses a package whose manifest points
  at a file it does not ship (panel entries, `background_task.entry`,
  `theme` / `network_hook` / `routing` entries). Without the check the
  checksummed file set and the consented surface silently diverged: a
  panel that 404s, a worker that never starts. The Dart
  `ExtPackage.verify` mirrors the check; the CLI has always enforced it
  for projects (`missing-entry`).
- **Downgrade**: `Store.Install` requires a strictly newer semver than
  the installed one; reinstalling an older `.soraext` as an "update" is
  refused. Rollback to N-1 is an explicit user action, re-reading the
  previous manifest from disk.
- **Team key ceremony pending**: `TeamPublicKey` is a placeholder;
  `VerifyCatalogSignature` and `VerifyRevocationList` fail closed until
  the owner completes the ceremony. Consequence, stated plainly: the
  team catalog and the revocation list are both **non-functional**
  today, catalog installs cannot be trusted, and emergency kill cannot
  be delivered. Sideloads (author-key verified) are unaffected.

## 7. Revocation (WS4)

Format: `revocations.json` + `revocations.json.minisig` (team key,
trusted comment `file:revocations.json`), `core/ext/revoke.go`.
Constraint language is deliberately tiny: `*`, `=x.y.z`, `<x.y.z`,
`<=x.y.z`. Enforcement in `Store`: install/update of a revoked
id@version refused; enabling a revoked extension refused.

Offline policy (no theater):

- **No cached list** → installs proceed. The catalog signature is the
  primary gate; a missing list must not brick first-run installs.
- **Expired cached list** → new installs/updates refused (fail closed),
  already-installed extensions keep running.
- **Emergency kill** (`"versions": "*"`) works only when the device can
  fetch the list. An offline device cannot receive a kill order, and we
  do not pretend otherwise. Disabling revokes tokens immediately.

Pass-1 status of the re-check pipeline (honest): the transport and the
storage exist, `core/ext/revocation_cache.go` (`RevocationCache`,
`Refresh`: fetch `.json` + `.minisig`, verify, cache **verified bytes
only**, fall back to cache on any failure), and sora-core applies the
cached list to the store at startup (`cmd/sora-core`), so a kill order
received earlier keeps applying offline and across restarts. What is
still missing: **no production trigger calls `Refresh` yet** (there is no
published team endpoint, and verification fails closed until the key
ceremony anyway), so today the cache can only ever be empty. The day the
ceremony completes, wiring `Refresh` into catalog sync is the last step -
the mechanism needs no rework.

## 8. Sideload consent (WS6)

A sideloaded package is verified against the author's **own** key from
the manifest, self-attested. The signature proves the bytes were not
modified after signing; it says nothing about whether the author is
who they claim to be, and anyone can mint one in a minute.

`core/ext/sideload.go` builds the facts the prompt must show
(`SideloadConsent`, after `pkg.Verify()`): author name/identity, key id
+ SHA-256 fingerprint (`AuthorKeyFingerprint`), every permission with a
blunt consequence ("will be able to redirect your traffic, including
banking and mail, through servers it chooses"), dangerous first, and
the warning block: not from the catalog, self-attested, trust only if
the fingerprint matches the author's published key.

Follow-ups for the app (Dart) side, spec'd not implemented: the consent
screen itself; TOFU author-key pinning with a loud warning on key
change (possible impersonation); "trust this author" as an explicit,
un-pre-checked decision.

## 9. Residual risks (what we do not claim)

1. **Renderer compromise.** Panels run in a WebView. A renderer RCE
   escapes the permission model entirely; permissions bound a
   well-behaved panel, not an exploited one. Mitigations: local files
   only (no remote content), no Node/ffi, WebView kept updated. The
   24 h token TTL bounds a stolen token's lifetime; it does not prevent
   theft.
2. **Dangerous permissions are inherently total.** Once `routing.rules`
   / `net.hooks` are implemented, granting them hands the extension the
   traffic path (A2). No technical control can make that safe, only
   consent, catalog review, and revocation. We say so on the prompt
   instead of implying sandboxing.
3. **Author key compromise.** A leaked author key lets the attacker ship
   trusted "updates" (version monotonicity does not help). Defenses:
   TOFU pinning (planned), revocation (needs the key ceremony), user
   vigilance. There is no silent recovery.
4. **Offline kill gap** (§7). Stated, not solved.
5. **Ceremony pending** (§6). Stated, not solved; the owner action is
   tracked, not hand-waved.
6. **Allowlist DNS.** `net.fetch` matches DNS names; since pass 1 the
   request rides the tunnel proxy, so name resolution happens at the
   engine, not on the local network, but the residual risk that an
   allowlisted host itself turns malicious remains.
7. **Inert-but-dangerous permissions.** Until enforced, `routing.rules`
   / `net.hooks` in the prompt must be labeled "not yet supported",
   not granted silently. A permission the app cannot enforce must not
   be presented as a protection. The machine-readable status is
   `core/ext/enforcement.go`; the CLI already warns authors about it
   (`sora-ext validate`), and the install prompt is the remaining
   consumer (l10n key `extPermNotYetActive`, proposed).

## 10. Fuzzing (WS8)

`core/ext/manifest_fuzz_test.go`: `FuzzParseManifest` (malformed JSON,
deep nesting, truncation, bad UTF-8, unicode lookalikes/RTL/zero-width
in ids) and `FuzzParseChecksums`. Invariants: no panics; accept ⇒
re-validates and satisfies the structural rules independently checked.
Findings and fixes are recorded in the security report
(`reports/extensions-40/partial-security.md`).

Pass 1 added seeds from real cases (the full v2-runtime manifest, the
dangerous-permission set, panel-entry attacks: percent-encoded traversal,
Windows ADS, backslashes) and three more targets:
`FuzzParseManifestFull` (the v2 half the v1 fuzzer never reaches -
background/network-hosts/asset pointers/panels gate),
`FuzzParseRevocationList` (the emergency-brake parser), and
`FuzzFetchURLPolicy` (the `net.fetch` URL policy: https-only, no
userinfo, no IP literals, no ports, allowlist, policy checked
independently, no network issued).
