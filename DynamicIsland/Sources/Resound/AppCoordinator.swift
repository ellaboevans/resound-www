import Foundation

@MainActor
final class AppCoordinator {
    private let nowPlaying: NowPlayingViewModel
    private let windowManager: WindowManager
    private let menuBarManager: MenuBarManager
    private let hotkeyManager: HotkeyManager

    convenience init() {
        self.init(
            nowPlaying: .shared,
            windowManager: .shared,
            menuBarManager: .shared,
            hotkeyManager: .shared
        )
    }

    init(
        nowPlaying: NowPlayingViewModel,
        windowManager: WindowManager,
        menuBarManager: MenuBarManager,
        hotkeyManager: HotkeyManager
    ) {
        self.nowPlaying = nowPlaying
        self.windowManager = windowManager
        self.menuBarManager = menuBarManager
        self.hotkeyManager = hotkeyManager
    }

    func start() {
        nowPlaying.start()
        windowManager.show()
        menuBarManager.setup()
        hotkeyManager.start { [weak windowManager] in
            windowManager?.toggle()
        }
    }

    func stop() {
        hotkeyManager.stop()
        nowPlaying.stop()
    }
}
