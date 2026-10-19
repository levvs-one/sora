# F9 sync contract

Normative wire contract between the Go sync daemon (`service/sync`) and the
app UI. Both sides MUST implement exactly this; when they disagree, this
document wins. The Go side is the reference implementation — its tests
(`pairing/pairing_test.go`, vectors T1) pin the wire bytes.

## 1. Pairing QR payload

URI form:

```
sora-sync://pair?v=1&id=<device-id>&pub=<base64url-32B>&token=<base64url-16B>&port=<1..65535>
```

`id`, `pub`, `token`, `port`, `v` are the only defined keys.

| Key   | Meaning | Format |
|---|---|---|
| `v` | Format version | `"1"`; anything else is rejected |
| `id` | Inviting device id (mDNS correlation) | 1–128 chars, non-blank |
| `pub` | Inviter's **ephemeral** X25519 public key | base64url **without padding**, exactly 32 bytes |
| `token` | Rendezvous token, proven after the Noise handshake | base64url **without padding**, exactly 16 bytes |
| `port` | Inviter's pairing listener TCP port | decimal `1`–`65535`; the IP comes from mDNS, never from the QR |

Rules:

- Scheme MUST be `sora-sync`, host MUST be `pair` (both matched exactly;
  the scheme is lowercased by URI parsing, so `SORA-SYNC://` is accepted
  and equivalent).
- Query keys MUST be sorted (`url.Values.Encode` order); encoders MUST
  produce this order so payloads are byte-comparable.
- No duplicate query keys: a duplicated key is rejected. Rationale: Go's
  `url.Values.Get` takes the first value while other parsers may take the
  last, so a duplicated `pub`/`token` could make the two sides run the
  handshake against different keys.
- No fragment: any `#` in the payload is rejected, even a bare trailing
  one (`url.Parse` silently drops an empty fragment, so the raw string is
  checked).
- Unknown extra keys are ignored (forward compatibility); unknown keys
  MUST NOT change the meaning of the defined ones.
- `pub`/`token` MUST be base64url **without** padding; padded or hex forms
  are rejected. The private key NEVER appears in the payload.
- The payload is single-use and expires with the pairing session (5 min).

### Wire vectors (shared with Dart)

Fixed vectors both sides MUST reproduce byte-for-byte. Key material is the
byte sequence `0..31` / `0..15`:

```
vectorPub32 = "AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8"  // bytes 0..31
vectorTok16 = "AAECAwQFBgcICQoLDA0ODw"                      // bytes 0..15
```

- **T1 (accept):**
  `sora-sync://pair?id=device-a&port=12345&pub=AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8&token=AAECAwQFBgcICQoLDA0ODw&v=1`
  decodes to `id="device-a"`, `port=12345`, `pub[i]=i`, `token[i]=i`, and
  re-encodes to the identical string.
- **Reject:** wrong scheme/host, `v=2` or missing `v`, `pub` of 31 bytes or
  not base64, `token` of 15 bytes or padded (`...Dw==`), `port` 0 / 65536 /
  non-numeric, empty or missing `id`, any fragment, any duplicated key.

### Dart migration note

The current app-side `SyncPairing` (`app/lib/src/sync.dart`) uses a
different, incompatible shape (`token` as hex, `key` instead of `pub`, no
`id`/`port`). It MUST be replaced with this contract before F9 ships: parse
with the rules above, render the QR from `POST /v1/pairing/start`
`qr_payload` verbatim (the daemon is the only key generator — the UI MUST
NOT invent key material), and never log the payload.

## 2. mDNS discovery

- Service type: `_sora-sync._tcp` (both advertise and browse).
- TXT records: `id=<device-id>`, `v=1`.
- mDNS is used ONLY to resolve a device id to a LAN IP. It is
  unauthenticated and spoofable; authentication happens in the Noise
  handshake (static-key check) and the token confirmation.
- **Dial gate:** the daemon dials ONLY loopback, RFC 1918, or link-local
  addresses (see `lanAddr` in `api/pairing.go`). A spoofed answer pointing
  outside the LAN is rejected before any TCP connect — so a LAN attacker
  cannot make the daemon disclose its Noise static key to an internet host.

## 3. Local HTTP API auth

- The API listens on `127.0.0.1` only (ephemeral port, written to
  `<data-dir>/http_addr`); it is never exposed to the LAN.
- Every endpoint requires `Authorization: Bearer <token>`. There are no
  public endpoints; a missing or wrong token is `401`.
- **Scope:** one token, full control of the API (pairing, peers, sync,
  documents). Scope is the OS user boundary: whoever can read
  `<data-dir>/api_token` (mode `0600`) already owns the device account.
- **Token format:** 32 random bytes, base64url without padding
  (43 chars), compared in constant time.
- **Lifetime (TTL): none by design.** The token persists until the data
  directory is wiped; rotation = stop the daemon, delete `api_token`,
  start again (a new 32-byte token is generated), then hand the new token
  to the app. No expiry is enforced because the app holds the token for
  the whole install lifetime and there is no refresh flow; expiry would
  only create lockouts, not security (localhost + `0600` is the boundary).
- The token MUST NOT appear in logs, QR payloads, or diagnostics bundles.
