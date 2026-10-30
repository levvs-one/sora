# ByeDPI

Blocking bypass without a VPN through the local ByeDPI proxy bundled with
Sora. It reshapes the start of each connection so the provider cannot
recognise the site, and needs no driver. The panel shows whether the bypass
runs and switches between three profiles:

| Profile | What it does |
|---|---|
| Strong (`TCP+TLS`) | Splits and reorders the start of a connection. Works most often. |
| Gentle (`TLS`) | Splits TLS further in. Use it if Strong breaks a site. |
| Plain HTTP (`HTTP`) | Changes the case of HTTP headers for sites without HTTPS. |

Turning it on switches Sora to the No server mode; choose a server or TUN to
use the VPN again. Works on Windows x64 and on Linux amd64 and arm64.

The extension ships profiles and a panel only: no executables, drivers or
scripts. Requires Sora 1.1.6.
