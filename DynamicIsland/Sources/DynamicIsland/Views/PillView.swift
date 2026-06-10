import SwiftUI

struct PillView: View {
    let trackTitle: String
    let isPlaying: Bool
    @State private var isHovering = false

    var body: some View {
        HStack {
            if isPlaying {
                waveform
                    .opacity(0.6)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 12, weight: .medium))
                    .opacity(0.4)
            }
        }
        .frame(height: 38)
        .frame(maxWidth: .infinity)
        .colorScheme(.dark)
        .brightness(isHovering ? 0.05 : 0)
        .scaleEffect(isHovering ? 1.03 : 1)
        .animation(.easeOut(duration: 0.15), value: isHovering)
        .onHover { h in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovering = h
            }
        }
    }

    @ViewBuilder
    private var waveform: some View {
        PhaseAnimator([0, 1, 2, 1]) { phase in
            HStack(spacing: 3) {
                Capsule()
                    .fill(.white)
                    .frame(width: 3, height: 12 + barHeight(index: 0, phase: phase))
                Capsule()
                    .fill(.white)
                    .frame(width: 3, height: 12 + barHeight(index: 1, phase: phase))
                Capsule()
                    .fill(.white)
                    .frame(width: 3, height: 12 + barHeight(index: 2, phase: phase))
            }
        } animation: { phase in
            .easeInOut(duration: 0.6)
        }
    }

    private func barHeight(index: Int, phase: Int) -> CGFloat {
        let heights: [[CGFloat]] = [
            [0, 6, 2],
            [6, 0, 4],
            [2, 4, 0],
        ]
        return heights[index][phase % heights[index].count]
    }
}
