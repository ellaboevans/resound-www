# Lock Screen Player Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Display a custom now-playing player on the macOS 14+ lock screen, co-existing with system elements (clock, user icon, password field).

**Architecture:** Start with Layer 1 (NSWindow at `screenSaverWindowLevel`). If NSWindows are deactivated by WindowServer when the user session is locked, fall back to Layer 2 (pure CGS window via SkyLight private API).

**Tech Stack:** Swift, SwiftUI, AppKit, Combine, SkyLight.framework (private CGS API for Layer 2 fallback)

---

## File Structure

### New Files
- `DynamicIsland/Sources/Resound/Views/LockScreenPlayerView.swift` — SwiftUI card rendering album art, title, progress bar, controls
- `DynamicIsland/Sources/Resound/ViewControllers/LockScreenViewController.swift` — NSViewController managing the NSWindow + NSHostingView
- `DynamicIsland/Sources/Resound/Coordinators/LockScreenCoordinator.swift` — orchestrator: lock/unlock notifications, Combine subscription, lifecycle
- `DynamicIsland/Sources/Resound/Services/CGSManager.swift` — CGS private API loader (Layer 2 fallback, built only if needed)

### Modified Files
- `DynamicIsland/Sources/Resound/App/AppCoordinator.swift` — add LockScreenCoordinator property, start/stop it

---

### Task 1: LockScreenPlayerView (SwiftUI card)

**Files:**
- Create: `DynamicIsland/Sources/Resound/Views/LockScreenPlayerView.swift`

- [ ] **Step 1: Create LockScreenPlayerView**

```swift
import SwiftUI

struct LockScreenPlayerView: View {
    let trackTitle: String
    let artistName: String
    let albumTitle: String
    let artwork: NSImage?
    let elapsed: TimeInterval
    let duration: TimeInterval
    let isPlaying: Bool
    let isEmpty: Bool

    var body: some View {
        VStack(spacing: 14) {
            if isEmpty {
                emptyState
            } else {
                trackRow
                progressBar
                transportControls
            }
        }
        .padding(20)
        .frame(width: 340)
        .background(
            ZStack {
                Color.black.opacity(0.92)
                VisualEffectView(material: .dark, blendingMode: .withinWindow)
                    .opacity(0.3)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var emptyState: some View {
        HStack(spacing: 10) {
            Text("♪")
                .font(.title2)
                .foregroundColor(.white.opacity(0.3))
            Text("Nothing playing")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.vertical, 20)
    }

    private var trackRow: some View {
        HStack(spacing: 14) {
            if let artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [.pink, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 52, height: 52)
                    Text("♪")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(trackTitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(artistName)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
                Text(albumTitle)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.3))
                    .lineLimit(1)
            }
        }
    }

    private var progressBar: some View {
        HStack(spacing: 8) {
            Text(formatTime(elapsed))
                .font(.system(size: 10, design: .monospaced).monospacedDigit())
                .foregroundColor(.white.opacity(0.3))
                .frame(width: 32, alignment: .trailing)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 3)
                    Capsule()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: geo.size.width * progress, height: 3)
                }
            }
            .frame(height: 3)
            Text(formatTime(duration))
                .font(.system(size: 10, design: .monospaced).monospacedDigit())
                .foregroundColor(.white.opacity(0.3))
                .frame(width: 32)
        }
    }

    private var transportControls: some View {
        HStack(spacing: 32) {
            Button(action: {}) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
            }
            .buttonStyle(.plain)
            Button(action: {}) {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 36, height: 36)
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.black)
                }
            }
            .buttonStyle(.plain)
            Button(action: {}) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
    }

    private var progress: Double {
        duration > 0 ? min(max(elapsed / duration, 0), 1) : 0
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let m = Int(time) / 60
        let s = Int(time) % 60
        return "\(m):\(String(format: "%02d", s))"
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blendingMode
        v.state = .active
        return v
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
```

- [ ] **Step 2: Build check**

Run: `swift build 2>&1 | tail -5`
Expected: Build succeeds (warnings OK)

- [ ] **Step 3: Commit**

