import AppKit
import IOKit.hidsystem

let NX_KEYTYPE_PLAY: Int32 = 16
let NX_KEYTYPE_FAST: Int32 = 17
let NX_KEYTYPE_REWIND: Int32 = 15

final class HotkeyManager {
    static let shared = HotkeyManager()
    private let settings = SettingsViewModel.shared

    private var playPauseMonitor: Any?
    private var nextTrackMonitor: Any?
    private var previousTrackMonitor: Any?
    private var toggleIslandMonitor: Any?
    private var localMonitor: Any?
    private var onToggleIsland: (() -> Void)?

    func start(onToggleIsland: @escaping () -> Void) {
        self.onToggleIsland = onToggleIsland

        let playPause = settings.playPauseBinding
        let nextTrack = settings.nextTrackBinding
        let previousTrack = settings.previousTrackBinding
        let toggleIsland = settings.toggleIslandBinding

        if playPause.keyCode != 0 {
            playPauseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self, self.matches(event: event, binding: playPause) else { return }
                self.sendMediaKey(keyCode: NX_KEYTYPE_PLAY)
            }
        }

        if nextTrack.keyCode != 0 {
            nextTrackMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self, self.matches(event: event, binding: nextTrack) else { return }
                self.sendMediaKey(keyCode: NX_KEYTYPE_FAST)
            }
        }

        if previousTrack.keyCode != 0 {
            previousTrackMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self, self.matches(event: event, binding: previousTrack) else { return }
                self.sendMediaKey(keyCode: NX_KEYTYPE_REWIND)
            }
        }

        if toggleIsland.keyCode != 0 {
            toggleIslandMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self, self.matches(event: event, binding: toggleIsland) else { return }
                self.onToggleIsland?()
            }
        }
    }

    func stop() {
        [playPauseMonitor, nextTrackMonitor, previousTrackMonitor, toggleIslandMonitor, localMonitor].compactMap { $0 }.forEach { NSEvent.removeMonitor($0) }
        playPauseMonitor = nil; nextTrackMonitor = nil; previousTrackMonitor = nil; toggleIslandMonitor = nil; localMonitor = nil
    }

    func startRecording(onKeyCaptured: @escaping (HotkeyBinding) -> Void) {
        stop()
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            onKeyCaptured(HotkeyBinding(keyCode: event.keyCode, flags: event.modifierFlags.rawValue))
            return nil
        }
    }

    func stopRecording() {
        if let monitor = localMonitor { NSEvent.removeMonitor(monitor); localMonitor = nil }
        start(onToggleIsland: onToggleIsland ?? {})
    }

    private func matches(event: NSEvent, binding: HotkeyBinding) -> Bool {
        event.keyCode == binding.keyCode && event.modifierFlags.rawValue & binding.flags == binding.flags
    }

    private func sendMediaKey(keyCode: Int32) {
        let down = NSEvent.otherEvent(with: .systemDefined, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil, subtype: 8, data1: Int((keyCode << 16) | (0x0 << 8) | 0xa), data2: -1)
        let up = NSEvent.otherEvent(with: .systemDefined, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil, subtype: 8, data1: Int((keyCode << 16) | (0x0 << 8) | 0xb), data2: -1)
        down?.cgEvent?.post(tap: .cghidEventTap)
        up?.cgEvent?.post(tap: .cghidEventTap)
    }
}
