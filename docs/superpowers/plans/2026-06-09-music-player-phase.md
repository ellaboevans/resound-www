# Music Player Phase — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the music player core of the Dynamic Island — a floating pill at top-center of screen that collapses/expands to show now playing info and playback controls.

**Architecture:** SwiftUI views inside a borderless NSWindow configured as `.floating` level, positioned at top-center of screen. Now playing data from MediaPlayer framework. Spring-based animations for pill↔card morph.

**Tech Stack:** SwiftUI, AppKit (NSWindow), MediaPlayer framework, SwiftPM

---

### Task 1: Project Scaffold

**Files:**
- Create: `DynamicIsland/Package.swift`
- Create: `DynamicIsland/Sources/DynamicIsland/DynamicIslandApp.swift`
- Create: `DynamicIsland/Sources/DynamicIsland/Info.plist`
- Create: `DynamicIsland/Makefile`

- [ ] **Step 1: Create Package.swift**

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DynamicIsland",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "DynamicIsland",
            resources: [.copy("Info.plist")]
        )
    ]
)
```

- [ ] **Step 2: Create Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleName</key>
    <string>DynamicIsland</string>
    <key>CFBundleIdentifier</key>
    <string>com.dynamicisland.app</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
</dict>
</plist>
```

- [ ] **Step 3: Create DynamicIslandApp.swift (entry point)**

```swift
import SwiftUI

@main
struct DynamicIslandApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { }
    }
}
```

- [ ] **Step 4: Create AppDelegate.swift**

```swift
import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowManager: WindowManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        windowManager = WindowManager()
        windowManager?.show()
    }
}
```

- [ ] **Step 5: Create Makefile**

```makefile
build:
	swift build

run: build
	.build/debug/DynamicIsland

release:
	swift build -c release
	cp -r .build/release/DynamicIsland DynamicIsland.app/Contents/MacOS/
	cp Sources/DynamicIsland/Info.plist DynamicIsland.app/Contents/

clean:
	rm -rf .build DynamicIsland.app
```

- [ ] **Step 6: Build and verify**

Run: `make build`
Expected: Compiles successfully

- [ ] **Step 7: Check that app runs with no dock icon (LSUIElement)**

Run: `make run` (stop after confirming no dock icon appears)
Expected: App runs, no dock icon, no menu bar icon yet

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: scaffold DynamicIsland project"
```

---

### Task 2: Window Manager — Floating Borderless Window

**Files:**
- Create: `DynamicIsland/Sources/DynamicIsland/WindowManager.swift`

- [ ] **Step 1: Create WindowManager.swift**

```swift
import Cocoa
import SwiftUI

final class WindowManager {
    private var window: NSWindow?

    func show() {
        let contentView = ContentView()

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)

        positionWindow(window)
        self.window = window
    }

    private func positionWindow(_ window: NSWindow) {
        guard let screen = NSScreen.main?.visibleFrame else { return }
        let windowWidth: CGFloat = 340
        let windowHeight: CGFloat = 34
        let x = screen.midX - windowWidth / 2
        let y = screen.maxY - windowHeight - 8
        window.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
        window.invalidateShadow()
    }

    func toggleExpanded(_ expanded: Bool) {
        guard let window = window, let screen = NSScreen.main?.visibleFrame else { return }
        let windowWidth: CGFloat = 340
        let collapsedHeight: CGFloat = 34
        let expandedHeight: CGFloat = 200

        let height = expanded ? expandedHeight : collapsedHeight
        let y = screen.maxY - height - 8
        let x = screen.midX - windowWidth / 2

        NSAnimationContext.runAnimationGroup { context in
            context.duration = expanded ? 0.4 : 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().setFrame(NSRect(x: x, y: y, width: windowWidth, height: height), display: true)
            window.invalidateShadow()
        }
    }
}
```

- [ ] **Step 2: Build**

Run: `make build`
Expected: Compiles successfully (ContentView.swift not yet created — will fail. Create a placeholder.)

- [ ] **Step 3: Create placeholder ContentView**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Island")
            .foregroundColor(.white)
    }
}
```

