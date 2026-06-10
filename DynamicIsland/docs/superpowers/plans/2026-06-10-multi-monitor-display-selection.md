# Multi-Monitor Display Selection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users pick which screen(s) the Dynamic Island appears on — all screens, or a single screen by display name.

**Architecture:** Add `DisplayMode` enum + `selectedScreenName` to SettingsViewModel. Add display/screen pickers to SettingsAppearanceView. Rewrite WindowManager to maintain a dictionary of windows keyed by screen name instead of a single window.

**Tech Stack:** Swift, SwiftUI, AppKit, `@AppStorage`

---

### Task 1: Create DisplayMode model

**Files:**
- Create: `Sources/Resound/Models/DisplayMode.swift`

- [ ] **Step 1: Create the file**

```swift
enum DisplayMode: String, CaseIterable, Codable {
    case allScreens = "All Screens"
    case singleScreen = "Single Screen"
}
```

- [ ] **Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeds

---

### Task 2: Add display settings to SettingsViewModel

**Files:**
- Modify: `Sources/Resound/ViewModels/SettingsViewModel.swift`

- [ ] **Step 1: Add new AppStorage properties**

After line 11 (`@AppStorage("waveformStyle") ...`), add:

```swift
@AppStorage("displayMode") var displayModeRaw = DisplayMode.allScreens.rawValue
@AppStorage("selectedScreen") var selectedScreenName = ""
```

After the `waveformStyle` computed property (after line 36), add:

```swift
var displayMode: DisplayMode {
    get { DisplayMode(rawValue: displayModeRaw) ?? .allScreens }
    set { displayModeRaw = newValue.rawValue }
}
```

- [ ] **Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeds

---

### Task 3: Add Display/Screen pickers to Settings UI

**Files:**
- Modify: `Sources/Resound/Views/Settings/SettingsAppearanceView.swift`

- [ ] **Step 1: Add display picker section**

After the Position picker (after line 24), add:

```swift
Picker("Display", selection: Binding(
    get: { settings.displayMode },
    set: { settings.displayMode = $0 }
)) {
    ForEach(DisplayMode.allCases, id: \.self) { mode in
        Text(mode.rawValue).tag(mode)
    }
}

if settings.displayMode == .singleScreen {
    Picker("Screen", selection: $settings.selectedScreenName) {
        ForEach(NSScreen.screens, id: \.localizedName) { screen in
            Text(screen.localizedName).tag(screen.localizedName)
        }
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeds

---

### Task 4: Rewrite WindowManager for multi-window support

**Files:**
- Modify: `Sources/Resound/WindowManager.swift`

- [ ] **Step 1: Replace single-window with multi-window**

Apply these changes to `WindowManager.swift`:

1. Replace `private var window: NSWindow?` with:
```swift
private var windows: [String: NSWindow] = [:]
```

2. Replace `func show()` with:
```swift
func show() {
    rebuildWindows()
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(screenConfigurationChanged),
        name: NSApplication.didChangeScreenParametersNotification,
        object: nil
    )
}
```

3. Replace settings subscription in `show()` — keep the existing `settings.objectWillChange` subscription but change its handler to call `rebuildWindows()` instead of `positionWindow`:
```swift
settings.objectWillChange
    .receive(on: DispatchQueue.main)
    .sink { [weak self] _ in
        self?.rebuildWindows()
    }
    .store(in: &cancellables)
```

4. Remove `toggle()`, `expand()`, `collapse()` methods (they'll be handled per-window via ContentView closures — each window already gets its own `onToggle`)

5. Add new methods:
```swift
@objc private func screenConfigurationChanged() {
    rebuildWindows()
}

private func rebuildWindows() {
    let targetScreens = resolveTargetScreens()
    let targetNames = Set(targetScreens.map(\.localizedName))

    // Close windows for screens no longer in target set
    for (name, win) in windows where !targetNames.contains(name) {
        win.close()
        windows.removeValue(forKey: name)
    }

    // Create or reposition windows for target screens
    for screen in targetScreens {
        if let existing = windows[screen.localizedName] {
            let height = isExpanded ? expandedHeight : collapsedHeight
            positionWindow(existing, on: screen, height: height)
        } else {
            let win = makeWindow(for: screen)
            windows[screen.localizedName] = win
        }
    }
}

private func resolveTargetScreens() -> [NSScreen] {
    switch settings.displayMode {
    case .allScreens:
        return NSScreen.screens
    case .singleScreen:
        if let matched = NSScreen.screens.first(where: { $0.localizedName == settings.selectedScreenName }) {
            return [matched]
        }
        return NSScreen.screens.first.map { [$0] } ?? []
    }
}

