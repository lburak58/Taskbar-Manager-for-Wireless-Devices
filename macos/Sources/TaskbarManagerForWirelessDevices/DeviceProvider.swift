import Foundation
import IOKit
import TMWDCore

/// Pil verisini toplar. Bloklayicidir; ana thread disinda cagrilmalidir.
enum DeviceProvider {
    static func fetch(demo: Bool) -> [BatteryDevice] {
        if demo { return Demo.devices }
        let io = readIOKit()
        let prof = readSystemProfiler()
        return DeviceMerger.merge(iokit: io, profiler: prof)
    }

    // MARK: IOKit (hizli yol: Magic Mouse/Keyboard/Trackpad)

    private static let ioClasses = [
        "AppleDeviceManagementHIDEventService",
        "AppleBluetoothHIDKeyboard",
        "BNBMouseDevice",
        "BNBTrackpadDevice",
        "IOBluetoothDevice"
    ]

    static func readIOKit() -> [BatteryDevice] {
        var result: [BatteryDevice] = []
        for cls in ioClasses {
            guard let matching = IOServiceMatching(cls) else { continue }
            var iterator: io_iterator_t = 0
            guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else { continue }
            var entry = IOIteratorNext(iterator)
            while entry != 0 {
                var unmanaged: Unmanaged<CFMutableDictionary>?
                if IORegistryEntryCreateCFProperties(entry, &unmanaged, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                   let cf = unmanaged?.takeRetainedValue(),
                   let props = cf as NSDictionary as? [String: Any],
                   let device = IORegistryParser.device(from: props) {
                    result.append(device)
                }
                IOObjectRelease(entry)
                entry = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }
        return result
    }

    // MARK: system_profiler

    static func readSystemProfiler(timeout: TimeInterval = 15) -> [BatteryDevice] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPBluetoothDataType", "-json"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { return [] }

        let killer = DispatchWorkItem { if process.isRunning { process.terminate() } }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: killer)
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        killer.cancel()
        return SystemProfilerParser.parse(data)
    }
}