- [ ] **Step 4: Build again**

Run: `make build`
Expected: Compiles successfully

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add floating borderless window manager"
```

---

### Task 3: Collapsed Pill View

**Files:**
- Create: `DynamicIsland/Sources/DynamicIsland/Views/PillView.swift`

- [ ] **Step 1: Create PillView.swift**

```swift
import SwiftUI

struct PillView: View {
    let trackTitle: String
    let artistName: String
    let isPlaying: Bool

    var body: some View {
        HStack(spacing: 10) {
            if isPlaying {
                albumArtIcon
                trackLabel
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "music.note")
                        .font(.system(size: 10, weight: .medium))
                    Text("No Music Playing")
                        .font(.system(size: 12, weight: .medium))
                }
                .opacity(0.4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
    }

    private var albumArtIcon: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [.pink, .red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 20, height: 20)
            .overlay(
                Image(systemName: "music.note")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
            )
    }

    private var trackLabel: some View {
        Text(trackTitle)
            .font(.system(size: 12, weight: .medium))
            .lineLimit(1)
            .frame(maxWidth: 140, alignment: .leading)
            .foregroundColor(.white)
    }
}
```

- [ ] **Step 2: Update ContentView to use PillView**

```swift
import SwiftUI

struct ContentView: View {
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            PillView(trackTitle: "Blinding Lights", artistName: "The Weeknd", isPlaying: true)
                .onTapGesture { withAnimation(.spring(duration: 0.4, bounce: 0.08)) { isExpanded.toggle() } }

            if isExpanded {
                EmptyView()
            }
        }
        .frame(maxWidth: 340)
    }
}
```

- [ ] **Step 3: Build and verify pill renders**

Run: `make build`
Expected: Compiles successfully

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: add collapsed pill view"
```

---

### Task 4: Now Playing Service — MediaPlayer Integration

**Files:**
- Create: `DynamicIsland/Sources/DynamicIsland/Services/NowPlayingService.swift`

- [ ] **Step 1: Create NowPlayingService.swift**

```swift
import MediaPlayer
import Combine

final class NowPlayingService {
    private var timer: Timer?
    let publisher = PassthroughSubject<NowPlayingInfo, Never>()

    struct NowPlayingInfo: Equatable {
        let trackTitle: String
        let artistName: String
        let albumTitle: String
        let duration: TimeInterval
        let elapsedTime: TimeInterval
        let isPlaying: Bool
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.pollNowPlaying()
        }
        pollNowPlaying()
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func pollNowPlaying() {
        guard let media = MPRemoteCommandCenter.shared().nowPlayingInfo else {
            publisher.send(NowPlayingInfo(
                trackTitle: "",
                artistName: "",
                albumTitle: "",
                duration: 0,
                elapsedTime: 0,
                isPlaying: false
            ))
            return
        }

        let info = NowPlayingInfo(
            trackTitle: media[MPMediaItemPropertyTitle] as? String ?? "",
            artistName: media[MPMediaItemPropertyArtist] as? String ?? "",
            albumTitle: media[MPMediaItemPropertyAlbumTitle] as? String ?? "",
            duration: media[MPMediaItemPropertyPlaybackDuration] as? TimeInterval ?? 0,
            elapsedTime: media[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? TimeInterval ?? 0,
            isPlaying: (media[MPNowPlayingInfoPropertyPlaybackRate] as? Double ?? 0) > 0
        )
        publisher.send(info)
    }
}
```

- [ ] **Step 2: Build**

Run: `make build`
Expected: Compiles successfully

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat: add now playing service"
```

---

### Task 5: Now Playing ViewModel

**Files:**
- Create: `DynamicIsland/Sources/DynamicIsland/ViewModels/NowPlayingViewModel.swift`

- [ ] **Step 1: Create NowPlayingViewModel.swift**

```swift
import Combine
import SwiftUI

