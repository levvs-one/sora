# Anti-DPI extension — user guide

Anti-DPI (`org.sora.anti-dpi`) is a first-party extension that drives
Sora's DPI-bypass (zapret) strategies from a panel: a curated preset
library, a full strategy editor, per-host bindings, one-click
auto-tuning and a censorship-event monitor. It does not run any code
of its own against your traffic — it stores **one layer** of strategy
data in the core (`ExtensionHost` contract 1.14), and the core merges
that layer into the next connection plan. This guide is the user
manual for the extension; the wire contract is in
[extensions-api.md](../extensions-api.md), the trust model in
[extensions.md](../extensions.md).

## 1. Installing

Anti-DPI ships as a signed `.soraext` package
(`extensions/anti-dpi/anti-dpi.soraext` in the repository).

**Until the team key ceremony is completed, there is no catalog
install.** The team catalog signature cannot verify yet, and the app
says so honestly instead of pretending. The install path today is
**sideloading**:

1. Extensions → **Install from file** → pick `anti-dpi.soraext`.
2. Read the sideload consent screen. It tells you, in plain words:
   this package did **not** come from the catalog, nobody reviewed
   it, and its signature is **self-attested** — it proves the file
   was not changed after the author signed it, nothing more. Check
   the author (`Sora Team`, `github:levvs-one`) and the key
   fingerprint if you got the file from anywhere but the official
   repository.
3. Review the permissions (§2) and tap **Install**.

> The shipped package is signed with a **development key**. That is
> a deliberate, disclosed placeholder until the owner's key
> ceremony; treat the fingerprint on the consent screen as
> informational, not as a trust anchor, for sideloaded builds.

Updating works like any extension: install the newer package over
the old one. If an update ever asks for **more** permissions than you
granted before, the prompt shows exactly what was added.

## 2. Permissions — and why each one exists

| Permission | Risk | Why Anti-DPI needs it |
|---|---|---|
| `bypass.read` | sensitive | Show the measured capabilities, the effective bypass state and your current layer (Overview, Monitor). |
| `bypass.write` | dangerous | Store your chosen global strategy and per-host bindings as the extension's layer in the core. This changes how your traffic is shaped — that is the whole point of the extension, and why it is classed dangerous. |
| `bypass.tune` | dangerous | Run the core's desync auto-tuner once, on demand (§6). Tuning probes the core's canary endpoints with candidate strategies. |
| `notifications` | normal | Tell you when auto-tuning found (or failed to find) a working strategy. |
| `ui.panel` | normal | Embed the Anti-DPI panel inside the app. |

There is deliberately **no** permission to read your subscriptions,
credentials or server list, and the extension does not ask for one.
Revoking a permission in the extension's details screen takes effect
for new tokens immediately; disabling the extension revokes all of
its tokens at once (§5).

## 3. The screens

- **Overview** — the effective state, straight from the core:
  platform, which backends (tpws/nfqws) are *measured* available and
  why not when they aren't, where the current global strategy came
  from (`user` / `extension` / `core default` / none), how many of
  your bindings the last plan actually carries, and whether a stored
  layer is still **pending** (waiting for the next connection, §4).
- **Presets** — the 15-preset library (`presets.json`): the 11
  profiles of the core tuner registry (derived from the registry, not
  invented) plus 4 classic tpws strategies. Each preset names what it
  targets, what it costs, and which backend it needs. Picking a
  preset fills the editor; nothing is applied until you press
  **Apply**.
  - *Known issue:* the three `midsni` presets
    (`sni_block/split-midsni`, `sni_block/disorder-midsni`,
    `kz_variant/split-midsni`) currently fail to apply — the core
    refuses the unresolved `midsni` marker at layer validation. The
    same strategies work when the auto-tuner picks them (it resolves
    the marker against the canary). This is tracked as a defect, not
    a feature.
- **Editor** — every field of the core's `BypassStrategy` (split
  positions, disorder/oob, TLS record, HTTP shaping, desync methods,
  fake payloads, fooling, TTL/autottl, repeats, filters). Validation
  mirrors the core's, so a strategy the core would reject is flagged
  before Apply, with the same reason.
- **Bindings** — per-destination strategies: a match in plan-rule
  form (`domain:example.org`, a bare domain, an IP or CIDR,
  `geosite:`/`geoip:`/`ruleset:` tags) plus the strategy to run for
  it. Bindings become bypass outbounds in the plan (§4).
- **Auto-tune** — run the tuner, see the attempts, the winner and its
  score; apply the winner as your global strategy in one click when
  the result carries one (§6).
- **Monitor** — live censorship and session events from the core
  (verdict kind + explanation), newest first, capped by the
  `monitor_limit` setting.
- **Profiles / settings** — the extension's own settings:
  `confirm_apply` (ask before Apply, default on), `language`
  (`auto`/`en`/`ru`), `monitor_limit` (20–200). Per-network strategy
  bindings chosen by the tuner live in the core, not here.

## 4. How applying works — the semantics that matter

- **Next connection, never mid-session.** Apply stores the layer in
  the core; the *next* plan built (the next Connect) uses it. A live
  session is never re-shaped under your traffic. The Overview's
  `pending_apply` indicator tells you a stored layer has not been
  picked up by a plan yet.