```bash
git add DynamicIsland/Sources/Resound/Views/LockScreenPlayerView.swift
git commit -m "feat: add LockScreenPlayerView SwiftUI card"
```

---

### Task 2: LockScreenViewController (NSWindow wrapper)

**Files:**
- Create: `DynamicIsland/Sources/Resound/ViewControllers/LockScreenViewController.swift`

- [ ] **Step 1: Create LockScreenViewController**

```swift
import Cocoa
import SwiftUI

final class LockScreenViewController: NSViewController {
    private var hostingView: NSHostingView<LockScreenPlayerView>?
    private var window: NSWindow?

    private var trackTitle = ""
    private var artistName = ""
    private var albumTitle = ""
    private var artwork: NSImage?
    private var elapsed: TimeInterval = 0
    private var duration: TimeInterval = 0
    private var isPlaying = false
    private var isEmpty = true

    func show() {
        guard window == nil else { return }

        let hosting = NSHostingView(rootView: makeView())
        hosting.translatesAutoresizingMaskIntoConstraints = false
        self.hostingView = hosting

        let contentRect = NSRect(x: 0, y: 0, width: 340, height: 172)
        let panel = NSPanel(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .screenSaverWindowLevel
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel.contentView = hosting
        panel.orderFrontRegardless()
        self.window = panel

        positionWindow(panel)
    }

    func hide() {
        window?.orderOut(nil)
        window = nil
        hostingView = nil
    }

    func update(trackTitle: String, artistName: String, albumTitle: String, artwork: NSImage?,
                elapsed: TimeInterval, duration: TimeInterval, isPlaying: Bool) {
        self.trackTitle = trackTitle
        self.artistName = artistName
        self.albumTitle = albumTitle
        self.artwork = artwork
        self.elapsed = elapsed
        self.duration = duration
        self.isPlaying = isPlaying
        self.isEmpty = trackTitle.isEmpty
        hostingView?.rootView = makeView()
    }

    private func makeView() -> LockScreenPlayerView {
        LockScreenPlayerView(
            trackTitle: trackTitle,
            artistName: artistName,
            albumTitle: albumTitle,
            artwork: artwork,
            elapsed: elapsed,
            duration: duration,
            isPlaying: isPlaying,
            isEmpty: isEmpty
        )
    }

    private func positionWindow(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let panelWidth: CGFloat = 340
        let panelHeight: CGFloat = 172
        let x = (screen.frame.width - panelWidth) / 2
        let y = (screen.frame.height - panelHeight) / 2
        panel.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true)
        panel.center()
    }
}
```

- [ ] **Step 2: Build check**

Run: `swift build 2>&1 | tail -5`
Expected: Build succeeds

- [ ] **Step 3: Commit**

```bash
git add DynamicIsland/Sources/Resound/ViewControllers/LockScreenViewController.swift
git commit -m "feat: add LockScreenViewController with NSWindow at screenSaverWindowLevel"
```

---

### Task 3: LockScreenCoordinator

**Files:**
- Create: `DynamicIsland/Sources/Resound/Coordinators/LockScreenCoordinator.swift`

- [ ] **Step 1: Create LockScreenCoordinator**

```swift
import Cocoa
import Combine

@MainActor
final class LockScreenCoordinator {
    private let viewController = LockScreenViewController()
    private var cancellables = Set<AnyCancellable>()
    private var isLocked = false

    func start() {
        observeLockState()
        observeNowPlaying()

        // Check if already locked on launch
        if let session = CGSessionCopyCurrentDictionary() as? [String: Any],
           session["CGSSessionScreenIsLocked"] as? Int == 1 {
            isLocked = true
            viewController.show()
        }
    }

    func stop() {
        viewController.hide()
        cancellables.removeAll()
    }

    private func observeLockState() {
        let center = DistributedNotificationCenter.default()
        center.addObserver(forName: NSNotification.Name("com.apple.screenIsLocked"), object: nil, queue: .main) { [weak self] _ in
            self?.isLocked = true
            self?.viewController.show()
        }
        center.addObserver(forName: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil, queue: .main) { [weak self] _ in
            self?.isLocked = false
            self?.viewController.hide()
        }
    }

    private func observeNowPlaying() {
        NowPlayingService.shared.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                guard let self else { return }
                var artwork: NSImage?
                if !info.artworkPath.isEmpty {
                    artwork = NSImage(contentsOfFile: info.artworkPath)
                }
                self.viewController.update(
                    trackTitle: info.trackTitle,
                    artistName: info.artistName,
                    albumTitle: info.albumTitle,
                    artwork: artwork,
                    elapsed: info.elapsedTime,
                    duration: info.duration,
                    isPlaying: info.isPlaying
                )
            }
            .store(in: &cancellables)
    }
}
```

