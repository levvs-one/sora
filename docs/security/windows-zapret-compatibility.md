# Windows Zapret compatibility probe

The requested Zapret and driverless ByeDPI extensions must have real host
integration before catalog publication. Today the core wraps Linux tpws and
Windows ByeDPI as local SOCKS proxies. Windows winws is a packet filter, not a
SOCKS proxy; replacing one with the other would change routing behavior.
This probe resolves native-loader compatibility before adding that integration.
It does not make the catalog entries or native hook consumer complete.

## Existing implementations reviewed, 26 October 2026

| Component | Latest release | Stars / open issues | Archive size | License / constraint |
| --- | --- | --- | --- | --- |
| bol-van/zapret | v72.13, 21 July 2026 | 16,305 / 2 | 7,959,200 bytes ZIP | MIT; classic version already vendored for Linux |
| hufrea/byedpi | v0.17.3, 22 September 2025 | 3,439 / 88 | 69,809 bytes Windows x64 ZIP | MIT; existing Windows SOCKS backend, no driver |
| basil00/WinDivert | v2.2.2, 21 September 2022 | 3,326 / 60 | 405,137 bytes variant A ZIP | LGPLv3 or GPLv2; the old release is a maintenance risk |
| bol-van/zapret2 | v1.0.6, 21 October 2026 | 5,788 / 9 issues and PRs | 9,970,350 bytes ZIP | Not substituted: Lua strategies and a different contract |

The existing standard-library subprocess, hashing, ZIP, ctypes and PowerShell
APIs suffice for this test. No driver loader, SCM manager, downloader client or
new dependency is implemented. The workflow's existing curl style fetches a
pinned official release; the fixture checks its exact size, archive SHA-256 and
four extracted component hashes before launch. The archive is a test input,
not a new shipped software artifact.

## What the disposable runner does

`packaging/windows/test_zapret_compatibility.py` refuses execution unless it is
explicitly opted in on a Windows GitHub Actions runner. That guard prevents
accidental local use; it is not a sandbox or proof of runner ownership.
`IsWow64Process2` must report a native AMD64 kernel, so x64 emulation on Windows
ARM64 cannot incorrectly qualify. The signed driver and the required WLANAPI
DLL must be present. A pre-existing WinDivert driver service aborts the fixture.

The exact winws binary is launched with `--wf-raw=false`. The documented literal
`false` filter diverts **no traffic**. Its own initialization marker must arrive
within 15 seconds while it remains alive. The fixture then terminates its child
and stops only the newly created driver service whose ImagePath exactly matches
this private fixture directory. A foreign path is never stopped. Driver-service
absence is required afterward. Logs preserve the primary failure if cleanup
also fails. No restart, firewall/route changes, AV exclusions, Secure Boot change
or test-signing mode is performed. No owner's service or driver is exercised.

Only syntax, pinned-archive static checks and the Linux refusal guard have been
run locally. Actual loader/signature/cleanup behavior is pending disposable
Windows CI. Even a successful run would not prove DPI evasion, packet shaping,
all Windows builds, Secure Boot/HVCI combinations, other-VPN coexistence, or
network-scoped production behavior.

## Packaging boundaries still open

The verified v72.13 x64 binary imports `cygwin1.dll`, `WinDivert.dll` and
`wlanapi.dll`; the bundled Cygwin runtime is 3.4.10. Windows Server installations
may lack WLANAPI. The app must report incompatibility rather than install an OS
feature or reboot automatically. Upstream Windows ARM64 requires an unsigned
driver and test mode; that route is excluded. No weaker backend fallback is
implied by an unsupported platform or refused driver.

The production bundle will need the exact applicable WinDivert/Cygwin notices
and corresponding-source arrangements before distribution. The current Cygwin
licensing page describes LGPLv3+ with a linking exception; it is not a substitute
for verifying the obligations of the embedded older runtime. The test does not
publish those binaries or change the signed extension catalog, root or packages.

Sources: [Zapret Windows contract](https://github.com/bol-van/zapret/blob/v72.13/docs/windows.md),
[WinDivert 2.2 filter and installation API](https://github.com/basil00/WinDivert/blob/v2.2.2/doc/windivert.html),
[WinDivert license](https://github.com/basil00/WinDivert/blob/v2.2.2/LICENSE),
[Cygwin licensing](https://www.cygwin.com/licensing.html),
[IsWow64Process2](https://learn.microsoft.com/en-us/windows/win32/api/wow64apiset/nf-wow64apiset-iswow64process2),
[Get-AuthenticodeSignature](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/get-authenticodesignature).
