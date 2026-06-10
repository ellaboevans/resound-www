import SwiftUI

struct ContentView: View {
    let onToggle: (Bool) -> Void
    @State private var isExpanded = false
    @ObservedObject private var nowPlaying = NowPlayingViewModel.shared
    @ObservedObject private var settings = SettingsViewModel.shared

    private var notchWidth: CGFloat { CGFloat(settings.notchWidth) }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: -6) {
                pillView
                expandedPanel
                    .offset(y: isExpanded ? 0 : 151)
                    .opacity(isExpanded ? 1 : 0)
                    .animation(.spring(response: 0.25, dampingFraction: 1), value: isExpanded)
            }
            .frame(width: notchWidth, height: 189)
        }
        .frame(width: notchWidth, height: isExpanded ? 189 : 38, alignment: .top)
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
            isExpanded = hovering
            onToggle(hovering)
        }
        .onAppear { NowPlayingViewModel.shared.start() }
        .onDisappear { NowPlayingViewModel.shared.stop() }
    }

    private var pillView: some View {
        PillView(
            trackTitle: nowPlaying.trackTitle,
            isPlaying: nowPlaying.isPlaying,
            artworkImage: nowPlaying.artworkImage,
            isExpanded: isExpanded,
            waveformStyle: settings.waveformStyle
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
