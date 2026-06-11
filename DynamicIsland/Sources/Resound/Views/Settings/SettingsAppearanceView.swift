import SwiftUI

struct SettingsAppearanceView: View {
    @ObservedObject var settings = SettingsViewModel.shared

    var body: some View {
        Form {
            Section {
                VStack {
                    Slider(value: $settings.notchWidth, in: 200...400, step: 5)
                    Text("\(Int(settings.notchWidth))pt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: { Text("Notch Width") }

            Picker("Position", selection: Binding(
                get: { settings.notchPosition },
                set: { settings.notchPosition = $0 }
            )) {
                ForEach(NotchPosition.allCases, id: \.self) { pos in
                    Text(pos.rawValue).tag(pos)
                }
            }

            Picker("Display", selection: Binding(
                get: { settings.displayMode },
                set: { settings.displayMode = $0 }
            )) {
                ForEach(DisplayMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }

            if settings.displayMode == .singleScreen {
                let screens = NSScreen.screens
                Picker("Screen", selection: $settings.selectedScreenName) {
                    ForEach(0..<screens.count, id: \.self) { i in
                        Text(screens[i].localizedName).tag(screens[i].localizedName)
                    }
                }
            }

            Section {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                    ForEach(WaveformStyle.allCases, id: \.self) { style in
                        VStack(spacing: 6) {
WaveformPreview(style: style, isPlaying: true, animated: false)
    .frame(height: 32)
                            Text(style.rawValue)
                                .font(.caption)
                        }
                        .padding(12)
                        .frame(minHeight: 72)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(settings.waveformStyle == style ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(settings.waveformStyle == style ? Color.accentColor : Color.gray.opacity(0.25), lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { settings.waveformStyle = style }
                    }
                }
            } header: { Text("Waveform Style") }
        }
        .formStyle(.grouped)
    }
}
