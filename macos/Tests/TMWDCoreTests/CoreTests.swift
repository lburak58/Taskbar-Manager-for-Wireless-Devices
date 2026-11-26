import XCTest
@testable import TMWDCore

private enum Fixture {
    static let airpods = """
    {"SPBluetoothDataType":[{"device_connected":[
      {"Ali’s AirPods Pro":{"device_address":"AA:BB","device_minorType":"Headphones",
        "device_batteryLevelLeft":"80%","device_batteryLevelRight":"75%","device_batteryLevelCase":"50%"}}
    ]}]}
    """
    static let magicMouse = """
    {"SPBluetoothDataType":[{"device_connected":[
      {"Magic Mouse":{"device_minorType":"Mouse","device_batteryLevelMain":"64%"}}
    ]}]}
    """
    static let xbox = """
    {"SPBluetoothDataType":[{"device_connected":[
      {"Xbox Wireless Controller":{"device_minorType":"Gamepad","device_batteryLevelMain":"62%"}}
    ]}]}
    """
    static let noBattery = """
    {"SPBluetoothDataType":[{"device_connected":[
      {"Some Speaker":{"device_minorType":"Speaker","device_address":"11:22"}}
    ]}]}
    """
    static let empty = #"{"SPBluetoothDataType":[{"device_connected":[]}]}"#
    static let unexpected = #"{"SPBluetoothDataType":"hello"}"#
    static let mixed = """
    {"SPBluetoothDataType":[{"device_connected":[
      {"Magic Keyboard":{"device_minorType":"Keyboard","device_batteryLevelMain":"40%"}},
      {"Broken":{"device_batteryLevelMain":"abc"}},
      "garbage",
      {"Weird":{"device_batteryLevelMain":250}}
    ]}]}
    """
}

private func parse(_ s: String) -> [BatteryDevice] { SystemProfilerParser.parse(Data(s.utf8)) }

final class CoreTests: XCTestCase {
    func testParseAirPodsUsesLowestAndDetail() {
        let d = parse(Fixture.airpods)
        XCTAssertEqual(d.count, 1)
        XCTAssertEqual(d[0].percent, 75)
        XCTAssertEqual(d[0].kind, .headphones)
        XCTAssertEqual(d[0].detail, "L 80% · R 75% · Case 50%")
    }

    func testParseMagicMouse() {
        let d = parse(Fixture.magicMouse)
        XCTAssertEqual(d, [BatteryDevice(name: "Magic Mouse", percent: 64, kind: .mouse)])
    }

    func testParseXboxController() {
        let d = parse(Fixture.xbox)
        XCTAssertEqual(d.first?.percent, 62)
        XCTAssertEqual(d.first?.kind, .controller)
    }

    func testDeviceWithoutBatteryIsSkipped() {
        XCTAssertTrue(parse(Fixture.noBattery).isEmpty)
    }

    func testEmptyAndUnexpectedAndGarbageInput() {
        XCTAssertTrue(parse(Fixture.empty).isEmpty)
        XCTAssertTrue(parse(Fixture.unexpected).isEmpty)
        XCTAssertTrue(parse("not json").isEmpty)
        XCTAssertTrue(parse("").isEmpty)
    }

    func testMixedEntriesKeepOnlyValid() {
        let d = parse(Fixture.mixed)
        XCTAssertEqual(d.map { $0.name }, ["Magic Keyboard"])
        XCTAssertEqual(d.first?.kind, .keyboard)
    }

    func testPercentParsing() {
        XCTAssertEqual(SystemProfilerParser.percent("85%"), 85)
        XCTAssertEqual(SystemProfilerParser.percent(" 7 % "), 7)
        XCTAssertEqual(SystemProfilerParser.percent(NSNumber(value: 40)), 40)
        XCTAssertNil(SystemProfilerParser.percent("-1%"))
        XCTAssertNil(SystemProfilerParser.percent("101%"))
        XCTAssertNil(SystemProfilerParser.percent(nil))
    }

