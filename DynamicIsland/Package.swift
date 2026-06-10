// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Resound",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Resound",
            exclude: ["Info.plist"],
            resources: [.copy("Resources/Resound.icns")]
        )
    ]
)
