# macOSLegacy — target composition notes (for `project.yml`)

Status: authored on Linux, syntax-checked only (`swiftc -parse`,
Swift 6.0.3 — see the delivery fragment). Nothing in this folder has
been compiled by Xcode yet; the verify-on-mac list is at the bottom.

Scope of this folder: the **legacy composition** for macOS 11–12
(ARCHITECTURE.md §1.6: legacy variant, old libbox, Developer ID
direct channel, no App Store gate). In this composition the main
client's fallbacks are the main paths, and the macOS 13+ surfaces
are honestly absent — not stubbed, not hidden behind runtime
branches that can never fire.

Engine pin for this tier: **sing-box-lx v1.13.13-lx.15** (see
`apple/Legacy/ENGINES.md` — same pin as the iOS 13–14 legacy tier;
measured 12/12 on the shared sora config corpus).

---

## 1. Targets

| Target | Type | Deployment target | Channel |
|---|---|---|---|
| `SoraMacLegacy` | application | macOS **11.0** | Developer ID + notarization only (no MAS variant) |
| `PacketTunnelMacLegacy` | system-extension | macOS **11.0** | embedded in `SoraMacLegacy`, `Contents/Library/SystemExtensions` |
| `SoraLoginItemHelper` | application (existing target, reused) | macOS 11.0 | embedded in `SoraMacLegacy`, `Contents/Library/LoginItems` |

Bundle IDs are **unchanged** from ARCHITECTURE.md §3.4
(`io.github.levvs-one.sora`, `.PacketTunnel`,
`.LoginItemHelper`, App Group `group.io.github.levvs-one.sora`):
the legacy build is the same product for older systems, not a
second product. Consequence to state plainly: on one machine the
legacy build and the main build replace each other (same bundle
id); they are not side-by-side installs. Signing variables are the
same placeholders as the main targets (`SORA_DEVELOPMENT_TEAM`,
`SORA_CODE_SIGN_IDENTITY` = Developer ID Application for release).

### Proposed XcodeGen entries (merge into `apple/project.yml` — this
### sub-department does not edit that file)

```yaml
  SoraMacLegacy:
    type: application
    platform: macOS
    deploymentTarget: "11.0"
    sources:
      # Legacy replacements (this folder):
      - path: Apps/macOSLegacy/SoraMacApp.swift
      - path: Apps/macOSLegacy/NotificationNames.swift
      - path: Apps/macOSLegacy/Core
      - path: Apps/macOSLegacy/Views
      # Originals reused as-is (explicit files — NOT the whole
      # SoraMac folder, so nothing excluded below leaks in):
      - path: Apps/macOS/SoraMac/AppDelegate.swift
      - path: Apps/macOS/SoraMac/Core/AppIdentifiers.swift
      - path: Apps/macOS/SoraMac/Core/AppState.swift
      - path: Apps/macOS/SoraMac/Core/HandoffManager.swift
      - path: Apps/macOS/SoraMac/Core/HotKeyManager.swift
      - path: Apps/macOS/SoraMac/Core/Notifications.swift
      - path: Apps/macOS/SoraMac/Core/SecurityScopedBookmarks.swift
      - path: Apps/macOS/SoraMac/Core/SystemExtensionManager.swift
      - path: Apps/macOS/SoraMac/Core/TunnelManager.swift
      - path: Apps/macOS/SoraMac/Core/TunnelStatus.swift
      - path: Apps/macOS/SoraMac/Core/URLImportHandler.swift
      - path: Apps/macOS/SoraMac/Design/DesignTokens.swift
      - path: Apps/macOS/SoraMac/MenuBar/StatusItemController.swift
      - path: Localizations/Localizable.xcstrings
      - path: Assets/Media.xcassets
    dependencies:
      - package: SoraCore
      - target: PacketTunnelMacLegacy
        embed: true
      - target: SoraLoginItemHelper
        embed: true
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: io.github.levvs-one.sora
        INFOPLIST_KEY_CFBundleDisplayName: Sora
        # Plist/entitlements are the originals, reused as-is:
        #   Apps/macOS/SoraMac/Resources/Info.plist
        #     (LSMinimumSystemVersion is already 11.0)
        #   Apps/macOS/SoraMac/Resources/SoraMac-DeveloperID.entitlements
        #     (Developer ID channel; the sandboxed MAS variant is
        #      NOT used by the legacy target)
  PacketTunnelMacLegacy:
    type: system-extension
    platform: macOS
    deploymentTarget: "11.0"
    sources:
      - path: PacketTunnel/PacketTunnelProvider.swift
      - path: PacketTunnel/TunnelConfigExchange.swift
      - path: PacketTunnel/Legacy   # bridge of the iOS sub-department, §3
      - path: Apps/macOS/SystemExtension
    dependencies:
      - package: SoraCore
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: io.github.levvs-one.sora.PacketTunnel
        INFOPLIST_KEY_NSExtension_NSExtensionPointIdentifier: com.apple.networkextension.packet-tunnel
```

