# Multi-Monitor Display Selection

**Date:** 2026-06-10
**Status:** Draft

## Problem

When a user has multiple displays connected (e.g., built-in MacBook display + external monitor), the Dynamic Island panel currently uses `NSScreen.main` to determine positioning. This causes the island to jump between screens unpredictably when the "main" screen changes based on mouse position or window focus.

## Goals

- Let users choose which screen(s) the Dynamic Island appears on
- Eliminate jumping behavior
- Support three modes: all screens, a specific screen only

## Models

### DisplayMode (new file: `Models/DisplayMode.swift`)

```swift
enum DisplayMode: String, CaseIterable, Codable {
    case allScreens = "All Screens"
    case singleScreen = "Single Screen"
}
```

### SettingsViewModel changes

Add two new `@AppStorage` properties:

```swift
@AppStorage("displayMode") var displayModeRaw = DisplayMode.allScreens.rawValue
@AppStorage("selectedScreen") var selectedScreenName = ""

var displayMode: DisplayMode {
    get { DisplayMode(rawValue: displayModeRaw) ?? .allScreens }
    set { displayModeRaw = newValue.rawValue }
}
```

## Settings UI

In `SettingsAppearanceView`, add a "Display" section:

- **Display Picker**: "All Screens" / "Single Screen"
- **Screen Picker** (shown only when `.singleScreen`): dropdown listing `NSScreen.screens` by `localizedName`, defaulting to the first screen in the list

## WindowManager Changes

### Data structures

Replace `private var window: NSWindow?` with:

```swift
private var windows: [String: NSWindow] = [:]
```

### Core method: `rebuildWindows()`

Called when:
- App starts (from `show()`)
- Settings change (via existing `objectWillChange` subscription)
- Screen configuration changes (via `NSApplication.didChangeScreenParametersNotification`)

Logic:
1. Determine target screens based on `displayMode` and `selectedScreenName`
   - `.allScreens` → all entries in `NSScreen.screens`
   - `.singleScreen` → the screen matching `selectedScreenName`, or first screen if name not found
2. For each target screen:
   - If a window for that screen's name already exists, reposition it
   - Otherwise, create a new window and position it
3. For any existing windows whose screen is no longer in the target set, close and remove them

### Window creation

Factor window creation into a helper:

```swift
private func makeWindow(for screen: NSScreen) -> NSWindow
```

Same configuration as current code (borderless, nonactivatingPanel, statusBar level, darkAqua appearance).

### Positioning

Change `positionWindow(_:height:)` to `positionWindow(_:on:height:)` where the second parameter is the target `NSScreen` instead of using `NSScreen.main`.

### Hover / Interaction

No changes needed. Each `ContentView` instance naturally handles its own hover state independently via `onToggle`. Each window manages its own expand/collapse independently.

### Screen change notifications

In `show()`, register for:

```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(screenConfigurationChanged),
    name: NSApplication.didChangeScreenParametersNotification,
    object: nil
)
```

`screenConfigurationChanged` calls `rebuildWindows()`.

## Files Changed

| File | Change |
|------|--------|
| `Sources/Resound/Models/DisplayMode.swift` | **New** — `DisplayMode` enum |
| `Sources/Resound/ViewModels/SettingsViewModel.swift` | Add `displayMode`, `selectedScreenName`, computed properties |
| `Sources/Resound/Views/Settings/SettingsAppearanceView.swift` | Add Display/Screen pickers |
| `Sources/Resound/WindowManager.swift` | Rewrite for multi-window support |

## Edge Cases

- **Screen disconnected**: `rebuildWindows()` runs, window for that screen is closed and removed
- **Screen connected**: `rebuildWindows()` runs, window is created for the new screen (if in all-screens mode)
- **Selected screen name no longer exists**: fall back to the first screen in `NSScreen.screens`
- **Single screen mode with only one display**: works as before, no visible change
- **All screens mode with one display**: single window, same as current behavior
