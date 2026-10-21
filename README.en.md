<p align="center">
  <img src="docs/images/logo-512.png" width="96" alt="Sora logo">
</p>
<h1 align="center">Sora</h1>

[Русский](README.md)

[![Release](https://img.shields.io/github/v/release/levvs-one/sora)](https://github.com/levvs-one/sora/releases)
[![Downloads](https://img.shields.io/github/downloads/levvs-one/sora/total)](https://github.com/levvs-one/sora/releases)
[![License](https://img.shields.io/github/license/levvs-one/sora)](LICENSE)

An open source VPN client for Windows and Linux. Works with your VPN provider's subscription: paste the link, pick a server, connect.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/home-1440x900-dark.png">
  <img src="docs/images/home-1440x900-light.png" alt="Sora main window" width="1440">
</picture>

## Install

Windows 10 1809+ or Windows 11, x64. In PowerShell:

```powershell
irm https://github.com/levvs-one/sora/releases/latest/download/install.ps1 | iex
```

Linux x64: Debian, Ubuntu, Fedora, openSUSE, Arch. In a terminal:

```sh
curl -fsSL https://github.com/levvs-one/sora/releases/latest/download/install.sh | sh
```

The scripts download the latest release, verify checksums and install the app with its service. Administrator rights are required. For manual installation, download the installer or packages from the [releases](https://github.com/levvs-one/sora/releases) page.

For older versions of Windows there is a separate client, [sora-legacy](https://github.com/levvs-one/sora-legacy).

## Quick start

1. Paste your subscription link.
2. Pick a server.
3. Click Connect.

## Features

- Subscriptions by link, including Xray JSON subscriptions: scheduled updates, traffic, expiry and provider announcements, and edits on top of a subscription that survive its refresh.
- VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, WireGuard and AmneziaWG, with REALITY and XHTTP transports. Three engines to choose from: sing-box, Xray, mihomo.
- Automatic server choice by latency and measured throughput, backup servers on failure, chains of two or three servers, and servers you add by hand.
- A virtual network adapter (TUN) or the system proxy, a kill switch, and rules by site, IP address and app.
- Network profiles: settings bound to a Wi-Fi network, gateway or provider, applied on request or automatically when you turn that on.
- DNS, IPv6 and tunnel leak checks, a connections screen grouped by app, and diagnostics with export.
- A subscription QR code and reading a QR code from an image. Sync of subscriptions, rules and settings between your computers on the local network without a cloud, over an encrypted channel.
- Extensions: a catalog of signed extensions, installing from a file, permissions confirmed at install. See [docs/extensions.md](docs/extensions.md).
- On Linux, a serverless zapret mode and zapret together with the VPN for direct traffic. It does not hide your IP address or replace a VPN.
- Runs in the tray, starts at login and updates from the app. 31 interface language variants, light and dark themes.

## Security

- Releases ship with `SHA256SUMS`. The install scripts and in-app updates verify checksums against it and install nothing on a mismatch. `SHA256SUMS` itself is not signed yet; its authenticity rests on the HTTPS connection to GitHub.
- The extension catalog and the revocation list are signed with the Sora team key compiled into the app. Extension packages are signed with their authors' keys.
- No telemetry: Sora sends no analytics or usage statistics to the developers. The app itself only contacts GitHub: for update information (can be turned off in settings) and, when you open the extension store, for the catalog and the revocation list. GitHub sees your IP address, as with any website visit.

Details in [docs/security.md](docs/security.md).

## Documentation

All guides except the extension developer docs are in Russian.

- Users: [installation](docs/install.md), [usage](docs/usage.md), [FAQ](docs/faq.md), [troubleshooting](docs/troubleshooting.md).
- Providers: [subscription formats](docs/providers.md).
- Developers: [architecture](docs/architecture.md), [building from source](docs/development.md), [extensions](docs/extensions.md).
- Security: [privacy model and data](docs/security.md).
- [Changelog](CHANGELOG.md) and [plans](PLANS.md).

The full documentation index is in [docs/](docs/).

## License

[GPL-3.0](LICENSE). [Third-party licenses](THIRD-PARTY-NOTICES.md).
