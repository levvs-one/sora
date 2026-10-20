# Sora

[Русский](README.md)

[![Latest release](https://img.shields.io/github/v/release/levvs-one/sora)](https://github.com/levvs-one/sora/releases)

An open source VPN client for Windows and Linux. Works with your VPN provider's subscription: paste the link, pick a server, connect.

![Sora main window in the light theme](docs/images/home-1440x900-light.png)

<details>
<summary>Dark theme</summary>

![Sora main window in the dark theme](docs/images/home-1440x900-dark.png)

</details>

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

## Documentation

These guides are in Russian.

- [Installation, updates and removal](docs/install.md)
- [Using Sora](docs/usage.md)
- [Subscription formats and provider guide](docs/providers.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Architecture](docs/architecture.md)
- [Development and building](docs/development.md)
- [Changelog](CHANGELOG.md)
- [Plans](PLANS.md)

## License

[GPL-3.0](LICENSE). [Third-party licenses](THIRD-PARTY-NOTICES.md).
