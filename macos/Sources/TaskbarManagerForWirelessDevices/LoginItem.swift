import Foundation
import ServiceManagement

/// "Baslangicta calistir" (SMAppService).
enum LoginItem {
    static var state: SMAppService.Status { SMAppService.mainApp.status }

    static var isEnabled: Bool { state == .enabled }

    /// Bundle disinda (swift run) ya da servis kullanilamiyorsa false.
    static var isSupported: Bool {
        guard Bundle.main.bundleIdentifier != nil, Bundle.main.bundlePath.hasSuffix(".app") else { return false }
        return state != .notFound
    }

    /// Basarisiz olursa false doner; cokme yok.
    @discardableResult
    static func setEnabled(_ on: Bool) -> Bool {
        do {
            if on {
                if state != .enabled { try SMAppService.mainApp.register() }
            } else {
                if state == .enabled || state == .requiresApproval { try SMAppService.mainApp.unregister() }
            }
            return true
        } catch {
            return false
        }
    }
}
