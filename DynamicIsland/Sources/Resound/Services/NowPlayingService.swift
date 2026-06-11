import Cocoa
import Combine

struct NowPlayingInfo: Equatable {
    let trackTitle: String
    let artistName: String
    let albumTitle: String
    let duration: TimeInterval
    let elapsedTime: TimeInterval
    let isPlaying: Bool
    let artworkPath: String
}

protocol NowPlayingProviding {
    var publisher: PassthroughSubject<NowPlayingInfo, Never> { get }
    func startMonitoring()
    func stopMonitoring()
    func playPause()
    func nextTrack()
    func previousTrack()
}

final class NowPlayingService {
    static let shared = NowPlayingService()
    private let queue = DispatchQueue(label: "com.dynamicisland.applescript", qos: .utility)
    private let appleScript = AppleScriptRunner()
    private let artworkCache = SpotifyArtworkCache(path: "/tmp/dynamic_island_art.jpg")
    private let mediaArtworkPath = "/tmp/dynamic_island_media_art.jpg"
    private var lastSpotifyUri: String?
    private var lastNotificationDate = Date.distantPast
    private var fallbackTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    let publisher = PassthroughSubject<NowPlayingInfo, Never>()

    private var musicSource: MusicSource {
        SettingsViewModel.shared.musicSource
    }