@MainActor
final class NowPlayingViewModel: ObservableObject {
    @Published var trackTitle: String = ""
    @Published var artistName: String = ""
    @Published var albumTitle: String = ""
    @Published var duration: TimeInterval = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var isPlaying: Bool = false

    private let service = NowPlayingService()
    private var cancellables = Set<AnyCancellable>()

    var progress: Double {
        duration > 0 ? elapsedTime / duration : 0
    }

    var formattedElapsed: String {
        formatTime(elapsedTime)
    }

    var formattedRemaining: String {
        formatTime(max(0, duration - elapsedTime))
    }

    func start() {
        service.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                self?.trackTitle = info.trackTitle
                self?.artistName = info.artistName
                self?.albumTitle = info.albumTitle
                self?.duration = info.duration
                self?.elapsedTime = info.elapsedTime
                self?.isPlaying = info.isPlaying
            }
            .store(in: &cancellables)
        service.startMonitoring()
    }

    func stop() {
        service.stopMonitoring()
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}
```

- [ ] **Step 2: Build**

Run: `make build`
Expected: Compiles successfully

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat: add now playing view model"
```

---

### Task 6: Expanded Music Panel

**Files:**
- Create: `DynamicIsland/Sources/DynamicIsland/Views/MusicSection.swift`

- [ ] **Step 1: Create MusicSection.swift**

```swift
import SwiftUI

struct MusicSection: View {
    let trackTitle: String
    let artistName: String
    let albumTitle: String
    let progress: Double
    let elapsedText: String
    let remainingText: String
    let isPlaying: Bool
    let onPlayPause: () -> Void
    let onNext: () -> Void
    let onPrevious: () -> Void

    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 0) {
            // Album art + track info
            HStack(spacing: 14) {
                albumArt
                trackInfo
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Progress bar
            progressBar
                .padding(.horizontal, 16)
                .padding(.top, 10)

            // Playback controls
            HStack(spacing: 28) {
                controlButton("backward.fill", action: onPrevious)
                playPauseButton
                controlButton("forward.fill", action: onNext)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)

            // Time labels
            HStack {
                Text(elapsedText)
                    .font(.system(size: 10, weight: .medium))
                    .monospacedDigit()
                Spacer()
                Text("-\(remainingText)")
                    .font(.system(size: 10, weight: .medium))
                    .monospacedDigit()
            }
            .opacity(0.3)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private var albumArt: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [.purple, .teal],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 52, height: 52)
            .overlay(
                Image(systemName: "music.note")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            )
            .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
    }

    private var trackInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(trackTitle)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
            Text(artistName)
                .font(.system(size: 11))
                .opacity(0.45)
                .lineLimit(1)
            if !albumTitle.isEmpty {
                Text(albumTitle)
                    .font(.system(size: 10))
                    .opacity(0.3)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 3)
                Capsule()
                    .fill(Color.white)
                    .frame(width: geo.size.width * progress, height: 3)
                    .opacity(0.5)
            }
        }
        .frame(height: 3)
    }

    private var playPauseButton: some View {
        Button(action: onPlayPause) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: 32, height: 32)
                .background(Color.white)
                .clipShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func controlButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .medium))
                .opacity(0.35)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
```

- [ ] **Step 2: Build**

Run: `make build`
Expected: Compiles successfully

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat: add expanded music section with controls"
```

---

### Task 7: Animated Content View — Collapse/Expand + Stagger

**Files:**
- Modify: `DynamicIsland/Sources/DynamicIsland/Views/ContentView.swift`
- Create: `DynamicIsland/Sources/DynamicIsland/Views/ExpandedPanel.swift`

- [ ] **Step 1: Create ExpandedPanel.swift**

```swift
import SwiftUI