`SWIFT_VERSION: 5.9` (project base) is required: the reused code
uses structured concurrency (`Task`, `@MainActor`, continuations),
which back-deploys to macOS 10.15+ with that toolchain — concurrency
is a language/runtime feature here, not an OS-12 API. The one place
an OS-12 *API* had crept into reused code (async `URLSession`) is
replaced in this folder (§2).

---

## 2. `SoraMacLegacy` sources: replacements in this folder

Each replacement declares the **same type names** as the original it
stands in for, so every reused file compiles unchanged. Each file's
header states what it replaces and why (API floor). No legacy Swift
file references any post-macOS-12 API — not even behind an
availability guard (grep-verified at delivery; the excluded API
names appear in this document only, never in `*.swift`).

| Legacy file | Replaces | Reason (floor) |
|---|---|---|
| `SoraMacApp.swift` | `SoraMac/SoraMacApp.swift` | Original declares the macOS 13 menu-bar scene conditionally. Legacy entry point declares the window scene only; the status item (AppDelegate + reused controller) is the menu bar. |
| `NotificationNames.swift` | *(extracted, no original of its own)* | `Notification.Name.soraOpenImport` lives in the excluded menu-bar content file; reused files (`StatusItemController`, `AppDelegate`) and the entry point need the name. Extracted verbatim (same raw value). |
| `Core/FeatureAvailability.swift` | `SoraMac/Core/FeatureAvailability.swift` | Probes pinned to the legacy answers as constants (the modern backends cannot exist in an 11.0-target process); bundle/plist probes stay real. Modern enum cases renamed and never vended; the shortcuts probe renamed `shortcutsActionsAvailable` (nothing reused referenced the old names — grep-verified). |
| `Core/LaunchAtLogin.swift` | `SoraMac/Core/LaunchAtLogin.swift` | Only the helper path exists on 11–12. Same `Status` enum and surface, plus the `NSWorkspaceOpen` helper reused views call. State is probed in layers (helper embedded → launchd job list → last requested value), never assumed; the registration call's result is recorded, not trusted blindly. Approval-pane opener points at Users & Groups (11–12 location of login items). |
| `Core/SoraCoreBridge.swift` | `SoraMac/Core/SoraCoreBridge.swift` | Two deltas, file otherwise identical: (1) async `URLSession.data(for:)` is macOS 12+ — `fetchSubscription` rebuilt on the completion-handler data task inside a checked continuation; (2) `buildConfig` passes `tier: .legacy` to the config builder instead of its `.main` default (§3). |
| `Core/WidgetSync.swift` | `SoraMac/Core/WidgetSync.swift` | Original reloads widget timelines after publishing. Legacy embeds no widget → no widget framework link, no reload. Snapshot + exchange publishing (tunnel-critical) kept byte-identical. |
| `Views/MainWindowView.swift` | `SoraMac/Views/MainWindowView.swift` | Window rebuilt on the two-column navigation view (the 11–12 split idiom); same `MacSection` (5 sections, by fact of the original: Servers, Subscriptions, Settings, Statistics, About — the mac client has no separate logs screen and import lives inside Servers/Subscriptions). Connect button: bordered style instead of the macOS 12 prominent variant. Header, banner, drag & drop, URL delivery unchanged. |
| `Views/ServersView.swift` | `SoraMac/Views/ServersView.swift` | Single delta: import sheet's confirm button (prominent style, macOS 12) → bordered + default-action shortcut. Otherwise the original file. |
| `Views/SecondaryViews.swift` | `SoraMac/Views/SecondaryViews.swift` | (1) Subscription date: FormatStyle rendering (macOS 12) → shared `DateFormatter`, same presentation. (2) Add button style as above. (3) Settings states the legacy ladder: launch-at-login row carries the explicit legacy-mechanism note; capabilities gain a menu-bar row (available, status-item path) and give Shortcuts/widget rows a reason + working alternative (keys in §5). Statistics/About/StatRow otherwise unchanged. |
| `Views/SystemStateViews.swift` | `SoraMac/Views/SystemStateViews.swift` | (1) Empty-state action style as above. (2) Extension-approval hint uses the legacy key (§5): on 11–12 approval is System Preferences → Security & Privacy → General; the shared string describes the macOS 13+ pane. Button still opens the security pane via the reused manager. |

