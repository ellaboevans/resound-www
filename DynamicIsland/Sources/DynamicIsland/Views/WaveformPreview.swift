import SwiftUI

struct WaveformPreview: View {
    let style: WaveformStyle
    let isPlaying: Bool
    var animated: Bool = true

    var body: some View {
        Group {
            if animated {
                TimelineView(.periodic(from: .now, by: 0.03)) { timeline in
                    content(for: timeline.date)
                }
            } else {
                content(for: Date())
            }
        }
        .frame(height: 28)
        .clipped()
    }

    @ViewBuilder
    private func content(for date: Date) -> some View {
        switch style {
        case .classic: ClassicBars(date: date, isPlaying: isPlaying).frame(maxWidth: .infinity)
        case .pulse: PulseBar(date: date, isPlaying: isPlaying).frame(maxWidth: .infinity)
        case .equalizer: EqualizerBars(date: date, isPlaying: isPlaying).frame(maxWidth: .infinity)
        }
    }
}

private struct ClassicBars: View {
    let date: Date; let isPlaying: Bool
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                Capsule().fill(Color.white.opacity(i == 1 ? 0.85 : 0.5))
                    .frame(width: 3, height: height(for: i))
                    .animation(.linear(duration: 0.03), value: height(for: i))
            }
        }
    }
    private func height(for index: Int) -> CGFloat {
        guard isPlaying else { return [0.5, 0.7, 0.4][index] * 28 }
        let t = date.timeIntervalSinceReferenceDate
        let v = sin(t * [0.9, 1.4, 0.8][index] + [0, 1.2, 2.8][index])
        return max(2, (0.25 + 0.55 * (v + 1) / 2) * 28)
    }
}

private struct PulseBar: View {
    let date: Date; let isPlaying: Bool
    var body: some View {
        Capsule().fill(Color.white)
            .frame(width: 6, height: height)
            .animation(.linear(duration: 0.03), value: height)
    }
    private var height: CGFloat {
        guard isPlaying else { return 0.65 * 28 }
        let v = sin(date.timeIntervalSinceReferenceDate * 2.0)
        return max(2, (0.5 + 0.45 * (v + 1) / 2) * 28)
    }
}

private struct EqualizerBars: View {
    let date: Date; let isPlaying: Bool
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<6, id: \.self) { i in
                Capsule().fill(Color.white.opacity(0.75))
                    .frame(width: 3, height: height(for: i))
                    .animation(.linear(duration: 0.03), value: height(for: i))
            }
        }
    }
    private func height(for index: Int) -> CGFloat {
        guard isPlaying else { return [0.3, 0.5, 0.4, 0.7, 0.35, 0.55][index] * 28 }
        let t = date.timeIntervalSinceReferenceDate
        let v = sin(t * [1.5, 2.0, 1.2, 2.5, 1.8, 3.0][index] + [0, 0.8, 1.6, 2.4, 3.2, 4.0][index])
        return max(2, (0.25 + 0.6 * (v + 1) / 2) * 28)
    }
}