struct ExpandedPanel: View {
    let trackTitle: String
    let artistName: String
    let albumTitle: String
    let progress: Double
    let elapsedText: String
    let remainingText: String
    let isPlaying: Bool
    let onPlayPause: () -> Void
    let onNext: () -> Void
    let onPrevious: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            MusicSection(
                trackTitle: trackTitle,
                artistName: artistName,
                albumTitle: albumTitle,
                progress: progress,
                elapsedText: elapsedText,
                remainingText: remainingText,
                isPlaying: isPlaying,
                onPlayPause: onPlayPause,
                onNext: onNext,
                onPrevious: onPrevious
            )
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
        .opacity(0)
        .scaleEffect(0.95)
    }
}
```

- [ ] **Step 2: Rewrite ContentView with animation**

```swift
import SwiftUI

struct ContentView: View {
    @State private var isExpanded = false
    @StateObject private var nowPlaying = NowPlayingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            pillView
                .zIndex(1)

            if isExpanded {
                expandedPanel
                    .transition(.identity)
                    .offset(y: -6)
            }
        }
        .frame(width: 340)
        .onAppear { nowPlaying.start() }
    }

    private var pillView: some View {
        PillView(
            trackTitle: nowPlaying.trackTitle,
            artistName: nowPlaying.artistName,
            isPlaying: nowPlaying.isPlaying
        )
        .contentShape(Capsule())
        .onTapGesture {
            if isExpanded {
                collapse()
            } else {
                expand()
            }
        }
    }

    private var expandedPanel: some View {
        ExpandedPanel(
            trackTitle: nowPlaying.trackTitle,
            artistName: nowPlaying.artistName,
            albumTitle: nowPlaying.albumTitle,
            progress: nowPlaying.progress,
            elapsedText: nowPlaying.formattedElapsed,
            remainingText: nowPlaying.formattedRemaining,
            isPlaying: nowPlaying.isPlaying,
            onPlayPause: { /* TODO: implement */ },
            onNext: { /* TODO: implement */ },
            onPrevious: { /* TODO: implement */ }
        )
    }

    private func expand() {
        withAnimation(.spring(duration: 0.4, bounce: 0.08)) {
            isExpanded = true
        }
    }

    private func collapse() {
        withAnimation(.easeOut(duration: 0.2)) {
            isExpanded = false
        }
    }
}
```

- [ ] **Step 3: Build**

Run: `make build`
Expected: Compiles successfully

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: add expand/collapse animation with stagger"
```

---

### Task 8: Playback Control Actions

**Files:**
- Modify: `DynamicIsland/Sources/DynamicIsland/Services/NowPlayingService.swift`
- Modify: `DynamicIsland/Sources/DynamicIsland/ViewModels/NowPlayingViewModel.swift`
- Modify: `DynamicIsland/Sources/DynamicIsland/Views/ContentView.swift`

- [ ] **Step 1: Add playback commands to NowPlayingService**

Add after `stopMonitoring()`:

```swift
func playPause() {
    guard let app = fetchNowPlayingApp() else { return }
    let command = MPRemoteCommandCenter.shared().togglePlayPauseCommand
    command.send(nil)
}

func nextTrack() {
    MPRemoteCommandCenter.shared().nextTrackCommand.send(nil)
}

func previousTrack() {
    MPRemoteCommandCenter.shared().previousTrackCommand.send(nil)
}

private func fetchNowPlayingApp() -> NSRunningApplication? {
    // MediaPlayer doesn't expose which app is playing directly
    // MPRemoteCommandCenter handles routing to the right app
    return nil
}
```

Note: `MPRemoteCommandCenter` commands are designed to be sent to the system, which routes them to the active now-playing app. The actual playback is handled by the system — no direct app reference needed.

- [ ] **Step 2: Add control methods to NowPlayingViewModel**

```swift
func playPause() { service.playPause() }
func nextTrack() { service.nextTrack() }
func previousTrack() { service.previousTrack() }
```

