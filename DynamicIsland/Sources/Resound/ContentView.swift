import SwiftUI

struct ContentView: View {
    let onToggle: (Bool) -> Void
    @State private var isExpanded = false
    @State private var expandedOpacity: Double = 0
    @State private var collapseTask: Task<Void, Never>?
    @ObservedObject private var nowPlaying = NowPlayingViewModel.shared
    @ObservedObject private var settings = SettingsViewModel.shared

    private var notchWidth: CGFloat { CGFloat(settings.notchWidth) }

    var body: some View {
        VStack(spacing: 0) {
            pillView
            expandedPanel
                .opacity(expandedOpacity)
        }
        .frame(width: notchWidth, height: isExpanded ? 192 : 38, alignment: .top)
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
            guard settings.autoHide else { return }
            collapseTask?.cancel()
            if hovering {
                onToggle(true)
                isExpanded = true
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedOpacity = 1
                }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedOpacity = 0
                }
                collapseTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    guard !Task.isCancelled else { return }
                    isExpanded = false
                    expandedOpacity = 0
                    onToggle(false)
                }
            }
        }
        .onDisappear {
            collapseTask?.cancel()
            collapseTask = nil
        }
        .onChange(of: settings.autoHide) { _, autoHide in
            if !autoHide {
                collapseTask?.cancel()
                collapseTask = nil
                isExpanded = true
                expandedOpacity = 1
                onToggle(true)
            } else {
                isExpanded = false
                expandedOpacity = 0
                onToggle(false)
            }
        }
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
