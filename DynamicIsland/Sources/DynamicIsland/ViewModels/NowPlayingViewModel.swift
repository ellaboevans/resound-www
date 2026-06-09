import Combine
import SwiftUI

@MainActor
final class NowPlayingViewModel: ObservableObject {
    @Published var trackTitle: String = ""
    @Published var artistName: String = ""
    @Published var albumTitle: String = ""
    @Published var artworkImage: NSImage? = nil
    @Published var duration: TimeInterval = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var isPlaying: Bool = false

    private let service = NowPlayingService()
    private var cancellables = Set<AnyCancellable>()
    private var tickTimer: Timer?
    private var lastTrackTitle: String = ""

    var progress: Double {
        duration > 0 ? elapsedTime / duration : 0
    }

    var formattedElapsed: String {
        formatTime(elapsedTime)
    }

    var formattedRemaining: String {
        formatTime(max(0, duration - elapsedTime))
    }

    func start() {
        cancellables.removeAll()
        service.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                guard let self = self else { return }
                self.trackTitle = info.trackTitle
                self.artistName = info.artistName
                self.albumTitle = info.albumTitle
                self.duration = info.duration
                self.elapsedTime = info.elapsedTime
                self.isPlaying = info.isPlaying

                if !info.artworkPath.isEmpty {
                    self.artworkImage = NSImage(contentsOfFile: info.artworkPath)
                } else if info.trackTitle != lastTrackTitle {
                    self.artworkImage = nil
                }
                lastTrackTitle = info.trackTitle

                self.updateTickTimer()
            }
            .store(in: &cancellables)
        service.startMonitoring()
    }

    func stop() {
        service.stopMonitoring()
        tickTimer?.invalidate()
        tickTimer = nil
        cancellables.removeAll()
    }

    func playPause() { service.playPause() }
    func nextTrack() { service.nextTrack() }
    func previousTrack() { service.previousTrack() }

    private func updateTickTimer() {
        tickTimer?.invalidate()
        tickTimer = nil
        guard isPlaying else { return }
        tickTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.elapsedTime += 0.1
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}
