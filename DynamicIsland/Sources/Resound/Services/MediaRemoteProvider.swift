import Foundation
import Combine

final class MediaRemoteProvider {
    static let shared = MediaRemoteProvider()

    private var requestNowPlaying: ((DispatchQueue, @escaping ([String: Any]) -> Void) -> Void)?
    private var registerNotifications: ((DispatchQueue) -> Void)?
    private var unregisterNotifications: (() -> Void)?
    private var timer: Timer?
    private(set) var lastInfo: NowPlayingInfo?
    let publisher = PassthroughSubject<NowPlayingInfo, Never>()

    struct NowPlayingInfo: Equatable {
        let trackTitle: String
        let artistName: String
        let albumTitle: String
        let duration: TimeInterval
        let elapsedTime: TimeInterval
        let isPlaying: Bool
        let artworkData: Data?
        let sourceApp: String
    }

    func start() {
        guard requestNowPlaying == nil else { return }
        guard loadFramework() else { return }

        let queue = DispatchQueue(label: "com.resound.mediaremote", qos: .utility)
        registerNotifications?(queue)

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.poll()
        }
        poll()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        unregisterNotifications?()
        requestNowPlaying = nil
        registerNotifications = nil
        unregisterNotifications = nil
        lastInfo = nil
    }

    private func poll() {
        guard let request = requestNowPlaying else { return }
        request(DispatchQueue.global(qos: .utility)) { [weak self] info in
            guard let self else { return }
            let parsed = parse(info)
            if let parsed, parsed != self.lastInfo {
                self.lastInfo = parsed
                DispatchQueue.main.async {
                    self.publisher.send(parsed)
                }
            }
        }
    }

    private func parse(_ dict: [String: Any]) -> NowPlayingInfo? {
        guard let title = dict["kMRMediaRemoteNowPlayingInfoTitle"] as? String,
              !title.isEmpty else { return nil }

        let artist = dict["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
        let album = dict["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? ""
        let duration = dict["kMRMediaRemoteNowPlayingInfoDuration"] as? Double ?? 0
        let elapsed = dict["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double ?? 0
        let rate = dict["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double ?? 0
        let artworkData = dict["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data
        let client = dict["kMRMediaRemoteNowPlayingInfoClientPropertiesData"] as? [String: Any]
        let sourceApp = client?["kMRMediaRemoteNowPlayingInfoClientBundleIdentifier"] as? String ?? ""

        return NowPlayingInfo(
            trackTitle: title,
            artistName: artist,
            albumTitle: album,
            duration: duration,
            elapsedTime: elapsed,
            isPlaying: rate > 0,
            artworkData: artworkData,
            sourceApp: sourceApp
        )
    }

    private func loadFramework() -> Bool {
        guard let lib = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY) else {
            return false
        }

        let MRRequest: (@convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void)?
            = loadSymbol(lib, "MRMediaRemoteGetNowPlayingInfo")
        let MRRegister: (@convention(c) (DispatchQueue) -> Void)?
            = loadSymbol(lib, "MRMediaRemoteRegisterForNowPlayingNotifications")
        let MRUnregister: (@convention(c) () -> Void)?
            = loadSymbol(lib, "MRMediaRemoteUnregisterForNowPlayingNotifications")

        requestNowPlaying = MRRequest
        registerNotifications = MRRegister
        unregisterNotifications = MRUnregister
        return requestNowPlaying != nil
    }

    private func loadSymbol<T>(_ lib: UnsafeMutableRawPointer, _ name: String) -> T? {
        guard let sym = dlsym(lib, name) else { return nil }
        return unsafeBitCast(sym, to: T.self)
    }
}
