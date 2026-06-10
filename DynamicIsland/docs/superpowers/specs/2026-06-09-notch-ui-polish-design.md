# Notch-Style UI Polish

## Overview

Polish the dynamic island widget to visually mimic the M3 MacBook's physical notch cutout — a flat-top, rounded-bottom pill shape with pure black background, flush with the top edge of the screen.

## Design Decisions

| Decision             | Choice                                                         |
| -------------------- | -------------------------------------------------------------- |
| Approach             | Dynamic Island aesthetic — pure black with notch shape         |
| Background           | `#000000` — pure black, no material/blur                       |
| Shape                | Flat top edge, rounded bottom corners (UnevenRoundedRectangle) |
| Width                | 340px for both collapsed and expanded states                   |
| Position             | Flush with screen top edge (no 8px gap)                        |
| Borders/Glow         | None — pure black                                              |
| Collapsed right side | Animated waveform (3 bars, pulsing when playing)               |
| Pill/panel seam      | Seamless — one continuous shape with shared background         |
| Hover effect         | Retain existing scale/brightness animation                     |

## Files to Change

### WindowManager.swift

- **Window position:** Change `screen.maxY - height - 8` → `screen.maxY - height` to remove the top gap
- The window's top edge now sits flush with the screen's visible frame top

### PillView.swift

- **Background:** Replace `.ultraThinMaterial` with `.black` (pure `#000`)
- **Shape:** Replace `Capsule()` with `UnevenRoundedRectangle` — flat top (radius: 0), rounded bottom
- **Right-side content:** Add animated waveform when `isPlaying` is true — 3 vertical bars using `PhaseAnimator`. Each bar animates height with a different phase offset (creating a wave effect). When paused, the waveform fades to opacity 0. Heights range ~8-16pt, bar width ~3pt, gaps ~3pt.
- **No border** — remove the `.stroke(.white.opacity(...))` overlay
- **Keep** the hover scale/brightness effect for interactivity feedback

### ExpandedPanel.swift

- **Background:** Replace `.ultraThinMaterial` with `.black`
- **Shape:** Replace `RoundedRectangle` with `UnevenRoundedRectangle` — flat top, rounded bottom
- **No border** — remove the `.stroke(.white.opacity(...))` overlay
- **Keep** the appear/disappear fade animation

### ContentView.swift

- **VStack container shape:** Apply a single notch-shaped background to the outer VStack to ensure the pill and expanded panel render as one seamless black shape
- The `UnevenRoundedRectangle` shape with flat top and rounded bottom goes on the VStack

## Unchanged Files

- **NowPlayingService.swift** — polling logic stays the same
- **NowPlayingViewModel.swift** — view model stays the same
- **MusicSection.swift** — content/padding stays the same (background changes handled by ExpandedPanel)
- **AppDelegate.swift, DynamicIslandApp.swift** — no changes needed

## Implementation Order

1. **WindowManager.swift** — fix window position to be flush with top
2. **PillView.swift** — notch shape, pure black, waveform animation
3. **ExpandedPanel.swift** — notch shape, pure black
4. **ContentView.swift** — unify background for seamless pill+panel
5. Build and verify

## Verification

- [ ] Build succeeds with no warnings
- [ ] Pill appears flush at the top of the screen (no gap)
- [ ] Background is pure black, not material
- [ ] Shape has flat top and rounded bottom
- [ ] Waveform animates when music is playing
- [ ] Waveform stops/pauses when music is paused
- [ ] Expanded panel has seamless black background
- [ ] Expand/collapse animation still works smoothly
