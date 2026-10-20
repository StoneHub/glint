// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MDown",
    platforms: [.macOS("26.0")],
    targets: [
        .executableTarget(
            name: "MDown",
            path: "Sources/MDown"
        )
    ]
)
