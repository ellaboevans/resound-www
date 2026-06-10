import Foundation
import Combine

final class NowPlayingService {
    static let shared = NowPlayingService()
    private let queue = DispatchQueue(label: "com.dynamicisland.applescript", qos: .utility)
    private let artworkPath = "/tmp/dynamic_island_art.jpg"
    private var lastSpotifyUri: String?
    private var lastNotificationDate = Date.distantPast
    private var fallbackTimer: Timer?
    let publisher = PassthroughSubject<NowPlayingInfo, Never>()

    struct NowPlayingInfo: Equatable {
        let trackTitle: String
        let artistName: String
        let albumTitle: String
        let duration: TimeInterval
        let elapsedTime: TimeInterval
        let isPlaying: Bool
        let artworkPath: String
    }

    func startMonitoring() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(playbackNotification),
            name: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil
        )
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(playbackNotification),
            name: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil
        )

        pollNowPlaying()

        fallbackTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if Date().timeIntervalSince(self.lastNotificationDate) > 4 {
                self.pollNowPlaying()
            }
        }
    }

    @objc private func playbackNotification() {
        lastNotificationDate = Date()
        pollNowPlaying()
    }

    func stopMonitoring() {
        DistributedNotificationCenter.default().removeObserver(self)
        fallbackTimer?.invalidate()
        fallbackTimer = nil
    }

    func playPause() {
        runAppleScript("tell application \"Spotify\" to playpause")
    }

    func nextTrack() {
        runAppleScript("tell application \"Spotify\" to next track")
    }

    func previousTrack() {
        runAppleScript("tell application \"Spotify\" to previous track")
    }

    private func pollNowPlaying() {
        queue.async { [weak self] in
            guard let self = self else { return }
            let (info, spotifyUri) = self.fetchNowPlaying()
            if let info = info {
                let trackChanged = spotifyUri != nil && spotifyUri != self.lastSpotifyUri
                self.lastSpotifyUri = spotifyUri

                if trackChanged {
                    try? FileManager.default.removeItem(atPath: self.artworkPath)
                }

                if let uri = spotifyUri {
                    let fm = FileManager.default
                    let hasArtwork = fm.fileExists(atPath: self.artworkPath) &&
                        ((try? fm.attributesOfItem(atPath: self.artworkPath))?[.size] as? Int ?? 0) > 100
                    if !hasArtwork {
                        self.fetchArtworkAsync(spotifyUri: uri)
                    }
                }

                DispatchQueue.main.async { self.publisher.send(info) }
            } else {
                self.lastSpotifyUri = nil
                DispatchQueue.main.async { self.sendEmpty() }
            }
        }
    }

    private func runAppleScript(_ source: String) {
        queue.async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", source]
            try? process.run()
            process.waitUntilExit()
        }
    }

    private func fetchArtworkAsync(spotifyUri: String) {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard let trackId = spotifyUri.components(separatedBy: ":").last else { return }

            let trackUrl = "https://open.spotify.com/track/\(trackId)"
            guard let encoded = trackUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: "https://open.spotify.com/oembed?url=\(encoded)") else { return }

            do {
                let data = try Data(contentsOf: url)
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let imageUrlStr = json["thumbnail_url"] as? String,
                   let imageUrl = URL(string: imageUrlStr) {
                    let imageData = try Data(contentsOf: imageUrl)
                    try imageData.write(to: URL(fileURLWithPath: self.artworkPath))
                    print("[NowPlayingService] artwork saved (\(imageData.count) bytes)")
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
        let script = """
        set output to ""
        tell application "System Events"
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
            if output is "" and exists (process "Music") then
                tell application "Music"
                    if player state is playing then
                        set output to (name of current track) & "|||" & (artist of current track) & "|||" & (album of current track) & "|||" & (duration of current track) & "|||" & (player position) & "|||playing"
                    else if player state is paused then
                        set output to (name of current track) & "|||" & (artist of current track) & "|||" & (album of current track) & "|||" & (duration of current track) & "|||" & (player position) & "|||paused"
                    end if
                end tell
            end if
        end tell
        return output
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

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
                let fm = FileManager.default
                if fm.fileExists(atPath: self.artworkPath),
                   let attrs = try? fm.attributesOfItem(atPath: self.artworkPath),
                   (attrs[.size] as? Int ?? 0) > 100 {
                    artworkPath = self.artworkPath
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
