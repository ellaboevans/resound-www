import SwiftUI

struct MusicSection: View {
    let trackTitle: String
    let artistName: String
    let albumTitle: String
    let progress: Double
    let elapsedText: String
    let remainingText: String
    let isPlaying: Bool
    let onPlayPause: () -> Void
    let onNext: () -> Void
    let onPrevious: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                albumArt
                trackInfo
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            progressBar
                .padding(.horizontal, 16)
                .padding(.top, 10)

            HStack(spacing: 28) {
                controlButton("backward.fill", action: onPrevious)
                playPauseButton
                controlButton("forward.fill", action: onNext)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)

            HStack {
                Text(elapsedText)
                    .font(.system(size: 10, weight: .medium))
                    .monospacedDigit()
                Spacer()
                Text("-\(remainingText)")
                    .font(.system(size: 10, weight: .medium))
                    .monospacedDigit()
            }
            .opacity(0.3)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private var albumArt: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [.purple, .teal],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 52, height: 52)
            .overlay(
                Image(systemName: "music.note")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            )
            .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
    }

    private var trackInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(trackTitle)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
            Text(artistName)
                .font(.system(size: 11))
                .opacity(0.45)
                .lineLimit(1)
            if !albumTitle.isEmpty {
                Text(albumTitle)
                    .font(.system(size: 10))
                    .opacity(0.3)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 3)
                Capsule()
                    .fill(Color.white)
                    .frame(width: geo.size.width * progress, height: 3)
                    .opacity(0.5)
            }
        }
        .frame(height: 3)
    }

    private var playPauseButton: some View {
        Button(action: onPlayPause) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: 32, height: 32)
                .background(Color.white)
                .clipShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func controlButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .medium))
                .opacity(0.35)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
