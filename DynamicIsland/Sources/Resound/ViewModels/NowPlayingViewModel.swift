import Combine
import SwiftUI

@MainActor
final class NowPlayingViewModel: ObservableObject {
    static let shared = NowPlayingViewModel()

    @Published var trackTitle: String = ""
    @Published var artistName: String = ""
    @Published var albumTitle: String = ""
    @Published var artworkImage: NSImage? = nil
    @Published var duration: TimeInterval = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var isPlaying: Bool = false

    private let service: any NowPlayingProviding
    private var cancellables = Set<AnyCancellable>()
    private var lastTrackTitle: String = ""
    private var started = false

    private var trackStartDate: Date?
    private var elapsedAtStart: TimeInterval = 0
    private var elapsedTimer: Timer?

    init(service: any NowPlayingProviding = NowPlayingService.shared) {
        self.service = service
    }

    var progress: Double {
        duration > 0 ? currentElapsed / duration : 0
    }

    var formattedElapsed: String {
        formatTime(currentElapsed)
    }

    var formattedRemaining: String {
        formatTime(max(0, duration - currentElapsed))
    }

    private var currentElapsed: TimeInterval {
        guard isPlaying, let startDate = trackStartDate else { return elapsedAtStart }
        return elapsedAtStart + Date().timeIntervalSince(startDate)
    }

    func start() {
        guard !started else { return }
        started = true
        service.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                guard let self = self else { return }
                self.trackTitle = info.trackTitle
                self.artistName = info.artistName
                self.albumTitle = info.albumTitle
                self.duration = info.duration
                self.elapsedAtStart = info.elapsedTime
                self.isPlaying = info.isPlaying
                self.trackStartDate = info.isPlaying ? Date() : nil
                self.syncElapsed()

                if !info.artworkPath.isEmpty {
                    self.artworkImage = NSImage(contentsOfFile: info.artworkPath)
                } else if info.trackTitle != lastTrackTitle {
                    self.artworkImage = nil
                }
                lastTrackTitle = info.trackTitle

                self.updateElapsedTimer()
            }
            .store(in: &cancellables)
        service.startMonitoring()
    }

    func stop() {
        service.stopMonitoring()
        elapsedTimer?.invalidate()
        elapsedTimer = nil
        cancellables.removeAll()
        started = false
    }

    func playPause() { service.playPause() }
    func nextTrack() { service.nextTrack() }
    func previousTrack() { service.previousTrack() }

    private func syncElapsed() {
        elapsedTime = currentElapsed
    }

    private func updateElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
        guard isPlaying else { syncElapsed(); return }
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.syncElapsed()
            }
        }
        syncElapsed()
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}
