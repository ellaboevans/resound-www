import SwiftUI

struct ContentView: View {
    let onToggle: (Bool) -> Void
    @State private var isExpanded = false
    @StateObject private var nowPlaying = NowPlayingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            pillView
                .zIndex(1)

            if isExpanded {
                expandedPanel
                    .transition(.identity)
                    .offset(y: -6)
            }
        }
        .frame(width: 340)
        .onAppear { nowPlaying.start() }
        .onDisappear { nowPlaying.stop() }
    }

    private var pillView: some View {
        PillView(
            trackTitle: nowPlaying.trackTitle,
            isPlaying: nowPlaying.isPlaying
        )
        .contentShape(Capsule())
        .onTapGesture {
            guard !nowPlaying.trackTitle.isEmpty else { return }
            withAnimation(.spring(duration: 0.4, bounce: 0.08)) {
                isExpanded.toggle()
            }
            onToggle(isExpanded)
        }
    }

    private var expandedPanel: some View {
        ExpandedPanel(
            trackTitle: nowPlaying.trackTitle,
            artistName: nowPlaying.artistName,
            albumTitle: nowPlaying.albumTitle,
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