    func startMonitoring() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(spotifyNotification),
            name: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil
        )
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(musicNotification),
            name: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil
        )

        MediaRemoteProvider.shared.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] remoteInfo in
                guard let self else { return }
                guard musicSource == .automatic else { return }
                let isMusicApp = remoteInfo.sourceApp == "com.spotify.client" || remoteInfo.sourceApp == "com.apple.Music"
                if !isMusicApp {
                    var path = ""
                    if let data = remoteInfo.artworkData {
                        try? data.write(to: URL(fileURLWithPath: self.mediaArtworkPath))
                        path = self.mediaArtworkPath
                    }
                    self.publisher.send(NowPlayingInfo(
                        trackTitle: remoteInfo.trackTitle,
                        artistName: remoteInfo.artistName,
                        albumTitle: remoteInfo.albumTitle,
                        duration: remoteInfo.duration,
                        elapsedTime: remoteInfo.elapsedTime,
                        isPlaying: remoteInfo.isPlaying,
                        artworkPath: path
                    ))
                }
            }
            .store(in: &cancellables)

        BrowserTabProvider.shared.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] browserInfo in
                guard let self else { return }
                guard musicSource == .automatic else { return }
                self.publisher.send(NowPlayingInfo(
                    trackTitle: browserInfo.trackTitle,
                    artistName: browserInfo.artistName,
                    albumTitle: browserInfo.albumTitle,
                    duration: browserInfo.duration,
                    elapsedTime: browserInfo.elapsedTime,
                    isPlaying: browserInfo.isPlaying,
                    artworkPath: browserInfo.artworkPath
                ))
            }
            .store(in: &cancellables)

        MediaRemoteProvider.shared.start()
        BrowserTabProvider.shared.start()

        pollNowPlaying()

        fallbackTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if Date().timeIntervalSince(self.lastNotificationDate) > 4 {
                self.pollNowPlaying()
            }
        }
    }

    @objc private func spotifyNotification() {
        guard musicSource == .automatic || musicSource == .spotify else { return }
        lastNotificationDate = Date()
        pollNowPlaying()
    }

    @objc private func musicNotification() {
        guard musicSource == .automatic || musicSource == .appleMusic else { return }
        lastNotificationDate = Date()
        pollNowPlaying()
    }

    func stopMonitoring() {
        DistributedNotificationCenter.default().removeObserver(self)
        MediaRemoteProvider.shared.stop()
        BrowserTabProvider.shared.stop()
        fallbackTimer?.invalidate()
        fallbackTimer = nil
        cancellables.removeAll()
    }

    private func optimisticToggleBrowserPlayback() {
        guard let browserInfo = BrowserTabProvider.shared.lastInfo,
              !browserInfo.trackTitle.isEmpty else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.publisher.send(NowPlayingInfo(
                trackTitle: browserInfo.trackTitle,
                artistName: browserInfo.artistName,
                albumTitle: browserInfo.albumTitle,
                duration: browserInfo.duration,
                elapsedTime: browserInfo.elapsedTime,
                isPlaying: !browserInfo.isPlaying,
                artworkPath: browserInfo.artworkPath
            ))
        }
    }

    func playPause() {
        switch musicSource {
        case .spotify:
            if isAppRunning("Spotify") { runAppleScript("tell application \"Spotify\" to playpause") }
        case .appleMusic:
            if isAppRunning("Music") { runAppleScript("tell application \"Music\" to playpause") }
        case .automatic:
            if isAppRunning("Spotify") { runAppleScript("tell application \"Spotify\" to playpause"); return }
            if isAppRunning("Music") { runAppleScript("tell application \"Music\" to playpause"); return }
            guard isChromeRunning() else { return }
            chromeMediaCommand("var v=document.querySelector('video');if(v){if(v.paused){v.play()}else{v.pause()}}")
            optimisticToggleBrowserPlayback()
        }
    }

    func nextTrack() {
        switch musicSource {
        case .spotify:
            if isAppRunning("Spotify") { runAppleScript("tell application \"Spotify\" to next track") }
        case .appleMusic:
            if isAppRunning("Music") { runAppleScript("tell application \"Music\" to next track") }
        case .automatic:
            if isAppRunning("Spotify") { runAppleScript("tell application \"Spotify\" to next track"); return }
            if isAppRunning("Music") { runAppleScript("tell application \"Music\" to next track"); return }
            guard isChromeRunning() else { return }
            chromeMediaCommand("document.querySelector('ytmusic-player-bar [aria-label=\"Next\"]')?.click()")
        }
    }

    func previousTrack() {
        switch musicSource {
        case .spotify:
            if isAppRunning("Spotify") { runAppleScript("tell application \"Spotify\" to previous track") }
        case .appleMusic:
            if isAppRunning("Music") { runAppleScript("tell application \"Music\" to previous track") }
        case .automatic:
            if isAppRunning("Spotify") { runAppleScript("tell application \"Spotify\" to previous track"); return }
            if isAppRunning("Music") { runAppleScript("tell application \"Music\" to previous track"); return }
            guard isChromeRunning() else { return }
            chromeMediaCommand("document.querySelector('ytmusic-player-bar [aria-label=\"Previous\"]')?.click()")
        }
    }

    private func isAppRunning(_ name: String) -> Bool {
        let script = "tell application \"System Events\" to exists (process \"\(name)\")"
        return (try? appleScript.output(from: script)) == "true"
    }

    private func chromeMediaCommand(_ js: String) {
        let escaped = js.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "Google Chrome"
            repeat with w in windows
                repeat with t in tabs of w
                    if URL of t contains "music.youtube.com" then
                        tell t to execute javascript "\(escaped)"
                        return
                    end if
                end repeat
            end repeat
        end tell
        """
        queue.async { [weak self] in
            _ = self?.appleScript.run(script)
        }
    }

    private func isChromeRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.google.Chrome" }
    }

    private func isChromePid() -> pid_t? {
        NSWorkspace.shared.runningApplications.first { $0.bundleIdentifier == "com.google.Chrome" }?.processIdentifier
    }

    private func isProcessAlive(_ pid: pid_t) -> Bool {
        kill(pid, 0) == 0
    }

    private func pollNowPlaying() {
        queue.async { [weak self] in
            guard let self = self else { return }
            let (info, spotifyUri) = self.fetchNowPlaying()
            if let info = info {
                let trackChanged = spotifyUri != nil && spotifyUri != self.lastSpotifyUri
                self.lastSpotifyUri = spotifyUri

                if trackChanged {
                    self.artworkCache.clear()
                }

                if let uri = spotifyUri {
                    if !self.artworkCache.hasArtwork {
                        self.fetchArtworkAsync(spotifyUri: uri)
                    }
                }

                DispatchQueue.main.async { self.publisher.send(info) }
            } else {
                self.lastSpotifyUri = nil
                if musicSource != .automatic ||
                   (MediaRemoteProvider.shared.lastInfo == nil && BrowserTabProvider.shared.lastInfo == nil) {
                    DispatchQueue.main.async { self.sendEmpty() }
                }
            }
        }
    }

    private func runAppleScript(_ source: String) {
        queue.async {
            _ = self.appleScript.run(source)
        }
    }

    private func fetchArtworkAsync(spotifyUri: String) {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard let trackId = spotifyUri.components(separatedBy: ":").last else { return }

            do {
                if let imageData = try self.artworkCache.fetchImageData(for: trackId) {
                    self.artworkCache.save(imageData)
                    // Re-fetch now-playing info which will now have the artwork path
                    let (fetchedInfo, _) = self.fetchNowPlaying()
                    if let info = fetchedInfo {
                        DispatchQueue.main.async { self.publisher.send(info) }
                    }
                }
            } catch {
                print("[NowPlayingService] artwork fetch error: \(error)")
            }
        }
    }

    private func fetchNowPlaying() -> (NowPlayingInfo?, spotifyUri: String?) {
        let spotifyBlock = """
        if exists (process "Spotify") then
            tell application "Spotify"
                if player state is playing or player state is paused then
                    if player state is playing then
                        set stateStr to "playing"
                    else
                        set stateStr to "paused"
                    end if
                    set output to (name of current track) & "|||" & (artist of current track) & "|||" & (album of current track) & "|||" & (duration of current track) & "|||" & (player position) & "|||" & stateStr & "|||" & (spotify url of current track)
                end if
            end tell
        end if
        """

        let musicBlock = """
        if output is "" and exists (process "Music") then
            tell application "Music"
                if player state is playing then
                    set output to (name of current track) & "|||" & (artist of current track) & "|||" & (album of current track) & "|||" & (duration of current track) & "|||" & (player position) & "|||playing"
                else if player state is paused then
                    set output to (name of current track) & "|||" & (artist of current track) & "|||" & (album of current track) & "|||" & (duration of current track) & "|||" & (player position) & "|||paused"
                end if
            end tell
        end if
        """

        let querySpotify = musicSource == .automatic || musicSource == .spotify
        let queryMusic = musicSource == .automatic || musicSource == .appleMusic

        let script = """
        set output to ""
        tell application "System Events"
        \(querySpotify ? spotifyBlock : "")
        \(queryMusic ? musicBlock : "")
        end tell
        return output
        """

        do {
            let output = try appleScript.output(from: script)
            guard !output.isEmpty else { return (nil, nil) }

            let parts = output.components(separatedBy: "|||")
            guard parts.count >= 6 else { return (nil, nil) }

            var spotifyUri: String?
            var artworkPath: String

            if parts[5] == "playing" || parts[5] == "paused" {
                // Spotify branch - 7 parts
                if parts.count > 6 {
                    spotifyUri = parts[6]
                }
                if artworkCache.hasArtwork {
                    artworkPath = artworkCache.path
                } else {
                    artworkPath = ""
                }
            } else {
                artworkPath = ""
            }

            return (NowPlayingInfo(
                trackTitle: parts[0],
                artistName: parts[1],
                albumTitle: parts[2],
                duration: (Double(parts[3]) ?? 0) / 1000,
                elapsedTime: Double(parts[4]) ?? 0,
                isPlaying: parts[5] == "playing",
                artworkPath: artworkPath
            ), spotifyUri)
        } catch {
            return (nil, nil)
        }
    }

    private func sendEmpty() {
        publisher.send(NowPlayingInfo(
            trackTitle: "", artistName: "", albumTitle: "",
            duration: 0, elapsedTime: 0, isPlaying: false, artworkPath: ""
        ))
    }
}

extension NowPlayingService: NowPlayingProviding {}

private final class AppleScriptRunner {
    func run(_ source: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", source]

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    func output(from source: String) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", source]

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

private final class SpotifyArtworkCache {
    let path: String
    private let fileManager: FileManager

    init(path: String, fileManager: FileManager = .default) {
        self.path = path
        self.fileManager = fileManager
    }

    var hasArtwork: Bool {
        fileManager.fileExists(atPath: path) &&
            ((try? fileManager.attributesOfItem(atPath: path))?[.size] as? Int ?? 0) > 100
    }

    func clear() {
        try? fileManager.removeItem(atPath: path)
    }

    func save(_ data: Data) {
        try? data.write(to: URL(fileURLWithPath: path))
    }

    func fetchImageData(for trackId: String) throws -> Data? {
        let trackUrl = "https://open.spotify.com/track/\(trackId)"
        guard let encoded = trackUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://open.spotify.com/oembed?url=\(encoded)") else {
            return nil
        }

        let data = try Data(contentsOf: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let imageUrlStr = json["thumbnail_url"] as? String,
              let imageUrl = URL(string: imageUrlStr) else {
            return nil
        }

        return try Data(contentsOf: imageUrl)
    }
}