private func makeWindow(for screen: NSScreen) -> NSWindow {
    let contentView = ContentView(onToggle: { [weak self] expanded in
        if expanded { self?.expand() } else { self?.collapse() }
    })
    let hostingView = NSHostingView(rootView: contentView)
    hostingView.sizingOptions = []

    let window = NSWindow(
        contentRect: .zero,
        styleMask: [.borderless, .nonactivatingPanel],
        backing: .buffered,
        defer: false
    )
    window.isOpaque = false
    window.backgroundColor = .clear
    window.hasShadow = false
    window.level = .statusBar
    window.appearance = NSAppearance(named: .darkAqua)
    window.ignoresMouseEvents = false
    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    window.contentView = hostingView

    let height = isExpanded ? expandedHeight : collapsedHeight
    positionWindow(window, on: screen, height: height)
    window.makeKeyAndOrderFront(nil)
    return window
}

private func positionWindow(_ window: NSWindow, on screen: NSScreen, height: CGFloat) {
    guard !isResizing else { return }
    isResizing = true
    defer { isResizing = false }

    let width = CGFloat(settings.notchWidth)
    let x: CGFloat
    switch settings.notchPosition {
    case .left: x = screen.frame.minX + 8
    case .center: x = screen.frame.midX - width / 2
    case .right: x = screen.frame.maxX - width - 8
    }
    let topEdge = settings.notchPosition == .center ? screen.frame.maxY : screen.visibleFrame.maxY
    let y = topEdge - height
    let frame = NSRect(x: x, y: y, width: width, height: height)
    if window.frame.equalTo(frame) { return }
    window.setFrame(frame, display: true, animate: false)
    window.invalidateShadow()
}
```

6. Keep `expand()` and `collapse()` as-is (they work on all windows via positionWindow), but update `expand()` to accept an optional screen parameter. Actually, looking at this more carefully — with multiple windows, expand/collapse becomes per-window. Let me reconsider.

Actually, the hover state is per-window via `ContentView.onToggle`. The `expand()`/`collapse()` methods are called from the `onToggle` closure. But the current `expand()` and `collapse()` use `guard let window = window else { return }` which won't work with multiple windows.

Let me restructure expand/collapse to be per-window. Remove the `isExpanded` property and instead handle it in each window's `ContentView` instance directly. The `ContentView` already manages its own `isExpanded` state — the `WindowManager`'s `expand()`/`collapse()` callbacks just position the window.

For multi-window, the `onToggle` closure needs to know which screen the window is on. Let me change the approach:

Replace `expand()`/`collapse()` with a method that takes a screen:

```swift
private func setWindowExpanded(_ window: NSWindow, on screen: NSScreen, expanded: Bool) {
    let height = expanded ? expandedHeight : collapsedHeight
    if expanded {
        positionWindow(window, on: screen, height: expandedHeight)
    } else {
        // Delay collapse like before
        collapseWorkItem?.cancel()
        let work = DispatchWorkItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                guard let self else { return }
                self.positionWindow(window, on: screen, height: self.collapsedHeight)
            }
        }
        collapseWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
    }
}
```

And update `makeWindow` to pass screen info to the closure:

```swift
private func makeWindow(for screen: NSScreen) -> NSWindow {
    let screenName = screen.localizedName
    let contentView = ContentView(onToggle: { [weak self] expanded in
        guard let self, let win = self.windows[screenName] else { return }
        self.setWindowExpanded(win, on: screen, expanded: expanded)
    })
    // ... rest of window creation
}
```

- [ ] **Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeds

---

### Task 5: Test the feature

- [ ] **Step 1: Run the app**

Run: `make run`
Expected: App launches, status bar icon appears

- [ ] **Step 2: Test default behavior (All Screens)**

Connect a second monitor. Verify the Dynamic Island pill appears on both screens.
Hover over each pill — each should independently expand/collapse.

- [ ] **Step 3: Test single screen mode**

Open Settings → Appearance. Change Display to "Single Screen". Pick a specific screen.
Verify the island only appears on the chosen screen.

- [ ] **Step 4: Test screen switching**

Switch to the other screen in settings. Verify the island moves from one screen to the other.

- [ ] **Step 5: Test hotkey toggle**

Press the configured hotkey. Verify the island toggles on the selected screen(s).

---

### Task 6: Commit (after testing)

- [ ] **Step 1: Stage changes**

```bash
git add Sources/Resound/Models/DisplayMode.swift \
       Sources/Resound/ViewModels/SettingsViewModel.swift \
       Sources/Resound/Views/Settings/SettingsAppearanceView.swift \
       Sources/Resound/WindowManager.swift
```

- [ ] **Step 2: Commit**

```bash
git commit -m "feat: add multi-monitor display selection with per-screen Dynamic Island windows"
```
