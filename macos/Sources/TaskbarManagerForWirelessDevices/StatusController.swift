import AppKit
import TMWDCore

/// Tek NSStatusItem; tum UI islemleri ana thread'de, sorgular arka planda.
final class StatusController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let demo: Bool
    private let queue = DispatchQueue(label: "tmwd.query", qos: .utility)
    private var timer: Timer?
    private var inFlight = false
    private var tracker = LowBatteryTracker()
    private var devices: [BatteryDevice] = []
    private var hasData = false

    init(demo: Bool) {
        self.demo = demo
        super.init()
        // statusItem.menu kalici atanirsa AppKit hover tooltip'ini gostermez; menu yalnizca tiklamada baglanir.
        menu.delegate = self
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        setToolTip(Strings.appName)
        rebuildMenu()
        render()
    }

    func start() {
        refresh()
        let t = Timer(timeInterval: 60, repeats: true) { [weak self] _ in self?.refresh() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    // MARK: Veri

    @objc func refresh() {
        guard !inFlight else { return } // ust uste binen sorgu yok
        inFlight = true
        let demo = self.demo
        queue.async { [weak self] in
            let result = DeviceProvider.fetch(demo: demo)
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.inFlight = false
                self.apply(result)
            }
        }
    }

    private func apply(_ result: [BatteryDevice]) {
        devices = result
        hasData = true
        let fresh = tracker.update(result)
        if !fresh.isEmpty { Notifier.notifyLow(fresh) }
        render()
        rebuildMenu()
    }

    // MARK: Gorunum

    private func symbol(_ candidates: [String], font: NSFont) -> NSImage? {
        let config = NSImage.SymbolConfiguration(pointSize: font.pointSize, weight: .regular)
        for name in candidates {
            if let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?.withSymbolConfiguration(config) {
                image.isTemplate = true
                return image
            }
        }
        return nil
    }

    private func attachment(_ image: NSImage, font: NSFont) -> NSAttributedString {
        let a = NSTextAttachment()
        a.image = image
        let size = image.size
        a.bounds = CGRect(x: 0, y: (font.capHeight - size.height) / 2, width: size.width, height: size.height)
        return NSAttributedString(attachment: a)
    }

    private var currentToolTip = ""

    /// Deger degismediyse yeniden atama (izleme alanini sifirlamasin).
    private func setToolTip(_ text: String) {
        guard let button = statusItem.button, text != currentToolTip || button.toolTip != text else { return }
        currentToolTip = text
        button.toolTip = text
        if ProcessInfo.processInfo.environment["TMWD_DEBUG"] == "1" {
            let line = "tooltip=" + text.replacingOccurrences(of: "\n", with: " | ") + "\n"
            FileHandle.standardError.write(Data(line.utf8))
        }
    }

    @objc private func statusClicked(_ sender: Any?) {
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
    }

    func menuDidClose(_ menu: NSMenu) {
        // Menu kapaninca baglantiyi kes: tooltip tekrar calisir.
        DispatchQueue.main.async { [weak self] in self?.statusItem.menu = nil }
    }

    private func render() {
        guard let button = statusItem.button else { return }
        let font = NSFont.menuBarFont(ofSize: 0)
        setToolTip(devices.isEmpty ? Strings.appName : Formatting.tooltip(devices))

        if devices.isEmpty {
            // Cihaz yok: soluk Bluetooth/radyo simgesi
            button.attributedTitle = NSAttributedString(string: "")
            button.image = symbol(["dot.radiowaves.left.and.right"], font: font)
            button.appearsDisabled = true
            return
        }
        button.image = nil
        button.appearsDisabled = false

        let text = NSMutableAttributedString()
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        for (index, d) in devices.enumerated() {
            if index > 0 { text.append(NSAttributedString(string: "  ", attributes: attrs)) }
            if let img = symbol(d.kind.symbolCandidates(deviceName: d.name), font: font) {
                text.append(attachment(img, font: font))
            }
            text.append(NSAttributedString(string: " \(d.percent)%", attributes: attrs))
            if d.percent < Formatting.lowLimit, let warn = symbol(["exclamationmark.triangle"], font: font) {
                text.append(NSAttributedString(string: " ", attributes: attrs))
                text.append(attachment(warn, font: font))
            }
        }
        button.attributedTitle = text
    }

    private func rebuildMenu() {
        menu.removeAllItems()
        let refreshItem = NSMenuItem(title: Strings.refresh, action: #selector(refresh), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        menu.addItem(.separator())

        if devices.isEmpty {
            let none = NSMenuItem(title: Strings.noDevices, action: nil, keyEquivalent: "")
            none.isEnabled = false
            menu.addItem(none)
        } else {
            for d in devices {
                let item = NSMenuItem(title: Formatting.line(d), action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
            }
        }
        menu.addItem(.separator())

        let login = NSMenuItem(title: Strings.runAtStartup, action: #selector(toggleLogin), keyEquivalent: "")
        login.target = self
        if LoginItem.isSupported {
            switch LoginItem.state {
            case .enabled: login.state = .on
            case .requiresApproval: login.state = .mixed
            default: login.state = .off
            }
        } else {
            login.isEnabled = false
        }
        menu.addItem(login)

        let quit = NSMenuItem(title: Strings.quit, action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    @objc private func toggleLogin() {
        let ok = LoginItem.setEnabled(!LoginItem.isEnabled)
        rebuildMenu()
        if !ok, let item = menu.items.first(where: { $0.title == Strings.runAtStartup }) {
            item.isEnabled = false // hata: ogeyi devre disi birak
        }
    }

    @objc private func quitApp() { NSApp.terminate(nil) }
}
