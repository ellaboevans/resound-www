import SwiftUI

final class SettingsViewModel: ObservableObject {
    static let shared = SettingsViewModel()

    @AppStorage("launchAtLogin") var launchAtLogin = false
    @AppStorage("musicSource") var musicSourceRaw = MusicSource.automatic.rawValue
    @AppStorage("autoHide") var autoHide = true

    @AppStorage("notchWidth") var notchWidth: Double = 340
    @AppStorage("notchPosition") var notchPositionRaw = NotchPosition.center.rawValue
    @AppStorage("waveformStyle") var waveformStyleRaw = WaveformStyle.classic.rawValue

    @AppStorage("playPauseKeyCode") var playPauseKeyCode: Double = 0
    @AppStorage("playPauseFlags") var playPauseFlags: Double = 0
    @AppStorage("nextTrackKeyCode") var nextTrackKeyCode: Double = 0
    @AppStorage("nextTrackFlags") var nextTrackFlags: Double = 0
    @AppStorage("previousTrackKeyCode") var previousTrackKeyCode: Double = 0
    @AppStorage("previousTrackFlags") var previousTrackFlags: Double = 0
    @AppStorage("toggleIslandKeyCode") var toggleIslandKeyCode: Double = 0
    @AppStorage("toggleIslandFlags") var toggleIslandFlags: Double = 0

    var musicSource: MusicSource {
        get { MusicSource(rawValue: musicSourceRaw) ?? .automatic }
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

    var playPauseBinding: HotkeyBinding {
        get { .init(keyCode: UInt16(playPauseKeyCode), flags: UInt(playPauseFlags)) }
        set { playPauseKeyCode = Double(newValue.keyCode); playPauseFlags = Double(newValue.flags) }
    }

    var nextTrackBinding: HotkeyBinding {
        get { .init(keyCode: UInt16(nextTrackKeyCode), flags: UInt(nextTrackFlags)) }
        set { nextTrackKeyCode = Double(newValue.keyCode); nextTrackFlags = Double(newValue.flags) }
    }

    var previousTrackBinding: HotkeyBinding {
        get { .init(keyCode: UInt16(previousTrackKeyCode), flags: UInt(previousTrackFlags)) }
        set { previousTrackKeyCode = Double(newValue.keyCode); previousTrackFlags = Double(newValue.flags) }
    }

    var toggleIslandBinding: HotkeyBinding {
        get { .init(keyCode: UInt16(toggleIslandKeyCode), flags: UInt(toggleIslandFlags)) }
        set { toggleIslandKeyCode = Double(newValue.keyCode); toggleIslandFlags = Double(newValue.flags) }
    }
}
