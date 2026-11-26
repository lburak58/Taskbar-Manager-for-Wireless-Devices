// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TaskbarManagerForWirelessDevices",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "TaskbarManagerForWirelessDevices", targets: ["TaskbarManagerForWirelessDevices"])
    ],
    targets: [
        // Saf mantik: tur tespiti, JSON ayristirma, birlestirme, dusuk pil kurali.
        .target(name: "TMWDCore"),
        .executableTarget(
            name: "TaskbarManagerForWirelessDevices",
            dependencies: ["TMWDCore"]
        ),
        .testTarget(name: "TMWDCoreTests", dependencies: ["TMWDCore"])
    ]
)
