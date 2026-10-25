# Native Windows transaction probe

This is an isolated feasibility test for S5, not a replacement Sora installer.
The shipped Inno package, update signature checks and release artifact profile
are unchanged. The probe asks Windows Installer to own the transaction instead
of placing a recovery timer in the possibly broken new application.

Two per-user fixture MSI packages share a component and upgrade identity and
contain different planted payloads. A deferred readiness action observes the
installed bytes and writes a separate observation before accepting or refusing
commit. The native Windows CI must establish all three outcomes:

1. Old installation succeeds, with its bytes and product registration present.
2. New bytes are actually observed, readiness refuses completion, and Windows
   Installer restores old bytes and the old registration. Aborting before copy
   cannot pass: the observation must prove that new bytes were read.
3. Retrying the same new package with successful readiness commits new bytes
   and only the new product registration. Cleanup must uninstall its files.

Only a disposable GitHub Windows runner executes the MSI files. The test refuses
ordinary local execution and existing fixture product registrations, uses fresh
GUIDs and private temporary paths, and checks the generated artifacts' hashes.
This guard prevents accidental local use; an environment variable is not a
security sandbox. The fixture executable only reads/writes planted files and
has no service, network, route or firewall code. Detailed MSI logs are retained.

## Verified construction, pending execution

Local wixl 0.106 successfully built both x64 packages. Exported MSI tables prove
`InstallInitialize=1500 < RemoveExistingProducts=1501 < ProcessComponents=1600`
and `InstallFiles=4000 < ProbeReady=4001 < InstallFinalize=6600`. The builder also
requires the readiness action's deferred bit and rejects ignore-failure actions.
The convenience MajorUpgrade default would remove the previous product before
the transaction; this probe authors the sequence explicitly and checks output.

The local compiler was extracted into a private directory from signed Arch
packages, verified against the existing public distribution keyring; no package
was installed on the owner or home-pc. CI builds the same upstream 0.106 from
the pinned 437,664-byte source archive (SHA-256
`1ed34279cf8080f14f1b8f10e649474125492a089912e7ca70e59dfa2e5a659b`).
The native rollback result still awaits Windows CI. Compilation/table checks
alone do not demonstrate restored files or an accepted readiness decision.

## Tool choice

Inspected 26 October 2026 before authoring the probe. Existing `msi.dll` supplies
rollback/product-state APIs on supported Windows; standard Go/Python libraries
build the inert observer, decode tables and verify outcomes. No handwritten MSI
database writer, crypto protocol or production update state machine is added.

| Candidate | Release | Stars / open | Weight | License / compatibility |
| --- | --- | --- | --- | --- |
| WiX 7.0.0 | 2026-04-06 | 1,163 / 7 (GitHub incl. PR) | 12,365,824 B CLI MSI | MS-RL plus OSMF/EULA conditions; .NET build SDK |
| Velopack 1.2.161 | 2026-09-29 | 2,415 / 40 (GitHub incl. PR) | 146,884,263 B vpk tool nupkg | MIT; SDK startup hooks and its updater/layout |
| msitools/wixl 0.106 | 2025-03-20 | 9 / 23 (GitLab stars/issues) | 437,664 B source archive | GPL-2.0-or-later / LGPL-2.1-or-later build tools; Linux GLib/Vala, x64 MSI output |

WiX's current maintenance terms cannot be accepted on an assumed revenue
exemption. Velopack offers a per-machine MSI mode, but integrating its updater
does not itself establish Sora's LocalSystem service/authenticated rollback
contract. MSIX services require Windows 10 2004+, above Sora's 1809 floor.
Selected wixl adds a Linux CI build tool while leaving Sora's runtime and
installer family intact during this test. Its libraries are not bundled into
Sora. The existing Sora repository is GPLv3; no new commercial service is used.

This probe does not demonstrate Sora SCM/IPC/network readiness, configuration
format reversal, signed rollback eligibility, Inno-to-MSI migration, reboot or
power-loss recovery. Those must be designed and tested before changing shipped
installation. Passing this test is evidence for a native transaction component,
not completion of S5 or permission to publish a new packaging family.

Sources: [Windows Installer rollback](https://learn.microsoft.com/en-us/windows/win32/msi/rollback-installation),
[removal sequencing](https://learn.microsoft.com/en-us/windows/win32/msi/removeexistingproducts-action),
[deferred actions](https://learn.microsoft.com/en-us/windows/win32/msi/deferred-execution-custom-actions),
[msitools 0.106](https://download.gnome.org/sources/msitools/0.106/),
[WiX terms](https://docs.firegiant.com/wix/osmf/),
[Velopack Windows layout](https://docs.velopack.io/packaging/operating-systems/windows),
[MSIX service OS floor](https://learn.microsoft.com/en-us/windows/msix/desktop/managing-your-msix-deployment-targetdevices).
