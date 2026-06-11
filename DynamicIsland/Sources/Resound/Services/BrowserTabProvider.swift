import Cocoa
import Combine

final class BrowserTabProvider {
    static let shared = BrowserTabProvider()

    private var timer: Timer?
    private var lastVideoId: String?
    private(set) var lastInfo: NowPlayingInfo?
    private let artworkCache = BrowserArtworkCache(path: "/tmp/dynamic_island_browser_art.jpg")
    private var oembedCache: [String: (title: String, artist: String)] = [:]
    private var consecutiveNoDataCount = 0
    private let maxNoDataBeforeSlow = 10
    private var jsAppleEventsDialogShown = false
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
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(self, selector: #selector(chromeLaunched), name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        nc.addObserver(self, selector: #selector(chromeTerminated), name: NSWorkspace.didTerminateApplicationNotification, object: nil)

        if isChromeRunning() {
            scheduleTimer(interval: 5.0)
        }
    }

    func stop() {
        stopPolling()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    @objc private func chromeLaunched(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier == "com.google.Chrome" else { return }
        scheduleTimer(interval: 0.5)
        poll()
    }

    @objc private func chromeTerminated(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier == "com.google.Chrome" else { return }
        lastInfo = nil
        lastVideoId = nil
        consecutiveNoDataCount = 0
        stopPolling()
        DispatchQueue.main.async { [weak self] in
            self?.publisher.send(NowPlayingInfo(trackTitle: "", artistName: "", albumTitle: "", duration: 0, elapsedTime: 0, isPlaying: false, artworkPath: ""))
        }
    }

    private func scheduleTimer(interval: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    private func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    private func isChromeRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.google.Chrome" }
    }

    private func showJavascriptAppleEventsDialog() {
        guard !jsAppleEventsDialogShown else { return }
        jsAppleEventsDialogShown = true
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Chrome JavaScript Access Required"
            alert.informativeText = "Resound needs JavaScript in Chrome to detect YouTube Music playback.\n\nTo enable:\n1. In Chrome, go to View → Developer → Developer Tools\n2. Then go to View → Developer → Allow JavaScript from Apple Events\n3. Click it to enable\n\nThis only needs to be done once."
            alert.alertStyle = .informational
            alert.icon = Self.resoundIcon(size: 64)
            let widthView = NSView(frame: NSRect(x: 0, y: 0, width: 420, height: 1))
            alert.accessoryView = widthView
            alert.addButton(withTitle: "Ok, Got it!")
            alert.runModal()
        }
    }

    private static func resoundIcon(size: CGFloat) -> NSImage {
        let iconSize = NSSize(width: size, height: size)
        return NSImage(size: iconSize, flipped: false) { rect in
            let inset = size * 0.15
            let outer = rect.insetBy(dx: inset, dy: inset)
            let barCount = 3
            let barWidth = size * 0.1
            let spacing = size * 0.12
            let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * spacing
            let startX = outer.midX - totalWidth / 2
            let maxHeight = outer.height - size * 0.15
            let heights: [CGFloat] = [0.4, 1.0, 0.7]
            NSColor.controlTextColor.setFill()
            for (i, relHeight) in heights.enumerated() {
                let barHeight = max(maxHeight * relHeight, size * 0.06)
                let x = startX + CGFloat(i) * (barWidth + spacing)
                let y = outer.midY - barHeight / 2
                let barRect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
                let barPath = NSBezierPath(roundedRect: barRect, xRadius: size * 0.03, yRadius: size * 0.03)
                barPath.fill()
            }
            return true
        }
    }