- [ ] **Step 2: Build check**

Run: `swift build 2>&1 | tail -5`
Expected: Build succeeds

- [ ] **Step 3: Commit**

```bash
git add DynamicIsland/Sources/Resound/Coordinators/LockScreenCoordinator.swift
git commit -m "feat: add LockScreenCoordinator for lock/unlock lifecycle + data flow"
```

---

### Task 4: Wire into AppCoordinator

**Files:**
- Modify: `DynamicIsland/Sources/Resound/App/AppCoordinator.swift`

- [ ] **Step 1: Add LockScreenCoordinator to AppCoordinator**

```swift
@MainActor
final class AppCoordinator {
    private let nowPlaying: NowPlayingViewModel
    private let windowManager: WindowManager
    private let menuBarManager: MenuBarManager
    private let lockScreen = LockScreenCoordinator()

    // ... existing init methods unchanged ...

    func start() {
        nowPlaying.start()
        windowManager.show()
        menuBarManager.setup()
        lockScreen.start()
    }

    func stop() {
        nowPlaying.stop()
        lockScreen.stop()
    }
}
```

The full file after changes:

```swift
import Foundation

@MainActor
final class AppCoordinator {
    private let nowPlaying: NowPlayingViewModel
    private let windowManager: WindowManager
    private let menuBarManager: MenuBarManager
    private let lockScreen = LockScreenCoordinator()

    convenience init() {
        self.init(
            nowPlaying: .shared,
            windowManager: .shared,
            menuBarManager: .shared
        )
    }

    init(
        nowPlaying: NowPlayingViewModel,
        windowManager: WindowManager,
        menuBarManager: MenuBarManager
    ) {
        self.nowPlaying = nowPlaying
        self.windowManager = windowManager
        self.menuBarManager = menuBarManager
    }

    func start() {
        nowPlaying.start()
        windowManager.show()
        menuBarManager.setup()
        lockScreen.start()
    }

    func stop() {
        nowPlaying.stop()
        lockScreen.stop()
    }
}
```

- [ ] **Step 2: Build check**

Run: `swift build 2>&1 | tail -5`
Expected: Build succeeds

- [ ] **Step 3: Commit**

```bash
git add DynamicIsland/Sources/Resound/App/AppCoordinator.swift
git commit -m "feat: wire LockScreenCoordinator into AppCoordinator lifecycle"
```

---

### Task 5: Build and Validate

**Files:** (none — this is a test/build task)

- [ ] **Step 1: Build release**

Run: `swift build -c release 2>&1 | tail -10`
Expected: Build succeeds

- [ ] **Step 2: Run the app and lock the screen**

1. Open the built app
2. Play some music (Spotify or Music.app)
3. Lock the screen (Cmd+Ctrl+Q or apple menu → Lock Screen)
4. Observe: does the player card appear on the lock screen?

Expected: either A) the card appears (NSWindow approach works!), or B) the card does not appear (need Layer 2 CGS fallback).

- [ ] **Step 3: If NSWindow appears and works → done**

No further work needed. Proceed to validation and commit.

- [ ] **Step 4: If NSWindow does NOT appear → build CGSManager (Layer 2)**

Proceed to Task 6.

- [ ] **Step 5: Commit**

```bash
git add .
git commit -m "chore: lock screen player ready for validation"
```

---

### Task 6: CGSManager (Layer 2 fallback — only if NSWindow fails)

