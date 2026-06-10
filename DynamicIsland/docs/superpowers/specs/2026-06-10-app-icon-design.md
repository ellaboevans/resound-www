# App Icon Design — Resound

## Final Design

| Element        | Detail                                                                                          |
| -------------- | ----------------------------------------------------------------------------------------------- |
| **Shape**      | Standard macOS rounded rectangle (36px corner radius, ~1024×1024 base)                          |
| **Background** | Dark gradient — `#000` (bottom) to `#333` (top)                                                 |
| **Foreground** | White notch pill outline (flat top edge, rounded bottom corners, ~24px corner radius) centered  |
| **Content**    | Classic waveform bars inside the pill — varying heights and opacities to suggest audio activity |
| **Palette**    | Black, dark gray, white — monochrome, matches the app's own interface                           |

## Implementation

- Vector source as SVG
- Export to PNG at all required macOS icon sizes
- Generate `.icns` via `iconutil`
- Bundle in `Resound.app/Contents/Resources/Resound.icns`
- Reference via `CFBundleIconFile` in Info.plist
