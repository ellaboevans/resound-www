# Settings Panel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a hybrid settings system — menu bar dropdown with quick controls, plus a full preferences window with General/Appearance/Hotkeys tabs.

**Architecture:** MenuBarManager owns an NSStatusItem + custom dropdown view. SettingsViewModel uses @AppStorage for persistence and is shared across the app via an environment object or singleton. Preferences window is a SwiftUI TabView. Hotkeys use global NSEvent monitors with stored key codes.

**Tech Stack:** SwiftUI, AppKit (NSStatusItem), UserDefaults (@AppStorage), Combine

---

### Task 1: SettingsViewModel + WaveformStyle + Models

**Files:**
- Create: `Sources/DynamicIsland/ViewModels/SettingsViewModel.swift`
- Create: `Sources/DynamicIsland/Models/WaveformStyle.swift`
- Create: `Sources/DynamicIsland/Models/MusicSource.swift`
- Create: `Sources/DynamicIsland/Models/NotchPosition.swift`

- [ ] **Step 1: Create MusicSource enum**

```swift
// Sources/DynamicIsland/Models/MusicSource.swift
import Foundation

enum MusicSource: String, CaseIterable, Codable {
    case spotify = "Spotify"
    case appleMusic = "Apple Music"
    case both = "Both"
}
```

- [ ] **Step 2: Create NotchPosition enum**

```swift
// Sources/DynamicIsland/Models/NotchPosition.swift
import Foundation

enum NotchPosition: String, CaseIterable, Codable {
    case left
    case center
    case right

    var label: String { rawValue.capitalized }

    var alignment: Alignment {
        switch self {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        }
    }
}
```

- [ ] **Step 3: Create WaveformStyle enum with preview support**

```swift
// Sources/DynamicIsland/Models/WaveformStyle.swift
import SwiftUI

enum WaveformStyle: String, CaseIterable, Codable {
    case classic
    case pulse
    case equalizer
    case minimal

    var label: String {
        switch self {
        case .classic: return "Classic"
        case .pulse: return "Pulse"
        case .equalizer: return "Equalizer"
        case .minimal: return "Minimal"
        }
    }
}
```

- [ ] **Step 4: Create SettingsViewModel**

```swift
// Sources/DynamicIsland/ViewModels/SettingsViewModel.swift
import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    static let shared = SettingsViewModel()

    @AppStorage("musicSource") var musicSourceRaw: String = MusicSource.both.rawValue
    @AppStorage("notchWidth") var notchWidth: Double = 340
    @AppStorage("notchPosition") var notchPositionRaw: String = NotchPosition.center.rawValue
    @AppStorage("waveformStyle") var waveformStyleRaw: String = WaveformStyle.classic.rawValue
    @AppStorage("autoHideWhenIdle") var autoHideWhenIdle: Bool = false
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
    @AppStorage("hotkeyPlayPause") var hotkeyPlayPauseData: Data = Data()
    @AppStorage("hotkeyNext") var hotkeyNextData: Data = Data()
    @AppStorage("hotkeyPrevious") var hotkeyPreviousData: Data = Data()
    @AppStorage("hotkeyToggle") var hotkeyToggleData: Data = Data()

    var musicSource: MusicSource {
        get { MusicSource(rawValue: musicSourceRaw) ?? .both }
        set { musicSourceRaw = newValue.rawValue }
    }

    var notchPosition: NotchPosition {
        get { NotchPosition(rawValue: notchPositionRaw) ?? .center }
        set { notchPositionRaw = newValue.rawValue }
    }

    var waveformStyle: WaveformStyle {
        get { WaveformStyle(rawValue: waveformStyleRaw) ?? .classic }
        set { waveformStyleRaw = newValue.rawValue }
    }

    let objectWillChange = PassthroughSubject<Void, Never>()

    private init() {
        UserDefaults.standard.register(defaults: [
            "musicSource": MusicSource.both.rawValue,
            "notchWidth": 340.0,
            "notchPosition": NotchPosition.center.rawValue,
            "waveformStyle": WaveformStyle.classic.rawValue,
            "autoHideWhenIdle": false,
            "launchAtLogin": false,
            "hotkeyPlayPause": Data(),
            "hotkeyNext": Data(),
            "hotkeyPrevious": Data(),
            "hotkeyToggle": Data(),
        ])
    }
}
```

