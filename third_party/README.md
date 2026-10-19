# third_party — provenance of vendored code and prebuilt blobs

## zapret (DPI bypass)

- **What:** `zapret/` — tpws/nfqws sources used by sora's serverless DPI-bypass mode.
- **Upstream:** https://github.com/bol-van/zapret
- **Vendored version:** 72.1 (see `THIRD-PARTY-NOTICES.md`; license MIT, © bol-van).
- **License texts:** `zapret-LICENSE.txt` shipped in the `sora-core` package.

## Prebuilt binary artifacts (audit SORA-L8)

The zapret tree ships prebuilt Windows objects that its own `nfq/Makefile`
links when building nfqws for Windows (Cygwin):

```
LIBS_CYGWIN  = -lz -Lwindows/windivert -Iwindows -lwlanapi -lole32 -loleaut32
LIBS_CYGWIN32 = -lwindivert32
LIBS_CYGWIN64 = -lwindivert64
```

These blobs arrive as part of the zapret vendor tree — they are the WinDivert
import libraries and resource objects zapret upstream bundles:

- **Upstream of the blobs:** WinDivert by basil00 — https://github.com/basil00/WinDivert,
  as redistributed inside zapret's `nfq/windows/` tree.
- **License of the blobs:** GNU Lesser General Public License v3 (see the header
  of `nfq/windows/windivert/windivert.h`).
- **Not built by sora:** sora never compiles or links these itself; they are only
  consumed by zapret's own Windows build. They are recorded here so every binary
  artifact in `third_party` has a provenance entry.

SHA-256 (measured 2026-10-19 on the vendored tree):

| File | SHA-256 |
|---|---|
| `zapret/nfq/windows/windivert/libwindivert32.a` | `19194f0a3add1cc2637b86ae1e83706059b8d3ed750b3c6383138f3cbacf56a2` |
| `zapret/nfq/windows/windivert/libwindivert64.a` | `8f992a067455aeea5cc5f828f124034b0c897cd8fec5cff614f0f90884f01ecd` |
| `zapret/nfq/windows/res/32/winicon.o` | `810023d7b54a4640bb04d5c37ef4cab2507dff43158167537ba3fd0330feb618` |
| `zapret/nfq/windows/res/32/winmanifest.o` | `95e63d3940f93eeaf61908ab257c377bfd16a1a4cbf0ecec5aecaff61489afdd` |
| `zapret/nfq/windows/res/64/winicon.o` | `234bf4b6b72e894a83039822bb48c6d1ec90fd27560d3b89dce30488016b43d3` |
| `zapret/nfq/windows/res/64/winmanifest.o` | `0517e35cf1563f92ee0eaaf59fa41bebf959e947b39e353507ce0b736806c003` |

When the zapret vendor tree is refreshed, re-measure the hashes above and keep
this file in sync.
