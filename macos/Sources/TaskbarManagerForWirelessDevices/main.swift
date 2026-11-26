import AppKit
import TMWDCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: StatusController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let demo = Demo.isEnabled(arguments: CommandLine.arguments, environment: ProcessInfo.processInfo.environment)
        let c = StatusController(demo: demo)
        controller = c
        c.start()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