- [ ] **Step 5: Build to verify**

Run: `swift build 2>&1`
Expected: Build succeeds

---

### Task 2: Waveform Animation Views

**Files:**
- Modify: `Sources/DynamicIsland/Views/PillView.swift`

- [ ] **Step 1: Replace waveform with style-switchable implementation**

Replace the `waveform` and `barHeight` in PillView with:

```swift
    @ViewBuilder
    private var waveform: some View {
        switch SettingsViewModel.shared.waveformStyle {
        case .classic:
            classicWaveform
        case .pulse:
            pulseWaveform
        case .equalizer:
            equalizerWaveform
        case .minimal:
            minimalWaveform
        }
    }

    @ViewBuilder
    private var classicWaveform: some View {
        PhaseAnimator([0, 1, 2, 1]) { phase in
            HStack(spacing: 3) {
                capsuleBar(height: 12 + barHeight(index: 0, phase: phase))
                capsuleBar(height: 12 + barHeight(index: 1, phase: phase))
                capsuleBar(height: 12 + barHeight(index: 2, phase: phase))
            }
        } animation: { _ in
            .easeInOut(duration: 0.6)
        }
    }

    @ViewBuilder
    private var pulseWaveform: some View {
        PhaseAnimator([0, 1, 0]) { phase in
            Circle()
                .fill(.white)
                .frame(width: 8 + CGFloat(phase) * 6, height: 8 + CGFloat(phase) * 6)
                .opacity(0.6 - Double(phase) * 0.15)
        } animation: { _ in
            .easeInOut(duration: 0.8)
        }
    }

    @ViewBuilder
    private var equalizerWaveform: some View {
        PhaseAnimator([0, 1, 2, 3, 2, 1]) { phase in
            HStack(spacing: 2) {
                capsuleBar(height: 8 + equalizerHeight(index: 0, phase: phase))
                capsuleBar(height: 8 + equalizerHeight(index: 1, phase: phase))
                capsuleBar(height: 8 + equalizerHeight(index: 2, phase: phase))
                capsuleBar(height: 8 + equalizerHeight(index: 3, phase: phase))
                capsuleBar(height: 8 + equalizerHeight(index: 4, phase: phase))
            }
        } animation: { _ in
            .easeInOut(duration: 0.4)
        }
    }

    @ViewBuilder
    private var minimalWaveform: some View {
        PhaseAnimator([0, 1, 0]) { phase in
            Capsule()
                .fill(.white)
                .frame(width: 4, height: 14 + CGFloat(phase) * 4)
                .opacity(0.5 + Double(phase) * 0.2)
        } animation: { _ in
            .easeInOut(duration: 1.0)
        }
    }

    private func capsuleBar(height: CGFloat) -> some View {
        Capsule()
            .fill(.white)
            .frame(width: 3, height: height)
    }

    private func equalizerHeight(index: Int, phase: Int) -> CGFloat {
        let heights: [[CGFloat]] = [
            [0, 4, 6, 2, 0],
            [4, 0, 2, 6, 4],
            [6, 2, 0, 4, 6],
            [2, 6, 4, 0, 2],
            [0, 4, 2, 6, 0],
            [4, 0, 6, 2, 4],
        ]
        return heights[phase % heights.count][index % 5]
    }
```

Also add `import Combine` and `import SwiftUI` at top of file (SwiftUI already imported).

- [ ] **Step 2: Add waveform preview views for the Appearance tab**

Add at the bottom of PillView.swift (outside the struct):

```swift
struct WaveformPreview: View {
    let style: WaveformStyle

    var body: some View {
        PillView(trackTitle: "", isPlaying: true, artworkImage: nil, isExpanded: false)
            .frame(width: 100, height: 38)
            .background(
                UnevenRoundedRectangle(
                    cornerRadii: .init(bottomLeading: 8, bottomTrailing: 8),
                    style: .continuous
                )
                .fill(.black)
            )
            .clipShape(
                UnevenRoundedRectangle(
                    cornerRadii: .init(bottomLeading: 8, bottomTrailing: 8),
                    style: .continuous
                )
            )
            .scaleEffect(0.8)
    }
}
```

