import SwiftUI

struct VolumeSlider: View {
    let volume: Int
    let onSetVolume: (Int) -> Void

    @State private var localVolume: Int = 50
    @State private var isDragging: Bool = false

    private var iconName: String {
        switch localVolume {
        case 0: "speaker.slash.fill"
        case 1..<35: "speaker.fill"
        case 35..<70: "speaker.wave.1.fill"
        default: "speaker.wave.3.fill"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.45))
                .frame(width: 14)

            Slider(
                value: Binding(
                    get: { Double(localVolume) },
                    set: { newVal in
                        let intVal = Int(newVal.rounded())
                        localVolume = intVal
                        onSetVolume(intVal)
                    }
                ),
                in: 0...100,
                onEditingChanged: { editing in
                    isDragging = editing
                }
            )
            .controlSize(.small)
            .accentColor(.white.opacity(0.6))

            Text("\(localVolume)%")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
                .monospacedDigit()
                .frame(width: 32, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .onAppear { localVolume = volume }
        .onChange(of: volume) { _, newValue in
            guard !isDragging else { return }
            localVolume = newValue
        }
    }
}
