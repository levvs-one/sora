# Building Sora for Apple platforms — on the owner's Mac

Everything in `apple/` was written on Linux and has never been compiled.
This is the step-by-step for the first real build, in order. Times are
not promised; step 2 (libbox) is the long pole.

Canonical references: identifiers and targets —
[ARCHITECTURE.md](ARCHITECTURE.md) §1, §3.4; feature scope —
[PARITY.md](PARITY.md).

## 0. Prerequisites

- macOS 13+ build machine, Xcode (current stable), an Apple Developer
  Program account.
- `brew install xcodegen go git-lfs` (Go is needed for libbox).
- The pinned engine: sing-box-lx **1.14.3-lx.22** (same pin as
  `packaging/engines/engines.lock` in the repo root).

## 1. Generate the Xcode project

```sh
cd apple
xcodegen generate --spec project.yml
open Sora.xcodeproj
```

Targets: `SoraIOS`, `SoraMac`, `PacketTunnelIOS` (app extension),
`PacketTunnelMac` (system extension), `SoraWidgetsIOS`,
`SoraWidgetsMac`, `SoraLoginItemHelper` (legacy path), plus the local
SPM package `SoraCore` (folder `SoraCore/`, referenced from project.yml
as a local package — no network fetch).

Signing variables are placeholders in project.yml, never committed:
set in Xcode or an untracked xcconfig —

- `SORA_DEVELOPMENT_TEAM` — your Team ID;
- `SORA_CODE_SIGN_IDENTITY` — e.g. `Apple Development` (dev) /
  `Developer ID Application` (macOS release).

⚠️ Known conflict to fix first: bundle IDs in project.yml follow
ARCHITECTURE.md §3.4 (`io.github.levvs-one.sora…`), but
`Apps/macOS/SoraMac/Core/AppIdentifiers.swift` still carries `dev.sora.*`
values. Per §3.4 the document wins — align that file before creating
App IDs, or the App Group will not match the entitlements.

## 2. Libbox.xcframework (the engine)

Sora's tunnel runs sing-box through its mobile library, **libbox**.
The upstream-official way (SagerNet/sing-box; the fork sing-box-lx keeps
the same tooling):

1. Clone the pinned source:
   `git clone https://github.com/Leadaxe/sing-box-lx && cd sing-box-lx && git checkout v1.14.3-lx.22`
   (upstream equivalent: `github.com/SagerNet/sing-box`.)
2. Install gomobile (the tool libbox is built with):
   `go install golang.org/x/mobile/cmd/gomobile@latest` and
   `gomobile init`.
3. Build the Apple framework with sing-box's own build tool — from the
   repo root of sing-box:
   `go run ./cmd/internal/build_libbox -target apple`
   This produces `Libbox.xcframework` for iOS, iOS simulator and macOS
   (upstream documents the Apple floor as iOS 15.0 / macOS 13.0, which is
   exactly our deployment target). Do **not** substitute a prebuilt
   framework from a third-party release: the pin and the lx patches
   (XHTTP client, AmneziaWG) only exist in this source.
   Background reading: sing-box documentation, "Libbox" / build-from-
   source pages at sing-box.sagernet.org, and the `build_libbox` tool
   under `cmd/internal/` in the source tree — if a flag differs in the
   pinned tag, the tool's `-help` in the pinned source is authoritative
   over this paragraph.
4. Verify the artifact before wiring it in:
   `ls Libbox.xcframework` (expect `ios-arm64`, `ios-arm64-simulator`,
   `macos-arm64_x86_64` slices) and record its checksum next to the
   engines.lock entry for the Apple build.

## 3. Wire the framework into the provider targets

- Drag `Libbox.xcframework` into the project; link + embed it in
  **both** PacketTunnel targets (`PacketTunnelIOS`, `PacketTunnelMac`)
  — the provider process is where libbox runs. The apps do not link it.
- `PacketTunnel/LibboxBridge.swift` is the only Swift file that touches
  libbox symbols. Reconcile it against the generated headers
  (`Libbox.xcframework/<slice>/Libbox.framework/Headers/Libbox.h` and the
  gomobile-generated `Libbox.objc.h` / module map) using the checklist
  in §7 before expecting the provider to compile.

## 4. Signing, capabilities, entitlements

For each App ID (ARCHITECTURE.md §3.4:
`io.github.levvs-one.sora`, `.PacketTunnel`, `.Widgets`):

- Capabilities: **Network Extensions** (packet tunnel), **App Groups**.
- App Group: `group.io.github.levvs-one.sora` — must be identical in the
  app, both providers and both widget extensions, and in the code
  (see the §1 warning about AppIdentifiers.swift).
- Keychain access group: `$(AppIdentifierPrefix)io.github.levvs-one.sora`.
- macOS system extension: the `PacketTunnelMac` target additionally
  needs the Network Extension entitlement for system extensions and
  must be embedded in the app's `Contents/Library/SystemExtensions`;
  approval by the user happens in System Settings → Privacy & Security /
  Login Items & Extensions (the app surfaces this as the
  `state.extensionNotApproved` banner, never as a raw error).
- iOS: the VPN profile approval prompt is system-driven; dismissal is
  surfaced as `state.vpnProfileNotApproved` with the
  `state.vpnProfileApprovalPathIos` hint.

## 5. Ship channels

### macOS — Developer ID + notarization