- [ ] **Step 3: Build to verify**

Run: `swift build 2>&1`
Expected: Build succeeds

---

### Task 3: MenuBarManager — Status Item + Dropdown

**Files:**
- Create: `Sources/DynamicIsland/Managers/MenuBarManager.swift`

- [ ] **Step 1: Create MenuBarManager with NSStatusItem**

```swift
// Sources/DynamicIsland/Managers/MenuBarManager.swift
import AppKit
import SwiftUI

@MainActor
final class MenuBarManager {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private let settingsVM = SettingsViewModel.shared
    private let nowPlayingVM: NowPlayingViewModel

    init(nowPlayingVM: NowPlayingViewModel) {
        self.nowPlayingVM = nowPlayingVM
        setupStatusItem()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "⏺"
        item.button?.font = NSFont.systemFont(ofSize: 14)
        item.button?.action = #selector(toggleDropdown)
        item.button?.target = self
        statusItem = item
    }

    @objc private func toggleDropdown() {
        guard let button = statusItem?.button else { return }
        if popover?.isShown == true {
            popover?.close()
            popover = nil
            return
        }
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 260, height: 300)
        popover.contentViewController = NSHostingController(
            rootView: DropdownView(
                nowPlayingVM: nowPlayingVM,
                onOpenSettings: { [weak self] in
                    self?.popover?.close()
                    self?.popover = nil
                    self?.openSettings()
                },
                onQuit: { NSApp.terminate(nil) }
            )
        )
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        self.popover = popover
    }

    private func openSettings() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Dynamic Island Settings"
        window.contentView = NSHostingView(rootView: SettingsView())
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

private struct DropdownView: View {
    @ObservedObject var nowPlayingVM: NowPlayingViewModel
    @ObservedObject private var settingsVM = SettingsViewModel.shared
    let onOpenSettings: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if nowPlayingVM.trackTitle.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "music.note")
                        .font(.title2)
                        .opacity(0.3)
                    Text("No Music Playing")
                        .font(.system(size: 12))
                        .opacity(0.4)
                }
                .padding(.top, 8)
            } else {
                VStack(spacing: 2) {
                    Text(nowPlayingVM.trackTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    Text("\(nowPlayingVM.artistName) — \(nowPlayingVM.albumTitle)")
                        .font(.system(size: 10))
                        .opacity(0.5)
                        .lineLimit(1)
                }
                .padding(.top, 8)
            }

            HStack(spacing: 20) {
                controlButton("backward.fill") { nowPlayingVM.previousTrack() }
                controlButton(nowPlayingVM.isPlaying ? "pause.fill" : "play.fill") { nowPlayingVM.playPause() }
                    .font(.system(size: 18))
                controlButton("forward.fill") { nowPlayingVM.nextTrack() }
            }

            Picker("Waveform", selection: Binding(
                get: { settingsVM.waveformStyle },
                set: { settingsVM.waveformStyle = $0 }
            )) {
                ForEach(WaveformStyle.allCases, id: \.self) { style in
                    Text(style.label).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Picker("Source", selection: Binding(
                get: { settingsVM.musicSource },
                set: { settingsVM.musicSource = $0 }
            )) {
                ForEach(MusicSource.allCases, id: \.self) { source in
                    Text(source.rawValue).tag(source)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            Button("Settings...", action: onOpenSettings)
                .font(.system(size: 12))
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("Quit", action: onQuit)
                .font(.system(size: 12))
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(width: 260)
    }

    private func controlButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14))
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `swift build 2>&1`
Expected: Build succeeds

---

### Task 4: Settings Window — General Tab

**Files:**
- Create: `Sources/DynamicIsland/Views/Settings/SettingsView.swift`
- Create: `Sources/DynamicIsland/Views/Settings/SettingsGeneralView.swift`

- [ ] **Step 1: Create SettingsView container**

```swift
// Sources/DynamicIsland/Views/Settings/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settingsVM = SettingsViewModel.shared

    var body: some View {
        TabView {
            SettingsGeneralView()
                .tabItem { Label("General", systemImage: "gearshape") }

            SettingsAppearanceView()
                .tabItem { Label("Appearance", systemImage: "paintbrush") }

            SettingsHotkeysView()
                .tabItem { Label("Hotkeys", systemImage: "keyboard") }
        }
        .frame(width: 500, height: 380)
    }
}
```

- [ ] **Step 2: Create SettingsGeneralView**

```swift
// Sources/DynamicIsland/Views/Settings/SettingsGeneralView.swift
import SwiftUI
import ServiceManagement

