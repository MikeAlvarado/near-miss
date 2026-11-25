// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NearMissCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "NearMissCore", targets: ["NearMissCore"])
    ],
    targets: [
        .target(name: "NearMissCore"),
        .testTarget(name: "NearMissCoreTests", dependencies: ["NearMissCore"]),
    ]
)
