import Foundation
import Combine

final class BrowserTabProvider {
    static let shared = BrowserTabProvider()

    private var timer: Timer?
    private var stateTimer: Timer?
    private var lastVideoId: String?
    private(set) var lastInfo: NowPlayingInfo?
    private let artworkCache = BrowserArtworkCache(path: "/tmp/dynamic_island_browser_art.jpg")
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

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.poll()
        }
        stateTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.pollPlaybackState()
        }
        poll()
        pollPlaybackState()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        stateTimer?.invalidate()
        stateTimer = nil
        lastVideoId = nil
        lastInfo = nil
    }

    private func poll() {
        let jxa = """
        var chrome = Application("Google Chrome");
        var wins = [];
        try { wins = chrome.windows; } catch(e) { }
        var out = [];
        for (var w = 0; w < wins.length; w++) {
            var tabs = [];
            try { tabs = wins[w].tabs; } catch(e) { }
            for (var i = 0; i < tabs.length; i++) {
                var t = tabs[i];
                var name = ""; var url = "";
                try { name = t.name(); } catch(e) {}
                try { url = t.url(); } catch(e) {}
                out.push(name + "|||" + url);
            }
        }
        out.join("\\n");
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-l", "JavaScript", "-e", jxa]
        let pipe = Pipe()
        process.standardOutput = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return }

            let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
            var found = false
            for line in lines {
                let parts = line.components(separatedBy: "|||")
                guard parts.count == 2 else { continue }
                if let videoId = extractYouTubeMusicVideoId(title: parts[0], url: parts[1]) {
                    found = true
                    handleYouTubeVideo(videoId, title: parts[0])
                    break
                }
            }

            if !found, lastInfo != nil {
                lastInfo = nil
                lastVideoId = nil
                DispatchQueue.main.async { [weak self] in
                    self?.publisher.send(NowPlayingInfo(
                        trackTitle: "", artistName: "", albumTitle: "",
                        duration: 0, elapsedTime: 0, isPlaying: false, artworkPath: ""
                    ))
                }
            }
        } catch {}
    }

    private func extractYouTubeMusicVideoId(title: String, url: String) -> String? {
        guard title.contains("YouTube Music") else { return nil }
        guard let urlComponents = URLComponents(string: url),
              urlComponents.host?.contains("music.youtube.com") == true else { return nil }
        return urlComponents.queryItems?.first(where: { $0.name == "v" })?.value
    }

    private func pollPlaybackState() {
        guard lastInfo != nil else { return }
        let script = """
        tell application "Google Chrome"
            repeat with w in windows
                repeat with t in tabs of w
                    if URL of t contains "music.youtube.com" then
                        set result to execute t javascript "var v=document.querySelector('video');v?v.currentTime+'|||'+v.duration+'|||'+(!v.paused):''"
                        return result
                    end if
                end repeat
            end repeat
            return ""
        end tell
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
            guard let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !output.isEmpty else { return }
            let parts = output.components(separatedBy: "|||")
            guard parts.count == 3,
                  let currentTime = Double(parts[0]),
                  let duration = Double(parts[1]),
                  duration > 0 else { return }
            let isPlaying = parts[2] == "true"

            guard let current = lastInfo else { return }
            let updated = NowPlayingInfo(
                trackTitle: current.trackTitle, artistName: current.artistName,
                albumTitle: current.albumTitle, duration: duration,
                elapsedTime: currentTime, isPlaying: isPlaying,
                artworkPath: current.artworkPath
            )
            if updated != current {
                lastInfo = updated
                DispatchQueue.main.async { [weak self] in
                    self?.publisher.send(updated)
                }
            }
        } catch {}
    }

    private func handleYouTubeVideo(_ videoId: String, title: String) {
        let isPlaying = !title.trimmingCharacters(in: .whitespaces).hasPrefix("YouTube Music")

        if videoId != lastVideoId {
            lastVideoId = videoId

            let parsed = parseYouTubeTabTitle(title)
            let info = NowPlayingInfo(
                trackTitle: parsed.title, artistName: parsed.artist,
                albumTitle: "", duration: 0, elapsedTime: 0,
                isPlaying: isPlaying, artworkPath: ""
            )
            lastInfo = info
            DispatchQueue.main.async { [weak self] in
                self?.publisher.send(info)
            }

            DispatchQueue.global(qos: .utility).async { [weak self] in
                self?.fetchYouTubeMetadata(videoId: videoId)
            }
            return
        }

        guard let current = lastInfo else { return }
        if current.isPlaying != isPlaying {
            let updated = NowPlayingInfo(
                trackTitle: current.trackTitle, artistName: current.artistName,
                albumTitle: current.albumTitle, duration: current.duration,
                elapsedTime: current.elapsedTime, isPlaying: isPlaying,
                artworkPath: current.artworkPath
            )
            lastInfo = updated
            DispatchQueue.main.async { [weak self] in
                self?.publisher.send(updated)
            }
        }
    }

    private func fetchYouTubeMetadata(videoId: String) {
        guard let url = URL(string: "https://www.youtube.com/oembed?url=https://music.youtube.com/watch?v=\(videoId)&format=json") else { return }
        do {
            let data = try Data(contentsOf: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
            let oembedTitle = json["title"] as? String ?? ""
            let artist = json["author_name"] as? String ?? ""
            var artworkPath = ""
            if let thumbUrlStr = json["thumbnail_url"] as? String,
               let thumbUrl = URL(string: thumbUrlStr),
               let imageData = try? Data(contentsOf: thumbUrl) {
                artworkCache.save(imageData)
                if artworkCache.hasArtwork {
                    artworkPath = artworkCache.path
                }
            }

            let info = NowPlayingInfo(
                trackTitle: oembedTitle, artistName: artist,
                albumTitle: "", duration: 0, elapsedTime: 0,
                isPlaying: true, artworkPath: artworkPath
            )
            lastInfo = info
            DispatchQueue.main.async { [weak self] in
                self?.publisher.send(info)
            }
        } catch {}
    }

    private func parseYouTubeTabTitle(_ title: String) -> (title: String, artist: String) {
        let cleaned = title.replacingOccurrences(of: " | YouTube Music", with: "").trimmingCharacters(in: .whitespaces)
        let dashRange = cleaned.range(of: " - ")
        if let range = dashRange {
            let before = String(cleaned[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            let after = String(cleaned[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            if before.contains("(feat.") || before.contains("ft.") {
                return (cleaned, "")
            }
            return (before, after)
        }
        return (cleaned, "")
    }
}

private final class BrowserArtworkCache {
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

    func save(_ data: Data) {
        try? data.write(to: URL(fileURLWithPath: path))
    }
}
