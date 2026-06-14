import Cocoa
import Combine

@MainActor
final class LockScreenCoordinator {
    private let viewController = LockScreenViewController()
    private var cancellables = Set<AnyCancellable>()
    private var lockObserver: NSObjectProtocol?
    private var unlockObserver: NSObjectProtocol?
    private var isLocked = false

    func start() {
        observeLockState()
        observeNowPlaying()
        checkInitialLockState()
    }

    func stop() {
        viewController.hide()
        cancellables.removeAll()
        if let lockObserver {
            DistributedNotificationCenter.default().removeObserver(lockObserver)
        }
        if let unlockObserver {
            DistributedNotificationCenter.default().removeObserver(unlockObserver)
        }
    }

    private func observeLockState() {
        let center = DistributedNotificationCenter.default()
        lockObserver = center.addObserver(forName: NSNotification.Name("com.apple.screenIsLocked"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                isLocked = true
                viewController.show()
            }
        }
        unlockObserver = center.addObserver(forName: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                isLocked = false
                viewController.hide()
            }
        }
    }

    private func observeNowPlaying() {
        NowPlayingService.shared.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                guard let self else { return }
                var artwork: NSImage?
                if !info.artworkPath.isEmpty {
                    artwork = NSImage(contentsOfFile: info.artworkPath)
                }
                self.viewController.update(
                    trackTitle: info.trackTitle,
                    artistName: info.artistName,
                    albumTitle: info.albumTitle,
                    artwork: artwork,
                    elapsed: info.elapsedTime,
                    duration: info.duration,
                    isPlaying: info.isPlaying
                )
            }
            .store(in: &cancellables)
    }

    private func checkInitialLockState() {
        if let sessionDict = CGSessionCopyCurrentDictionary() as? [String: Any],
           sessionDict["CGSSessionScreenIsLocked"] as? Int32 == 1 {
            isLocked = true
            viewController.show()
        }
    }
}
