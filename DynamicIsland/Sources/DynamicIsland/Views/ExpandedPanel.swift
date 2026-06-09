import SwiftUI

struct ExpandedPanel: View {
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
        MusicSection(
            trackTitle: trackTitle,
            artistName: artistName,
            albumTitle: albumTitle,
            progress: progress,
            elapsedText: elapsedText,
            remainingText: remainingText,
            isPlaying: isPlaying,
            onPlayPause: onPlayPause,
            onNext: onNext,
            onPrevious: onPrevious
        )
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
    }
}
