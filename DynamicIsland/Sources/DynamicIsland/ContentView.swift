import SwiftUI

struct ContentView: View {
    let onToggle: (Bool) -> Void
    @State private var isExpanded = false
    @StateObject private var nowPlaying = NowPlayingViewModel()

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: -6) {
                pillView
                expandedPanel
                    .offset(y: isExpanded ? 0 : 151)
                    .opacity(isExpanded ? 1 : 0)
                    .animation(.spring(response: 0.25, dampingFraction: 1), value: isExpanded)
            }
            .frame(width: 340, height: 189)
        }
        .frame(width: 340, height: isExpanded ? 189 : 38, alignment: .top)
        .clipped()
        .background(
            UnevenRoundedRectangle(
                cornerRadii: .init(
                    bottomLeading: 14,
                    bottomTrailing: 14
                ),
                style: .continuous
            )
            .fill(.black)
        )
        .onHover { hovering in
            guard !nowPlaying.trackTitle.isEmpty else { return }
            isExpanded = hovering
            onToggle(hovering)
        }
        .onAppear { nowPlaying.start() }
        .onDisappear { nowPlaying.stop() }
    }

    private var pillView: some View {
        PillView(
            trackTitle: nowPlaying.trackTitle,
            isPlaying: nowPlaying.isPlaying,
            artworkImage: nowPlaying.artworkImage,
            isExpanded: isExpanded
        )
        .transaction { t in
            t.disablesAnimations = true
        }
    }

    private var expandedPanel: some View {
        ExpandedPanel {
            MusicSection(
                trackTitle: nowPlaying.trackTitle,
                artistName: nowPlaying.artistName,
                albumTitle: nowPlaying.albumTitle,
                artworkImage: nowPlaying.artworkImage,
                progress: nowPlaying.progress,
                elapsedText: nowPlaying.formattedElapsed,
                remainingText: nowPlaying.formattedRemaining,
                isPlaying: nowPlaying.isPlaying,
                onPlayPause: { nowPlaying.playPause() },
                onNext: { nowPlaying.nextTrack() },
                onPrevious: { nowPlaying.previousTrack() }
            )
        }
    }
}
