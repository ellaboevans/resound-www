import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            SettingsGeneralView()
                .tabItem { Label("General", systemImage: "gearshape") }
            SettingsAppearanceView()
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
            SettingsHotkeysView()
                .tabItem { Label("Hotkeys", systemImage: "keyboard") }
        }
        .frame(width: 420, height: 320)
    }
}
