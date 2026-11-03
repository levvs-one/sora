# Zapret

Blocking bypass without a VPN. Zapret reshapes the first packets of each
connection so the provider cannot recognise the site. The panel shows whether
the bypass runs and switches between three profiles:

| Profile | What it does |
|---|---|
| Strong (`TCP+TLS`) | Splits and reorders the start of a connection. Works most often. |
| Gentle (`TLS`) | Only splits TLS. Use it if Strong breaks a site. |
| Plain HTTP (`HTTP`) | Changes the case of HTTP headers for sites without HTTPS. |

Turning it on switches Sora to the No server mode; choose a server or TUN to
use the VPN again.

- **Linux** uses the TPWS backend bundled with Sora.
- **Windows** uses the WinDivert backend. It shapes TCP ports 80 and 443 for
  every application, so Sora asks for consent on each launch, and the backend
  must be installed separately.

The extension ships profiles and a panel only: no executables, drivers or
scripts. Requires Sora 1.1.6.
