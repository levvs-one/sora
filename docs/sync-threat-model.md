# sora-sync threat model

`sora-sync` is the device-to-device sync daemon (F9). It pairs devices over a
QR code shown on one device and scanned by the other, discovers peers on the
LAN via mDNS, and exchanges VPN documents (subscriptions, rules, settings)
over a Noise_XX-encrypted TCP channel. There is no cloud, no account, and no
telemetry.

> **Implementation status (2026-10-20).** The Go service (`service/sync`)
> is implemented and its honesty properties are verified by tests, not just
> by reading:
> - QR wire format is pinned by fixed vectors (`pairing/pairing_test.go`:
>   `TestVectorT1Decodes` positive T1 plus `TestVectorsReject` negatives —
>   wrong scheme/host, v=2, 31-byte pub, 15-byte token, bad ports, empty id;
>   the literals are copied into `reports/F9-SYNC-CONTRACT.md` for the Dart
>   cross-check).
> - The full contract flow is exercised over the real HTTP API
>   (`api/e2e_test.go`: `TestHTTPAPIEndToEnd` — `POST /v1/pairing/start` →
>   `qr_payload` decodes via `pairing.Decode` → `POST /v1/pairing/join`
>   with the raw string → `GET /v1/peers` → `PUT /v1/documents/...` →
>   `POST /v1/peers/{id}/sync` → the document arrives byte-identical;
>   only mDNS discovery is stubbed, the pairing port comes from the QR).
> - One instance per data dir: `sora-sync` probes `http_addr` + `GET
>   /v1/status` with the dir's bearer token at startup and refuses to
>   start a second daemon (exit 1); a stale `http_addr` from a crashed
>   daemon does not block restart. The app uses the same probe to reuse a
>   running daemon.
> - `transport.Dial` rejects a peer whose presented device id differs from
>   the QR's; `upsertPeer` replaces a peer's identity key on re-pairing so
>   a reinstalled device does not leave a stale key that would fail every
>   later sync.
> - The inviter records the peer only after the first sync succeeds, like
  the joiner: a device the daemon could not sync with is not a peer.
- Sync reports carry `kind`/`name`/`from`/`updated_at` per document so the
  client can show exactly what arrived and where it came from.
- Single instance per data dir is enforced with an OS file lock
  (`flock`/`LockFileEx` on `<dataDir>/lock`) taken *before* the
  `http_addr` probe — the old probe-then-start had a startup race where
  two daemons could both conclude "no live instance".
- The app side is wired (2026-10-20): the sync screen spawns the daemon,
  publishes the contract §4 document kinds (`PUT /v1/documents/...`)
  before every peer sync (skipping unchanged snapshots by hash, so no
  timestamp churn), applies exactly the `pulled` metas after the sync,
  and shows a per-document result (kind, name, `from`, `updated_at`)
  instead of bare counters. The document bridge is covered by
  `app/test/sync_qr_test.dart` (Dart QR vectors, mirror of the Go
  vectors) and the daemon side by `api/bridge_test.go`
  (`TestDocumentKindsEndToEnd` over the real HTTP API).

## Assets

| Asset | Sensitivity |
|---|---|
| VPN documents (subscription URLs, custom rules, settings) | High — subscription URLs are bearer credentials |
| Device identity private key (`identity.json`) | High — authenticates the device to paired peers |
| Pairing rendezvous token (16 bytes, in the QR) | High during pairing — proves the joiner saw the screen |
| API bearer token (`api_token`) | Medium — localhost only |

## Trust boundaries

1. **The screen showing the QR.** Whoever sees the QR can pair. The user is
   expected to show it only to their own device, in person.
2. **The LAN.** Considered hostile: an attacker may sniff, spoof mDNS, and
   run a man-in-the-middle on TCP.
3. **The paired device.** After pairing, the peer is trusted with every
   synced document. Pairing is an explicit trust decision by the user.
4. **The local machine.** `identity.json` and `api_token` rely on filesystem
   permissions (0600). A compromised OS is out of scope.

## Protocol

### Pairing (QR → Noise_XX → token confirmation)