struct SettingsGeneralView: View {
    @ObservedObject private var settingsVM = SettingsViewModel.shared

    var body: some View {
        Form {
            Section {
                Picker("Music Source", selection: Binding(
                    get: { settingsVM.musicSource },
                    set: { settingsVM.musicSource = $0 }
                )) {
                    ForEach(MusicSource.allCases, id: \.self) { source in
                        Text(source.rawValue).tag(source)
                    }
                }

                Toggle("Launch at login", isOn: Binding(
                    get: { settingsVM.launchAtLogin },
                    set: { newValue in
                        settingsVM.launchAtLogin = newValue
                        applyLaunchAtLogin(newValue)
                    }
                ))

                Toggle("Auto-hide when idle", isOn: $settingsVM.autoHideWhenIdle)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func applyLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            try? SMAppService.mainApp.register()
            if !enabled {
                try? SMAppService.mainApp.unregister()
            }
        }
    }
}
```

- [ ] **Step 3: Build to verify**

Run: `swift build 2>&1`
Expected: Build succeeds

---

### Task 5: Settings Window — Appearance Tab

**Files:**
- Create: `Sources/DynamicIsland/Views/Settings/SettingsAppearanceView.swift`

- [ ] **Step 1: Create SettingsAppearanceView**

```swift
// Sources/DynamicIsland/Views/Settings/SettingsAppearanceView.swift
import SwiftUI

struct SettingsAppearanceView: View {
    @ObservedObject private var settingsVM = SettingsViewModel.shared

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Width: \(Int(settingsVM.notchWidth))pt")
                        .font(.system(size: 12, weight: .medium))
                    Slider(value: $settingsVM.notchWidth, in: 200...400, step: 10)
                }

                Picker("Position", selection: Binding(
                    get: { settingsVM.notchPosition },
                    set: { settingsVM.notchPosition = $0 }
                )) {
                    ForEach(NotchPosition.allCases, id: \.self) { pos in
                        Text(pos.label).tag(pos)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                Text("Waveform Style")
                    .font(.system(size: 12, weight: .medium))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                    ForEach(WaveformStyle.allCases, id: \.self) { style in
                        waveformCard(style)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func waveformCard(_ style: WaveformStyle) -> some View {
        VStack(spacing: 6) {
            WaveformPreview(style: style)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.05))
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(settingsVM.waveformStyle == style ? Color.accentColor : Color.clear, lineWidth: 2)
                )

            Text(style.label)
                .font(.system(size: 11))
        }
        .onTapGesture {
            settingsVM.waveformStyle = style
        }
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `swift build 2>&1`
Expected: Build succeeds

---

### Task 6: Settings Window — Hotkeys Tab

**Files:**
- Create: `Sources/DynamicIsland/Views/Settings/SettingsHotkeysView.swift`
- Create: `Sources/DynamicIsland/Models/HotkeyBinding.swift`
- Create: `Sources/DynamicIsland/Managers/HotkeyManager.swift`

- [ ] **Step 1: Create HotkeyBinding model**

```swift
// Sources/DynamicIsland/Models/HotkeyBinding.swift
import AppKit

struct HotkeyBinding: Codable, Equatable {
    var keyCode: UInt16
    var modifierFlags: UInt

    static let empty = HotkeyBinding(keyCode: 0, modifierFlags: 0)

    var isSet: Bool { keyCode != 0 }

    var displayString: String {
        guard isSet else { return "Not set" }
        var parts: [String] = []
        if modifierFlags & NSEvent.ModifierFlags.command.rawValue != 0 { parts.append("⌘") }
        if modifierFlags & NSEvent.ModifierFlags.option.rawValue != 0 { parts.append("⌥") }
        if modifierFlags & NSEvent.ModifierFlags.shift.rawValue != 0 { parts.append("⇧") }
        if modifierFlags & NSEvent.ModifierFlags.control.rawValue != 0 { parts.append("⌃") }
        if let chars = keyToString(keyCode) { parts.append(chars) }
        return parts.joined()
    }
}

private func keyToString(_ keyCode: UInt16) -> String? {
    let mapping: [UInt16: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
        8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
        16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
        23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
        30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "Return",
        37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",",
        44: "/", 45: "N", 46: "M", 47: ".", 48: "Tab", 49: "Space",
        50: "`", 51: "⌫", 53: "⎋", 123: "←", 124: "→", 125: "↓", 126: "↑",
    ]
    return mapping[keyCode]
}
```

- [ ] **Step 2: Create HotkeyManager**

```swift
// Sources/DynamicIsland/Managers/HotkeyManager.swift
import AppKit
import Combine

