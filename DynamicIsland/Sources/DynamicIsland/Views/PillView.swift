import SwiftUI

struct PillView: View {
    let trackTitle: String
    let isPlaying: Bool
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 10) {
            if isPlaying {
                albumArtIcon
                trackLabel
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "music.note")
                        .font(.system(size: 10, weight: .medium))
                    Text("No Music Playing")
                        .font(.system(size: 12, weight: .medium))
                }
                .opacity(0.4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .colorScheme(.dark)
        .background(Capsule().fill(.ultraThinMaterial))
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
        .scaleEffect(isPressed ? 0.97 : 1)
        .animation(.easeOut(duration: 0.12), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var albumArtIcon: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [.pink, .red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 20, height: 20)
            .overlay(
                Image(systemName: "music.note")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
            )
    }

    private var trackLabel: some View {
        Text(trackTitle)
            .font(.system(size: 12, weight: .medium))
            .lineLimit(1)
            .frame(maxWidth: 140, alignment: .leading)
            .foregroundColor(.white)
    }
}
