import SwiftUI

struct PillView: View {
    let trackTitle: String
    let isPlaying: Bool
    let artworkImage: NSImage?
    let isExpanded: Bool
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 0) {
            if isPlaying {
                albumArtView
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(width: 22, height: 22)
            }
            Spacer(minLength: 0)
            waveform
                .opacity(isPlaying ? 0.6 : 0.15)
        }
        .padding(.horizontal, 10)
        .frame(height: 38)
        .frame(maxWidth: .infinity)
        .colorScheme(.dark)
        .brightness(isHovering ? 0.05 : 0)
        .scaleEffect(!isExpanded && isHovering ? 1.03 : 1)
        .animation(.easeOut(duration: 0.15), value: isHovering)
        .onHover { h in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovering = h
            }
        }
    }

    @ViewBuilder
    private var albumArtView: some View {
        if let image = artworkImage {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 22, height: 22)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.pink, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 22, height: 22)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                )
        }
    }

    @ViewBuilder
    private var waveform: some View {
        if isPlaying {
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
        } else {
            HStack(spacing: 3) {
                Capsule()
                    .fill(.white.opacity(0.15))
                    .frame(width: 3, height: 12)
                Capsule()
                    .fill(.white.opacity(0.15))
                    .frame(width: 3, height: 14)
                Capsule()
                    .fill(.white.opacity(0.15))
                    .frame(width: 3, height: 10)
            }
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
