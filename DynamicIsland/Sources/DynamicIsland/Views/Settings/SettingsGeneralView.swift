import SwiftUI

struct SettingsGeneralView: View {
    @ObservedObject var settings = SettingsViewModel.shared

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
                Picker("Music source", selection: Binding(
                    get: { settings.musicSource },
                    set: { settings.musicSource = $0 }
                )) {
                    ForEach(MusicSource.allCases, id: \.self) { source in
                        Text(source.rawValue).tag(source)
                    }
                }
                Toggle("Auto-hide island", isOn: $settings.autoHide)
            }
        }
        .formStyle(.grouped)
    }
}