**Files:**
- Create: `DynamicIsland/Sources/Resound/Services/CGSManager.swift`

- [ ] **Step 1: Create CGSManager**

```swift
import Foundation

typealias CGSConnection = UInt32
typealias CGSWindowID = UInt32

struct CGSFunctions {
    let newConnection: @convention(c) (UnsafeMutableRawPointer?) -> CGSConnection
    let newWindow: @convention(c) (CGSConnection, CGRect, CGSWindowID) -> OSStatus
    let releaseWindow: @convention(c) (CGSConnection, CGSWindowID) -> OSStatus
    let releaseConnection: @convention(c) (CGSConnection) -> OSStatus
    let setWindowLevel: @convention(c) (CGSConnection, CGSWindowID, Int32) -> OSStatus
    let orderWindow: @convention(c) (CGSConnection, CGSWindowID, Int32, CGSWindowID) -> OSStatus
    let setWindowOpacity: @convention(c) (CGSConnection, CGSWindowID, Bool) -> OSStatus
    let setWindowAlpha: @convention(c) (CGSConnection, CGSWindowID, Float) -> OSStatus
    let setWindowBounds: @convention(c) (CGSConnection, CGSWindowID, CGRect) -> OSStatus
}

final class CGSManager {
    static let shared = CGSManager()
    private(set) var functions: CGSFunctions?
    private(set) var isAvailable = false
    private var connection: CGSConnection = 0

    func load() -> Bool {
        guard !isAvailable else { return true }
        guard let lib = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY) else {
            return false
        }

        func symbol<T>(_ name: String) -> T? {
            guard let sym = dlsym(lib, name) else { return nil }
            return unsafeBitCast(sym, to: T.self)
        }

        guard let nc: CGSFunctions.CGSFuncNewConnection = symbol("CGSNewConnection"),
              let nw: CGSFunctions.CGSFuncNewWindow = symbol("CGSNewWindow"),
              let rw: CGSFunctions.CGSFuncReleaseWindow = symbol("CGSReleaseWindow"),
              let rcn: CGSFunctions.CGSFuncReleaseConnection = symbol("CGSReleaseConnection"),
              let swl: CGSFunctions.CGSFuncSetWindowLevel = symbol("CGSSetWindowLevel"),
              let ow: CGSFunctions.CGSFuncOrderWindow = symbol("CGSOrderWindow"),
              let swo: CGSFunctions.CGSFuncSetWindowOpacity = symbol("CGSSetWindowOpacity"),
              let swa: CGSFunctions.CGSFuncSetWindowAlpha = symbol("CGSSetWindowAlpha"),
              let swb: CGSFunctions.CGSFuncSetWindowBounds = symbol("CGSSetWindowBounds")
        else { return false }

        functions = CGSFunctions(newConnection: nc, newWindow: nw, releaseWindow: rw,
                                 releaseConnection: rcn, setWindowLevel: swl, orderWindow: ow,
                                 setWindowOpacity: swo, setWindowAlpha: swa, setWindowBounds: swb)
        isAvailable = true
        return true
    }

    func createConnection() -> CGSConnection? {
        guard isAvailable, let f = functions else { return nil }
        let cid = f.newConnection(nil)
        guard cid != 0 else { return nil }
        connection = cid
        return cid
    }
}
```

Wait, the typealias needs to match actual CGS types. Let me use the known signatures:

