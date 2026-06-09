import Combine
import SwiftUI

@MainActor
final class NowPlayingViewModel: ObservableObject {
    @Published var trackTitle: String = ""
    @Published var artistName: String = ""
    @Published var albumTitle: String = ""
    @Published var duration: TimeInterval = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var isPlaying: Bool = false

    private let service = NowPlayingService()
    private var cancellables = Set<AnyCancellable>()

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
        service.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                self?.trackTitle = info.trackTitle
                self?.artistName = info.artistName
                self?.albumTitle = info.albumTitle
                self?.duration = info.duration
                self?.elapsedTime = info.elapsedTime
                self?.isPlaying = info.isPlaying
            }
            .store(in: &cancellables)
        service.startMonitoring()
    }

    func stop() {
        service.stopMonitoring()
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}