## 3. `PacketTunnelMacLegacy` composition (system extension)

| Source | Origin | Verdict |
|---|---|---|
| `PacketTunnel/PacketTunnelProvider.swift` | shared provider code | **Reused as-is.** It speaks only to the bridge protocol and the exchange types; nothing in it is newer than macOS 11 (NE provider API floor is far older). Sleep/wake, app messages, fast-switch reload — identical behaviour. |
| `PacketTunnel/TunnelConfigExchange.swift` | shared | **Reused as-is.** Pure Foundation Codable contract + identifiers (§3.4 canon). |
| `PacketTunnel/Legacy/**` | **the iOS legacy sub-department's zone** | **Present in the tree** (`LibboxBridgeLegacy.swift` + `LegacyBridgeNotes.md`, landed in parallel with this composition). Provides exactly the main bridge's API surface — `protocol LibboxBridge`, `enum LibboxBridgeError`, `final class LibboxBridgeImpl`, over `TunnelStatusPayload` from the exchange file — so the provider compiles unchanged. Built against **sing-box-lx v1.13.13-lx.15** (`apple/Legacy/ENGINES.md`); gomobile/Go floor for that pin is macOS 11 by runtime (Go 1.24), no explicit version flags in its build tool. **One composition seam remains, owned by the coordinator:** the bridge's platform interface gets the TUN file descriptor from a registered provider (`LibboxBridgeImpl.registerTUNFDProvider(_:)`); the fd lives in the shared `PacketTunnelProvider` (`NEPacketTunnelFlow`), which neither app sub-department forks — the registration line is wired at target composition and is a verify-on-mac item (§9). Until it is wired, the bridge's `OpenTun` throws and the tunnel honestly fails to start rather than running fd-less. |
| `PacketTunnel/LibboxBridge.swift` | main bridge | **Excluded.** It is the main pin's bridge (sing-box-lx 1.14.3-lx.22, whose libbox floor is macOS 13). The legacy bridge above takes its place; type names are the seam. |
| `Apps/macOS/SystemExtension/Info.plist`, `PacketTunnelMac.entitlements` | main mac target packaging | **Reused as-is.** Principal class stays `PacketTunnelProvider`; bundle id stays §3.4. |
| `SystemExtensionManager.swift` (app side) | `SoraMac/Core/` | **Reused as-is** — see §4. |

**SoraCore tier (landed in parallel, consumed here):** the version
gates measured in `apple/Legacy/ENGINES.md` §4 live in SoraCore as
`EngineTier` — `LibboxConfigBuilder.build(…tier:)` reads the tier's
capability table and does not emit the five 1.14-only items
(`http_clients` / `route.default_http_client`, Hysteria2
`hop_interval_max`, `bbr_profile`, gecko obfs, uTLS `chrome_155`)
for `.legacy`; with those gated, the pin passes the shared corpus
12/12. The builder's tier parameter defaults to `.main`, so the
legacy app states its tier explicitly at its one call site: the
`SoraCoreBridge` replacement in this folder passes `tier: .legacy`
in `buildConfig` (§2). The grpc advisory acceptance for this pin
is the coordinator decision recorded in ENGINES.md §6.3 — flagged
here, not re-decided.

## 4. System extension on 11–12: what is reused, what changes

The approval/activation flow is the Developer ID flow (no App
Store gate on this channel, ARCHITECTURE.md §1.6/§6):

`SystemExtensionManager.activate()` → activation request →
`requestNeedsUserApproval` → user allows the extension in
**System Preferences → Security & Privacy → General** →
properties probe reports `.active`; an update that the system
defers reports `.needsRestart` ("will complete after reboot").

- **Reused without changes:** `SystemExtensionManager.swift`
  entire — request construction, delegate folding into
  `ActivationState`, properties-request status probe, deactivation.
  The request API family predates macOS 11 (10.15), and every state
  it produces already renders through designed `state.*` banners.
- **Changed (and where):** only the *words around* the flow, in the
  legacy replacement of `SystemStateViews.swift` — the approval
  hint names the 11–12 pane (new key, §5) instead of the macOS 13+
  Settings path, and the action button says "System Preferences".
  The manager's `approvalSettingsURL` anchor
  (`…com.apple.preference.security?Privacy`) opens Security &
  Privacy on 11–12 as-is, so no code change is needed there.