1. The inviter generates an ephemeral X25519 keypair and a 16-byte token,
   and encodes `{device_id, ephemeral_pub, token, port}` into
   `sora-sync://pair?...`. The private key never leaves the device.
2. The joiner finds the inviter's IP via mDNS (`_sora-sync._tcp`, matched by
   device id), takes the port from the QR, and dials.
3. Noise_XX (`Noise_XX_25519_ChaChaPoly_SHA256`) runs with the ephemeral key
   as the static key on both sides — there are no long-term keys yet.
4. After the handshake the joiner checks the peer's static key equals the
   QR's public key. Then **both sides exchange
   HMAC-SHA256(token, handshake_hash)** and compare. Only a peer that saw
   the QR knows the token; the handshake hash binds the confirmation to
   this exact encrypted channel.
5. Both sides exchange long-term device identities and run the first document
   sync.

**Why this defeats a LAN MITM:** the attacker never sees the QR, so they
cannot produce the token confirmation. Downgrading or relaying the handshake
changes the handshake hash, which breaks the confirmation. The static-key
check stops an attacker from substituting their own QR-time key.

### Sync between paired devices

Subsequent syncs use Noise_XX with the **long-term identity keys** as the
static keys. Each side verifies the peer's static key against the paired
device list (`peers.json`); unknown keys are rejected before any document
moves. No token is needed — pairing already established trust.

### Discovery

mDNS is used only to resolve a device id to a LAN IP. It is unauthenticated
by design; all authentication happens in the Noise handshake and the
token/identity-key checks above. A spoofed mDNS answer can at most redirect
the joiner to an attacker, who then fails the cryptographic checks.

## Document handling

- Documents are opaque blobs (`kind`, `name`, `updated_at`, payload). The
  daemon never parses payloads.
- Conflicts resolve last-write-wins by `updated_at` (unix milliseconds).
  Clocks are assumed roughly correct; a device with a wildly wrong clock can
  win conflicts it should not — accepted, and surfaced by showing `from`
  and `updated_at` per document.
- `kind`/`name` are restricted to `[A-Za-z0-9._-]` (max 128 chars); anything
  else is rejected before touching the filesystem. Writes are atomic and
  `0600`.
- Single documents are capped at 16 MiB; the transport reassembles at most
  64 MiB per message.

## Local API

- Listens on `127.0.0.1` only (never `0.0.0.0`).
- Every request needs `Authorization: Bearer <token>`; the token is 32
  random bytes stored `0600` in the data directory, compared in constant
  time.
- Request bodies are capped at 17 MiB.

## Pairing listener

- Binds `0.0.0.0` (the joiner is on the LAN) but lives only for the pairing
  TTL (5 minutes) or until the user stops it. An unauthenticated peer gets
  nothing: the Noise handshake plus token confirmation gate everything.
- The persistent sync listener also binds `0.0.0.0` but only talks to
  already-paired identity keys.

## Out of scope / accepted risks

- **QR shoulder-surfing or screenshots.** Anyone who captures the QR during
  the 5-minute window can pair. Mitigation: short TTL, and the app shows
  which devices are paired (`GET /v1/peers`) so an unknown device is visible;
  `DELETE /v1/peers/{id}` revokes it.
- **Stolen device.** A paired device keeps its identity key and can sync.
  Revoke it from any remaining device; there is no remote wipe.
- **Traffic analysis.** An observer sees that two devices sync and roughly
  how much, but not what.
- **mDNS is plaintext.** Device ids leak to the LAN; they are random and
  carry no user data.
- **No forward secrecy for documents at rest.** Documents sit encrypted only
  by filesystem permissions. Noise provides forward secrecy in transit per
  session (fresh ephemerals every handshake).

## What the app must do

- Show the QR only on explicit user action; never log or screenshot it.
- After pairing, show the new peer and let the user revoke unknown ones.
- When documents arrive (`pulled` in a sync report), show the user what
  came from where: the sync result lists every pulled and pushed document
  with kind, name, `from` and `updated_at`. Applying pulled documents
  follows the user's explicit sync action — the bridge applies exactly the
  `pulled` metas and never invents documents.
- Keep `api_token` out of logs and diagnostics bundles.
