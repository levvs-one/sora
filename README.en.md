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

The scripts verify checksums and install the app with its service. Administrator rights are required. For manual installation, see the [releases](https://github.com/levvs-one/sora/releases) page.

For older systems, there is a separate client: [sora-legacy](https://github.com/levvs-one/sora-legacy).

## Quick start

1. Paste your subscription link.
2. Pick a server.
3. Click Connect.

## Features

- Censorship-circumvention protocols: REALITY, XHTTP, AmneziaWG, Hysteria2; DPI fragmentation.
- Three engines to choose from: sing-box, Xray, mihomo.
- Subscriptions with auto-update: lowest-latency server selection, traffic usage, expiry dates, provider announcements.
- TUN adapter or system proxy; kill switch; split tunneling by site, IP address and app.
- On Linux, a serverless zapret mode for some blocks. It does not hide your IP address or replace a VPN.
- One-click diagnostics: HAR, PCAPNG, Windows event logs; in-app updates; 31 interface languages.
- Extensions: signed add-ons that extend the client.

## Security

- Releases ship with `SHA256SUMS` — the install scripts verify checksums before installing.
- Release authenticity: minisign signature (`SHA256SUMS`) plus file checksums; without a valid signature, installation and updates refuse to proceed.
- In-app updates verify checksums of downloaded files.
- No telemetry: Sora sends nothing to developers or third parties.

Details — in [docs/security.md](docs/security.md).

## Documentation

All guides are in Russian.

- Users: [installation](docs/install.md), [usage](docs/usage.md), [troubleshooting](docs/troubleshooting.md).
- Providers: [subscription formats](docs/providers.md).
- Developers: [architecture](docs/architecture.md), [building from source](docs/development.md).
- Security: [privacy model and data](docs/security.md).

The full documentation index is in [docs/](docs/).

## License

[GPL-3.0](LICENSE). [Third-party licenses](THIRD-PARTY-NOTICES.md).