@MainActor
final class HotkeyManager {
    static let shared = HotkeyManager()
    private var monitors: [Any] = []
    private let settingsVM = SettingsViewModel.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    func start() {
        // Re-register when settings change
        settingsVM.objectWillChange
            .sink { [weak self] _ in self?.registerAll() }
            .store(in: &cancellables)
        registerAll()
    }

    func stop() {
        monitors.forEach { NSEvent.removeMonitor($0) }
        monitors.removeAll()
    }

    private struct RegisteredHotkey {
        let binding: HotkeyBinding
        let action: () -> Void
    }

    private var registered: [RegisteredHotkey] = []
    private var globalMonitor: Any?

    func start() {
        settingsVM.objectWillChange
            .sink { [weak self] _ in self?.registerAll() }
            .store(in: &cancellables)
        registerAll()

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.handleKeyEvent(event)
        }
    }

    func stop() {
        monitors.forEach { NSEvent.removeMonitor($0) }
        monitors.removeAll()
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
    }

    private func registerAll() {
        registered.removeAll()
        register(binding: decodeHotkey(settingsVM.hotkeyPlayPauseData)) { [weak self] in self?.notify("playPause") }
        register(binding: decodeHotkey(settingsVM.hotkeyNextData)) { [weak self] in self?.notify("next") }
        register(binding: decodeHotkey(settingsVM.hotkeyPreviousData)) { [weak self] in self?.notify("previous") }
        register(binding: decodeHotkey(settingsVM.hotkeyToggleData)) { [weak self] in self?.notify("toggle") }
    }

    private func register(binding: HotkeyBinding, action: @escaping () -> Void) {
        guard binding.isSet else { return }
        registered.append(RegisteredHotkey(binding: binding, action: action))
    }

    private func handleKeyEvent(_ event: NSEvent) {
        let modifiers = event.modifierFlags.intersection([.command, .option, .shift, .control]).rawValue
        for hotkey in registered {
            if event.keyCode == hotkey.binding.keyCode && modifiers == hotkey.binding.modifierFlags {
                hotkey.action()
                return
            }
        }
    }

    private func notify(_ id: String) {
        NotificationCenter.default.post(name: NSNotification.Name("Hotkey\(id)"), object: nil)
    }
}

private func decodeHotkey(_ data: Data) -> HotkeyBinding {
    (try? JSONDecoder().decode(HotkeyBinding.self, from: data)) ?? .empty
}
```

- [ ] **Step 3: Create SettingsHotkeysView**

```swift
// Sources/DynamicIsland/Views/Settings/SettingsHotkeysView.swift
import SwiftUI

struct SettingsHotkeysView: View {
    @ObservedObject private var settingsVM = SettingsViewModel.shared

