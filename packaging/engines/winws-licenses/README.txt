Sora Windows Zapret bundle

Unmodified classic Zapret v72.13 (MIT), WinDivert 2.2.2 (LGPLv3 option)
and Cygwin 3.4.10-1 (LGPLv3+ with the Cygwin Linking Exception).
The full upstream licence and copyright texts are in this directory.
Cygwin includes newlib code covered by the accompanying Newlib notices.

Complete upstream source archives are installed under ../sources:
- zapret-v72.13.zip includes winws source and its build scripts.
- WinDivert-v2.2.2-source.tar.gz includes the library and driver source/build scripts.
- cygwin-3.4.10-1-src.tar.xz includes newlib-cygwin source and the cygport recipe.

No upstream component is modified by Sora. Sora's own GPLv3 source and build
instructions are available with the matching release tag at:
https://github.com/levvs-one/sora

The stock core admits only its pinned native bundle. To use modified native
components with Sora, rebuild the corresponding Sora core with the new component
digests (core/engine/winws/bundle.go); rebuild WinDivert using its included
instructions and the normal Windows driver-signing requirements.
Do not disable Windows protection or enable test signing.

This optional mode shapes public TCP traffic on ports 80/443 system-wide.
It does not provide a VPN or a per-application packet filter. Sora closes only
its own child/filter handles and never stops/deletes a shared WinDivert service.
The driver may remain loaded until a normal Windows restart.