- [ ] **Step 3: Wire up ContentView actions**

Replace the `onPlayPause`, `onNext`, `onPrevious` closures:

```swift
onPlayPause: { nowPlaying.playPause() },
onNext: { nowPlaying.nextTrack() },
onPrevious: { nowPlaying.previousTrack() }
```

- [ ] **Step 4: Build**

Run: `make build`
Expected: Compiles successfully

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: wire up playback controls"
```

---

### Task 9: Animation Polish

**Files:**
- Modify: `DynamicIsland/Sources/DynamicIsland/Views/ContentView.swift`
- Modify: `DynamicIsland/Sources/DynamicIsland/Views/ExpandedPanel.swift`
- Modify: `DynamicIsland/Sources/DynamicIsland/WindowManager.swift`

- [ ] **Step 1: Add content stagger to ExpandedPanel**

Replace the body with staggered entrance:

```swift
struct ExpandedPanel<Content: View>: View {
    @ViewBuilder let content: Content
    @State private var showContent = false

    var body: some View {
        content
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 6)
            .onAppear {
                withAnimation(.easeOut(duration: 0.2).delay(0.15)) {
                    showContent = true
                }
            }
            .onDisappear { showContent = false }
    }
}
```

- [ ] **Step 2: Update ContentView to use animated wrapper**

Replace `ExpandedPanel(...)` with:

```swift
ExpandedPanel {
    MusicSection(...)
}
```

- [ ] **Step 3: Update PillView press feedback**

Add to `PillView` body modifier chain:

```swift
.scaleEffect(isPressed ? 0.97 : 1)
.animation(.easeOut(duration: 0.12), value: isPressed)
.simultaneousGesture(
    DragGesture(minimumDistance: 0)
        .onChanged { _ in isPressed = true }
        .onEnded { _ in isPressed = false }
)
```

Add `@State private var isPressed = false` to PillView.

- [ ] **Step 4: Build and run**

Run: `make build`
Expected: Compiles successfully

Run: `make run`
Expected: Pill appears at top-center. Tap to expand with spring animation. Content staggers in.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add stagger entrance and pill press feedback"
```

---

### Task 10: Window Resize Animation Sync

**Files:**
- Modify: `DynamicIsland/Sources/DynamicIsland/WindowManager.swift`

- [ ] **Step 1: Add spring-based window resize**

Replace `toggleExpanded` with spring-compatible animation using NSView animation:

```swift
func resize(to height: CGFloat, animated: Bool) {
    guard let window = window, let screen = NSScreen.main?.visibleFrame else { return }
    let width: CGFloat = 340
    let y = screen.maxY - height - 8
    let x = screen.midX - width / 2
    let newFrame = NSRect(x: x, y: y, width: width, height: height)

    if animated {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.23, 1, 0.32, 1)
            window.animator().setFrame(newFrame, display: true)
            window.invalidateShadow()
        }
    } else {
        window.setFrame(newFrame, display: true)
        window.invalidateShadow()
    }
}
```

- [ ] **Step 2: Wire WindowManager into ContentView**

Create a reference from ContentView to WindowManager. Use NotificationCenter or a shared instance.

- [ ] **Step 3: Build and polish**

Run: `make build`
Verify smooth resize syncs with SwiftUI animation.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: sync window resize with spring animation"
```

---

### Task 11: Edge Case — Nothing Playing State

- [ ] **Step 1: Verify PillView already handles empty state**

PillView already shows "No Music Playing" when `isPlaying` is false and trackTitle is empty. Confirm this works visually by launching without any music app active.

- [ ] **Step 2: Handle expanded panel empty state**

Update ContentView to prevent expanding when nothing is playing:

```swift
private var pillView: some View {
    PillView(...)
        .onTapGesture {
            guard !nowPlaying.trackTitle.isEmpty else { return }
            // toggle expand/collapse
        }
}
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat: handle nothing-playing edge case"
```