    var body: some View {
        VStack(spacing: 16) {
            hotkeyRow(label: "Play/Pause", data: $settingsVM.hotkeyPlayPauseData)
            hotkeyRow(label: "Next Track", data: $settingsVM.hotkeyNextData)
            hotkeyRow(label: "Previous Track", data: $settingsVM.hotkeyPreviousData)
            hotkeyRow(label: "Toggle Island", data: $settingsVM.hotkeyToggleData)

            Spacer()

            Button("Restore Defaults") {
                settingsVM.hotkeyPlayPauseData = Data()
                settingsVM.hotkeyNextData = Data()
                settingsVM.hotkeyPreviousData = Data()
                settingsVM.hotkeyToggleData = Data()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func hotkeyRow(label: String, data: Binding<Data>) -> some View {
        let binding = HotkeyBindingView.DataBinding(
            get: { (try? JSONDecoder().decode(HotkeyBinding.self, from: data.wrappedValue)) ?? .empty },
            set: { data.wrappedValue = (try? JSONEncoder().encode($0)) ?? Data() }
        )
        return HStack {
            Text(label)
                .frame(width: 120, alignment: .leading)
            HotkeyBindingView(binding: binding)
        }
    }
}

private struct HotkeyBindingView: View {
    struct DataBinding {
        let get: () -> HotkeyBinding
        let set: (HotkeyBinding) -> Void
    }

    let binding: DataBinding
    @State private var isRecording = false
    @State private var displayText = "Not set"

    var body: some View {
        HStack {
            if isRecording {
                Text("Press keys...")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 12))
            } else {
                Text(displayText)
                    .font(.system(size: 12, design: .monospaced))
                    .opacity(binding.get().isSet ? 1 : 0.4)
            }

            Button(isRecording ? "Cancel" : "Record") {
                isRecording.toggle()
                if isRecording { startRecording() }
            }
            .font(.system(size: 11))

            Button("Clear") {
                binding.set(.empty)
                displayText = "Not set"
            }
            .font(.system(size: 11))
            .disabled(!binding.get().isSet)
        }
        .onAppear { displayText = binding.get().displayString }
    }

    private func startRecording() {
        var localMonitor: Any?
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [self] event in
            guard isRecording else { return event }
            let binding = HotkeyBinding(
                keyCode: event.keyCode,
                modifierFlags: event.modifierFlags.intersection([.command, .option, .shift, .control]).rawValue
            )
            self.binding.set(binding)
            displayText = binding.displayString
            isRecording = false
            if let monitor = localMonitor {
                NSEvent.removeMonitor(monitor)
            }
            return nil
        }
    }
}
```

- [ ] **Step 4: Build to verify**

Run: `swift build 2>&1`
Expected: Build succeeds

---

### Task 7: Integration — Wire Everything Together

**Files:**
- Modify: `Sources/DynamicIsland/DynamicIslandApp.swift`
- Modify: `Sources/DynamicIsland/Managers/WindowManager.swift`
- Modify: `Sources/DynamicIsland/Services/NowPlayingService.swift`

- [ ] **Step 1: Wire MenuBarManager into app entry point**

Replace `DynamicIslandApp.swift`:

```swift
// Sources/DynamicIsland/DynamicIslandApp.swift
import SwiftUI

@main
struct DynamicIslandApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
```

- [ ] **Step 2: Update AppDelegate to instantiate MenuBarManager**

Replace `AppDelegate.swift`:

```swift
// Sources/DynamicIsland/AppDelegate.swift
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowManager: WindowManager?
    private var menuBarManager: MenuBarManager?
    private let nowPlayingVM = NowPlayingViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        windowManager = WindowManager(nowPlayingVM: nowPlayingVM)
        windowManager?.show()

        menuBarManager = MenuBarManager(nowPlayingVM: nowPlayingVM)

        nowPlayingVM.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        nowPlayingVM.stop()
    }
}
```

- [ ] **Step 3: Update WindowManager to accept ViewModel and observe settings**

Replace `WindowManager.swift`:

```swift
// Sources/DynamicIsland/Managers/WindowManager.swift
import Cocoa
import SwiftUI
import Combine

final class WindowManager {
    private var window: NSWindow?
    private let collapsedHeight: CGFloat = 38
    private let expandedHeight: CGFloat = 192
    private let nowPlayingVM: NowPlayingViewModel
    private let settingsVM = SettingsViewModel.shared
    private var cancellables = Set<AnyCancellable>()

