import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            SettingsGeneralView()
                .tabItem { Label("General", systemImage: "gearshape") }
            SettingsAppearanceView()
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
        }
        .frame(width: 420, height: 320)
    }
}
