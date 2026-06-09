# Mac Dynamic Island — Design Spec

## Overview

A floating pill/capsule HUD overlay for macOS that sits at the top-center of the screen. Built with SwiftUI + NSWindow. Expands on click into a panel showing music player, system status, and weather.

## Architecture

- **Approach:** SwiftUI app with a borderless, floating NSWindow pinned top-center
- **Window config:** `.level = .floating`, `.ignoresMouseEvents = false`, `.isOpaque = false`, `.backgroundColor = .clear`
- **Position:** Centered horizontally at the top edge of the screen, inset ~8px from top
- **Stays visible across all spaces** (optional, can be configured)

## Tech Stack

- SwiftUI for all UI
- AppKit via NSViewRepresentable / NSWindow for window management
- MediaPlayer framework for now-playing detection
- SystemKit / IOKit for CPU/RAM/network stats
- CoreLocation + WeatherKit for weather

## States

### Collapsed (default)
- Slim pill, ~200-280px wide, ~34px tall
- Shows: album art icon + track title | weather temp | system uplink/downlink
- If nothing playing: shows just weather + system
- Rounded pill shape (borderRadius: 100px)

### Expanded (on click)
- Card morphs from pill, ~340px wide
- Music hero: album art (52x52) + track title + artist + progress bar
- Playback controls: previous / play-pause / next
- System section: CPU up/down, network up/down, battery
- Weather section: condition icon, temp, feels-like, high/low, location
- Sections below a subtle divider

## Animation Spec

All animation values are drawn from Emil Kowalski's animation principles.

### Expand (pill → card)
- **Spring:** `duration: 0.4, bounce: 0.08`
- **transform-origin:** Calculated from screen position (pill center)
- **Initial state:** `scale(0.95) + opacity(0)` — never scale(0)
- **clip-path morph:** `inset(0 35% 0 35%) → inset(0 0 0 0)` (approximate pill-to-card)
- **Content stagger:** Sections fade in at 30ms intervals with `translateY(6px)`
- **Backdrop blur:** Ramps from 24px → 40px to bridge the transition
- **Easing:** `cubic-bezier(0.23, 1, 0.32, 1)`

### Collapse (card → pill)
- **Duration:** 200ms ease-out (asymmetric — collapse is faster)
- Content fades out first (100ms), then card shrinks to pill
- Backdrop blur drops from 40px → 24px
- Shorter spring: `duration: 0.2, bounce: 0`

### Button press feedback
- Play button: `scale(0.95)` on `:active`, `transition: transform 120ms ease-out`
- All pressable elements have subtle scale-down feedback

### Hover
- Gated behind `@media (hover: hover) and (pointer: fine)` to avoid touch false positives
- Pill has subtle brightness increase on hover

### Reduced motion
- Respect `prefers-reduced-motion`: keep opacity/color transitions, remove all movement/scale/clip-path

## Edge Cases

- **Nothing playing:** Pill shows weather + system only. No music section in expanded panel. Music area collapses or shows "No music playing" placeholder.
- **Long titles:** In pill, truncated with ellipsis (max-width 140px). In expanded, no truncation. Optionally marquee scroll for very long titles.
- **No system data:** Hide system section. Weather stands alone.
- **No weather data:** Hide weather section. System stands alone.
- **All data unavailable:** Show minimal pill with app icon or "No data" state.
- **Multiple screens:** Window appears on active screen (follows key window). Configurable to stay on one screen.

## Implementation Order (Music Player First)

1. Project scaffold — Xcode project setup, window management
2. Collapsed pill view — static UI with SwiftUI
3. Expand/collapse animation — NSWindow animation + SwiftUI transitions
4. Now Playing integration — MediaPlayer framework
5. Playback controls — play/pause, next, previous via MPRemoteCommandCenter
6. System stats — CPU/memory/network/battery via ProcessInfo + IOKit
7. Weather — CoreLocation + WeatherKit
8. Polish — edge cases, reduced motion, hover states, spring tuning

## File Structure

```
DynamicIsland/
├── DynamicIslandApp.swift
├── AppDelegate.swift
├── WindowManager.swift
├── Views/
│   ├── PillView.swift
│   ├── ExpandedPanel.swift
│   ├── MusicSection.swift
│   ├── SystemSection.swift
│   └── WeatherSection.swift
├── ViewModels/
│   ├── NowPlayingViewModel.swift
│   ├── SystemStatsViewModel.swift
│   └── WeatherViewModel.swift
├── Services/
│   ├── NowPlayingService.swift
│   ├── SystemStatsService.swift
│   └── WeatherService.swift
└── Resources/
    └── Assets.xcassets
```
