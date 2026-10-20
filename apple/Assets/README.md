# Assets — Apple clients

`Media.xcassets` is the asset catalog both apps use (it is the
Assets.car replacement: Xcode compiles it into `Assets.car` at build
time). It is listed in the sources of `SoraIOS` / `SoraMac` in
`../project.yml`.

## AppIcon.appiconset

- Source artwork: `docs/images/logo-512.png` (black Sora mark on
  transparency, 512×512), composited onto the design light surface
  `#FFFFFF` (`Palette.light.surface`, `app/lib/src/design/theme.dart`).
- 25 entries: iPhone (20/29/40/60 pt), iPad (20/29/40/76/83.5 pt), macOS
  (16/32/128/256/512 pt), plus the 1024×1024 marketing icon.
- Verify any time: `python3 verify_icons.py` — checks every PNG's real
  pixel size against `Contents.json`. Last run: **25/25 OK, 0 mismatches**.
- **Honest limit:** the master is 512 px, so the two 1024 px files
  (`Icon-512x512@2x.png`, `Icon-1024.png`) are Lanczos **upscales** —
  correct dimensions, no extra detail ("мыло" at large sizes is possible).
  For a store-grade icon the owner needs a ≥1024 px (ideally vector/SVG)
  master; regenerate by replacing the source in the generation snippet in
  git history of this file's PR description — or simply drop a larger
  `logo-1024.png` next to the 512 one and re-run the same resize table.

## AccentColor.colorset

From the design palette (`app/lib/src/design/theme.dart`, `Palette.ink`):
light `#1D1D1F`, dark `#F5F5F7` (sRGB components in the colorset). The
connection-glow spectrum in `glow.dart` is decoration, not an accent
colour, and is deliberately not used here.

## logo-512.png

The transparent master copy, for `apple/README.md` and docs. Not part of
the asset catalog.
