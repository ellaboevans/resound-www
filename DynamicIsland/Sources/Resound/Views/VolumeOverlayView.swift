import SwiftUI

struct VolumeOverlayView: View {
    @ObservedObject private var state = VolumeOverlayState.shared

    private var iconName: String {
        if state.isMuted { return "speaker.slash.fill" }
        switch state.level {
        case 0: return "speaker.slash.fill"
        case ..<0.2: return "speaker.fill"
        case ..<0.5: return "speaker.wave.1.fill"
        default: return "speaker.wave.3.fill"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 18)

            GeometryReader { geo in
                let barCount = 8
                let spacing: CGFloat = 3
                let barWidth = (geo.size.width - CGFloat(barCount - 1) * spacing) / CGFloat(barCount)
                let fillCount = Int((CGFloat(state.level) * CGFloat(barCount)).rounded())
                HStack(spacing: spacing) {
                    ForEach(0..<barCount, id: \.self) { i in
                        Capsule()
                            .fill(i < fillCount ? Color.white.opacity(i == fillCount - 1 ? 0.5 : 0.7) : Color.white.opacity(0.1))
                            .frame(width: barWidth, height: 22)
                    }
                }
            }
            .frame(height: 22)

            Text("\(Int((state.level * 100).rounded()))%")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
                .monospacedDigit()
                .fixedSize(horizontal: true, vertical: false)
                .frame(minWidth: 30, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(white: 0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
        .colorScheme(.dark)
    }
}
