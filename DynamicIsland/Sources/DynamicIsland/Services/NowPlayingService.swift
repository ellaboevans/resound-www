import Foundation
import MediaPlayer
import Combine

final class NowPlayingService {
    private var timer: Timer?
    let publisher = PassthroughSubject<NowPlayingInfo, Never>()

    struct NowPlayingInfo: Equatable {
        let trackTitle: String
        let artistName: String
        let albumTitle: String
        let duration: TimeInterval
        let elapsedTime: TimeInterval
        let isPlaying: Bool
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.pollNowPlaying()
        }
        pollNowPlaying()
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func pollNowPlaying() {
        guard let media = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
            publisher.send(NowPlayingInfo(
                trackTitle: "",
                artistName: "",
                albumTitle: "",
                duration: 0,
                elapsedTime: 0,
                isPlaying: false
            ))
            return
        }

        let info = NowPlayingInfo(
            trackTitle: media[MPMediaItemPropertyTitle] as? String ?? "",
            artistName: media[MPMediaItemPropertyArtist] as? String ?? "",
            albumTitle: media[MPMediaItemPropertyAlbumTitle] as? String ?? "",
            duration: media[MPMediaItemPropertyPlaybackDuration] as? TimeInterval ?? 0,
            elapsedTime: media[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? TimeInterval ?? 0,
            isPlaying: (media[MPNowPlayingInfoPropertyPlaybackRate] as? Double ?? 0) > 0
        )
        publisher.send(info)
    }
}
