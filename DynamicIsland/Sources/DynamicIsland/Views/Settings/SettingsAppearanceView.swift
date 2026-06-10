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

            Section {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))]) {
                    ForEach(WaveformStyle.allCases, id: \.self) { style in
                        VStack {
                            WaveformPreview(style: style, isPlaying: true)
                                .frame(height: 28)
                            Text(style.rawValue)
                                .font(.caption2)
                        }
                        .padding(6)
                        .background(settings.waveformStyle == style ? Color.accentColor.opacity(0.2) : Color.clear)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(settings.waveformStyle == style ? Color.accentColor : Color.clear, lineWidth: 1)
                        )
                        .onTapGesture { settings.waveformStyle = style }
                    }
                }
            } header: { Text("Waveform Style") }
        }
        .formStyle(.grouped)
    }
}
