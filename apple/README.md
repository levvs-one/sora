# Sora for Apple platforms

![Sora logo](Assets/logo-512.png)

Native iOS and macOS clients for sora, sharing one Swift core
(`SoraCore`) and one packet-tunnel provider (`PacketTunnel`) with the
existing Flutter + Go product. This tree is a port, not a rewrite of the
product logic: identifiers, localization keys and honest-state strings
mirror the main app.

## Honest status

**This tree was written on Linux. It has never been compiled.**
No Xcode, no Swift toolchain and no Apple SDK exist on the machine that
produced it, so nothing here is "verified working": Swift sources were
written carefully against documented APIs, every generated artifact that
*could* be checked on Linux *was* checked (JSON/YAML validity, converter
and glossary/icon scripts actually run — see below), and everything that
needs a Mac is listed as a checklist in
[docs/BUILD-MAC.md](docs/BUILD-MAC.md). The first Mac build *will* find
issues; that document is the plan for that day.

Deployment targets (per [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)):
**iOS 15.0+ / macOS 13.0+** — the libbox floor. macOS 11–12 are not
supported by the main targets.

## Tree map

| Path | What |
|---|---|
| `project.yml` | XcodeGen spec: both apps, PacketTunnel (iOS app-extension + macOS system-extension), widget extensions, login-item helper, Debug/Release |
| `SoraCore/` | Local SPM package shared by all targets (models, parsers, config, storage) |
| `PacketTunnel/` | Shared `NEPacketTunnelProvider` + `LibboxBridge` (sing-box libbox) |
| `Apps/iOS/` | iOS app (views, widgets, intents) |
| `Apps/macOS/` | macOS app (`SoraMac/`), system-extension packaging, widgets, intents, login-item helper |
| `Localizations/` | `Localizable.xcstrings` (760 keys × 31 locales), ARB→xcstrings converter, glossary + consistency check |
| `Assets/` | `Media.xcassets` (AppIcon, AccentColor), icon size verifier |
| `docs/ARCHITECTURE.md`, `docs/PARITY.md` | Design and feature-parity records (research department) |
| `docs/BUILD-MAC.md` | Step-by-step build/sign/ship guide for the owner's Mac |

## Quick start (on a Mac)

```sh
brew install xcodegen
cd apple
xcodegen generate --spec project.yml
# build Libbox.xcframework first — docs/BUILD-MAC.md §2 — then:
open Sora.xcodeproj
```

Full steps, signing, notarization and TestFlight: docs/BUILD-MAC.md.
