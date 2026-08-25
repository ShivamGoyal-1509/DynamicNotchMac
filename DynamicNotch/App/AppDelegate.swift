import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var notchWindowController: NotchWindowController?

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {
        NSApp.setActivationPolicy(.accessory)

        notchWindowController =
            NotchWindowController()

        notchWindowController?.show()
    }
}
