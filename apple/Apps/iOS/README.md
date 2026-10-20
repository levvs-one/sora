# Sora for iOS — app, Packet Tunnel provider, widget

Native SwiftUI client for iOS, at design parity with the Flutter app
(cool-neutral palette, dark theme primary, no raw error text anywhere in
the UI — every failure is a designed, localized state).

> **Identifiers — resolved.** The App Group is
> `group.io.github.levvs-one.sora` and bundle ids sit under
> `io.github.levvs-one.sora` (ARCHITECTURE.md §3.4, single source of
> truth). An early divergence across sub-departments was reconciled at
> acceptance (2026-10-20) and verified by grep over all of `apple/`.
> This code takes its group from `PacketTunnel/TunnelConfigExchange.swift`
> (`SoraIdentifiers`) everywhere — including constructing
> `JSONFileProfileStore(directory:)` explicitly instead of
> `sharedContainer()`.

## Targets and files

Create three targets in Xcode (iOS 15+ deployment for the app and the
tunnel; AppIntents code self-gates to iOS 16):

### 1. App — `io.github.levvs-one.sora`
| File | Notes |
|---|---|
| `SoraApp.swift` | `@main`, object graph, deep links, scene-phase wake |
| `TunnelManager.swift` | NETunnelProviderManager, on-demand rules, status stream |
| `TunnelState.swift` | `TunnelUIState` → `state.*` localization keys |
| `ViewModels.swift` | Servers / Import / Stats / Settings models |
| `Views/ContentView.swift` | Tab shell + `AppRouter` |
| `Views/OnboardingView.swift`, `ServersView.swift`, `ServerEditView.swift`, `ImportView.swift`, `QRScannerView.swift`, `QRShareView.swift`, `StatsView.swift`, `SettingsView.swift` | Screens; ViewModels are separate |
| `LinkEncoder.swift` | Share-link encoder mirroring `LinkParser` (app layer; SoraCore parses only) |
| `DeepLinks.swift` | `sora://` routing + all LinkParser schemes |
| `Notifications.swift` | `sora.connection` category, localized texts |
| `Intents/SoraIntents.swift` | AppIntents Connect/Disconnect/Status (iOS 16+) |
| `Design.swift`, `Design/DesignTokens.swift` | Palette parity + tokens |
| `Info.plist`, `Sora.entitlements` | In this folder (drafts) |

### 2. Packet Tunnel extension — `io.github.levvs-one.sora.PacketTunnel`
All of `apple/PacketTunnel/`: `PacketTunnelProvider.swift`,
`LibboxBridge.swift`, `TunnelConfigExchange.swift`, plus its
`Info.plist` / `PacketTunnel.entitlements`. Also link
`TunnelConfigExchange.swift` into the app and widget targets (shared).

### 3. Widget extension — `io.github.levvs-one.sora.Widgets`
`Widgets/SoraWidget.swift` (+ its plist/entitlements), plus the shared
files `Design.swift`, `Design/DesignTokens.swift`,
`PacketTunnel/TunnelConfigExchange.swift`.

## Dependencies

- **SoraCore** (SPM, `apple/SoraCore`): link into app and widget (the
  widget uses only Foundation-level types via the shared snapshot file;
  linking SoraCore there is optional). The app uses `ServerProfile`,
  `LinkParser.parse`, `SubscriptionParser.parse`,
  `LibboxConfigBuilder.build`, `JSONFileProfileStore` /
  `ProfilePersisting`, `AppSettings`.
- **Libbox.xcframework**: link into the **Packet Tunnel extension
  only**. All libbox calls sit behind `LibboxBridge`
  (`PacketTunnel/LibboxBridge.swift`); its signatures carry
  `TODO(verify-on-mac)` markers to reconcile with the pinned
  framework's generated headers — the TUN file-descriptor handoff
  (platform interface) is the first item to verify.
- **Asset catalog**: define Any/Dark appearance colours
  `SoraBackground` (#0B0B0C / #F5F5F7), `SoraSurface` (#1C1C1E / #FFFFFF),
  `SoraField` (#2C2C2E / #EBEBEF) — Flutter `Palette` values; views also
  resolve the same values per color scheme via DesignTokens helpers.

## Behaviour notes

- **States, not errors.** `NEVPNStatus.invalid` is rendered as
  `state.vpnProfileNotApproved` (+ the `state.vpnProfileApprovalPathIos`
  hint), `.reasserting` as `state.reconnectingAfterNetworkChange`, a
  missing configuration as `state.vpnProfileMissing`. Raw `Error`
  strings go to the log only.
- **On-demand / kill switch.** With the kill switch on, TunnelManager
  installs Connect on-demand rules (Wi-Fi, cellular, any) so the tunnel
  returns after network changes and reboots; off clears the rules.
- **Sleep/wake.** The provider re-asserts its network settings in
  `wake()`; the app sends a `.wake` provider message when it becomes
  active.
- **Stats honesty.** Stats come from provider messages; when the
  bridge cannot supply counters the Stats screen shows
  `trafficUnavailable` instead of zeroes, and the footer names the
  source. The widget shows snapshot age via `state.widgetStaleData`.
- **Deep links.** `sora://import?url=…`, bare share links in every
  LinkParser scheme, `sora://connect`, `sora://disconnect` → ImportView
  pre-filled / TunnelManager actions (same approval path as a tap).
- **SiriKit fallback (iOS 15): designed, not implemented.** AppIntents
  needs iOS 16. For iOS 15 the design is `INIntent` handlers with the
  same three verbs delegating to TunnelManager; until implemented,
  iOS 15 devices simply have no Shortcuts surface (the app itself is
  unaffected).

## New localization keys proposed (for the localization pass)

Existing keys are reused wherever possible (`state.*`, `qrNoCamera`,
`trafficUnavailable`, `customServer*`, `killSwitch`, `dns`, `theme*`…).
New keys introduced by this code, all in the shared namespaces:
`state.vpnProfileMissing`, `state.tunnelUnavailable`,
`alert.noProfileSelected`, `alert.configBuildFailed`,
`alert.profileStoreFailed`, `alert.providerMessageFailed`,
`alert.importFailed`, `state.emptyStateActionHint`,
plus screen keys prefixed `onboarding*`, `servers*`, `serverEdit*`,
`import*`, `stats*`, `settings*`, `notif.*`, `intent*`, `widget*`,
`navServers`, `navStats`, `refresh`, `connect`, `disconnect`,
`alertTitle`, `subscriptionGroupTitle`, `qrShareUnavailable*`.
Values must be written in plain language, glossary terms only:
сервер / подписка / подключение.

## Verification status

Linux has no Xcode: SwiftUI/NetworkExtension code is written carefully
but NOT compiled here. Foundation-only files
(`PacketTunnel/TunnelConfigExchange.swift`,
`PacketTunnel/LibboxBridge.swift`, `Apps/iOS/TunnelState.swift`,
`Apps/iOS/DeepLinks.swift`) pass `swiftc -parse` with the Linux Swift
6.0.3 toolchain. Everything else needs a Mac: first build, libbox
header reconciliation, VPN approval flow, widget/intent runs.
