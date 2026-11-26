import Foundation

public struct BatteryDevice: Equatable {
    public var name: String
    public var percent: Int
    public var kind: DeviceKind
    /// Ornegin "L 80% · R 75% · Case 50%"
    public var detail: String?

    public init(name: String, percent: Int, kind: DeviceKind, detail: String? = nil) {
        self.name = name
        self.percent = percent
        self.kind = kind
        self.detail = detail
    }
}

public enum Strings {
    public static let appName = "Taskbar Manager for Wireless Devices"
    public static let refresh = "Yenile"
    public static let runAtStartup = "Başlangıçta çalıştır"
    public static let quit = "Çıkış"
    public static let noDevices = "Pil bilgisi veren cihaz yok"
    public static let lowBattery = "Düşük pil"
}

public enum Formatting {
    public static let lowLimit = 20

    public static func line(_ d: BatteryDevice) -> String { "\(d.name) – \(d.percent)%" }

    public static func tooltipLine(_ d: BatteryDevice) -> String {
        if let detail = d.detail, !detail.isEmpty { return line(d) + " (" + detail + ")" }
        return line(d)
    }

    public static func tooltip(_ devices: [BatteryDevice]) -> String {
        devices.map(tooltipLine).joined(separator: "\n")
    }

    public static func notificationBody(_ devices: [BatteryDevice]) -> String {
        Strings.lowBattery + "\n" + devices.map { "\($0.name): %\($0.percent)" }.joined(separator: "\n")
    }
}

public enum Demo {
    public static var devices: [BatteryDevice] {
        [("Klavye", 50), ("Kulaklık", 85), ("Mouse", 18), ("Xbox Controller", 62)].map {
            BatteryDevice(name: $0.0, percent: $0.1, kind: DeviceKind.detect(name: $0.0))
        }
    }

    public static func isEnabled(arguments: [String], environment: [String: String]) -> Bool {
        arguments.contains("--demo") || environment["TMWD_DEMO"] == "1"
    }
}

/// Dusuk pil kurali: yuzde < 20 olunca bir kez uyar; %20 ustune cikarsa (ya da cihaz kaybolursa) sifirlanir.
public struct LowBatteryTracker {
    private var alerted = Set<String>()
    public init() {}

    public mutating func update(_ devices: [BatteryDevice]) -> [BatteryDevice] {
        let names = Set(devices.map { $0.name })
        alerted = alerted.intersection(names)
        var fresh: [BatteryDevice] = []
        for d in devices {
            if d.percent < Formatting.lowLimit {
                if !alerted.contains(d.name) {
                    alerted.insert(d.name)
                    fresh.append(d)
                }
            } else {
                alerted.remove(d.name)
            }
        }
        return fresh
    }
}
