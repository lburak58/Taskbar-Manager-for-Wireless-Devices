import Foundation

/// Cihaz turu. Tespit `detect(name:minorType:)` ile yapilir.
public enum DeviceKind: String, Equatable, CaseIterable {
    case headphones, mouse, keyboard, controller, phone, pen, trackpad, unknown

    /// Ad ve (varsa) device_minorType uzerinden tur tespiti. Windows surumundeki anahtar kelimeler korunur.
    public static func detect(name: String, minorType: String? = nil) -> DeviceKind {
        let text = (name + " " + (minorType ?? "")).lowercased()
        let tokens = Set(text.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init))

        func has(_ keys: [String]) -> Bool { keys.contains { text.contains($0) } }

        if has(["headphone", "headset", "airpods", "kulaklık", "kulaklik", "speaker", "hoparlör"]) || tokens.contains(where: { $0.hasPrefix("buds") }) {
            return .headphones
        }
        if has(["trackpad"]) { return .trackpad }
        if has(["mouse"]) { return .mouse }
        if has(["keyboard", "klavye"]) { return .keyboard }
        if has(["controller", "gamepad", "xbox", "dualsense", "dualshock"]) { return .controller }
        if has(["phone"]) { return .phone }
        if has(["pencil"]) || tokens.contains("pen") { return .pen }
        return .unknown
    }

    /// Oncelik sirasina gore SF Symbol adaylari (macOS 13'te hepsi olmayabilir; ilk bulunan kullanilir).
    public func symbolCandidates(deviceName: String = "") -> [String] {
        switch self {
        case .headphones:
            let base = ["headphones", "speaker.wave.2"]
            return deviceName.lowercased().contains("airpods") ? ["airpods"] + base : base
        case .mouse: return ["computermouse", "cursorarrow"]
        case .keyboard: return ["keyboard"]
        case .controller: return ["gamecontroller"]
        case .phone: return ["iphone", "phone"]
        case .pen: return ["applepencil", "pencil.tip", "pencil"]
        case .trackpad: return ["rectangle.and.hand.point.up.left", "hand.point.up.left", "dot.radiowaves.left.and.right"]
        case .unknown: return ["dot.radiowaves.left.and.right"]
        }
    }
}
