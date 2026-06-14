# Lock Screen Player — Design Spec

## Overview

Add a custom expandable now-playing player overlay to the macOS lock screen (14+), co-existing with the system's existing lock screen elements (clock, user icon, password field). The player renders a dark translucent card in the middle area of the lock screen showing album art, track info, progress bar, and transport controls.

## Problem

The macOS lock screen is a secure environment managed by `loginwindow.app`. Normal app windows are hidden when the screen locks. Third-party apps cannot render UI on the lock screen through standard APIs. Apple does show a Now Playing widget at the bottom of the lock screen, but it is inconsistent and our app's track info does not appear there.

## Approach: CGS Private Window (Layer 1 — NSWindow)

Load private CoreGraphics Server functions from SkyLight.framework via `dlsym` to create a window at the screen saver window level (`kCGScreenSaverWindowLevel`, value 1000). This level renders above the desktop wallpaper but below the lock screen's password field and clock.

**Two-layer strategy, starting with Layer 1:**

- **Layer 1:** Create a borderless, transparent NSWindow at `CGWindowLevelForKey(.screenSaverWindowLevelKey)` with SwiftUI content via NSHostingView. If NSWindows are deactivated by WindowServer on lock (session-scoped), fall back to Layer 2.
- **Layer 2:** Create the window purely via CGS (`CGSNewWindow`), attach a CoreAnimation layer as the rendering surface, and render content manually. More work, no session constraints.

## Architecture

### Components

**1. CGSManager** (`Sources/Resound/Services/CGSManager.swift`)

Manages connection to WindowServer and window lifecycle. Loads CGS function pointers from SkyLight.framework via dlsym (same pattern as MediaRemoteProvider):

- `CGSNewConnection` — open WindowServer connection
- `CGSNewWindow` — create window, returns CGSWindowID
- `CGSReleaseWindow` — destroy window
- `CGSReleaseConnection` — close connection
- `CGSSetWindowLevel` — set z-position
- `CGSOrderWindow` — place in stacking order
- `CGSSetWindowOpacity` — transparent flag
- `CGSSetWindowAlpha` — opacity value
- `CGSSetWindowBounds` — size and position

Owns a single CGSConnection (created on first use, reused). If any symbol fails to load, the manager reports unavailability and the feature is disabled (no crash).

**2. LockScreenCoordinator** (`Sources/Resound/Coordinators/LockScreenCoordinator.swift`)

The orchestrator. Responsibilities:

- Register for screen lock/unlock notifications via `DistributedNotificationCenter` for `com.apple.screenIsLocked` / `com.apple.screenIsUnlocked` (these fire on session lock/unlock, unlike NSWorkspace notifications which fire on display sleep)
- On lock: create the player window and make it visible
- On unlock: destroy the window cleanly
- Subscribe to `MediaRemoteProvider.shared.publisher` for now-playing updates
- Forward `NowPlayingInfo` to the player view controller

**3. LockScreenPlayerView** (`Sources/Resound/Views/LockScreenPlayerView.swift`)

A SwiftUI view matching the existing Dynamic Island aesthetic:

- Size: 340×172 (card content only; window sizing adds ~20px padding per side)
- Layout (top to bottom):
  - Row: album artwork (52×52 rounded) + title/artist/album text
  - Progress bar (3px height, tabular-nums timestamps, 0.3 opacity on unfilled portion)
  - Transport controls: skip back, play/pause, skip forward
- Visual: dark translucent card (`Color.black.opacity(0.92)` with backdrop blur), 14px rounded corners, 1px subtle border (0.06 opacity white), 20px internal padding
- Always expanded (no collapse)
- No interaction by default (ignores mouse events to not interfere with password entry)

**4. LockScreenViewController** (`Sources/Resound/ViewControllers/LockScreenViewController.swift`)

NSViewController wrapping `LockScreenPlayerView` in an NSHostingView. Manages the NSWindow:

- Creates borderless, transparent, non-activating NSWindow
- Sets `ignoresMouseEvents = true`, `isOpaque = false`, `level = .screenSaverWindowLevel`
- Sizes window to fit content
- Positions centered horizontally, centered vertically — content sits in the middle of the screen, appearing above the wallpaper layer but below the clock/user icon/password area
- On deactivation/lock: shows window
- On unlock: hides and destroys

### Data Flow

```
MediaRemoteProvider.shared.publisher
  → LockScreenCoordinator (Combine subscriber)
    → LockScreenViewController (receives NowPlayingInfo updates)
      → LockScreenPlayerView (SwiftUI re-renders on state change)
```

No new data pipeline. The existing `NowPlayingInfo` struct and Combine publisher are reused.

### Lifecycle

| Event | Action |
|---|---|
| App launches | LockScreenCoordinator init: register for `com.apple.screenIsLocked` / `com.apple.screenIsUnlocked` via `DistributedNotificationCenter` |
| Screen locks | Create NSWindow at screenSaverWindowLevel, show player with fade-in |
| Screen unlocks | Fade out and destroy NSWindow |
| Track changes | Update SwiftUI view (data arrives via Combine publisher) |
| Playback stops | Show empty state (♪ icon + "Nothing playing") |
| App terminates | Destroy window, unregister notifications (deinit) |

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| NSWindow may not render when session is deactivated (macOS 14+) | Fall back to Layer 2 (pure CGS window + CoreAnimation) |
| Window may be below password field layer | Test actual macOS 14+ behavior; adjust window level constants |
| Window may flicker on lock/unlock | Use smooth alpha transitions on lock/unlock |
| CGS API changes in macOS update | Loaded via dlsym — failure to load = feature disabled, no crash |
| Window blocks password entry | `ignoresMouseEvents = true` |
| Multi-monitor: window only appears on one screen | Detect which screen the lock screen is on; place window there |

## Success Criteria

1. Player card appears on the lock screen within 1 second of screen locking
2. Player card disappears immediately on unlock
3. Now playing info (title, artist, album, artwork) displays correctly
4. Progress bar advances in real-time
5. Transport controls are visible (interactivity deferred)
6. No interference with password entry or lock screen dismissal
7. Zero CPU usage when screen is unlocked
8. Feature degrades gracefully on macOS versions where CGS doesn't work

## Out of Scope (Deferred)

- Transport control interactivity on lock screen (requires `ignoresMouseEvents = false` and security considerations)
- Multi-monitor support (detect active lock screen display)
- Custom theming options
- Screen saver integration (Approach 2 fallback)