```swift
import Foundation

typealias CGSConnection = UInt32
typealias CGSWindowID = UInt32

final class CGSManager {
    static let shared = CGSManager()
    private(set) var isAvailable = false

    private typealias CGSNewConnectionFunc = @convention(c) (UnsafeMutableRawPointer?) -> CGSConnection
    private typealias CGSNewWindowFunc = @convention(c) (CGSConnection, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> OSStatus
    private typealias CGSReleaseWindowFunc = @convention(c) (CGSConnection, CGSWindowID) -> OSStatus
    private typealias CGSReleaseConnectionFunc = @convention(c) (CGSConnection) -> OSStatus
    private typealias CGSSetWindowLevelFunc = @convention(c) (CGSConnection, CGSWindowID, Int32) -> OSStatus
    private typealias CGSOrderWindowFunc = @convention(c) (CGSConnection, CGSWindowID, Int32, CGSWindowID) -> OSStatus
    private typealias CGSSetWindowOpacityFunc = @convention(c) (CGSConnection, CGSWindowID, Bool) -> OSStatus
    private typealias CGSSetWindowAlphaFunc = @convention(c) (CGSConnection, CGSWindowID, Float) -> OSStatus
    private typealias CGSSetWindowBoundsFunc = @convention(c) (CGSConnection, CGSWindowID, CGRect) -> OSStatus

    private var newConnection: CGSNewConnectionFunc?
    private var newWindow: CGSNewWindowFunc?
    private var releaseWindow: CGSReleaseWindowFunc?
    private var releaseConnection: CGSReleaseConnectionFunc?
    private var setWindowLevel: CGSSetWindowLevelFunc?
    private var orderWindow: CGSOrderWindowFunc?
    private var setWindowOpacity: CGSSetWindowOpacityFunc?
    private var setWindowAlpha: CGSSetWindowAlphaFunc?
    private var setWindowBounds: CGSSetWindowBoundsFunc?

    func load() -> Bool {
        guard !isAvailable else { return true }
        guard let lib = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY) else {
            return false
        }

        func symbol<T>(_ name: String) -> T? {
            guard let sym = dlsym(lib, name) else { return nil }
            return unsafeBitCast(sym, to: T.self)
        }

        newConnection = symbol("CGSNewConnection")
        newWindow = symbol("CGSNewWindow")
        releaseWindow = symbol("CGSReleaseWindow")
        releaseConnection = symbol("CGSReleaseConnection")
        setWindowLevel = symbol("CGSSetWindowLevel")
        orderWindow = symbol("CGSOrderWindow")
        setWindowOpacity = symbol("CGSSetWindowOpacity")
        setWindowAlpha = symbol("CGSSetWindowAlpha")
        setWindowBounds = symbol("CGSSetWindowBounds")

        let allLoaded = newConnection != nil && newWindow != nil && releaseWindow != nil &&
                        releaseConnection != nil && setWindowLevel != nil && orderWindow != nil &&
                        setWindowOpacity != nil && setWindowAlpha != nil && setWindowBounds != nil
        isAvailable = allLoaded
        return allLoaded
    }

    func createConnection() -> CGSConnection? {
        guard isAvailable, let fn = newConnection else { return nil }
        let cid = fn(nil)
        return cid != 0 ? cid : nil
    }

    func setLevel(connection: CGSConnection, window: CGSWindowID, level: Int32) -> Bool {
        guard isAvailable, let fn = setWindowLevel else { return false }
        return fn(connection, window, level) == 0
    }

    // ... additional helpers as needed during Layer 2 implementation
}
```

- [ ] **Step 2: Build check**

Run: `swift build 2>&1 | tail -5`
Expected: Build succeeds (with a deprecation warning on `RTLD_LAZY` — that's fine)

- [ ] **Step 3: Commit**

```bash
git add DynamicIsland/Sources/Resound/Services/CGSManager.swift
git commit -m "feat: add CGSManager for SkyLight private API (Layer 2 fallback)"
```

---

### Task 7: CGS Window Rendering (Layer 2 — only if NSWindow fails)

**Files:**
- Modify: `DynamicIsland/Sources/Resound/ViewControllers/LockScreenViewController.swift`
- Create: `DynamicIsland/Sources/Resound/Views/LockScreenCGSView.swift`

This task depends on the exact CGS API behavior observed during testing. Full implementation details to be determined based on what CGSWindowID we get and how ordering works. The key steps will be:

1. Create a CGS connection + window at `kCGScreenSaverWindowLevel` (1000)
2. Create a CALayer and set it as the window's backing layer
3. Render SwiftUI content into the layer using `ImageRenderer` or `MTKView`
4. Position and alpha-animate on lock/unlock

Implementation deferred until NSWindow approach is validated (Task 5).
