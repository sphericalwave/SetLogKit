// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SetLogKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SetLogKit", targets: ["SetLogKit"]),
    ],
    dependencies: [
        .package(path: "../EquipmentKit"),
    ],
    targets: [
        .target(name: "SetLogKit", dependencies: ["EquipmentKit"]),
        .testTarget(name: "SetLogKitTests", dependencies: ["SetLogKit"]),
    ]
)
