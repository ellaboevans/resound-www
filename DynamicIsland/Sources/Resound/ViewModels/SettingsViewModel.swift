import SwiftUI
import ServiceManagement

final class SettingsViewModel: ObservableObject {
    static let shared = SettingsViewModel()

    @AppStorage("launchAtLogin") var launchAtLogin = false {
        didSet { applyLaunchAtLogin() }
    }
    @AppStorage("musicSource") var musicSourceRaw = MusicSource.automatic.rawValue
    @AppStorage("autoHide") var autoHide = true

    @AppStorage("notchWidth") var notchWidth: Double = 340
    @AppStorage("notchPosition") var notchPositionRaw = NotchPosition.center.rawValue
    @AppStorage("waveformStyle") var waveformStyleRaw = WaveformStyle.classic.rawValue

    @AppStorage("displayMode") var displayModeRaw = DisplayMode.allScreens.rawValue
    @AppStorage("selectedScreen") private var selectedScreenNameRaw = ""

    init() {
        syncLaunchAtLogin()
    }

    private func syncLaunchAtLogin() {
        if #available(macOS 13, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func applyLaunchAtLogin() {
        guard #available(macOS 13, *) else { return }
        do {
            if launchAtLogin {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            print("[Settings] launch at login error: \(error)")
        }
    }

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

    var displayMode: DisplayMode {
        get { DisplayMode(rawValue: displayModeRaw) ?? .allScreens }
        set {
            displayModeRaw = newValue.rawValue
            if newValue == .singleScreen && selectedScreenNameRaw.isEmpty {
                selectedScreenNameRaw = NSScreen.main?.localizedName ?? ""
            }
        }
    }

    var selectedScreenName: String {
        get {
            if selectedScreenNameRaw.isEmpty {
                return NSScreen.main?.localizedName ?? ""
            }
            return selectedScreenNameRaw
        }
        set { selectedScreenNameRaw = newValue }
    }
}
