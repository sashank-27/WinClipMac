// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WinClipMac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "WinClipMac", targets: ["WinClipMac"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "WinClipMac",
            dependencies: [],
            resources: []
        )
    ]
)