- **Not present on 11–12 and not faked:** there is no "Login Items
  & Extensions" management pane; extension removal goes through
  the same deactivation request, and the Settings capability row
  reports the extension from the factual embedded/active probes.

## 5. Localisation keys

`tr(_:_:)` resolves from the shared
`Localizations/Localizable.xcstrings`; fallback English ships in
code, so nothing renders as a raw key before the localisation pass.

**Already in the shared table** (used by legacy + reused files):
`about`, `add`, `addSubscription`, `alert.importFailed`,
`alert.noProfileSelected`, `alert.profileStoreFailed`, `app.name`,
`appCopyright`, `appVersion`, `cancel`, `currentServer`, `delete`,
`error.import_empty`, `importSealed`, `launchAtLogin`,
`launchAtLoginDetail`, `qrFromClipboard`, `search`, `servers`,
`settings`, `subscriptionLink`, `subscriptions`, and the `state.*`
family (via the reused `TunnelStatus`/`SystemStateViews` paths,
incl. `state.extensionNotApproved`, `state.extensionNeedsRestart`,
`state.extensionMissing`, `state.profileNotCreated`,
`state.appGroupUnavailable`, `state.failed`).

**Proposed by the main mac client, inherited unchanged** (not yet
in the shared table; fallbacks ship in the originals and in these
replacements identically): all `mac.*` keys the originals use —
`mac.connect`, `mac.disconnect`, `mac.statistics`, `mac.sidebar`,
`mac.servers.*`, `mac.import.*`, `mac.subscriptions.*`,
`mac.settings.*`, `mac.stats.*`, `mac.menu.*`, `mac.state.*`,
`mac.cap.available`, `mac.cap.unavailable`, `mac.cap.handoff`,
`mac.cap.widget`, `mac.cap.systemExtension`, `mac.launch.enabled`,
`mac.launch.unavailable`, `mac.about.*`, `mac.a11y.*`,
`mac.handoff.title`, plus the empty-state keys passed to
`EmptyStateView` (`mac.servers.emptyTitle/emptyBody/noMatchBody/
clearSearch`, `mac.subscriptions.emptyTitle/emptyBody/focusField`,
`mac.stats.emptyTitle/emptyBody`) and `speedtestEmpty`.
One deliberate exception: the original's capabilities-row key for
the intents surface is **not** reused (renamed below), so no legacy
string ever spells a macOS 13 framework name.

**New, legacy-only (proposed here — EN fallback in code, RU for the
localisation pass):**

| Key | EN (fallback in code) | RU (proposal) |
|---|---|---|
| `mac.legacy.launch.note` | "On macOS 11–12 this uses the classic login item. You can also manage it in System Preferences → Users & Groups → Login Items." | «На macOS 11–12 используется классический объект входа. Им также можно управлять в «Системных настройках» → «Пользователи и группы» → «Объекты входа».» |
| `mac.legacy.cap.menuBar` | "Menu bar icon" | «Значок в строке меню» |
| `mac.legacy.cap.shortcuts` | "Shortcuts actions" | «Действия Shortcuts» |
| `mac.legacy.cap.shortcutsDetail` | "Shortcuts actions need macOS 13 or later. Connect and switch servers from the menu bar icon or the main window instead." | «Действия Shortcuts требуют macOS 13 или новее. Подключайтесь и переключайте серверы через значок в строке меню или главное окно.» |
| `mac.legacy.cap.widgetDetail` | "The status widget is not included in this build for macOS 11–12. Connection status lives in the menu bar icon and the main window." | «Виджет состояния не входит в эту сборку для macOS 11–12. Состояние подключения — в значке в строке меню и в главном окне.» |
| `mac.legacy.extensionApprovalPath` | "On this system: open System Preferences → Security & Privacy → General and allow Sora when it appears there." | «На этой системе: откройте «Системные настройки» → «Защита и безопасность» → «Основные» и разрешите Sora, когда она там появится.» |

Glossary check (§8.3): "сервер / подписка / журнал / подключения"
usage in the RU proposals follows the table; no banned synonyms.

## 6. Excluded from the legacy composition (whole)

