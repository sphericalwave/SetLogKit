// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SetLogKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SetLogKit", targets: ["SetLogKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sphericalwave/EquipmentKit.git", branch: "main"),
    ],
    targets: [
        .target(name: "SetLogKit", dependencies: ["EquipmentKit"]),
        .testTarget(name: "SetLogKitTests", dependencies: ["SetLogKit"]),
    ]
)
