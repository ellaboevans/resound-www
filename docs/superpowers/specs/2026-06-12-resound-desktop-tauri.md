# Resound Desktop — Tauri + Vue 3 Cross-Platform Port

## Overview

Port Resound (macOS menubar music controller) to Windows and Linux using Tauri
(Rust backend) + Vue 3 (frontend). Keep the existing native macOS SwiftUI app
unchanged. The new cross-platform app lives in its own directory
`resound-desktop/` within the same `dynamic-island` monorepo, alongside
`DynamicIsland/` (macOS) and `resound-www/` (website).

## Directory Layout

```
dynamic-island/
  resound-desktop/
    src/              # Vue 3 frontend
    src-tauri/        # Rust backend (Tauri)
    package.json
    vite.config.ts
    ...
```

## Frontend (Vue 3)

A floating overlay window that mirrors the macOS Dynamic Island UX, adapted for
machines without a notch.

### Components

- **`Pill.vue`** — Rounded floating pill positioned top-center of the primary
  display. No notch gap — just a clean pill shape. Shows album art + animated
  waveform on hover.
- **`ExpandedPanel.vue`** — Expanded view with artwork, track title, artist,
  and progress bar. Slides down on hover interaction.
- **`TransportControls.vue`** — Play/pause, next, previous buttons. Play/pause
  is a filled circle with icon, matching macOS version's style.
- **`VolumeSlider.vue`** — Slider below transport controls, reads/writes
  system volume via Tauri commands.
- **`VolumeOverlay.vue`** — OSD overlay showing volume or brightness level
  with 8-bar level indicator.
- **`SettingsPanel.vue`** — Launch at login, music source filtering, display
  options.
- **`NowPlayingState`** — Shared reactive state composable.

### Design Constraints

- Dark aesthetic matching the macOS version (`#080808` background).
- Always-on-top floating window with transparent background (Tauri webview).
- Same interaction model: hover to expand, auto-hide on leave (configurable).

## Backend (Rust / Tauri)

### System Integration

- **System tray** with app icon, show/hide, quit.
- **Always-on-top floating window** positioned at top-center of primary display.

### Media Sources

- **Spotify** — On Windows via `Windows.Media.Control`
    (`GlobalSystemMediaTransportControlsSessionManager`). On Linux via D-Bus
    MPRIS (`org.mpris.MediaPlayer2.spotify`).
- **YouTube Music (browser)** — On Windows, Chrome registers with
    `Windows.Media.Control` when playing media. On Linux, Chrome exposes
    MPRIS. No JXA/AppleScript needed — the browser handles this natively.
- **Artwork** — Fetched from the media session metadata, cached locally.

### Tauri Commands (IPC)

Exposed to the Vue frontend via `invoke()`:

- `get_now_playing` — Returns track title, artist, artwork path, progress,
  playing state.
- `play_pause`, `next_track`, `prev_track` — Transport control.
- `get_volume`, `set_volume(level: i32)` — System volume.
- `get_settings`, `set_settings(...)` — Persistent settings.

### Events (Frontend Push)

- `now-playing-changed` — Emitted on track change / state update (poll or
  listener driven).
- `volume-changed` — Emitted on OS-level volume change.

### Artwork

Artwork from media sessions is base64-encoded or saved to a temp path and sent
to the frontend as a data URL or file path for the webview to display.

## Media Integration by Platform

| Feature | Windows | Linux |
|---------|---------|-------|
| Spotify detection | `Windows.Media.Control` | MPRIS D-Bus |
| Chrome/YTM detection | `Windows.Media.Control` | MPRIS D-Bus |
| Volume control | System audio API (WASAPI) | ALSA/PulseAudio |
| Launch at login | Registry / Startup folder | XDG autostart |
| System tray | Tauri built-in | Tauri built-in |

## Feature Parity

Deliver the same Resound feature set from day one:

- [x] Floating pill UI (rounded, no notch gap)
- [x] Hover expand/collapse with artwork + track info
- [x] Play/pause, next, previous controls
- [x] Progress bar with elapsed/remaining time
- [x] Volume slider
- [x] Volume OSD overlay
- [x] Settings (music source filtering, auto-hide, launch at login)
- [x] Multi-monitor support (primary screen for now)
- [x] Empty state when nothing is playing