    init(nowPlayingVM: NowPlayingViewModel) {
        self.nowPlayingVM = nowPlayingVM
    }

    func show() {
        let contentView = ContentView(
            onToggle: { [weak self] expanded in
                if expanded {
                    self?.expand()
                } else {
                    self?.collapse()
                }
            },
            nowPlayingVM: nowPlayingVM
        )

        let hostingView = NSHostingView(rootView: contentView)

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

        positionWindow(window, width: CGFloat(settingsVM.notchWidth))
        window.makeKeyAndOrderFront(nil)
        self.window = window

        settingsVM.objectWillChange
            .sink { [weak self] in
                self?.repositionWindow()
            }
            .store(in: &cancellables)
    }

    deinit {
        window?.close()
    }

    private func positionWindow(_ window: NSWindow, width: CGFloat) {
        guard let screen = NSScreen.main else { return }
        let y = screen.frame.maxY - collapsedHeight
        let x = screen.frame.midX - width / 2
        window.setFrame(NSRect(x: x, y: y, width: width, height: collapsedHeight), display: true)
        window.invalidateShadow()
    }

    private func repositionWindow() {
        guard let window = window else { return }
        let width = CGFloat(settingsVM.notchWidth)
        let x: CGFloat
        if let screen = NSScreen.main {
            switch settingsVM.notchPosition {
            case .left: x = screen.frame.minX + 20
            case .center: x = screen.frame.midX - width / 2
            case .right: x = screen.frame.maxX - width - 20
            }
        } else {
            x = 0
        }
        let currentHeight = window.frame.height
        window.setFrame(NSRect(x: x, y: screen?.frame.maxY ?? 0 - currentHeight, width: width, height: currentHeight), display: true)
        window.invalidateShadow()
    }

    private func expand() {
        guard let window = window, let screen = NSScreen.main else { return }
        let width = CGFloat(settingsVM.notchWidth)
        let y = screen.frame.maxY - expandedHeight
        let x: CGFloat
        switch settingsVM.notchPosition {
        case .left: x = screen.frame.minX + 20
        case .center: x = screen.frame.midX - width / 2
        case .right: x = screen.frame.maxX - width - 20
        }
        window.setFrame(NSRect(x: x, y: y, width: width, height: expandedHeight), display: true)
        window.invalidateShadow()
    }

    private func collapse() {
        guard let window = window, let screen = NSScreen.main else { return }
        let width = CGFloat(settingsVM.notchWidth)
        let y = screen.frame.maxY - collapsedHeight
        let x: CGFloat
        switch settingsVM.notchPosition {
        case .left: x = screen.frame.minX + 20
        case .center: x = screen.frame.midX - width / 2
        case .right: x = screen.frame.maxX - width - 20
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            window.setFrame(NSRect(x: x, y: y, width: width, height: self.collapsedHeight), display: true)
            window.invalidateShadow()
        }
    }
}
```

- [ ] **Step 4: Update ContentView to accept nowPlayingVM directly**

Replace ContentView.swift — change the `@StateObject private var nowPlaying` to accept it as a parameter:

```swift
// ContentView.swift changes:
// - Remove @StateObject private var nowPlaying = NowPlayingViewModel()
// - Add let nowPlayingVM: NowPlayingViewModel
// - Replace all nowPlaying references with nowPlayingVM
// - Update the init signature
```

The full updated ContentView:

```swift
import SwiftUI

