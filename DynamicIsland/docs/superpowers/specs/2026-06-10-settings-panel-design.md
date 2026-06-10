# Settings Panel Design

## Overview
A hybrid settings system for the Dynamic Island app — quick controls in a menu bar dropdown, full preferences in a standalone window.

## Menu Bar Dropdown
A menu bar icon that shows a custom NSMenu/NSView dropdown with:

- **Now Playing**: track title, artist, album (read-only)
- **Transport controls**: Play/Pause, Previous, Next
- **Waveform style picker**: inline segmented control or small previews
- **Music source selector**: Spotify / Apple Music popup button
- **Separator**
- **Settings...** — opens the full preferences window
- **Quit**

## Preferences Window
A standard macOS preferences window (`NSTabView` or SwiftUI `TabView`) with three tabs.

### General
- **Launch at login**: `Toggle` — uses `SMLoginItemSetEnabled` or ServiceManagement
- **Music source**: `Picker` — Spotify, Apple Music, or Both
- **Auto-hide when idle**: `Toggle` — hide the notch entirely when no music is playing

### Appearance
- **Width**: `Slider` — range 200–400pt, current value displayed
- **Position**: `SegmentedPicker` — Left, Center, Right
- **Waveform style**: Grid of selectable cards, each showing a small preview animation
  - **Classic** — current animated bars (3 capsules)
  - **Pulse** — single expanding circle
  - **Equalizer** — frequency-style bars (5+ bars)
  - **Minimal** — subtle dot or small line

### Hotkeys
- **Play/Pause**: hotkey recorder row
- **Next Track**: hotkey recorder row
- **Previous Track**: hotkey recorder row
- **Toggle Island**: hotkey recorder row
- Each row: label + current shortcut + [Record] button + [Clear] button
- **Restore Defaults** button at bottom

## Architecture

### New Files
- `MenuBarManager.swift` — manages NSStatusItem, dropdown view, menu actions
- `SettingsViewModel.swift` — ObservableObject, @AppStorage-backed settings
- `SettingsView.swift` — TabView container for preferences window
- `SettingsGeneralView.swift` — General tab
- `SettingsAppearanceView.swift` — Appearance tab  
- `SettingsHotkeysView.swift` — Hotkeys tab
- `WaveformStyle.swift` — enum for waveform variants + preview views

### Settings Storage
- `UserDefaults` via `@AppStorage` property wrappers in `SettingsViewModel`
- Keys prefixed with `com.dynamicisland.`

### Data Flow
```
SettingsViewModel (ObservableObject)
  → @AppStorage keys sync to UserDefaults
  → WindowManager observes changes via .onReceive or Combine
  → PillView/ContentView reads waveform style from SettingsViewModel
  → NowPlayingService reads music source from SettingsViewModel
  → Hotkeys registered with CGEvent or MASShortcut
```

### Integration Points
- `DynamicIslandApp.swift` — instantiate `MenuBarManager` on launch
- `WindowManager.swift` — observe width/position changes to reposition window
- `ContentView.swift` — observe waveform style to switch pill animation
- `NowPlayingService.swift` — filter by selected music source
- `PillView.swift` — render selected waveform style

## Scope Notes
- **Notifications** (iPhone-style alerts) deferred to future iteration
- Hotkeys use `CGEvent` or `MASShortcut` for global capture
- Waveform styles are visual-only at launch; can be expanded later