1. Archive with the `SoraMac` scheme (Release).
2. Sign all nested code inside-out: login-item helper, widget,
   system extension, frameworks (incl. Libbox.xcframework), then the app,
   with `Developer ID Application` + hardened runtime + a secure timestamp.
3. `xcrun notarytool submit Sora.dmg --keychain-profile <profile> --wait`,
   then `xcrun stapler staple`. Verify on a clean user account:
   first launch must not produce a Gatekeeper block, and the system
   extension approval flow must reach the `state.extensionNotApproved`
   banner (not a crash) when approval is pending.

### iOS — TestFlight

1. Archive with the `SoraIOS` scheme (Release), upload via Organizer or
   `xcrun altool`/`Transporter`.
2. App Store Connect: the PacketTunnel extension requires the Network
   Extension entitlement justification in the review notes (VPN app;
   user-imported configurations only; no built-in proxy service).
3. Test on a physical device — the simulator cannot run a real
   packet tunnel.

## 6. Adaptivity acceptance checklist (real devices)

Capability matrix — what the user actually gets per system:

| Capability | iOS 15 | iOS 16 | iOS 17+ | macOS 13+ | macOS 11–12 |
|---|---|---|---|---|---|
| Full TUN tunnel (libbox) | ✅ | ✅ | ✅ | ✅ | ❌ not supported — libbox floor is macOS 13; the main targets do not install |
| Widgets (view state, connect state) | ✅ WidgetKit | ✅ | ✅ interactive (AppIntents-based actions) | ✅ | ❌ (no build) |
| AppIntents / Shortcuts actions | ❌ (framework is iOS 16+) → honest `state.intentNeedsAppApproval`-style absence: no shortcut surface, app shows setup state | ✅ | ✅ | ✅ | ❌ |
| Menu bar (macOS) / launch at login | — | — | — | ✅ MenuBarExtra + SMAppService | legacy fallbacks exist in code (NSStatusItem, login-item helper) but only for a hypothetical legacy target — do not promise them |
| State banners (`state.*`) | ✅ | ✅ | ✅ | ✅ | ❌ |

On-device checks (tick each on hardware, not simulator):

- [ ] Fresh install → banner `state.profileNotCreated` /
      `state.vpnProfileMissing`, and approving the VPN profile clears it.
- [ ] Deny the VPN profile → `state.vpnProfileNotApproved` + iOS hint
      path string; no raw system text anywhere (screenshot every banner).
- [ ] macOS: leave system-extension approval pending → 
      `state.extensionNotApproved`; approve → connect works without
      reinstall; update the extension → `state.extensionNeedsRestart`
      path exercised once.
- [ ] Join a new Wi-Fi / switch Wi-Fi→LTE → `state.reconnecting` /
      `state.reconnectingAfterNetworkChange` banner, tunnel recovers to
      the *same* server; offline network → `state.networkChangedOffline`.
- [ ] Captive portal Wi-Fi → `state.captivePortalDetected`.
- [ ] Low Power Mode on → reconnect delay surfaces
      `state.reconnectDelayedLowPower`, not a fake failure.
- [ ] Widget on home/lock screen (iOS 15 and 17), macOS Notification
      Center: shows last known state; kill the tunnel, wait, confirm the
      stale state is labelled via `state.widgetStaleData` wording, and a
      tap opens the app.
- [ ] Shortcuts (iOS 16+/macOS 13+): Connect/Disconnect intents run;
      on iOS 15 confirm the intents are simply absent (no broken entry).
- [ ] Kill switch on → disconnect the tunnel manually → no traffic
      outside the tunnel (check with a leak test); with the extension
      unapproved, the UI shows `state.killSwitchNeedsExtension` instead
      of pretending protection.
- [ ] Every empty state (no servers, no subscriptions, no connections,
      no logs) renders the designed short text per GLOSSARY.md style —
      one sentence + the action — in RU and EN at both system languages.

## 7. LibboxBridge signature checklist

`PacketTunnel/LibboxBridge.swift` carries `TODO(verify-on-mac)` markers
(grep them). For each, open the pinned framework's headers and tick:

- [ ] L10/L51: every libbox call in the file exists in `Libbox.h` with
      the exact name used (gomobile renames Go functions; trust the
      header, not the Go source spelling).
- [ ] L68: the service-constructor call — exact generated signature
      (argument order, `NSError**` out-parameter, return type).
- [ ] L81: config-setup constructor name + the config argument label.
- [ ] L99: traffic/status query via the command client — method name,
      whether it is synchronous or callback-based, and the units of the
      returned counters (bytes vs bits) against the header docs.
- [ ] Setup call (platform interface registration) precedes service
      start in `PacketTunnelProvider.startTunnel` — gomobile libbox
      requires the platform interface before any box is created.
- [ ] After any fix, remove the corresponding `TODO(verify-on-mac)`
      marker in the same commit.

## 8. Known TODO seams (grep snapshot, 2026-10-20)

`grep -rn "TODO(verify-on-mac)" apple/ --include='*.swift'` at delivery
time finds exactly the five markers in `PacketTunnel/LibboxBridge.swift`
listed in §7 (lines 10, 51, 68, 81, 99). No other `TODO-verify` markers existed in the
app/core code written on Linux; new ones found during the first Mac
build belong in this section, with the same rule: a marker is removed
only by the change that verifies it.
