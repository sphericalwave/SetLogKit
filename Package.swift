// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SetLogKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SetLogKit", targets: ["SetLogKit"]),
    ],
    targets: [
        .target(name: "SetLogKit"),
        .testTarget(name: "SetLogKitTests", dependencies: ["SetLogKit"]),
    ]
)
