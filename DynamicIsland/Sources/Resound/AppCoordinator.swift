import Foundation

@MainActor
final class AppCoordinator {
    private let nowPlaying: NowPlayingViewModel
    private let windowManager: WindowManager
    private let menuBarManager: MenuBarManager
    private let lockScreen = LockScreenCoordinator()

    convenience init() {
        self.init(
            nowPlaying: .shared,
            windowManager: .shared,
            menuBarManager: .shared
        )
    }

    init(
        nowPlaying: NowPlayingViewModel,
        windowManager: WindowManager,
        menuBarManager: MenuBarManager
    ) {
        self.nowPlaying = nowPlaying
        self.windowManager = windowManager
        self.menuBarManager = menuBarManager
    }

    func start() {
        nowPlaying.start()
        windowManager.show()
        menuBarManager.setup()
        lockScreen.start()
    }

    func stop() {
        nowPlaying.stop()
        lockScreen.stop()
    }
}
