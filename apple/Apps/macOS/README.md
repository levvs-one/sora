# Sora for macOS — `apple/Apps/macOS/`

Native SwiftUI macOS client for sora: same SoraCore, same shared
PacketTunnel provider code as iOS (`apple/PacketTunnel/`), same
design tokens and glossary terms as the desktop Flutter app.
Minimum system: **macOS 11** — modern APIs are reached through a
runtime capability ladder (`FeatureAvailability`), not version
checks in views.

## Targets

| Target | Folder | Notes |
|---|---|---|
| `SoraMac` (app) | `SoraMac/` | SwiftUI + AppDelegate bridge; links SoraCore only — **never libbox** |
| `PacketTunnelMac` (system extension) | `SystemExtension/` (packaging) + shared `apple/PacketTunnel/` (code) | Same `NEPacketTunnelProvider`; macOS packages it as a *system extension*, activated via `OSSystemExtensionRequest` |
| `SoraWidgetsMac` | `Widgets/` | Status widget; reads only the App Group snapshot |
| `SoraLoginItemHelper` | `LoginItemHelper/` | macOS 11–12 launch-at-login fallback; background-only, opens the main app and exits |

## Capability ladder (one place: `SoraMac/Core/FeatureAvailability.swift`)

| Feature | Modern backend | Fallback backend |
|---|---|---|
| Menu bar | `MenuBarExtra` scene (13+) | `NSStatusItem` + `NSMenu` controller (11–12) |
| Launch at login | `SMAppService.mainApp` (13+) | Login Item helper + `SMLoginItemSetEnabled` (11–12) |
| Shortcuts | AppIntents Connect/Disconnect/Status/SwitchServer (13+) | **none — designed, honestly reported as unavailable** in Settings; no SiriKit port |
| Widget | WidgetKit (11+, all supported systems) | — |
| Window layout | hand-rolled sidebar split (identical on all versions; no `NavigationSplitView` fork) | same |

Both menu-bar backends render the same content model
(`MenuBar/MenuBarContent.swift` ↔ `StatusItemController.swift`):
status, current server, Connect/Disconnect, quick switch (first 8),
Open, Quit — and with zero servers both offer **Import…** instead of
going dead. The status icon is a **template image**
(`sora-status-template` asset) so it renders correctly in light,
dark and tinted menu bars.

## Tunnel / system extension flow

1. `SystemExtensionManager.activate()` submits an
   `OSSystemExtensionRequest`; outcomes fold into
   `awaitingUserApproval / needsRestart / active / failed`, each
   rendered as a designed banner (`state.*` strings), never raw text.
2. Approval: user confirms in System Settings → General → Login
   Items & Extensions (hint string `state.vpnProfileApprovalPathMac`).
3. `TunnelManager.installProfile` builds the config via SoraCore
   (`LibboxConfigBuilder`), publishes the exchange
   (providerConfiguration + App Group `sora.tunnel.config.v1` +
   `current-config.json`, ARCHITECTURE.md §3.4/§4.3) and saves the
   `NETunnelProviderManager` profile.
4. Connect = `startVPNTunnel`. Server switch while connected = fast
   switch: new exchange + `reloadConfig` provider message, no tunnel
   restart (§4.3).
5. Resilience (§4.2): on-demand rules when auto-reconnect is on,
   `.reasserting` shown as "reconnecting", wake-from-sleep restarts a
   tunnel that was up, `NWPathMonitor` triggers status re-reads only.

## Identifiers (ARCHITECTURE.md §3.4 canon — the only values)

App `io.github.levvs-one.sora` · PacketTunnel
`io.github.levvs-one.sora.PacketTunnel` · Widgets
`io.github.levvs-one.sora.Widgets` · LoginItemHelper
`io.github.levvs-one.sora.LoginItemHelper` · App Group
`group.io.github.levvs-one.sora` · Keychain
`$(AppIdentifierPrefix)io.github.levvs-one.sora` · scheme `sora://`.

⚠️ Divergences found while building (fixes sent to their owners):
`apple/project.yml` and `SoraCore/SoraSharedIdentifiers` still carry
other identifier variants; this app follows §3.4 and passes explicit
store directories so it never resolves the wrong App Group.

## Files the build doc owns

`docs/BUILD-MAC.md` is written by another sub-department; the file
list to agree on: this tree, `apple/project.yml` (XcodeGen),
`apple/SoraCore/Package.swift`, `apple/PacketTunnel/`,
`apple/Localizations/Localizable.xcstrings`,
`apple/Assets/Media.xcassets` (incl. the `sora-status-template`
template image the menu bar expects).

## Notarization (Developer ID channel — summary; details in BUILD-MAC.md)

1. Build with Hardened Runtime + `SoraMac-DeveloperID.entitlements`.
2. Sign app, system extension, helper and widget with the Developer
   ID Application certificate (nested code inside-out).
3. `xcrun notarytool submit` → wait for `Accepted` → `xcrun stapler staple`.
4. MAS channel instead uses `SoraMac.entitlements` (App Sandbox) and
   App Store Connect — no notarization step.
System-extension approval and VPN-profile creation still require the
user on first run in BOTH channels; there is no silent install path.

## Localisation

Strings come from the shared `apple/Localizations/Localizable.xcstrings`.
New macOS-only keys proposed by this app use the `mac.*` prefix
(fallback English text ships in code via `tr(_:_:)`, so nothing
renders as a raw key before the localisation pass merges them).
Proposed keys: `mac.connect`, `mac.disconnect`, `mac.statistics`,
`mac.servers.*`, `mac.import.*`, `mac.subscriptions.*`,
`mac.settings.*`, `mac.stats.*`, `mac.menu.*`, `mac.state.*`,
`mac.cap.*`, `mac.launch.*`, `mac.intent.*`, `mac.widget.description`,
`mac.handoff.title`, `mac.routing.received`, `mac.a11y.*`, `mac.about.*`,
`mac.sidebar`. State/notification/error keys (`state.*`, `notify.*`,
`alert.*`, `error.import_empty`, `importSealed`, …) already exist in
the shared table and are reused as-is.

## Details standard (owner mandate) — where each point lives

1. **DesignTokens** — `SoraMac/Design/DesignTokens.swift`: 4/8 grid,
   radii, semantic colours for both appearances (Flutter Palette
   hexes), Motion tiers **160/180/220 ms** from the Flutter `Motion`
   tokens (theme.dart) — no magic numbers in screens.
2. **Accessibility** — labels on every interactive element (window,
   menu-bar popover, status-item menu items, widget); sidebar →
   header → banner → content is the VoiceOver order.
3. **Empty states** — `EmptyStateView` + designed banners; menu bar
   stays alive with no servers.
4. **Truncation** — names `.tail`, addresses/URLs `.middle`, fixed
   column widths from tokens, fixed row heights.
5. **Dark/light parity** — semantic token colours only; template
   status icon.
6. **Animations** — only `DesignTokens.Motion` animations, collapsed
   under Reduce Motion.
7. **Terms** — main app's glossary (`servers`, `subscriptions`,
   `settings`, `about`, … shared keys), one word per concept.

## Not verifiable without a Mac (honest list)

Everything below is code-complete but was only syntax-checked on
Linux (`swiftc -parse`, Swift 6.0.3): SwiftUI/AppKit/NetworkExtension
compilation, system-extension activation and approval UX, VPN
profile creation, actual tunnelling, SMAppService registration,
widget timeline rendering, Handoff between real devices, hot-key
registration conflicts, notarization. First Xcode build is expected
to surface type-level fixes (notably around `String(localized:)`
availability and scene composition) — see the delivery report.
