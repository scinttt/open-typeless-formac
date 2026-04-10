import AppKit
import SwiftUI

@MainActor
final class MainWindowController {
    static let shared = MainWindowController()
    private var window: NSWindow?

    func show(
        appState: AppState,
        coordinator: DictationSessionCoordinator,
        permissionManager: PermissionManager,
        hotkeyManager: HotkeyManager
    ) {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = MainWindowView(hotkeyManager: hotkeyManager)
            .environmentObject(appState)
            .environmentObject(coordinator)
            .environmentObject(permissionManager)

        let hostingController = NSHostingController(rootView: view)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "OpenTypeless"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 560, height: 400))
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }

    func close() {
        window?.close()
    }
}
