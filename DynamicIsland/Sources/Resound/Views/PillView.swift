import SwiftUI

struct PillView: View {
    let trackTitle: String
    let isPlaying: Bool
    let artworkImage: NSImage?
    let isExpanded: Bool
    let waveformStyle: WaveformStyle
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
            WaveformPreview(style: waveformStyle, isPlaying: isPlaying)
                .frame(width: 60, height: 28)
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


}