    private func poll() {
        guard isChromeRunning() else {
            if lastInfo != nil {
                lastInfo = nil
                lastVideoId = nil
                DispatchQueue.main.async { [weak self] in
                    self?.publisher.send(NowPlayingInfo(trackTitle: "", artistName: "", albumTitle: "", duration: 0, elapsedTime: 0, isPlaying: false, artworkPath: ""))
                }
            }
            scheduleTimer(interval: 5.0)
            return
        }

        let jxa = """
        var chrome = Application("Google Chrome");
        var result = "";
        var jsBlocked = false;
        try {
            if (chrome.running()) {
                var wins = chrome.windows();
                for (var w = 0; w < wins.length; w++) {
                    try {
                        var tabs = wins[w].tabs();
                        for (var i = 0; i < tabs.length; i++) {
                            var t = tabs[i];
                            var name = t.name();
                            var url = t.url();
                            if (url.indexOf("music.youtube.com") >= 0) {
                                var state = "";
                                try {
                                    var js = "try{var p=document.querySelector('#movie_player,#ytd-player');if(p&&p.getPlayerState){var s=p.getPlayerState();(s==1?'true':'false')+'|||'+p.getCurrentTime()+'|||'+p.getDuration()}else{var v=document.querySelector('video');v?(!v.paused+'|||'+v.currentTime+'|||'+v.duration):''}}catch(e){''}";
                                    state = t.execute({javascript: js});
                                } catch(e) {
                                    state = "";
                                    if (e.message && e.message.indexOf("turned off") >= 0) { jsBlocked = true; }
                                }
                                result = (jsBlocked ? "JS_BLOCKED|||" : "") + name + "|||" + url + "|||" + state;
                                break;
                            }
                        }
                    } catch(e) {}
                    if (result) { break; }
                }
            }
        } catch(e) {}
        result;
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
            guard let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !output.isEmpty else {
                if lastInfo != nil {
                    lastInfo = nil; lastVideoId = nil
                    DispatchQueue.main.async { [weak self] in
                        self?.publisher.send(NowPlayingInfo(trackTitle: "", artistName: "", albumTitle: "", duration: 0, elapsedTime: 0, isPlaying: false, artworkPath: ""))
                    }
                }
                consecutiveNoDataCount += 1
                if consecutiveNoDataCount >= maxNoDataBeforeSlow {
                    scheduleTimer(interval: 5.0)
                }
                return
            }

            var offset = 0
            if output.hasPrefix("JS_BLOCKED|||") {
                offset = 1
                showJavascriptAppleEventsDialog()
            }
            let parts = output.components(separatedBy: "|||")
            guard parts.count >= 5 + offset else {
                consecutiveNoDataCount += 1
                if consecutiveNoDataCount >= maxNoDataBeforeSlow {
                    scheduleTimer(interval: 5.0)
                }
                return
            }
            let title = parts[0 + offset]
            let url = parts[1 + offset]
            let isPlaying = parts[2 + offset] == "true"
            let currentTime = TimeInterval(parts[3 + offset]) ?? 0
            let duration = TimeInterval(parts[4 + offset]) ?? 0

            guard let urlComponents = URLComponents(string: url),
                  urlComponents.host?.contains("music.youtube.com") == true,
                  let videoId = urlComponents.queryItems?.first(where: { $0.name == "v" })?.value else {
                consecutiveNoDataCount += 1
                if consecutiveNoDataCount >= maxNoDataBeforeSlow {
                    scheduleTimer(interval: 5.0)
                }
                return
            }

            consecutiveNoDataCount = 0
            scheduleTimer(interval: 0.5)
            handleYouTubeVideo(videoId: videoId, title: title, currentTime: currentTime, duration: duration, isPlaying: isPlaying)
        } catch {
            if lastInfo != nil {
                lastInfo = nil; lastVideoId = nil
                DispatchQueue.main.async { [weak self] in
                    self?.publisher.send(NowPlayingInfo(trackTitle: "", artistName: "", albumTitle: "", duration: 0, elapsedTime: 0, isPlaying: false, artworkPath: ""))
                }
            }
            consecutiveNoDataCount += 1
            if consecutiveNoDataCount >= maxNoDataBeforeSlow {
                scheduleTimer(interval: 5.0)
            }
        }
    }

    private func handleYouTubeVideo(videoId: String, title: String, currentTime: TimeInterval, duration: TimeInterval, isPlaying: Bool) {
        if videoId != lastVideoId {
            lastVideoId = videoId

            let parsed = parseYouTubeTabTitle(title)
            if let cached = oembedCache[videoId] {
                let info = NowPlayingInfo(
                    trackTitle: cached.title, artistName: cached.artist,
                    albumTitle: "", duration: duration, elapsedTime: currentTime,
                    isPlaying: isPlaying, artworkPath: artworkCache.path
                )
                lastInfo = info
                DispatchQueue.main.async { [weak self] in
                    self?.publisher.send(info)
                }
            } else {
                let info = NowPlayingInfo(
                    trackTitle: parsed.title, artistName: parsed.artist,
                    albumTitle: "", duration: duration, elapsedTime: currentTime,
                    isPlaying: isPlaying, artworkPath: ""
                )
                lastInfo = info
                DispatchQueue.main.async { [weak self] in
                    self?.publisher.send(info)
                }
                fetchYouTubeMetadata(videoId: videoId, title: title)
            }
            return
        }

        guard let current = lastInfo else { return }
        let needsUpdate = current.isPlaying != isPlaying ||
                          abs(current.elapsedTime - currentTime) > 1 ||
                          abs(current.duration - duration) > 0.1
        if needsUpdate {
            let updated = NowPlayingInfo(
                trackTitle: current.trackTitle, artistName: current.artistName,
                albumTitle: current.albumTitle, duration: duration,
                elapsedTime: currentTime, isPlaying: isPlaying,
                artworkPath: current.artworkPath
            )
            lastInfo = updated
            DispatchQueue.main.async { [weak self] in
                self?.publisher.send(updated)
            }
        }
    }

    private func fetchYouTubeMetadata(videoId: String, title: String) {
        guard let url = URL(string: "https://www.youtube.com/oembed?url=https://music.youtube.com/watch?v=\(videoId)&format=json") else { return }
        do {
            let data = try Data(contentsOf: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
            let oembedTitle = json["title"] as? String ?? ""
            let artist = json["author_name"] as? String ?? ""
            oembedCache[videoId] = (oembedTitle, artist)

            var artworkPath = ""
            if let thumbUrlStr = json["thumbnail_url"] as? String,
               let thumbUrl = URL(string: thumbUrlStr),
               let imageData = try? Data(contentsOf: thumbUrl) {
                artworkCache.save(imageData)
                if artworkCache.hasArtwork { artworkPath = artworkCache.path }
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