| Excluded | Why |
|---|---|
| `Apps/macOS/SoraMac/MenuBar/MenuBarContent.swift` | Defines the macOS 13 menu-bar scene (and the popover view only that scene consumes). The status-item controller mirrors its content model natively; the one shared declaration it carried was extracted (§2). |
| `Apps/macOS/Intents/**` | The intents framework arrives with macOS 13. No substitute surface is shipped; Settings shows the designed unavailable state (§5.2 ladder). |
| `Apps/macOS/Widgets/**` | Widget extension targets are not part of the legacy composition (BUILD-MAC.md §6 matrix for this segment). Settings shows the designed unavailable state with the working alternative named. |
| `Apps/macOS/SoraMac/Resources/SoraMac.entitlements` | The sandboxed/MAS variant. Legacy ships Developer ID only; the Developer ID entitlements file is used instead. |
| The five originals replaced in §2 (+ original `SoraMacApp.swift`) | Superseded by the replacements; including both copies would duplicate type names. |

## 7. Menu bar / launch at login / widgets — the ladder, as built

- **Menu bar:** `StatusItemController` **reused as-is** after a
  per-line floor audit (status item, menu, template image,
  accessibility labels, state observers — nothing newer than
  macOS 11; its only concurrency use is `Task`, which
  back-deploys). It is the *only* menu-bar path here: `AppDelegate`
  (reused as-is) installs it because the legacy
  `FeatureAvailability` probe always answers the status-item
  backend. The 13+ scene is not declared anywhere in this target.
- **Launch at login:** helper path only — existing
  `SoraLoginItemHelper` target embedded at
  `Contents/Library/LoginItems`, registered by the legacy
  `LaunchAtLogin` replacement (§2), legacy mechanism named in
  Settings, state from the layered factual probe.
- **Widgets / Shortcuts:** targets excluded; the honest
  "not available on this system" state lives in Settings
  (capabilities section of the legacy `SecondaryViews`), with the
  reason and the alternative in the row. No empty screens, no
  placeholder surfaces.

## 8. Reused-as-is audit (why each original is floor-clean)

`AppDelegate` (backend choice already goes through the probe —
with the legacy probe it always installs the status item; URL
Apple-events, Handoff continuation, hot key wiring all predate
11) · `AppIdentifiers`, `TunnelStatus`, `URLImportHandler`,
`HandoffManager`, `SecurityScopedBookmarks` (pure Foundation /
pre-11 AppKit) · `AppState`, `Notifications` (Combine /
UserNotifications, pre-11) · `HotKeyManager` (Carbon hot keys) ·
`SystemExtensionManager` (request API from 10.15) ·
`TunnelManager` (NE + path monitor + workspace sleep/wake, all
pre-11; its async NE calls are compiler-generated wrappers over
completion-handler APIs — listed in verify-on-mac regardless) ·
`DesignTokens` (+ the `tr` helper) · `StatusItemController`
(above) · `LoginItemHelper/main.swift` (opens the main app via the
10.15 workspace API) · provider + exchange (§3) · Info.plist /
entitlements (§1).

## 9. Verify on Mac (owner's machine — nothing here was compiled)

1. First Xcode build of both legacy targets with deployment target
   11.0; expected friction points, in order: the job-dictionary
   bridging spelling in legacy `LaunchAtLogin` (marked in-file),
   sidebar list style + navigation-link tag/selection behaviour of
   the legacy main window on 11 and 12, plain list style on 11,
   the async NE wrappers in the reused `TunnelManager`.
2. Real macOS 11 and 12 machines/VMs: fresh install → extension
   approval in System Preferences → Security & Privacy → General
   (banner text + button land in the right pane) → connect →
   fast switch → sleep/wake and Wi-Fi change recovery.
3. Login item: enable in Settings → log out/in → main app opens;
   disable → log out/in → it does not; confirm the launchd probe
   in `refresh()` agrees with reality in both states.
4. Status item: light / dark / tinted menu bars (template image),
   VoiceOver labels, zero-server menu still offers Import.
5. §8.8 detail-standard pass: light+dark screenshots of every
   section, largest Dynamic Type, longest server/subscription
   names (tail/middle truncation), Reduce Motion on.
6. `sora://` deep link + drag-&-drop import on 11 and 12.
7. Developer ID signing inside-out + notarization + staple; first
   launch on a clean account must reach the designed banners, not
   a Gatekeeper block (BUILD-MAC.md §5 recipe).
8. Legacy libbox (pin §3) built and the provider actually tunnels
   on 11 and 12 — the engine sub-department's Mac checks apply to
   this target unchanged. Includes wiring the TUN-fd registration
   (`registerTUNFDProvider`, §3) at composition and confirming the
   tunnel starts with it in place.
