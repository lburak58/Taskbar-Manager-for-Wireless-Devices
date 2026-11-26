import Foundation

public enum SystemProfilerParser {
    /// `system_profiler SPBluetoothDataType -json` ciktisini ayristirir. Beklenmeyen bicimde bos liste doner, cokmez.
    public static func parse(_ data: Data) -> [BatteryDevice] {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sections = root["SPBluetoothDataType"] as? [Any],
              let first = sections.first as? [String: Any],
              let connected = first["device_connected"] as? [Any] else { return [] }

        var result: [BatteryDevice] = []
        for entry in connected {
            guard let dict = entry as? [String: Any] else { continue }
            for (name, value) in dict {
                guard let props = value as? [String: Any],
                      let device = device(name: name, props: props) else { continue }
                result.append(device)
            }
        }
        return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func device(name: String, props: [String: Any]) -> BatteryDevice? {
        let main = percent(props["device_batteryLevelMain"])
        let left = percent(props["device_batteryLevelLeft"])
        let right = percent(props["device_batteryLevelRight"])
        let box = percent(props["device_batteryLevelCase"])

        let levels = [main, left, right].compactMap { $0 }
        guard let lowest = levels.min() else { return nil }

        var detail: String?
        if left != nil || right != nil || box != nil {
            var parts: [String] = []
            if let m = main { parts.append("\(m)%") }
            if let l = left { parts.append("L \(l)%") }
            if let r = right { parts.append("R \(r)%") }
            if let c = box { parts.append("Case \(c)%") }
            detail = parts.joined(separator: " · ")
        }
        let minor = props["device_minorType"] as? String
        return BatteryDevice(name: name, percent: lowest, kind: DeviceKind.detect(name: name, minorType: minor), detail: detail)
    }

    /// "85%", 85, "85" -> 85 (0...100). Gecersizse nil.
    static func percent(_ value: Any?) -> Int? {
        var number: Int?
        if let s = value as? String {
            number = Int(s.trimmingCharacters(in: CharacterSet(charactersIn: "%").union(.whitespaces)))
        } else if let n = value as? NSNumber {
            number = n.intValue
        }
        guard let n = number, n >= 0, n <= 100 else { return nil }
        return n
    }
}

public enum IORegistryParser {
    /// IOKit kayit girdisi ozelliklerinden cihaz uretir ("BatteryPercent", "Product").
    public static func device(from props: [String: Any]) -> BatteryDevice? {
        guard let name = (props["Product"] as? String)?.trimmingCharacters(in: .whitespaces), !name.isEmpty,
              let pct = SystemProfilerParser.percent(props["BatteryPercent"]) else { return nil }
        return BatteryDevice(name: name, percent: pct, kind: DeviceKind.detect(name: name))
    }
}

public enum DeviceMerger {
    public static func normalize(_ name: String) -> String {
        name.replacingOccurrences(of: "\u{2019}", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    /// Ada gore birlestirir. system_profiler ayrintisi (L/R/Case) varsa o korunur; yoksa IOKit (daha taze) yuzdesi kullanilir.
    public static func merge(iokit: [BatteryDevice], profiler: [BatteryDevice]) -> [BatteryDevice] {
        var byKey: [String: BatteryDevice] = [:]
        var order: [String] = []

        for d in profiler {
            let key = normalize(d.name)
            if byKey[key] == nil { order.append(key) }
            byKey[key] = d
        }
        for d in iokit {
            let key = normalize(d.name)
            if let existing = byKey[key] {
                if existing.detail == nil {
                    var merged = d
                    merged.name = existing.name
                    if existing.kind != .unknown { merged.kind = existing.kind }
                    byKey[key] = merged
                }
            } else {
                order.append(key)
                byKey[key] = d
            }
        }
        return order.compactMap { byKey[$0] }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