- **You win, always.** Your in-app bypass rules and your request's
  own zapret strategy outrank the extension:
  - the layer's global strategy fills the zapret-with-VPN slot
    **only when your request carries no strategy of its own**;
  - a binding whose destination you already route (a rule of yours,
    a preset rule, or a Bypass settings entry) is **skipped**, never
    duplicated or overridden.
- **One layer, replaced whole.** Apply sends the entire layer
  (global + all bindings) in one call. Applying an empty layer
  clears the extension's layer.
- **Fail-closed validation.** A strategy the core's rules reject
  (unknown desync method, `ttl` together with `auto_ttl`, tpws-only
  knobs mixed into an nfqws strategy, …) is refused at Apply and the
  previously stored layer stays untouched.

## 5. Disabling is revoking

Disabling Anti-DPI in the extensions list is not a pause button —
it is a revocation:

- its host tokens are revoked immediately (an open panel loses core
  access at once);
- no new token can be minted for it while it is disabled;
- the next connection plan is built **without** its layer — global
  strategy and bindings both — so the core behaves as if the
  extension had never applied anything.

The stored layer itself is kept on disk, so re-enabling the
extension restores your layer as it was. If you want it gone, clear
the layer (Apply with an empty layer) or uninstall the extension.

## 6. Auto-tuning — and its discipline

Auto-tune is the core's Geneva-style desync tuner, exposed through
`bypass.tune`. Its rules are the core's, and the panel cannot bend
them:

- **Explicit only.** Tuning runs when you tap the button — never
  automatically, never in the background.
- **Canaries only.** The tuner probes the core's two fixed canary
  endpoints. The request carries no target, so neither the panel nor
  anything else can aim it at a site of its choosing.
- **Never over a live session.** Tuning needs its own short probe
  sessions, so it refuses to run while you are connected. Disconnect
  first. Swapping strategies under live traffic to test a guess
  would break the connections tuning exists to save.
- **Rate-limited per network**, and the winner is bound to that
  network (and to the matching network profile, if you have one), so
  a strategy picked at home is not blindly reused on a café network.
- **Honest results.** If no candidate works, the panel says so (with
  the attempt count). If the winner has no faithful strategy form,
  you get the winner's id and score without an Apply button — the
  core has bound it to the network profile instead.

## 7. Platform limits — by backend, as measured

The Overview's capability list is **probed on your machine**, not
assumed from the OS name. Current executor reality:

- **Linux** — both backends exist: tpws (split/disorder/record
  strategies, unprivileged SOCKS) and nfqws (fake/autottl/QUIC
  desync over NFQUEUE; needs the nfqws binary, nftables, the
  `nfnetlink_queue` kernel module, privilege — root/CAP_NET_ADMIN or
  the polkit helper — and a free queue number).
- **Windows** — tpws-subset strategies only. winws (the Windows
  nfqws counterpart) is **specification/discovery only**: plans that
  need it fail closed, naming the pending WinDivert step.
- **macOS** — no bypass executor ships today; strategies report
  unavailable with the probed reason.
- **Android** — no bypass path ships today (the client itself is
  still a platform decision); same honest unavailability.

A strategy whose backend is unavailable is refused at Apply/Connect
with the missing capability named — never silently skipped while
the UI pretends to desync.

## 8. Troubleshooting — by CapabilityError reason

Connect/Apply refusals from the bypass executor name the missing
capability (`bypass: this host lacks <capability>: <reason>`):

| Capability named | What it means | Remedy |
|---|---|---|
| `tpws binary` | tpws is not in the engines directory or not executable | Install/repair the zapret helpers, or pick an nfqws strategy (Linux). |
| `nfqws binary` | nfqws is not installed or not executable | Install the zapret helpers. |
| `platform executor` | This platform has no executor for the strategy (e.g. winws pending on Windows) | Use a tpws strategy, or another platform. |
| `nftables (nft)` | `nft` missing, or present but cannot talk to the kernel's nf_tables | Install nftables; check the kernel has nf_tables. |
| `nfnetlink_queue kernel module` | The kernel cannot queue packets to userspace | `modprobe nfnetlink_queue`, or use a tpws strategy. |
| `privilege (root / CAP_NET_ADMIN)` | Installing NFQUEUE rules needs elevation the core does not have | Run the core as the privileged service / via its polkit helper, or use a tpws strategy. |
| `a free NFQUEUE number` | Every queue number in Sora's range is bound by another process | Stop the other zapret instance/process using the queues. |

Other common states:

- **"Pending apply" never clears** — no new connection has been
  built since you applied. Reconnect; the state reflects the last
  *built* plan by design.
- **A binding "does nothing"** — check the Overview's bindings
  count: if your own rule already routes that destination, the
  binding was skipped on purpose (you win, §4).
- **Auto-tune refuses to start** — you are connected (disconnect
  first), or this network was tuned very recently (rate limit; the
  refusal says when it lifts).
- **A preset fails to apply with "unresolved marker"** — the known
  `midsni` issue in §3; use auto-tune or a sibling preset meanwhile.
- **Everything reports unavailable** — on macOS/Android that is the
  honest current state (§7); on Linux it means the zapret helpers
  are not installed where the core looks for them.