struct ContentView: View {
    let onToggle: (Bool) -> Void
    let nowPlayingVM: NowPlayingViewModel
    @State private var isExpanded = false
    @ObservedObject private var settingsVM = SettingsViewModel.shared

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: -6) {
                pillView
                expandedPanel
                    .offset(y: isExpanded ? 0 : 151)
                    .opacity(isExpanded ? 1 : 0)
                    .animation(.spring(response: 0.25, dampingFraction: 1), value: isExpanded)
            }
            .frame(width: 340, height: 189)
        }
        .frame(width: 340, height: isExpanded ? 189 : 38, alignment: .top)
        .clipped()
        .background(
            UnevenRoundedRectangle(
                cornerRadii: .init(
                    bottomLeading: 14,
                    bottomTrailing: 14
                ),
                style: .continuous
            )
            .fill(.black)
        )
        .onHover { hovering in
            guard !nowPlayingVM.trackTitle.isEmpty else { return }
            isExpanded = hovering
            onToggle(hovering)
        }
        .onAppear { nowPlayingVM.start() }
        .onDisappear { nowPlayingVM.stop() }
    }

    private var pillView: some View {
        PillView(
            trackTitle: nowPlayingVM.trackTitle,
            isPlaying: nowPlayingVM.isPlaying,
            artworkImage: nowPlayingVM.artworkImage,
            isExpanded: isExpanded
        )
        .transaction { t in
            t.disablesAnimations = true
        }
    }

    private var expandedPanel: some View {
        ExpandedPanel {
            MusicSection(
                trackTitle: nowPlayingVM.trackTitle,
                artistName: nowPlayingVM.artistName,
                albumTitle: nowPlayingVM.albumTitle,
                artworkImage: nowPlayingVM.artworkImage,
                progress: nowPlayingVM.progress,
                elapsedText: nowPlayingVM.formattedElapsed,
                remainingText: nowPlayingVM.formattedRemaining,
                isPlaying: nowPlayingVM.isPlaying,
                onPlayPause: { nowPlayingVM.playPause() },
                onNext: { nowPlayingVM.nextTrack() },
                onPrevious: { nowPlayingVM.previousTrack() }
            )
        }
    }
}
```

- [ ] **Step 5: Update NowPlayingService to respect music source**

Add source filtering at the start of the AppleScript. Update `fetchNowPlaying()`:

Replace the AppleScript in `fetchNowPlaying()` to conditionally check Spotify or Music based on settings. The script stays mostly the same but we can skip checking one or the other.

```swift
    private func fetchNowPlaying() -> (NowPlayingInfo?, spotifyUri: String?) {
        let source = SettingsViewModel.shared.musicSource
        let checkSpotify = source == .spotify || source == .both
        let checkMusic = source == .appleMusic || source == .both

        let script = """
        set output to ""
        tell application "System Events"
        """ +
        (checkSpotify ? """
            if exists (process "Spotify") then
                tell application "Spotify"
                    if player state is playing or player state is paused then
                        if player state is playing then
                            set stateStr to "playing"
                        else
                            set stateStr to "paused"
                        end if
                        set output to (name of current track) & "|||" & (artist of current track) & "|||" & (album of current track) & "|||" & (duration of current track) & "|||" & (player position) & "|||" & stateStr & "|||" & (spotify url of current track)
                    end if
                end tell
            end if
        """ : "") +
        (checkMusic ? """
            if output is "" and exists (process "Music") then
                tell application "Music"
                    if player state is playing then
                        set output to (name of current track) & "|||" & (artist of current track) & "|||" & (album of current track) & "|||" & (duration of current track) & "|||" & (player position) & "|||playing"
                    else if player state is paused then
                        set output to (name of current track) & "|||" & (artist of current track) & "|||" & (album of current track) & "|||" & (duration of current track) & "|||" & (player position) & "|||paused"
                    end if
                end tell
            end if
        """ : "") + """
        end tell
        return output
        """

        // ... rest of the method stays the same
    }
```

Also add `import Combine` at top of the file for settings observation.

- [ ] **Step 6: Build to verify**

Run: `swift build 2>&1`
Expected: Build succeeds

---

### Task 8: Final Polish and Test

**Files:**
- Full project

- [ ] **Step 1: Make sure the directory structure is clean**

```bash
mkdir -p Sources/DynamicIsland/Views/Settings
mkdir -p Sources/DynamicIsland/Models
mkdir -p Sources/DynamicIsland/Managers
```

- [ ] **Step 2: Full build**

Run: `swift build 2>&1`
Expected: Build succeeds with no errors

- [ ] **Step 3: Run the app**

Run: `make run`
Expected: App launches, menu bar icon shows, click to see dropdown, Settings... opens preferences window