    func testKindDetection() {
        XCTAssertEqual(DeviceKind.detect(name: "Sony WH-1000XM4", minorType: "Headphones"), .headphones)
        XCTAssertEqual(DeviceKind.detect(name: "Galaxy Buds2"), .headphones)
        XCTAssertEqual(DeviceKind.detect(name: "Kulaklık"), .headphones)
        XCTAssertEqual(DeviceKind.detect(name: "Magic Trackpad"), .trackpad)
        XCTAssertEqual(DeviceKind.detect(name: "MX Master", minorType: "Mouse"), .mouse)
        XCTAssertEqual(DeviceKind.detect(name: "Klavye"), .keyboard)
        XCTAssertEqual(DeviceKind.detect(name: "DualSense Wireless Controller"), .controller)
        XCTAssertEqual(DeviceKind.detect(name: "Pixel 8", minorType: "Phone"), .phone)
        XCTAssertEqual(DeviceKind.detect(name: "Apple Pencil"), .pen)
        XCTAssertEqual(DeviceKind.detect(name: "Open Thing"), .unknown)
        XCTAssertEqual(DeviceKind.detect(name: "Foo"), .unknown)
    }

    func testAirPodsSymbolCandidates() {
        XCTAssertEqual(DeviceKind.headphones.symbolCandidates(deviceName: "AirPods Pro").first, "airpods")
        XCTAssertEqual(DeviceKind.headphones.symbolCandidates(deviceName: "Sony").first, "headphones")
        for kind in DeviceKind.allCases { XCTAssertFalse(kind.symbolCandidates().isEmpty) }
    }

    func testMergeByNamePrefersProfilerDetailElseIOKitPercent() {
        let prof = [
            BatteryDevice(name: "Ali’s AirPods", percent: 70, kind: .headphones, detail: "L 70% · R 80%"),
            BatteryDevice(name: "Magic Mouse", percent: 60, kind: .mouse)
        ]
        let io = [
            BatteryDevice(name: "Ali's AirPods", percent: 99, kind: .unknown),
            BatteryDevice(name: "magic mouse ", percent: 58, kind: .unknown),
            BatteryDevice(name: "Magic Keyboard", percent: 30, kind: .keyboard)
        ]
        let merged = DeviceMerger.merge(iokit: io, profiler: prof)
        XCTAssertEqual(merged.map { $0.name }, ["Ali’s AirPods", "Magic Keyboard", "Magic Mouse"])
        XCTAssertEqual(merged[0].percent, 70)
        XCTAssertEqual(merged[2].percent, 58)
        XCTAssertEqual(merged[2].kind, .mouse)
    }

    func testMergeEmpty() {
        XCTAssertTrue(DeviceMerger.merge(iokit: [], profiler: []).isEmpty)
    }

    func testIORegistryParser() {
        let d = IORegistryParser.device(from: ["Product": "Magic Keyboard", "BatteryPercent": 55])
        XCTAssertEqual(d, BatteryDevice(name: "Magic Keyboard", percent: 55, kind: .keyboard))
        XCTAssertNil(IORegistryParser.device(from: ["Product": "X"]))
        XCTAssertNil(IORegistryParser.device(from: ["BatteryPercent": 10]))
    }

    func testLowBatteryAlertsOnceAndRearms() {
        var t = LowBatteryTracker()
        let low = BatteryDevice(name: "Mouse", percent: 18, kind: .mouse)
        var ok = low; ok.percent = 25
        var edge = low; edge.percent = 20

        XCTAssertEqual(t.update([low]).count, 1)
        XCTAssertEqual(t.update([low]).count, 0)
        XCTAssertEqual(t.update([edge]).count, 0)   // 20 düşük değil, yeniden kurulur
        XCTAssertEqual(t.update([low]).count, 1)
        XCTAssertEqual(t.update([ok]).count, 0)
        XCTAssertEqual(t.update([low]).count, 1)
        XCTAssertEqual(t.update([]).count, 0)       // cihaz kayboldu
        XCTAssertEqual(t.update([low]).count, 1)
    }

    func testFormattingAndDemo() {
        let demo = Demo.devices
        XCTAssertEqual(demo.map { $0.percent }, [50, 85, 18, 62])
        XCTAssertEqual(demo.map { $0.kind }, [.keyboard, .headphones, .mouse, .controller])
        XCTAssertEqual(Formatting.line(demo[0]), "Klavye – 50%")
        XCTAssertEqual(Formatting.tooltip(demo).split(separator: "\n").count, 4)
        XCTAssertEqual(Formatting.notificationBody([demo[2]]), "Düşük pil\nMouse: %18")
        XCTAssertTrue(Demo.isEnabled(arguments: ["x", "--demo"], environment: [:]))
        XCTAssertTrue(Demo.isEnabled(arguments: ["x"], environment: ["TMWD_DEMO": "1"]))
        XCTAssertFalse(Demo.isEnabled(arguments: ["x"], environment: [:]))
    }
}
